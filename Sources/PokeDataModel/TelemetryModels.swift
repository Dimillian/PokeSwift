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
    case evolution
    case naming
    case oakIntro
    case titleOptions
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
    public let alert: FieldAlertTelemetry?
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
        alert: FieldAlertTelemetry? = nil,
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
        self.alert = alert
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

public enum FieldAlertBubbleKind: String, Codable, Equatable, Sendable {
    case exclamation
}

public struct FieldAlertTelemetry: Codable, Equatable, Sendable {
    public let objectID: String
    public let kind: FieldAlertBubbleKind

    public init(objectID: String, kind: FieldAlertBubbleKind) {
        self.objectID = objectID
        self.kind = kind
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

public struct FieldPromptTelemetry: Codable, Equatable, Sendable {
    public let interactionID: String
    public let kind: String
    public let options: [String]
    public let focusedIndex: Int

    public init(interactionID: String, kind: String, options: [String], focusedIndex: Int) {
        self.interactionID = interactionID
        self.kind = kind
        self.options = options
        self.focusedIndex = focusedIndex
    }
}

public struct FieldHealingTelemetry: Codable, Equatable, Sendable {
    public let interactionID: String
    public let phase: String
    public let activeBallCount: Int
    public let totalBallCount: Int
    public let pulseStep: Int
    public let nurseObjectID: String?

    public init(
        interactionID: String,
        phase: String,
        activeBallCount: Int,
        totalBallCount: Int,
        pulseStep: Int,
        nurseObjectID: String? = nil
    ) {
        self.interactionID = interactionID
        self.phase = phase
        self.activeBallCount = activeBallCount
        self.totalBallCount = totalBallCount
        self.pulseStep = pulseStep
        self.nurseObjectID = nurseObjectID
    }
}

public struct PartyMoveTelemetry: Codable, Equatable, Sendable {
    public let id: String
    public let currentPP: Int?

    public init(id: String, currentPP: Int? = nil) {
        self.id = id
        self.currentPP = currentPP
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
    public let majorStatus: MajorStatusCondition
    public let moves: [String]
    public let moveStates: [PartyMoveTelemetry]

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
        majorStatus: MajorStatusCondition = .none,
        moves: [String],
        moveStates: [PartyMoveTelemetry]? = nil,
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
        self.majorStatus = majorStatus
        self.moves = moves
        self.moveStates = moveStates ?? moves.map { PartyMoveTelemetry(id: $0) }
    }

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
        majorStatus: MajorStatusCondition = .none,
        moveStates: [PartyMoveTelemetry],
        experience: ExperienceProgressTelemetry = .init(total: 0, levelStart: 0, nextLevel: 1),
        growthOutlook: PokemonGrowthOutlookTelemetry = .neutral
    ) {
        self.init(
            speciesID: speciesID,
            displayName: displayName,
            level: level,
            currentHP: currentHP,
            maxHP: maxHP,
            attack: attack,
            defense: defense,
            speed: speed,
            special: special,
            majorStatus: majorStatus,
            moves: moveStates.map(\.id),
            moveStates: moveStates,
            experience: experience,
            growthOutlook: growthOutlook
        )
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
        case majorStatus
        case moves
        case moveStates
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
        majorStatus = try container.decodeIfPresent(MajorStatusCondition.self, forKey: .majorStatus) ?? .none
        let decodedLegacyMoves: [String]
        let decodedMoveStates: [PartyMoveTelemetry]
        if let legacyMoveIDs = try? container.decode([String].self, forKey: .moves) {
            decodedLegacyMoves = legacyMoveIDs
        } else if let structuredMoves = try? container.decode([PartyMoveTelemetry].self, forKey: .moves) {
            decodedLegacyMoves = structuredMoves.map(\.id)
        } else {
            decodedLegacyMoves = []
        }

        if let structuredMoves = try? container.decode([PartyMoveTelemetry].self, forKey: .moveStates) {
            decodedMoveStates = structuredMoves
        } else if let structuredMoves = try? container.decode([PartyMoveTelemetry].self, forKey: .moves) {
            decodedMoveStates = structuredMoves
        } else {
            decodedMoveStates = decodedLegacyMoves.map { PartyMoveTelemetry(id: $0) }
        }

        moveStates = decodedMoveStates
        moves = decodedLegacyMoves.isEmpty ? decodedMoveStates.map(\.id) : decodedLegacyMoves
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

public enum BattlePresentationStage: String, Codable, Equatable, Sendable {
    case idle
    case introFlash1
    case introFlash2
    case introFlash3
    case introSpiral
    case introCrossing
    case introReveal
    case commandReady
    case attackWindup
    case attackImpact
    case hpDrain
    case resultText
    case faint
    case experience
    case levelUp
    case enemySendOut
    case turnSettle
    case battleComplete
}

public enum BattlePresentationSide: String, Codable, Equatable, Sendable {
    case player
    case enemy
}

public enum BattlePresentationUIVisibility: String, Codable, Equatable, Sendable {
    case hidden
    case visible
}

public enum BattleTransitionStyle: String, Codable, Equatable, Sendable {
    case none
    case circle
    case spiral
}

public enum BattleMeterKind: String, Codable, Equatable, Sendable {
    case hp
    case experience
}

public struct BattleMeterAnimationTelemetry: Codable, Equatable, Sendable {
    public let kind: BattleMeterKind
    public let side: BattlePresentationSide
    public let fromValue: Int
    public let toValue: Int
    public let maximumValue: Int
    public let startLevel: Int?
    public let endLevel: Int?
    public let startLevelStart: Int?
    public let startNextLevel: Int?
    public let endLevelStart: Int?
    public let endNextLevel: Int?

    public init(
        kind: BattleMeterKind,
        side: BattlePresentationSide,
        fromValue: Int,
        toValue: Int,
        maximumValue: Int,
        startLevel: Int? = nil,
        endLevel: Int? = nil,
        startLevelStart: Int? = nil,
        startNextLevel: Int? = nil,
        endLevelStart: Int? = nil,
        endNextLevel: Int? = nil
    ) {
        self.kind = kind
        self.side = side
        self.fromValue = fromValue
        self.toValue = toValue
        self.maximumValue = maximumValue
        self.startLevel = startLevel
        self.endLevel = endLevel
        self.startLevelStart = startLevelStart
        self.startNextLevel = startNextLevel
        self.endLevelStart = endLevelStart
        self.endNextLevel = endNextLevel
    }
}

public struct BattleAttackAnimationPlaybackTelemetry: Codable, Equatable, Sendable {
    public let playbackID: String
    public let moveID: String
    public let attackerSide: BattlePresentationSide
    public let totalDuration: TimeInterval

    public init(
        playbackID: String,
        moveID: String,
        attackerSide: BattlePresentationSide,
        totalDuration: TimeInterval
    ) {
        self.playbackID = playbackID
        self.moveID = moveID
        self.attackerSide = attackerSide
        self.totalDuration = totalDuration
    }
}

public enum BattleApplyingHitEffectKind: String, Codable, Equatable, Sendable {
    case shakeScreenVertical
    case shakeScreenHorizontalHeavy
    case shakeScreenHorizontalLight
    case shakeScreenHorizontalSlow
    case shakeScreenHorizontalSlow2
    case blinkDefender
}

public struct BattleApplyingHitEffectTelemetry: Codable, Equatable, Sendable {
    public let playbackID: String
    public let kind: BattleApplyingHitEffectKind
    public let attackerSide: BattlePresentationSide
    public let totalDuration: TimeInterval

    public init(
        playbackID: String,
        kind: BattleApplyingHitEffectKind,
        attackerSide: BattlePresentationSide,
        totalDuration: TimeInterval
    ) {
        self.playbackID = playbackID
        self.kind = kind
        self.attackerSide = attackerSide
        self.totalDuration = totalDuration
    }
}

public struct BattlePresentationTelemetry: Codable, Equatable, Sendable {
    public let stage: BattlePresentationStage
    public let revision: Int
    public let uiVisibility: BattlePresentationUIVisibility
    public let activeSide: BattlePresentationSide?
    public let hidePlayerPokemon: Bool
    public let transitionStyle: BattleTransitionStyle
    public let meterAnimation: BattleMeterAnimationTelemetry?
    public let attackAnimation: BattleAttackAnimationPlaybackTelemetry?
    public let applyingHitEffect: BattleApplyingHitEffectTelemetry?

    public init(
        stage: BattlePresentationStage,
        revision: Int,
        uiVisibility: BattlePresentationUIVisibility,
        activeSide: BattlePresentationSide? = nil,
        hidePlayerPokemon: Bool = false,
        transitionStyle: BattleTransitionStyle = .none,
        meterAnimation: BattleMeterAnimationTelemetry? = nil,
        attackAnimation: BattleAttackAnimationPlaybackTelemetry? = nil,
        applyingHitEffect: BattleApplyingHitEffectTelemetry? = nil
    ) {
        self.stage = stage
        self.revision = revision
        self.uiVisibility = uiVisibility
        self.activeSide = activeSide
        self.hidePlayerPokemon = hidePlayerPokemon
        self.transitionStyle = transitionStyle
        self.meterAnimation = meterAnimation
        self.attackAnimation = attackAnimation
        self.applyingHitEffect = applyingHitEffect
    }
}

public enum BattleApplyingHitEffectPlaybackDefaults {
    public static let framesPerSecond: Double = 60

    public static func frameCount(for kind: BattleApplyingHitEffectKind) -> Int {
        switch kind {
        case .shakeScreenVertical:
            return 48
        case .shakeScreenHorizontalHeavy:
            return 72
        case .shakeScreenHorizontalLight:
            return 18
        case .shakeScreenHorizontalSlow:
            return 48
        case .shakeScreenHorizontalSlow2:
            return 24
        case .blinkDefender:
            return 78
        }
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

public struct ShopRowTelemetry: Codable, Equatable, Sendable {
    public let itemID: String
    public let displayName: String
    public let ownedQuantity: Int
    public let unitPrice: Int
    public let transactionPrice: Int
    public let isSelectable: Bool

    public init(
        itemID: String,
        displayName: String,
        ownedQuantity: Int,
        unitPrice: Int,
        transactionPrice: Int,
        isSelectable: Bool = true
    ) {
        self.itemID = itemID
        self.displayName = displayName
        self.ownedQuantity = ownedQuantity
        self.unitPrice = unitPrice
        self.transactionPrice = transactionPrice
        self.isSelectable = isSelectable
    }
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

public struct InventoryItemTelemetry: Codable, Equatable, Sendable {
    public let itemID: String
    public let displayName: String
    public let quantity: Int
    public let price: Int
    public let battleUse: ItemManifest.BattleUseKind

    public init(
        itemID: String,
        displayName: String,
        quantity: Int,
        price: Int = 0,
        battleUse: ItemManifest.BattleUseKind = .none
    ) {
        self.itemID = itemID
        self.displayName = displayName
        self.quantity = quantity
        self.price = price
        self.battleUse = battleUse
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
    public let phase: String
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
        phase: String = "moveSelection",
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
        kind = try container.decodeIfPresent(BattleKind.self, forKey: .kind) ?? .trainer
        trainerName = try container.decode(String.self, forKey: .trainerName)
        trainerSpritePath = try container.decodeIfPresent(String.self, forKey: .trainerSpritePath)
        playerPokemon = try container.decode(PartyPokemonTelemetry.self, forKey: .playerPokemon)
        enemyPokemon = try container.decode(PartyPokemonTelemetry.self, forKey: .enemyPokemon)
        enemyPartyCount = try container.decodeIfPresent(Int.self, forKey: .enemyPartyCount) ?? 1
        enemyActiveIndex = try container.decodeIfPresent(Int.self, forKey: .enemyActiveIndex) ?? 0
        focusedMoveIndex = try container.decode(Int.self, forKey: .focusedMoveIndex)
        focusedBagItemIndex = try container.decodeIfPresent(Int.self, forKey: .focusedBagItemIndex) ?? 0
        focusedPartyIndex = try container.decodeIfPresent(Int.self, forKey: .focusedPartyIndex) ?? 0
        canRun = try container.decodeIfPresent(Bool.self, forKey: .canRun) ?? false
        canUseBag = try container.decodeIfPresent(Bool.self, forKey: .canUseBag) ?? false
        canSwitch = try container.decodeIfPresent(Bool.self, forKey: .canSwitch) ?? false
        phase = try container.decodeIfPresent(String.self, forKey: .phase) ?? "moveSelection"
        textLines = try container.decodeIfPresent([String].self, forKey: .textLines) ?? []
        learnMovePrompt = try container.decodeIfPresent(BattleLearnMovePromptTelemetry.self, forKey: .learnMovePrompt)
        moveSlots = try container.decodeIfPresent([BattleMoveSlotTelemetry].self, forKey: .moveSlots) ?? []
        bagItems = try container.decodeIfPresent([InventoryItemTelemetry].self, forKey: .bagItems) ?? []
        battleMessage = try container.decode(String.self, forKey: .battleMessage)
        capture = try container.decodeIfPresent(BattleCaptureTelemetry.self, forKey: .capture)
        presentation = try container.decodeIfPresent(BattlePresentationTelemetry.self, forKey: .presentation) ?? .init(
            stage: .idle,
            revision: 0,
            uiVisibility: .visible
        )
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

public struct ShopTelemetry: Codable, Equatable, Sendable {
    public let martID: String
    public let title: String
    public let phase: String
    public let promptText: String
    public let focusedMainMenuIndex: Int
    public let focusedItemIndex: Int
    public let focusedConfirmationIndex: Int
    public let selectedQuantity: Int
    public let selectedTransactionKind: String?
    public let menuOptions: [String]
    public let buyItems: [ShopRowTelemetry]
    public let sellItems: [ShopRowTelemetry]

    public init(
        martID: String,
        title: String,
        phase: String,
        promptText: String,
        focusedMainMenuIndex: Int,
        focusedItemIndex: Int,
        focusedConfirmationIndex: Int,
        selectedQuantity: Int,
        selectedTransactionKind: String?,
        menuOptions: [String],
        buyItems: [ShopRowTelemetry],
        sellItems: [ShopRowTelemetry]
    ) {
        self.martID = martID
        self.title = title
        self.phase = phase
        self.promptText = promptText
        self.focusedMainMenuIndex = focusedMainMenuIndex
        self.focusedItemIndex = focusedItemIndex
        self.focusedConfirmationIndex = focusedConfirmationIndex
        self.selectedQuantity = selectedQuantity
        self.selectedTransactionKind = selectedTransactionKind
        self.menuOptions = menuOptions
        self.buyItems = buyItems
        self.sellItems = sellItems
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

public enum SoundEffectPlaybackStatusTelemetry: String, Codable, Equatable, Sendable {
    case started
    case rejected
}

public struct SoundEffectTelemetry: Codable, Equatable, Sendable {
    public let soundEffectID: String
    public let reason: String
    public let playbackRevision: Int
    public let status: SoundEffectPlaybackStatusTelemetry
    public let replacedSoundEffectID: String?

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
    public let fieldPrompt: FieldPromptTelemetry?
    public let fieldHealing: FieldHealingTelemetry?
    public let starterChoice: StarterChoiceTelemetry?
    public let party: PartyTelemetry?
    public let inventory: InventoryTelemetry?
    public let battle: BattleTelemetry?
    public let shop: ShopTelemetry?
    public let eventFlags: EventFlagTelemetry?
    public let audio: AudioTelemetry?
    public let soundEffects: [SoundEffectTelemetry]
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
        fieldPrompt: FieldPromptTelemetry? = nil,
        fieldHealing: FieldHealingTelemetry? = nil,
        starterChoice: StarterChoiceTelemetry?,
        party: PartyTelemetry?,
        inventory: InventoryTelemetry?,
        battle: BattleTelemetry?,
        shop: ShopTelemetry?,
        eventFlags: EventFlagTelemetry?,
        audio: AudioTelemetry?,
        soundEffects: [SoundEffectTelemetry] = [],
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
        self.fieldPrompt = fieldPrompt
        self.fieldHealing = fieldHealing
        self.starterChoice = starterChoice
        self.party = party
        self.inventory = inventory
        self.battle = battle
        self.shop = shop
        self.eventFlags = eventFlags
        self.audio = audio
        self.soundEffects = soundEffects
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
    case scriptFailed
    case dialogueStarted
    case warpCompleted
    case encounterTriggered
    case battleStarted
    case battleEnded
    case blackout
    case shopOpened
    case shopClosed
    case shopPurchase
    case inventoryChanged
    case partyHealed
    case saveResult
    case nicknameApplied
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
