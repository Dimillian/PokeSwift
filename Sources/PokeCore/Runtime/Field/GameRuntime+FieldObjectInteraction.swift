import PokeDataModel

extension GameRuntime {
    func interactAhead() {
        guard let gameplayState, let map = currentMapManifest else { return }
        let target = translated(gameplayState.playerPosition, by: gameplayState.facing)

        if let object = currentFieldObjects.first(where: { $0.position == target }) {
            interact(with: object)
            return
        }

        let secondTarget = translated(target, by: gameplayState.facing)
        if let object = currentFieldObjects.first(where: { $0.position == secondTarget }),
           canInteractOverCounter(with: object, through: target, on: map) {
            interact(with: object)
            return
        }

        if let backgroundEvent = map.backgroundEvents.first(where: { $0.position == target }) {
            showDialogue(id: backgroundEvent.dialogueID, completion: .returnToField)
            return
        }

        if let obstacle = fieldObstacleAhead() {
            beginFieldObstacleInteraction(obstacle)
        }
    }

    func canInteractOverCounter(with object: FieldRenderableObjectState, through tile: TilePoint, on map: MapManifest) -> Bool {
        guard currentMapObjectManifest(id: object.id)?.interactionReach == .overCounter,
              let tileID = collisionTileID(at: tile, in: map),
              let tileset = content.tileset(id: map.tileset) else {
            return false
        }
        return tileset.collision.passableTileIDs.contains(tileID) == false
    }

    func interact(with object: FieldRenderableObjectState) {
        guard let objectManifest = currentMapObjectManifest(id: object.id) else { return }

        if handleVisiblePickupInteraction(with: objectManifest) {
            return
        }

        if handleTrainerInteraction(with: object, manifest: objectManifest) {
            return
        }

        if let trigger = objectManifest.interactionTriggers.first(where: { trigger in
            trigger.conditions.allSatisfy { conditionMatches($0, blockedMoveFacing: nil) }
        }) {
            if let scriptID = trigger.scriptID {
                beginScript(id: scriptID)
                return
            }
            if let martID = trigger.martID {
                openMart(id: martID)
                return
            }
            if let dialogueID = trigger.dialogueID {
                showDialogue(id: dialogueID, completion: .returnToField)
                return
            }
        }

        if let scriptID = objectManifest.interactionScriptID {
            beginScript(id: scriptID)
            return
        }

        if let dialogueID = objectManifest.interactionDialogueID {
            showDialogue(id: dialogueID, completion: .returnToField)
        }
    }

    func handleVisiblePickupInteraction(with objectManifest: MapObjectManifest) -> Bool {
        guard let itemID = objectManifest.pickupItemID, var gameplayState else {
            return false
        }

        if canAddItem(itemID, quantity: 1, to: gameplayState) {
            addItem(itemID, quantity: 1, to: &gameplayState)
            ensureObjectStateExists(objectManifest.id, in: &gameplayState)
            gameplayState.objectStates[objectManifest.id]?.visible = false
            self.gameplayState = gameplayState
            traceEvent(
                .inventoryChanged,
                "Picked up \(itemID).",
                mapID: gameplayState.mapID,
                details: [
                    "itemID": itemID,
                    "quantity": "1",
                    "operation": "pickup",
                    "objectID": objectManifest.id,
                ]
            )
            showDialogue(id: "pickup_found_\(itemID.lowercased())", completion: .returnToField)
        } else {
            showDialogue(id: "pickup_no_room", completion: .returnToField)
        }
        return true
    }

    func handleTrainerInteraction(with object: FieldRenderableObjectState, manifest: MapObjectManifest) -> Bool {
        guard let battleID = manifest.trainerBattleID else {
            return false
        }

        if isTrainerDefeated(manifest) {
            if let afterBattleDialogueID = manifest.trainerAfterBattleDialogueID {
                showDialogue(id: afterBattleDialogueID, completion: .returnToField)
                return true
            }
            return false
        }

        if var gameplayState {
            gameplayState.objectStates[object.id]?.facing = oppositeFacingDirection(of: gameplayState.facing)
            self.gameplayState = gameplayState
        }
        beginTrainerEncounter(
            battleID: battleID,
            sourceTrainerObjectID: object.id,
            introDialogueID: manifest.trainerIntroDialogueID
        )
        return true
    }
}
