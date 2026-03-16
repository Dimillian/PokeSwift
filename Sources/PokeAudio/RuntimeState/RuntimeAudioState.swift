import Foundation
import PokeDataModel

public struct RuntimeStagedSoundEffectRequest {
    public let delay: TimeInterval
    public let request: SoundEffectPlaybackRequest

    public init(delay: TimeInterval, request: SoundEffectPlaybackRequest) {
        self.delay = delay
        self.request = request
    }
}

public struct RuntimeAudioState: Equatable {
    public var trackID: String
    public var entryID: String
    public var reason: String
    public var playbackRevision: Int

    public init(
        trackID: String,
        entryID: String,
        reason: String,
        playbackRevision: Int
    ) {
        self.trackID = trackID
        self.entryID = entryID
        self.reason = reason
        self.playbackRevision = playbackRevision
    }
}

public struct RuntimeSoundEffectState: Equatable {
    public var soundEffectID: String
    public var reason: String
    public var playbackRevision: Int
    public var status: SoundEffectPlaybackStatusTelemetry
    public var replacedSoundEffectID: String?

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
