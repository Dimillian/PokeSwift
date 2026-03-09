import Foundation
import ImageIO
import PokeDataModel

public struct LoadedContent: Sendable {
    public let rootURL: URL
    public let gameManifest: GameManifest
    public let constantsManifest: ConstantsManifest
    public let charmapManifest: CharmapManifest
    public let titleManifest: TitleSceneManifest
    public let audioManifest: AudioManifest
    public let gameplayManifest: GameplayManifest

    public init(
        rootURL: URL,
        gameManifest: GameManifest,
        constantsManifest: ConstantsManifest,
        charmapManifest: CharmapManifest,
        titleManifest: TitleSceneManifest,
        audioManifest: AudioManifest,
        gameplayManifest: GameplayManifest
    ) {
        self.rootURL = rootURL
        self.gameManifest = gameManifest
        self.constantsManifest = constantsManifest
        self.charmapManifest = charmapManifest
        self.titleManifest = titleManifest
        self.audioManifest = audioManifest
        self.gameplayManifest = gameplayManifest
    }

    public var contentRoot: URL {
        rootURL
    }

    public var titleSceneManifest: TitleSceneManifest {
        titleManifest
    }

    public func map(id: String) -> MapManifest? {
        gameplayManifest.maps.first { $0.id == id }
    }

    public func tileset(id: String) -> TilesetManifest? {
        gameplayManifest.tilesets.first { $0.id == id }
    }

    public func overworldSprite(id: String) -> OverworldSpriteManifest? {
        gameplayManifest.overworldSprites.first { $0.id == id }
    }

    public func dialogue(id: String) -> DialogueManifest? {
        gameplayManifest.dialogues.first { $0.id == id }
    }

    public func script(id: String) -> ScriptManifest? {
        gameplayManifest.scripts.first { $0.id == id }
    }

    public func species(id: String) -> SpeciesManifest? {
        gameplayManifest.species.first { $0.id == id }
    }

    public func move(id: String) -> MoveManifest? {
        gameplayManifest.moves.first { $0.id == id }
    }

    public func trainerBattle(id: String) -> TrainerBattleManifest? {
        gameplayManifest.trainerBattles.first { $0.id == id }
    }

    public func fieldRenderIssues(map: MapManifest, spriteIDs: [String]) -> [String] {
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
            ]
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

public protocol ContentLoader: Sendable {
    func load() throws -> LoadedContent
    func loadContent(variant: GameVariant) throws -> LoadedContent
}

public enum ContentLoadError: Error, LocalizedError {
    case missingRoot(URL)
    case missingManifest(String)
    case invalidAsset(String)

    public var errorDescription: String? {
        switch self {
        case let .missingRoot(url):
            "Missing content root at \(url.path)"
        case let .missingManifest(name):
            "Missing manifest \(name)"
        case let .invalidAsset(path):
            "Missing asset at \(path)"
        }
    }
}

public final class FileSystemContentLoader: ContentLoader {
    private let rootURL: URL
    private let decoder = JSONDecoder()

    public init(rootURL: URL? = nil, bundle: Bundle = .main) {
        self.rootURL = rootURL ?? ContentLocator.defaultContentRoot(bundle: bundle)
    }

    public func load() throws -> LoadedContent {
        try loadContent(variant: .red)
    }

    public func loadContent(variant: GameVariant) throws -> LoadedContent {
        let variantRoot = try resolveVariantRoot(for: variant)
        let gameManifest: GameManifest = try decode("game_manifest.json", at: variantRoot)
        let constantsManifest: ConstantsManifest = try decode("constants.json", at: variantRoot)
        let charmapManifest: CharmapManifest = try decode("charmap.json", at: variantRoot)
        let titleManifest: TitleSceneManifest = try decode("title_manifest.json", at: variantRoot)
        let audioManifest: AudioManifest = try decode("audio_manifest.json", at: variantRoot)
        let gameplayManifest: GameplayManifest = try decode("gameplay_manifest.json", at: variantRoot)

        let requiredAssetPaths =
            titleManifest.assets.map(\.relativePath) +
            gameplayManifest.tilesets.flatMap { [$0.imagePath, $0.blocksetPath] } +
            gameplayManifest.overworldSprites.map(\.imagePath)

        for relativePath in requiredAssetPaths {
            let assetURL = variantRoot.appendingPathComponent(relativePath)
            guard FileManager.default.fileExists(atPath: assetURL.path) else {
                throw ContentLoadError.invalidAsset(relativePath)
            }
        }

        for tileset in gameplayManifest.tilesets {
            let imageURL = variantRoot.appendingPathComponent(tileset.imagePath)
            guard FileManager.default.fileExists(atPath: imageURL.path) else {
                throw ContentLoadError.invalidAsset(tileset.imagePath)
            }

            let blocksetURL = variantRoot.appendingPathComponent(tileset.blocksetPath)
            guard FileManager.default.fileExists(atPath: blocksetURL.path) else {
                throw ContentLoadError.invalidAsset(tileset.blocksetPath)
            }
        }

        for sprite in gameplayManifest.overworldSprites {
            let spriteURL = variantRoot.appendingPathComponent(sprite.imagePath)
            guard FileManager.default.fileExists(atPath: spriteURL.path) else {
                throw ContentLoadError.invalidAsset(sprite.imagePath)
            }
        }

        return LoadedContent(
            rootURL: variantRoot,
            gameManifest: gameManifest,
            constantsManifest: constantsManifest,
            charmapManifest: charmapManifest,
            titleManifest: titleManifest,
            audioManifest: audioManifest,
            gameplayManifest: gameplayManifest
        )
    }

    private func resolveVariantRoot(for variant: GameVariant) throws -> URL {
        let directRoot = rootURL
        if FileManager.default.fileExists(atPath: directRoot.appendingPathComponent("game_manifest.json").path) {
            return directRoot
        }

        let nestedRoot = rootURL.appendingPathComponent(variant.rawValue.capitalized, isDirectory: true)
        if FileManager.default.fileExists(atPath: nestedRoot.appendingPathComponent("game_manifest.json").path) {
            return nestedRoot
        }

        throw ContentLoadError.missingRoot(nestedRoot)
    }

    private func decode<T: Decodable>(_ filename: String, at root: URL) throws -> T {
        let url = root.appendingPathComponent(filename)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ContentLoadError.missingManifest(filename)
        }

        let data = try Data(contentsOf: url)
        return try decoder.decode(T.self, from: data)
    }
}

public enum ContentLocator {
    public static func defaultContentRoot(bundle: Bundle = .main) -> URL {
        if let override = ProcessInfo.processInfo.environment["POKESWIFT_CONTENT_ROOT"] {
            return URL(fileURLWithPath: override, isDirectory: true)
        }

        if let resourceURL = bundle.resourceURL {
            let bundledRoot = resourceURL.appendingPathComponent("Content", isDirectory: true)
            if FileManager.default.fileExists(atPath: bundledRoot.path) {
                return bundledRoot
            }
        }

        return URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
            .appendingPathComponent("Content", isDirectory: true)
    }
}
