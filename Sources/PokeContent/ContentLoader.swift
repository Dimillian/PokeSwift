import Foundation
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

        for asset in titleManifest.assets {
            let assetURL = variantRoot.appendingPathComponent(asset.relativePath)
            guard FileManager.default.fileExists(atPath: assetURL.path) else {
                throw ContentLoadError.invalidAsset(asset.relativePath)
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
