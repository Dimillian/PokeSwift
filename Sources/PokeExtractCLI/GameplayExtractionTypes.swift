import Foundation
import PokeDataModel

struct GameplayExtractionContext {
    let repoRoot: URL
    let mapSizes: [String: TileSize]
    let mapHeadersByID: [String: ParsedMapHeader]
    let mapMusicByMapID: [String: String]
    let mapScriptMetadataByMapID: [String: MapScriptMetadata]
    let objectVisibilityByMapID: [String: [String: Bool]]
    let martStockLabels: Set<String>
    let fieldPalettes: [FieldPaletteManifest]
    let fieldPaletteRules: ParsedFieldPaletteRules
}

struct ParsedFieldPaletteRules {
    let paletteIDsInOrder: [String]
    let mapIndexByID: [String: Int]
    let numCityMaps: Int
    let indoorGroupIDByMapID: [String: String]
}

struct ParsedTilesetCollisionData {
    let passableTilesByKey: [String: [Int]]
    let warpTilesByLabel: [String: [Int]]
    let doorTilesByLabel: [String: [Int]]
    let grassTilesByLabel: [String: Int?]
    let animationKindsByLabel: [String: TilesetAnimationKind]
    let tilePairCollisionsByTileset: [String: [TilePairCollisionManifest]]
    let ledges: [LedgeCollisionManifest]
}

struct RawWarpEntry {
    let origin: TilePoint
    let rawTargetMapID: String
    let targetWarp: Int
}

struct ParsedMapHeader {
    let symbolName: String
    let id: String
    let tileset: String
    let connections: [RawMapConnection]
}

struct RawMapConnection {
    let direction: MapConnectionDirection
    let targetMapID: String
    let offset: Int
}

struct StandardTrainerHeaderMetadata {
    let defeatFlagID: String
    let engageDistance: Int
    let battleTextLabel: String
    let endBattleTextLabel: String
    let afterBattleTextLabel: String
}

struct MapScriptMetadata {
    let textLabelByTextID: [String: String]
    let pickupTextIDs: Set<String>
    let farTextLabelByLocalLabel: [String: String]
    let referencedFarTextLabels: Set<String>
    let trainerHeadersByLabel: [String: StandardTrainerHeaderMetadata]
    let trainerHeaderLabelByTextLabel: [String: String]
    let usesStandardTrainerLoop: Bool
    let wildEncounterSuppressionZones: [WildEncounterSuppressionZoneManifest]
}

struct MapManifestDraft {
    let id: String
    let displayName: String
    let parentMapID: String?
    let isOutdoor: Bool
    let defaultMusicID: String
    let borderBlockID: Int
    let blockWidth: Int
    let blockHeight: Int
    let stepWidth: Int
    let stepHeight: Int
    let tileset: String
    let blockIDs: [Int]
    let stepCollisionTileIDs: [Int]
    let rawWarps: [RawWarpEntry]
    let fieldObstacles: [FieldObstacleManifest]
    let backgroundEvents: [BackgroundEventManifest]
    let objects: [MapObjectManifest]
    let connections: [MapConnectionManifest]
}

struct PokedexData {
    let dexNumber: Int
    let category: String?
    let heightFeet: Int?
    let heightInches: Int?
    let weightTenths: Int?
    let entryText: String?
}

struct PokedexEntryData {
    let category: String
    let heightFeet: Int
    let heightInches: Int
    let weightTenths: Int
}

struct CanonicalSpeciesDefinition {
    let file: String
    let id: String
    let displayName: String
    let cryData: (soundEffectID: String?, pitch: Int?, length: Int?)
}

struct PokemonIndexMetadata {
    let id: String
    let displayName: String
    let cryData: (soundEffectID: String?, pitch: Int?, length: Int?)
}

struct SpeciesProgressionManifest {
    let evolutions: [EvolutionManifest]
    let levelUpLearnset: [LevelUpMoveManifest]
}

enum SpeciesProgressionSection {
    case none
    case evolutions
    case learnset
}

struct TrainerClassMetadata {
    let displayName: String
    let parties: [[TrainerPokemonManifest]]
    let trainerSpritePath: String?
    let baseRewardMoney: Int
}

struct ReferencedSliceTrainerBattle {
    let id: String
    let trainerClass: String
    let trainerNumber: Int
    let playerWinDialogueID: String
    let completionFlagID: String
}

struct TrainerRewardMetadata {
    let trainerSpritePath: String?
    let baseRewardMoney: Int
}
