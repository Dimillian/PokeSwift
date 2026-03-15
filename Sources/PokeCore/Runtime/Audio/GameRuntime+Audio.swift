import Foundation
import PokeDataModel

extension GameRuntime {
    public func toggleMusicEnabled() {
        setMusicEnabled(isMusicEnabled == false)
    }

    public func setMusicEnabled(_ enabled: Bool) {
        guard isMusicEnabled != enabled else { return }
        isMusicEnabled = enabled

        if enabled {
            if let currentAudioState {
                audioPlayer?.playMusic(
                    request: .init(trackID: currentAudioState.trackID, entryID: currentAudioState.entryID),
                    completion: nil
                )
            }
        } else {
            audioPlayer?.stopAllMusic()
        }

        publishSnapshot()
    }

    func requestTitleMusic() {
        requestMusic(trackID: content.audioManifest.titleTrackID, entryID: "default", reason: "title")
    }

    func requestDefaultMapMusic() {
        guard let musicID = currentMapManifest?.defaultMusicID else { return }
        requestMusic(trackID: musicID, entryID: "default", reason: "mapDefault")
    }

    func requestAudioCue(id: String, reason: String = "scriptOverride") {
        guard let cue = content.audioCue(id: id) else { return }
        if cue.waitForCompletion || cue.resumeMusicAfterCompletion {
            playAudioCue(id: id, reason: reason)
            return
        }

        switch cue.assetKind {
        case .music:
            requestMusic(trackID: cue.assetID, entryID: cue.entryID, reason: reason)
        case .soundEffect:
            _ = playSoundEffect(id: cue.assetID, reason: reason)
        }
    }

    func playAudioCue(id: String, reason: String, completion: (() -> Void)? = nil) {
        guard let cue = content.audioCue(id: id) else {
            completion?()
            return
        }

        let resumeAudioState = cue.resumeMusicAfterCompletion ? currentAudioState : nil
        let playbackCompletion: (() -> Void)? = cue.waitForCompletion || cue.resumeMusicAfterCompletion || completion != nil ? { [weak self] in
            guard let self else {
                completion?()
                return
            }
            if let resumeAudioState {
                self.requestMusic(
                    trackID: resumeAudioState.trackID,
                    entryID: resumeAudioState.entryID,
                    reason: resumeAudioState.reason
                )
            }
            completion?()
        } : nil

        switch cue.assetKind {
        case .music:
            if playbackCompletion == nil {
                requestMusic(trackID: cue.assetID, entryID: cue.entryID, reason: reason)
                return
            }
            playOneShotMusic(trackID: cue.assetID, entryID: cue.entryID, reason: reason, completion: playbackCompletion)
        case .soundEffect:
            _ = playSoundEffect(id: cue.assetID, reason: reason, completion: playbackCompletion)
        }
    }

    func requestTrainerBattleMusic() {
        requestAudioCue(id: "trainer_battle", reason: "battle")
    }

    func requestTrainerVictoryMusic(reason: String = "battleVictory") {
        requestAudioCue(id: "trainer_victory", reason: reason)
    }

    func requestWildVictoryMusic(reason: String = "battleVictory") {
        requestAudioCue(id: "wild_victory", reason: reason)
    }

    func requestTrainerEncounterMusic(for battleID: String) {
        guard let cueID = content.trainerEncounterAudioCueID(for: battleID) else { return }
        requestAudioCue(id: cueID, reason: "trainerEncounter")
    }

    func requestRivalExitMusic() {
        requestAudioCue(id: "rival_exit", reason: "scriptOverride")
    }

    func stopAllMusic() {
        audioPlayer?.stopAllMusic()
        currentAudioState = nil
    }

    func playUIConfirmSound() {
        _ = playSoundEffect(id: "SFX_PRESS_AB", reason: "uiConfirm")
    }

    func playCollisionSoundIfNeeded() {
        guard collisionSoundInFlight == false else { return }
        let result = playSoundEffect(id: "SFX_COLLISION", reason: "blockedMovement") { [weak self] in
            self?.collisionSoundInFlight = false
        }
        collisionSoundInFlight = result.status == .started
    }

    func battleSoundEffectRequest(
        id: String,
        frequencyModifier: Int? = nil,
        tempoModifier: Int? = nil
    ) -> SoundEffectPlaybackRequest? {
        guard content.soundEffect(id: id) != nil else { return nil }
        return .init(
            soundEffectID: id,
            frequencyModifier: frequencyModifier,
            tempoModifier: tempoModifier
        )
    }

    func speciesCrySoundEffectRequest(
        speciesID: String,
        frequencyModifier: Int? = nil,
        tempoModifier: Int? = nil
    ) -> SoundEffectPlaybackRequest? {
        guard let species = content.species(id: speciesID),
              let soundEffectID = species.crySoundEffectID else {
            return nil
        }

        return battleSoundEffectRequest(
            id: soundEffectID,
            frequencyModifier: frequencyModifier ?? species.cryPitch,
            tempoModifier: tempoModifier ?? species.cryLength
        )
    }

    func sendOutSoundEffectRequests(
        side: BattlePresentationSide,
        speciesID: String
    ) -> [RuntimeStagedSoundEffectRequest] {
        var requests: [RuntimeStagedSoundEffectRequest] = []

        if let poofRequest = battleSoundEffectRequest(id: "SFX_BALL_POOF") {
            requests.append(
                RuntimeStagedSoundEffectRequest(
                    delay: BattleSendOutAnimationTiming.poofSoundDelay,
                    request: poofRequest
                )
            )
        }

        if let cryRequest = speciesCrySoundEffectRequest(speciesID: speciesID) {
            requests.append(
                RuntimeStagedSoundEffectRequest(
                    delay: BattleSendOutAnimationTiming.crySoundDelay(for: side),
                    request: cryRequest
                )
            )
        }

        return requests
    }

    func enemyFaintSoundEffectRequests() -> [SoundEffectPlaybackRequest] {
        ["SFX_FAINT_FALL", "SFX_FAINT_THUD"].compactMap { battleSoundEffectRequest(id: $0) }
    }

    func moveSoundEffectRequest(
        for move: MoveManifest,
        attackerSpeciesID: String
    ) -> SoundEffectPlaybackRequest? {
        guard let battleAudio = move.battleAudio else { return nil }
        switch battleAudio.kind {
        case .soundEffect:
            guard let soundEffectID = battleAudio.soundEffectID else { return nil }
            return battleSoundEffectRequest(
                id: soundEffectID,
                frequencyModifier: battleAudio.frequencyModifier,
                tempoModifier: battleAudio.tempoModifier
            )
        case .cry:
            return speciesCrySoundEffectRequest(
                speciesID: attackerSpeciesID,
                frequencyModifier: battleAudio.frequencyModifier,
                tempoModifier: battleAudio.tempoModifier
            )
        }
    }

    func applyingHitSoundEffectRequest(typeMultiplier: Int) -> SoundEffectPlaybackRequest? {
        let soundEffectID: String
        let frequencyModifier: Int
        let tempoModifier: Int
        switch typeMultiplier {
        case Int.min..<1:
            return nil
        case 1..<10:
            soundEffectID = "SFX_NOT_VERY_EFFECTIVE"
            frequencyModifier = 0x50
            tempoModifier = 0x01
        case 11...Int.max:
            soundEffectID = "SFX_SUPER_EFFECTIVE"
            frequencyModifier = 0xE0
            tempoModifier = 0xFF
        default:
            soundEffectID = "SFX_DAMAGE"
            frequencyModifier = 0x20
            tempoModifier = 0x30
        }

        return battleSoundEffectRequest(
            id: soundEffectID,
            frequencyModifier: frequencyModifier,
            tempoModifier: tempoModifier
        )
    }

    @discardableResult
    func playMoveAudio(for move: MoveManifest, attackerSpeciesID: String, reason: String = "battleMove") -> SoundEffectPlaybackResult? {
        guard let request = moveSoundEffectRequest(for: move, attackerSpeciesID: attackerSpeciesID) else { return nil }
        return playSoundEffect(request, reason: reason)
    }

    func executeDialoguePageEventsIfNeeded() {
        guard let dialogueState,
              let dialogue = currentDialogueManifest,
              dialogue.pages.indices.contains(dialogueState.pageIndex) else {
            isDialogueAudioBlockingInput = false
            return
        }

        let pageEvents = dialogue.pages[dialogueState.pageIndex].events
        guard pageEvents.isEmpty == false else {
            isDialogueAudioBlockingInput = false
            return
        }

        dialogueAudioRevision += 1
        let revision = dialogueAudioRevision
        isDialogueAudioBlockingInput = pageEvents.contains(where: \.waitForCompletion)
        executeDialoguePageEvent(pageEvents, at: 0, revision: revision)
    }

    private func executeDialoguePageEvent(_ events: [DialogueEvent], at index: Int, revision: Int) {
        guard index < events.count else {
            if dialogueAudioRevision == revision {
                isDialogueAudioBlockingInput = false
            }
            return
        }

        let event = events[index]
        let completion: (() -> Void)? = event.waitForCompletion ? { [weak self] in
            guard let self, self.dialogueAudioRevision == revision else { return }
            self.executeDialoguePageEvent(events, at: index + 1, revision: revision)
        } : nil

        switch event.kind {
        case .soundEffect:
            if let soundEffectID = event.soundEffectID {
                _ = playSoundEffect(id: soundEffectID, reason: "dialogueCommand", completion: completion)
            } else {
                completion?()
            }
        case .cry:
            if let speciesID = event.speciesID,
               let request = speciesCrySoundEffectRequest(speciesID: speciesID) {
                _ = playSoundEffect(request, reason: "dialogueCommand", completion: completion)
            } else {
                completion?()
            }
        }

        if event.waitForCompletion == false {
            executeDialoguePageEvent(events, at: index + 1, revision: revision)
        }
    }

    private func requestMusic(trackID: String, entryID: String, reason: String) {
        if let currentAudioState, currentAudioState.trackID == trackID, currentAudioState.entryID == entryID {
            if currentAudioState.reason != reason {
                self.currentAudioState = RuntimeAudioState(
                    trackID: currentAudioState.trackID,
                    entryID: currentAudioState.entryID,
                    reason: reason,
                    playbackRevision: currentAudioState.playbackRevision
                )
            }
            return
        }

        let nextRevision = (currentAudioState?.playbackRevision ?? 0) + 1
        currentAudioState = RuntimeAudioState(
            trackID: trackID,
            entryID: entryID,
            reason: reason,
            playbackRevision: nextRevision
        )
        guard isMusicEnabled else { return }
        audioPlayer?.playMusic(request: .init(trackID: trackID, entryID: entryID), completion: nil)
    }

    func restoreAudioState(_ state: RuntimeAudioState, reason: String) {
        requestMusic(trackID: state.trackID, entryID: state.entryID, reason: reason)
    }

    private func playOneShotMusic(trackID: String, entryID: String, reason: String, completion: (() -> Void)? = nil) {
        let nextRevision = (currentAudioState?.playbackRevision ?? 0) + 1
        currentAudioState = RuntimeAudioState(
            trackID: trackID,
            entryID: entryID,
            reason: reason,
            playbackRevision: nextRevision
        )

        guard isMusicEnabled else {
            completion?()
            return
        }

        guard let audioPlayer else {
            completion?()
            return
        }

        audioPlayer.playMusic(request: .init(trackID: trackID, entryID: entryID)) {
            completion?()
        }
    }

    @discardableResult
    func playSoundEffect(
        _ request: SoundEffectPlaybackRequest,
        reason: String,
        completion: (() -> Void)? = nil
    ) -> SoundEffectPlaybackResult {
        playSoundEffect(
            id: request.soundEffectID,
            reason: reason,
            frequencyModifier: request.frequencyModifier,
            tempoModifier: request.tempoModifier,
            completion: completion
        )
    }

    @discardableResult
    func playSoundEffect(
        id: String,
        reason: String,
        frequencyModifier: Int? = nil,
        tempoModifier: Int? = nil,
        completion: (() -> Void)? = nil
    ) -> SoundEffectPlaybackResult {
        let revision = (recentSoundEffects.first?.playbackRevision ?? 0) + 1
        guard content.soundEffect(id: id) != nil else {
            let result = SoundEffectPlaybackResult(soundEffectID: id, status: .rejected)
            recordSoundEffect(result, reason: reason, revision: revision)
            completion?()
            return result
        }

        guard let audioPlayer else {
            let result = SoundEffectPlaybackResult(soundEffectID: id, status: .started)
            recordSoundEffect(result, reason: reason, revision: revision)
            completion?()
            return result
        }

        let request = SoundEffectPlaybackRequest(
            soundEffectID: id,
            frequencyModifier: frequencyModifier,
            tempoModifier: tempoModifier
        )
        let result: SoundEffectPlaybackResult
        if let completion {
            result = audioPlayer.playSFX(request: request) {
                completion()
            }
        } else {
            result = audioPlayer.playSFX(request: request, completion: nil)
        }
        recordSoundEffect(result, reason: reason, revision: revision)
        if result.status == .rejected {
            completion?()
        }
        return result
    }

    private func recordSoundEffect(_ result: SoundEffectPlaybackResult, reason: String, revision: Int) {
        recentSoundEffects.insert(
            RuntimeSoundEffectState(
                soundEffectID: result.soundEffectID,
                reason: reason,
                playbackRevision: revision,
                status: result.status == .started ? .started : .rejected,
                replacedSoundEffectID: result.replacedSoundEffectID
            ),
            at: 0
        )
        if recentSoundEffects.count > 8 {
            recentSoundEffects.removeLast(recentSoundEffects.count - 8)
        }
    }
}
