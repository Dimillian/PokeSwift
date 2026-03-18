import Foundation
import PokeDataModel

private struct ResolvedWarpDestination {
    let map: MapManifest
    let position: TilePoint
    let facing: FacingDirection
    let previousMapID: String?
}

extension GameRuntime {
    func handleWarpIfNeeded() -> Bool {
        guard var gameplayState,
              let map = currentMapManifest,
              let warp = map.warps.first(where: { $0.origin == gameplayState.playerPosition }),
              let destination = resolveWarpDestination(for: warp, from: map, gameplayState: gameplayState) else {
            return false
        }
        let transitionKind = fieldTransitionKind(
            sourceMap: map,
            sourcePosition: warp.origin,
            targetMap: destination.map,
            targetPosition: destination.position
        )
        let shouldStepOut = shouldAutoStepOut(on: destination.position, in: destination.map)

        gameplayState.activeMapScriptTriggerID = nil
        self.gameplayState = gameplayState
        if transitionKind == .door {
            _ = playSoundEffect(id: "SFX_GO_INSIDE", reason: "warpTransition")
        } else {
            _ = playSoundEffect(id: "SFX_GO_OUTSIDE", reason: "warpTransition")
        }
        fieldTransitionTask?.cancel()
        fieldTransitionTask = Task { [weak self] in
            await self?.runWarpTransition(
                warp: warp,
                destination: destination,
                kind: transitionKind,
                shouldStepOut: shouldStepOut
            )
        }
        return true
    }

    private func runWarpTransition(
        warp: WarpManifest,
        destination: ResolvedWarpDestination,
        kind: RuntimeFieldTransitionKind,
        shouldStepOut: Bool
    ) async {
        defer {
            fieldTransitionTask = nil
        }

        fieldTransitionState = .init(kind: kind, phase: .fadingOut)
        substate = "field_transition_\(kind.rawValue)_\(RuntimeFieldTransitionPhase.fadingOut.rawValue)"
        publishSnapshot()
        await sleep(seconds: fieldFadeDuration)

        guard Task.isCancelled == false, var gameplayState else { return }
        clearFieldObstacleOverrides()
        gameplayState.mapID = destination.map.id
        gameplayState.previousMapID = destination.previousMapID
        gameplayState.playerPosition = destination.position
        gameplayState.facing = destination.facing
        gameplayState.activeMapScriptTriggerID = nil
        self.gameplayState = gameplayState

        scene = .field
        substate = "field_transition_\(kind.rawValue)_\(RuntimeFieldTransitionPhase.fadingIn.rawValue)"
        requestDefaultMapMusic()

        fieldTransitionState = .init(kind: kind, phase: .fadingIn)
        publishSnapshot()
        await sleep(seconds: fieldFadeDuration)

        guard Task.isCancelled == false else { return }

        if shouldStepOut {
            fieldTransitionState = .init(kind: kind, phase: .steppingOut)
            substate = "field_transition_\(kind.rawValue)_\(RuntimeFieldTransitionPhase.steppingOut.rawValue)"
            gameplayState.facing = .down
            self.gameplayState = gameplayState
            publishSnapshot()
            await animatePlayerMovement(path: [.down])
            guard Task.isCancelled == false else { return }
        }

        fieldTransitionState = nil
        substate = "field"
        beginFieldMovementCooldown()
        publishSnapshot()
        traceEvent(
            .warpCompleted,
            "Warped to \(destination.map.id).",
            mapID: destination.map.id,
            details: [
                "warpID": warp.id,
                "toMapID": destination.map.id,
                "transitionKind": kind.rawValue,
                "steppedOut": shouldStepOut ? "true" : "false",
            ]
        )
        evaluateMapScriptsIfNeeded()
    }

    private func resolveWarpDestination(
        for warp: WarpManifest,
        from sourceMap: MapManifest,
        gameplayState: GameplayState
    ) -> ResolvedWarpDestination? {
        let targetMapID = resolvedWarpTargetMapID(for: warp, gameplayState: gameplayState)
        guard let targetMap = content.map(id: targetMapID) else {
            return nil
        }
        let targetPosition = resolvedWarpTargetPosition(for: warp, in: targetMap)
        let targetFacing = resolvedWarpTargetFacing(for: warp, targetMap: targetMap, targetPosition: targetPosition)
        let previousMapID = updatedPreviousMapID(
            entering: targetMap,
            from: sourceMap,
            currentPreviousMapID: gameplayState.previousMapID
        )
        return ResolvedWarpDestination(
            map: targetMap,
            position: targetPosition,
            facing: targetFacing,
            previousMapID: previousMapID
        )
    }

    func resolvedWarpTargetMapID(for warp: WarpManifest, gameplayState: GameplayState) -> String {
        if warp.usesPreviousMapTarget, let previousMapID = gameplayState.previousMapID {
            return previousMapID
        }
        return warp.targetMapID
    }

    func resolvedWarpTargetPosition(for warp: WarpManifest, in targetMap: MapManifest) -> TilePoint {
        guard let targetWarpIndex = warp.targetWarpIndex,
              targetMap.warps.indices.contains(targetWarpIndex) else {
            return warp.targetPosition
        }
        return targetMap.warps[targetWarpIndex].origin
    }

    func resolvedWarpTargetFacing(for warp: WarpManifest, targetMap: MapManifest, targetPosition: TilePoint) -> FacingDirection {
        if isDoorTile(at: targetPosition, in: targetMap) {
            return .down
        }
        return warp.targetFacing
    }

    func updatedPreviousMapID(
        entering targetMap: MapManifest,
        from sourceMap: MapManifest,
        currentPreviousMapID: String?
    ) -> String? {
        let returnTargetMapIDs = Set(targetMap.warps.filter(\.usesPreviousMapTarget).map(\.targetMapID))
        guard returnTargetMapIDs.isEmpty == false else {
            return currentPreviousMapID
        }
        if returnTargetMapIDs.contains(sourceMap.id) {
            return sourceMap.id
        }
        if let currentPreviousMapID, returnTargetMapIDs.contains(currentPreviousMapID) {
            return currentPreviousMapID
        }
        return sourceMap.id
    }

    func fieldTransitionKind(
        sourceMap: MapManifest,
        sourcePosition: TilePoint,
        targetMap: MapManifest,
        targetPosition: TilePoint
    ) -> RuntimeFieldTransitionKind {
        if isDoorTile(at: sourcePosition, in: sourceMap) || isDoorTile(at: targetPosition, in: targetMap) {
            return .door
        }
        return .warp
    }

    func shouldAutoStepOut(on position: TilePoint, in map: MapManifest) -> Bool {
        isDoorTile(at: position, in: map)
    }

    func isDoorTile(at position: TilePoint, in map: MapManifest) -> Bool {
        guard let tileset = content.tileset(id: map.tileset),
              let tileID = collisionTileID(at: position, in: map) else {
            return false
        }
        return tileset.collision.doorTileIDs.contains(tileID)
    }

    var fieldFadeDuration: TimeInterval {
        validationMode ? 0.04 : 0.14
    }
}
