import Foundation
import PokeContent
import PokeDataModel

extension GameRuntime {
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

    private func conditionsMatch(_ trigger: MapScriptTriggerManifest, blockedMoveFacing: FacingDirection?) -> Bool {
        trigger.conditions.allSatisfy { conditionMatches($0, blockedMoveFacing: blockedMoveFacing) }
    }

    private func conditionMatches(_ condition: ScriptConditionManifest, blockedMoveFacing: FacingDirection?) -> Bool {
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
        runActiveScript()
    }

    func runActiveScript() {
        guard let scriptID = gameplayState?.activeScriptID,
              let script = content.script(id: scriptID) else {
            finishScript()
            return
        }

        while let stepIndex = gameplayState?.activeScriptStep,
              script.steps.indices.contains(stepIndex) {
            let step = script.steps[stepIndex]
            gameplayState?.activeScriptStep = stepIndex + 1
            if execute(step: step) {
                return
            }
        }
        finishScript()
    }

    func execute(step: ScriptStep) -> Bool {
        switch step.action {
        case "showDialogue":
            guard let dialogueID = step.dialogueID else { return false }
            showDialogue(id: dialogueID, completion: .continueScript)
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
            case "setObjectVisibility":
                if let objectID = step.objectID, let visible = step.visible {
                    gameplayState.objectStates[objectID]?.visible = visible
                }
            case "moveObject":
                if let objectID = step.objectID, var object = gameplayState.objectStates[objectID] {
                    for direction in step.path {
                        object.position = translated(object.position, by: direction)
                        object.facing = direction
                    }
                    gameplayState.objectStates[objectID] = object
                }
            case "movePlayer":
                for direction in step.path {
                    gameplayState.playerPosition = translated(gameplayState.playerPosition, by: direction)
                    gameplayState.facing = direction
                }
            case "faceObject":
                if let objectID = step.objectID, let raw = step.stringValue {
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

    func finishScript() {
        gameplayState?.activeScriptID = nil
        gameplayState?.activeScriptStep = nil
        if scene == .scriptedSequence {
            scene = .field
            substate = "field"
        }
    }

    func makeInitialGameplayState() -> GameplayState {
        let start = content.gameplayManifest.playerStart
        var objectStates: [String: RuntimeObjectState] = [:]
        for map in content.gameplayManifest.maps {
            for object in map.objects {
                objectStates[object.id] = RuntimeObjectState(position: object.position, facing: object.facing, visible: object.visibleByDefault)
            }
        }
        objectStates["pallet_town_oak"]?.visible = false
        objectStates["oaks_lab_oak_2"]?.visible = false

        return GameplayState(
            mapID: start.mapID,
            playerPosition: start.position,
            facing: start.facing,
            objectStates: objectStates,
            activeFlags: Set(start.initialFlags),
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
            battle: nil
        )
    }

    private func facingDirection(for rawValue: String) -> FacingDirection {
        FacingDirection(rawValue: rawValue) ?? .down
    }
}
