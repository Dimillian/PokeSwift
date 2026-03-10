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
            showDialogue(id: dialogueID, completion: .returnToField)
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
            scene = .field
            substate = "field"
            return
        }
        dialogueState = DialogueState(dialogueID: dialogue.id, pageIndex: 0, completionAction: completion)
        scene = .dialogue
        substate = "dialogue_\(id)"
    }

    func queueDeferredActions(_ actions: [DeferredAction]) {
        guard actions.isEmpty == false else { return }
        deferredActions.append(contentsOf: actions)
    }

    func advanceDeferredQueueIfNeeded() {
        guard dialogueState == nil, scene == .field || scene == .scriptedSequence else {
            return
        }
        guard deferredActions.isEmpty == false else { return }

        let action = deferredActions.removeFirst()
        switch action {
        case let .dialogue(dialogueID):
            showDialogue(id: dialogueID, completion: .returnToField)
        case let .battle(battleID):
            startBattle(id: battleID)
        case .startLabIntro:
            if var gameplayState {
                gameplayState.objectStates["pallet_town_oak"]?.position = TilePoint(x: 12, y: 10)
                gameplayState.playerPosition = TilePoint(x: 12, y: 11)
                gameplayState.facing = .up
                gameplayState.mapID = "OAKS_LAB"
                gameplayState.activeFlags.insert("EVENT_FOLLOWED_OAK_INTO_LAB")
                gameplayState.activeFlags.insert("EVENT_FOLLOWED_OAK_INTO_LAB_2")
                self.gameplayState = gameplayState
            }
            runFallbackLabIntro()
        case let .hideObject(objectID):
            gameplayState?.objectStates[objectID]?.visible = false
            scene = .field
            substate = "field"
            return
        }
    }
}
