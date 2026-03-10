import SwiftUI
import PokeCore
import PokeDataModel

public struct FieldMapView: View {
    let map: MapManifest
    let playerPosition: TilePoint
    let playerFacing: FacingDirection
    let objects: [FieldObjectRenderState]
    let playerSpriteID: String
    let renderAssets: FieldRenderAssets?

    public init(
        map: MapManifest,
        playerPosition: TilePoint,
        playerFacing: FacingDirection,
        objects: [FieldObjectRenderState],
        playerSpriteID: String = "SPRITE_RED",
        renderAssets: FieldRenderAssets? = nil
    ) {
        self.map = map
        self.playerPosition = playerPosition
        self.playerFacing = playerFacing
        self.objects = objects
        self.playerSpriteID = playerSpriteID
        self.renderAssets = renderAssets
    }

    public var body: some View {
        GeometryReader { proxy in
            let pixelWidth = CGFloat(max(1, map.blockWidth * FieldSceneRenderer.blockPixelSize))
            let pixelHeight = CGFloat(max(1, map.blockHeight * FieldSceneRenderer.blockPixelSize))
            let scale = min(proxy.size.width / pixelWidth, proxy.size.height / pixelHeight)
            let renderWidth = pixelWidth * scale
            let renderHeight = pixelHeight * scale

            ZStack {
                if let renderedField {
                    Image(decorative: renderedField, scale: 1)
                        .interpolation(.none)
                        .resizable()
                } else {
                    placeholderField
                }
            }
            .frame(width: renderWidth, height: renderHeight)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
    }

    private var renderedField: CGImage? {
        guard let renderAssets else { return nil }
        return try? FieldSceneRenderer.render(
            map: map,
            playerPosition: playerPosition,
            playerFacing: playerFacing,
            playerSpriteID: playerSpriteID,
            objects: objects,
            assets: renderAssets
        )
    }

    @ViewBuilder
    private var placeholderField: some View {
        let stepWidth = max(1, map.stepWidth)
        let stepHeight = max(1, map.stepHeight)
        let tileSize = min(
            CGFloat(map.blockWidth * FieldSceneRenderer.blockPixelSize) / CGFloat(stepWidth),
            CGFloat(map.blockHeight * FieldSceneRenderer.blockPixelSize) / CGFloat(stepHeight)
        )

        ZStack(alignment: .topLeading) {
            ForEach(0..<stepHeight, id: \.self) { y in
                ForEach(0..<stepWidth, id: \.self) { x in
                    Rectangle()
                        .fill(tileColor(x: x, y: y))
                        .frame(width: tileSize, height: tileSize)
                        .position(x: (CGFloat(x) * tileSize) + (tileSize / 2), y: (CGFloat(y) * tileSize) + (tileSize / 2))
                }
            }

            ForEach(objects, id: \.id) { object in
                Rectangle()
                    .fill(objectColor(for: object.sprite))
                    .frame(width: tileSize * 0.88, height: tileSize * 0.88)
                    .overlay {
                        Text(object.displayName.prefix(1))
                            .font(.system(size: tileSize * 0.45, weight: .black, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .position(x: (CGFloat(object.position.x) * tileSize) + (tileSize / 2), y: (CGFloat(object.position.y) * tileSize) + (tileSize / 2))
            }

            Capsule()
                .fill(Color.black)
                .frame(width: tileSize * 0.8, height: tileSize * 0.9)
                .overlay(alignment: overlayAlignment(for: playerFacing)) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: tileSize * 0.18, height: tileSize * 0.18)
                        .offset(directionOffset(for: playerFacing, tileSize: tileSize))
                }
                .position(x: (CGFloat(playerPosition.x) * tileSize) + (tileSize / 2), y: (CGFloat(playerPosition.y) * tileSize) + (tileSize / 2))
        }
    }

    private func tileColor(x: Int, y: Int) -> Color {
        let blockX = max(0, min(map.blockWidth - 1, x / 2))
        let blockY = max(0, min(map.blockHeight - 1, y / 2))
        let index = min(map.blockIDs.count - 1, (blockY * map.blockWidth) + blockX)
        let blockID = map.blockIDs.isEmpty ? 0 : map.blockIDs[index]
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
