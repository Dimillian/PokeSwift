import Foundation

public struct MusicPlaybackRequest: Equatable, Sendable {
    public let trackID: String
    public let entryID: String

    public init(trackID: String, entryID: String = "default") {
        self.trackID = trackID
        self.entryID = entryID
    }
}

public struct SoundEffectPlaybackRequest: Equatable, Sendable {
    public let soundEffectID: String
    public let frequencyModifier: Int?
    public let tempoModifier: Int?

    public init(soundEffectID: String, frequencyModifier: Int? = nil, tempoModifier: Int? = nil) {
        self.soundEffectID = soundEffectID
        self.frequencyModifier = frequencyModifier
        self.tempoModifier = tempoModifier
    }
}

public enum SoundEffectPlaybackStatus: String, Equatable, Sendable {
    case started
    case rejected
}

public struct SoundEffectPlaybackResult: Equatable, Sendable {
    public let soundEffectID: String
    public let status: SoundEffectPlaybackStatus
    public let replacedSoundEffectID: String?

    public init(soundEffectID: String, status: SoundEffectPlaybackStatus, replacedSoundEffectID: String? = nil) {
        self.soundEffectID = soundEffectID
        self.status = status
        self.replacedSoundEffectID = replacedSoundEffectID
    }
}

public protocol RuntimeAudioPlaying: AnyObject {
    @MainActor
    func playMusic(request: MusicPlaybackRequest, completion: (@MainActor () -> Void)?)

    @MainActor
    func playSFX(
        request: SoundEffectPlaybackRequest,
        completion: (@MainActor () -> Void)?
    ) -> SoundEffectPlaybackResult

    @MainActor
    func stopAllMusic()
}
