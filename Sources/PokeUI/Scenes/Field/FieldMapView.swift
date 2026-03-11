import Foundation
import SwiftUI
import PokeCore
import PokeDataModel

public struct FieldMapView: View {
    let map: MapManifest
    let playerPosition: TilePoint
    let playerFacing: FacingDirection
    let playerStepDuration: TimeInterval
    let objects: [FieldObjectRenderState]
    let playerSpriteID: String
    let renderAssets: FieldRenderAssets?
    let transition: FieldTransitionTelemetry?
    let displayStyle: FieldDisplayStyle

    @State private var renderedScene: FieldRenderedScene?
    @State private var presentedCameraOrigin: CGPoint = .zero
    @State private var presentedPlayerWorldPosition: CGPoint = .zero
    @State private var presentedObjectWorldPositions: [String: CGPoint] = [:]
    @State private var presentationIdentity: FieldPresentationIdentity?
    @State private var playerStepAnimation: PlayerStepAnimationState?
    @State private var objectStepAnimations: [String: ObjectStepAnimationState] = [:]

    public init(
        map: MapManifest,
        playerPosition: TilePoint,
        playerFacing: FacingDirection,
        playerStepDuration: TimeInterval = 16.0 / 60.0,
        objects: [FieldObjectRenderState],
        playerSpriteID: String = "SPRITE_RED",
        renderAssets: FieldRenderAssets? = nil,
        transition: FieldTransitionTelemetry? = nil,
        displayStyle: FieldDisplayStyle = .defaultGameplayStyle
    ) {
        self.map = map
        self.playerPosition = playerPosition
        self.playerFacing = playerFacing
        self.playerStepDuration = playerStepDuration
        self.objects = objects
        self.playerSpriteID = playerSpriteID
        self.renderAssets = renderAssets
        self.transition = transition
        self.displayStyle = displayStyle
    }

    public var body: some View {
        GeometryReader { proxy in
            let scale = viewportScale(for: proxy.size)
            let viewportWidth = CGFloat(FieldSceneRenderer.viewportPixelSize.width) * scale
            let viewportHeight = CGFloat(FieldSceneRenderer.viewportPixelSize.height) * scale

            ZStack {
                if let renderedScene {
                    FixedViewportRenderedField(
                        scene: renderedScene,
                        playerFacing: playerFacing,
                        playerStepAnimation: playerStepAnimation,
                        playerStepDuration: playerStepDuration,
                        transition: transition,
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
                        playerPosition: playerPosition,
                        playerFacing: playerFacing,
                        objects: objects,
                        metrics: FieldSceneRenderer.sceneMetrics(for: map),
                        transition: transition,
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
            renderAssets: renderAssets,
            displayStyle: displayStyle
        )
    }

    static func sceneRenderTaskIdentity(
        map: MapManifest,
        playerFacing: FacingDirection,
        playerSpriteID: String,
        objects: [FieldObjectRenderState],
        renderAssets: FieldRenderAssets?,
        displayStyle _: FieldDisplayStyle
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
        let shouldAnimate = shouldAnimateTransition(to: nextIdentity)
        let nextStepAnimation = makePlayerStepAnimation(to: nextIdentity)
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
        }

        if shouldAnimate || shouldAnimateObjects {
            playerStepAnimation = nextStepAnimation
            objectStepAnimations = nextObjectStepAnimations
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

    private func shouldAnimateTransition(to nextIdentity: FieldPresentationIdentity) -> Bool {
        guard let previousIdentity = presentationIdentity,
              previousIdentity.mapID == nextIdentity.mapID else {
            return false
        }

        let deltaX = abs(previousIdentity.playerPosition.x - nextIdentity.playerPosition.x)
        let deltaY = abs(previousIdentity.playerPosition.y - nextIdentity.playerPosition.y)
        return (deltaX + deltaY) == 1
    }

    private func makePlayerStepAnimation(to nextIdentity: FieldPresentationIdentity) -> PlayerStepAnimationState? {
        guard shouldAnimateTransition(to: nextIdentity) else {
            return nil
        }

        return PlayerStepAnimationState(
            mapID: nextIdentity.mapID,
            destinationPosition: nextIdentity.playerPosition,
            startedAt: Date()
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

    private func viewportScale(for size: CGSize) -> CGFloat {
        let rawScale = min(
            size.width / CGFloat(FieldSceneRenderer.viewportPixelSize.width),
            size.height / CGFloat(FieldSceneRenderer.viewportPixelSize.height)
        )
        guard rawScale.isFinite, rawScale > 0 else {
            return 1
        }
        if rawScale >= 1 {
            return max(1, floor(rawScale))
        }
        return rawScale
    }

    static func playerWalkAnimationPhase(
        elapsed: TimeInterval,
        stepDuration: TimeInterval = 16.0 / 60.0
    ) -> Int? {
        guard stepDuration > 0 else { return nil }
        let clampedElapsed = max(0, elapsed)
        guard clampedElapsed < stepDuration else { return nil }
        let phaseDuration = stepDuration / 4
        guard phaseDuration > 0 else { return nil }
        return min(3, Int(clampedElapsed / phaseDuration))
    }

    static func playerUsesWalkingFrame(phase: Int?) -> Bool {
        guard let phase else { return false }
        return phase == 1 || phase == 3
    }

    static func playerUsesMirroredWalkingFrame(facing: FacingDirection, phase: Int?) -> Bool {
        guard phase == 3 else { return false }
        return facing == .up || facing == .down
    }
}

private struct RenderedFieldSceneBox: @unchecked Sendable {
    let scene: FieldRenderedScene
}

struct FieldSceneRenderIdentity: Equatable {
    let map: MapManifest
    let playerFacing: FacingDirection
    let playerSpriteID: String
    let objects: [FieldObjectRenderState]
    let assets: FieldRenderAssets
}

private struct FieldPresentationIdentity: Equatable {
    let mapID: String
    let playerPosition: TilePoint
    let objects: [FieldObjectPresentationIdentity]
}

private struct PlayerStepAnimationState: Equatable {
    let mapID: String
    let destinationPosition: TilePoint
    let startedAt: Date
}

private struct FieldObjectPresentationIdentity: Equatable {
    let id: String
    let position: TilePoint
    let movementMode: ActorMovementMode?
}

private struct ObjectStepAnimationState: Equatable {
    let mapID: String
    let objectID: String
    let destinationPosition: TilePoint
    let startedAt: Date
}

private struct FixedViewportRenderedField: View {
    let scene: FieldRenderedScene
    let playerFacing: FacingDirection
    let playerStepAnimation: PlayerStepAnimationState?
    let playerStepDuration: TimeInterval
    let transition: FieldTransitionTelemetry?
    let displayStyle: FieldDisplayStyle
    let displayScale: CGFloat
    let cameraOrigin: CGPoint
    let playerWorldPosition: CGPoint
    let objectWorldPositions: [String: CGPoint]
    let objectStepAnimations: [String: ObjectStepAnimationState]

    var body: some View {
        let cornerRadius = max(6, displayScale * 2.5)

        TimelineView(.animation) { timeline in
            let playerWalkPhase = playerWalkAnimationPhase(at: timeline.date)

            ZStack(alignment: .topLeading) {
                lcdBackground

                Image(decorative: scene.backgroundImage, scale: 1)
                    .interpolation(.none)
                    .resizable()
                    .frame(
                        width: CGFloat(scene.metrics.contentPixelSize.width) * displayScale,
                        height: CGFloat(scene.metrics.contentPixelSize.height) * displayScale
                    )
                    .offset(
                        x: -cameraOrigin.x * displayScale,
                        y: -cameraOrigin.y * displayScale
                    )

                ForEach(sortedActors) { actor in
                    let renderedWorldPosition = actor.role == .player
                        ? playerWorldPosition
                        : (objectWorldPositions[actor.id] ?? CGPoint(x: CGFloat(actor.worldPosition.x), y: CGFloat(actor.worldPosition.y)))
                    let objectWalkPhase = objectWalkAnimationPhase(actorID: actor.id, at: timeline.date)
                    let usesWalkingFrame = actor.walkingImage != nil && (
                        (actor.role == .player && FieldMapView.playerUsesWalkingFrame(phase: playerWalkPhase)) ||
                        (actor.role == .object && FieldMapView.playerUsesWalkingFrame(phase: objectWalkPhase))
                    )
                    let usesMirroredWalkFrame = actor.role == .player &&
                        FieldMapView.playerUsesMirroredWalkingFrame(facing: playerFacing, phase: playerWalkPhase)
                    let image = usesWalkingFrame ? (actor.walkingImage ?? actor.image) : actor.image
                    let flipsHorizontally = actor.role == .player
                        ? actor.flippedHorizontally != usesMirroredWalkFrame
                        : actor.flippedHorizontally

                    Image(decorative: image, scale: 1)
                        .interpolation(.none)
                        .resizable()
                        .frame(
                            width: CGFloat(actor.size.width) * displayScale,
                            height: CGFloat(actor.size.height) * displayScale
                        )
                        .scaleEffect(x: flipsHorizontally ? -1 : 1, y: -1, anchor: .center)
                        .position(
                            x: ((renderedWorldPosition.x - cameraOrigin.x) + CGFloat(actor.size.width) / 2) * displayScale,
                            y: ((renderedWorldPosition.y - cameraOrigin.y) + CGFloat(actor.size.height) / 2) * displayScale
                        )
                        .zIndex(renderedWorldPosition.y)
                }

            }
            .fieldScreenEffect(displayStyle: displayStyle, displayScale: displayScale)
            .frame(
                width: CGFloat(FieldSceneRenderer.viewportPixelSize.width) * displayScale,
                height: CGFloat(FieldSceneRenderer.viewportPixelSize.height) * displayScale,
                alignment: .topLeading
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                FieldViewportTransitionOverlay(transition: transition)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.black.opacity(0.16), lineWidth: max(1, displayScale * 0.16))
            }
        }
    }

    private func playerWalkAnimationPhase(at date: Date) -> Int? {
        guard let playerStepAnimation,
              playerStepAnimation.mapID == scene.mapID else {
            return nil
        }
        let elapsed = date.timeIntervalSince(playerStepAnimation.startedAt)
        return FieldMapView.playerWalkAnimationPhase(
            elapsed: elapsed,
            stepDuration: playerStepDuration
        )
    }

    private func objectWalkAnimationPhase(actorID: String, at date: Date) -> Int? {
        guard let animation = objectStepAnimations[actorID],
              animation.mapID == scene.mapID else {
            return nil
        }
        let elapsed = date.timeIntervalSince(animation.startedAt)
        return FieldMapView.playerWalkAnimationPhase(
            elapsed: elapsed,
            stepDuration: playerStepDuration
        )
    }

    private var sortedActors: [FieldRenderedActor] {
        scene.actors.sorted { lhs, rhs in
            if lhs.worldPosition.y == rhs.worldPosition.y {
                return lhs.id < rhs.id
            }
            return lhs.worldPosition.y < rhs.worldPosition.y
        }
    }

    private var lcdBackground: some View {
        ZStack {
            Rectangle()
                .fill(Color(red: 0.49, green: 0.56, blue: 0.17))

            LinearGradient(
                colors: [
                    Color.white.opacity(0.07),
                    Color.clear,
                    Color.black.opacity(0.08),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

private struct FixedViewportPlaceholderField: View {
    let map: MapManifest
    let playerPosition: TilePoint
    let playerFacing: FacingDirection
    let objects: [FieldObjectRenderState]
    let metrics: FieldSceneMetrics
    let transition: FieldTransitionTelemetry?
    let displayStyle: FieldDisplayStyle
    let displayScale: CGFloat
    let cameraOrigin: CGPoint
    let playerWorldPosition: CGPoint

    var body: some View {
        let viewportWidth = CGFloat(FieldSceneRenderer.viewportPixelSize.width) * displayScale
        let viewportHeight = CGFloat(FieldSceneRenderer.viewportPixelSize.height) * displayScale
        let stepSize = CGFloat(FieldSceneRenderer.stepPixelSize) * displayScale
        let contentOrigin = CGPoint(x: -cameraOrigin.x * displayScale, y: -cameraOrigin.y * displayScale)
        let stepCountX = Int(ceil(Double(FieldSceneRenderer.viewportPixelSize.width) / Double(FieldSceneRenderer.stepPixelSize))) + 3
        let stepCountY = Int(ceil(Double(FieldSceneRenderer.viewportPixelSize.height) / Double(FieldSceneRenderer.stepPixelSize))) + 3
        let startStepX = Int(floor(cameraOrigin.x / CGFloat(FieldSceneRenderer.stepPixelSize))) - 1
        let startStepY = Int(floor(cameraOrigin.y / CGFloat(FieldSceneRenderer.stepPixelSize))) - 1
        let cornerRadius = max(6, displayScale * 2.5)

        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(Color(red: 0.49, green: 0.56, blue: 0.17))

            ForEach(0..<stepCountY, id: \.self) { row in
                ForEach(0..<stepCountX, id: \.self) { column in
                    let paddedStepX = startStepX + column
                    let paddedStepY = startStepY + row
                    Rectangle()
                        .fill(tileColor(forPaddedStepX: paddedStepX, paddedStepY: paddedStepY))
                        .frame(width: stepSize, height: stepSize)
                        .position(
                            x: contentOrigin.x + (CGFloat(paddedStepX * FieldSceneRenderer.stepPixelSize) * displayScale) + (stepSize / 2),
                            y: contentOrigin.y + (CGFloat(paddedStepY * FieldSceneRenderer.stepPixelSize) * displayScale) + (stepSize / 2)
                        )
                }
            }

            ForEach(objects, id: \.id) { object in
                let worldX = CGFloat((object.position.x * FieldSceneRenderer.stepPixelSize) + metrics.paddingPixels.width)
                let worldY = CGFloat((object.position.y * FieldSceneRenderer.stepPixelSize) + metrics.paddingPixels.height)
                Rectangle()
                    .fill(objectColor(for: object.sprite))
                    .frame(width: stepSize * 0.88, height: stepSize * 0.88)
                    .overlay {
                        Text(object.displayName.prefix(1))
                            .font(.system(size: max(8, stepSize * 0.34), weight: .black, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .position(
                        x: ((worldX - cameraOrigin.x) * displayScale) + (stepSize / 2),
                        y: ((worldY - cameraOrigin.y) * displayScale) + (stepSize / 2)
                    )
            }

            Capsule()
                .fill(Color.black)
                .frame(width: stepSize * 0.8, height: stepSize * 0.9)
                .overlay(alignment: overlayAlignment(for: playerFacing)) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: max(3, stepSize * 0.16), height: max(3, stepSize * 0.16))
                        .offset(directionOffset(for: playerFacing, tileSize: stepSize))
                }
                .position(
                    x: ((playerWorldPosition.x - cameraOrigin.x) * displayScale) + (stepSize / 2),
                    y: ((playerWorldPosition.y - cameraOrigin.y) * displayScale) + (stepSize / 2)
                )

        }
        .fieldScreenEffect(displayStyle: displayStyle, displayScale: displayScale)
        .frame(width: viewportWidth, height: viewportHeight, alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            FieldViewportTransitionOverlay(transition: transition)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.black.opacity(0.16), lineWidth: max(1, displayScale * 0.16))
        }
    }

    private func tileColor(forPaddedStepX paddedStepX: Int, paddedStepY: Int) -> Color {
        let paddingStepsX = metrics.paddingPixels.width / FieldSceneRenderer.stepPixelSize
        let paddingStepsY = metrics.paddingPixels.height / FieldSceneRenderer.stepPixelSize
        let mapStepX = paddedStepX - paddingStepsX
        let mapStepY = paddedStepY - paddingStepsY

        let blockX = mapStepX / 2
        let blockY = mapStepY / 2
        let blockID = map.blockID(atBlockX: blockX, blockY: blockY)

        switch map.tileset {
        case "OVERWORLD":
            return (blockID % 5 == 0) ? Color(red: 0.86, green: 0.93, blue: 0.79) : Color(red: 0.79, green: 0.87, blue: 0.73)
        case "DOJO":
            return (blockID % 4 == 0) ? Color(red: 0.96, green: 0.92, blue: 0.83) : Color(red: 0.88, green: 0.84, blue: 0.74)
        default:
            return (blockID % 3 == 0) ? Color(red: 0.93, green: 0.93, blue: 0.9) : Color(red: 0.84, green: 0.84, blue: 0.8)
        }
    }

    private func objectColor(for sprite: String) -> Color {
        switch sprite {
        case _ where sprite.contains("OAK"):
            return Color(red: 0.28, green: 0.43, blue: 0.31)
        case _ where sprite.contains("BLUE"):
            return Color(red: 0.2, green: 0.33, blue: 0.62)
        case _ where sprite.contains("POKE_BALL"):
            return Color(red: 0.75, green: 0.2, blue: 0.18)
        case _ where sprite.contains("MOM"):
            return Color(red: 0.67, green: 0.42, blue: 0.58)
        default:
            return Color(red: 0.45, green: 0.45, blue: 0.45)
        }
    }

    private func overlayAlignment(for facing: FacingDirection) -> Alignment {
        switch facing {
        case .up:
            return .top
        case .down:
            return .bottom
        case .left:
            return .leading
        case .right:
            return .trailing
        }
    }

    private func directionOffset(for facing: FacingDirection, tileSize: CGFloat) -> CGSize {
        let amount = tileSize * 0.1
        switch facing {
        case .up:
            return CGSize(width: 0, height: amount)
        case .down:
            return CGSize(width: 0, height: -amount)
        case .left:
            return CGSize(width: amount, height: 0)
        case .right:
            return CGSize(width: -amount, height: 0)
        }
    }
}

private struct FieldViewportTransitionOverlay: View {
    let transition: FieldTransitionTelemetry?

    var body: some View {
        Rectangle()
            .fill(Color.black)
            .opacity(targetOpacity)
            .animation(.linear(duration: 0.12), value: transition?.phase)
            .allowsHitTesting(false)
    }

    private var targetOpacity: Double {
        transition?.phase == "fadingOut" ? 1 : 0
    }
}
