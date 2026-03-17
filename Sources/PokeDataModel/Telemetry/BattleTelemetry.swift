import Foundation

public enum BattlePhaseTelemetry: String, Codable, Equatable, Sendable {
    case introText
    case moveSelection
    case bagSelection
    case partySelection
    case trainerAboutToUseDecision
    case learnMoveDecision
    case learnMoveSelection
    case resolvingTurn
    case turnText
    case battleComplete
}

public struct BattleCaptureTelemetry: Codable, Equatable, Sendable {
    public let result: String
    public let shakes: Int
    public let itemID: String?

    public init(result: String, shakes: Int, itemID: String? = nil) {
        self.result = result
        self.shakes = shakes
        self.itemID = itemID
    }
}

public struct BattleTelemetry: Codable, Equatable, Sendable {
    public let battleID: String
    public let kind: BattleKind
    public let trainerName: String
    public let trainerSpritePath: String?
    public let playerPokemon: PartyPokemonTelemetry
    public let enemyPokemon: PartyPokemonTelemetry
    public let enemyPartyCount: Int
    public let enemyActiveIndex: Int
    public let focusedMoveIndex: Int
    public let focusedBagItemIndex: Int
    public let focusedPartyIndex: Int
    public let canRun: Bool
    public let canUseBag: Bool
    public let canSwitch: Bool
    public let phase: BattlePhaseTelemetry
    public let textLines: [String]
    public let learnMovePrompt: BattleLearnMovePromptTelemetry?
    public let moveSlots: [BattleMoveSlotTelemetry]
    public let bagItems: [InventoryItemTelemetry]
    public let battleMessage: String
    public let capture: BattleCaptureTelemetry?
    public let presentation: BattlePresentationTelemetry

    public init(
        battleID: String,
        kind: BattleKind = .trainer,
        trainerName: String,
        trainerSpritePath: String? = nil,
        playerPokemon: PartyPokemonTelemetry,
        enemyPokemon: PartyPokemonTelemetry,
        enemyPartyCount: Int,
        enemyActiveIndex: Int,
        focusedMoveIndex: Int,
        focusedBagItemIndex: Int = 0,
        focusedPartyIndex: Int = 0,
        canRun: Bool = false,
        canUseBag: Bool = false,
        canSwitch: Bool = false,
        phase: BattlePhaseTelemetry = .moveSelection,
        textLines: [String] = [],
        learnMovePrompt: BattleLearnMovePromptTelemetry? = nil,
        moveSlots: [BattleMoveSlotTelemetry] = [],
        bagItems: [InventoryItemTelemetry] = [],
        battleMessage: String,
        capture: BattleCaptureTelemetry? = nil,
        presentation: BattlePresentationTelemetry = .init(
            stage: .idle,
            revision: 0,
            uiVisibility: .visible
        )
    ) {
        self.battleID = battleID
        self.kind = kind
        self.trainerName = trainerName
        self.trainerSpritePath = trainerSpritePath
        self.playerPokemon = playerPokemon
        self.enemyPokemon = enemyPokemon
        self.enemyPartyCount = enemyPartyCount
        self.enemyActiveIndex = enemyActiveIndex
        self.focusedMoveIndex = focusedMoveIndex
        self.focusedBagItemIndex = focusedBagItemIndex
        self.focusedPartyIndex = focusedPartyIndex
        self.canRun = canRun
        self.canUseBag = canUseBag
        self.canSwitch = canSwitch
        self.phase = phase
        self.textLines = textLines
        self.learnMovePrompt = learnMovePrompt
        self.moveSlots = moveSlots
        self.bagItems = bagItems
        self.battleMessage = battleMessage
        self.capture = capture
        self.presentation = presentation
    }

    private enum CodingKeys: String, CodingKey {
        case battleID
        case kind
        case trainerName
        case trainerSpritePath
        case playerPokemon
        case enemyPokemon
        case enemyPartyCount
        case enemyActiveIndex
        case focusedMoveIndex
        case focusedBagItemIndex
        case focusedPartyIndex
        case canRun
        case canUseBag
        case canSwitch
        case phase
        case textLines
        case learnMovePrompt
        case moveSlots
        case bagItems
        case battleMessage
        case capture
        case presentation
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        battleID = try container.decode(String.self, forKey: .battleID)
        kind = try container.decode(BattleKind.self, forKey: .kind, default: .trainer)
        trainerName = try container.decode(String.self, forKey: .trainerName)
        trainerSpritePath = try container.decodeIfPresent(String.self, forKey: .trainerSpritePath)
        playerPokemon = try container.decode(PartyPokemonTelemetry.self, forKey: .playerPokemon)
        enemyPokemon = try container.decode(PartyPokemonTelemetry.self, forKey: .enemyPokemon)
        enemyPartyCount = try container.decode(Int.self, forKey: .enemyPartyCount, default: 1)
        enemyActiveIndex = try container.decode(Int.self, forKey: .enemyActiveIndex, default: 0)
        focusedMoveIndex = try container.decode(Int.self, forKey: .focusedMoveIndex)
        focusedBagItemIndex = try container.decode(Int.self, forKey: .focusedBagItemIndex, default: 0)
        focusedPartyIndex = try container.decode(Int.self, forKey: .focusedPartyIndex, default: 0)
        canRun = try container.decode(Bool.self, forKey: .canRun, default: false)
        canUseBag = try container.decode(Bool.self, forKey: .canUseBag, default: false)
        canSwitch = try container.decode(Bool.self, forKey: .canSwitch, default: false)
        let decodedPhase = try container.decode(String.self, forKey: .phase, default: BattlePhaseTelemetry.moveSelection.rawValue)
        phase = BattlePhaseTelemetry(rawValue: decodedPhase) ?? .moveSelection
        textLines = try container.decodeArray([String].self, forKey: .textLines, default: [])
        learnMovePrompt = try container.decodeIfPresent(BattleLearnMovePromptTelemetry.self, forKey: .learnMovePrompt)
        moveSlots = try container.decodeArray([BattleMoveSlotTelemetry].self, forKey: .moveSlots, default: [])
        bagItems = try container.decodeArray([InventoryItemTelemetry].self, forKey: .bagItems, default: [])
        battleMessage = try container.decode(String.self, forKey: .battleMessage)
        capture = try container.decodeIfPresent(BattleCaptureTelemetry.self, forKey: .capture)
        presentation = try container.decode(BattlePresentationTelemetry.self, forKey: .presentation, default: .init(
            stage: .idle,
            revision: 0,
            uiVisibility: .visible
        ))
    }
}

public struct BattleLearnMovePromptTelemetry: Codable, Equatable, Sendable {
    public enum Stage: String, Codable, Equatable, Sendable {
        case confirm
        case replace
    }

    public let pokemonName: String
    public let moveID: String
    public let moveDisplayName: String
    public let stage: Stage

    public init(
        pokemonName: String,
        moveID: String,
        moveDisplayName: String,
        stage: Stage
    ) {
        self.pokemonName = pokemonName
        self.moveID = moveID
        self.moveDisplayName = moveDisplayName
        self.stage = stage
    }
}

public struct BattleMoveSlotTelemetry: Codable, Equatable, Sendable {
    public let moveID: String
    public let displayName: String
    public let currentPP: Int
    public let maxPP: Int
    public let isSelectable: Bool

    public init(
        moveID: String,
        displayName: String,
        currentPP: Int,
        maxPP: Int,
        isSelectable: Bool = true
    ) {
        self.moveID = moveID
        self.displayName = displayName
        self.currentPP = currentPP
        self.maxPP = maxPP
        self.isSelectable = isSelectable
    }
}
