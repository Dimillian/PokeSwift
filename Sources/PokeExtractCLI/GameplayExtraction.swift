import Foundation
import PokeDataModel

func extractGameplayManifest(source: SourceTree) throws -> GameplayManifest {
    let context = try makeGameplayExtractionContext(source: source)
    let tilesets = try buildTilesets(repoRoot: context.repoRoot)

    let mapDrafts = try gameplayCoverageMaps.map { definition in
        try makeMapManifestDraft(
            repoRoot: context.repoRoot,
            definition: definition,
            size: context.mapSizes[definition.mapID] ?? fallbackMapSize(for: definition.mapID),
            defaultMusicID: context.mapMusicByMapID[definition.mapID] ?? fallbackMusicID(for: definition.mapID),
            mapSizes: context.mapSizes,
            mapHeadersByID: context.mapHeadersByID,
            tilesets: tilesets,
            mapScriptMetadata: context.mapScriptMetadataByMapID[definition.mapID],
            objectVisibilityByConstant: context.objectVisibilityByMapID[definition.mapID] ?? [:],
            martStockLabels: context.martStockLabels
        )
    }
    let maps = try resolveMapWarps(mapDrafts, tilesets: tilesets)
    let playerStart = try buildPlayerStart(repoRoot: context.repoRoot)
    let itemNamesByID = try parseItemNames(repoRoot: context.repoRoot)
    let dialogues = try buildDialogues(
        repoRoot: context.repoRoot,
        mapScriptMetadataByMapID: context.mapScriptMetadataByMapID,
        itemNamesByID: itemNamesByID
    )
    let fieldInteractions = try buildFieldInteractions(maps: maps, repoRoot: context.repoRoot)
    let mapScripts = buildMapScripts()
    let scripts = try buildScripts(repoRoot: context.repoRoot, maps: maps)
    let items = try buildItems(repoRoot: context.repoRoot)
    let marts = try buildMarts(repoRoot: context.repoRoot, mapScriptMetadataByMapID: context.mapScriptMetadataByMapID)
    let species = try buildSpecies(repoRoot: context.repoRoot)
    let moves = try buildMoves(repoRoot: context.repoRoot)
    let typeEffectiveness = try buildTypeEffectiveness(repoRoot: context.repoRoot)
    let wildEncounterTables = try buildWildEncounterTables(
        repoRoot: context.repoRoot,
        maps: maps,
        mapScriptMetadataByMapID: context.mapScriptMetadataByMapID
    )
    let trainerAIMoveChoiceModifications = try buildTrainerAIMoveChoiceModifications(repoRoot: context.repoRoot)
    let trainerBattles = try buildTrainerBattles(
        repoRoot: context.repoRoot,
        mapScriptMetadataByMapID: context.mapScriptMetadataByMapID
    )
    let eventFlags = try parseEventFlags(
        repoRoot: context.repoRoot,
        maps: maps,
        wildEncounterTables: wildEncounterTables,
        fieldInteractions: fieldInteractions,
        mapScripts: mapScripts,
        scripts: scripts,
        trainerBattles: trainerBattles,
        playerStart: playerStart
    )
    let commonBattleText = try buildCommonBattleText(repoRoot: context.repoRoot)

    return GameplayManifest(
        maps: maps,
        tilesets: tilesets,
        overworldSprites: buildOverworldSprites(),
        dialogues: dialogues,
        fieldInteractions: fieldInteractions,
        eventFlags: EventFlagManifest(flags: eventFlags),
        mapScripts: mapScripts,
        scripts: scripts,
        items: items,
        marts: marts,
        species: species,
        moves: moves,
        typeEffectiveness: typeEffectiveness,
        wildEncounterTables: wildEncounterTables,
        trainerAIMoveChoiceModifications: trainerAIMoveChoiceModifications,
        trainerBattles: trainerBattles,
        commonBattleText: commonBattleText,
        playerStart: playerStart
    )
}

private func makeGameplayExtractionContext(source: SourceTree) throws -> GameplayExtractionContext {
    let mapSizes = try parseMapSizes(repoRoot: source.repoRoot)
    let mapHeadersByID = try parseMapHeaders(repoRoot: source.repoRoot)
    let mapMusicByMapID = try parseMapMusic(repoRoot: source.repoRoot)
    let mapScriptMetadataByMapID = try parseSelectedMapScriptMetadata(repoRoot: source.repoRoot)
    let objectVisibilityByMapID = try parseToggleableObjectDefaultVisibility(repoRoot: source.repoRoot)
    let martStockLabels = try Set(parseMartStocks(repoRoot: source.repoRoot).keys)

    return GameplayExtractionContext(
        repoRoot: source.repoRoot,
        mapSizes: mapSizes,
        mapHeadersByID: mapHeadersByID,
        mapMusicByMapID: mapMusicByMapID,
        mapScriptMetadataByMapID: mapScriptMetadataByMapID,
        objectVisibilityByMapID: objectVisibilityByMapID,
        martStockLabels: martStockLabels
    )
}
