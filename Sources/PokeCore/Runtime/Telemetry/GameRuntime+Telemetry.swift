import Foundation
import PokeDataModel

extension GameRuntime {
    public func currentSnapshot() -> RuntimeTelemetrySnapshot {
        RuntimeTelemetrySnapshot(
            appVersion: "0.3.0",
            contentVersion: content.gameManifest.contentVersion,
            scene: scene,
            substate: substate,
            titleMenu: scene == .titleMenu ? TitleMenuTelemetry(entries: menuEntries, focusedIndex: focusedIndex) : nil,
            field: makeFieldTelemetry(),
            dialogue: makeDialogueTelemetry(),
            starterChoice: makeStarterChoiceTelemetry(),
            party: makePartyTelemetry(),
            inventory: makeInventoryTelemetry(),
            battle: makeBattleTelemetry(),
            eventFlags: makeFlagTelemetry(),
            audio: makeAudioTelemetry(),
            save: makeSaveTelemetry(),
            recentInputEvents: recentInputEvents,
            assetLoadingFailures: Array(Set(assetLoadingFailures + currentFieldRenderIssues)).sorted(),
            window: .init(scale: windowScale, renderWidth: 160, renderHeight: 144)
        )
    }

    func publishSnapshot() {
        advanceDeferredQueueIfNeeded()
        refreshIdleMovementScheduling()
        guard let telemetryPublisher else { return }
        let snapshot = currentSnapshot()
        Task {
            await telemetryPublisher.publish(snapshot: snapshot)
        }
    }

    func makeFieldTelemetry() -> FieldTelemetry? {
        guard let gameplayState, let map = content.map(id: gameplayState.mapID) else { return nil }
        return FieldTelemetry(
            mapID: map.id,
            mapName: map.displayName,
            playerPosition: gameplayState.playerPosition,
            facing: gameplayState.facing,
            objects: currentFieldObjects.map {
                .init(
                    id: $0.id,
                    position: $0.position,
                    facing: $0.facing,
                    movementMode: $0.movementMode
                )
            },
            activeMapScriptTriggerID: gameplayState.activeMapScriptTriggerID,
            activeScriptID: gameplayState.activeScriptID,
            activeScriptStep: gameplayState.activeScriptStep,
            renderMode: currentFieldRenderMode,
            transition: fieldTransitionState.map {
                .init(kind: $0.kind.rawValue, phase: $0.phase.rawValue)
            }
        )
    }

    func makeDialogueTelemetry() -> DialogueTelemetry? {
        guard let dialogueState, let dialogue = content.dialogue(id: dialogueState.dialogueID) else { return nil }
        let page = dialogue.pages[dialogueState.pageIndex]
        return DialogueTelemetry(dialogueID: dialogue.id, pageIndex: dialogueState.pageIndex, pageCount: dialogue.pages.count, lines: page.lines)
    }

    func makeStarterChoiceTelemetry() -> StarterChoiceTelemetry? {
        guard scene == .starterChoice else { return nil }
        return StarterChoiceTelemetry(options: starterChoiceOptions.map(\.displayName), focusedIndex: starterChoiceFocusedIndex)
    }

    func makePartyTelemetry() -> PartyTelemetry? {
        guard let gameplayState else { return nil }
        return PartyTelemetry(pokemon: gameplayState.playerParty.map { makePartyPokemonTelemetry(from: $0) })
    }

    func makeBattleTelemetry() -> BattleTelemetry? {
        guard let battle = gameplayState?.battle else { return nil }
        return BattleTelemetry(
            battleID: battle.battleID,
            kind: battle.kind,
            trainerName: battle.trainerName,
            playerPokemon: makePartyPokemonTelemetry(from: battle.playerPokemon),
            enemyPokemon: makePartyPokemonTelemetry(from: battle.enemyPokemon),
            enemyPartyCount: battle.enemyParty.count,
            enemyActiveIndex: battle.enemyActiveIndex,
            focusedMoveIndex: battle.focusedMoveIndex,
            canRun: battle.canRun,
            phase: battle.phase.rawValue,
            textLines: battle.message.isEmpty ? [] : [battle.message],
            moveSlots: battle.playerPokemon.moves.compactMap { runtimeMove in
                guard let move = content.move(id: runtimeMove.id) else { return nil }
                return BattleMoveSlotTelemetry(
                    moveID: move.id,
                    displayName: move.displayName,
                    currentPP: runtimeMove.currentPP,
                    maxPP: move.maxPP,
                    isSelectable: runtimeMove.currentPP > 0
                )
            },
            battleMessage: battle.message
        )
    }

    func makeInventoryTelemetry() -> InventoryTelemetry? {
        guard gameplayState != nil else { return nil }
        return InventoryTelemetry(
            items: currentInventoryItems.compactMap { item in
                guard let manifest = content.item(id: item.itemID) else { return nil }
                return InventoryItemTelemetry(
                    itemID: manifest.id,
                    displayName: manifest.displayName,
                    quantity: item.quantity
                )
            }
        )
    }

    func makeFlagTelemetry() -> EventFlagTelemetry? {
        guard let gameplayState else { return nil }
        return EventFlagTelemetry(activeFlags: gameplayState.activeFlags.sorted())
    }

    func makeAudioTelemetry() -> AudioTelemetry? {
        guard let currentAudioState else { return nil }
        return AudioTelemetry(
            trackID: currentAudioState.trackID,
            entryID: currentAudioState.entryID,
            reason: currentAudioState.reason,
            playbackRevision: currentAudioState.playbackRevision
        )
    }

    func makeSaveTelemetry() -> SaveTelemetry? {
        SaveTelemetry(
            metadata: saveMetadata,
            canSave: canSaveGame,
            canLoad: canLoadGame || scene == .titleMenu && saveMetadata != nil,
            lastResult: lastSaveResult,
            errorMessage: saveErrorMessage
        )
    }

    func makePartyPokemonTelemetry(from pokemon: RuntimePokemonState) -> PartyPokemonTelemetry {
        PartyPokemonTelemetry(
            speciesID: pokemon.speciesID,
            displayName: pokemon.nickname,
            level: pokemon.level,
            currentHP: pokemon.currentHP,
            maxHP: pokemon.maxHP,
            attack: pokemon.attack,
            defense: pokemon.defense,
            speed: pokemon.speed,
            special: pokemon.special,
            moves: pokemon.moves.map(\.id),
            experience: .init(
                total: pokemon.experience,
                levelStart: experienceRequired(for: pokemon.level, speciesID: pokemon.speciesID),
                nextLevel: pokemon.level >= 100
                    ? experienceRequired(for: pokemon.level, speciesID: pokemon.speciesID)
                    : experienceRequired(for: pokemon.level + 1, speciesID: pokemon.speciesID)
            ),
            growthOutlook: growthOutlook(for: pokemon)
        )
    }

    func growthOutlook(for pokemon: RuntimePokemonState) -> PokemonGrowthOutlookTelemetry {
        let hpScore = hiddenGrowthScore(dv: pokemon.dvs.hp, statExp: pokemon.statExp.hp)
        let attackScore = hiddenGrowthScore(dv: pokemon.dvs.attack, statExp: pokemon.statExp.attack)
        let defenseScore = hiddenGrowthScore(dv: pokemon.dvs.defense, statExp: pokemon.statExp.defense)
        let speedScore = hiddenGrowthScore(dv: pokemon.dvs.speed, statExp: pokemon.statExp.speed)
        let specialScore = hiddenGrowthScore(dv: pokemon.dvs.special, statExp: pokemon.statExp.special)
        let allScores = [hpScore, attackScore, defenseScore, speedScore, specialScore]

        guard let minimumScore = allScores.min(),
              let maximumScore = allScores.max(),
              minimumScore < maximumScore else {
            return .neutral
        }

        func trend(for score: Int) -> PokemonStatGrowthTelemetry {
            if score == maximumScore {
                return .favored
            }
            if score == minimumScore {
                return .lagging
            }
            return .neutral
        }

        return PokemonGrowthOutlookTelemetry(
            hp: trend(for: hpScore),
            attack: trend(for: attackScore),
            defense: trend(for: defenseScore),
            speed: trend(for: speedScore),
            special: trend(for: specialScore)
        )
    }

    func hiddenGrowthScore(dv: Int, statExp: Int) -> Int {
        (dv * 16) + ceilSquareRoot(of: statExp)
    }
}
