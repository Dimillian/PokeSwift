import Foundation

extension GameRuntime {
    func requestTitleMusic() {
        requestAudio(trackID: content.audioManifest.titleTrackID, entryID: "default", reason: "title")
    }

    func requestDefaultMapMusic() {
        guard let musicID = currentMapManifest?.defaultMusicID else { return }
        requestAudio(trackID: musicID, entryID: "default", reason: "mapDefault")
    }

    func requestAudioCue(id: String, reason: String = "scriptOverride") {
        guard let cue = content.audioCue(id: id) else { return }
        requestAudio(trackID: cue.trackID, entryID: cue.entryID, reason: reason)
    }

    func playAudioCue(id: String, reason: String, completion: (() -> Void)? = nil) {
        guard let cue = content.audioCue(id: id) else {
            completion?()
            return
        }
        playOneShotAudio(trackID: cue.trackID, entryID: cue.entryID, reason: reason, completion: completion)
    }

    func requestTrainerBattleMusic() {
        requestAudioCue(id: "trainer_battle", reason: "battle")
    }

    func requestRivalExitMusic() {
        requestAudioCue(id: "rival_exit", reason: "scriptOverride")
    }

    func stopAllMusic() {
        audioPlayer?.stopAllMusic()
        currentAudioState = nil
    }

    private func requestAudio(trackID: String, entryID: String, reason: String) {
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
        audioPlayer?.play(request: .init(trackID: trackID, entryID: entryID), completion: nil)
    }

    private func playOneShotAudio(trackID: String, entryID: String, reason: String, completion: (() -> Void)? = nil) {
        let nextRevision = (currentAudioState?.playbackRevision ?? 0) + 1
        currentAudioState = RuntimeAudioState(
            trackID: trackID,
            entryID: entryID,
            reason: reason,
            playbackRevision: nextRevision
        )

        guard let audioPlayer else {
            completion?()
            return
        }

        audioPlayer.play(request: .init(trackID: trackID, entryID: entryID)) {
            completion?()
        }
    }
}
