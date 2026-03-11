import Foundation
import PokeContent
import PokeDataModel

private struct ResolvedScriptMovementActor {
    let actorID: String
    let path: [FacingDirection]
    let startPoint: TilePoint?
}

private struct ResolvedFieldStep {
    let map: MapManifest
    let point: TilePoint
}

extension GameRuntime {
    func handleField(button: RuntimeButton) {
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
            evaluateWildEncounterIfNeeded()
        }
    }

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
        }
    }

    func canInteractOverCounter(with object: FieldObjectRenderState, through tile: TilePoint, on map: MapManifest) -> Bool {
        guard currentMapObjectManifest(id: object.id)?.interactionReach == .overCounter,
              let tileID = collisionTileID(at: tile, in: map),
              let tileset = content.tileset(id: map.tileset) else {
            return false
        }
        return tileset.collision.passableTileIDs.contains(tileID) == false
    }

    func interact(with object: FieldObjectRenderState) {
        guard let objectManifest = currentMapObjectManifest(id: object.id) else {
            if let dialogueID = object.interactionDialogueID {
                showDialogue(id: dialogueID, completion: .returnToField)
            }
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

    func chooseStarter(speciesID: String) {
        scene = .field
        substate = "field"
        gameplayState?.pendingStarterSpeciesID = speciesID
        showDialogue(id: "oaks_lab_mon_energetic", completion: .beginPostChoiceSequence)
    }

    func currentMapObjectManifest(id: String) -> MapObjectManifest? {
        currentMapManifest?.objects.first { $0.id == id }
    }

    func handleWarpIfNeeded() -> Bool {
        guard var gameplayState,
              let map = content.map(id: gameplayState.mapID),
              let warp = map.warps.first(where: { $0.origin == gameplayState.playerPosition }),
              let targetMap = content.map(id: warp.targetMapID) else {
            return false
        }
        let transitionKind = fieldTransitionKind(sourceMap: map, sourcePosition: warp.origin, targetMap: targetMap, targetPosition: warp.targetPosition)
        let shouldStepOut = shouldAutoStepOut(on: warp.targetPosition, in: targetMap)

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
                targetMap: targetMap,
                kind: transitionKind,
                shouldStepOut: shouldStepOut
            )
        }
        return true
    }

    func runWarpTransition(
        warp: WarpManifest,
        targetMap: MapManifest,
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
        gameplayState.mapID = targetMap.id
        gameplayState.playerPosition = warp.targetPosition
        gameplayState.facing = warp.targetFacing
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
        publishSnapshot()
        traceEvent(
            .warpCompleted,
            "Warped to \(targetMap.id).",
            mapID: targetMap.id,
            details: [
                "warpID": warp.id,
                "toMapID": targetMap.id,
                "transitionKind": kind.rawValue,
                "steppedOut": shouldStepOut ? "true" : "false",
            ]
        )
        evaluateMapScriptsIfNeeded()
    }

    func beginScriptedPlayerMovement(_ path: [FacingDirection]) {
        beginScriptedMovement(.init(kind: .fixedPath, actors: [.init(actorID: "player", path: path)]))
    }

    func beginScriptedMovement(_ movement: ScriptMovementManifest) {
        fieldMovementTask?.cancel()
        fieldMovementTask = nil
        idleMovementTask?.cancel()
        idleMovementTask = nil
        scriptedMovementTask?.cancel()
        scriptedMovementTask = Task { [weak self] in
            await self?.runScriptedMovement(movement)
        }
    }

    func beginFieldMovementCooldown() {
        fieldMovementTask?.cancel()
        fieldMovementTask = Task { [weak self] in
            guard let self else { return }
            await self.sleep(seconds: self.fieldStepDuration)
            guard Task.isCancelled == false else { return }
            self.fieldMovementTask = nil
        }
    }

    func runScriptedPlayerMovement(_ path: [FacingDirection]) async {
        await runScriptedMovement(.init(kind: .fixedPath, actors: [.init(actorID: "player", path: path)]))
    }

    func runScriptedMovement(_ movement: ScriptMovementManifest) async {
        defer {
            scriptedMovementTask = nil
        }

        let actors = resolvedActors(for: movement)
        guard actors.isEmpty == false else {
            runActiveScript()
            publishSnapshot()
            return
        }

        await animateActors(actors, mode: .scripted)
        guard Task.isCancelled == false else { return }
        runActiveScript()
        publishSnapshot()
    }

    func animatePlayerMovement(path: [FacingDirection]) async {
        guard path.isEmpty == false else { return }
        await animateActors([.init(actorID: "player", path: path, startPoint: nil)], mode: .scripted)
    }

    private func animateActors(_ actors: [ResolvedScriptMovementActor], mode: ActorMovementMode) async {
        guard actors.isEmpty == false else { return }
        applyMovementStartPointsIfNeeded(actors)
        let maxPathLength = actors.map { $0.path.count }.max() ?? 0
        guard maxPathLength > 0 else {
            clearMovementModes(for: actors)
            publishSnapshot()
            return
        }

        for stepIndex in 0..<maxPathLength {
            guard Task.isCancelled == false,
                  var gameplayState,
                  let map = currentMapManifest else {
                clearMovementModes(for: actors)
                return
            }

            let movingObjectIDs = Set(actors.lazy.filter { $0.actorID != "player" }.map(\.actorID))
            var occupiedTiles = occupiedTileSet(excludingObjectIDs: movingObjectIDs, excludingPlayer: actors.contains { $0.actorID == "player" })
            var reservedTiles: Set<TilePoint> = []

            for actor in actors where actor.path.indices.contains(stepIndex) {
                let direction = actor.path[stepIndex]
                if actor.actorID == "player" {
                    let current = gameplayState.playerPosition
                    let next = translated(current, by: direction)
                    guard canActorOccupy(next, from: current, in: map, facing: direction, occupiedTiles: occupiedTiles, reservedTiles: reservedTiles) else {
                        continue
                    }
                    gameplayState.facing = direction
                    gameplayState.playerPosition = next
                    occupiedTiles.insert(next)
                    reservedTiles.insert(next)
                } else if var objectState = gameplayState.objectStates[actor.actorID] {
                    let current = objectState.position
                    let next = translated(current, by: direction)
                    guard canActorOccupy(next, from: current, in: map, facing: direction, occupiedTiles: occupiedTiles, reservedTiles: reservedTiles) else {
                        objectState.facing = direction
                        gameplayState.objectStates[actor.actorID] = objectState
                        continue
                    }
                    objectState.facing = direction
                    objectState.position = next
                    objectState.movementMode = mode
                    gameplayState.objectStates[actor.actorID] = objectState
                    occupiedTiles.insert(next)
                    reservedTiles.insert(next)
                }
            }

            self.gameplayState = gameplayState
            publishSnapshot()
            await sleep(seconds: fieldStepDuration)
        }

        clearMovementModes(for: actors)
        publishSnapshot()
    }

    private func resolvedActors(for movement: ScriptMovementManifest) -> [ResolvedScriptMovementActor] {
        guard let gameplayState, let map = currentMapManifest else { return [] }
        let selectedVariant = movement.variants.first {
            $0.conditions.allSatisfy { conditionMatches($0, blockedMoveFacing: nil) }
        }

        let actors = selectedVariant?.actors ?? movement.actors
        let startPoint = selectedVariant?.point

        switch movement.kind {
        case .pathToPlayerAdjacent:
            guard let actorID = actors.first?.actorID else {
                return []
            }
            let target = TilePoint(
                x: gameplayState.playerPosition.x + (movement.targetPlayerOffset?.x ?? 0),
                y: gameplayState.playerPosition.y + (movement.targetPlayerOffset?.y ?? 0)
            )
            return resolvedPathActor(
                actorID: actorID,
                target: target,
                startPoint: startPoint,
                gameplayState: gameplayState,
                map: map
            )
        case .pathToObjectOffset:
            guard let actorID = actors.first?.actorID,
                  let targetObjectID = movement.targetObjectID,
                  let targetObject = gameplayState.objectStates[targetObjectID]
            else {
                return []
            }
            let target = TilePoint(
                x: targetObject.position.x + (movement.targetObjectOffset?.x ?? 0),
                y: targetObject.position.y + (movement.targetObjectOffset?.y ?? 0)
            )
            return resolvedPathActor(
                actorID: actorID,
                target: target,
                startPoint: startPoint,
                gameplayState: gameplayState,
                map: map
            )
        case .fixedPath, .palletEscort, .rivalStarterPickup:
            return actors.map { ResolvedScriptMovementActor(actorID: $0.actorID, path: $0.path, startPoint: startPoint) }
        }
    }

    private func resolvedPathActor(
        actorID: String,
        target: TilePoint,
        startPoint: TilePoint?,
        gameplayState: GameplayState,
        map: MapManifest
    ) -> [ResolvedScriptMovementActor] {
        guard actorID != "player",
              let objectState = gameplayState.objectStates[actorID],
              let path = shortestPath(
                  from: objectState.position,
                  to: target,
                  in: map,
                  ignoringObjectID: actorID
              ) else {
            return []
        }

        return [.init(actorID: actorID, path: path, startPoint: startPoint)]
    }

    private func applyMovementStartPointsIfNeeded(_ actors: [ResolvedScriptMovementActor]) {
        guard var gameplayState else { return }
        var didChangeState = false

        for actor in actors {
            guard let startPoint = actor.startPoint, actor.actorID != "player" else { continue }
            if gameplayState.objectStates[actor.actorID]?.position != startPoint {
                gameplayState.objectStates[actor.actorID]?.position = startPoint
                didChangeState = true
            }
        }

        if didChangeState {
            self.gameplayState = gameplayState
            publishSnapshot()
        }
    }

    private func clearMovementModes(for actors: [ResolvedScriptMovementActor]) {
        guard var gameplayState else { return }
        for actor in actors where actor.actorID != "player" {
            gameplayState.objectStates[actor.actorID]?.movementMode = nil
        }
        self.gameplayState = gameplayState
    }

    func refreshIdleMovementScheduling() {
        guard canRunIdleMovement else {
            idleMovementTask?.cancel()
            idleMovementTask = nil
            return
        }
        guard idleMovementTask == nil else { return }
        idleMovementTask = Task { [weak self] in
            await self?.runIdleMovementLoop()
        }
    }

    var canRunIdleMovement: Bool {
        scene == .field &&
            dialogueState == nil &&
            gameplayState?.battle == nil &&
            fieldTransitionState == nil &&
            scriptedMovementTask == nil
    }

    func runIdleMovementLoop() async {
        defer {
            idleMovementTask = nil
        }

        while Task.isCancelled == false {
            await sleep(seconds: idleMovementInterval)
            guard Task.isCancelled == false else { return }
            await performIdleMovementCycle()
        }
    }

    func performIdleMovementCycle() async {
        guard canRunIdleMovement, var gameplayState, let map = currentMapManifest else { return }
        let visibleWalkers = map.objects
            .filter { object in
                object.movementBehavior.idleMode == .walk &&
                    (gameplayState.objectStates[object.id]?.visible ?? object.visibleByDefault) &&
                    gameplayState.objectStates[object.id]?.movementMode == nil
            }
            .sorted { $0.id < $1.id }

        guard visibleWalkers.isEmpty == false else { return }

        var occupiedTiles = occupiedTileSet(excludingObjectIDs: [], excludingPlayer: false)
        var reservedTiles: Set<TilePoint> = []
        var plannedActors: [ResolvedScriptMovementActor] = []

        for object in visibleWalkers {
            guard let objectState = gameplayState.objectStates[object.id] else { continue }
            let directions = object.movementBehavior.axis.allowedDirections
            guard directions.isEmpty == false else { continue }

            let startIndex = objectState.idleStepIndex % directions.count
            var chosenDirection: FacingDirection?
            var chosenDestination: TilePoint?

            for offset in 0..<directions.count {
                let direction = directions[(startIndex + offset) % directions.count]
                let next = translated(objectState.position, by: direction)
                guard isWithinIdleBounds(next, behavior: object.movementBehavior) else { continue }
                guard canActorOccupy(next, from: objectState.position, in: map, facing: direction, occupiedTiles: occupiedTiles.subtracting([objectState.position]), reservedTiles: reservedTiles) else {
                    continue
                }
                chosenDirection = direction
                chosenDestination = next
                break
            }

            gameplayState.objectStates[object.id]?.idleStepIndex += 1

            guard let chosenDirection, let chosenDestination else { continue }
            reservedTiles.insert(chosenDestination)
            occupiedTiles.remove(objectState.position)
            occupiedTiles.insert(chosenDestination)
            plannedActors.append(.init(actorID: object.id, path: [chosenDirection], startPoint: nil))
        }

        self.gameplayState = gameplayState
        guard plannedActors.isEmpty == false else { return }
        await animateActors(plannedActors, mode: .idle)
    }

    func occupiedTileSet(excludingObjectIDs: Set<String>, excludingPlayer: Bool) -> Set<TilePoint> {
        guard let gameplayState, let map = currentMapManifest else { return [] }
        var occupied: Set<TilePoint> = []
        if excludingPlayer == false {
            occupied.insert(gameplayState.playerPosition)
        }
        for object in map.objects where excludingObjectIDs.contains(object.id) == false {
            guard let objectState = gameplayState.objectStates[object.id], objectState.visible else { continue }
            occupied.insert(objectState.position)
        }
        return occupied
    }

    func canActorOccupy(
        _ nextPoint: TilePoint,
        from currentPoint: TilePoint,
        in map: MapManifest,
        facing: FacingDirection,
        occupiedTiles: Set<TilePoint>,
        reservedTiles: Set<TilePoint>
    ) -> Bool {
        guard isWithinFieldBounds(nextPoint, in: map) else {
            return false
        }
        guard occupiedTiles.contains(nextPoint) == false, reservedTiles.contains(nextPoint) == false else {
            return false
        }
        return tilesAllowFieldTraversal(from: currentPoint, to: nextPoint, in: map, facing: facing)
    }

    func shortestPath(
        from start: TilePoint,
        to goal: TilePoint,
        in map: MapManifest,
        ignoringObjectID: String
    ) -> [FacingDirection]? {
        if start == goal {
            return []
        }

        var queue: [TilePoint] = [start]
        var queueIndex = 0
        var visited: Set<TilePoint> = [start]
        var previous: [TilePoint: (TilePoint, FacingDirection)] = [:]
        let occupied = occupiedTileSet(excludingObjectIDs: [ignoringObjectID], excludingPlayer: false)

        while queueIndex < queue.count {
            let current = queue[queueIndex]
            queueIndex += 1
            for direction in FacingDirection.allCases {
                let next = translated(current, by: direction)
                guard visited.contains(next) == false else { continue }
                guard canActorOccupy(next, from: current, in: map, facing: direction, occupiedTiles: occupied.subtracting([start]), reservedTiles: []) else {
                    continue
                }
                visited.insert(next)
                previous[next] = (current, direction)
                if next == goal {
                    return reconstructedPath(goal: goal, previous: previous)
                }
                queue.append(next)
            }
        }

        return nil
    }

    func reconstructedPath(
        goal: TilePoint,
        previous: [TilePoint: (TilePoint, FacingDirection)]
    ) -> [FacingDirection] {
        var path: [FacingDirection] = []
        var cursor = goal
        while let entry = previous[cursor] {
            path.append(entry.1)
            cursor = entry.0
        }
        return path.reversed()
    }

    func isWithinIdleBounds(_ point: TilePoint, behavior: ObjectMovementBehavior) -> Bool {
        let dx = abs(point.x - behavior.home.x)
        let dy = abs(point.y - behavior.home.y)
        return max(dx, dy) <= behavior.maxDistanceFromHome
    }

    var idleMovementInterval: TimeInterval {
        validationMode ? 0.05 : 0.32
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

    var fieldStepDuration: TimeInterval {
        fieldAnimationStepDuration
    }

    func isWithinFieldBounds(_ point: TilePoint, in map: MapManifest) -> Bool {
        point.x >= 0 && point.y >= 0 && point.x < map.stepWidth && point.y < map.stepHeight
    }

    func tilesAllowFieldTraversal(
        from currentPoint: TilePoint,
        to nextPoint: TilePoint,
        in map: MapManifest,
        facing: FacingDirection
    ) -> Bool {
        guard let tileset = content.tileset(id: map.tileset),
              let currentTileID = collisionTileID(at: currentPoint, in: map),
              let nextTileID = collisionTileID(at: nextPoint, in: map) else {
            return true
        }

        let passableTileIDs = Set(tileset.collision.passableTileIDs)
        let ledgeAllowsStep = tileset.collision.ledges.contains {
            $0.facing == facing && $0.standingTileID == currentTileID && $0.ledgeTileID == nextTileID
        }

        guard passableTileIDs.contains(nextTileID) || ledgeAllowsStep else {
            return false
        }

        return tileset.collision.tilePairCollisions.contains(where: {
            ($0.fromTileID == currentTileID && $0.toTileID == nextTileID) ||
            ($0.fromTileID == nextTileID && $0.toTileID == currentTileID)
        }) == false
    }

    func sleep(seconds: TimeInterval) async {
        guard seconds > 0 else { return }
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }

    func canMove(from currentPoint: TilePoint, to nextPoint: TilePoint, in map: MapManifest, facing: FacingDirection) -> Bool {
        resolveFieldStep(
            from: currentPoint,
            to: nextPoint,
            in: map,
            gameplayState: gameplayState,
            facing: facing
        ) != nil
    }

    func collisionTileID(at point: TilePoint, in map: MapManifest) -> Int? {
        guard isWithinFieldBounds(point, in: map) else {
            return nil
        }
        let index = (point.y * map.stepWidth) + point.x
        guard map.stepCollisionTileIDs.indices.contains(index) else { return nil }
        return map.stepCollisionTileIDs[index]
    }

    fileprivate func resolveFieldStep(
        from currentPoint: TilePoint,
        to nextPoint: TilePoint,
        in map: MapManifest,
        gameplayState: GameplayState?,
        facing: FacingDirection
    ) -> ResolvedFieldStep? {
        if (0..<map.stepWidth).contains(nextPoint.x), (0..<map.stepHeight).contains(nextPoint.y) {
            guard canOccupyFieldPoint(nextPoint, from: currentPoint, in: map, mapID: map.id, gameplayState: gameplayState, facing: facing) else {
                return nil
            }
            return ResolvedFieldStep(map: map, point: nextPoint)
        }

        guard let connectionDestination = connectionDestination(for: nextPoint, from: map, facing: facing) else {
            return nil
        }
        guard canOccupyFieldPoint(
            connectionDestination.point,
            from: connectionDestination.originPoint,
            in: connectionDestination.map,
            mapID: connectionDestination.map.id,
            gameplayState: gameplayState,
            facing: facing
        ) else {
            return nil
        }
        return ResolvedFieldStep(map: connectionDestination.map, point: connectionDestination.point)
    }

    func canOccupyFieldPoint(
        _ nextPoint: TilePoint,
        from currentPoint: TilePoint,
        in map: MapManifest,
        mapID: String,
        gameplayState: GameplayState?,
        facing: FacingDirection
    ) -> Bool {
        guard isWithinFieldBounds(nextPoint, in: map) else {
            return false
        }

        if visibleObjectPositions(on: mapID, gameplayState: gameplayState).contains(nextPoint) {
            return false
        }
        return tilesAllowFieldTraversal(from: currentPoint, to: nextPoint, in: map, facing: facing)
    }

    func visibleObjectPositions(on mapID: String, gameplayState: GameplayState?) -> Set<TilePoint> {
        guard let gameplayState, let map = content.map(id: mapID) else { return [] }
        return Set(map.objects.compactMap { object in
            guard gameplayState.objectStates[object.id]?.visible ?? object.visibleByDefault else { return nil }
            return gameplayState.objectStates[object.id]?.position ?? object.position
        })
    }

    func connectionDestination(
        for attemptedPoint: TilePoint,
        from map: MapManifest,
        facing: FacingDirection
    ) -> (map: MapManifest, point: TilePoint, originPoint: TilePoint)? {
        guard let connection = map.connections.first(where: { $0.direction == mapConnectionDirection(for: facing) }),
              let targetMap = content.map(id: connection.targetMapID) else {
            return nil
        }

        switch facing {
        case .up:
            let targetX = attemptedPoint.x - (connection.offset * 2)
            guard (0..<targetMap.stepWidth).contains(targetX) else { return nil }
            return (
                map: targetMap,
                point: .init(x: targetX, y: targetMap.stepHeight - 1),
                originPoint: .init(x: targetX, y: targetMap.stepHeight)
            )
        case .down:
            let targetX = attemptedPoint.x - (connection.offset * 2)
            guard (0..<targetMap.stepWidth).contains(targetX) else { return nil }
            return (
                map: targetMap,
                point: .init(x: targetX, y: 0),
                originPoint: .init(x: targetX, y: -1)
            )
        case .left:
            let targetY = attemptedPoint.y - (connection.offset * 2)
            guard (0..<targetMap.stepHeight).contains(targetY) else { return nil }
            return (
                map: targetMap,
                point: .init(x: targetMap.stepWidth - 1, y: targetY),
                originPoint: .init(x: targetMap.stepWidth, y: targetY)
            )
        case .right:
            let targetY = attemptedPoint.y - (connection.offset * 2)
            guard (0..<targetMap.stepHeight).contains(targetY) else { return nil }
            return (
                map: targetMap,
                point: .init(x: 0, y: targetY),
                originPoint: .init(x: -1, y: targetY)
            )
        }
    }

    func mapConnectionDirection(for facing: FacingDirection) -> MapConnectionDirection {
        switch facing {
        case .up: return .north
        case .down: return .south
        case .left: return .west
        case .right: return .east
        }
    }
}
