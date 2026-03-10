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
        let currentPoint = gameplayState.playerPosition
        let nextPoint = translated(currentPoint, by: direction)
        guard canMove(from: currentPoint, to: nextPoint, in: map, facing: direction) else {
            self.gameplayState = gameplayState
            evaluateMapScriptsIfNeeded(blockedMoveFacing: direction)
            guard scene == .field, dialogueState == nil, self.gameplayState?.activeScriptID == nil else {
                return
            }
            substate = "blocked"
            return
        }

        gameplayState.playerPosition = nextPoint
        self.gameplayState = gameplayState
        if handleWarpIfNeeded() {
            return
        }
        evaluateMapScriptsIfNeeded()
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

        gameplayState.mapID = targetMap.id
        gameplayState.playerPosition = warp.targetPosition
        gameplayState.facing = warp.targetFacing
        gameplayState.activeMapScriptTriggerID = nil
        self.gameplayState = gameplayState

        scene = .field
        substate = "field"
        requestDefaultMapMusic()
        evaluateMapScriptsIfNeeded()
        return true
    }

    func canMove(from currentPoint: TilePoint, to nextPoint: TilePoint, in map: MapManifest, facing: FacingDirection) -> Bool {
        guard nextPoint.x >= 0, nextPoint.y >= 0, nextPoint.x < map.stepWidth, nextPoint.y < map.stepHeight else {
            return false
        }

        if currentFieldObjects.contains(where: { $0.position == nextPoint }) {
            return false
        }

        guard let tileset = currentTilesetManifest,
              let currentTileID = collisionTileID(at: currentPoint, in: map),
              let nextTileID = collisionTileID(at: nextPoint, in: map) else {
            return true
        }

        let passableTileIDs = Set(tileset.collision.passableTileIDs)
        let ledgeAllowsStep = tileset.collision.ledges.contains {
            $0.facing == facing && $0.standingTileID == currentTileID && $0.ledgeTileID == nextTileID
        }

        if passableTileIDs.contains(nextTileID) == false && ledgeAllowsStep == false {
            return false
        }

        if tileset.collision.tilePairCollisions.contains(where: {
            ($0.fromTileID == currentTileID && $0.toTileID == nextTileID) ||
            ($0.fromTileID == nextTileID && $0.toTileID == currentTileID)
        }) {
            return false
        }

        return true
    }

    func collisionTileID(at point: TilePoint, in map: MapManifest) -> Int? {
        guard point.x >= 0, point.y >= 0, point.x < map.stepWidth, point.y < map.stepHeight else {
            return nil
        }
        let index = (point.y * map.stepWidth) + point.x
        guard map.stepCollisionTileIDs.indices.contains(index) else { return nil }
        return map.stepCollisionTileIDs[index]
    }
}
