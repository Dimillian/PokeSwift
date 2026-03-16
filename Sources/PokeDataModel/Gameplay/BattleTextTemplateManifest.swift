import Foundation

public struct BattleTextTemplateManifest: Codable, Equatable, Sendable {
    public let wantsToFight: String
    public let enemyFainted: String
    public let playerFainted: String
    public let playerBlackedOut: String
    public let trainerDefeated: String
    public let moneyForWinning: String
    public let trainerAboutToUse: String
    public let trainerSentOut: String
    public let playerSendOutGo: String
    public let playerSendOutDoIt: String
    public let playerSendOutGetm: String
    public let playerSendOutEnemyWeak: String

    public init(
        wantsToFight: String,
        enemyFainted: String,
        playerFainted: String,
        playerBlackedOut: String,
        trainerDefeated: String,
        moneyForWinning: String,
        trainerAboutToUse: String,
        trainerSentOut: String,
        playerSendOutGo: String,
        playerSendOutDoIt: String,
        playerSendOutGetm: String,
        playerSendOutEnemyWeak: String
    ) {
        self.wantsToFight = wantsToFight
        self.enemyFainted = enemyFainted
        self.playerFainted = playerFainted
        self.playerBlackedOut = playerBlackedOut
        self.trainerDefeated = trainerDefeated
        self.moneyForWinning = moneyForWinning
        self.trainerAboutToUse = trainerAboutToUse
        self.trainerSentOut = trainerSentOut
        self.playerSendOutGo = playerSendOutGo
        self.playerSendOutDoIt = playerSendOutDoIt
        self.playerSendOutGetm = playerSendOutGetm
        self.playerSendOutEnemyWeak = playerSendOutEnemyWeak
    }

    private enum CodingKeys: String, CodingKey {
        case wantsToFight
        case enemyFainted
        case playerFainted
        case playerBlackedOut
        case trainerDefeated
        case moneyForWinning
        case trainerAboutToUse
        case trainerSentOut
        case playerSendOutGo
        case playerSendOutDoIt
        case playerSendOutGetm
        case playerSendOutEnemyWeak
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        wantsToFight = try container.decode(String.self, forKey: .wantsToFight)
        enemyFainted = try container.decode(String.self, forKey: .enemyFainted)
        playerFainted = try container.decode(String.self, forKey: .playerFainted)
        playerBlackedOut = try container.decodeIfPresent(String.self, forKey: .playerBlackedOut)
            ?? "{playerName} is out of useable POKéMON! {playerName} blacked out!"
        trainerDefeated = try container.decode(String.self, forKey: .trainerDefeated)
        moneyForWinning = try container.decode(String.self, forKey: .moneyForWinning)
        trainerAboutToUse = try container.decode(String.self, forKey: .trainerAboutToUse)
        trainerSentOut = try container.decode(String.self, forKey: .trainerSentOut)
        playerSendOutGo = try container.decode(String.self, forKey: .playerSendOutGo)
        playerSendOutDoIt = try container.decode(String.self, forKey: .playerSendOutDoIt)
        playerSendOutGetm = try container.decode(String.self, forKey: .playerSendOutGetm)
        playerSendOutEnemyWeak = try container.decode(String.self, forKey: .playerSendOutEnemyWeak)
    }
}
