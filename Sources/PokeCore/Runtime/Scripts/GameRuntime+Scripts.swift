import Foundation
import PokeContent
import PokeDataModel

extension GameRuntime {
    var isReadyForFreeFieldStep: Bool {
        scene == .field && dialogueState == nil && gameplayState?.activeScriptID == nil
    }

    func evaluateMapScriptsIfNeeded(blockedMoveFacing: FacingDirection? = nil) {
        guard scene == .field, dialogueState == nil, let gameplayState else { return }
        guard let mapScript = content.mapScript(for: gameplayState.mapID) else {
            substate = "field"
            self.gameplayState?.activeMapScriptTriggerID = nil
            return
        }

        guard let trigger = mapScript.triggers.first(where: { conditionsMatch($0, blockedMoveFacing: blockedMoveFacing) }) else {
            self.gameplayState?.activeMapScriptTriggerID = nil
            substate = "field"
            return
        }

        self.gameplayState?.activeMapScriptTriggerID = trigger.id
        beginScript(id: trigger.scriptID)
    }

    func conditionsMatch(_ trigger: MapScriptTriggerManifest, blockedMoveFacing: FacingDirection?) -> Bool {
        trigger.conditions.allSatisfy { conditionMatches($0, blockedMoveFacing: blockedMoveFacing) }
    }

    func conditionMatches(_ condition: ScriptConditionManifest, blockedMoveFacing: FacingDirection?) -> Bool {
        switch condition.kind {
        case "flagSet":
            guard let flagID = condition.flagID else { return false }
            return hasFlag(flagID)
        case "flagUnset":
            guard let flagID = condition.flagID else { return false }
            return hasFlag(flagID) == false
        case "playerYEquals":
            guard let intValue = condition.intValue else { return false }
            return gameplayState?.playerPosition.y == intValue
        case "playerXEquals":
            guard let intValue = condition.intValue else { return false }
            return gameplayState?.playerPosition.x == intValue
        case "chosenStarterEquals":
            guard let stringValue = condition.stringValue else { return false }
            return gameplayState?.chosenStarterSpeciesID == stringValue
        case "itemPresent":
            guard let stringValue = condition.stringValue else { return false }
            return hasItem(stringValue)
        case "itemAbsent":
            guard let stringValue = condition.stringValue else { return false }
            return hasItem(stringValue) == false
        case "blockedMoveFacingEquals":
            guard let stringValue = condition.stringValue else { return false }
            return blockedMoveFacing?.rawValue == stringValue
        default:
            return false
        }
    }

    func beginScript(id: String) {
        gameplayState?.activeScriptID = id
        gameplayState?.activeScriptStep = 0
        scene = .scriptedSequence
        substate = "script_\(id)"
        traceEvent(.scriptStarted, "Started script \(id).", mapID: gameplayState?.mapID, scriptID: id)
        runActiveScript()
    }

    func runActiveScript() {
        guard let scriptID = gameplayState?.activeScriptID else {
            finishScript()
            return
        }
        guard let script = content.script(id: scriptID) else {
            failActiveScript(
                scriptID: scriptID,
                message: "Missing script content for \(scriptID).",
                details: [
                    "failureKind": "missingScript",
                    "missingScriptID": scriptID,
                ]
            )
            return
        }

        while let step = nextActiveScriptStep(in: script) {
            if execute(step: step) {
                return
            }
        }
        finishScript()
    }

    private func nextActiveScriptStep(in script: ScriptManifest) -> ScriptStep? {
        guard var gameplayState,
              let stepIndex = gameplayState.activeScriptStep,
              script.steps.indices.contains(stepIndex) else {
            return nil
        }

        let step = script.steps[stepIndex]
        gameplayState.activeScriptStep = stepIndex + 1
        self.gameplayState = gameplayState
        return step
    }

    func execute(step: ScriptStep) -> Bool {
        switch step.action {
        case "showDialogue":
            guard let dialogueID = step.dialogueID else { return false }
            showDialogue(id: dialogueID, completion: .continueScript)
            return true
        case "startFieldInteraction":
            guard let fieldInteractionID = step.fieldInteractionID else { return false }
            startFieldInteraction(id: fieldInteractionID, completionAction: .continueScript)
            return true
        case "startStarterChoice":
            scene = .starterChoice
            substate = "starter_choice"
            if let speciesID = step.stringValue {
                starterChoiceFocusedIndex = starterChoiceOptions.firstIndex(where: { $0.id == speciesID }) ?? 0
            }
            return true
        case "startBattle":
            guard let battleID = step.battleID else { return false }
            startBattle(id: battleID)
            return true
        case "promptItemPickup":
            guard let itemID = step.stringValue,
                  let dialogueID = step.dialogueID,
                  let successDialogueID = step.successDialogueID else {
                return false
            }
            let promptID = "\(gameplayState?.activeScriptID ?? itemID.lowercased())_prompt"
            showDialogue(
                id: dialogueID,
                completion: .openScriptItemPrompt(
                    .init(
                        promptID: promptID,
                        itemID: itemID,
                        targetObjectID: step.objectID,
                        successFlagID: step.successFlagID,
                        successDialogueID: successDialogueID,
                        failureDialogueID: step.failureDialogueID
                    )
                )
            )
            return true
        case "promptYesNo":
            guard let dialogueID = step.dialogueID else { return false }
            let promptID = "\(gameplayState?.activeScriptID ?? dialogueID)_choice_prompt"
            showDialogue(
                id: dialogueID,
                completion: .openScriptChoicePrompt(
                    .init(
                        promptID: promptID,
                        failureDialogueID: step.failureDialogueID
                    )
                )
            )
            return true
        case "healParty":
            healParty()
            return false
        case "playMusicCue":
            guard let cueID = step.stringValue else { return false }
            requestAudioCue(id: cueID)
            return false
        case "restoreMapMusic":
            requestDefaultMapMusic()
            return false
        case "performMovement":
            guard let movement = step.movement else { return false }
            beginScriptedMovement(movement)
            return true
        case "moveObject":
            guard let objectID = step.objectID else { return false }
            beginScriptedMovement(
                .init(
                    kind: .fixedPath,
                    actors: [.init(actorID: objectID, path: step.path)]
                )
            )
            return true
        case "movePlayer":
            beginScriptedMovement(
                .init(
                    kind: .fixedPath,
                    actors: [.init(actorID: "player", path: step.path)]
                )
            )
            return true
        default:
            guard var gameplayState else { return false }
            switch step.action {
            case "setFlag":
                if let flagID = step.flagID {
                    gameplayState.activeFlags.insert(flagID)
                }
            case "clearFlag":
                if let flagID = step.flagID {
                    gameplayState.activeFlags.remove(flagID)
                }
            case "addItem":
                if let itemID = step.stringValue {
                    let quantity = step.intValue ?? 1
                    if addItem(itemID, quantity: quantity, to: &gameplayState) {
                        traceScriptInventoryAddition(itemID: itemID, quantity: quantity, gameplayState: gameplayState)
                    }
                }
            case "removeItem":
                if let itemID = step.stringValue {
                    let removed = removeItem(itemID, quantity: step.intValue ?? 1, from: &gameplayState)
                    if removed {
                        traceEvent(
                            .inventoryChanged,
                            "Removed \(step.intValue ?? 1)x \(itemID).",
                            mapID: gameplayState.mapID,
                            scriptID: gameplayState.activeScriptID,
                            details: [
                                "itemID": itemID,
                                "quantity": String(step.intValue ?? 1),
                                "operation": "remove",
                            ]
                        )
                    }
                }
            case "giveItem":
                if let itemID = step.stringValue {
                    let quantity = step.intValue ?? 1
                    let added = addItem(itemID, quantity: quantity, to: &gameplayState)
                    if added {
                        if let flagID = step.successFlagID {
                            gameplayState.activeFlags.insert(flagID)
                        }
                        traceScriptInventoryAddition(itemID: itemID, quantity: quantity, gameplayState: gameplayState)
                    }
                    self.gameplayState = gameplayState
                    let dialogueID = added ? step.successDialogueID : step.failureDialogueID
                    if let dialogueID {
                        let completion: DialogueState.CompletionAction
                        if added || step.continueOnFailure ?? true {
                            completion = .continueScript
                        } else {
                            finishScript()
                            completion = .returnToField
                        }
                        let itemDisplayName = content.item(id: itemID)?.displayName ?? itemID
                        showDialogue(
                            id: dialogueID,
                            replacements: ["wStringBuffer": itemDisplayName],
                            completion: completion
                        )
                        return true
                    }
                    if added == false, step.continueOnFailure == false {
                        finishScript()
                    }
                    return false
                }
            case "awardBadge":
                if let badgeID = step.badgeID ?? step.stringValue {
                    gameplayState.earnedBadgeIDs.insert(Self.normalizedBadgeID(badgeID))
                }
            case "setObjectVisibility":
                if let objectID = step.objectID, let visible = step.visible {
                    ensureObjectStateExists(objectID, in: &gameplayState)
                    gameplayState.objectStates[objectID]?.visible = visible
                }
            case "faceObject":
                if let objectID = step.objectID, let raw = step.stringValue {
                    ensureObjectStateExists(objectID, in: &gameplayState)
                    gameplayState.objectStates[objectID]?.facing = facingDirection(for: raw)
                }
            case "facePlayer":
                if let raw = step.stringValue {
                    gameplayState.facing = facingDirection(for: raw)
                }
            case "setObjectPosition":
                if let objectID = step.objectID, let point = step.point {
                    gameplayState.objectStates[objectID]?.position = point
                }
            case "setMap":
                if let mapID = step.stringValue, let point = step.point {
                    gameplayState.mapID = mapID
                    gameplayState.playerPosition = point
                    gameplayState.activeMapScriptTriggerID = nil
                }
            default:
                break
            }
            self.gameplayState = gameplayState
            return false
        }
    }

    func finishScript(traceCompletion: Bool = true) {
        let completedScriptID = gameplayState?.activeScriptID
        gameplayState?.activeScriptID = nil
        gameplayState?.activeScriptStep = nil
        if traceCompletion, let completedScriptID {
            traceEvent(.scriptFinished, "Finished script \(completedScriptID).", mapID: gameplayState?.mapID, scriptID: completedScriptID)
        }
        if scene == .scriptedSequence {
            scene = .field
            substate = "field"
        }
    }

    func failActiveScript(
        scriptID: String? = nil,
        message: String,
        details: [String: String]
    ) {
        let failingScriptID = scriptID ?? gameplayState?.activeScriptID
        traceEvent(
            .scriptFailed,
            message,
            mapID: gameplayState?.mapID,
            scriptID: failingScriptID,
            details: details
        )
        if gameplayState?.activeScriptID != nil {
            finishScript(traceCompletion: false)
        } else {
            scene = .field
            substate = "field"
        }
    }

    func makeInitialGameplayState() -> GameplayState {
        let start = content.gameplayManifest.playerStart
        var objectStates: [String: RuntimeObjectState] = [:]
        for map in content.gameplayManifest.maps {
            for object in map.objects {
                objectStates[object.id] = RuntimeObjectState(
                    position: object.position,
                    facing: object.facing,
                    visible: object.visibleByDefault,
                    movementMode: nil,
                    idleStepIndex: 0
                )
            }
        }
        objectStates["pallet_town_oak"]?.visible = false
        objectStates["oaks_lab_oak_2"]?.visible = false

        return GameplayState(
            mapID: start.mapID,
            previousMapID: nil,
            playerPosition: start.position,
            facing: start.facing,
            blackoutCheckpoint: start.defaultBlackoutCheckpoint,
            objectStates: objectStates,
            activeFlags: Set(start.initialFlags),
            money: 3000,
            inventory: [],
            currentBoxIndex: 0,
            boxedPokemon: (0..<Self.storageBoxCount).map { RuntimePokemonBoxState(index: $0, pokemon: []) },
            ownedSpeciesIDs: [],
            seenSpeciesIDs: [],
            speciesEncounterCounts: [:],
            earnedBadgeIDs: [],
            gotStarterBit: false,
            playerName: start.playerName,
            rivalName: start.rivalName,
            playerParty: [],
            chosenStarterSpeciesID: nil,
            rivalStarterSpeciesID: nil,
            pendingStarterSpeciesID: nil,
            activeMapScriptTriggerID: nil,
            activeScriptID: nil,
            activeScriptStep: nil,
            battle: nil,
            encounterStepCounter: 0,
            totalStepCount: 0,
            wildEncounterCount: 0,
            trainerBattleCount: 0,
            playTimeSeconds: 0
        )
    }

    private func facingDirection(for rawValue: String) -> FacingDirection {
        FacingDirection(rawValue: rawValue) ?? .down
    }

    func traceScriptInventoryAddition(
        itemID: String,
        quantity: Int,
        gameplayState: GameplayState
    ) {
        traceEvent(
            .inventoryChanged,
            "Added \(quantity)x \(itemID).",
            mapID: gameplayState.mapID,
            scriptID: gameplayState.activeScriptID,
            details: [
                "itemID": itemID,
                "quantity": String(quantity),
                "operation": "add",
            ]
        )
    }
}
