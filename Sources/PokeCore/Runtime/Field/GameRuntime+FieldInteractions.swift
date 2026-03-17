import Foundation
import PokeDataModel

extension GameRuntime {
    func startFieldInteraction(id: String, completionAction: DialogueState.CompletionAction) {
        guard let interaction = content.fieldInteraction(id: id) else {
            enterSettledFieldState()
            return
        }

        clearTransientInteractionState()
        fieldHealingState = nil

        switch interaction.kind {
        case .pokemonCenterHealing:
            showDialogue(
                id: interaction.introDialogueID,
                completion: .showDialogue(
                    dialogueID: interaction.prompt.dialogueID,
                    completionAction: .fieldPrompt(
                        interactionID: interaction.id,
                        completionAction: completionAction
                    )
                )
            )
        case .dialogueChoice:
            showDialogue(
                id: interaction.introDialogueID,
                completion: .showDialogue(
                    dialogueID: interaction.prompt.dialogueID,
                    completionAction: .fieldPrompt(
                        interactionID: interaction.id,
                        completionAction: completionAction
                    )
                )
            )
        case .paidAdmission:
            guard let paidAdmission = interaction.paidAdmission else {
                enterSettledFieldState()
                return
            }

            if hasFlag(paidAdmission.successFlagID) {
                showDialogue(id: interaction.successDialogueID, completion: completionAction)
                return
            }

            showDialogue(
                id: interaction.introDialogueID,
                completion: .fieldPrompt(
                    interactionID: interaction.id,
                    completionAction: completionAction
                )
            )
        }
    }

    func handleFieldPrompt(button: RuntimeButton) {
        guard var promptState = fieldPromptState else {
            fieldPromptState = nil
            scriptItemPromptState = nil
            scriptChoicePromptState = nil
            return
        }

        if let scriptItemPromptState {
            switch button {
            case .left, .right, .up, .down:
                promptState.focusedIndex = promptState.focusedIndex == 0 ? 1 : 0
                fieldPromptState = promptState
            case .cancel:
                playUIConfirmSound()
                resolveScriptItemPromptSelection(accepted: false, promptState: scriptItemPromptState)
            case .confirm, .start:
                playUIConfirmSound()
                resolveScriptItemPromptSelection(accepted: promptState.focusedIndex == 0, promptState: scriptItemPromptState)
            }
            return
        }

        if let scriptChoicePromptState {
            switch button {
            case .left, .right, .up, .down:
                promptState.focusedIndex = promptState.focusedIndex == 0 ? 1 : 0
                fieldPromptState = promptState
            case .cancel:
                playUIConfirmSound()
                resolveScriptChoicePromptSelection(accepted: false, promptState: scriptChoicePromptState)
            case .confirm, .start:
                playUIConfirmSound()
                resolveScriptChoicePromptSelection(accepted: promptState.focusedIndex == 0, promptState: scriptChoicePromptState)
            }
            return
        }

        guard let interaction = content.fieldInteraction(id: promptState.interactionID) else {
            fieldPromptState = nil
            return
        }

        switch button {
        case .left, .right, .up, .down:
            promptState.focusedIndex = promptState.focusedIndex == 0 ? 1 : 0
            fieldPromptState = promptState
        case .cancel:
            playUIConfirmSound()
            resolveFieldPromptSelection(accepted: false, promptState: promptState, interaction: interaction)
        case .confirm, .start:
            playUIConfirmSound()
            resolveFieldPromptSelection(accepted: promptState.focusedIndex == 0, promptState: promptState, interaction: interaction)
        }
    }

    private func resolveScriptItemPromptSelection(
        accepted: Bool,
        promptState: RuntimeScriptItemPromptState
    ) {
        clearTransientInteractionState()
        enterSettledFieldState()

        guard accepted else {
            finishScript()
            return
        }

        guard var gameplayState else {
            finishScript()
            return
        }

        let itemID = promptState.itemID
        guard addItem(itemID, quantity: 1, to: &gameplayState) else {
            finishScript()
            if let failureDialogueID = promptState.failureDialogueID {
                showDialogue(id: failureDialogueID, completion: .returnToField)
            }
            return
        }

        if let objectID = promptState.targetObjectID {
            ensureObjectStateExists(objectID, in: &gameplayState)
            gameplayState.objectStates[objectID]?.visible = false
        }
        if let successFlagID = promptState.successFlagID {
            gameplayState.activeFlags.insert(successFlagID)
        }
        self.gameplayState = gameplayState
        traceScriptInventoryAddition(itemID: itemID, quantity: 1, gameplayState: gameplayState)

        let itemDisplayName = content.item(id: itemID)?.displayName ?? itemID
        showDialogue(
            id: promptState.successDialogueID,
            replacements: ["wStringBuffer": itemDisplayName],
            completion: .continueScript
        )
    }

    private func resolveScriptChoicePromptSelection(
        accepted: Bool,
        promptState: RuntimeScriptChoicePromptState
    ) {
        clearTransientInteractionState()

        if accepted {
            scene = .scriptedSequence
            runActiveScript()
            return
        }

        enterSettledFieldState()
        if let failureDialogueID = promptState.failureDialogueID {
            showDialogue(id: failureDialogueID, completion: .continueScript)
        } else {
            scene = .scriptedSequence
            runActiveScript()
        }
    }

    private func resolveFieldPromptSelection(
        accepted: Bool,
        promptState: RuntimeFieldPromptState,
        interaction: FieldInteractionManifest
    ) {
        clearTransientInteractionState()
        enterSettledFieldState()

        switch interaction.kind {
        case .pokemonCenterHealing:
            if accepted {
                showDialogue(
                    id: interaction.acceptedDialogueID,
                    completion: .startFieldHealing(
                        interactionID: interaction.id,
                        completionAction: promptState.completionAction
                    )
                )
                return
            }

            if let declinedDialogueID = interaction.declinedDialogueID {
                showDialogue(
                    id: declinedDialogueID,
                    completion: .showDialogue(
                        dialogueID: interaction.farewellDialogueID,
                        completionAction: promptState.completionAction
                    )
                )
                return
            }

            showDialogue(id: interaction.farewellDialogueID, completion: promptState.completionAction)
        case .dialogueChoice:
            if accepted {
                showDialogue(
                    id: interaction.acceptedDialogueID,
                    completion: .showDialogue(
                        dialogueID: interaction.successDialogueID,
                        completionAction: promptState.completionAction
                    )
                )
                return
            }

            if let declinedDialogueID = interaction.declinedDialogueID {
                showDialogue(id: declinedDialogueID, completion: promptState.completionAction)
                return
            }

            showDialogue(id: interaction.farewellDialogueID, completion: promptState.completionAction)
        case .paidAdmission:
            resolvePaidAdmissionPromptSelection(
                accepted: accepted,
                promptState: promptState,
                interaction: interaction
            )
        }
    }

    func startFieldHealing(interactionID: String, completionAction: DialogueState.CompletionAction) {
        guard let interaction = content.fieldInteraction(id: interactionID),
              let healing = interaction.healingSequence else {
            enterSettledFieldState()
            return
        }

        clearHeldFieldDirections()
        recordBlackoutCheckpoint(healing.blackoutCheckpoint)
        fieldInteractionTask?.cancel()

        let originalFacing: FacingDirection?
        if let nurseObjectID = healing.nurseObjectID {
            originalFacing = gameplayState?.objectStates[nurseObjectID]?.facing ?? currentMapObjectManifest(id: nurseObjectID)?.facing
            setObjectFacing(nurseObjectID, to: .right)
        } else {
            originalFacing = nil
        }

        fieldHealingState = RuntimeFieldHealingState(
            interactionID: interaction.id,
            nurseObjectID: healing.nurseObjectID,
            originalFacing: originalFacing,
            completionAction: completionAction,
            phase: .priming,
            activeBallCount: 0,
            totalBallCount: max(1, gameplayState?.playerParty.count ?? 0),
            pulseStep: 0
        )
        scene = .field
        substate = "field_interaction_\(interaction.id)"
        publishSnapshot()

        fieldInteractionTask = Task { [weak self] in
            await self?.runPokemonCenterHealingSequence(interaction: interaction, healing: healing)
        }
    }

    func fieldPromptOptions(for kind: FieldPromptKind) -> [String] {
        switch kind {
        case .yesNo:
            return ["YES", "NO"]
        }
    }

    private func runPokemonCenterHealingSequence(
        interaction: FieldInteractionManifest,
        healing: FieldHealingSequenceManifest
    ) async {
        defer {
            fieldInteractionTask = nil
        }

        let initialDelay = validationMode || isTestEnvironment ? 0.02 : (3.0 / 60.0)
        let pulseDelay = validationMode || isTestEnvironment ? 0.03 : 0.5

        await sleep(seconds: initialDelay)
        guard Task.isCancelled == false else { return }

        audioPlayer?.stopAllMusic()

        let totalBallCount = max(1, gameplayState?.playerParty.count ?? fieldHealingState?.totalBallCount ?? 1)
        for index in 0..<totalBallCount {
            guard Task.isCancelled == false else { return }
            if var state = fieldHealingState {
                state.phase = .machineActive
                state.activeBallCount = index + 1
                state.pulseStep += 1
                fieldHealingState = state
            }
            publishSnapshot()
            _ = playSoundEffect(id: healing.machineSoundEffectID, reason: "pokemonCenterHealing")
            await sleep(seconds: pulseDelay)
        }

        guard Task.isCancelled == false else { return }

        healParty()
        if var state = fieldHealingState {
            state.phase = .healedJingle
            state.activeBallCount = totalBallCount
            state.pulseStep += 1
            fieldHealingState = state
        }
        publishSnapshot()

        playAudioCue(id: healing.healedAudioCueID, reason: "pokemonCenterHealing") { [weak self] in
            guard let self else { return }
            self.finishPokemonCenterHealing(interaction: interaction)
        }
    }

    private func finishPokemonCenterHealing(interaction: FieldInteractionManifest) {
        let completionAction = fieldHealingState?.completionAction ?? .returnToField
        if let nurseObjectID = fieldHealingState?.nurseObjectID,
           let originalFacing = fieldHealingState?.originalFacing {
            setObjectFacing(nurseObjectID, to: originalFacing)
        }
        fieldHealingState = nil
        enterSettledFieldState()
        showDialogue(
            id: interaction.successDialogueID,
            completion: .showDialogue(
                dialogueID: interaction.farewellDialogueID,
                completionAction: completionAction
            )
        )
    }

    private func recordBlackoutCheckpoint(_ checkpoint: BlackoutCheckpointManifest?) {
        guard let checkpoint, var gameplayState else { return }
        gameplayState.blackoutCheckpoint = checkpoint
        self.gameplayState = gameplayState
    }

    private func resolvePaidAdmissionPromptSelection(
        accepted: Bool,
        promptState: RuntimeFieldPromptState,
        interaction: FieldInteractionManifest
    ) {
        guard let paidAdmission = interaction.paidAdmission else {
            showDialogue(id: interaction.farewellDialogueID, completion: promptState.completionAction)
            return
        }

        let deniedDialogueID = interaction.declinedDialogueID ?? interaction.farewellDialogueID
        let deniedCompletion = paidAdmission.deniedExitPath.isEmpty
            ? promptState.completionAction
            : .beginScriptedMovement(path: paidAdmission.deniedExitPath)

        guard accepted else {
            showDialogue(id: deniedDialogueID, completion: deniedCompletion)
            return
        }

        guard var gameplayState else {
            showDialogue(id: deniedDialogueID, completion: deniedCompletion)
            return
        }

        guard canAfford(paidAdmission.price, gameplayState: gameplayState) else {
            showDialogue(
                id: paidAdmission.insufficientFundsDialogueID,
                completion: .showDialogue(
                    dialogueID: deniedDialogueID,
                    completionAction: deniedCompletion
                )
            )
            return
        }

        guard spendMoney(paidAdmission.price, from: &gameplayState) else {
            showDialogue(
                id: paidAdmission.insufficientFundsDialogueID,
                completion: .showDialogue(
                    dialogueID: deniedDialogueID,
                    completionAction: deniedCompletion
                )
            )
            return
        }

        gameplayState.activeFlags.insert(paidAdmission.successFlagID)
        self.gameplayState = gameplayState

        if let purchaseSoundEffectID = paidAdmission.purchaseSoundEffectID {
            _ = playSoundEffect(id: purchaseSoundEffectID, reason: "paidAdmission")
        }

        showDialogue(id: interaction.acceptedDialogueID, completion: promptState.completionAction)
    }

    private func setObjectFacing(_ objectID: String, to facing: FacingDirection) {
        guard var gameplayState else { return }
        if let objectState = gameplayState.objectStates[objectID] {
            var updated = objectState
            updated.facing = facing
            gameplayState.objectStates[objectID] = updated
        } else if let object = currentMapObjectManifest(id: objectID) {
            gameplayState.objectStates[objectID] = .init(
                position: object.position,
                facing: facing,
                visible: object.visibleByDefault
            )
        }
        self.gameplayState = gameplayState
    }
}
