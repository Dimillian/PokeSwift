import Foundation
import PokeContent
import PokeDataModel

extension GameRuntime {
    func canRunScript(id: String) -> Bool {
        switch id {
        case _ where id.contains("oak_intro"):
            return hasFlag("EVENT_FOLLOWED_OAK_INTO_LAB") == false
        case _ where id.contains("dont_go_away"):
            return gameplayState?.gotStarterBit == false
        case _ where id.contains("rival_challenge"):
            return gameplayState?.gotStarterBit == true && hasFlag("EVENT_BATTLED_RIVAL_IN_OAKS_LAB") == false
        default:
            return true
        }
    }

    func runMapScriptIfAvailable(named id: String) {
        if content.script(id: id) != nil {
            beginScript(id: id)
            return
        }

        switch id {
        case _ where id.contains("oak_intro"):
            runFallbackOakIntro()
        case _ where id.contains("oaks_lab_intro"):
            runFallbackLabIntro()
        case _ where id.contains("dont_go_away"):
            showDialogue(id: "oaks_lab_oak_dont_go_away_yet", completion: .returnToField)
            if var gameplayState {
                gameplayState.playerPosition = TilePoint(x: 4, y: 5)
                gameplayState.facing = .up
                self.gameplayState = gameplayState
            }
        case _ where id.contains("rival_challenge"):
            runFallbackRivalChallenge()
        default:
            scene = .field
            substate = "field"
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
        case "setFlag":
            if let flagID = step.flagID {
                gameplayState?.activeFlags.insert(flagID)
            }
        case "clearFlag":
            if let flagID = step.flagID {
                gameplayState?.activeFlags.remove(flagID)
            }
        case "setObjectVisibility":
            if let objectID = step.objectID, let visible = step.visible {
                gameplayState?.objectStates[objectID]?.visible = visible
            }
        case "moveObject":
            if let objectID = step.objectID {
                moveObject(id: objectID, through: step.path)
            }
        case "movePlayer":
            for direction in step.path {
                gameplayState?.playerPosition = translated(gameplayState?.playerPosition ?? TilePoint(x: 0, y: 0), by: direction)
                gameplayState?.facing = direction
            }
        case "faceObject":
            if let objectID = step.objectID, let raw = step.stringValue, let facing = FacingDirection(rawValue: raw) {
                gameplayState?.objectStates[objectID]?.facing = facing
            }
        case "facePlayer":
            if let raw = step.stringValue, let facing = FacingDirection(rawValue: raw) {
                gameplayState?.facing = facing
            }
        case "setObjectPosition":
            if let objectID = step.objectID, let point = step.point {
                gameplayState?.objectStates[objectID]?.position = point
            }
        case "setMap":
            if let mapID = step.stringValue, let point = step.point {
                gameplayState?.mapID = mapID
                gameplayState?.playerPosition = point
            }
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
        default:
            break
        }
        return false
    }

    func finishScript() {
        gameplayState?.activeScriptID = nil
        gameplayState?.activeScriptStep = nil
        if scene == .scriptedSequence {
            scene = .field
            substate = "field"
        }
    }

    func runFallbackOakIntro() {
        guard var gameplayState else { return }
        gameplayState.activeFlags.insert("EVENT_OAK_APPEARED_IN_PALLET")
        gameplayState.objectStates["pallet_town_oak"]?.visible = true
        gameplayState.objectStates["pallet_town_oak"]?.position = TilePoint(x: 8, y: 3)
        gameplayState.objectStates["pallet_town_oak"]?.facing = .down
        self.gameplayState = gameplayState
        showDialogue(id: "pallet_town_oak_hey_wait", completion: .returnToField)
        queueDeferredActions([
            .dialogue("pallet_town_oak_its_unsafe"),
            .startLabIntro,
        ])
    }

    func runFallbackLabIntro() {
        guard var gameplayState else { return }
        gameplayState.mapID = "OAKS_LAB"
        gameplayState.playerPosition = TilePoint(x: 5, y: 10)
        gameplayState.facing = .up
        gameplayState.objectStates["oaks_lab_oak_1"]?.visible = true
        gameplayState.objectStates["oaks_lab_oak_2"]?.visible = false
        self.gameplayState = gameplayState

        showDialogue(id: "oaks_lab_rival_fed_up_with_waiting", completion: .returnToField)
        gameplayState.activeFlags.insert("EVENT_OAK_ASKED_TO_CHOOSE_MON")
        self.gameplayState = gameplayState
        queueDeferredActions([
            .dialogue("oaks_lab_oak_choose_mon"),
            .dialogue("oaks_lab_rival_what_about_me"),
            .dialogue("oaks_lab_oak_be_patient"),
        ])
    }

    func runFallbackRivalChallenge() {
        guard gameplayState?.chosenStarterSpeciesID != nil else { return }
        showDialogue(id: "oaks_lab_rival_ill_take_you_on", completion: .returnToField)
        queueDeferredActions([.battle("AUTO")])
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
            activeScriptID: nil,
            activeScriptStep: nil,
            battle: nil
        )
    }
}
