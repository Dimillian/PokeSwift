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
            recordSaveResult(operation: "save", succeeded: false, message: "Saving is only available while exploring the field.")
            publishSnapshot()
            return false
        }

        guard let saveStore else {
            recordSaveResult(operation: "save", succeeded: false, message: GameSaveRuntimeError.storeUnavailable.localizedDescription)
            publishSnapshot()
            return false
        }

        do {
            let envelope = try makeSaveEnvelope()
            try saveStore.save(envelope)
            saveMetadata = envelope.metadata
            saveErrorMessage = nil
            recordSaveResult(operation: "save", succeeded: true, message: "Saved at \(envelope.metadata.locationName).")
            publishSnapshot()
            return true
        } catch {
            saveErrorMessage = error.localizedDescription
            recordSaveResult(operation: "save", succeeded: false, message: error.localizedDescription)
            publishSnapshot()
            return false
        }
    }

    @discardableResult
    public func loadSavedGameFromSidebar() -> Bool {
        loadSavedGame(operation: "load", requireSettledFieldState: true)
    }

    @discardableResult
    func continueFromTitleMenu() -> Bool {
        loadSavedGame(operation: "continue", requireSettledFieldState: false)
    }

    func loadSavedGame(operation: String, requireSettledFieldState: Bool) -> Bool {
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
            let successMessage = operation == "continue"
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
            playerPosition: gameplayState.playerPosition,
            facing: gameplayState.facing,
            objectStates: gameplayState.objectStates.mapValues {
                GameSaveObjectState(position: $0.position, facing: $0.facing, visible: $0.visible)
            },
            activeFlags: gameplayState.activeFlags.sorted(),
            money: gameplayState.money,
            inventory: gameplayState.inventory.map { .init(itemID: $0.itemID, quantity: $0.quantity) },
            earnedBadgeIDs: gameplayState.earnedBadgeIDs.sorted(),
            playerName: gameplayState.playerName,
            rivalName: gameplayState.rivalName,
            playerParty: gameplayState.playerParty.map { pokemon in
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
                    accuracyStage: pokemon.accuracyStage,
                    evasionStage: pokemon.evasionStage,
                    moves: pokemon.moves.map { GameSaveMove(id: $0.id, currentPP: $0.currentPP) }
                )
            },
            chosenStarterSpeciesID: gameplayState.chosenStarterSpeciesID,
            rivalStarterSpeciesID: gameplayState.rivalStarterSpeciesID,
            pendingStarterSpeciesID: gameplayState.pendingStarterSpeciesID,
            activeMapScriptTriggerID: nil,
            activeScriptID: gameplayState.activeScriptID,
            activeScriptStep: gameplayState.activeScriptStep,
            acquisitionRNGState: acquisitionRNGState,
            encounterStepCounter: gameplayState.encounterStepCounter,
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

        playthroughID = envelope.metadata.playthroughID
        gameplayState = GameplayState(
            mapID: envelope.snapshot.mapID,
            playerPosition: envelope.snapshot.playerPosition,
            facing: envelope.snapshot.facing,
            objectStates: envelope.snapshot.objectStates.mapValues {
                RuntimeObjectState(
                    position: $0.position,
                    facing: $0.facing,
                    visible: $0.visible,
                    movementMode: nil,
                    idleStepIndex: 0
                )
            },
            activeFlags: Set(envelope.snapshot.activeFlags),
            money: envelope.snapshot.money,
            inventory: envelope.snapshot.inventory.map { .init(itemID: $0.itemID, quantity: $0.quantity) },
            earnedBadgeIDs: Set(envelope.snapshot.earnedBadgeIDs),
            gotStarterBit: envelope.snapshot.chosenStarterSpeciesID != nil,
            playerName: envelope.snapshot.playerName,
            rivalName: envelope.snapshot.rivalName,
            playerParty: envelope.snapshot.playerParty.map { pokemon in
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
                    accuracyStage: pokemon.accuracyStage,
                    evasionStage: pokemon.evasionStage,
                    moves: pokemon.moves.map { RuntimeMoveState(id: $0.id, currentPP: $0.currentPP) }
                )
            },
            chosenStarterSpeciesID: envelope.snapshot.chosenStarterSpeciesID,
            rivalStarterSpeciesID: envelope.snapshot.rivalStarterSpeciesID,
            pendingStarterSpeciesID: envelope.snapshot.pendingStarterSpeciesID,
            activeMapScriptTriggerID: nil,
            activeScriptID: envelope.snapshot.activeScriptID,
            activeScriptStep: envelope.snapshot.activeScriptStep,
            battle: nil,
            encounterStepCounter: envelope.snapshot.encounterStepCounter,
            playTimeSeconds: envelope.snapshot.playTimeSeconds
        )
        if envelope.snapshot.acquisitionRNGState == 0 {
            reseedAcquisitionRNG(for: playthroughID)
        } else {
            acquisitionRNGState = envelope.snapshot.acquisitionRNGState
        }
        dialogueState = nil
        deferredActions.removeAll()
        currentAudioState = nil
        fieldTransitionState = nil
        starterChoiceFocusedIndex = 0
        placeholderTitle = nil
        scene = .field
        substate = "field"
        restartGameplayClock()
        requestDefaultMapMusic()
    }

    func recordSaveResult(operation: String, succeeded: Bool, message: String?) {
        lastSaveResult = RuntimeSaveResult(
            operation: operation,
            succeeded: succeeded,
            message: message,
            timestamp: Self.timestampFormatter.string(from: Date())
        )
        traceEvent(
            .saveResult,
            message ?? "\(operation.capitalized) \(succeeded ? "succeeded" : "failed").",
            mapID: gameplayState?.mapID,
            details: [
                "operation": operation,
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

    static let timestampFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}
