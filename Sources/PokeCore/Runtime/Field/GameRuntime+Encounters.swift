import Foundation
import PokeDataModel

extension GameRuntime {
    func evaluateWildEncounterIfNeeded() {
        guard isReadyForFreeFieldStep,
              var gameplayState,
              gameplayState.battle == nil,
              let map = currentMapManifest,
              let encounterTable = content.wildEncounterTable(mapID: map.id),
              encounterTable.grassEncounterRate > 0,
              canTriggerLandEncounter(in: map, position: gameplayState.playerPosition, encounterTable: encounterTable) else {
            return
        }

        gameplayState.encounterStepCounter += 1
        self.gameplayState = gameplayState

        guard nextAcquisitionRandomByte() < encounterTable.grassEncounterRate else {
            return
        }
        guard let encounter = selectWildEncounter(from: encounterTable.grassSlots) else {
            return
        }

        traceEvent(
            .encounterTriggered,
            "Triggered wild encounter with \(encounter.speciesID).",
            mapID: gameplayState.mapID,
            battleKind: .wild,
            details: [
                "speciesID": encounter.speciesID,
                "level": String(encounter.level),
                "encounterRate": String(encounterTable.grassEncounterRate),
                "encounterSurface": encounterTable.landEncounterSurface.rawValue,
                "stepCounter": String(gameplayState.encounterStepCounter),
            ]
        )
        startWildBattle(speciesID: encounter.speciesID, level: encounter.level)
    }

    func canTriggerLandEncounter(
        in map: MapManifest,
        position: TilePoint,
        encounterTable: WildEncounterTableManifest
    ) -> Bool {
        guard isLandEncounterSuppressed(at: position, encounterTable: encounterTable) == false else {
            return false
        }

        switch encounterTable.landEncounterSurface {
        case .grass:
            return isStandingOnGrass(in: map, position: position)
        case .floor:
            return isStandingOnLandEncounterFloor(in: map, position: position)
        }
    }

    func isLandEncounterSuppressed(
        at position: TilePoint,
        encounterTable: WildEncounterTableManifest
    ) -> Bool {
        encounterTable.suppressionZones.contains { zone in
            zone.positions.contains(position) &&
            zone.conditions.allSatisfy { conditionMatches($0, blockedMoveFacing: nil) }
        }
    }

    func isStandingOnGrass(in map: MapManifest, position: TilePoint) -> Bool {
        guard let grassTileID = content.tileset(id: map.tileset)?.collision.grassTileID,
              let tileID = collisionTileID(at: position, in: map) else {
            return false
        }
        return tileID == grassTileID
    }

    func isStandingOnLandEncounterFloor(in map: MapManifest, position: TilePoint) -> Bool {
        guard let tileset = content.tileset(id: map.tileset),
              let tileID = collisionTileID(at: position, in: map) else {
            return false
        }
        if tileset.collision.doorTileIDs.contains(tileID) || tileset.collision.warpTileIDs.contains(tileID) {
            return false
        }
        return tileset.collision.passableTileIDs.contains(tileID)
    }

    func selectWildEncounter(from slots: [WildEncounterSlotManifest]) -> WildEncounterSlotManifest? {
        guard slots.isEmpty == false else { return nil }

        let roll = nextAcquisitionRandomByte()
        let thresholds = [50, 101, 140, 165, 190, 215, 228, 241, 252, 255]
        let slotIndex = thresholds.firstIndex(where: { roll <= $0 }) ?? (slots.count - 1)
        guard slots.indices.contains(slotIndex) else {
            return slots.last
        }
        return slots[slotIndex]
    }
}
