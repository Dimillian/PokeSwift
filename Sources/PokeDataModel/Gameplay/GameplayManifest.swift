import Foundation

public struct GameplayManifest: Codable, Equatable, Sendable {
    public let maps: [MapManifest]
    public let tilesets: [TilesetManifest]
    public let overworldSprites: [OverworldSpriteManifest]
    public let dialogues: [DialogueManifest]
    public let fieldInteractions: [FieldInteractionManifest]
    public let eventFlags: EventFlagManifest
    public let mapScripts: [MapScriptManifest]
    public let scripts: [ScriptManifest]
    public let items: [ItemManifest]
    public let marts: [MartManifest]
    public let species: [SpeciesManifest]
    public let moves: [MoveManifest]
    public let typeEffectiveness: [TypeEffectivenessManifest]
    public let wildEncounterTables: [WildEncounterTableManifest]
    public let trainerAIMoveChoiceModifications: [TrainerAIMoveChoiceModificationManifest]
    public let trainerBattles: [TrainerBattleManifest]
    public let commonBattleText: BattleTextTemplateManifest
    public let playerStart: PlayerStartManifest

    public init(
        maps: [MapManifest],
        tilesets: [TilesetManifest],
        overworldSprites: [OverworldSpriteManifest],
        dialogues: [DialogueManifest],
        fieldInteractions: [FieldInteractionManifest] = [],
        eventFlags: EventFlagManifest,
        mapScripts: [MapScriptManifest],
        scripts: [ScriptManifest],
        items: [ItemManifest] = [],
        marts: [MartManifest] = [],
        species: [SpeciesManifest],
        moves: [MoveManifest],
        typeEffectiveness: [TypeEffectivenessManifest] = [],
        wildEncounterTables: [WildEncounterTableManifest] = [],
        trainerAIMoveChoiceModifications: [TrainerAIMoveChoiceModificationManifest] = [],
        trainerBattles: [TrainerBattleManifest],
        commonBattleText: BattleTextTemplateManifest = .init(
            wantsToFight: "{trainerName} wants to fight!",
            enemyFainted: "Enemy {enemyPokemon} fainted!",
            playerFainted: "{playerPokemon} fainted!",
            playerBlackedOut: "{playerName} is out of useable POKéMON! {playerName} blacked out!",
            trainerDefeated: "{playerName} defeated {trainerName}!",
            moneyForWinning: "{playerName} got ¥{money} for winning!",
            trainerAboutToUse: "{trainerName} is about to use {enemyPokemon}! Will {playerName} change #MON?",
            trainerSentOut: "{trainerName} sent out {enemyPokemon}!",
            playerSendOutGo: "Go! {playerPokemon}!",
            playerSendOutDoIt: "Do it! {playerPokemon}!",
            playerSendOutGetm: "Get'm! {playerPokemon}!",
            playerSendOutEnemyWeak: "The enemy's weak! Get'm! {playerPokemon}!"
        ),
        playerStart: PlayerStartManifest
    ) {
        self.maps = maps
        self.tilesets = tilesets
        self.overworldSprites = overworldSprites
        self.dialogues = dialogues
        self.fieldInteractions = fieldInteractions
        self.eventFlags = eventFlags
        self.mapScripts = mapScripts
        self.scripts = scripts
        self.items = items
        self.marts = marts
        self.species = species
        self.moves = moves
        self.typeEffectiveness = typeEffectiveness
        self.wildEncounterTables = wildEncounterTables
        self.trainerAIMoveChoiceModifications = trainerAIMoveChoiceModifications
        self.trainerBattles = trainerBattles
        self.commonBattleText = commonBattleText
        self.playerStart = playerStart
    }

    private enum CodingKeys: String, CodingKey {
        case maps
        case tilesets
        case overworldSprites
        case dialogues
        case fieldInteractions
        case eventFlags
        case mapScripts
        case scripts
        case items
        case marts
        case species
        case moves
        case typeEffectiveness
        case wildEncounterTables
        case trainerAIMoveChoiceModifications
        case trainerBattles
        case commonBattleText
        case playerStart
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        maps = try container.decode([MapManifest].self, forKey: .maps)
        tilesets = try container.decode([TilesetManifest].self, forKey: .tilesets)
        overworldSprites = try container.decode([OverworldSpriteManifest].self, forKey: .overworldSprites)
        dialogues = try container.decode([DialogueManifest].self, forKey: .dialogues)
        fieldInteractions = try container.decodeIfPresent([FieldInteractionManifest].self, forKey: .fieldInteractions) ?? []
        eventFlags = try container.decode(EventFlagManifest.self, forKey: .eventFlags)
        mapScripts = try container.decode([MapScriptManifest].self, forKey: .mapScripts)
        scripts = try container.decode([ScriptManifest].self, forKey: .scripts)
        items = try container.decodeIfPresent([ItemManifest].self, forKey: .items) ?? []
        marts = try container.decodeIfPresent([MartManifest].self, forKey: .marts) ?? []
        species = try container.decode([SpeciesManifest].self, forKey: .species)
        moves = try container.decode([MoveManifest].self, forKey: .moves)
        typeEffectiveness = try container.decodeIfPresent([TypeEffectivenessManifest].self, forKey: .typeEffectiveness) ?? []
        wildEncounterTables = try container.decodeIfPresent([WildEncounterTableManifest].self, forKey: .wildEncounterTables) ?? []
        trainerAIMoveChoiceModifications = try container.decodeIfPresent(
            [TrainerAIMoveChoiceModificationManifest].self,
            forKey: .trainerAIMoveChoiceModifications
        ) ?? []
        trainerBattles = try container.decode([TrainerBattleManifest].self, forKey: .trainerBattles)
        commonBattleText = try container.decodeIfPresent(BattleTextTemplateManifest.self, forKey: .commonBattleText) ?? .init(
            wantsToFight: "{trainerName} wants to fight!",
            enemyFainted: "Enemy {enemyPokemon} fainted!",
            playerFainted: "{playerPokemon} fainted!",
            playerBlackedOut: "{playerName} is out of useable POKéMON! {playerName} blacked out!",
            trainerDefeated: "{playerName} defeated {trainerName}!",
            moneyForWinning: "{playerName} got ¥{money} for winning!",
            trainerAboutToUse: "{trainerName} is about to use {enemyPokemon}! Will {playerName} change #MON?",
            trainerSentOut: "{trainerName} sent out {enemyPokemon}!",
            playerSendOutGo: "Go! {playerPokemon}!",
            playerSendOutDoIt: "Do it! {playerPokemon}!",
            playerSendOutGetm: "Get'm! {playerPokemon}!",
            playerSendOutEnemyWeak: "The enemy's weak! Get'm! {playerPokemon}!"
        )
        playerStart = try container.decode(PlayerStartManifest.self, forKey: .playerStart)
    }
}
