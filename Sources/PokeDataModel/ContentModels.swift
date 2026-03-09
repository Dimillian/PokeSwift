import Foundation

public enum GameVariant: String, Codable, Sendable, CaseIterable {
    case red
}

public typealias ContentConstantsManifest = ConstantsManifest

public struct SourceReference: Codable, Hashable, Sendable {
    public let path: String
    public let purpose: String

    public init(path: String, purpose: String) {
        self.path = path
        self.purpose = purpose
    }
}

public struct GameManifest: Codable, Equatable, Sendable {
    public let contentVersion: String
    public let variant: GameVariant
    public let sourceCommit: String
    public let extractorVersion: String
    public let sourceFiles: [SourceReference]

    public init(contentVersion: String, variant: GameVariant, sourceCommit: String, extractorVersion: String, sourceFiles: [SourceReference]) {
        self.contentVersion = contentVersion
        self.variant = variant
        self.sourceCommit = sourceCommit
        self.extractorVersion = extractorVersion
        self.sourceFiles = sourceFiles
    }
}

public struct PixelSize: Codable, Equatable, Sendable {
    public let width: Int
    public let height: Int

    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }
}

public struct ConstantsManifest: Codable, Equatable, Sendable {
    public let variant: GameVariant
    public let sourceFiles: [SourceReference]
    public let watchedKeys: [String]
    public let musicTrack: String
    public let titleMonSelectionConstant: String

    public init(variant: GameVariant, sourceFiles: [SourceReference], watchedKeys: [String], musicTrack: String, titleMonSelectionConstant: String) {
        self.variant = variant
        self.sourceFiles = sourceFiles
        self.watchedKeys = watchedKeys
        self.musicTrack = musicTrack
        self.titleMonSelectionConstant = titleMonSelectionConstant
    }
}

public struct CharmapManifest: Codable, Equatable, Sendable {
    public let variant: GameVariant
    public let entries: [CharmapEntry]

    public init(variant: GameVariant, entries: [CharmapEntry]) {
        self.variant = variant
        self.entries = entries
    }
}

public struct CharmapEntry: Codable, Equatable, Sendable {
    public let token: String
    public let value: Int
    public let sourceSection: String

    public init(token: String, value: Int, sourceSection: String) {
        self.token = token
        self.value = value
        self.sourceSection = sourceSection
    }
}

public struct TitleMenuEntry: Codable, Equatable, Hashable, Sendable {
    public let id: String
    public let label: String
    public let enabledByDefault: Bool

    public init(id: String, label: String, enabledByDefault: Bool) {
        self.id = id
        self.label = label
        self.enabledByDefault = enabledByDefault
    }

    public var enabled: Bool {
        enabledByDefault
    }
}

public struct LogoBounceStep: Codable, Equatable, Hashable, Sendable {
    public let yDelta: Int
    public let frames: Int

    public init(yDelta: Int, frames: Int) {
        self.yDelta = yDelta
        self.frames = frames
    }
}

public struct TitleAsset: Codable, Equatable, Hashable, Sendable {
    public let id: String
    public let relativePath: String
    public let kind: String

    public init(id: String, relativePath: String, kind: String) {
        self.id = id
        self.relativePath = relativePath
        self.kind = kind
    }
}

public struct TitleSceneTimings: Codable, Equatable, Sendable {
    public let launchFadeSeconds: Double
    public let splashDurationSeconds: Double
    public let attractPromptDelaySeconds: Double

    public init(launchFadeSeconds: Double, splashDurationSeconds: Double, attractPromptDelaySeconds: Double) {
        self.launchFadeSeconds = launchFadeSeconds
        self.splashDurationSeconds = splashDurationSeconds
        self.attractPromptDelaySeconds = attractPromptDelaySeconds
    }
}

public struct TitleSceneManifest: Codable, Equatable, Sendable {
    public let variant: GameVariant
    public let sourceFiles: [SourceReference]
    public let titleMonSpecies: String
    public let menuEntries: [TitleMenuEntry]
    public let logoBounceSequence: [LogoBounceStep]
    public let assets: [TitleAsset]
    public let timings: TitleSceneTimings

    public init(
        variant: GameVariant,
        sourceFiles: [SourceReference],
        titleMonSpecies: String,
        menuEntries: [TitleMenuEntry],
        logoBounceSequence: [LogoBounceStep],
        assets: [TitleAsset],
        timings: TitleSceneTimings
    ) {
        self.variant = variant
        self.sourceFiles = sourceFiles
        self.titleMonSpecies = titleMonSpecies
        self.menuEntries = menuEntries
        self.logoBounceSequence = logoBounceSequence
        self.assets = assets
        self.timings = timings
    }
}

public struct AudioManifest: Codable, Equatable, Sendable {
    public struct Track: Codable, Equatable, Sendable {
        public let id: String
        public let sourceFile: String

        public init(id: String, sourceFile: String) {
            self.id = id
            self.sourceFile = sourceFile
        }
    }

    public let variant: GameVariant
    public let tracks: [Track]

    public init(variant: GameVariant, tracks: [Track]) {
        self.variant = variant
        self.tracks = tracks
    }
}
