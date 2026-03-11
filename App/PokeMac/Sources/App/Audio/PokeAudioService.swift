import AVFAudio
import Foundation
import PokeCore
import PokeDataModel

@MainActor
final class PokeAudioService: RuntimeAudioPlaying {
    private struct RenderedChannelBuffers: @unchecked Sendable {
        let prelude: AVAudioPCMBuffer?
        let loop: AVAudioPCMBuffer?
        let duration: Double
    }

    private struct RenderedAudioAsset: @unchecked Sendable {
        let channels: [Int: RenderedChannelBuffers]
        let playbackMode: AudioManifest.PlaybackMode
        let maxDuration: Double
    }

    private struct PendingMusicPlayback {
        let requestID: Int
        let cacheKey: String
        let playbackMode: AudioManifest.PlaybackMode
        let completion: (@MainActor () -> Void)?
    }

    private struct PendingSoundEffectPlayback {
        let requestID: Int
        let cacheKey: String
        let soundEffectID: String
        let order: Int
        let requestedHardwareChannels: [Int]
        let replacedSoundEffectID: String?
        let completion: (@MainActor () -> Void)?
    }

    private struct ActiveSoundEffectChannelState {
        let requestID: Int
        let soundEffectID: String
        let order: Int
    }

    private let manifest: AudioManifest
    private let engine = AVAudioEngine()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private let renderQueue = DispatchQueue(
        label: "com.dimillian.PokeSwift.audio-render",
        qos: .userInitiated,
        attributes: .concurrent
    )
    private let musicPlayers = (0..<4).map { _ in AVAudioPlayerNode() }
    private let soundEffectPlayers = (0..<4).map { _ in AVAudioPlayerNode() }
    private var musicRenderCache: [String: RenderedAudioAsset] = [:]
    private var soundEffectRenderCache: [String: RenderedAudioAsset] = [:]
    private var rendersInFlight: Set<String> = []
    private var pendingMusicPlayback: PendingMusicPlayback?
    private var pendingSoundEffectPlayback: [Int: PendingSoundEffectPlayback] = [:]
    private var activeSoundEffectsByHardwareChannel: [Int: ActiveSoundEffectChannelState] = [:]
    private var musicCompletionWorkItem: DispatchWorkItem?
    private var soundEffectCompletionWorkItems: [Int: DispatchWorkItem] = [:]
    private var playbackRequestID = 0

    init(manifest: AudioManifest) {
        self.manifest = manifest
        for player in musicPlayers + soundEffectPlayers {
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
        }
        engine.mainMixerNode.outputVolume = 0.6
        try? engine.start()
        primeMusicEntryIfPossible(trackID: manifest.titleTrackID, entryID: "default")
        prewarmMusicManifest()
    }

    func playMusic(request: MusicPlaybackRequest, completion: (@MainActor () -> Void)?) {
        guard let track = manifest.tracks.first(where: { $0.id == request.trackID }),
              let entry = track.entries.first(where: { $0.id == request.entryID }) else {
            completion?()
            return
        }

        ensureEngineRunning()
        stopMusicPlayers()

        let cacheKey = musicCacheKey(trackID: request.trackID, entryID: request.entryID)
        playbackRequestID += 1
        let requestID = playbackRequestID

        if let rendered = musicRenderCache[cacheKey] {
            pendingMusicPlayback = nil
            startMusicPlayback(
                rendered,
                cacheKey: cacheKey,
                playbackMode: entry.playbackMode,
                completion: completion
            )
            return
        }

        pendingMusicPlayback = PendingMusicPlayback(
            requestID: requestID,
            cacheKey: cacheKey,
            playbackMode: entry.playbackMode,
            completion: completion
        )
        scheduleMusicRenderIfNeeded(cacheKey: cacheKey, entry: entry)
    }

    func playSFX(
        request: SoundEffectPlaybackRequest,
        completion: (@MainActor () -> Void)?
    ) -> SoundEffectPlaybackResult {
        guard let soundEffect = manifest.soundEffects.first(where: { $0.id == request.soundEffectID }) else {
            completion?()
            return .init(soundEffectID: request.soundEffectID, status: .rejected)
        }

        let requestedHardwareChannels = Array(
            Set(soundEffect.requestedChannels.compactMap(Self.hardwareChannelIndex(forSoftwareChannel:)))
        ).sorted()
        let conflictingStates = requestedHardwareChannels.compactMap { activeSoundEffectsByHardwareChannel[$0] }
        if conflictingStates.contains(where: { soundEffect.order > $0.order }) {
            completion?()
            return .init(soundEffectID: request.soundEffectID, status: .rejected)
        }

        let replacedID = conflictingStates.map(\.soundEffectID).first
        ensureEngineRunning()
        playbackRequestID += 1
        let requestID = playbackRequestID
        let cacheKey = soundEffectCacheKey(request: request)

        if let rendered = soundEffectRenderCache[cacheKey] {
            startSoundEffectPlayback(
                rendered,
                requestID: requestID,
                soundEffectID: soundEffect.id,
                order: soundEffect.order,
                requestedHardwareChannels: requestedHardwareChannels,
                replacedSoundEffectID: replacedID,
                completion: completion
            )
            return .init(soundEffectID: request.soundEffectID, status: .started, replacedSoundEffectID: replacedID)
        }

        pendingSoundEffectPlayback[requestID] = PendingSoundEffectPlayback(
            requestID: requestID,
            cacheKey: cacheKey,
            soundEffectID: soundEffect.id,
            order: soundEffect.order,
            requestedHardwareChannels: requestedHardwareChannels,
            replacedSoundEffectID: replacedID,
            completion: completion
        )
        scheduleSoundEffectRenderIfNeeded(cacheKey: cacheKey, soundEffect: soundEffect)
        return .init(soundEffectID: request.soundEffectID, status: .started, replacedSoundEffectID: replacedID)
    }

    func stopAllMusic() {
        playbackRequestID += 1
        pendingMusicPlayback = nil
        musicCompletionWorkItem?.cancel()
        stopMusicPlayers()
    }

    private func ensureEngineRunning() {
        if engine.isRunning == false {
            try? engine.start()
        }
    }

    private func stopMusicPlayers() {
        for player in musicPlayers {
            player.stop()
            player.reset()
            player.volume = 1
        }
    }

    private func prewarmMusicManifest() {
        for track in manifest.tracks {
            for entry in track.entries {
                scheduleMusicRenderIfNeeded(cacheKey: musicCacheKey(trackID: track.id, entryID: entry.id), entry: entry)
            }
        }
    }

    private func primeMusicEntryIfPossible(trackID: String, entryID: String) {
        guard let track = manifest.tracks.first(where: { $0.id == trackID }),
              let entry = track.entries.first(where: { $0.id == entryID }) else {
            return
        }
        let cacheKey = musicCacheKey(trackID: trackID, entryID: entryID)
        guard musicRenderCache[cacheKey] == nil else { return }
        musicRenderCache[cacheKey] = Self.renderedAudioAsset(
            playbackMode: entry.playbackMode,
            channels: entry.channels,
            sampleRate: format.sampleRate
        )
    }

    private func musicCacheKey(trackID: String, entryID: String) -> String {
        "music:\(trackID):\(entryID)"
    }

    private func soundEffectCacheKey(request: SoundEffectPlaybackRequest) -> String {
        "sfx:\(request.soundEffectID):\(request.frequencyModifier ?? -1):\(request.tempoModifier ?? -1)"
    }

    private func scheduleMusicRenderIfNeeded(cacheKey: String, entry: AudioManifest.Entry) {
        guard musicRenderCache[cacheKey] == nil, rendersInFlight.contains(cacheKey) == false else { return }
        rendersInFlight.insert(cacheKey)

        let sampleRate = format.sampleRate
        renderQueue.async { [entry] in
            let rendered = Self.renderedAudioAsset(
                playbackMode: entry.playbackMode,
                channels: entry.channels,
                sampleRate: sampleRate
            )
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.rendersInFlight.remove(cacheKey)
                self.musicRenderCache[cacheKey] = rendered

                guard let pendingMusicPlayback = self.pendingMusicPlayback,
                      pendingMusicPlayback.requestID == self.playbackRequestID,
                      pendingMusicPlayback.cacheKey == cacheKey else {
                    return
                }

                self.pendingMusicPlayback = nil
                self.startMusicPlayback(
                    rendered,
                    cacheKey: cacheKey,
                    playbackMode: pendingMusicPlayback.playbackMode,
                    completion: pendingMusicPlayback.completion
                )
            }
        }
    }

    private func scheduleSoundEffectRenderIfNeeded(cacheKey: String, soundEffect: AudioManifest.SoundEffect) {
        guard soundEffectRenderCache[cacheKey] == nil, rendersInFlight.contains(cacheKey) == false else { return }
        rendersInFlight.insert(cacheKey)

        let sampleRate = format.sampleRate
        renderQueue.async { [channels = soundEffect.channels] in
            let rendered = Self.renderedAudioAsset(
                playbackMode: .oneShot,
                channels: channels,
                sampleRate: sampleRate
            )
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.rendersInFlight.remove(cacheKey)
                self.soundEffectRenderCache[cacheKey] = rendered

                let pending = self.pendingSoundEffectPlayback.values.filter { $0.cacheKey == cacheKey }
                for request in pending.sorted(by: { $0.requestID < $1.requestID }) {
                    self.pendingSoundEffectPlayback.removeValue(forKey: request.requestID)
                    self.startSoundEffectPlayback(
                        rendered,
                        requestID: request.requestID,
                        soundEffectID: request.soundEffectID,
                        order: request.order,
                        requestedHardwareChannels: request.requestedHardwareChannels,
                        replacedSoundEffectID: request.replacedSoundEffectID,
                        completion: request.completion
                    )
                }
            }
        }
    }

    private func startMusicPlayback(
        _ rendered: RenderedAudioAsset,
        cacheKey: String,
        playbackMode: AudioManifest.PlaybackMode,
        completion: (@MainActor () -> Void)?
    ) {
        musicCompletionWorkItem?.cancel()

        for hardwareChannel in 0..<4 {
            guard let buffers = rendered.channels[hardwareChannel] else { continue }
            let player = musicPlayers[hardwareChannel]
            switch playbackMode {
            case .looping:
                if let prelude = buffers.prelude, prelude.frameLength > 0 {
                    player.scheduleBuffer(prelude) { [weak self] in
                        Task { @MainActor [weak self] in
                            guard let self,
                                  let loop = self.musicRenderCache[cacheKey]?.channels[hardwareChannel]?.loop,
                                  loop.frameLength > 0 else {
                                return
                            }
                            self.musicPlayers[hardwareChannel].scheduleBuffer(loop, at: nil, options: [.loops])
                            if self.musicPlayers[hardwareChannel].isPlaying == false {
                                self.musicPlayers[hardwareChannel].play()
                            }
                        }
                    }
                } else if let loop = buffers.loop, loop.frameLength > 0 {
                    player.scheduleBuffer(loop, at: nil, options: [.loops])
                }
            case .oneShot:
                if let prelude = buffers.prelude {
                    player.scheduleBuffer(prelude)
                }
            }

            if player.isPlaying == false {
                player.play()
            }
        }

        if playbackMode == .oneShot, let completion {
            let workItem = DispatchWorkItem { completion() }
            musicCompletionWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + rendered.maxDuration, execute: workItem)
        }
    }

    private func startSoundEffectPlayback(
        _ rendered: RenderedAudioAsset,
        requestID: Int,
        soundEffectID: String,
        order: Int,
        requestedHardwareChannels: [Int],
        replacedSoundEffectID: String?,
        completion: (@MainActor () -> Void)?
    ) {
        var maxDuration = 0.0

        for hardwareChannel in requestedHardwareChannels {
            soundEffectCompletionWorkItems[hardwareChannel]?.cancel()
            soundEffectCompletionWorkItems[hardwareChannel] = nil

            let player = soundEffectPlayers[hardwareChannel]
            player.stop()
            player.reset()
            activeSoundEffectsByHardwareChannel[hardwareChannel] = .init(
                requestID: requestID,
                soundEffectID: soundEffectID,
                order: order
            )

            if let buffers = rendered.channels[hardwareChannel] {
                maxDuration = max(maxDuration, buffers.duration)
                if buffers.duration > 0 {
                    musicPlayers[hardwareChannel].volume = 0
                }
                if let prelude = buffers.prelude {
                    player.scheduleBuffer(prelude)
                    player.play()
                }

                let workItem = DispatchWorkItem { [weak self] in
                    guard let self,
                          self.activeSoundEffectsByHardwareChannel[hardwareChannel]?.requestID == requestID else {
                        return
                    }
                    self.activeSoundEffectsByHardwareChannel.removeValue(forKey: hardwareChannel)
                    self.musicPlayers[hardwareChannel].volume = 1
                    self.soundEffectCompletionWorkItems[hardwareChannel] = nil
                }
                soundEffectCompletionWorkItems[hardwareChannel] = workItem
                DispatchQueue.main.asyncAfter(deadline: .now() + buffers.duration, execute: workItem)
            } else {
                activeSoundEffectsByHardwareChannel.removeValue(forKey: hardwareChannel)
            }
        }

        if let completion {
            let completionDelay = max(0.0, maxDuration)
            DispatchQueue.main.asyncAfter(deadline: .now() + completionDelay) {
                completion()
            }
        }

        _ = replacedSoundEffectID
    }

    nonisolated private static func renderedAudioAsset(
        playbackMode: AudioManifest.PlaybackMode,
        channels: [AudioManifest.ChannelProgram],
        sampleRate: Double
    ) -> RenderedAudioAsset {
        var renderedChannels: [Int: RenderedChannelBuffers] = [:]
        var maxDuration = 0.0

        for channel in channels {
            let hardwareChannel = hardwareChannelIndex(forSoftwareChannel: channel.channelNumber)
                ?? max(0, min(3, channel.channelNumber - 1))
            let preludeSamples = renderSegment(events: channel.prelude, sampleRate: sampleRate, seed: UInt64(channel.channelNumber * 7919))
            let loopSamples = renderSegment(events: channel.loop, sampleRate: sampleRate, seed: UInt64(channel.channelNumber * 7919))
            let preludeDuration = renderedDuration(for: channel.prelude)
            let loopDuration = renderedDuration(for: channel.loop)
            let duration = max(preludeDuration, loopDuration)
            maxDuration = max(maxDuration, duration)
            renderedChannels[hardwareChannel] = RenderedChannelBuffers(
                prelude: makeBuffer(from: preludeSamples, sampleRate: sampleRate),
                loop: makeBuffer(from: loopSamples, sampleRate: sampleRate),
                duration: duration
            )
        }

        return RenderedAudioAsset(
            channels: renderedChannels,
            playbackMode: playbackMode,
            maxDuration: maxDuration
        )
    }

    nonisolated private static func hardwareChannelIndex(forSoftwareChannel channelNumber: Int) -> Int? {
        switch channelNumber {
        case 1, 5:
            return 0
        case 2, 6:
            return 1
        case 3, 7:
            return 2
        case 4, 8:
            return 3
        default:
            return nil
        }
    }

    nonisolated private static func makeBuffer(from samples: [Float]?, sampleRate: Double) -> AVAudioPCMBuffer? {
        guard let samples, samples.isEmpty == false,
              let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)),
              let channelData = buffer.floatChannelData?[0] else {
            return nil
        }
        buffer.frameLength = AVAudioFrameCount(samples.count)
        samples.withUnsafeBufferPointer { source in
            channelData.update(from: source.baseAddress!, count: source.count)
        }
        return buffer
    }

    nonisolated private static func renderSegment(
        events: [AudioManifest.Event],
        sampleRate: Double,
        seed: UInt64
    ) -> [Float]? {
        let totalDuration = renderedDuration(for: events)
        guard totalDuration > 0 else { return nil }
        let frameCount = max(1, Int(ceil(totalDuration * sampleRate)))
        var samples = Array(repeating: Float.zero, count: frameCount)

        samples.withUnsafeMutableBufferPointer { buffer in
            guard let baseAddress = buffer.baseAddress else { return }
            for event in events {
                render(
                    event: event,
                    into: baseAddress,
                    frameCount: frameCount,
                    sampleRate: sampleRate,
                    seed: seed
                )
            }
            normalize(samples: baseAddress, frameCount: frameCount)
        }

        return samples
    }

    nonisolated private static func renderedDuration(for events: [AudioManifest.Event]) -> Double {
        events.map { $0.startTime + $0.duration }.max() ?? 0
    }

    nonisolated private static func render(
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

    nonisolated private static func modulatedFrequency(for event: AudioManifest.Event, localTime: Double) -> Double {
        let baseFrequency = pitchSlideAdjustedFrequency(
            baseFrequency: event.frequencyHz ?? 440,
            event: event,
            localTime: localTime
        )
        return vibratoAdjustedFrequency(baseFrequency: baseFrequency, event: event, localTime: localTime)
    }

    nonisolated private static func pitchSlideAdjustedFrequency(
        baseFrequency: Double,
        event: AudioManifest.Event,
        localTime: Double
    ) -> Double {
        guard let startRegister = event.frequencyRegister,
              let targetRegister = event.pitchSlideTargetRegister,
              let pitchSlideFrameCount = event.pitchSlideFrameCount,
              pitchSlideFrameCount > 0 else {
            return baseFrequency
        }
        let elapsedFrames = max(0, Int((localTime * 60).rounded(.down)))
        let appliedFrames = min(pitchSlideFrameCount, elapsedFrames)
        let registerDelta = targetRegister - startRegister
        let currentRegister: Int
        if appliedFrames >= pitchSlideFrameCount {
            currentRegister = targetRegister
        } else {
            currentRegister = startRegister + Int(
                (Double(registerDelta) * Double(appliedFrames)) / Double(pitchSlideFrameCount)
            )
        }
        return frequencyHz(forRegister: currentRegister, waveform: event.waveform)
    }

    nonisolated private static func vibratoAdjustedFrequency(baseFrequency: Double, event: AudioManifest.Event, localTime: Double) -> Double {
        guard event.vibratoDepthSemitones > 0, event.vibratoRateHz > 0 else { return baseFrequency }
        guard localTime >= event.vibratoDelaySeconds else { return baseFrequency }
        let semitoneOffset = sin(2 * .pi * localTime * event.vibratoRateHz) * event.vibratoDepthSemitones
        return baseFrequency * pow(2, semitoneOffset / 12)
    }

    nonisolated private static func envelopeAdjustedAmplitude(for event: AudioManifest.Event, localTime: Double) -> Double {
        guard let stepDuration = event.envelopeStepDuration, event.envelopeDirection != 0 else {
            return event.amplitude
        }
        let steps = Int(localTime / stepDuration)
        let delta = Double(event.envelopeDirection * steps) / 15
        return max(0, min(1, event.amplitude + delta))
    }

    nonisolated private static func noiseSample(
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

        return current + ((next - current) * mix * 0.2)
    }

    nonisolated private static func heldNoiseValue(stepIndex: Int, seed: UInt64, shortMode: Bool) -> Double {
        let effectiveIndex = shortMode ? (stepIndex & 0x7f) : stepIndex
        var hash = seed &+ (UInt64(truncatingIfNeeded: effectiveIndex) &* 1_103_515_245)
        hash ^= hash >> 15
        hash &*= 0xD168_AAAD
        let bipolar = (Double(hash & 0xffff) / 32_767.5) - 1

        guard shortMode else { return bipolar }
        let metallicPulse = ((effectiveIndex >> 1) & 1) == 0 ? 0.35 : -0.35
        return max(-1, min(1, (bipolar * 0.65) + metallicPulse))
    }

    nonisolated private static func waveTableSample(_ waveSamples: [Double]?, localTime: Double, frequency: Double) -> Double {
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

    nonisolated private static func normalize(samples: UnsafeMutablePointer<Float>, frameCount: Int) {
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

    nonisolated private static func frequencyHz(forRegister hardwareRegister: Int, waveform: AudioManifest.Waveform) -> Double {
        let frequencyBits = hardwareRegister & 0x07ff
        let denominator = 2048 - frequencyBits
        guard denominator > 0 else { return 440 }
        let numerator: Double = waveform == .wave ? 65_536 : 131_072
        return numerator / Double(denominator)
    }
}
