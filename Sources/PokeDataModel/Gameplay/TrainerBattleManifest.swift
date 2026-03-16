import Foundation

public struct TrainerPokemonManifest: Codable, Equatable, Sendable {
    public let speciesID: String
    public let level: Int

    public init(speciesID: String, level: Int) {
        self.speciesID = speciesID
        self.level = level
    }
}

public struct TrainerAIMoveChoiceModificationManifest: Codable, Equatable, Sendable {
    public let trainerClass: String
    public let modifications: [Int]

    public init(trainerClass: String, modifications: [Int]) {
        self.trainerClass = trainerClass
        self.modifications = modifications
    }
}

public struct TrainerBattleManifest: Codable, Equatable, Sendable {
    public let id: String
    public let trainerClass: String
    public let trainerNumber: Int
    public let displayName: String
    public let party: [TrainerPokemonManifest]
    public let trainerSpritePath: String?
    public let baseRewardMoney: Int
    public let encounterAudioCueID: String?
    public let playerWinDialogueID: String
    public let playerLoseDialogueID: String?
    public let healsPartyAfterBattle: Bool
    public let preventsBlackoutOnLoss: Bool
    public let completionFlagID: String
    public let postBattleScriptID: String?
    public let runsPostBattleScriptOnLoss: Bool

    public init(
        id: String,
        trainerClass: String,
        trainerNumber: Int,
        displayName: String,
        party: [TrainerPokemonManifest],
        trainerSpritePath: String? = nil,
        baseRewardMoney: Int = 0,
        encounterAudioCueID: String? = nil,
        playerWinDialogueID: String,
        playerLoseDialogueID: String? = nil,
        healsPartyAfterBattle: Bool,
        preventsBlackoutOnLoss: Bool,
        completionFlagID: String,
        postBattleScriptID: String? = nil,
        runsPostBattleScriptOnLoss: Bool = false
    ) {
        self.id = id
        self.trainerClass = trainerClass
        self.trainerNumber = trainerNumber
        self.displayName = displayName
        self.party = party
        self.trainerSpritePath = trainerSpritePath
        self.baseRewardMoney = max(0, baseRewardMoney)
        self.encounterAudioCueID = encounterAudioCueID
        self.playerWinDialogueID = playerWinDialogueID
        self.playerLoseDialogueID = playerLoseDialogueID
        self.healsPartyAfterBattle = healsPartyAfterBattle
        self.preventsBlackoutOnLoss = preventsBlackoutOnLoss
        self.completionFlagID = completionFlagID
        self.postBattleScriptID = postBattleScriptID
        self.runsPostBattleScriptOnLoss = runsPostBattleScriptOnLoss
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case trainerClass
        case trainerNumber
        case displayName
        case party
        case trainerSpritePath
        case baseRewardMoney
        case encounterAudioCueID
        case playerWinDialogueID
        case playerLoseDialogueID
        case healsPartyAfterBattle
        case preventsBlackoutOnLoss
        case completionFlagID
        case postBattleScriptID
        case runsPostBattleScriptOnLoss
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        trainerClass = try container.decode(String.self, forKey: .trainerClass)
        trainerNumber = try container.decode(Int.self, forKey: .trainerNumber)
        displayName = try container.decode(String.self, forKey: .displayName)
        party = try container.decode([TrainerPokemonManifest].self, forKey: .party)
        trainerSpritePath = try container.decodeIfPresent(String.self, forKey: .trainerSpritePath)
        baseRewardMoney = max(0, try container.decodeIfPresent(Int.self, forKey: .baseRewardMoney) ?? 0)
        encounterAudioCueID = try container.decodeIfPresent(String.self, forKey: .encounterAudioCueID)
        playerWinDialogueID = try container.decode(String.self, forKey: .playerWinDialogueID)
        playerLoseDialogueID = try container.decodeIfPresent(String.self, forKey: .playerLoseDialogueID)
        healsPartyAfterBattle = try container.decode(Bool.self, forKey: .healsPartyAfterBattle)
        preventsBlackoutOnLoss = try container.decode(Bool.self, forKey: .preventsBlackoutOnLoss)
        completionFlagID = try container.decode(String.self, forKey: .completionFlagID)
        postBattleScriptID = try container.decodeIfPresent(String.self, forKey: .postBattleScriptID)
        runsPostBattleScriptOnLoss = try container.decodeIfPresent(Bool.self, forKey: .runsPostBattleScriptOnLoss) ?? false
    }
}
