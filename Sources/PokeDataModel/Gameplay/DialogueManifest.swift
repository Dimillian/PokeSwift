import Foundation

public struct DialoguePage: Codable, Equatable, Sendable {
    public let lines: [String]
    public let waitsForPrompt: Bool
    public let events: [DialogueEvent]

    public init(lines: [String], waitsForPrompt: Bool, events: [DialogueEvent] = []) {
        self.lines = lines
        self.waitsForPrompt = waitsForPrompt
        self.events = events
    }

    private enum CodingKeys: String, CodingKey {
        case lines
        case waitsForPrompt
        case events
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        lines = try container.decode([String].self, forKey: .lines)
        waitsForPrompt = try container.decode(Bool.self, forKey: .waitsForPrompt)
        events = try container.decodeIfPresent([DialogueEvent].self, forKey: .events) ?? []
    }
}

public struct DialogueManifest: Codable, Equatable, Sendable {
    public let id: String
    public let pages: [DialoguePage]

    public init(id: String, pages: [DialoguePage]) {
        self.id = id
        self.pages = pages
    }
}

public enum DialogueEventKind: String, Codable, Equatable, Sendable {
    case soundEffect
    case cry
    case music
    case restoreMapMusic
}

public struct DialogueEvent: Codable, Equatable, Sendable {
    public let kind: DialogueEventKind
    public let soundEffectID: String?
    public let speciesID: String?
    public let trackID: String?
    public let waitForCompletion: Bool

    public init(
        kind: DialogueEventKind,
        soundEffectID: String? = nil,
        speciesID: String? = nil,
        trackID: String? = nil,
        waitForCompletion: Bool = true
    ) {
        self.kind = kind
        self.soundEffectID = soundEffectID
        self.speciesID = speciesID
        self.trackID = trackID
        self.waitForCompletion = waitForCompletion
    }
}
