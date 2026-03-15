import SwiftUI
import PokeDataModel
import PokeRender

struct FixedViewportPlaceholderField: View {
    @Environment(\.pokeAppearanceMode) private var appearanceMode
    @Environment(\.pokeGameplayHDREnabled) private var gameplayHDREnabled
    @Environment(\.colorScheme) private var colorScheme

    let map: MapManifest
    let playerPosition: TilePoint
    let playerFacing: FacingDirection
    let objects: [FieldRenderableObjectState]
    let metrics: FieldSceneMetrics
    let transition: FieldTransitionTelemetry?
    let alert: FieldAlertTelemetry?
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
                        Text(object.id.prefix(1))
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

            if let alertObject = alertObject {
                let worldX = CGFloat((alertObject.position.x * FieldSceneRenderer.stepPixelSize) + metrics.paddingPixels.width)
                let worldY = CGFloat((alertObject.position.y * FieldSceneRenderer.stepPixelSize) + metrics.paddingPixels.height)

                FieldAlertBubbleView(kind: alertObject.kind, displayScale: displayScale)
                    .position(
                        x: ((worldX - cameraOrigin.x) * displayScale) + (stepSize / 2),
                        y: ((worldY - cameraOrigin.y) * displayScale) - (displayScale * 3)
                    )
            }
        }
        .gameplayScreenEffect(
            displayStyle: displayStyle,
            displayScale: displayScale,
            hdrBoost: fieldShaderHDRBoost
        )
        .frame(width: viewportWidth, height: viewportHeight, alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            FieldViewportTransitionOverlay(transition: transition)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
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

    private var alertObject: (position: TilePoint, kind: FieldAlertBubbleKind)? {
        guard let alert,
              let position = objects.first(where: { $0.id == alert.objectID })?.position else {
            return nil
        }
        return (position, alert.kind)
    }
}
