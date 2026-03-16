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

public enum TextSpeed: String, CaseIterable, Codable, Sendable {
    case fast
    case medium
    case slow

    public var label: String {
        rawValue.uppercased()
    }

    /// Per-character reveal delay in seconds, matching original Game Boy frame timings.
    public var characterDelay: TimeInterval {
        switch self {
        case .fast: return 1.0 / 60.0   // 1 frame
        case .medium: return 3.0 / 60.0  // 3 frames
        case .slow: return 5.0 / 60.0    // 5 frames
        }
    }
}

public enum BattleAnimation: String, CaseIterable, Codable, Sendable {
    case on
    case off

    public var label: String {
        rawValue.uppercased()
    }
}

public enum BattleStyle: String, CaseIterable, Codable, Sendable {
    case shift
    case set

    public var label: String {
        rawValue.uppercased()
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
    public enum CueAssetKind: String, Codable, Equatable, Sendable {
        case music
        case soundEffect
    }

    public enum PlaybackMode: String, Codable, Equatable, Sendable {
        case looping
        case oneShot
    }

    public enum Waveform: String, Codable, Equatable, Sendable {
        case square
        case wave
        case noise
    }

    public struct Event: Codable, Equatable, Sendable {
        public let startTime: Double
        public let duration: Double
        public let frequencyHz: Double?
        public let frequencyRegister: Int?
        public let amplitude: Double
        public let dutyCycle: Double?
        public let dutyCyclePattern: Int?
        public let dutyCyclePatternStepOffset: Int
        public let envelopeStepDuration: Double?
        public let envelopeDirection: Int
        public let waveSamples: [Double]?
        public let stereoLeftEnabled: Bool
        public let stereoRightEnabled: Bool
        public let vibratoDelaySeconds: Double
        public let vibratoDepthSemitones: Double
        public let vibratoRateHz: Double
        public let vibratoDelayFrames: Int
        public let vibratoExtentUp: Int
        public let vibratoExtentDown: Int
        public let vibratoRateFrames: Int
        public let pitchSlideTargetHz: Double?
        public let pitchSlideTargetRegister: Int?
        public let pitchSlideFrameCount: Int?
        public let noiseShortMode: Bool?
        public let waveform: Waveform

        public init(
            startTime: Double,
            duration: Double,
            frequencyHz: Double?,
            frequencyRegister: Int? = nil,
            amplitude: Double,
            dutyCycle: Double? = nil,
            dutyCyclePattern: Int? = nil,
            dutyCyclePatternStepOffset: Int = 0,
            envelopeStepDuration: Double? = nil,
            envelopeDirection: Int = 0,
            waveSamples: [Double]? = nil,
            stereoLeftEnabled: Bool = true,
            stereoRightEnabled: Bool = true,
            vibratoDelaySeconds: Double = 0,
            vibratoDepthSemitones: Double = 0,
            vibratoRateHz: Double = 0,
            vibratoDelayFrames: Int = 0,
            vibratoExtentUp: Int = 0,
            vibratoExtentDown: Int = 0,
            vibratoRateFrames: Int = 0,
            pitchSlideTargetHz: Double? = nil,
            pitchSlideTargetRegister: Int? = nil,
            pitchSlideFrameCount: Int? = nil,
            noiseShortMode: Bool? = nil,
            waveform: Waveform
        ) {
            self.startTime = startTime
            self.duration = duration
            self.frequencyHz = frequencyHz
            self.frequencyRegister = frequencyRegister
            self.amplitude = amplitude
            self.dutyCycle = dutyCycle
            self.dutyCyclePattern = dutyCyclePattern
            self.dutyCyclePatternStepOffset = dutyCyclePatternStepOffset
            self.envelopeStepDuration = envelopeStepDuration
            self.envelopeDirection = envelopeDirection
            self.waveSamples = waveSamples
            self.stereoLeftEnabled = stereoLeftEnabled
            self.stereoRightEnabled = stereoRightEnabled
            self.vibratoDelaySeconds = vibratoDelaySeconds
            self.vibratoDepthSemitones = vibratoDepthSemitones
            self.vibratoRateHz = vibratoRateHz
            self.vibratoDelayFrames = vibratoDelayFrames
            self.vibratoExtentUp = vibratoExtentUp
            self.vibratoExtentDown = vibratoExtentDown
            self.vibratoRateFrames = vibratoRateFrames
            self.pitchSlideTargetHz = pitchSlideTargetHz
            self.pitchSlideTargetRegister = pitchSlideTargetRegister
            self.pitchSlideFrameCount = pitchSlideFrameCount
            self.noiseShortMode = noiseShortMode
            self.waveform = waveform
        }
    }

    public struct ChannelProgram: Codable, Equatable, Sendable {
        public let channelNumber: Int
        public let prelude: [Event]
        public let loop: [Event]

        public init(channelNumber: Int, prelude: [Event], loop: [Event]) {
            self.channelNumber = channelNumber
            self.prelude = prelude
            self.loop = loop
        }
    }

    public struct Entry: Codable, Equatable, Sendable {
        public let id: String
        public let sourceLabel: String
        public let playbackMode: PlaybackMode
        public let channels: [ChannelProgram]

        public init(id: String, sourceLabel: String, playbackMode: PlaybackMode, channels: [ChannelProgram]) {
            self.id = id
            self.sourceLabel = sourceLabel
            self.playbackMode = playbackMode
            self.channels = channels
        }
    }

    public struct Track: Codable, Equatable, Sendable {
        public let id: String
        public let sourceLabel: String
        public let sourceFile: String
        public let entries: [Entry]

        public init(id: String, sourceLabel: String, sourceFile: String, entries: [Entry]) {
            self.id = id
            self.sourceLabel = sourceLabel
            self.sourceFile = sourceFile
            self.entries = entries
        }
    }

    public struct SoundEffect: Codable, Equatable, Sendable {
        public let id: String
        public let sourceLabel: String
        public let sourceFile: String
        public let bank: Int
        public let priority: Int
        public let order: Int
        public let requestedChannels: [Int]
        public let channels: [ChannelProgram]

        public init(
            id: String,
            sourceLabel: String,
            sourceFile: String,
            bank: Int,
            priority: Int,
            order: Int,
            requestedChannels: [Int],
            channels: [ChannelProgram]
        ) {
            self.id = id
            self.sourceLabel = sourceLabel
            self.sourceFile = sourceFile
            self.bank = bank
            self.priority = priority
            self.order = order
            self.requestedChannels = requestedChannels
            self.channels = channels
        }
    }

    public struct MapRoute: Codable, Equatable, Sendable {
        public let mapID: String
        public let musicID: String

        public init(mapID: String, musicID: String) {
            self.mapID = mapID
            self.musicID = musicID
        }
    }

    public struct Cue: Codable, Equatable, Sendable {
        public let id: String
        public let assetKind: CueAssetKind
        public let assetID: String
        public let entryID: String
        public let waitForCompletion: Bool
        public let resumeMusicAfterCompletion: Bool

        public init(
            id: String,
            assetKind: CueAssetKind = .music,
            assetID: String,
            entryID: String = "default",
            waitForCompletion: Bool = false,
            resumeMusicAfterCompletion: Bool = false
        ) {
            self.id = id
            self.assetKind = assetKind
            self.assetID = assetID
            self.entryID = entryID
            self.waitForCompletion = waitForCompletion
            self.resumeMusicAfterCompletion = resumeMusicAfterCompletion
        }

        public var trackID: String {
            assetID
        }
    }

    public let variant: GameVariant
    public let titleTrackID: String
    public let mapRoutes: [MapRoute]
    public let cues: [Cue]
    public let tracks: [Track]
    public let soundEffects: [SoundEffect]

    public init(
        variant: GameVariant,
        titleTrackID: String,
        mapRoutes: [MapRoute],
        cues: [Cue],
        tracks: [Track],
        soundEffects: [SoundEffect] = []
    ) {
        self.variant = variant
        self.titleTrackID = titleTrackID
        self.mapRoutes = mapRoutes
        self.cues = cues
        self.tracks = tracks
        self.soundEffects = soundEffects
    }
}
