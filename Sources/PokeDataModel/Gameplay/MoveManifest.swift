import Foundation

public struct MoveManifest: Codable, Equatable, Sendable {
    public let id: String
    public let displayName: String
    public let power: Int
    public let accuracy: Int
    public let maxPP: Int
    public let effect: String
    public let type: String
    public let battleAudio: BattleAudioManifest?

    public init(
        id: String,
        displayName: String,
        power: Int,
        accuracy: Int,
        maxPP: Int,
        effect: String,
        type: String,
        battleAudio: BattleAudioManifest? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.power = power
        self.accuracy = accuracy
        self.maxPP = maxPP
        self.effect = effect
        self.type = type
        self.battleAudio = battleAudio
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case displayName
        case power
        case accuracy
        case maxPP
        case effect
        case type
        case battleAudio
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        displayName = try container.decode(String.self, forKey: .displayName)
        power = try container.decode(Int.self, forKey: .power)
        accuracy = try container.decode(Int.self, forKey: .accuracy)
        maxPP = try container.decode(Int.self, forKey: .maxPP)
        effect = try container.decode(String.self, forKey: .effect)
        type = try container.decode(String.self, forKey: .type)
        battleAudio = try container.decodeIfPresent(BattleAudioManifest.self, forKey: .battleAudio)
    }
}

public enum BattleAudioKind: String, Codable, Equatable, Sendable {
    case soundEffect
    case cry
}

public struct BattleAudioManifest: Codable, Equatable, Sendable {
    public let kind: BattleAudioKind
    public let soundEffectID: String?
    public let frequencyModifier: Int?
    public let tempoModifier: Int?

    public init(
        kind: BattleAudioKind,
        soundEffectID: String? = nil,
        frequencyModifier: Int? = nil,
        tempoModifier: Int? = nil
    ) {
        self.kind = kind
        self.soundEffectID = soundEffectID
        self.frequencyModifier = frequencyModifier
        self.tempoModifier = tempoModifier
    }
}
