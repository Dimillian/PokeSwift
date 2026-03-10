import Foundation

public struct AudioPlaybackRequest: Equatable, Sendable {
    public let trackID: String
    public let entryID: String

    public init(trackID: String, entryID: String = "default") {
        self.trackID = trackID
        self.entryID = entryID
    }
}

public protocol RuntimeAudioPlaying: AnyObject {
    @MainActor
    func play(request: AudioPlaybackRequest, completion: (@MainActor () -> Void)?)

    @MainActor
    func stopAllMusic()
}
