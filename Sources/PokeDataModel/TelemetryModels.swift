import Foundation

public enum RuntimeScene: String, Codable, Sendable {
    case launch
    case splash
    case titleAttract
    case titleMenu
    case field
    case dialogue
    case scriptedSequence
    case starterChoice
    case battle
    case placeholder
}

public enum RuntimeButton: String, Codable, Sendable, CaseIterable {
    case up
    case down
    case left
    case right
    case confirm
    case cancel
    case start
}

public struct InputEventTelemetry: Codable, Equatable, Sendable {
    public let button: RuntimeButton
    public let timestamp: String

    public init(button: RuntimeButton, timestamp: String) {
        self.button = button
        self.timestamp = timestamp
    }
}

public struct TitleMenuTelemetry: Codable, Equatable, Sendable {
    public let entries: [TitleMenuEntry]
    public let focusedIndex: Int

    public init(entries: [TitleMenuEntry], focusedIndex: Int) {
        self.entries = entries
        self.focusedIndex = focusedIndex
    }
}

public struct WindowTelemetry: Codable, Equatable, Sendable {
    public let scale: Int
    public let renderWidth: Int
    public let renderHeight: Int

    public init(scale: Int, renderWidth: Int, renderHeight: Int) {
        self.scale = scale
        self.renderWidth = renderWidth
        self.renderHeight = renderHeight
    }
}

public struct FieldTelemetry: Codable, Equatable, Sendable {
    public let mapID: String
    public let mapName: String
    public let playerPosition: TilePoint
    public let facing: FacingDirection
    public let activeMapScriptTriggerID: String?
    public let activeScriptID: String?
    public let activeScriptStep: Int?
    public let renderMode: String

    public init(
        mapID: String,
        mapName: String,
        playerPosition: TilePoint,
        facing: FacingDirection,
        activeMapScriptTriggerID: String?,
        activeScriptID: String?,
        activeScriptStep: Int?,
        renderMode: String
    ) {
        self.mapID = mapID
        self.mapName = mapName
        self.playerPosition = playerPosition
        self.facing = facing
        self.activeMapScriptTriggerID = activeMapScriptTriggerID
        self.activeScriptID = activeScriptID
        self.activeScriptStep = activeScriptStep
        self.renderMode = renderMode
    }
}

public struct DialogueTelemetry: Codable, Equatable, Sendable {
    public let dialogueID: String
    public let pageIndex: Int
    public let pageCount: Int
    public let lines: [String]

    public init(dialogueID: String, pageIndex: Int, pageCount: Int, lines: [String]) {
        self.dialogueID = dialogueID
        self.pageIndex = pageIndex
        self.pageCount = pageCount
        self.lines = lines
    }
}

public struct PartyPokemonTelemetry: Codable, Equatable, Sendable {
    public let speciesID: String
    public let displayName: String
    public let level: Int
    public let currentHP: Int
    public let maxHP: Int
    public let moves: [String]

    public init(speciesID: String, displayName: String, level: Int, currentHP: Int, maxHP: Int, moves: [String]) {
        self.speciesID = speciesID
        self.displayName = displayName
        self.level = level
        self.currentHP = currentHP
        self.maxHP = maxHP
        self.moves = moves
    }
}

public struct PartyTelemetry: Codable, Equatable, Sendable {
    public let pokemon: [PartyPokemonTelemetry]

    public init(pokemon: [PartyPokemonTelemetry]) {
        self.pokemon = pokemon
    }
}

public struct BattleTelemetry: Codable, Equatable, Sendable {
    public let battleID: String
    public let trainerName: String
    public let playerPokemon: PartyPokemonTelemetry
    public let enemyPokemon: PartyPokemonTelemetry
    public let enemyPartyCount: Int
    public let enemyActiveIndex: Int
    public let focusedMoveIndex: Int
    public let phase: String
    public let textLines: [String]
    public let moveSlots: [BattleMoveSlotTelemetry]
    public let battleMessage: String

    public init(
        battleID: String,
        trainerName: String,
        playerPokemon: PartyPokemonTelemetry,
        enemyPokemon: PartyPokemonTelemetry,
        enemyPartyCount: Int,
        enemyActiveIndex: Int,
        focusedMoveIndex: Int,
        phase: String = "moveSelection",
        textLines: [String] = [],
        moveSlots: [BattleMoveSlotTelemetry] = [],
        battleMessage: String
    ) {
        self.battleID = battleID
        self.trainerName = trainerName
        self.playerPokemon = playerPokemon
        self.enemyPokemon = enemyPokemon
        self.enemyPartyCount = enemyPartyCount
        self.enemyActiveIndex = enemyActiveIndex
        self.focusedMoveIndex = focusedMoveIndex
        self.phase = phase
        self.textLines = textLines
        self.moveSlots = moveSlots
        self.battleMessage = battleMessage
    }

    private enum CodingKeys: String, CodingKey {
        case battleID
        case trainerName
        case playerPokemon
        case enemyPokemon
        case enemyPartyCount
        case enemyActiveIndex
        case focusedMoveIndex
        case phase
        case textLines
        case moveSlots
        case battleMessage
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        battleID = try container.decode(String.self, forKey: .battleID)
        trainerName = try container.decode(String.self, forKey: .trainerName)
        playerPokemon = try container.decode(PartyPokemonTelemetry.self, forKey: .playerPokemon)
        enemyPokemon = try container.decode(PartyPokemonTelemetry.self, forKey: .enemyPokemon)
        enemyPartyCount = try container.decodeIfPresent(Int.self, forKey: .enemyPartyCount) ?? 1
        enemyActiveIndex = try container.decodeIfPresent(Int.self, forKey: .enemyActiveIndex) ?? 0
        focusedMoveIndex = try container.decode(Int.self, forKey: .focusedMoveIndex)
        phase = try container.decodeIfPresent(String.self, forKey: .phase) ?? "moveSelection"
        textLines = try container.decodeIfPresent([String].self, forKey: .textLines) ?? []
        moveSlots = try container.decodeIfPresent([BattleMoveSlotTelemetry].self, forKey: .moveSlots) ?? []
        battleMessage = try container.decode(String.self, forKey: .battleMessage)
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

public struct StarterChoiceTelemetry: Codable, Equatable, Sendable {
    public let options: [String]
    public let focusedIndex: Int

    public init(options: [String], focusedIndex: Int) {
        self.options = options
        self.focusedIndex = focusedIndex
    }
}

public struct EventFlagTelemetry: Codable, Equatable, Sendable {
    public let activeFlags: [String]

    public init(activeFlags: [String]) {
        self.activeFlags = activeFlags
    }
}

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

public struct RuntimeTelemetrySnapshot: Codable, Equatable, Sendable {
    public let appVersion: String
    public let contentVersion: String
    public let scene: RuntimeScene
    public let substate: String
    public let titleMenu: TitleMenuTelemetry?
    public let field: FieldTelemetry?
    public let dialogue: DialogueTelemetry?
    public let starterChoice: StarterChoiceTelemetry?
    public let party: PartyTelemetry?
    public let battle: BattleTelemetry?
    public let eventFlags: EventFlagTelemetry?
    public let audio: AudioTelemetry?
    public let recentInputEvents: [InputEventTelemetry]
    public let assetLoadingFailures: [String]
    public let window: WindowTelemetry

    public init(
        appVersion: String,
        contentVersion: String,
        scene: RuntimeScene,
        substate: String,
        titleMenu: TitleMenuTelemetry?,
        field: FieldTelemetry?,
        dialogue: DialogueTelemetry?,
        starterChoice: StarterChoiceTelemetry?,
        party: PartyTelemetry?,
        battle: BattleTelemetry?,
        eventFlags: EventFlagTelemetry?,
        audio: AudioTelemetry?,
        recentInputEvents: [InputEventTelemetry],
        assetLoadingFailures: [String],
        window: WindowTelemetry
    ) {
        self.appVersion = appVersion
        self.contentVersion = contentVersion
        self.scene = scene
        self.substate = substate
        self.titleMenu = titleMenu
        self.field = field
        self.dialogue = dialogue
        self.starterChoice = starterChoice
        self.party = party
        self.battle = battle
        self.eventFlags = eventFlags
        self.audio = audio
        self.recentInputEvents = recentInputEvents
        self.assetLoadingFailures = assetLoadingFailures
        self.window = window
    }
}

public protocol TelemetryPublisher: Sendable {
    func publish(snapshot: RuntimeTelemetrySnapshot) async
}
