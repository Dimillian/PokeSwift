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
    public let entries: [TitleMenuEntryState]
    public let focusedIndex: Int

    public init(entries: [TitleMenuEntryState], focusedIndex: Int) {
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
    public let objects: [FieldObjectTelemetry]
    public let activeMapScriptTriggerID: String?
    public let activeScriptID: String?
    public let activeScriptStep: Int?
    public let renderMode: String
    public let transition: FieldTransitionTelemetry?

    public init(
        mapID: String,
        mapName: String,
        playerPosition: TilePoint,
        facing: FacingDirection,
        objects: [FieldObjectTelemetry] = [],
        activeMapScriptTriggerID: String?,
        activeScriptID: String?,
        activeScriptStep: Int?,
        renderMode: String,
        transition: FieldTransitionTelemetry? = nil
    ) {
        self.mapID = mapID
        self.mapName = mapName
        self.playerPosition = playerPosition
        self.facing = facing
        self.objects = objects
        self.activeMapScriptTriggerID = activeMapScriptTriggerID
        self.activeScriptID = activeScriptID
        self.activeScriptStep = activeScriptStep
        self.renderMode = renderMode
        self.transition = transition
    }
}

public struct FieldObjectTelemetry: Codable, Equatable, Sendable {
    public let id: String
    public let position: TilePoint
    public let facing: FacingDirection
    public let movementMode: ActorMovementMode?

    public init(
        id: String,
        position: TilePoint,
        facing: FacingDirection,
        movementMode: ActorMovementMode? = nil
    ) {
        self.id = id
        self.position = position
        self.facing = facing
        self.movementMode = movementMode
    }
}

public struct FieldTransitionTelemetry: Codable, Equatable, Sendable {
    public let kind: String
    public let phase: String

    public init(kind: String, phase: String) {
        self.kind = kind
        self.phase = phase
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
    public let experience: ExperienceProgressTelemetry
    public let speciesID: String
    public let displayName: String
    public let level: Int
    public let currentHP: Int
    public let maxHP: Int
    public let attack: Int
    public let defense: Int
    public let speed: Int
    public let special: Int
    public let growthOutlook: PokemonGrowthOutlookTelemetry
    public let moves: [String]

    public init(
        speciesID: String,
        displayName: String,
        level: Int,
        currentHP: Int,
        maxHP: Int,
        attack: Int,
        defense: Int,
        speed: Int,
        special: Int,
        moves: [String],
        experience: ExperienceProgressTelemetry = .init(total: 0, levelStart: 0, nextLevel: 1),
        growthOutlook: PokemonGrowthOutlookTelemetry = .neutral
    ) {
        self.experience = experience
        self.speciesID = speciesID
        self.displayName = displayName
        self.level = level
        self.currentHP = currentHP
        self.maxHP = maxHP
        self.attack = attack
        self.defense = defense
        self.speed = speed
        self.special = special
        self.growthOutlook = growthOutlook
        self.moves = moves
    }

    private enum CodingKeys: String, CodingKey {
        case experience
        case speciesID
        case displayName
        case level
        case currentHP
        case maxHP
        case attack
        case defense
        case speed
        case special
        case growthOutlook
        case moves
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        experience = try container.decodeIfPresent(ExperienceProgressTelemetry.self, forKey: .experience) ?? .init(total: 0, levelStart: 0, nextLevel: 1)
        speciesID = try container.decode(String.self, forKey: .speciesID)
        displayName = try container.decode(String.self, forKey: .displayName)
        level = try container.decode(Int.self, forKey: .level)
        currentHP = try container.decode(Int.self, forKey: .currentHP)
        maxHP = try container.decode(Int.self, forKey: .maxHP)
        attack = try container.decodeIfPresent(Int.self, forKey: .attack) ?? 0
        defense = try container.decodeIfPresent(Int.self, forKey: .defense) ?? 0
        speed = try container.decodeIfPresent(Int.self, forKey: .speed) ?? 0
        special = try container.decodeIfPresent(Int.self, forKey: .special) ?? 0
        growthOutlook = try container.decodeIfPresent(PokemonGrowthOutlookTelemetry.self, forKey: .growthOutlook) ?? .neutral
        moves = try container.decode([String].self, forKey: .moves)
    }
}

public struct ExperienceProgressTelemetry: Codable, Equatable, Sendable {
    public let total: Int
    public let levelStart: Int
    public let nextLevel: Int

    public init(total: Int, levelStart: Int, nextLevel: Int) {
        self.total = total
        self.levelStart = levelStart
        self.nextLevel = nextLevel
    }
}

public enum PokemonStatGrowthTelemetry: String, Codable, Equatable, Sendable {
    case favored
    case neutral
    case lagging
}

public struct PokemonGrowthOutlookTelemetry: Codable, Equatable, Sendable {
    public static let neutral = PokemonGrowthOutlookTelemetry(
        hp: .neutral,
        attack: .neutral,
        defense: .neutral,
        speed: .neutral,
        special: .neutral
    )

    public let hp: PokemonStatGrowthTelemetry
    public let attack: PokemonStatGrowthTelemetry
    public let defense: PokemonStatGrowthTelemetry
    public let speed: PokemonStatGrowthTelemetry
    public let special: PokemonStatGrowthTelemetry

    public init(
        hp: PokemonStatGrowthTelemetry,
        attack: PokemonStatGrowthTelemetry,
        defense: PokemonStatGrowthTelemetry,
        speed: PokemonStatGrowthTelemetry,
        special: PokemonStatGrowthTelemetry
    ) {
        self.hp = hp
        self.attack = attack
        self.defense = defense
        self.speed = speed
        self.special = special
    }
}

public struct PartyTelemetry: Codable, Equatable, Sendable {
    public let pokemon: [PartyPokemonTelemetry]

    public init(pokemon: [PartyPokemonTelemetry]) {
        self.pokemon = pokemon
    }
}

public struct InventoryItemTelemetry: Codable, Equatable, Sendable {
    public let itemID: String
    public let displayName: String
    public let quantity: Int

    public init(itemID: String, displayName: String, quantity: Int) {
        self.itemID = itemID
        self.displayName = displayName
        self.quantity = quantity
    }
}

public struct InventoryTelemetry: Codable, Equatable, Sendable {
    public let items: [InventoryItemTelemetry]

    public init(items: [InventoryItemTelemetry]) {
        self.items = items
    }
}

public struct BattleTelemetry: Codable, Equatable, Sendable {
    public let battleID: String
    public let kind: BattleKind
    public let trainerName: String
    public let playerPokemon: PartyPokemonTelemetry
    public let enemyPokemon: PartyPokemonTelemetry
    public let enemyPartyCount: Int
    public let enemyActiveIndex: Int
    public let focusedMoveIndex: Int
    public let canRun: Bool
    public let phase: String
    public let textLines: [String]
    public let moveSlots: [BattleMoveSlotTelemetry]
    public let battleMessage: String

    public init(
        battleID: String,
        kind: BattleKind = .trainer,
        trainerName: String,
        playerPokemon: PartyPokemonTelemetry,
        enemyPokemon: PartyPokemonTelemetry,
        enemyPartyCount: Int,
        enemyActiveIndex: Int,
        focusedMoveIndex: Int,
        canRun: Bool = false,
        phase: String = "moveSelection",
        textLines: [String] = [],
        moveSlots: [BattleMoveSlotTelemetry] = [],
        battleMessage: String
    ) {
        self.battleID = battleID
        self.kind = kind
        self.trainerName = trainerName
        self.playerPokemon = playerPokemon
        self.enemyPokemon = enemyPokemon
        self.enemyPartyCount = enemyPartyCount
        self.enemyActiveIndex = enemyActiveIndex
        self.focusedMoveIndex = focusedMoveIndex
        self.canRun = canRun
        self.phase = phase
        self.textLines = textLines
        self.moveSlots = moveSlots
        self.battleMessage = battleMessage
    }

    private enum CodingKeys: String, CodingKey {
        case battleID
        case kind
        case trainerName
        case playerPokemon
        case enemyPokemon
        case enemyPartyCount
        case enemyActiveIndex
        case focusedMoveIndex
        case canRun
        case phase
        case textLines
        case moveSlots
        case battleMessage
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        battleID = try container.decode(String.self, forKey: .battleID)
        kind = try container.decodeIfPresent(BattleKind.self, forKey: .kind) ?? .trainer
        trainerName = try container.decode(String.self, forKey: .trainerName)
        playerPokemon = try container.decode(PartyPokemonTelemetry.self, forKey: .playerPokemon)
        enemyPokemon = try container.decode(PartyPokemonTelemetry.self, forKey: .enemyPokemon)
        enemyPartyCount = try container.decodeIfPresent(Int.self, forKey: .enemyPartyCount) ?? 1
        enemyActiveIndex = try container.decodeIfPresent(Int.self, forKey: .enemyActiveIndex) ?? 0
        focusedMoveIndex = try container.decode(Int.self, forKey: .focusedMoveIndex)
        canRun = try container.decodeIfPresent(Bool.self, forKey: .canRun) ?? false
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
    public let inventory: InventoryTelemetry?
    public let battle: BattleTelemetry?
    public let eventFlags: EventFlagTelemetry?
    public let audio: AudioTelemetry?
    public let save: SaveTelemetry?
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
        inventory: InventoryTelemetry?,
        battle: BattleTelemetry?,
        eventFlags: EventFlagTelemetry?,
        audio: AudioTelemetry?,
        save: SaveTelemetry?,
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
        self.inventory = inventory
        self.battle = battle
        self.eventFlags = eventFlags
        self.audio = audio
        self.save = save
        self.recentInputEvents = recentInputEvents
        self.assetLoadingFailures = assetLoadingFailures
        self.window = window
    }
}

public enum RuntimeSessionEventKind: String, Codable, Equatable, Sendable {
    case sessionStarted
    case scriptStarted
    case scriptFinished
    case dialogueStarted
    case warpCompleted
    case encounterTriggered
    case battleStarted
    case battleEnded
    case inventoryChanged
    case partyHealed
    case saveResult
}

public struct RuntimeSessionEvent: Codable, Equatable, Sendable {
    public let timestamp: String
    public let kind: RuntimeSessionEventKind
    public let message: String
    public let scene: RuntimeScene
    public let mapID: String?
    public let scriptID: String?
    public let dialogueID: String?
    public let battleID: String?
    public let battleKind: BattleKind?
    public let details: [String: String]

    public init(
        timestamp: String,
        kind: RuntimeSessionEventKind,
        message: String,
        scene: RuntimeScene,
        mapID: String?,
        scriptID: String? = nil,
        dialogueID: String? = nil,
        battleID: String? = nil,
        battleKind: BattleKind? = nil,
        details: [String: String] = [:]
    ) {
        self.timestamp = timestamp
        self.kind = kind
        self.message = message
        self.scene = scene
        self.mapID = mapID
        self.scriptID = scriptID
        self.dialogueID = dialogueID
        self.battleID = battleID
        self.battleKind = battleKind
        self.details = details
    }
}

public protocol TelemetryPublisher: Sendable {
    func publish(snapshot: RuntimeTelemetrySnapshot) async
    func publish(event: RuntimeSessionEvent) async
}

public extension TelemetryPublisher {
    func publish(event: RuntimeSessionEvent) async {}
}
