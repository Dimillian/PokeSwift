import Foundation
import SwiftUI
import PokeDataModel
import PokeRender

struct FixedViewportRenderedField: View {
    @Environment(\.pokeAppearanceMode) private var appearanceMode
    @Environment(\.pokeGameplayHDREnabled) private var gameplayHDREnabled
    @Environment(\.colorScheme) private var colorScheme

    let scene: FieldRenderedScene
    let playerFacing: FacingDirection
    let playerStepAnimation: PlayerStepAnimationState?
    let playerStepDuration: TimeInterval
    let transition: FieldTransitionTelemetry?
    let alert: FieldAlertTelemetry?
    let displayStyle: FieldDisplayStyle
    let displayScale: CGFloat
    let cameraOrigin: CGPoint
    let playerWorldPosition: CGPoint
    let objectWorldPositions: [String: CGPoint]
    let objectStepAnimations: [String: ObjectStepAnimationState]

    var body: some View {
        let cornerRadius = max(6, displayScale * 2.5)
        let hasActiveStepAnimation = playerStepAnimation != nil || objectStepAnimations.isEmpty == false
        let hasAnimatedTiles = scene.tileset.animation.isAnimated && scene.animatedTilePlacements.isEmpty == false
        let walkAnimationInterval = max(1.0 / 120.0, playerStepDuration / 8.0)
        let timelineInterval = hasAnimatedTiles ? min(walkAnimationInterval, 1.0 / 60.0) : walkAnimationInterval

        TimelineView(
            .animation(
                minimumInterval: timelineInterval,
                paused: hasActiveStepAnimation == false && hasAnimatedTiles == false
            )
        ) { timeline in
            let playerWalkPhase = playerWalkAnimationPhase(at: timeline.date)
            let tileAnimationState = FieldSceneRenderer.tileAnimationVisualState(
                animation: scene.tileset.animation,
                visibleFieldFrameCount: max(0, Int(floor(ProcessInfo.processInfo.systemUptime * 60)))
            )
            let animatedOverlayImage = FieldSceneRenderer.animatedOverlayImage(
                for: scene,
                visualState: tileAnimationState
            )

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

                if let animatedOverlayImage {
                    Image(decorative: animatedOverlayImage, scale: 1)
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
                }

                ForEach(scene.actors) { actor in
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

                if let alert, let alertActor = alertActor {
                    FieldAlertBubbleView(kind: alert.kind, displayScale: displayScale)
                        .position(
                            x: ((alertActor.worldPosition.x - cameraOrigin.x) + CGFloat(alertActor.size.width) / 2) * displayScale,
                            y: ((alertActor.worldPosition.y - cameraOrigin.y) - 3) * displayScale
                        )
                        .zIndex(Double(alertActor.worldPosition.y + 1000))
                }
            }
            .gameplayScreenEffect(
                displayStyle: displayStyle,
                displayScale: displayScale,
                hdrBoost: fieldShaderHDRBoost
            )
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
            stepDuration: playerStepDuration,
            phaseOffset: playerStepAnimation.phaseOffset
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

    private var lcdBackground: some View {
        Rectangle()
            .fill(Color(red: 0.49, green: 0.56, blue: 0.17))
    }

    private var fieldShaderHDRBoost: Float {
        Float(
            PokeThemePalette.gameplayHDRProfile(
                appearanceMode: appearanceMode,
                colorScheme: colorScheme,
                isEnabled: gameplayHDREnabled
            )
            .fieldShaderBoost
        )
    }
}

private extension FixedViewportRenderedField {
    var alertActor: FieldAlertActorPosition? {
        guard let alert else { return nil }
        guard let actor = scene.actors.first(where: { $0.id == alert.objectID }) else { return nil }
        let worldPosition = objectWorldPositions[actor.id] ?? CGPoint(
            x: CGFloat(actor.worldPosition.x),
            y: CGFloat(actor.worldPosition.y)
        )
        return FieldAlertActorPosition(
            worldPosition: worldPosition,
            size: CGSize(width: CGFloat(actor.size.width), height: CGFloat(actor.size.height))
        )
    }
}
