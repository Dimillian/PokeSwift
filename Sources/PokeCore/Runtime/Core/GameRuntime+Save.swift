import Foundation
import PokeDataModel

enum GameSaveRuntimeError: LocalizedError {
    case missingState
    case storeUnavailable
    case fileMissing
    case unsupportedSchema(Int)
    case unknownMap(String)

    var errorDescription: String? {
        switch self {
        case .missingState:
            return "No gameplay state is available to save."
        case .storeUnavailable:
            return "Save storage is unavailable."
        case .fileMissing:
            return "No save file is available."
        case let .unsupportedSchema(version):
            return "Save schema \(version) is not supported."
        case let .unknownMap(mapID):
            return "Saved map \(mapID) is not present in the loaded content."
        }
    }
}

extension GameRuntime {
    public func saveCurrentGame() -> Bool {
        guard canSaveGame else {
            recordSaveResult(operation: .save, succeeded: false, message: "Saving is only available while exploring the field.")
            publishSnapshot()
            return false
        }

        guard let saveStore else {
            recordSaveResult(operation: .save, succeeded: false, message: GameSaveRuntimeError.storeUnavailable.localizedDescription)
            publishSnapshot()
            return false
        }

        do {
            let envelope = try makeSaveEnvelope()
            try saveStore.save(envelope)
            saveMetadata = envelope.metadata
            saveErrorMessage = nil
            recordSaveResult(operation: .save, succeeded: true, message: "Saved at \(envelope.metadata.locationName).")
            publishSnapshot()
            return true
        } catch {
            saveErrorMessage = error.localizedDescription
            recordSaveResult(operation: .save, succeeded: false, message: error.localizedDescription)
            publishSnapshot()
            return false
        }
    }

    @discardableResult
    public func loadSavedGameFromSidebar() -> Bool {
        loadSavedGame(operation: .load, requireSettledFieldState: true)
    }

    @discardableResult
    func continueFromTitleMenu() -> Bool {
        loadSavedGame(operation: .continue, requireSettledFieldState: false)
    }

    func loadSavedGame(operation: RuntimeSaveOperation, requireSettledFieldState: Bool) -> Bool {
        if requireSettledFieldState && canLoadGame == false {
            recordSaveResult(operation: operation, succeeded: false, message: "Loading is only available from settled field gameplay.")
            publishSnapshot()
            return false
        }

        guard let saveStore else {
            recordSaveResult(operation: operation, succeeded: false, message: GameSaveRuntimeError.storeUnavailable.localizedDescription)
            publishSnapshot()
            return false
        }

        do {
            guard let envelope = try saveStore.loadSave() else {
                throw GameSaveRuntimeError.fileMissing
            }
            try applySaveEnvelope(envelope)
            saveMetadata = envelope.metadata
            saveErrorMessage = nil
            let successMessage = operation == .continue
                ? "Continue loaded from \(envelope.metadata.locationName)."
                : "Loaded save from \(envelope.metadata.locationName)."
            recordSaveResult(operation: operation, succeeded: true, message: successMessage)
            publishSnapshot()
            return true
        } catch {
            saveMetadata = nil
            saveErrorMessage = error.localizedDescription
            recordSaveResult(operation: operation, succeeded: false, message: error.localizedDescription)
            publishSnapshot()
            return false
        }
    }

    func makeSaveEnvelope() throws -> GameSaveEnvelope {
        guard var gameplayState else {
            throw GameSaveRuntimeError.missingState
        }

        gameplayState.playTimeSeconds = currentPlayTimeSeconds()
        self.gameplayState = gameplayState
        restartGameplayClock()

        let metadata = GameSaveMetadata(
            schemaVersion: Self.saveSchemaVersion,
            variant: content.gameManifest.variant,
            playthroughID: playthroughID,
            playerName: gameplayState.playerName,
            locationName: currentMapManifest?.displayName ?? gameplayState.mapID,
            badgeCount: gameplayState.earnedBadgeIDs.count,
            playTimeSeconds: gameplayState.playTimeSeconds,
            savedAt: Self.timestampFormatter.string(from: Date())
        )

        let snapshot = GameSaveSnapshot(
            mapID: gameplayState.mapID,
            previousMapID: gameplayState.previousMapID,
            playerPosition: gameplayState.playerPosition,
            facing: gameplayState.facing,
            blackoutCheckpoint: gameplayState.blackoutCheckpoint,
            objectStates: gameplayState.objectStates.mapValues { makeSaveObjectState(from: $0) },
            activeFlags: gameplayState.activeFlags.sorted(),
            money: gameplayState.money,
            inventory: gameplayState.inventory.map { .init(itemID: $0.itemID, quantity: $0.quantity) },
            currentBoxIndex: gameplayState.currentBoxIndex,
            boxedPokemon: gameplayState.boxedPokemon.map { box in
                GameSavePokemonBox(
                    index: box.index,
                    pokemon: box.pokemon.map { makeSavePokemon(from: $0) }
                )
            },
            ownedSpeciesIDs: gameplayState.ownedSpeciesIDs.sorted(),
            seenSpeciesIDs: gameplayState.seenSpeciesIDs.sorted(),
            speciesEncounterCounts: normalizedSpeciesEncounterCounts(gameplayState.speciesEncounterCounts),
            earnedBadgeIDs: Self.normalizedBadgeIDs(gameplayState.earnedBadgeIDs).sorted(),
            playerName: gameplayState.playerName,
            rivalName: gameplayState.rivalName,
            playerParty: gameplayState.playerParty.map { makeSavePokemon(from: $0) },
            chosenStarterSpeciesID: gameplayState.chosenStarterSpeciesID,
            rivalStarterSpeciesID: gameplayState.rivalStarterSpeciesID,
            pendingStarterSpeciesID: gameplayState.pendingStarterSpeciesID,
            activeMapScriptTriggerID: nil,
            activeScriptID: gameplayState.activeScriptID,
            activeScriptStep: gameplayState.activeScriptStep,
            encounterStepCounter: gameplayState.encounterStepCounter,
            totalStepCount: gameplayState.totalStepCount,
            wildEncounterCount: gameplayState.wildEncounterCount,
            trainerBattleCount: gameplayState.trainerBattleCount,
            playTimeSeconds: gameplayState.playTimeSeconds
        )

        return GameSaveEnvelope(metadata: metadata, snapshot: snapshot)
    }

    func applySaveEnvelope(_ envelope: GameSaveEnvelope) throws {
        guard (3...Self.saveSchemaVersion).contains(envelope.metadata.schemaVersion) else {
            throw GameSaveRuntimeError.unsupportedSchema(envelope.metadata.schemaVersion)
        }
        guard content.map(id: envelope.snapshot.mapID) != nil else {
            throw GameSaveRuntimeError.unknownMap(envelope.snapshot.mapID)
        }

        transitionTask?.cancel()
        fieldTransitionTask?.cancel()
        fieldMovementTask?.cancel()
        scriptedMovementTask?.cancel()
        idleMovementTask?.cancel()
        trainerEngagementTask?.cancel()
        fieldInteractionTask?.cancel()

        playthroughID = envelope.metadata.playthroughID
        var mergedObjectStates = makeInitialGameplayState().objectStates
        for (objectID, savedObjectState) in envelope.snapshot.objectStates {
            mergedObjectStates[objectID] = makeRuntimeObjectState(from: savedObjectState)
        }
        gameplayState = GameplayState(
            mapID: envelope.snapshot.mapID,
            previousMapID: envelope.snapshot.previousMapID,
            playerPosition: envelope.snapshot.playerPosition,
            facing: envelope.snapshot.facing,
            blackoutCheckpoint: envelope.snapshot.blackoutCheckpoint ?? content.gameplayManifest.playerStart.defaultBlackoutCheckpoint,
            objectStates: mergedObjectStates,
            activeFlags: Set(envelope.snapshot.activeFlags),
            money: envelope.snapshot.money,
            inventory: envelope.snapshot.inventory.map { .init(itemID: $0.itemID, quantity: $0.quantity) },
            currentBoxIndex: envelope.snapshot.currentBoxIndex,
            boxedPokemon: normalizedBoxes(from: envelope.snapshot.boxedPokemon),
            ownedSpeciesIDs: Set(envelope.snapshot.ownedSpeciesIDs),
            seenSpeciesIDs: Set(envelope.snapshot.seenSpeciesIDs),
            speciesEncounterCounts: normalizedSpeciesEncounterCounts(envelope.snapshot.speciesEncounterCounts),
            earnedBadgeIDs: Self.normalizedBadgeIDs(envelope.snapshot.earnedBadgeIDs),
            gotStarterBit: envelope.snapshot.chosenStarterSpeciesID != nil,
            playerName: envelope.snapshot.playerName,
            rivalName: envelope.snapshot.rivalName,
            playerParty: envelope.snapshot.playerParty.map { makeRuntimePokemon(from: $0) },
            chosenStarterSpeciesID: envelope.snapshot.chosenStarterSpeciesID,
            rivalStarterSpeciesID: envelope.snapshot.rivalStarterSpeciesID,
            pendingStarterSpeciesID: envelope.snapshot.pendingStarterSpeciesID,
            activeMapScriptTriggerID: nil,
            // Field saves should resume in a settled exploration state. If an
            // earlier bug serialized stale script progress, drop it on load.
            activeScriptID: nil,
            activeScriptStep: nil,
            battle: nil,
            encounterStepCounter: envelope.snapshot.encounterStepCounter,
            totalStepCount: envelope.snapshot.totalStepCount,
            wildEncounterCount: envelope.snapshot.wildEncounterCount,
            trainerBattleCount: envelope.snapshot.trainerBattleCount,
            playTimeSeconds: envelope.snapshot.playTimeSeconds
        )
        reseedRuntimeRNG()
        clearFieldObstacleOverrides()
        clearHeldFieldDirections()
        clearTransientInteractionState()
        fieldHealingState = nil
        shopState = nil
        fieldPartyReorderState = nil
        fieldItemUseState = nil
        fieldLearnMoveState = nil
        deferredActions.removeAll()
        currentAudioState = nil
        fieldTransitionState = nil
        fieldAlertState = nil
        starterChoiceFocusedIndex = 0
        placeholderTitle = nil
        restartGameplayClock()
        enterSettledFieldState(restoreMapMusic: true)
    }

    func makeSaveObjectState(from objectState: RuntimeObjectState) -> GameSaveObjectState {
        GameSaveObjectState(
            position: objectState.position,
            facing: objectState.facing,
            visible: objectState.visible
        )
    }

    func makeSavePokemon(from pokemon: RuntimePokemonState) -> GameSavePokemon {
        GameSavePokemon(
            speciesID: pokemon.speciesID,
            nickname: pokemon.nickname,
            level: pokemon.level,
            experience: pokemon.experience,
            dvs: pokemon.dvs,
            statExp: pokemon.statExp,
            maxHP: pokemon.maxHP,
            currentHP: pokemon.currentHP,
            attack: pokemon.attack,
            defense: pokemon.defense,
            speed: pokemon.speed,
            special: pokemon.special,
            attackStage: pokemon.attackStage,
            defenseStage: pokemon.defenseStage,
            speedStage: pokemon.speedStage,
            specialStage: pokemon.specialStage,
            accuracyStage: pokemon.accuracyStage,
            evasionStage: pokemon.evasionStage,
            majorStatus: pokemon.majorStatus,
            statusCounter: pokemon.statusCounter,
            moves: pokemon.moves.map { GameSaveMove(id: $0.id, currentPP: $0.currentPP) }
        )
    }

    func makeRuntimeObjectState(from objectState: GameSaveObjectState) -> RuntimeObjectState {
        RuntimeObjectState(
            position: objectState.position,
            facing: objectState.facing,
            visible: objectState.visible,
            movementMode: nil,
            idleStepIndex: 0
        )
    }

    func makeRuntimePokemon(from pokemon: GameSavePokemon) -> RuntimePokemonState {
        RuntimePokemonState(
            speciesID: pokemon.speciesID,
            nickname: pokemon.nickname,
            level: pokemon.level,
            experience: pokemon.experience,
            dvs: pokemon.dvs,
            statExp: pokemon.statExp,
            maxHP: pokemon.maxHP,
            currentHP: pokemon.currentHP,
            attack: pokemon.attack,
            defense: pokemon.defense,
            speed: pokemon.speed,
            special: pokemon.special,
            attackStage: pokemon.attackStage,
            defenseStage: pokemon.defenseStage,
            speedStage: pokemon.speedStage,
            specialStage: pokemon.specialStage,
            accuracyStage: pokemon.accuracyStage,
            evasionStage: pokemon.evasionStage,
            majorStatus: pokemon.majorStatus,
            statusCounter: pokemon.statusCounter,
            moves: pokemon.moves.map { RuntimeMoveState(id: $0.id, currentPP: $0.currentPP) }
        )
    }

    func recordSaveResult(operation: RuntimeSaveOperation, succeeded: Bool, message: String?) {
        lastSaveResult = RuntimeSaveResult(
            operation: operation,
            succeeded: succeeded,
            message: message,
            timestamp: Self.timestampFormatter.string(from: Date())
        )
        traceEvent(
            .saveResult,
            message ?? "\(operation.rawValue.capitalized) \(succeeded ? "succeeded" : "failed").",
            mapID: gameplayState?.mapID,
            details: [
                "operation": operation.rawValue,
                "succeeded": succeeded ? "true" : "false",
            ]
        )
    }

    func currentPlayTimeSeconds() -> Int {
        guard let gameplayState else { return 0 }
        guard let gameplaySessionStartedAt else { return gameplayState.playTimeSeconds }
        return max(gameplayState.playTimeSeconds, gameplayState.playTimeSeconds + Int(Date().timeIntervalSince(gameplaySessionStartedAt)))
    }

    func restartGameplayClock() {
        gameplaySessionStartedAt = gameplayState == nil ? nil : Date()
    }

    func normalizedBoxes(from savedBoxes: [GameSavePokemonBox]) -> [RuntimePokemonBoxState] {
        let savedByIndex = Dictionary(uniqueKeysWithValues: savedBoxes.map { ($0.index, $0) })
        return (0..<Self.storageBoxCount).map { index in
            let saved = savedByIndex[index]
            return RuntimePokemonBoxState(
                index: index,
                pokemon: saved?.pokemon.map { makeRuntimePokemon(from: $0) } ?? []
            )
        }
    }

    static let timestampFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}
