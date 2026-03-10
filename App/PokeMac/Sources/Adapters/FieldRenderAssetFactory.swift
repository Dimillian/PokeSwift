import PokeCore
import PokeDataModel
import PokeUI

@MainActor
func makeFieldRenderAssets(runtime: GameRuntime) -> FieldRenderAssets? {
    guard let tilesetManifest = runtime.currentTilesetManifest else { return nil }

    let tileset = FieldTilesetDefinition(
        id: tilesetManifest.id,
        imageURL: runtime.content.rootURL.appendingPathComponent(tilesetManifest.imagePath),
        blocksetURL: runtime.content.rootURL.appendingPathComponent(tilesetManifest.blocksetPath),
        sourceTileSize: tilesetManifest.sourceTileSize,
        blockTileWidth: tilesetManifest.blockTileWidth,
        blockTileHeight: tilesetManifest.blockTileHeight
    )

    let spritePairs: [(String, FieldSpriteDefinition)] = runtime.currentFieldSpriteIDs.compactMap { spriteID in
        guard let manifest = runtime.content.overworldSprite(id: spriteID) else { return nil }
        let definition = FieldSpriteDefinition(
            id: manifest.id,
            imageURL: runtime.content.rootURL.appendingPathComponent(manifest.imagePath),
            frameWidth: manifest.frameWidth,
            frameHeight: manifest.frameHeight,
            facingFrames: [
                .down: fieldSpriteFrame(from: manifest.facingFrames.down),
                .up: fieldSpriteFrame(from: manifest.facingFrames.up),
                .left: fieldSpriteFrame(from: manifest.facingFrames.left),
                .right: fieldSpriteFrame(from: manifest.facingFrames.right),
            ]
        )
        return (spriteID, definition)
    }

    return FieldRenderAssets(
        tileset: tileset,
        overworldSprites: Dictionary(uniqueKeysWithValues: spritePairs)
    )
}

private func fieldSpriteFrame(from rect: PixelRect) -> FieldSpriteFrame {
    FieldSpriteFrame(
        x: rect.x,
        y: rect.y,
        width: rect.width,
        height: rect.height,
        flippedHorizontally: rect.flippedHorizontally
    )
}
