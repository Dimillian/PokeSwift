import Foundation
import PokeDataModel

extension GameRuntime {
    func resolvedDialogueLines(_ lines: [String], replacements: [String: String]) -> [String] {
        lines.map { line in
            let withPlaceholders = replacements.reduce(line) { partial, replacement in
                partial.replacingOccurrences(of: "{\(replacement.key)}", with: replacement.value)
            }
            return withPlaceholders
                .replacingOccurrences(of: "<PLAYER>", with: playerName)
                .replacingOccurrences(of: "<RIVAL>", with: gameplayState?.rivalName ?? "BLUE")
        }
    }

    func handleDialogue(button: RuntimeButton) {
        guard button == .confirm || button == .start || button == .cancel,
              var dialogueState,
              let dialogue = currentDialogueManifest,
              dialogue.pages.indices.contains(dialogueState.pageIndex) else {
            return
        }
        let isFinalPage = dialogueState.pageIndex == dialogue.pages.count - 1
        if case .fieldPrompt = dialogueState.completionAction, isFinalPage {
            handleFieldPrompt(button: button)
            return
        }
        if case .openScriptItemPrompt = dialogueState.completionAction, isFinalPage {
            handleFieldPrompt(button: button)
            return
        }
        if case .openScriptChoicePrompt = dialogueState.completionAction, isFinalPage {
            handleFieldPrompt(button: button)
            return
        }
        if case .openFieldObstaclePrompt = dialogueState.completionAction, isFinalPage {
            handleFieldPrompt(button: button)
            return
        }
        let currentPageHasBlockingEvents = dialogue.pages[dialogueState.pageIndex].events.contains(where: \.waitForCompletion)
        guard currentPageHasBlockingEvents == false || isDialogueAudioBlockingInput == false else {
            return
        }

        if dialogueTextFullyRevealed == false, isTestEnvironment == false {
            dialogueTextFullyRevealed = true
            return
        }

        playUIConfirmSound()

        if dialogueState.pageIndex < dialogue.pages.count - 1 {
            dialogueState.pageIndex += 1
            if isTestEnvironment == false {
                dialogueTextFullyRevealed = false
            }
            self.dialogueState = dialogueState
            substate = "dialogue_\(dialogueState.dialogueID)"
            executeDialoguePageEventsIfNeeded()
            return
        }

        clearTransientInteractionState()
        switch dialogueState.completionAction {
        case .returnToField:
            enterSettledFieldState()
        case .continueScript:
            scene = .scriptedSequence
            runActiveScript()
        case let .healAndShow(dialogueID):
            healParty()
            playAudioCue(id: "mom_heal", reason: "jingle") { [weak self] in
                guard let self else { return }
                self.showDialogue(id: dialogueID, completion: .returnToField)
            }
        case let .openStarterChoice(preselectedSpeciesID):
            scene = .starterChoice
            substate = "starter_choice"
            starterChoiceFocusedIndex = max(0, starterChoiceOptions.firstIndex(where: { $0.id == preselectedSpeciesID }) ?? 0)
        case .beginPostChoiceSequence:
            enterSettledFieldState()
            finalizeStarterChoiceSequence()
        case .beginPostChoiceNaming:
            guard let speciesID = gameplayState?.pendingStarterSpeciesID else {
                enterSettledFieldState()
                finalizeStarterChoiceSequence()
                return
            }
            let defaultName = content.species(id: speciesID)?.displayName ?? speciesID.capitalized
            enterSettledFieldState()
            beginNicknameConfirmation(
                speciesID: speciesID,
                defaultName: defaultName,
                completion: .returnToFieldAfterStarter
            )
        case let .finishTrainerBattle(won, preventsBlackoutOnLoss, postBattleScriptID, runsPostBattleScriptOnLoss, sourceTrainerObjectID):
            enterSettledFieldState()
            completeTrainerBattleDialogue(
                won: won,
                preventsBlackoutOnLoss: preventsBlackoutOnLoss,
                postBattleScriptID: postBattleScriptID,
                runsPostBattleScriptOnLoss: runsPostBattleScriptOnLoss,
                sourceTrainerObjectID: sourceTrainerObjectID
            )
        case let .startBattle(battleID, sourceTrainerObjectID):
            enterSettledFieldState()
            startBattle(id: battleID, sourceTrainerObjectID: sourceTrainerObjectID)
        case let .showDialogue(dialogueID, completionAction):
            enterSettledFieldState()
            showDialogue(id: dialogueID, completion: completionAction)
        case let .continueCaptureAftermath(aftermath):
            enterSettledFieldState()
            continueCaptureAftermath(aftermath)
        case let .fieldPrompt(interactionID, completionAction):
            scene = .dialogue
            substate = "dialogue_\(dialogue.id)_prompt"
            fieldPromptState = .init(
                interactionID: interactionID,
                kind: content.fieldInteraction(id: interactionID)?.prompt.kind ?? .yesNo,
                completionAction: completionAction,
                focusedIndex: 0
            )
        case let .openScriptItemPrompt(promptState):
            scene = .dialogue
            substate = "dialogue_\(dialogue.id)_prompt"
            scriptItemPromptState = promptState
            scriptChoicePromptState = nil
            fieldPromptState = .init(
                interactionID: promptState.promptID,
                kind: .yesNo,
                completionAction: .continueScript,
                focusedIndex: 0
            )
        case let .openScriptChoicePrompt(promptState):
            scene = .dialogue
            substate = "dialogue_\(dialogue.id)_prompt"
            scriptItemPromptState = nil
            scriptChoicePromptState = promptState
            fieldPromptState = .init(
                interactionID: promptState.promptID,
                kind: .yesNo,
                completionAction: .continueScript,
                focusedIndex: 0
            )
        case let .openFieldObstaclePrompt(promptState):
            scene = .dialogue
            substate = "dialogue_\(dialogue.id)_prompt"
            fieldObstaclePromptState = promptState
            fieldPromptState = .init(
                interactionID: promptState.obstacleID,
                kind: .yesNo,
                completionAction: .returnToField,
                focusedIndex: 0
            )
        case let .startFieldHealing(interactionID, completionAction):
            startFieldHealing(interactionID: interactionID, completionAction: completionAction)
        case let .beginScriptedMovement(path):
            enterSettledFieldState()
            beginScriptedPlayerMovement(path)
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
            playUIConfirmSound()
            chooseStarter(speciesID: starterChoiceOptions[starterChoiceFocusedIndex].id)
        case .cancel:
            playUIConfirmSound()
            scene = .field
            substate = "field"
        }
    }

    func showDialogue(
        id: String,
        replacements: [String: String] = [:],
        completion: DialogueState.CompletionAction
    ) {
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
                enterSettledFieldState()
            }
            return
        }
        if case let .fieldPrompt(interactionID, completionAction) = completion {
            fieldPromptState = .init(
                interactionID: interactionID,
                kind: content.fieldInteraction(id: interactionID)?.prompt.kind ?? .yesNo,
                completionAction: completionAction,
                focusedIndex: 0
            )
            scriptItemPromptState = nil
            scriptChoicePromptState = nil
        } else if case let .openScriptItemPrompt(promptState) = completion {
            scriptItemPromptState = promptState
            scriptChoicePromptState = nil
            fieldPromptState = .init(
                interactionID: promptState.promptID,
                kind: .yesNo,
                completionAction: .continueScript,
                focusedIndex: 0
            )
        } else if case let .openScriptChoicePrompt(promptState) = completion {
            scriptItemPromptState = nil
            scriptChoicePromptState = promptState
            fieldPromptState = .init(
                interactionID: promptState.promptID,
                kind: .yesNo,
                completionAction: .continueScript,
                focusedIndex: 0
            )
        } else if case let .openFieldObstaclePrompt(promptState) = completion {
            fieldObstaclePromptState = promptState
            scriptItemPromptState = nil
            scriptChoicePromptState = nil
            fieldPromptState = .init(
                interactionID: promptState.obstacleID,
                kind: .yesNo,
                completionAction: .returnToField,
                focusedIndex: 0
            )
        } else {
            fieldPromptState = nil
            scriptItemPromptState = nil
            scriptChoicePromptState = nil
            fieldObstaclePromptState = nil
        }
        if isTestEnvironment == false {
            dialogueTextFullyRevealed = false
        }
        dialogueState = DialogueState(
            dialogueID: dialogue.id,
            pages: nil,
            replacements: replacements,
            pageIndex: 0,
            completionAction: completion
        )
        scene = .dialogue
        substate = "dialogue_\(id)"
        executeDialoguePageEventsIfNeeded()
        traceEvent(.dialogueStarted, "Started dialogue \(id).", mapID: gameplayState?.mapID, dialogueID: id)
    }

    func showInlineDialogue(
        id: String,
        pages: [DialoguePage],
        completion: DialogueState.CompletionAction
    ) {
        clearTransientInteractionState()
        if case let .openFieldObstaclePrompt(promptState) = completion {
            fieldObstaclePromptState = promptState
            fieldPromptState = .init(
                interactionID: promptState.obstacleID,
                kind: .yesNo,
                completionAction: .returnToField,
                focusedIndex: 0
            )
        }
        if isTestEnvironment == false {
            dialogueTextFullyRevealed = false
        }
        dialogueState = DialogueState(
            dialogueID: id,
            pages: pages,
            replacements: [:],
            pageIndex: 0,
            completionAction: completion
        )
        scene = .dialogue
        substate = "dialogue_\(id)"
        executeDialoguePageEventsIfNeeded()
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
                if var gameplayState {
                    ensureObjectStateExists(objectID, in: &gameplayState)
                    gameplayState.objectStates[objectID]?.visible = false
                    self.gameplayState = gameplayState
                }
                enterSettledFieldState()
            case .restoreMapMusic:
                enterSettledFieldState(restoreMapMusic: true)
            }
        }
    }
}
