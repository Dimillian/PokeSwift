import Foundation
import PokeDataModel

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
        let battleAnimationManifest: BattleAnimationManifest = try decode("battle_animation_manifest.json", at: variantRoot)

        let requiredAssetPaths =
            titleManifest.assets.map(\.relativePath) +
            ["Assets/battle/effects/send_out_poof.png"] +
            battleAnimationManifest.tilesets.map(\.imagePath) +
            gameplayManifest.tilesets.flatMap { [$0.imagePath, $0.blocksetPath] } +
            gameplayManifest.overworldSprites.map(\.imagePath) +
            gameplayManifest.species.flatMap { species -> [String] in
                guard let battleSprite = species.battleSprite else { return [] }
                return [battleSprite.frontImagePath, battleSprite.backImagePath]
            }

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
            gameplayManifest: gameplayManifest,
            battleAnimationManifest: battleAnimationManifest
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
