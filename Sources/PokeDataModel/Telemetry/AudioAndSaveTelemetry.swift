import Foundation

public struct AudioTelemetry: Codable, Equatable, Sendable {
    public let trackID: String
    public let entryID: String
    public let reason: String
    public let playbackRevision: Int

    public init(trackID: String, entryID: String, reason: String, playbackRevision: Int) {
        self.trackID = trackID
        self.entryID = entryID
        self.reason = reason
        self.playbackRevision = playbackRevision
    }
}

public enum SoundEffectPlaybackStatusTelemetry: String, Codable, Equatable, Sendable {
    case started
    case rejected
}

public struct SoundEffectTelemetry: Codable, Equatable, Sendable {
    public let soundEffectID: String
    public let reason: String
    public let playbackRevision: Int
    public let status: SoundEffectPlaybackStatusTelemetry
    public let replacedSoundEffectID: String?

    public init(
        soundEffectID: String,
        reason: String,
        playbackRevision: Int,
        status: SoundEffectPlaybackStatusTelemetry,
        replacedSoundEffectID: String? = nil
    ) {
        self.soundEffectID = soundEffectID
        self.reason = reason
        self.playbackRevision = playbackRevision
        self.status = status
        self.replacedSoundEffectID = replacedSoundEffectID
    }
}

public struct SaveTelemetry: Codable, Equatable, Sendable {
    public let metadata: GameSaveMetadata?
    public let canSave: Bool
    public let canLoad: Bool
    public let lastResult: RuntimeSaveResult?
    public let errorMessage: String?

    public init(
        metadata: GameSaveMetadata?,
        canSave: Bool,
        canLoad: Bool,
        lastResult: RuntimeSaveResult?,
        errorMessage: String?
    ) {
        self.metadata = metadata
        self.canSave = canSave
        self.canLoad = canLoad
        self.lastResult = lastResult
        self.errorMessage = errorMessage
    }
}
