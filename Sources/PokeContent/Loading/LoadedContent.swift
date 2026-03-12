import Foundation
import PokeDataModel

public struct LoadedContent: Sendable {
    public let rootURL: URL
    public let gameManifest: GameManifest
    public let constantsManifest: ConstantsManifest
    public let charmapManifest: CharmapManifest
    public let titleManifest: TitleSceneManifest
    public let audioManifest: AudioManifest
    public let gameplayManifest: GameplayManifest

    public init(
        rootURL: URL,
        gameManifest: GameManifest,
        constantsManifest: ConstantsManifest,
        charmapManifest: CharmapManifest,
        titleManifest: TitleSceneManifest,
        audioManifest: AudioManifest,
        gameplayManifest: GameplayManifest
    ) {
        self.rootURL = rootURL
        self.gameManifest = gameManifest
        self.constantsManifest = constantsManifest
        self.charmapManifest = charmapManifest
        self.titleManifest = titleManifest
        self.audioManifest = audioManifest
        self.gameplayManifest = gameplayManifest
    }

    public var contentRoot: URL {
        rootURL
    }

    public var titleSceneManifest: TitleSceneManifest {
        titleManifest
    }

    public func map(id: String) -> MapManifest? {
        gameplayManifest.maps.first { $0.id == id }
    }

    public func tileset(id: String) -> TilesetManifest? {
        gameplayManifest.tilesets.first { $0.id == id }
    }

    public func overworldSprite(id: String) -> OverworldSpriteManifest? {
        gameplayManifest.overworldSprites.first { $0.id == id }
    }

    public func dialogue(id: String) -> DialogueManifest? {
        gameplayManifest.dialogues.first { $0.id == id }
    }

    public func fieldInteraction(id: String) -> FieldInteractionManifest? {
        gameplayManifest.fieldInteractions.first { $0.id == id }
    }

    public func script(id: String) -> ScriptManifest? {
        gameplayManifest.scripts.first { $0.id == id }
    }

    public func mapScript(for mapID: String) -> MapScriptManifest? {
        gameplayManifest.mapScripts.first { $0.mapID == mapID }
    }

    public func species(id: String) -> SpeciesManifest? {
        gameplayManifest.species.first { $0.id == id }
    }

    public func item(id: String) -> ItemManifest? {
        gameplayManifest.items.first { $0.id == id }
    }

    public func mart(id: String) -> MartManifest? {
        gameplayManifest.marts.first { $0.id == id }
    }

    public func mart(mapID: String, clerkObjectID: String) -> MartManifest? {
        gameplayManifest.marts.first { $0.mapID == mapID && $0.clerkObjectID == clerkObjectID }
    }

    public func move(id: String) -> MoveManifest? {
        gameplayManifest.moves.first { $0.id == id }
    }

    public func typeEffectiveness(attackingType: String, defendingType: String) -> TypeEffectivenessManifest? {
        gameplayManifest.typeEffectiveness.first { $0.attackingType == attackingType && $0.defendingType == defendingType }
    }

    public func wildEncounterTable(mapID: String) -> WildEncounterTableManifest? {
        gameplayManifest.wildEncounterTables.first { $0.mapID == mapID }
    }

    public func trainerBattle(id: String) -> TrainerBattleManifest? {
        gameplayManifest.trainerBattles.first { $0.id == id }
    }

    public func trainerBattle(trainerClass: String, trainerNumber: Int) -> TrainerBattleManifest? {
        gameplayManifest.trainerBattles.first { $0.trainerClass == trainerClass && $0.trainerNumber == trainerNumber }
    }

    public func trainerAIMoveChoiceModifications(trainerClass: String) -> TrainerAIMoveChoiceModificationManifest? {
        let normalizedClass = Self.normalizedTrainerAIClassKey(trainerClass)
        return gameplayManifest.trainerAIMoveChoiceModifications.first {
            Self.normalizedTrainerAIClassKey($0.trainerClass) == normalizedClass
        }
    }

    public func audioTrack(id: String) -> AudioManifest.Track? {
        audioManifest.tracks.first { $0.id == id }
    }

    public func audioEntry(trackID: String, entryID: String = "default") -> AudioManifest.Entry? {
        audioTrack(id: trackID)?.entries.first { $0.id == entryID }
    }

    public func audioCue(id: String) -> AudioManifest.Cue? {
        audioManifest.cues.first { $0.id == id }
    }

    public func soundEffect(id: String) -> AudioManifest.SoundEffect? {
        audioManifest.soundEffects.first { $0.id == id }
    }

    static func normalizedTrainerAIClassKey(_ trainerClass: String) -> String {
        trainerClass
            .replacingOccurrences(of: "OPP_", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: " ", with: "")
    }
}
