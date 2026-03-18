import Foundation

extension GameRuntime {
    func clearTransientInteractionState() {
        dialogueState = nil
        fieldPromptState = nil
        scriptItemPromptState = nil
        scriptChoicePromptState = nil
        fieldObstaclePromptState = nil
        isDialogueAudioBlockingInput = false
    }

    func enterSettledFieldState(
        restoreMapMusic: Bool = false,
        publishSnapshot shouldPublishSnapshot: Bool = false
    ) {
        scene = .field
        substate = "field"
        if restoreMapMusic {
            requestDefaultMapMusic()
        }
        if shouldPublishSnapshot {
            publishSnapshot()
        }
    }
}
