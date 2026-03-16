import AVFAudio
import Foundation
import PokeDataModel

@MainActor
public final class PokeAudioService: RuntimeAudioPlaying {
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
    private var musicRenderCache: [String: PokeAudioRenderedAsset] = [:]
    private var soundEffectRenderCache: [String: PokeAudioRenderedAsset] = [:]
    private var rendersInFlight: Set<String> = []
    private var pendingMusicPlayback: PendingMusicPlayback?
    private var pendingSoundEffectPlayback: [Int: PendingSoundEffectPlayback] = [:]
    private var activeSoundEffectsByHardwareChannel: [Int: ActiveSoundEffectChannelState] = [:]
    private var musicCompletionWorkItem: DispatchWorkItem?
    private var soundEffectCompletionWorkItems: [Int: DispatchWorkItem] = [:]
    private var playbackRequestID = 0
    private var activeMusicRequestID = 0

    public init(manifest: AudioManifest) {
        self.manifest = manifest
        configureEngineGraph()
        startEngineIfPossible()
        primeMusicEntryIfPossible(trackID: manifest.titleTrackID, entryID: "default")
        prewarmMusicManifest()
    }

    public func playMusic(request: MusicPlaybackRequest, completion: (@MainActor () -> Void)?) {
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

    public func playSFX(
        request: SoundEffectPlaybackRequest,
        completion: (@MainActor () -> Void)?
    ) -> SoundEffectPlaybackResult {
        guard let soundEffect = manifest.soundEffects.first(where: { $0.id == request.soundEffectID }) else {
            completion?()
            return .init(soundEffectID: request.soundEffectID, status: .rejected)
        }

        let requestedHardwareChannels = Array(
            Set(soundEffect.requestedChannels.compactMap(PokeAudioRenderer.hardwareChannelIndex(forSoftwareChannel:)))
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

    public func stopAllMusic() {
        playbackRequestID += 1
        activeMusicRequestID = playbackRequestID
        pendingMusicPlayback = nil
        musicCompletionWorkItem?.cancel()
        stopMusicPlayers()
    }

    private func configureEngineGraph() {
        engine.attach(musicMixerNode)
        engine.attach(soundEffectMixerNode)
        engine.connect(musicMixerNode, to: engine.mainMixerNode, format: format)
        engine.connect(soundEffectMixerNode, to: engine.mainMixerNode, format: format)

        attach(players: musicPlayers, to: musicMixerNode)
        attach(players: soundEffectPlayers, to: soundEffectMixerNode)

        musicMixerNode.outputVolume = PokeAudioMixDefaults.musicVolume
        soundEffectMixerNode.outputVolume = PokeAudioMixDefaults.soundEffectVolume
        engine.mainMixerNode.outputVolume = PokeAudioMixDefaults.masterVolume
    }

    private func attach(players: [AVAudioPlayerNode], to mixer: AVAudioMixerNode) {
        for player in players {
            engine.attach(player)
            engine.connect(player, to: mixer, format: format)
        }
    }

    private func startEngineIfPossible() {
        try? engine.start()
    }

    private func ensureEngineRunning() {
        if engine.isRunning == false {
            startEngineIfPossible()
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
                scheduleMusicRenderIfNeeded(
                    cacheKey: musicCacheKey(trackID: track.id, entryID: entry.id),
                    entry: entry
                )
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
        musicRenderCache[cacheKey] = PokeAudioRenderer.renderedAudioAsset(
            playbackMode: entry.playbackMode,
            channels: entry.channels,
            sampleRate: format.sampleRate,
            options: .music
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
            let rendered = PokeAudioRenderer.renderedAudioAsset(
                playbackMode: entry.playbackMode,
                channels: entry.channels,
                sampleRate: sampleRate,
                options: .music
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
            let rendered = PokeAudioRenderer.renderedAudioAsset(
                playbackMode: .oneShot,
                channels: channels,
                sampleRate: sampleRate,
                options: .soundEffect,
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
        _ rendered: PokeAudioRenderedAsset,
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
        _ rendered: PokeAudioRenderedAsset,
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
}
