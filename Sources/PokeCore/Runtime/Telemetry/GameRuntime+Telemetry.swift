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
            fieldPrompt: makeFieldPromptTelemetry(),
            fieldHealing: makeFieldHealingTelemetry(),
            starterChoice: makeStarterChoiceTelemetry(),
            party: makePartyTelemetry(),
            inventory: makeInventoryTelemetry(),
            battle: makeBattleTelemetry(),
            shop: makeShopTelemetry(),
            eventFlags: makeFlagTelemetry(),
            audio: makeAudioTelemetry(),
            soundEffects: makeSoundEffectTelemetry(),
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
            alert: makeFieldAlertTelemetry(),
            transition: makeFieldTransitionTelemetry()
        )
    }

    func makeDialogueTelemetry() -> DialogueTelemetry? {
        guard let dialogueState, let dialogue = content.dialogue(id: dialogueState.dialogueID) else { return nil }
        let page = dialogue.pages[dialogueState.pageIndex]
        return DialogueTelemetry(dialogueID: dialogue.id, pageIndex: dialogueState.pageIndex, pageCount: dialogue.pages.count, lines: page.lines)
    }

    func makeFieldPromptTelemetry() -> FieldPromptTelemetry? {
        guard let fieldPromptState else { return nil }
        return FieldPromptTelemetry(
            interactionID: fieldPromptState.interactionID,
            kind: fieldPromptState.kind.rawValue,
            options: fieldPromptOptions(for: fieldPromptState.kind),
            focusedIndex: fieldPromptState.focusedIndex
        )
    }

    func makeFieldHealingTelemetry() -> FieldHealingTelemetry? {
        guard let fieldHealingState else { return nil }
        return FieldHealingTelemetry(
            interactionID: fieldHealingState.interactionID,
            phase: fieldHealingState.phase.rawValue,
            activeBallCount: fieldHealingState.activeBallCount,
            totalBallCount: fieldHealingState.totalBallCount,
            pulseStep: fieldHealingState.pulseStep,
            nurseObjectID: fieldHealingState.nurseObjectID
        )
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
        guard let gameplayState, let battle = gameplayState.battle else { return nil }
        return BattleTelemetry(
            battleID: battle.battleID,
            kind: battle.kind,
            trainerName: battle.trainerName,
            trainerSpritePath: battle.trainerSpritePath,
            playerPokemon: makePartyPokemonTelemetry(from: battle.playerPokemon),
            enemyPokemon: makePartyPokemonTelemetry(from: battle.enemyPokemon),
            enemyPartyCount: battle.enemyParty.count,
            enemyActiveIndex: battle.enemyActiveIndex,
            focusedMoveIndex: battle.focusedMoveIndex,
            focusedBagItemIndex: battle.focusedBagItemIndex,
            focusedPartyIndex: battle.focusedPartyIndex,
            canRun: battle.canRun,
            canUseBag: battle.kind == .wild && currentBattleBagItems.isEmpty == false,
            canSwitch: canUseBattleSwitch(for: battle, gameplayState: gameplayState),
            phase: battle.phase.rawValue,
            textLines: battle.message.isEmpty ? [] : [battle.message],
            learnMovePrompt: makeBattleLearnMovePromptTelemetry(from: battle),
            moveSlots: battle.playerPokemon.moves.compactMap { makeBattleMoveSlotTelemetry(from: $0) },
            bagItems: currentBattleBagItems.compactMap(makeInventoryItemTelemetry(from:)),
            battleMessage: battle.message,
            capture: makeBattleCaptureTelemetry(from: battle.lastCaptureResult),
            presentation: .init(
                stage: battle.presentation.stage,
                revision: battle.presentation.revision,
                uiVisibility: battle.presentation.uiVisibility,
                activeSide: battle.presentation.activeSide,
                hidePlayerPokemon: battle.presentation.hidePlayerPokemon,
                transitionStyle: battle.presentation.transitionStyle,
                meterAnimation: battle.presentation.meterAnimation
            )
        )
    }

    func makeBattleLearnMovePromptTelemetry(from battle: RuntimeBattleState) -> BattleLearnMovePromptTelemetry? {
        guard let learnMoveState = battle.learnMoveState,
              let move = content.move(id: learnMoveState.moveID) else {
            return nil
        }

        let stage: BattleLearnMovePromptTelemetry.Stage
        switch battle.phase {
        case .learnMoveDecision:
            stage = .confirm
        case .learnMoveSelection:
            stage = .replace
        default:
            return nil
        }

        return BattleLearnMovePromptTelemetry(
            pokemonName: battle.playerPokemon.nickname,
            moveID: move.id,
            moveDisplayName: move.displayName,
            stage: stage
        )
    }

    func makeInventoryTelemetry() -> InventoryTelemetry? {
        guard gameplayState != nil else { return nil }
        return InventoryTelemetry(
            items: currentInventoryItems.compactMap(makeInventoryItemTelemetry(from:))
        )
    }

    func makeShopTelemetry() -> ShopTelemetry? {
        guard let shopState,
              let mart = content.mart(id: shopState.martID) else {
            return nil
        }

        let buyItems = mart.stockItemIDs.compactMap { itemID -> ShopRowTelemetry? in
            guard let item = content.item(id: itemID) else { return nil }
            return makeShopRowTelemetry(
                item: item,
                ownedQuantity: itemQuantity(item.id),
                transactionPrice: item.price,
                isSelectable: maxPurchasableQuantity(for: item) > 0
            )
        }

        let sellItems = currentInventoryItems.compactMap { itemState -> ShopRowTelemetry? in
            guard let item = content.item(id: itemState.itemID) else { return nil }
            return makeShopRowTelemetry(
                item: item,
                ownedQuantity: itemState.quantity,
                transactionPrice: sellPrice(for: item),
                isSelectable: canSell(item: item)
            )
        }

        return ShopTelemetry(
            martID: mart.id,
            title: currentMapManifest?.displayName ?? "Poke Mart",
            phase: shopState.phase.rawValue,
            promptText: shopState.message,
            focusedMainMenuIndex: shopState.focusedMainMenuIndex,
            focusedItemIndex: shopState.focusedItemIndex,
            focusedConfirmationIndex: shopState.focusedConfirmationIndex,
            selectedQuantity: shopState.selectedQuantity,
            selectedTransactionKind: shopState.transaction?.kind.rawValue,
            menuOptions: ["BUY", "SELL", "QUIT"],
            buyItems: buyItems,
            sellItems: sellItems
        )
    }

    func makeBattleMoveSlotTelemetry(from runtimeMove: RuntimeMoveState) -> BattleMoveSlotTelemetry? {
        guard let move = content.move(id: runtimeMove.id) else { return nil }
        return BattleMoveSlotTelemetry(
            moveID: move.id,
            displayName: move.displayName,
            currentPP: runtimeMove.currentPP,
            maxPP: move.maxPP,
            isSelectable: runtimeMove.currentPP > 0
        )
    }

    func makeBattleCaptureTelemetry(from result: RuntimeBattleCaptureResult?) -> BattleCaptureTelemetry? {
        guard let result else { return nil }

        switch result {
        case .uncatchable:
            return BattleCaptureTelemetry(result: "uncatchable", shakes: 0)
        case .boxFull:
            return BattleCaptureTelemetry(result: "boxFull", shakes: 0)
        case let .failed(shakes):
            return BattleCaptureTelemetry(result: "failure", shakes: shakes)
        case .success:
            return BattleCaptureTelemetry(result: "success", shakes: 4)
        }
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

    func makeSoundEffectTelemetry() -> [SoundEffectTelemetry] {
        recentSoundEffects.map {
            .init(
                soundEffectID: $0.soundEffectID,
                reason: $0.reason,
                playbackRevision: $0.playbackRevision,
                status: $0.status,
                replacedSoundEffectID: $0.replacedSoundEffectID
            )
        }
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
            majorStatus: pokemon.majorStatus,
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

    func makeInventoryItemTelemetry(from item: RuntimeInventoryItemState) -> InventoryItemTelemetry? {
        guard let manifest = content.item(id: item.itemID) else { return nil }
        return InventoryItemTelemetry(
            itemID: manifest.id,
            displayName: manifest.displayName,
            quantity: item.quantity,
            price: manifest.price,
            battleUse: manifest.battleUse
        )
    }

    func makeShopRowTelemetry(
        item: ItemManifest,
        ownedQuantity: Int,
        transactionPrice: Int,
        isSelectable: Bool
    ) -> ShopRowTelemetry {
        ShopRowTelemetry(
            itemID: item.id,
            displayName: item.displayName,
            ownedQuantity: ownedQuantity,
            unitPrice: item.price,
            transactionPrice: transactionPrice,
            isSelectable: isSelectable
        )
    }

    func growthOutlook(for pokemon: RuntimePokemonState) -> PokemonGrowthOutlookTelemetry {
        let hpScore = hiddenPotentialScore(dv: pokemon.dvs.hp)
        let attackScore = hiddenPotentialScore(dv: pokemon.dvs.attack)
        let defenseScore = hiddenPotentialScore(dv: pokemon.dvs.defense)
        let speedScore = hiddenPotentialScore(dv: pokemon.dvs.speed)
        let specialScore = hiddenPotentialScore(dv: pokemon.dvs.special)
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

    func hiddenPotentialScore(dv: Int) -> Int {
        dv
    }
}
