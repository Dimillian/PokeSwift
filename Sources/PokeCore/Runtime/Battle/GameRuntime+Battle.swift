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
        gameplayState.objectStates[selectedBallObjectID(for: speciesID)]?.visible = false
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
        gameplayState.activeFlags.insert(battle.completionFlagID)
        gameplayState.playerParty = syncedPlayerParty(from: battle, gameplayState: gameplayState)
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
        // We do not have defeated-trainer music yet, but the trainer battle track
        // should not continue under the result dialogue.
        stopAllMusic()
        showDialogue(id: won ? battle.winDialogueID : battle.loseDialogueID, completion: .startPostBattleDialogue(won: won))
    }

    func runPostBattleSequence(won: Bool) {
        let _ = won
        beginScript(id: "oaks_lab_rival_exit_after_battle")
    }

    func finishWildBattleEscape() {
        cancelBattlePresentation()
        guard var gameplayState else { return }
        let battle = gameplayState.battle
        if let battle = gameplayState.battle {
            gameplayState.playerParty = syncedPlayerParty(from: battle, gameplayState: gameplayState)
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
        gameplayState.playerParty = syncedPlayerParty(from: battle, gameplayState: gameplayState)
        gameplayState.battle = nil
        self.gameplayState = gameplayState
        if won == false {
            healParty()
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

    func finishWildBattleCapture(battle: RuntimeBattleState) {
        cancelBattlePresentation()
        guard var gameplayState else { return }
        gameplayState.playerParty = syncedPlayerParty(from: battle, gameplayState: gameplayState)
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

    func startBattle(id: String) {
        guard var gameplayState,
              let chosenStarter = gameplayState.chosenStarterSpeciesID else {
            return
        }

        guard let battleManifest = content.trainerBattle(id: id) else {
            return
        }

        let playerPokemon = gameplayState.playerParty.first ?? makePokemon(speciesID: chosenStarter, level: 5, nickname: chosenStarter.capitalized)
        let enemyParty = battleManifest.party.map {
            makeTrainerBattlePokemon(speciesID: $0.speciesID, level: $0.level, nickname: $0.speciesID.capitalized)
        }
        guard enemyParty.isEmpty == false else { return }

        let openingMessage = "\(battleManifest.displayName) challenges you!"
        let battle = RuntimeBattleState(
            battleID: battleManifest.id,
            kind: .trainer,
            trainerName: battleManifest.displayName,
            completionFlagID: battleManifest.completionFlagID,
            healsPartyAfterBattle: battleManifest.healsPartyAfterBattle,
            preventsBlackoutOnLoss: battleManifest.preventsBlackoutOnLoss,
            winDialogueID: battleManifest.winDialogueID,
            loseDialogueID: battleManifest.loseDialogueID,
            canRun: false,
            playerPokemon: playerPokemon,
            enemyParty: enemyParty,
            enemyActiveIndex: 0,
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
                openingMessage: openingMessage,
                transitionStyle: .spiral
            ),
            battleID: battle.battleID
        )
    }

    func startWildBattle(speciesID: String, level: Int) {
        guard var gameplayState else { return }
        let playerPokemon = gameplayState.playerParty.first ?? makePokemon(
            speciesID: gameplayState.chosenStarterSpeciesID ?? "SQUIRTLE",
            level: 5,
            nickname: gameplayState.chosenStarterSpeciesID?.capitalized ?? "Squirtle"
        )
        let enemyPokemon = makePokemon(
            speciesID: speciesID,
            level: level,
            nickname: content.species(id: speciesID)?.displayName ?? speciesID.capitalized
        )
        let battleID = "wild_\(gameplayState.mapID.lowercased())_\(speciesID.lowercased())_\(level)"

        let battle = RuntimeBattleState(
            battleID: battleID,
            kind: .wild,
            trainerName: "Wild \(enemyPokemon.nickname)",
            completionFlagID: "",
            healsPartyAfterBattle: false,
            preventsBlackoutOnLoss: false,
            winDialogueID: "",
            loseDialogueID: "",
            canRun: true,
            playerPokemon: playerPokemon,
            enemyParty: [enemyPokemon],
            enemyActiveIndex: 0,
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
                requiresConfirmAfterReveal: true
            ),
            battleID: battle.battleID
        )
    }

    func healParty() {
        guard var gameplayState else { return }
        gameplayState.playerParty = gameplayState.playerParty.map { pokemon in
            var healed = pokemon
            healed.currentHP = healed.maxHP
            healed.attackStage = 0
            healed.defenseStage = 0
            healed.accuracyStage = 0
            healed.evasionStage = 0
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
}
