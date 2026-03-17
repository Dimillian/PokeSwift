import Foundation
import SwiftUI
import PokeDataModel
import PokeRender

public struct FieldMapView: View {
    let map: MapManifest
    let fieldPalette: FieldPaletteManifest?
    let playerPosition: TilePoint
    let playerFacing: FacingDirection
    let playerStepDuration: TimeInterval
    let objects: [FieldRenderableObjectState]
    let playerSpriteID: String
    let renderAssets: FieldRenderAssets?
    let transition: FieldTransitionTelemetry?
    let alert: FieldAlertTelemetry?
    let displayStyle: FieldDisplayStyle

    @State private var renderedScene: FieldRenderedScene?
    @State private var presentedCameraOrigin: CGPoint = .zero
    @State private var presentedPlayerWorldPosition: CGPoint = .zero
    @State private var presentedObjectWorldPositions: [String: CGPoint] = [:]
    @State private var presentationIdentity: FieldPresentationIdentity?
    @State private var presentedMap: MapManifest?
    @State private var playerStepAnimation: PlayerStepAnimationState?
    @State private var objectStepAnimations: [String: ObjectStepAnimationState] = [:]

    public init(
        map: MapManifest,
        fieldPalette: FieldPaletteManifest? = nil,
        playerPosition: TilePoint,
        playerFacing: FacingDirection,
        playerStepDuration: TimeInterval = 16.0 / 60.0,
        objects: [FieldRenderableObjectState],
        playerSpriteID: String = "SPRITE_RED",
        renderAssets: FieldRenderAssets? = nil,
        transition: FieldTransitionTelemetry? = nil,
        alert: FieldAlertTelemetry? = nil,
        displayStyle: FieldDisplayStyle = .defaultGameplayStyle
    ) {
        self.map = map
        self.fieldPalette = fieldPalette
        self.playerPosition = playerPosition
        self.playerFacing = playerFacing
        self.playerStepDuration = playerStepDuration
        self.objects = objects
        self.playerSpriteID = playerSpriteID
        self.renderAssets = renderAssets
        self.transition = transition
        self.alert = alert
        self.displayStyle = displayStyle
    }

    public var body: some View {
        GeometryReader { proxy in
            let scale = GameplayViewportScale.snappedFieldViewportScale(for: proxy.size)
            let viewportWidth = CGFloat(FieldSceneRenderer.viewportPixelSize.width) * scale
            let viewportHeight = CGFloat(FieldSceneRenderer.viewportPixelSize.height) * scale

            ZStack {
                if let renderedScene {
                    FixedViewportRenderedField(
                        scene: renderedScene,
                        fieldPalette: fieldPalette,
                        playerFacing: playerFacing,
                        playerStepAnimation: playerStepAnimation,
                        playerStepDuration: playerStepDuration,
                        transition: transition,
                        alert: alert,
                        displayStyle: displayStyle,
                        displayScale: scale,
                        cameraOrigin: presentedCameraOrigin,
                        playerWorldPosition: presentedPlayerWorldPosition,
                        objectWorldPositions: presentedObjectWorldPositions,
                        objectStepAnimations: objectStepAnimations
                    )
                } else {
                    FixedViewportPlaceholderField(
                        map: map,
                        fieldPalette: fieldPalette,
                        playerPosition: playerPosition,
                        playerFacing: playerFacing,
                        objects: objects,
                        metrics: FieldSceneRenderer.sceneMetrics(for: map),
                        transition: transition,
                        alert: alert,
                        displayStyle: displayStyle,
                        displayScale: scale,
                        cameraOrigin: presentedCameraOrigin,
                        playerWorldPosition: presentedPlayerWorldPosition
                    )
                }
            }
            .frame(width: viewportWidth, height: viewportHeight)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .task(id: presentationSignature) {
            syncPresentedState(metrics: FieldSceneRenderer.sceneMetrics(for: map))
        }
        .task(id: sceneRenderSignature) {
            await updateRenderedScene()
        }
    }

    private var presentationSignature: FieldPresentationIdentity {
        FieldPresentationIdentity(
            mapID: map.id,
            playerPosition: playerPosition,
            objects: objects.map {
                .init(id: $0.id, position: $0.position, movementMode: $0.movementMode)
            }
        )
    }

    private var sceneRenderSignature: FieldSceneRenderIdentity? {
        Self.sceneRenderTaskIdentity(
            map: map,
            playerFacing: playerFacing,
            playerSpriteID: playerSpriteID,
            objects: objects,
            renderAssets: renderAssets
        )
    }

    static func sceneRenderTaskIdentity(
        map: MapManifest,
        playerFacing: FacingDirection,
        playerSpriteID: String,
        objects: [FieldRenderableObjectState],
        renderAssets: FieldRenderAssets?
    ) -> FieldSceneRenderIdentity? {
        guard let renderAssets else { return nil }
        return FieldSceneRenderIdentity(
            map: map,
            playerFacing: playerFacing,
            playerSpriteID: playerSpriteID,
            objects: objects,
            assets: renderAssets
        )
    }

    @MainActor
    private func updateRenderedScene() async {
        guard let renderAssets else {
            renderedScene = nil
            return
        }

        let scene = await renderFieldScene(assets: renderAssets)
        guard Task.isCancelled == false else { return }
        renderedScene = scene
    }

    private func renderFieldScene(assets: FieldRenderAssets) async -> FieldRenderedScene? {
        let map = map
        let playerPosition = playerPosition
        let playerFacing = playerFacing
        let playerSpriteID = playerSpriteID
        let objects = objects

        let renderResult = await Task.detached(priority: .userInitiated) {
            try? RenderedFieldSceneBox(
                scene: FieldSceneRenderer.renderScene(
                    map: map,
                    playerPosition: playerPosition,
                    playerFacing: playerFacing,
                    playerSpriteID: playerSpriteID,
                    objects: objects,
                    assets: assets
                )
            )
        }.value
        return renderResult?.scene
    }

    @MainActor
    private func syncPresentedState(metrics: FieldSceneMetrics) {
        let targetPlayerWorld = FieldSceneRenderer.playerWorldPosition(for: playerPosition, metrics: metrics)
        let targetCamera = FieldCameraState.target(
            playerWorldPosition: targetPlayerWorld,
            contentPixelSize: metrics.contentPixelSize
        )
        let nextIdentity = FieldPresentationIdentity(
            mapID: map.id,
            playerPosition: playerPosition,
            objects: objects.map {
                .init(id: $0.id, position: $0.position, movementMode: $0.movementMode)
            }
        )
        let transitionDirection = transitionDirection(to: nextIdentity, nextMap: map)
        let shouldAnimate = transitionDirection != nil
        let nextStepAnimation = makePlayerStepAnimation(to: nextIdentity, direction: transitionDirection)
        let connectedStepOrigin = connectedStepOriginPosition(
            to: nextIdentity,
            nextMap: map,
            direction: transitionDirection
        )
        let nextObjectWorldPositions = Dictionary(uniqueKeysWithValues: objects.map { object in
            (
                object.id,
                CGPoint(
                    x: CGFloat(FieldSceneRenderer.playerWorldPosition(for: object.position, metrics: metrics).x),
                    y: CGFloat(FieldSceneRenderer.playerWorldPosition(for: object.position, metrics: metrics).y)
                )
            )
        })
        let nextObjectStepAnimations = makeObjectStepAnimations(to: nextIdentity)
        let shouldAnimateObjects = nextObjectStepAnimations.isEmpty == false
        let resolvedPlayerStepAnimation = resolvedPlayerStepAnimation(
            nextIdentity: nextIdentity,
            nextStepAnimation: nextStepAnimation,
            shouldAnimateObjects: shouldAnimateObjects
        )

        let applyState = {
            presentedPlayerWorldPosition = CGPoint(
                x: CGFloat(targetPlayerWorld.x),
                y: CGFloat(targetPlayerWorld.y)
            )
            presentedCameraOrigin = CGPoint(
                x: CGFloat(targetCamera.origin.x),
                y: CGFloat(targetCamera.origin.y)
            )
            presentedObjectWorldPositions = nextObjectWorldPositions
            presentationIdentity = nextIdentity
            presentedMap = map
        }

        if shouldAnimate || shouldAnimateObjects {
            playerStepAnimation = resolvedPlayerStepAnimation
            objectStepAnimations = nextObjectStepAnimations
            if let connectedStepOrigin {
                var transaction = Transaction()
                transaction.animation = nil
                withTransaction(transaction) {
                    presentedPlayerWorldPosition = CGPoint(
                        x: CGFloat(connectedStepOrigin.playerWorldPosition.x),
                        y: CGFloat(connectedStepOrigin.playerWorldPosition.y)
                    )
                    presentedCameraOrigin = CGPoint(
                        x: CGFloat(connectedStepOrigin.cameraOrigin.x),
                        y: CGFloat(connectedStepOrigin.cameraOrigin.y)
                    )
                    presentedObjectWorldPositions = nextObjectWorldPositions
                }
            }
            withAnimation(.linear(duration: playerStepDuration)) {
                applyState()
            }
        } else {
            playerStepAnimation = nil
            objectStepAnimations = [:]
            var transaction = Transaction()
            transaction.animation = nil
            withTransaction(transaction) {
                applyState()
            }
        }
    }

    private func resolvedPlayerStepAnimation(
        nextIdentity: FieldPresentationIdentity,
        nextStepAnimation: PlayerStepAnimationState?,
        shouldAnimateObjects: Bool,
        now: Date = Date()
    ) -> PlayerStepAnimationState? {
        if let nextStepAnimation {
            return nextStepAnimation
        }

        guard shouldAnimateObjects,
              let currentAnimation = playerStepAnimation else {
            return nil
        }

        guard Self.shouldRetainPlayerStepAnimation(
            currentDestinationPosition: currentAnimation.destinationPosition,
            startedAt: currentAnimation.startedAt,
            nextPlayerPosition: nextIdentity.playerPosition,
            now: now,
            stepDuration: playerStepDuration
        ) else {
            return nil
        }

        return currentAnimation
    }

    private func transitionDirection(to nextIdentity: FieldPresentationIdentity, nextMap: MapManifest) -> FacingDirection? {
        guard let previousIdentity = presentationIdentity,
              let previousMap = presentedMap else {
            return nil
        }

        if previousIdentity.mapID == nextIdentity.mapID {
            return Self.stepDirection(from: previousIdentity.playerPosition, to: nextIdentity.playerPosition)
        }

        return Self.connectedStepDirection(
            from: previousMap,
            previousPosition: previousIdentity.playerPosition,
            to: nextMap,
            nextPosition: nextIdentity.playerPosition
        )
    }

    private func connectedStepOriginPosition(
        to nextIdentity: FieldPresentationIdentity,
        nextMap: MapManifest,
        direction: FacingDirection?
    ) -> (playerWorldPosition: FieldPixelPoint, cameraOrigin: FieldPixelPoint)? {
        guard let previousIdentity = presentationIdentity,
              previousIdentity.mapID != nextIdentity.mapID,
              let direction,
              let originPosition = Self.connectedStepOriginPosition(
                  nextPosition: nextIdentity.playerPosition,
                  direction: direction
              ) else {
            return nil
        }

        let metrics = FieldSceneRenderer.sceneMetrics(for: nextMap)
        let originWorldPosition = FieldSceneRenderer.playerWorldPosition(for: originPosition, metrics: metrics)
        let originCamera = FieldCameraState.target(
            playerWorldPosition: originWorldPosition,
            contentPixelSize: metrics.contentPixelSize
        )
        return (originWorldPosition, originCamera.origin)
    }

    private func makePlayerStepAnimation(to nextIdentity: FieldPresentationIdentity, direction: FacingDirection?) -> PlayerStepAnimationState? {
        guard let previousIdentity = presentationIdentity,
              let direction else {
            return nil
        }

        let now = Date()
        let phaseOffset = Self.chainedWalkPhaseOffset(
            previousDirection: playerStepAnimation?.direction,
            nextDirection: direction,
            previousStartedAt: playerStepAnimation?.startedAt,
            now: now,
            stepDuration: playerStepDuration
        )

        return PlayerStepAnimationState(
            mapID: nextIdentity.mapID,
            destinationPosition: nextIdentity.playerPosition,
            startedAt: now,
            direction: direction,
            phaseOffset: phaseOffset
        )
    }

    private func makeObjectStepAnimations(to nextIdentity: FieldPresentationIdentity) -> [String: ObjectStepAnimationState] {
        guard let previousIdentity = presentationIdentity,
              previousIdentity.mapID == nextIdentity.mapID else {
            return [:]
        }

        let previousObjects = Dictionary(uniqueKeysWithValues: previousIdentity.objects.map { ($0.id, $0) })
        return nextIdentity.objects.reduce(into: [:]) { result, object in
            guard let previousObject = previousObjects[object.id] else { return }
            let deltaX = abs(previousObject.position.x - object.position.x)
            let deltaY = abs(previousObject.position.y - object.position.y)
            guard (deltaX + deltaY) == 1 else { return }
            guard object.movementMode != nil || previousObject.movementMode != nil else { return }
            result[object.id] = .init(
                mapID: nextIdentity.mapID,
                objectID: object.id,
                destinationPosition: object.position,
                startedAt: Date()
            )
        }
    }

    static func playerWalkAnimationPhase(
        elapsed: TimeInterval,
        stepDuration: TimeInterval = 16.0 / 60.0,
        phaseOffset: Int = 0
    ) -> Int? {
        guard stepDuration > 0 else { return nil }
        let clampedElapsed = max(0, elapsed)
        guard clampedElapsed < stepDuration else { return nil }
        let phaseDuration = stepDuration / 4
        guard phaseDuration > 0 else { return nil }
        let basePhase = min(3, Int(clampedElapsed / phaseDuration))
        return (basePhase + normalizedPhaseOffset(phaseOffset)) % 4
    }

    static func chainedWalkPhaseOffset(
        previousDirection: FacingDirection?,
        nextDirection: FacingDirection,
        previousStartedAt: Date?,
        now: Date = Date(),
        stepDuration: TimeInterval = 16.0 / 60.0
    ) -> Int {
        guard stepDuration > 0,
              let previousDirection,
              let previousStartedAt,
              previousDirection == nextDirection else {
            return 0
        }

        let elapsed = now.timeIntervalSince(previousStartedAt)
        guard elapsed >= (stepDuration * 0.75),
              elapsed <= (stepDuration * 1.5) else {
            return 0
        }

        return 1
    }

    static func shouldRetainPlayerStepAnimation(
        currentDestinationPosition: TilePoint?,
        startedAt: Date?,
        nextPlayerPosition: TilePoint,
        now: Date = Date(),
        stepDuration: TimeInterval = 16.0 / 60.0
    ) -> Bool {
        guard stepDuration > 0,
              let currentDestinationPosition,
              let startedAt,
              currentDestinationPosition == nextPlayerPosition else {
            return false
        }

        return now.timeIntervalSince(startedAt) < stepDuration
    }

    static func playerUsesWalkingFrame(phase: Int?) -> Bool {
        guard let phase else { return false }
        return phase == 1 || phase == 3
    }

    static func playerUsesMirroredWalkingFrame(facing: FacingDirection, phase: Int?) -> Bool {
        guard phase == 3 else { return false }
        return facing == .up || facing == .down
    }

    private static func stepDirection(from start: TilePoint, to end: TilePoint) -> FacingDirection? {
        if end.x == start.x + 1, end.y == start.y {
            return .right
        }
        if end.x == start.x - 1, end.y == start.y {
            return .left
        }
        if end.x == start.x, end.y == start.y + 1 {
            return .down
        }
        if end.x == start.x, end.y == start.y - 1 {
            return .up
        }
        return nil
    }

    static func connectedStepDirection(
        from previousMap: MapManifest,
        previousPosition: TilePoint,
        to nextMap: MapManifest,
        nextPosition: TilePoint
    ) -> FacingDirection? {
        for connection in previousMap.connections where connection.targetMapID == nextMap.id {
            switch connection.direction {
            case .north:
                let expectedPreviousX = nextPosition.x + (connection.offset * 2)
                guard previousPosition == .init(x: expectedPreviousX, y: 0),
                      nextPosition.y == nextMap.stepHeight - 1 else {
                    continue
                }
                return .up
            case .south:
                let expectedPreviousX = nextPosition.x + (connection.offset * 2)
                guard previousPosition == .init(x: expectedPreviousX, y: previousMap.stepHeight - 1),
                      nextPosition.y == 0 else {
                    continue
                }
                return .down
            case .west:
                let expectedPreviousY = nextPosition.y + (connection.offset * 2)
                guard previousPosition == .init(x: 0, y: expectedPreviousY),
                      nextPosition.x == nextMap.stepWidth - 1 else {
                    continue
                }
                return .left
            case .east:
                let expectedPreviousY = nextPosition.y + (connection.offset * 2)
                guard previousPosition == .init(x: previousMap.stepWidth - 1, y: expectedPreviousY),
                      nextPosition.x == 0 else {
                    continue
                }
                return .right
            }
        }

        return nil
    }

    static func connectedStepOriginPosition(
        nextPosition: TilePoint,
        direction: FacingDirection
    ) -> TilePoint? {
        switch direction {
        case .up:
            return .init(x: nextPosition.x, y: nextPosition.y + 1)
        case .down:
            return .init(x: nextPosition.x, y: nextPosition.y - 1)
        case .left:
            return .init(x: nextPosition.x + 1, y: nextPosition.y)
        case .right:
            return .init(x: nextPosition.x - 1, y: nextPosition.y)
        }
    }

    private static func normalizedPhaseOffset(_ phaseOffset: Int) -> Int {
        let normalized = phaseOffset % 4
        return normalized >= 0 ? normalized : normalized + 4
    }
}
