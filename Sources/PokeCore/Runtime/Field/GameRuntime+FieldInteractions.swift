import Foundation
import PokeDataModel

extension GameRuntime {
    func startFieldInteraction(id: String, completionAction: DialogueState.CompletionAction) {
        guard let interaction = content.fieldInteraction(id: id) else {
            scene = .field
            substate = "field"
            return
        }

        fieldPromptState = nil
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
        }
    }

    func handleFieldPrompt(button: RuntimeButton) {
        guard var promptState = fieldPromptState,
              let interaction = content.fieldInteraction(id: promptState.interactionID) else {
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

    private func resolveFieldPromptSelection(
        accepted: Bool,
        promptState: RuntimeFieldPromptState,
        interaction: FieldInteractionManifest
    ) {
        fieldPromptState = nil
        dialogueState = nil
        isDialogueAudioBlockingInput = false
        scene = .field
        substate = "field"

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
    }

    func startFieldHealing(interactionID: String, completionAction: DialogueState.CompletionAction) {
        guard let interaction = content.fieldInteraction(id: interactionID),
              let healing = interaction.healingSequence else {
            scene = .field
            substate = "field"
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
        scene = .field
        substate = "field"
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
