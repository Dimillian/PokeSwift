import PokeDataModel

extension GameRuntime {
    func handleField(button: RuntimeButton) {
        if nicknameConfirmation != nil {
            handleNicknameConfirmation(button: button)
            return
        }
        if shopState != nil {
            handleShop(button: button)
            return
        }
        guard isFieldInputLocked == false else { return }
        clearFieldPartyReorderState()
        switch button {
        case .up:
            movePlayer(in: .up)
        case .down:
            movePlayer(in: .down)
        case .left:
            movePlayer(in: .left)
        case .right:
            movePlayer(in: .right)
        case .confirm, .start:
            playUIConfirmSound()
            interactAhead()
        case .cancel:
            break
        }
    }

    var preferredHeldFieldDirection: FacingDirection? {
        heldFieldDirections.last
    }

    var canContinueHeldFieldMovement: Bool {
        scene == .field &&
            dialogueState == nil &&
            fieldPromptState == nil &&
            nicknameConfirmation == nil &&
            shopState == nil &&
            fieldHealingState == nil &&
            fieldTransitionState == nil &&
            scriptedMovementTask == nil &&
            trainerEngagementTask == nil &&
            fieldInteractionTask == nil &&
            gameplayState?.activeScriptID == nil &&
            gameplayState?.battle == nil
    }

    func pressHeldFieldDirection(_ direction: FacingDirection) {
        heldFieldDirections.removeAll { $0 == direction }
        heldFieldDirections.append(direction)
        _ = consumeHeldFieldDirectionIfPossible()
    }

    func releaseHeldFieldDirection(_ direction: FacingDirection) {
        heldFieldDirections.removeAll { $0 == direction }
    }

    func clearHeldFieldDirections() {
        heldFieldDirections.removeAll()
    }

    @discardableResult
    func consumeHeldFieldDirectionIfPossible() -> Bool {
        guard canContinueHeldFieldMovement,
              isFieldInputLocked == false,
              let direction = preferredHeldFieldDirection else {
            return false
        }

        movePlayer(in: direction)
        return true
    }

    func movePlayer(in direction: FacingDirection) {
        guard isFieldInputLocked == false else { return }
        guard var gameplayState, let map = currentMapManifest else { return }
        gameplayState.facing = direction
        let currentPoint = gameplayState.playerPosition
        let nextPoint = translated(currentPoint, by: direction)
        guard let destination = resolveFieldStep(from: currentPoint, to: nextPoint, in: map, gameplayState: gameplayState, facing: direction) else {
            self.gameplayState = gameplayState
            evaluateMapScriptsIfNeeded(blockedMoveFacing: direction)
            guard scene == .field, dialogueState == nil, self.gameplayState?.activeScriptID == nil else {
                return
            }
            playCollisionSoundIfNeeded()
            substate = "blocked"
            return
        }

        let mapChanged = gameplayState.mapID != destination.map.id
        gameplayState.mapID = destination.map.id
        gameplayState.playerPosition = destination.point
        gameplayState.activeMapScriptTriggerID = nil
        gameplayState.totalStepCount += 1
        self.gameplayState = gameplayState
        if mapChanged {
            requestDefaultMapMusic()
        }
        if handleWarpIfNeeded() {
            return
        }
        beginFieldMovementCooldown()
        substate = "field"
        evaluateMapScriptsIfNeeded()
        if isReadyForFreeFieldStep {
            if evaluateTrainerSightIfNeeded() == false {
                evaluateWildEncounterIfNeeded()
            }
        }
    }

    func chooseStarter(speciesID: String) {
        scene = .field
        substate = "field"
        gameplayState?.pendingStarterSpeciesID = speciesID
        showDialogue(id: "oaks_lab_mon_energetic", completion: .beginPostChoiceNaming)
    }
}
