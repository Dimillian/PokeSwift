import AVFAudio
import Foundation
import PokeCore
import PokeDataModel

@MainActor
final class PokeAudioService: RuntimeAudioPlaying {
    private enum MixDefaults {
        static let masterVolume: Float = 0.6
        static let musicVolume: Float = 0.4
        static let soundEffectVolume: Float = 1.0
        static let renderedSampleGain: Float = 0.16
    }

    private struct RenderedChannelBuffers: @unchecked Sendable {
        let prelude: AVAudioPCMBuffer?
        let loop: AVAudioPCMBuffer?
        let duration: Double
    }

    private struct RenderedSamples {
        var left: [Float]
        var right: [Float]
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
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2)!
    private let musicMixerNode = AVAudioMixerNode()
    private let soundEffectMixerNode = AVAudioMixerNode()
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
    private var activeMusicRequestID = 0

    init(manifest: AudioManifest) {
        self.manifest = manifest
        engine.attach(musicMixerNode)
        engine.attach(soundEffectMixerNode)
        engine.connect(musicMixerNode, to: engine.mainMixerNode, format: format)
        engine.connect(soundEffectMixerNode, to: engine.mainMixerNode, format: format)

        for player in musicPlayers {
            engine.attach(player)
            engine.connect(player, to: musicMixerNode, format: format)
        }
        for player in soundEffectPlayers {
            engine.attach(player)
            engine.connect(player, to: soundEffectMixerNode, format: format)
        }

        musicMixerNode.outputVolume = MixDefaults.musicVolume
        soundEffectMixerNode.outputVolume = MixDefaults.soundEffectVolume
        engine.mainMixerNode.outputVolume = MixDefaults.masterVolume
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
        activeMusicRequestID = requestID

        if let rendered = musicRenderCache[cacheKey] {
            pendingMusicPlayback = nil
            startMusicPlayback(
                rendered,
                requestID: requestID,
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
        scheduleSoundEffectRenderIfNeeded(
            cacheKey: cacheKey,
            soundEffect: soundEffect,
            request: request
        )
        return .init(soundEffectID: request.soundEffectID, status: .started, replacedSoundEffectID: replacedID)
    }

    func stopAllMusic() {
        playbackRequestID += 1
        activeMusicRequestID = playbackRequestID
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
                    requestID: pendingMusicPlayback.requestID,
                    cacheKey: cacheKey,
                    playbackMode: pendingMusicPlayback.playbackMode,
                    completion: pendingMusicPlayback.completion
                )
            }
        }
    }

    private func scheduleSoundEffectRenderIfNeeded(
        cacheKey: String,
        soundEffect: AudioManifest.SoundEffect,
        request: SoundEffectPlaybackRequest
    ) {
        guard soundEffectRenderCache[cacheKey] == nil, rendersInFlight.contains(cacheKey) == false else { return }
        rendersInFlight.insert(cacheKey)

        let sampleRate = format.sampleRate
        renderQueue.async { [channels = soundEffect.channels, request] in
            let rendered = Self.renderedAudioAsset(
                playbackMode: .oneShot,
                channels: channels,
                sampleRate: sampleRate,
                soundEffectRequest: request
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
        requestID: Int,
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
                                  self.activeMusicRequestID == requestID,
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
        sampleRate: Double,
        soundEffectRequest: SoundEffectPlaybackRequest? = nil
    ) -> RenderedAudioAsset {
        var renderedChannels: [Int: RenderedChannelBuffers] = [:]
        var maxDuration = 0.0

        for channel in channels {
            let hardwareChannel = hardwareChannelIndex(forSoftwareChannel: channel.channelNumber)
                ?? max(0, min(3, channel.channelNumber - 1))
            let preludeEvents = adjusted(
                events: channel.prelude,
                for: soundEffectRequest,
                channelNumber: channel.channelNumber
            )
            let loopEvents = adjusted(
                events: channel.loop,
                for: soundEffectRequest,
                channelNumber: channel.channelNumber
            )
            let preludeSamples = renderSegment(
                events: preludeEvents,
                sampleRate: sampleRate,
                seed: UInt64(channel.channelNumber * 7919)
            )
            let loopSamples = renderSegment(
                events: loopEvents,
                sampleRate: sampleRate,
                seed: UInt64(channel.channelNumber * 7919)
            )
            let preludeDuration = renderedDuration(for: preludeEvents)
            let loopDuration = renderedDuration(for: loopEvents)
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

    nonisolated private static func adjusted(
        events: [AudioManifest.Event],
        for request: SoundEffectPlaybackRequest?,
        channelNumber: Int
    ) -> [AudioManifest.Event] {
        guard let request else { return events }
        let tempoScale = tempoScale(for: request.tempoModifier, channelNumber: channelNumber)
        return events.map {
            adjusted(
                event: $0,
                frequencyModifier: request.frequencyModifier,
                tempoScale: tempoScale
            )
        }
    }

    nonisolated private static func adjusted(
        event: AudioManifest.Event,
        frequencyModifier: Int?,
        tempoScale: Double
    ) -> AudioManifest.Event {
        let adjustedRegister = adjustedFrequencyRegister(
            event.frequencyRegister,
            modifier: frequencyModifier
        )
        let adjustedTargetRegister = adjustedFrequencyRegister(
            event.pitchSlideTargetRegister,
            modifier: frequencyModifier
        )
        let adjustedFrequencyHz = adjustedRegister.map {
            frequencyHz(forRegister: $0, waveform: event.waveform)
        } ?? event.frequencyHz
        let adjustedTargetHz = adjustedTargetRegister.map {
            frequencyHz(forRegister: $0, waveform: event.waveform)
        } ?? event.pitchSlideTargetHz

        return .init(
            startTime: event.startTime * tempoScale,
            duration: event.duration * tempoScale,
            frequencyHz: adjustedFrequencyHz,
            frequencyRegister: adjustedRegister,
            amplitude: event.amplitude,
            dutyCycle: event.dutyCycle,
            dutyCyclePattern: event.dutyCyclePattern,
            dutyCyclePatternStepOffset: event.dutyCyclePatternStepOffset,
            envelopeStepDuration: event.envelopeStepDuration,
            envelopeDirection: event.envelopeDirection,
            waveSamples: event.waveSamples,
            stereoLeftEnabled: event.stereoLeftEnabled,
            stereoRightEnabled: event.stereoRightEnabled,
            vibratoDelaySeconds: event.vibratoDelaySeconds,
            vibratoDepthSemitones: event.vibratoDepthSemitones,
            vibratoRateHz: event.vibratoRateHz,
            vibratoDelayFrames: event.vibratoDelayFrames,
            vibratoExtentUp: event.vibratoExtentUp,
            vibratoExtentDown: event.vibratoExtentDown,
            vibratoRateFrames: event.vibratoRateFrames,
            pitchSlideTargetHz: adjustedTargetHz,
            pitchSlideTargetRegister: adjustedTargetRegister,
            pitchSlideFrameCount: event.pitchSlideFrameCount,
            noiseShortMode: event.noiseShortMode,
            waveform: event.waveform
        )
    }

    nonisolated private static func adjustedFrequencyRegister(
        _ register: Int?,
        modifier: Int?
    ) -> Int? {
        guard let register, let modifier else { return register }
        let lowByte = register & 0xff
        let highByte = register & 0x700
        let summedLowByte = lowByte + (modifier & 0xff)
        let adjustedHighByte = min(0x700, highByte + ((summedLowByte >> 8) << 8))
        return adjustedHighByte | (summedLowByte & 0xff)
    }

    nonisolated private static func tempoScale(
        for modifier: Int?,
        channelNumber: Int
    ) -> Double {
        guard let modifier else { return 1 }
        guard channelNumber != 8 else { return 1 }
        return Double(0x80 + (modifier & 0xff)) / Double(0x100)
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

    nonisolated private static func makeBuffer(from samples: RenderedSamples?, sampleRate: Double) -> AVAudioPCMBuffer? {
        guard let samples,
              samples.left.isEmpty == false,
              samples.left.count == samples.right.count,
              let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.left.count)),
              let leftChannelData = buffer.floatChannelData?[0],
              let rightChannelData = buffer.floatChannelData?[1] else {
            return nil
        }
        buffer.frameLength = AVAudioFrameCount(samples.left.count)
        samples.left.withUnsafeBufferPointer { source in
            leftChannelData.update(from: source.baseAddress!, count: source.count)
        }
        samples.right.withUnsafeBufferPointer { source in
            rightChannelData.update(from: source.baseAddress!, count: source.count)
        }
        return buffer
    }

    nonisolated private static func renderSegment(
        events: [AudioManifest.Event],
        sampleRate: Double,
        seed: UInt64
    ) -> RenderedSamples? {
        let totalDuration = renderedDuration(for: events)
        guard totalDuration > 0 else { return nil }
        let frameCount = max(1, Int(ceil(totalDuration * sampleRate)))
        var leftSamples = Array(repeating: Float.zero, count: frameCount)
        var rightSamples = Array(repeating: Float.zero, count: frameCount)

        leftSamples.withUnsafeMutableBufferPointer { leftBuffer in
            guard let leftBaseAddress = leftBuffer.baseAddress else { return }
            rightSamples.withUnsafeMutableBufferPointer { rightBuffer in
                guard let rightBaseAddress = rightBuffer.baseAddress else { return }
                for event in events {
                    render(
                        event: event,
                        leftChannel: leftBaseAddress,
                        rightChannel: rightBaseAddress,
                        frameCount: frameCount,
                        sampleRate: sampleRate,
                        seed: seed
                    )
                }
            }
        }

        return RenderedSamples(left: leftSamples, right: rightSamples)
    }

    nonisolated private static func renderedDuration(for events: [AudioManifest.Event]) -> Double {
        events.map { $0.startTime + $0.duration }.max() ?? 0
    }

    nonisolated private static func render(
        event: AudioManifest.Event,
        leftChannel: UnsafeMutablePointer<Float>,
        rightChannel: UnsafeMutablePointer<Float>,
        frameCount: Int,
        sampleRate: Double,
        seed: UInt64
    ) {
        guard event.duration > 0 else { return }
        let startFrame = max(0, Int(event.startTime * sampleRate))
        let endFrame = min(frameCount, Int((event.startTime + event.duration) * sampleRate))
        guard endFrame > startFrame else { return }
        guard event.stereoLeftEnabled || event.stereoRightEnabled else { return }
        let declickFrames = max(1, Int(sampleRate * 0.00035))

        for frame in startFrame..<endFrame {
            let localTime = Double(frame - startFrame) / sampleRate
            let sampleValue: Double
            switch event.waveform {
            case .square:
                let frequency = modulatedFrequency(for: event, localTime: localTime)
                let phase = (localTime * frequency).truncatingRemainder(dividingBy: 1)
                sampleValue = phase < effectiveDutyCycle(for: event, localTime: localTime) ? 1 : -1
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
            let startDistance = frame - startFrame
            let endDistance = (endFrame - 1) - frame
            let edgeFrames = min(startDistance, endDistance)
            let declickEnvelope: Float
            if edgeFrames < declickFrames {
                declickEnvelope = Float(edgeFrames + 1) / Float(declickFrames + 1)
            } else {
                declickEnvelope = 1
            }

            let sample = Float(sampleValue * amplitude) * MixDefaults.renderedSampleGain * declickEnvelope
            if event.stereoLeftEnabled {
                leftChannel[frame] += sample
            }
            if event.stereoRightEnabled {
                rightChannel[frame] += sample
            }
        }
    }

    nonisolated private static func modulatedFrequency(for event: AudioManifest.Event, localTime: Double) -> Double {
        let pitchAdjustedRegister = pitchSlideAdjustedRegister(event: event, localTime: localTime)
        let baseFrequency = pitchAdjustedRegister.map {
            frequencyHz(forRegister: $0, waveform: event.waveform)
        } ?? event.frequencyHz ?? 440
        return vibratoAdjustedFrequency(
            baseFrequency: baseFrequency,
            frequencyRegister: pitchAdjustedRegister ?? event.frequencyRegister,
            event: event,
            localTime: localTime
        )
    }

    nonisolated private static func pitchSlideAdjustedRegister(
        event: AudioManifest.Event,
        localTime: Double
    ) -> Int? {
        guard let startRegister = event.frequencyRegister,
              let targetRegister = event.pitchSlideTargetRegister,
              let pitchSlideFrameCount = event.pitchSlideFrameCount,
              pitchSlideFrameCount > 0 else {
            return nil
        }
        let elapsedFrames = max(0, Int((localTime * 60).rounded(.down)))
        let appliedFrames = min(pitchSlideFrameCount, elapsedFrames)
        let registerDelta = targetRegister - startRegister
        if appliedFrames >= pitchSlideFrameCount {
            return targetRegister
        }
        return startRegister + Int(
            (Double(registerDelta) * Double(appliedFrames)) / Double(pitchSlideFrameCount)
        )
    }

    nonisolated private static func vibratoAdjustedFrequency(
        baseFrequency: Double,
        frequencyRegister: Int?,
        event: AudioManifest.Event,
        localTime: Double
    ) -> Double {
        if let adjustedRegister = gbVibratoAdjustedRegister(
            baseRegister: frequencyRegister,
            event: event,
            localTime: localTime
        ) {
            return frequencyHz(forRegister: adjustedRegister, waveform: event.waveform)
        }
        guard event.vibratoDepthSemitones > 0, event.vibratoRateHz > 0 else { return baseFrequency }
        guard localTime >= event.vibratoDelaySeconds else { return baseFrequency }
        let semitoneOffset = sin(2 * .pi * localTime * event.vibratoRateHz) * event.vibratoDepthSemitones
        return baseFrequency * pow(2, semitoneOffset / 12)
    }

    // Match the GB engine more closely by toggling low-byte register offsets instead
    // of applying a smooth sine-wave LFO to the note frequency.
    nonisolated private static func gbVibratoAdjustedRegister(
        baseRegister: Int?,
        event: AudioManifest.Event,
        localTime: Double
    ) -> Int? {
        guard let baseRegister else { return nil }
        guard event.vibratoExtentUp > 0 || event.vibratoExtentDown > 0 else { return nil }

        let elapsedFrames = max(0, Int((localTime * 60).rounded(.down)))
        guard elapsedFrames >= event.vibratoDelayFrames else { return baseRegister }

        let stepFrames = max(1, event.vibratoRateFrames + 1)
        let phase = (elapsedFrames - event.vibratoDelayFrames) / stepFrames
        let lowByte = baseRegister & 0xff
        let adjustedLowByte: Int
        if phase.isMultiple(of: 2) {
            adjustedLowByte = min(0xff, lowByte + event.vibratoExtentUp)
        } else {
            adjustedLowByte = max(0, lowByte - event.vibratoExtentDown)
        }

        return (baseRegister & 0x0700) | adjustedLowByte
    }

    nonisolated private static func envelopeAdjustedAmplitude(for event: AudioManifest.Event, localTime: Double) -> Double {
        guard let stepDuration = event.envelopeStepDuration, event.envelopeDirection != 0 else {
            return event.amplitude
        }
        let steps = Int(localTime / stepDuration)
        let delta = Double(event.envelopeDirection * steps) / 15
        return max(0, min(1, event.amplitude + delta))
    }

    nonisolated private static func effectiveDutyCycle(for event: AudioManifest.Event, localTime: Double) -> Double {
        guard let pattern = event.dutyCyclePattern else {
            return event.dutyCycle ?? 0.5
        }

        let elapsedFrames = max(0, Int((localTime * 60).rounded(.down)))
        let stepOffset = (event.dutyCyclePatternStepOffset + elapsedFrames) & 0x3
        let rotatedPattern = rotateDutyCyclePattern(pattern, stepOffset: stepOffset)
        return dutyCycle(forPatternValue: (rotatedPattern >> 6) & 0x3)
    }

    nonisolated private static func rotateDutyCyclePattern(_ pattern: Int, stepOffset: Int) -> Int {
        let rotation = (stepOffset & 0x3) * 2
        let byte = pattern & 0xff
        return ((byte << rotation) | (byte >> (8 - rotation))) & 0xff
    }

    nonisolated private static func dutyCycle(forPatternValue value: Int) -> Double {
        switch value {
        case 0: return 0.125
        case 1: return 0.25
        case 3: return 0.75
        default: return 0.5
        }
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
        return heldNoiseValue(
            stepIndex: stepIndex,
            seed: seed,
            shortMode: event.noiseShortMode ?? false
        )
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
        let sampleIndex = Int(position.rounded(.down)) % waveSamples.count
        return waveSamples[sampleIndex]
    }

    nonisolated private static func frequencyHz(forRegister hardwareRegister: Int, waveform: AudioManifest.Waveform) -> Double {
        let frequencyBits = hardwareRegister & 0x07ff
        let denominator = 2048 - frequencyBits
        guard denominator > 0 else { return 440 }
        let numerator: Double = waveform == .wave ? 65_536 : 131_072
        return numerator / Double(denominator)
    }
}
