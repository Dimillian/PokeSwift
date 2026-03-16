import Foundation
import ImageIO
import PokeDataModel

public extension LoadedContent {
    func fieldRenderIssues(map: MapManifest, spriteIDs: [String]) -> [String] {
        var issues: [String] = []

        guard let tileset = tileset(id: map.tileset) else {
            return ["missing tileset manifest: \(map.tileset)"]
        }

        let tilesetURL = rootURL.appendingPathComponent(tileset.imagePath)
        let blocksetURL = rootURL.appendingPathComponent(tileset.blocksetPath)

        guard FileManager.default.fileExists(atPath: tilesetURL.path) else {
            return ["missing tileset image: \(tileset.imagePath)"]
        }
        guard FileManager.default.fileExists(atPath: blocksetURL.path) else {
            return ["missing tileset blockset: \(tileset.blocksetPath)"]
        }

        let tilesPerBlock = tileset.blockTileWidth * tileset.blockTileHeight
        guard tilesPerBlock > 0 else {
            return ["invalid tiles per block for tileset: \(tileset.id)"]
        }

        do {
            let blocksetData = try Data(contentsOf: blocksetURL)
            if blocksetData.count.isMultiple(of: tilesPerBlock) == false {
                issues.append("invalid blockset length: \(tileset.blocksetPath)")
            } else if let tileCapacity = imageTileCapacity(at: tilesetURL, tileSize: tileset.sourceTileSize) {
                let blockCount = blocksetData.count / tilesPerBlock
                let blockBytes = [UInt8](blocksetData)
                let uniqueBlockIDs = Set(map.blockIDs)
                for blockID in uniqueBlockIDs {
                    if blockID >= blockCount {
                        issues.append("invalid block \(blockID) for tileset \(tileset.id)")
                        continue
                    }

                    let start = blockID * tilesPerBlock
                    let tiles = blockBytes[start..<(start + tilesPerBlock)]
                    for tileIndex in tiles where Int(tileIndex) >= tileCapacity {
                        issues.append("invalid tile \(tileIndex) for tileset \(tileset.id)")
                        break
                    }
                }
            } else {
                issues.append("invalid tileset image: \(tileset.imagePath)")
            }
        } catch {
            issues.append("failed to read tileset assets for \(tileset.id)")
        }

        for animatedTile in tileset.animation.animatedTiles {
            for frameImagePath in animatedTile.frameImagePaths {
                let frameURL = rootURL.appendingPathComponent(frameImagePath)
                guard FileManager.default.fileExists(atPath: frameURL.path) else {
                    issues.append("missing tileset animation frame: \(frameImagePath)")
                    continue
                }
                guard let size = imagePixelSize(at: frameURL) else {
                    issues.append("invalid tileset animation frame: \(frameImagePath)")
                    continue
                }
                if size.width != tileset.sourceTileSize || size.height != tileset.sourceTileSize {
                    issues.append("unexpected tileset animation frame size: \(frameImagePath)")
                }
            }
        }

        let uniqueSpriteIDs = Array(Set(spriteIDs)).sorted()
        for spriteID in uniqueSpriteIDs {
            guard let sprite = overworldSprite(id: spriteID) else {
                issues.append("missing sprite manifest: \(spriteID)")
                continue
            }

            let spriteURL = rootURL.appendingPathComponent(sprite.imagePath)
            guard FileManager.default.fileExists(atPath: spriteURL.path) else {
                issues.append("missing sprite image: \(sprite.imagePath)")
                continue
            }

            guard let size = imagePixelSize(at: spriteURL) else {
                issues.append("invalid sprite image: \(sprite.imagePath)")
                continue
            }

            let frames = [
                sprite.facingFrames.down,
                sprite.facingFrames.up,
                sprite.facingFrames.left,
                sprite.facingFrames.right,
            ] + [
                sprite.walkingFrames?.down,
                sprite.walkingFrames?.up,
                sprite.walkingFrames?.left,
                sprite.walkingFrames?.right,
            ].compactMap { $0 }
            for frame in frames {
                let maxX = frame.x + frame.width
                let maxY = frame.y + frame.height
                if frame.x < 0 || frame.y < 0 || maxX > size.width || maxY > size.height {
                    issues.append("sprite frame out of bounds: \(spriteID)")
                    break
                }
            }
        }

        return Array(Set(issues)).sorted()
    }

    private func imageTileCapacity(at url: URL, tileSize: Int) -> Int? {
        guard tileSize > 0, let size = imagePixelSize(at: url) else { return nil }
        return max(1, (size.width / tileSize) * (size.height / tileSize))
    }

    private func imagePixelSize(at url: URL) -> (width: Int, height: Int)? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int
        else {
            return nil
        }

        return (width, height)
    }
}
