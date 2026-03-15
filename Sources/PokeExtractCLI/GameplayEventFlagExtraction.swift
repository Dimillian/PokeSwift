import Foundation
import PokeDataModel

func parseEventFlags(
    repoRoot: URL,
    maps: [MapManifest],
    wildEncounterTables: [WildEncounterTableManifest],
    fieldInteractions: [FieldInteractionManifest],
    mapScripts: [MapScriptManifest],
    scripts: [ScriptManifest],
    trainerBattles: [TrainerBattleManifest],
    playerStart: PlayerStartManifest
) throws -> [EventFlagDefinition] {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("constants/event_constants.asm"))
    let requiredFlags = referencedEventFlagIDs(
        maps: maps,
        wildEncounterTables: wildEncounterTables,
        fieldInteractions: fieldInteractions,
        mapScripts: mapScripts,
        scripts: scripts,
        trainerBattles: trainerBattles,
        playerStart: playerStart
    )

    return try requiredFlags.map { flagID in
        guard contents.contains("const \(flagID)") else {
            throw ExtractorError.invalidArguments("missing event flag \(flagID)")
        }
        return EventFlagDefinition(id: flagID, sourceConstant: flagID)
    }
}

private func referencedEventFlagIDs(
    maps: [MapManifest],
    wildEncounterTables: [WildEncounterTableManifest],
    fieldInteractions: [FieldInteractionManifest],
    mapScripts: [MapScriptManifest],
    scripts: [ScriptManifest],
    trainerBattles: [TrainerBattleManifest],
    playerStart: PlayerStartManifest
) -> [String] {
    let objectTriggerFlags = maps.flatMap { map in
        map.objects.flatMap { object in
            object.interactionTriggers.flatMap { $0.conditions.compactMap(\.flagID) }
        }
    }
    let fieldInteractionFlags = fieldInteractions.compactMap { interaction in
        interaction.paidAdmission?.successFlagID
    }
    let encounterZoneFlags = wildEncounterTables.flatMap { table in
        table.suppressionZones.flatMap { $0.conditions.compactMap(\.flagID) }
    }
    let mapScriptFlags = mapScripts.flatMap { $0.triggers.flatMap { $0.conditions.compactMap(\.flagID) } }
    let scriptStepFlags = scripts.flatMap { script in
        script.steps.compactMap(\.flagID)
        + script.steps.compactMap(\.successFlagID)
        + script.steps.flatMap { step in
            (step.movement?.variants ?? []).flatMap { $0.conditions.compactMap(\.flagID) }
        }
    }
    let trainerBattleFlags = trainerBattles.map(\.completionFlagID).filter { $0.isEmpty == false }

    return Set(
        playerStart.initialFlags
        + objectTriggerFlags
        + fieldInteractionFlags
        + encounterZoneFlags
        + mapScriptFlags
        + scriptStepFlags
        + trainerBattleFlags
    )
    .sorted()
}
