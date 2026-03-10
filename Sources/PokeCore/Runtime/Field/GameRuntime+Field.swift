import Foundation
import PokeContent
import PokeDataModel

extension GameRuntime {
    func handleField(button: RuntimeButton) {
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
            interactAhead()
        case .cancel:
            break
        }
    }

    func movePlayer(in direction: FacingDirection) {
        guard var gameplayState, let map = currentMapManifest else { return }
        gameplayState.facing = direction
        let nextPoint = translated(gameplayState.playerPosition, by: direction)
        guard canMove(to: nextPoint, in: map, objectStates: gameplayState.objectStates) else {
            self.gameplayState = gameplayState
            substate = "blocked"
            return
        }

        gameplayState.playerPosition = nextPoint
        self.gameplayState = gameplayState
        if handleWarpIfNeeded() {
            return
        }
        evaluateTriggers(on: map, position: nextPoint)
    }

    func interactAhead() {
        guard let gameplayState, let map = currentMapManifest else { return }
        let target = translated(gameplayState.playerPosition, by: gameplayState.facing)

        if let object = currentFieldObjects.first(where: { $0.position == target }) {
            interact(with: object)
            return
        }

        if let backgroundEvent = map.backgroundEvents.first(where: { $0.position == target }) {
            showDialogue(id: backgroundEvent.dialogueID, completion: .returnToField)
        }
    }

    func interact(with object: FieldObjectRenderState) {
        switch object.id {
        case "reds_house_1f_mom":
            if gameplayState?.gotStarterBit == true {
                showDialogue(id: "reds_house_1f_mom_rest", completion: .healAndShow(dialogueID: "reds_house_1f_mom_looking_great"))
            } else {
                showDialogue(id: "reds_house_1f_mom_wakeup", completion: .returnToField)
            }
        case "oaks_lab_rival":
            if gameplayState?.gotStarterBit == true {
                showDialogue(id: "oaks_lab_rival_my_pokemon_looks_stronger", completion: .returnToField)
            } else {
                showDialogue(id: "oaks_lab_rival_gramps_isnt_around", completion: .returnToField)
            }
        case "oaks_lab_oak_1":
            if gameplayState?.gotStarterBit == true {
                showDialogue(id: "oaks_lab_oak_raise_your_young_pokemon", completion: .returnToField)
            } else if hasFlag("EVENT_OAK_ASKED_TO_CHOOSE_MON") {
                showDialogue(id: "oaks_lab_oak_which_pokemon_do_you_want", completion: .returnToField)
            } else {
                showDialogue(id: "oaks_lab_oak_choose_mon", completion: .returnToField)
            }
        case "oaks_lab_poke_ball_charmander":
            interactWithStarterBall(speciesID: "CHARMANDER", promptDialogueID: "oaks_lab_you_want_charmander")
        case "oaks_lab_poke_ball_squirtle":
            interactWithStarterBall(speciesID: "SQUIRTLE", promptDialogueID: "oaks_lab_you_want_squirtle")
        case "oaks_lab_poke_ball_bulbasaur":
            interactWithStarterBall(speciesID: "BULBASAUR", promptDialogueID: "oaks_lab_you_want_bulbasaur")
        default:
            if let dialogueID = object.interactionDialogueID {
                showDialogue(id: dialogueID, completion: .returnToField)
            }
        }
    }

    func interactWithStarterBall(speciesID: String, promptDialogueID: String) {
        guard hasFlag("EVENT_OAK_ASKED_TO_CHOOSE_MON") else {
            showDialogue(id: "oaks_lab_those_are_pokeballs", completion: .returnToField)
            return
        }
        guard gameplayState?.gotStarterBit == false else {
            showDialogue(id: "oaks_lab_last_mon", completion: .returnToField)
            return
        }

        gameplayState?.pendingStarterSpeciesID = speciesID
        showDialogue(id: promptDialogueID, completion: .openStarterChoice(preselectedSpeciesID: speciesID))
    }

    func chooseStarter(speciesID: String) {
        scene = .field
        substate = "field"
        gameplayState?.pendingStarterSpeciesID = speciesID
        showDialogue(id: "oaks_lab_mon_energetic", completion: .beginPostChoiceSequence)
    }

    func handleWarpIfNeeded() -> Bool {
        guard var gameplayState,
              let map = content.map(id: gameplayState.mapID),
              let warp = map.warps.first(where: { $0.origin == gameplayState.playerPosition }),
              let targetMap = content.map(id: warp.targetMapID) else {
            return false
        }

        if map.id == "OAKS_LAB" {
            if gameplayState.gotStarterBit == false {
                runMapScriptIfAvailable(named: "oaks_lab_dont_go_away")
                return true
            }
            if gameplayState.activeFlags.contains("EVENT_BATTLED_RIVAL_IN_OAKS_LAB") == false {
                runMapScriptIfAvailable(named: "oaks_lab_rival_challenge")
                return true
            }
        }

        gameplayState.mapID = targetMap.id
        gameplayState.playerPosition = warp.targetPosition
        gameplayState.facing = warp.targetFacing
        self.gameplayState = gameplayState

        if targetMap.id == "OAKS_LAB" && hasFlag("EVENT_FOLLOWED_OAK_INTO_LAB") == false {
            runMapScriptIfAvailable(named: "oaks_lab_intro")
        } else {
            scene = .field
            substate = "field"
        }
        return true
    }

    func evaluateTriggers(on map: MapManifest, position: TilePoint) {
        guard let trigger = map.triggerRegions.first(where: { $0.contains(point: position) && canRunScript(id: $0.scriptID) }) else {
            substate = "field"
            return
        }
        runMapScriptIfAvailable(named: trigger.scriptID)
    }

    func canMove(to point: TilePoint, in map: MapManifest, objectStates: [String: RuntimeObjectState]) -> Bool {
        guard point.x >= 0, point.y >= 0, point.x < map.stepWidth, point.y < map.stepHeight else {
            return false
        }

        if currentFieldObjects.contains(where: { $0.position == point }) {
            return false
        }

        let blockedTiles = blockedTiles(for: map.id)
        return blockedTiles.contains(point) == false
    }

    func blockedTiles(for mapID: String) -> Set<TilePoint> {
        switch mapID {
        case "REDS_HOUSE_2F":
            return perimeter(width: 8, height: 8).subtracting([TilePoint(x: 7, y: 1)])
        case "REDS_HOUSE_1F":
            var blocked = perimeter(width: 8, height: 8)
            blocked.subtract([TilePoint(x: 2, y: 7), TilePoint(x: 3, y: 7), TilePoint(x: 7, y: 1)])
            return blocked
        case "PALLET_TOWN":
            var blocked = perimeter(width: 20, height: 18)
            blocked.formUnion(rect(minX: 2, minY: 2, maxX: 6, maxY: 5))
            blocked.formUnion(rect(minX: 10, minY: 2, maxX: 14, maxY: 5))
            blocked.formUnion(rect(minX: 10, minY: 8, maxX: 14, maxY: 11))
            blocked.subtract([
                TilePoint(x: 5, y: 5),
                TilePoint(x: 13, y: 5),
                TilePoint(x: 12, y: 11),
                TilePoint(x: 8, y: 1),
                TilePoint(x: 9, y: 1),
                TilePoint(x: 10, y: 1),
            ])
            return blocked
        case "OAKS_LAB":
            var blocked = perimeter(width: 10, height: 12)
            blocked.subtract([TilePoint(x: 4, y: 11), TilePoint(x: 5, y: 11)])
            blocked.formUnion(rect(minX: 4, minY: 1, maxX: 8, maxY: 2))
            blocked.subtract([TilePoint(x: 6, y: 3), TilePoint(x: 7, y: 3), TilePoint(x: 8, y: 3)])
            return blocked
        default:
            return []
        }
    }
}
