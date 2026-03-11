import AVFAudio
import Foundation
import PokeCore
import PokeDataModel

@MainActor
final class PokeAudioService: RuntimeAudioPlaying {
    private struct RenderedEntry {
        let prelude: AVAudioPCMBuffer?
        let loop: AVAudioPCMBuffer?
        let oneShotDuration: Double
    }

    private struct RenderedSamples {
        let prelude: [Float]?
        let loop: [Float]?
        let oneShotDuration: Double
    }

    private struct PendingPlayback {
        let requestID: Int
        let cacheKey: String
        let playbackMode: AudioManifest.PlaybackMode
        let completion: (@MainActor () -> Void)?
    }

    private let manifest: AudioManifest
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private let renderQueue = DispatchQueue(label: "com.dimillian.PokeSwift.audio-render", qos: .userInitiated)
    private var renderCache: [String: RenderedEntry] = [:]
    private var rendersInFlight: Set<String> = []
    private var completionWorkItem: DispatchWorkItem?
    private var playbackRequestID = 0
    private var pendingPlayback: PendingPlayback?

    init(manifest: AudioManifest) {
        self.manifest = manifest
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 0.6
        try? engine.start()
        prewarmManifest()
    }

    func play(request: AudioPlaybackRequest, completion: (@MainActor () -> Void)?) {
        guard let track = manifest.tracks.first(where: { $0.id == request.trackID }),
              let entry = track.entries.first(where: { $0.id == request.entryID }) else {
            completion?()
            return
        }

        ensureEngineRunning()
        completionWorkItem?.cancel()
        player.stop()
        player.reset()

        let cacheKey = "\(request.trackID):\(request.entryID)"
        playbackRequestID += 1
        let requestID = playbackRequestID

        if let rendered = renderCache[cacheKey] {
            pendingPlayback = nil
            startPlayback(
                rendered,
                cacheKey: cacheKey,
                playbackMode: entry.playbackMode,
                completion: completion
            )
            return
        }

        pendingPlayback = PendingPlayback(
            requestID: requestID,
            cacheKey: cacheKey,
            playbackMode: entry.playbackMode,
            completion: completion
        )
        scheduleRenderIfNeeded(cacheKey: cacheKey, entry: entry)
    }

    func stopAllMusic() {
        playbackRequestID += 1
        pendingPlayback = nil
        completionWorkItem?.cancel()
        player.stop()
        player.reset()
    }

    private func scheduleLoopBufferIfNeeded(_ buffer: AVAudioPCMBuffer?) {
        guard let buffer, buffer.frameLength > 0 else { return }
        player.scheduleBuffer(buffer, at: nil, options: [.loops])
        if player.isPlaying == false {
            player.play()
        }
    }

    private func ensureEngineRunning() {
        if engine.isRunning == false {
            try? engine.start()
        }
    }

    private func prewarmManifest() {
        for track in manifest.tracks {
            for entry in track.entries {
                let cacheKey = "\(track.id):\(entry.id)"
                scheduleRenderIfNeeded(cacheKey: cacheKey, entry: entry)
            }
        }
    }

    private func scheduleRenderIfNeeded(cacheKey: String, entry: AudioManifest.Entry) {
        guard renderCache[cacheKey] == nil, rendersInFlight.contains(cacheKey) == false else { return }
        rendersInFlight.insert(cacheKey)

        let sampleRate = format.sampleRate
        renderQueue.async { [entry] in
            let samples = Self.renderedSamples(for: entry, sampleRate: sampleRate)
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.rendersInFlight.remove(cacheKey)
                let rendered = RenderedEntry(
                    prelude: self.makeBuffer(from: samples.prelude),
                    loop: self.makeBuffer(from: samples.loop),
                    oneShotDuration: samples.oneShotDuration
                )
                self.renderCache[cacheKey] = rendered

                guard let pendingPlayback = self.pendingPlayback,
                      pendingPlayback.requestID == self.playbackRequestID,
                      pendingPlayback.cacheKey == cacheKey else {
                    return
                }

                self.pendingPlayback = nil
                self.startPlayback(
                    rendered,
                    cacheKey: cacheKey,
                    playbackMode: pendingPlayback.playbackMode,
                    completion: pendingPlayback.completion
                )
            }
        }
    }

    private func startPlayback(
        _ rendered: RenderedEntry,
        cacheKey: String,
        playbackMode: AudioManifest.PlaybackMode,
        completion: (@MainActor () -> Void)?
    ) {
        switch playbackMode {
        case .looping:
            if let prelude = rendered.prelude, prelude.frameLength > 0 {
                player.scheduleBuffer(prelude) { [weak self] in
                    Task { @MainActor [weak self, cacheKey] in
                        guard let self else { return }
                        self.scheduleLoopBufferIfNeeded(self.renderCache[cacheKey]?.loop)
                    }
                }
            } else {
                scheduleLoopBufferIfNeeded(rendered.loop)
            }
            player.play()
        case .oneShot:
            if let prelude = rendered.prelude {
                player.scheduleBuffer(prelude)
                player.play()
            }
            if let completion {
                let workItem = DispatchWorkItem { completion() }
                completionWorkItem = workItem
                DispatchQueue.main.asyncAfter(deadline: .now() + rendered.oneShotDuration, execute: workItem)
            }
        }
    }

    private func makeBuffer(from samples: [Float]?) -> AVAudioPCMBuffer? {
        guard let samples, samples.isEmpty == false else { return nil }
        let frameCount = AVAudioFrameCount(samples.count)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let channelData = buffer.floatChannelData?[0] else {
            return nil
        }
        buffer.frameLength = frameCount
        samples.withUnsafeBufferPointer { source in
            channelData.update(from: source.baseAddress!, count: source.count)
        }
        return buffer
    }

    private nonisolated static func renderedSamples(
        for entry: AudioManifest.Entry,
        sampleRate: Double
    ) -> RenderedSamples {
        let prelude = renderSegment(channels: entry.channels, keyPath: \.prelude, sampleRate: sampleRate)
        let loop = renderSegment(channels: entry.channels, keyPath: \.loop, sampleRate: sampleRate)
        let duration = max(
            renderedDuration(for: entry.channels, keyPath: \.prelude),
            renderedDuration(for: entry.channels, keyPath: \.loop)
        )
        return RenderedSamples(prelude: prelude, loop: loop, oneShotDuration: duration)
    }

    private nonisolated static func renderSegment(
        channels: [AudioManifest.ChannelProgram],
        keyPath: KeyPath<AudioManifest.ChannelProgram, [AudioManifest.Event]>,
        sampleRate: Double
    ) -> [Float]? {
        let totalDuration = renderedDuration(for: channels, keyPath: keyPath)
        guard totalDuration > 0 else { return nil }
        let frameCount = max(1, Int(ceil(totalDuration * sampleRate)))
        var samples = Array(repeating: Float.zero, count: frameCount)

        samples.withUnsafeMutableBufferPointer { buffer in
            guard let baseAddress = buffer.baseAddress else { return }
            for channel in channels {
                let events = channel[keyPath: keyPath]
                for event in events {
                    render(
                        event: event,
                        into: baseAddress,
                        frameCount: frameCount,
                        sampleRate: sampleRate,
                        seed: UInt64(channel.channelNumber * 7919)
                    )
                }
            }
            normalize(samples: baseAddress, frameCount: frameCount)
        }

        return samples
    }

    private nonisolated static func renderedDuration(
        for channels: [AudioManifest.ChannelProgram],
        keyPath: KeyPath<AudioManifest.ChannelProgram, [AudioManifest.Event]>
    ) -> Double {
        channels
            .flatMap { $0[keyPath: keyPath] }
            .map { $0.startTime + $0.duration }
            .max() ?? 0
    }

    private nonisolated static func render(
        event: AudioManifest.Event,
        into samples: UnsafeMutablePointer<Float>,
        frameCount: Int,
        sampleRate: Double,
        seed: UInt64
    ) {
        guard event.duration > 0 else { return }
        let startFrame = max(0, Int(event.startTime * sampleRate))
        let endFrame = min(frameCount, Int((event.startTime + event.duration) * sampleRate))
        guard endFrame > startFrame else { return }

        let attackFrames = max(1, Int(sampleRate * 0.003))
        let releaseFrames = max(1, Int(sampleRate * 0.01))
        let effectiveDuty = event.dutyCycle ?? 0.5

        for frame in startFrame..<endFrame {
            let localTime = Double(frame - startFrame) / sampleRate
            let envelope: Double
            if frame - startFrame < attackFrames {
                envelope = Double(frame - startFrame) / Double(attackFrames)
            } else if endFrame - frame < releaseFrames {
                envelope = Double(endFrame - frame) / Double(releaseFrames)
            } else {
                envelope = 1
            }

            let sampleValue: Double
            switch event.waveform {
            case .square:
                let frequency = modulatedFrequency(for: event, localTime: localTime)
                let phase = (localTime * frequency).truncatingRemainder(dividingBy: 1)
                sampleValue = phase < effectiveDuty ? 1 : -1
            case .wave:
                let frequency = modulatedFrequency(for: event, localTime: localTime)
                sampleValue = waveTableSample(event.waveSamples, localTime: localTime, frequency: frequency)
            case .noise:
                sampleValue = noiseSample(
                    event: event,
                    localTime: localTime,
                    sampleRate: sampleRate,
                    seed: seed &+ UInt64(truncatingIfNeeded: startFrame)
                )
            }

            let amplitude = envelopeAdjustedAmplitude(for: event, localTime: localTime)
            samples[frame] += Float(sampleValue * amplitude * envelope * 0.18)
        }
    }

    private nonisolated static func modulatedFrequency(for event: AudioManifest.Event, localTime: Double) -> Double {
        let baseFrequency = pitchSlideAdjustedFrequency(
            baseFrequency: event.frequencyHz ?? 440,
            event: event,
            localTime: localTime
        )
        return vibratoAdjustedFrequency(baseFrequency: baseFrequency, event: event, localTime: localTime)
    }

    private nonisolated static func pitchSlideAdjustedFrequency(
        baseFrequency: Double,
        event: AudioManifest.Event,
        localTime: Double
    ) -> Double {
        guard let targetFrequency = event.pitchSlideTargetHz, event.duration > 0 else {
            return baseFrequency
        }
        let progress = max(0, min(1, localTime / event.duration))
        return baseFrequency + ((targetFrequency - baseFrequency) * progress)
    }

    private nonisolated static func vibratoAdjustedFrequency(baseFrequency: Double, event: AudioManifest.Event, localTime: Double) -> Double {
        guard event.vibratoDepthSemitones > 0, event.vibratoRateHz > 0 else { return baseFrequency }
        guard localTime >= event.vibratoDelaySeconds else { return baseFrequency }
        let semitoneOffset = sin(2 * .pi * localTime * event.vibratoRateHz) * event.vibratoDepthSemitones
        return baseFrequency * pow(2, semitoneOffset / 12)
    }

    private nonisolated static func envelopeAdjustedAmplitude(for event: AudioManifest.Event, localTime: Double) -> Double {
        guard let stepDuration = event.envelopeStepDuration, event.envelopeDirection != 0 else {
            return event.amplitude
        }
        let steps = Int(localTime / stepDuration)
        let delta = Double(event.envelopeDirection * steps) / 15
        return max(0, min(1, event.amplitude + delta))
    }

    private nonisolated static func noiseSample(
        event: AudioManifest.Event,
        localTime: Double,
        sampleRate: Double,
        seed: UInt64
    ) -> Double {
        let clockHz = max(1, min(event.frequencyHz ?? 4_096, sampleRate * 0.45))
        let stepPosition = localTime * clockHz
        let stepIndex = Int(stepPosition.rounded(.down))
        let nextIndex = stepIndex + 1
        let mix = stepPosition - floor(stepPosition)

        let current = heldNoiseValue(
            stepIndex: stepIndex,
            seed: seed,
            shortMode: event.noiseShortMode ?? false
        )
        let next = heldNoiseValue(
            stepIndex: nextIndex,
            seed: seed,
            shortMode: event.noiseShortMode ?? false
        )

        // Short interpolation removes the worst edge aliasing without blurring the attack.
        return current + ((next - current) * mix * 0.2)
    }

    private nonisolated static func heldNoiseValue(stepIndex: Int, seed: UInt64, shortMode: Bool) -> Double {
        let effectiveIndex = shortMode ? (stepIndex & 0x7f) : stepIndex
        var hash = seed &+ (UInt64(truncatingIfNeeded: effectiveIndex) &* 1_103_515_245)
        hash ^= hash >> 15
        hash &*= 0xD168_AAAD
        let bipolar = (Double(hash & 0xffff) / 32_767.5) - 1

        guard shortMode else { return bipolar }
        let metallicPulse = ((effectiveIndex >> 1) & 1) == 0 ? 0.35 : -0.35
        return max(-1, min(1, (bipolar * 0.65) + metallicPulse))
    }

    private nonisolated static func waveTableSample(_ waveSamples: [Double]?, localTime: Double, frequency: Double) -> Double {
        guard let waveSamples, waveSamples.isEmpty == false else {
            return sin(2 * .pi * localTime * frequency)
        }
        let phase = (localTime * frequency).truncatingRemainder(dividingBy: 1)
        let position = phase * Double(waveSamples.count)
        let lowerIndex = Int(position) % waveSamples.count
        let upperIndex = (lowerIndex + 1) % waveSamples.count
        let fraction = position - floor(position)
        let lowerValue = waveSamples[lowerIndex]
        let upperValue = waveSamples[upperIndex]
        return lowerValue + ((upperValue - lowerValue) * fraction)
    }

    private nonisolated static func normalize(samples: UnsafeMutablePointer<Float>, frameCount: Int) {
        var peak: Float = 0
        for index in 0..<frameCount {
            peak = max(peak, abs(samples[index]))
        }
        guard peak > 0.95 else { return }
        let scale = 0.95 / peak
        for index in 0..<frameCount {
            samples[index] *= scale
        }
    }
}
