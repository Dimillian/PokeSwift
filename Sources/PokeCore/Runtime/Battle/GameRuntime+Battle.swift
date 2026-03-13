import PokeDataModel

extension GameRuntime {
    func finalizeStarterChoiceSequence(nickname: String? = nil) {
        guard var gameplayState, let speciesID = gameplayState.pendingStarterSpeciesID else { return }

        gameplayState.gotStarterBit = true
        gameplayState.chosenStarterSpeciesID = speciesID
        let resolvedNickname = nickname ?? content.species(id: speciesID)?.displayName ?? speciesID.capitalized
        gameplayState.playerParty = [makePokemon(speciesID: speciesID, level: 5, nickname: resolvedNickname)]
        gameplayState.activeFlags.insert("EVENT_GOT_STARTER")
        let rivalSpeciesID = rivalStarter(for: speciesID)
        gameplayState.rivalStarterSpeciesID = rivalSpeciesID
        let ballObjectID = selectedBallObjectID(for: speciesID)
        ensureObjectStateExists(ballObjectID, in: &gameplayState)
        gameplayState.objectStates[ballObjectID]?.visible = false
        self.gameplayState = gameplayState

        showDialogue(id: "oaks_lab_received_mon_\(speciesID.lowercased())", completion: .returnToField)
        queueDeferredActions([.script(rivalPickupScriptID(for: speciesID))])
    }

    func finishBattle(battle: RuntimeBattleState, won: Bool) {
        cancelBattlePresentation()
        if battle.kind == .wild {
            finishWildBattle(battle: battle, won: won)
            return
        }

        guard var gameplayState else { return }
        if won, battle.completionFlagID.isEmpty == false {
            gameplayState.activeFlags.insert(battle.completionFlagID)
        }
        gameplayState.playerParty = finalizedPlayerPartyAfterBattle(from: battle, gameplayState: gameplayState)
        gameplayState.battle = nil
        self.gameplayState = gameplayState
        if battle.healsPartyAfterBattle {
            healParty()
        }
        traceEvent(
            .battleEnded,
            "Finished trainer battle \(battle.battleID).",
            mapID: gameplayState.mapID,
            battleID: battle.battleID,
            battleKind: battle.kind,
            details: [
                "outcome": won ? "won" : "lost",
                "opponent": battle.trainerName,
            ]
        )
        if won == false {
            stopAllMusic()
        }
        let followUpDialogueID = won ? battle.playerWinDialogueID : battle.playerLoseDialogueID
        if let followUpDialogueID {
            showDialogue(
                id: followUpDialogueID,
                completion: .finishTrainerBattle(
                    won: won,
                    preventsBlackoutOnLoss: battle.preventsBlackoutOnLoss,
                    postBattleScriptID: battle.postBattleScriptID,
                    sourceTrainerObjectID: battle.sourceTrainerObjectID
                )
            )
        } else {
            completeTrainerBattleDialogue(
                won: won,
                preventsBlackoutOnLoss: battle.preventsBlackoutOnLoss,
                postBattleScriptID: battle.postBattleScriptID,
                sourceTrainerObjectID: battle.sourceTrainerObjectID
            )
        }
    }

    func completeTrainerBattleDialogue(
        won: Bool,
        preventsBlackoutOnLoss: Bool,
        postBattleScriptID: String?,
        sourceTrainerObjectID: String?
    ) {
        if let postBattleScriptID {
            beginScript(id: postBattleScriptID)
            return
        }

        if won == false, preventsBlackoutOnLoss == false {
            performBlackout(sourceTrainerObjectID: sourceTrainerObjectID)
            return
        }

        scene = .field
        substate = "field"
        requestDefaultMapMusic()
    }

    func finishWildBattleEscape() {
        cancelBattlePresentation()
        guard var gameplayState else { return }
        let battle = gameplayState.battle
        if let battle = gameplayState.battle {
            gameplayState.playerParty = finalizedPlayerPartyAfterBattle(from: battle, gameplayState: gameplayState)
        }
        gameplayState.battle = nil
        self.gameplayState = gameplayState
        scene = .field
        substate = "field"
        if let battle {
            traceEvent(
                .battleEnded,
                "Escaped wild battle \(battle.battleID).",
                mapID: gameplayState.mapID,
                battleID: battle.battleID,
                battleKind: battle.kind,
                details: [
                    "outcome": "escaped",
                    "opponent": battle.trainerName,
                ]
            )
        }
        requestDefaultMapMusic()
    }

    func finishWildBattle(battle: RuntimeBattleState, won: Bool) {
        cancelBattlePresentation()
        guard var gameplayState else { return }
        gameplayState.playerParty = finalizedPlayerPartyAfterBattle(from: battle, gameplayState: gameplayState)
        gameplayState.battle = nil
        self.gameplayState = gameplayState
        if won == false {
            traceEvent(
                .battleEnded,
                "Finished wild battle \(battle.battleID).",
                mapID: gameplayState.mapID,
                battleID: battle.battleID,
                battleKind: battle.kind,
                details: [
                    "outcome": "lost",
                    "opponent": battle.trainerName,
                ]
            )
            performBlackout(sourceTrainerObjectID: nil)
            return
        }
        scene = .field
        substate = "field"
        traceEvent(
            .battleEnded,
            "Finished wild battle \(battle.battleID).",
            mapID: gameplayState.mapID,
            battleID: battle.battleID,
            battleKind: battle.kind,
            details: [
                "outcome": won ? "won" : "lost",
                "opponent": battle.trainerName,
            ]
        )
        requestDefaultMapMusic()
    }

    func shouldBlackoutOnLoss(for battle: RuntimeBattleState) -> Bool {
        wonBattleWouldPreventBlackout(battle) == false
    }

    private func wonBattleWouldPreventBlackout(_ battle: RuntimeBattleState) -> Bool {
        battle.kind == .trainer && battle.preventsBlackoutOnLoss
    }

    func beginBlackoutSequence(battle: inout RuntimeBattleState) {
        traceEvent(
            .battleEnded,
            "Finished \(battle.kind == .trainer ? "trainer" : "wild") battle \(battle.battleID).",
            mapID: gameplayState?.mapID,
            battleID: battle.battleID,
            battleKind: battle.kind,
            details: [
                "outcome": "lost",
                "opponent": battle.trainerName,
            ]
        )
        if battle.kind == .trainer {
            stopAllMusic()
        }
        let messages = blackoutFollowUpMessages(for: battle)
        guard messages.isEmpty == false else {
            performBlackout(sourceTrainerObjectID: battle.sourceTrainerObjectID)
            return
        }

        presentBattleMessages(
            messages,
            battle: &battle,
            pendingAction: .performBlackout(sourceTrainerObjectID: battle.sourceTrainerObjectID)
        )
    }

    func blackoutFollowUpMessages(for battle: RuntimeBattleState) -> [String] {
        [playerBlackedOutText()]
    }

    func finishWildBattleCapture(battle: RuntimeBattleState) {
        cancelBattlePresentation()
        guard var gameplayState else { return }
        gameplayState.playerParty = finalizedPlayerPartyAfterBattle(from: battle, gameplayState: gameplayState)
        gameplayState.battle = nil
        self.gameplayState = gameplayState
        scene = .field
        substate = "field"
        traceEvent(
            .battleEnded,
            "Captured \(battle.enemyPokemon.speciesID) in \(battle.battleID).",
            mapID: gameplayState.mapID,
            battleID: battle.battleID,
            battleKind: battle.kind,
            details: [
                "outcome": "captured",
                "speciesID": battle.enemyPokemon.speciesID,
            ]
        )
        requestDefaultMapMusic()
    }

    func startBattle(
        id: String,
        sourceTrainerObjectID: String? = nil,
        introDialogueID _: String? = nil
    ) {
        guard var gameplayState,
              let chosenStarter = gameplayState.chosenStarterSpeciesID else {
            return
        }

        guard let battleManifest = content.trainerBattle(id: id) else {
            return
        }

        let playerPokemon = clearBattleStatStages(
            gameplayState.playerParty.first ?? makePokemon(speciesID: chosenStarter, level: 5, nickname: chosenStarter.capitalized)
        )
        let enemyParty = battleManifest.party.map {
            makeTrainerBattlePokemon(speciesID: $0.speciesID, level: $0.level, nickname: $0.speciesID.capitalized)
        }
        guard enemyParty.isEmpty == false else { return }

        let wantsToFightMessage = trainerWantsToFightText(trainerName: battleManifest.displayName)

        var battle = RuntimeBattleState(
            battleID: battleManifest.id,
            kind: .trainer,
            trainerName: battleManifest.displayName,
            trainerSpritePath: battleManifest.trainerSpritePath,
            baseRewardMoney: battleManifest.baseRewardMoney,
            completionFlagID: battleManifest.completionFlagID,
            healsPartyAfterBattle: battleManifest.healsPartyAfterBattle,
            preventsBlackoutOnLoss: battleManifest.preventsBlackoutOnLoss,
            playerWinDialogueID: battleManifest.playerWinDialogueID,
            playerLoseDialogueID: battleManifest.playerLoseDialogueID,
            postBattleScriptID: battleManifest.postBattleScriptID,
            canRun: false,
            trainerClass: battleManifest.trainerClass,
            sourceTrainerObjectID: sourceTrainerObjectID,
            playerPokemon: playerPokemon,
            enemyParty: enemyParty,
            enemyActiveIndex: 0,
            aiLayer2Encouragement: 0,
            phase: .introText,
            focusedMoveIndex: 0,
            focusedBagItemIndex: 0,
            focusedPartyIndex: 0,
            partySelectionMode: .optionalSwitch,
            message: "",
            queuedMessages: [],
            pendingAction: nil,
            lastCaptureResult: nil,
            pendingPresentationBatches: [],
            learnMoveState: nil,
            rewardContinuation: nil,
            presentation: .init(
                stage: .introFlash1,
                revision: 0,
                uiVisibility: .hidden,
                activeSide: nil,
                transitionStyle: .spiral
            )
        )
        battle.pendingPresentationBatches = makeTrainerOpeningSendOutBatches(
            battle: battle
        )

        gameplayState.playerParty = syncedPlayerParty(from: battle, gameplayState: gameplayState)
        gameplayState.battle = battle
        self.gameplayState = gameplayState
        fieldPartyReorderState = nil
        scene = .battle
        substate = "battle"
        traceEvent(
            .battleStarted,
            "Started trainer battle \(battle.battleID).",
            mapID: gameplayState.mapID,
            battleID: battle.battleID,
            battleKind: battle.kind,
            details: [
                "opponent": battle.trainerName,
                "enemySpecies": battle.enemyPokemon.speciesID,
                "enemyLevel": String(battle.enemyPokemon.level),
            ]
        )
        requestTrainerBattleMusic()
        scheduleBattlePresentation(
            makeIntroPresentationBeats(
                openingMessage: wantsToFightMessage,
                transitionStyle: .spiral,
                requiresConfirmAfterReveal: true
            ),
            battleID: battle.battleID
        )
    }

    func startWildBattle(speciesID: String, level: Int) {
        guard var gameplayState else { return }
        let playerPokemon = clearBattleStatStages(
            gameplayState.playerParty.first ?? makePokemon(
                speciesID: gameplayState.chosenStarterSpeciesID ?? "SQUIRTLE",
                level: 5,
                nickname: gameplayState.chosenStarterSpeciesID?.capitalized ?? "Squirtle"
            )
        )
        let enemyPokemon = clearBattleStatStages(
            makePokemon(
                speciesID: speciesID,
                level: level,
                nickname: content.species(id: speciesID)?.displayName ?? speciesID.capitalized
            )
        )
        let battleID = "wild_\(gameplayState.mapID.lowercased())_\(speciesID.lowercased())_\(level)"

        var battle = RuntimeBattleState(
            battleID: battleID,
            kind: .wild,
            trainerName: "Wild \(enemyPokemon.nickname)",
            trainerSpritePath: nil,
            baseRewardMoney: 0,
            completionFlagID: "",
            healsPartyAfterBattle: false,
            preventsBlackoutOnLoss: false,
            playerWinDialogueID: "",
            playerLoseDialogueID: nil,
            postBattleScriptID: nil,
            canRun: true,
            trainerClass: nil,
            sourceTrainerObjectID: nil,
            playerPokemon: playerPokemon,
            enemyParty: [enemyPokemon],
            enemyActiveIndex: 0,
            aiLayer2Encouragement: 0,
            phase: .introText,
            focusedMoveIndex: 0,
            focusedBagItemIndex: 0,
            focusedPartyIndex: 0,
            partySelectionMode: .optionalSwitch,
            message: "",
            queuedMessages: [],
            pendingAction: .moveSelection,
            lastCaptureResult: nil,
            pendingPresentationBatches: [],
            learnMoveState: nil,
            rewardContinuation: nil,
            presentation: .init(
                stage: .introFlash1,
                revision: 0,
                uiVisibility: .hidden,
                activeSide: nil,
                transitionStyle: .spiral
            )
        )
        battle.pendingPresentationBatches = [
            makePlayerSendOutBatch(
                playerPokemon: battle.playerPokemon,
                enemyPokemon: battle.enemyPokemon
            ),
        ]
        gameplayState.playerParty = syncedPlayerParty(from: battle, gameplayState: gameplayState)
        gameplayState.battle = battle
        self.gameplayState = gameplayState
        scene = .battle
        substate = "battle"
        traceEvent(
            .battleStarted,
            "Started wild battle \(battle.battleID).",
            mapID: gameplayState.mapID,
            battleID: battle.battleID,
            battleKind: battle.kind,
            details: [
                "opponent": battle.trainerName,
                "enemySpecies": battle.enemyPokemon.speciesID,
                "enemyLevel": String(battle.enemyPokemon.level),
            ]
        )
        requestTrainerBattleMusic()
        scheduleBattlePresentation(
            makeIntroPresentationBeats(
                openingMessage: "Wild \(enemyPokemon.nickname) appeared!",
                transitionStyle: .spiral,
                requiresConfirmAfterReveal: true,
                revealSoundEffectRequest: speciesCrySoundEffectRequest(speciesID: enemyPokemon.speciesID)
            ),
            battleID: battle.battleID
        )
    }

    func healParty() {
        guard var gameplayState else { return }
        gameplayState.playerParty = gameplayState.playerParty.map { pokemon in
            var healed = pokemon
            healed.currentHP = healed.maxHP
            healed = clearBattleStatStages(healed)
            healed.moves = healed.moves.map { move in
                var restored = move
                restored.currentPP = content.move(id: move.id)?.maxPP ?? move.currentPP
                return restored
            }
            return healed
        }
        self.gameplayState = gameplayState
        traceEvent(
            .partyHealed,
            "Healed party.",
            mapID: gameplayState.mapID,
            details: [
                "partyCount": String(gameplayState.playerParty.count),
            ]
        )
    }

    func performBlackout(sourceTrainerObjectID: String?) {
        guard var gameplayState else { return }
        let previousMoney = gameplayState.money
        if let sourceTrainerObjectID {
            resetObjectStateToManifest(sourceTrainerObjectID, in: &gameplayState)
        }
        let checkpoint = gameplayState.blackoutCheckpoint ?? content.gameplayManifest.playerStart.defaultBlackoutCheckpoint
        gameplayState.money /= 2
        if let checkpoint {
            gameplayState.mapID = checkpoint.mapID
            gameplayState.playerPosition = checkpoint.position
            gameplayState.facing = checkpoint.facing
        }
        gameplayState.battle = nil
        gameplayState.activeMapScriptTriggerID = nil
        gameplayState.activeScriptID = nil
        gameplayState.activeScriptStep = nil
        self.gameplayState = gameplayState
        healParty()
        dialogueState = nil
        fieldPromptState = nil
        fieldHealingState = nil
        shopState = nil
        fieldPartyReorderState = nil
        deferredActions.removeAll()
        currentAudioState = nil
        fieldInteractionTask?.cancel()
        fieldInteractionTask = nil
        fieldAlertState = nil
        traceEvent(
            .blackout,
            "Player blacked out.",
            mapID: gameplayState.mapID,
            details: [
                "previousMoney": String(previousMoney),
                "remainingMoney": String(gameplayState.money),
                "moneyLost": String(max(0, previousMoney - gameplayState.money)),
                "checkpointMapID": checkpoint?.mapID ?? gameplayState.mapID,
            ]
        )
        scene = .field
        substate = "field"
        requestDefaultMapMusic()
    }

    func rivalStarter(for playerStarter: String) -> String {
        switch playerStarter {
        case "CHARMANDER":
            return "SQUIRTLE"
        case "SQUIRTLE":
            return "BULBASAUR"
        default:
            return "CHARMANDER"
        }
    }

    func rivalPickupScriptID(for playerStarter: String) -> String {
        switch playerStarter {
        case "CHARMANDER":
            return "oaks_lab_rival_picks_after_charmander"
        case "SQUIRTLE":
            return "oaks_lab_rival_picks_after_squirtle"
        default:
            return "oaks_lab_rival_picks_after_bulbasaur"
        }
    }

    func selectedBallObjectID(for speciesID: String) -> String {
        switch speciesID {
        case "CHARMANDER":
            return "oaks_lab_poke_ball_charmander"
        case "SQUIRTLE":
            return "oaks_lab_poke_ball_squirtle"
        default:
            return "oaks_lab_poke_ball_bulbasaur"
        }
    }

    func syncedPlayerParty(from battle: RuntimeBattleState, gameplayState: GameplayState) -> [RuntimePokemonState] {
        guard gameplayState.playerParty.isEmpty == false else {
            return [battle.playerPokemon]
        }

        var party = gameplayState.playerParty
        party[0] = battle.playerPokemon
        return party
    }

    func finalizedPlayerPartyAfterBattle(from battle: RuntimeBattleState, gameplayState: GameplayState) -> [RuntimePokemonState] {
        var finalizedBattle = battle
        finalizedBattle.playerPokemon = clearBattleStatStages(finalizedBattle.playerPokemon)
        return syncedPlayerParty(from: finalizedBattle, gameplayState: gameplayState)
    }

    func clearBattleStatStages(_ pokemon: RuntimePokemonState) -> RuntimePokemonState {
        var cleared = pokemon
        cleared.attackStage = 0
        cleared.defenseStage = 0
        cleared.speedStage = 0
        cleared.specialStage = 0
        cleared.accuracyStage = 0
        cleared.evasionStage = 0
        return cleared
    }
}
