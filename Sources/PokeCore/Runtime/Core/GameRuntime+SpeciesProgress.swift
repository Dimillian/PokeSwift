extension GameRuntime {
    func recordOwnedSpecies(
        _ speciesID: String,
        in gameplayState: inout GameplayState,
        countEncounter: Bool = false
    ) {
        gameplayState.ownedSpeciesIDs.insert(speciesID)
        if countEncounter {
            recordSpeciesEncounter(speciesID, in: &gameplayState)
        } else {
            gameplayState.seenSpeciesIDs.insert(speciesID)
        }
    }

    func recordSpeciesEncounter(_ speciesID: String, in gameplayState: inout GameplayState) {
        gameplayState.seenSpeciesIDs.insert(speciesID)
        gameplayState.speciesEncounterCounts[speciesID, default: 0] += 1
    }

    func normalizedSpeciesEncounterCounts(_ encounterCounts: [String: Int]) -> [String: Int] {
        encounterCounts.reduce(into: [:]) { result, entry in
            guard entry.value > 0 else { return }
            result[entry.key] = entry.value
        }
    }
}
