import Foundation
import PokeDataModel

extension GameRuntime {
    func handleDialogue(button: RuntimeButton) {
        guard button == .confirm || button == .start || button == .cancel,
              var dialogueState,
              let dialogue = content.dialogue(id: dialogueState.dialogueID) else {
            return
        }

        if dialogueState.pageIndex < dialogue.pages.count - 1 {
            dialogueState.pageIndex += 1
            self.dialogueState = dialogueState
            substate = "dialogue_\(dialogueState.dialogueID)"
            return
        }

        self.dialogueState = nil
        switch dialogueState.completionAction {
        case .returnToField:
            scene = .field
            substate = "field"
        case .continueScript:
            scene = .scriptedSequence
            runActiveScript()
        case let .healAndShow(dialogueID):
            healParty()
            playAudioCue(id: "mom_heal", reason: "jingle") { [weak self] in
                guard let self else { return }
                self.requestDefaultMapMusic()
                self.showDialogue(id: dialogueID, completion: .returnToField)
            }
        case let .openStarterChoice(preselectedSpeciesID):
            scene = .starterChoice
            substate = "starter_choice"
            starterChoiceFocusedIndex = max(0, starterChoiceOptions.firstIndex(where: { $0.id == preselectedSpeciesID }) ?? 0)
        case .beginPostChoiceSequence:
            scene = .field
            substate = "field"
            finalizeStarterChoiceSequence()
        case let .startPostBattleDialogue(won):
            scene = .field
            substate = "field"
            runPostBattleSequence(won: won)
        }
    }

    func handleStarterChoice(button: RuntimeButton) {
        guard starterChoiceOptions.isEmpty == false else { return }
        switch button {
        case .left, .up:
            starterChoiceFocusedIndex = (starterChoiceFocusedIndex - 1 + starterChoiceOptions.count) % starterChoiceOptions.count
        case .right, .down:
            starterChoiceFocusedIndex = (starterChoiceFocusedIndex + 1) % starterChoiceOptions.count
        case .confirm, .start:
            chooseStarter(speciesID: starterChoiceOptions[starterChoiceFocusedIndex].id)
        case .cancel:
            scene = .field
            substate = "field"
        }
    }

    func showDialogue(id: String, completion: DialogueState.CompletionAction) {
        guard let dialogue = content.dialogue(id: id) else {
            var details: [String: String] = [
                "failureKind": "missingDialogue",
                "missingDialogueID": id,
            ]
            if case .continueScript = completion {
                details["completionAction"] = "continueScript"
            }
            let message = "Missing dialogue content for \(id)."
            if gameplayState?.activeScriptID != nil {
                failActiveScript(message: message, details: details)
            } else {
                traceEvent(
                    .scriptFailed,
                    message,
                    mapID: gameplayState?.mapID,
                    dialogueID: id,
                    details: details
                )
                scene = .field
                substate = "field"
            }
            return
        }
        dialogueState = DialogueState(dialogueID: dialogue.id, pageIndex: 0, completionAction: completion)
        scene = .dialogue
        substate = "dialogue_\(id)"
        traceEvent(.dialogueStarted, "Started dialogue \(id).", mapID: gameplayState?.mapID, dialogueID: id)
    }

    func queueDeferredActions(_ actions: [DeferredAction]) {
        guard actions.isEmpty == false else { return }
        deferredActions.append(contentsOf: actions)
    }

    func advanceDeferredQueueIfNeeded() {
        guard dialogueState == nil, scene == .field || scene == .scriptedSequence else {
            return
        }
        while deferredActions.isEmpty == false, dialogueState == nil, scene == .field || scene == .scriptedSequence {
            let action = deferredActions.removeFirst()
            switch action {
            case let .dialogue(dialogueID):
                showDialogue(id: dialogueID, completion: .returnToField)
                return
            case let .battle(battleID):
                startBattle(id: battleID)
                return
            case let .script(scriptID):
                beginScript(id: scriptID)
                return
            case let .hideObject(objectID):
                gameplayState?.objectStates[objectID]?.visible = false
                scene = .field
                substate = "field"
            case .restoreMapMusic:
                requestDefaultMapMusic()
                scene = .field
                substate = "field"
            }
        }
    }
}
