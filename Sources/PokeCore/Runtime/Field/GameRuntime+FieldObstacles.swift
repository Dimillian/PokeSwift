import PokeDataModel

extension GameRuntime {
    var currentBaseMapManifest: MapManifest? {
        guard let gameplayState else { return nil }
        return content.map(id: gameplayState.mapID)
    }

    func effectiveMapManifest(for mapID: String) -> MapManifest? {
        guard let baseMap = content.map(id: mapID) else {
            return nil
        }
        return mapWithFieldObstacleOverrides(baseMap)
    }

    func fieldObstacleAhead() -> FieldObstacleManifest? {
        guard let gameplayState, let map = currentBaseMapManifest else {
            return nil
        }

        let target = translated(gameplayState.playerPosition, by: gameplayState.facing)
        return fieldObstacle(at: target, in: map)
    }

    func beginFieldObstacleInteraction(_ obstacle: FieldObstacleManifest) {
        switch obstacle.kind {
        case .cutTree:
            guard let mapID = gameplayState?.mapID else {
                return
            }

            guard earnedBadgeIDs.contains(Self.normalizedBadgeID(obstacle.requiredBadgeID)) else {
                showDialogue(id: "field_move_new_badge_required", completion: .returnToField)
                return
            }

            guard firstPartyPokemonKnowing(moveID: obstacle.requiredMoveID) != nil else {
                showDialogue(id: "field_move_nothing_to_cut", completion: .returnToField)
                return
            }

            showInlineDialogue(
                id: "field_obstacle_cut_prompt",
                pages: [.init(lines: ["This tree can be CUT!", "Want to use CUT?"], waitsForPrompt: true)],
                completion: .openFieldObstaclePrompt(
                    .init(
                        mapID: mapID,
                        obstacleID: obstacle.id
                    )
                )
            )
        }
    }

    func firstPartyPokemonKnowing(moveID: String) -> (index: Int, pokemon: RuntimePokemonState)? {
        guard let gameplayState else {
            return nil
        }

        guard let result = gameplayState.playerParty.enumerated().first(where: { _, pokemon in
            pokemon.moves.contains(where: { $0.id == moveID })
        }) else {
            return nil
        }

        return (index: result.offset, pokemon: result.element)
    }

    func clearFieldObstacleOverrides() {
        clearedFieldObstacleIDsByMapID.removeAll()
    }

    func fieldObstacle(id obstacleID: String, on mapID: String) -> FieldObstacleManifest? {
        guard let map = content.map(id: mapID) else {
            return nil
        }

        return map.fieldObstacles.first { obstacle in
            obstacle.id == obstacleID && isFieldObstacleCleared(obstacleID, on: mapID) == false
        }
    }

    func markFieldObstacleCleared(_ obstacle: FieldObstacleManifest, on mapID: String) {
        clearedFieldObstacleIDsByMapID[mapID, default: []].insert(obstacle.id)
    }

    private func fieldObstacle(at targetPosition: TilePoint, in map: MapManifest) -> FieldObstacleManifest? {
        map.fieldObstacles.first { obstacle in
            fieldObstacleTriggerPosition(for: obstacle) == targetPosition &&
                isFieldObstacleCleared(obstacle.id, on: map.id) == false
        }
    }

    private func fieldObstacleTriggerPosition(for obstacle: FieldObstacleManifest) -> TilePoint {
        TilePoint(
            x: (obstacle.blockPosition.x * 2) + obstacle.triggerStepOffset.x,
            y: (obstacle.blockPosition.y * 2) + obstacle.triggerStepOffset.y
        )
    }

    private func isFieldObstacleCleared(_ obstacleID: String, on mapID: String) -> Bool {
        clearedFieldObstacleIDsByMapID[mapID]?.contains(obstacleID) ?? false
    }

    private func mapWithFieldObstacleOverrides(_ baseMap: MapManifest) -> MapManifest {
        guard let clearedIDs = clearedFieldObstacleIDsByMapID[baseMap.id], clearedIDs.isEmpty == false else {
            return baseMap
        }

        var blockIDs = baseMap.blockIDs
        var stepCollisionTileIDs = baseMap.stepCollisionTileIDs

        for obstacle in baseMap.fieldObstacles where clearedIDs.contains(obstacle.id) {
            let blockIndex = (obstacle.blockPosition.y * baseMap.blockWidth) + obstacle.blockPosition.x
            if blockIDs.indices.contains(blockIndex) {
                blockIDs[blockIndex] = obstacle.replacementBlockID
            }

            let stepOriginX = obstacle.blockPosition.x * 2
            let stepOriginY = obstacle.blockPosition.y * 2
            let replacementTileIDs = obstacle.replacementStepCollisionTileIDs
            let stepOffsets = [
                TilePoint(x: 0, y: 0),
                TilePoint(x: 1, y: 0),
                TilePoint(x: 0, y: 1),
                TilePoint(x: 1, y: 1),
            ]

            for (index, offset) in stepOffsets.enumerated() where replacementTileIDs.indices.contains(index) {
                let stepX = stepOriginX + offset.x
                let stepY = stepOriginY + offset.y
                let collisionIndex = (stepY * baseMap.stepWidth) + stepX
                if stepCollisionTileIDs.indices.contains(collisionIndex) {
                    stepCollisionTileIDs[collisionIndex] = replacementTileIDs[index]
                }
            }
        }

        return MapManifest(
            id: baseMap.id,
            displayName: baseMap.displayName,
            defaultMusicID: baseMap.defaultMusicID,
            fieldPaletteID: baseMap.fieldPaletteID,
            borderBlockID: baseMap.borderBlockID,
            blockWidth: baseMap.blockWidth,
            blockHeight: baseMap.blockHeight,
            stepWidth: baseMap.stepWidth,
            stepHeight: baseMap.stepHeight,
            tileset: baseMap.tileset,
            blockIDs: blockIDs,
            stepCollisionTileIDs: stepCollisionTileIDs,
            warps: baseMap.warps,
            fieldObstacles: baseMap.fieldObstacles,
            backgroundEvents: baseMap.backgroundEvents,
            objects: baseMap.objects,
            connections: baseMap.connections
        )
    }
}
