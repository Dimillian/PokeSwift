import PokeDataModel

struct BattleExperienceRewardResult {
    let messages: [String]
    let pendingLearnMove: RuntimeBattleLearnMoveState?
    let pendingEvolution: RuntimePendingEvolutionState?
}

struct LevelUpMoveProcessingResult {
    let messages: [String]
    let pendingLearnMove: RuntimeBattleLearnMoveState?
}

extension GameRuntime {
    func makeEnemyDefeatResolution(
        battle: RuntimeBattleState,
        defeatedEnemy: RuntimePokemonState,
        playerPokemon: RuntimePokemonState
    ) -> (updatedPlayer: RuntimePokemonState, beats: [RuntimeBattlePresentationBeat]) {
        let previousPlayer = playerPokemon
        var updatedPlayer = playerPokemon
        let rewardResult = applyBattleExperienceReward(
            defeatedPokemon: defeatedEnemy,
            to: &updatedPlayer,
            isTrainerBattle: battle.kind == .trainer
        )
        let experienceMessages = rewardResult.messages

        var beats: [RuntimeBattlePresentationBeat] = []
        let wildVictoryCueID = battle.kind == .wild && battle.enemyActiveIndex + 1 >= battle.enemyParty.count
            ? "wild_victory"
            : nil

        if let experienceMessage = experienceMessages.first {
            beats.append(
                .init(
                    delay: battlePresentationDelay(base: 0.3),
                    stage: .experience,
                    uiVisibility: .visible,
                    activeSide: .player,
                    requiresConfirmAfterDisplay: true,
                    meterAnimation: experienceMeterAnimation(from: previousPlayer, to: updatedPlayer),
                    message: experienceMessage,
                    playerPokemon: updatedPlayer,
                    audioCueID: wildVictoryCueID
                )
            )

            var levelUpSoundPending = true
            for message in experienceMessages.dropFirst() {
                let shouldPlayLevelUpSound = levelUpSoundPending && message.contains("grew to Lv")
                beats.append(
                    .init(
                        delay: battlePresentationDelay(base: 0.24),
                        stage: .levelUp,
                        uiVisibility: .visible,
                        activeSide: .player,
                        requiresConfirmAfterDisplay: true,
                        message: message,
                        soundEffectRequest: shouldPlayLevelUpSound ? battleSoundEffectRequest(id: "SFX_LEVEL_UP") : nil
                    )
                )
                if shouldPlayLevelUpSound {
                    levelUpSoundPending = false
                }
            }
        }

        let rewardContinuation: RuntimeBattleRewardContinuation
        if battle.enemyActiveIndex + 1 < battle.enemyParty.count {
            rewardContinuation = battle.kind == .trainer
                ? .aboutToUse(index: battle.enemyActiveIndex + 1, previousMoveIndex: battle.focusedMoveIndex)
                : .sendNextEnemy(index: battle.enemyActiveIndex + 1)
        } else if battle.kind == .trainer {
            rewardContinuation = .finishTrainerWin(
                payout: trainerBattlePayoutAmount(battle: battle, defeatedEnemy: defeatedEnemy)
            )
        } else {
            rewardContinuation = .finishWin
        }

        beats.append(
            .init(
                delay: battlePresentationDelay(base: 0.18),
                stage: rewardResult.pendingLearnMove == nil ? .turnSettle : .levelUp,
                uiVisibility: .visible,
                phase: .turnText,
                pendingAction: .continueLevelUpResolution,
                learnMoveState: rewardResult.pendingLearnMove,
                rewardContinuation: rewardContinuation,
                pendingEvolution: rewardResult.pendingEvolution,
                playerPokemon: updatedPlayer
            )
        )

        return (updatedPlayer, beats)
    }

    func applyBattleExperienceReward(
        defeatedPokemon: RuntimePokemonState,
        to pokemon: inout RuntimePokemonState,
        isTrainerBattle: Bool
    ) -> BattleExperienceRewardResult {
        let baseSpeciesID = levelUpSpeciesID(for: pokemon)
        let gainedExperience = battleExperienceAward(for: defeatedPokemon, isTrainerBattle: isTrainerBattle)
        let updatedStatExp = awardStatExp(from: defeatedPokemon, to: pokemon.statExp)
        let maximumExperience = maximumExperience(for: baseSpeciesID)
        let updatedExperience = min(maximumExperience, pokemon.experience + gainedExperience)
        let updatedLevel = levelAfterGainingExperience(
            currentLevel: pokemon.level,
            updatedExperience: updatedExperience,
            speciesID: baseSpeciesID
        )
        guard gainedExperience > 0 || updatedStatExp != pokemon.statExp else {
            return BattleExperienceRewardResult(messages: [], pendingLearnMove: nil, pendingEvolution: nil)
        }

        var messages = ["\(pokemon.nickname) gained \(gainedExperience) EXP!"]
        let previousLevel = pokemon.level
        let previousMaxHP = pokemon.maxHP

        if updatedLevel > previousLevel {
            let recalculatedPokemon = makeConfiguredPokemon(
                speciesID: baseSpeciesID,
                nickname: pokemon.nickname,
                level: updatedLevel,
                experience: updatedExperience,
                dvs: pokemon.dvs,
                statExp: updatedStatExp,
                currentHP: nil,
                attackStage: pokemon.attackStage,
                defenseStage: pokemon.defenseStage,
                speedStage: pokemon.speedStage,
                specialStage: pokemon.specialStage,
                accuracyStage: pokemon.accuracyStage,
                evasionStage: pokemon.evasionStage,
                majorStatus: pokemon.majorStatus,
                moves: levelUpMoveSet(for: pokemon)
            )
            let gainedMaxHP = recalculatedPokemon.maxHP - previousMaxHP
            var leveledPokemon: RuntimePokemonState
            if pokemon.battleEffects.transformedState != nil {
                leveledPokemon = RuntimePokemonState(
                    speciesID: pokemon.speciesID,
                    nickname: pokemon.nickname,
                    level: updatedLevel,
                    experience: updatedExperience,
                    dvs: pokemon.dvs,
                    statExp: updatedStatExp,
                    maxHP: recalculatedPokemon.maxHP,
                    currentHP: min(
                        recalculatedPokemon.maxHP,
                        max(0, pokemon.currentHP + gainedMaxHP)
                    ),
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
                    isBadlyPoisoned: pokemon.isBadlyPoisoned,
                    moves: pokemon.moves,
                    battleEffects: pokemon.battleEffects
                )
                updateTransformedOriginalState(for: &leveledPokemon, originalPokemon: recalculatedPokemon)
            } else {
                leveledPokemon = recalculatedPokemon
                leveledPokemon.currentHP = min(
                    recalculatedPokemon.maxHP,
                    max(0, pokemon.currentHP + gainedMaxHP)
                )
                leveledPokemon.statusCounter = pokemon.statusCounter
                leveledPokemon.isBadlyPoisoned = pokemon.isBadlyPoisoned
                leveledPokemon.battleEffects = pokemon.battleEffects
            }
            pokemon = leveledPokemon
        } else {
            pokemon = RuntimePokemonState(
                speciesID: pokemon.speciesID,
                nickname: pokemon.nickname,
                level: pokemon.level,
                experience: updatedExperience,
                dvs: pokemon.dvs,
                statExp: updatedStatExp,
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
                isBadlyPoisoned: pokemon.isBadlyPoisoned,
                moves: pokemon.moves,
                battleEffects: pokemon.battleEffects
            )
        }

        if updatedLevel > previousLevel {
            for nextLevel in (previousLevel + 1)...updatedLevel {
                messages.append("\(pokemon.nickname) grew to Lv\(nextLevel)!")
            }
        }

        let learnMoveResult = applyPendingLevelUpMoves(
            to: &pokemon,
            moveIDs: levelUpMoveIDsDue(
                for: baseSpeciesID,
                from: previousLevel,
                to: updatedLevel
            )
        )
        messages.append(contentsOf: learnMoveResult.messages)
        let pendingEvolution = pendingLevelEvolution(
            speciesID: baseSpeciesID,
            from: previousLevel,
            to: updatedLevel
        )

        return BattleExperienceRewardResult(
            messages: messages,
            pendingLearnMove: learnMoveResult.pendingLearnMove,
            pendingEvolution: pendingEvolution
        )
    }

    func pendingLevelEvolution(
        speciesID: String,
        from previousLevel: Int,
        to updatedLevel: Int
    ) -> RuntimePendingEvolutionState? {
        guard updatedLevel > previousLevel,
              let species = content.species(id: speciesID),
              let evolution = species.evolutions.first(where: {
                  $0.trigger.kind == .level &&
                  ($0.trigger.level ?? 0) > previousLevel &&
                  ($0.trigger.level ?? 0) <= updatedLevel
              }) else {
            return nil
        }

        return RuntimePendingEvolutionState(
            partyIndex: 0,
            originalSpeciesID: speciesID,
            targetSpeciesID: evolution.targetSpeciesID
        )
    }

    func levelUpMoveIDsDue(for speciesID: String, from previousLevel: Int, to updatedLevel: Int) -> [String] {
        guard updatedLevel > previousLevel,
              let species = content.species(id: speciesID) else {
            return []
        }
        return species.levelUpLearnset
            .filter { $0.level > previousLevel && $0.level <= updatedLevel }
            .map(\.moveID)
    }

    func applyPendingLevelUpMoves(
        to pokemon: inout RuntimePokemonState,
        moveIDs: [String]
    ) -> LevelUpMoveProcessingResult {
        var messages: [String] = []
        var pendingMoveIDs = moveIDs
        var knownMoves = levelUpMoveSet(for: pokemon)

        while pendingMoveIDs.isEmpty == false {
            let moveID = pendingMoveIDs.removeFirst()
            guard knownMoves.contains(where: { $0.id == moveID }) == false,
                  let move = content.move(id: moveID) else {
                continue
            }

            if knownMoves.count < 4 {
                knownMoves.append(RuntimeMoveState(id: move.id, currentPP: move.maxPP))
                setLevelUpMoveSet(knownMoves, for: &pokemon)
                messages.append("\(pokemon.nickname) learned \(move.displayName)!")
                continue
            }

            messages.append("\(pokemon.nickname) is trying to learn \(move.displayName)!")
            messages.append("But \(pokemon.nickname) can't learn more than 4 moves.")
            return LevelUpMoveProcessingResult(
                messages: messages,
                pendingLearnMove: .init(moveID: move.id, remainingMoveIDs: pendingMoveIDs)
            )
        }

        return LevelUpMoveProcessingResult(messages: messages, pendingLearnMove: nil)
    }

    func continueLevelUpResolution(battle: inout RuntimeBattleState) {
        if battle.learnMoveState != nil {
            enterLearnMoveDecisionPrompt(battle: &battle)
            return
        }
        resumeRewardContinuation(battle: &battle)
    }

    func enterLearnMoveDecisionPrompt(battle: inout RuntimeBattleState) {
        guard let learnMoveState = battle.learnMoveState,
              let move = content.move(id: learnMoveState.moveID) else {
            battle.learnMoveState = nil
            resumeRewardContinuation(battle: &battle)
            return
        }
        battle.phase = .learnMoveDecision
        battle.focusedMoveIndex = 0
        battle.pendingAction = nil
        battle.queuedMessages = []
        battle.message = "Teach \(move.displayName) to \(battle.playerPokemon.nickname)?"
    }

    func resolveLearnMoveDecision(battle: inout RuntimeBattleState) {
        guard battle.phase == .learnMoveDecision,
              let learnMoveState = battle.learnMoveState,
              let move = content.move(id: learnMoveState.moveID) else {
            return
        }

        if battle.focusedMoveIndex == 0 {
            battle.phase = .learnMoveSelection
            battle.focusedMoveIndex = 0
            battle.pendingAction = nil
            battle.queuedMessages = []
            battle.message = "Choose a move to forget for \(move.displayName)."
            return
        }

        battle.learnMoveState = nil
        processPendingLevelUpMoves(
            battle: &battle,
            moveIDs: learnMoveState.remainingMoveIDs,
            prefixMessages: ["\(battle.playerPokemon.nickname) did not learn \(move.displayName)."]
        )
    }

    func resolveLearnMoveSelection(battle: inout RuntimeBattleState) {
        guard battle.phase == .learnMoveSelection,
              let learnMoveState = battle.learnMoveState,
              let newMove = content.move(id: learnMoveState.moveID) else {
            return
        }

        var knownMoves = levelUpMoveSet(for: battle.playerPokemon)
        guard knownMoves.indices.contains(battle.focusedMoveIndex) else {
            return
        }

        let forgottenMoveID = knownMoves[battle.focusedMoveIndex].id
        guard hmMoveIDs.contains(forgottenMoveID) == false else {
            let moveDisplayName = content.move(id: forgottenMoveID)?.displayName ?? forgottenMoveID
            battle.message = "\(moveDisplayName) can't be forgotten."
            return
        }

        let forgottenMoveName = content.move(id: forgottenMoveID)?.displayName ?? forgottenMoveID
        knownMoves[battle.focusedMoveIndex] = RuntimeMoveState(
            id: newMove.id,
            currentPP: newMove.maxPP
        )
        setLevelUpMoveSet(knownMoves, for: &battle.playerPokemon)
        battle.learnMoveState = nil

        processPendingLevelUpMoves(
            battle: &battle,
            moveIDs: learnMoveState.remainingMoveIDs,
            prefixMessages: [
                "\(battle.playerPokemon.nickname) forgot \(forgottenMoveName).",
                "\(battle.playerPokemon.nickname) learned \(newMove.displayName)!",
            ]
        )
    }

    func processPendingLevelUpMoves(
        battle: inout RuntimeBattleState,
        moveIDs: [String],
        prefixMessages: [String] = []
    ) {
        var playerPokemon = battle.playerPokemon
        let learnMoveResult = applyPendingLevelUpMoves(to: &playerPokemon, moveIDs: moveIDs)
        battle.playerPokemon = playerPokemon
        battle.learnMoveState = learnMoveResult.pendingLearnMove

        let messages = prefixMessages + learnMoveResult.messages
        guard messages.isEmpty == false else {
            continueLevelUpResolution(battle: &battle)
            return
        }

        presentBattleMessages(messages, battle: &battle, pendingAction: .continueLevelUpResolution)
    }

    func levelUpSpeciesID(for pokemon: RuntimePokemonState) -> String {
        pokemon.battleEffects.transformedState?.originalSpeciesID ?? pokemon.speciesID
    }

    func levelUpMoveSet(for pokemon: RuntimePokemonState) -> [RuntimeMoveState] {
        pokemon.battleEffects.transformedState?.originalMoves ?? pokemon.moves
    }

    func battleDisplayedMoveSet(for battle: RuntimeBattleState) -> [RuntimeMoveState] {
        if battle.learnMoveState != nil {
            return levelUpMoveSet(for: battle.playerPokemon)
        }
        return battle.playerPokemon.moves
    }

    func setLevelUpMoveSet(_ moves: [RuntimeMoveState], for pokemon: inout RuntimePokemonState) {
        guard var transformedState = pokemon.battleEffects.transformedState else {
            pokemon.moves = moves
            return
        }

        transformedState.originalMoves = moves
        pokemon.battleEffects.transformedState = transformedState
    }

    func updateTransformedOriginalState(
        for pokemon: inout RuntimePokemonState,
        originalPokemon: RuntimePokemonState
    ) {
        guard var transformedState = pokemon.battleEffects.transformedState else {
            return
        }

        transformedState.originalAttack = originalPokemon.attack
        transformedState.originalDefense = originalPokemon.defense
        transformedState.originalSpeed = originalPokemon.speed
        transformedState.originalSpecial = originalPokemon.special
        transformedState.originalAttackStage = originalPokemon.attackStage
        transformedState.originalDefenseStage = originalPokemon.defenseStage
        transformedState.originalSpeedStage = originalPokemon.speedStage
        transformedState.originalSpecialStage = originalPokemon.specialStage
        transformedState.originalAccuracyStage = originalPokemon.accuracyStage
        transformedState.originalEvasionStage = originalPokemon.evasionStage
        transformedState.originalMoves = originalMovesForTransformSnapshot(originalPokemon)
        pokemon.battleEffects.transformedState = transformedState
    }

    func resumeRewardContinuation(battle: inout RuntimeBattleState) {
        guard let rewardContinuation = battle.rewardContinuation else {
            returnToBattleMoveSelection(battle: &battle)
            return
        }

        battle.rewardContinuation = nil
        switch rewardContinuation {
        case let .aboutToUse(index, _):
            let messages = trainerAboutToUseMessages(trainerName: battle.trainerName, pokemon: battle.enemyParty[index])
            if messages.count > 1 {
                presentBattleMessages(
                    [messages[0]],
                    battle: &battle,
                    pendingAction: .enterTrainerAboutToUseDecision(nextIndex: index)
                )
            } else {
                enterTrainerAboutToUseDecision(battle: &battle, nextIndex: index)
            }
        case let .sendNextEnemy(index):
            scheduleNextEnemySendOut(battle: &battle, nextIndex: index)
        case let .finishTrainerWin(payout):
            presentBattleMessages(
                [
                    trainerDefeatedText(trainerName: battle.trainerName),
                    moneyForWinningText(amount: payout),
                ],
                battle: &battle,
                pendingAction: .completeTrainerVictory(payout: payout),
                audioCueID: "trainer_victory"
            )
        case .finishWin:
            battle.phase = .battleComplete
            finishBattle(battle: battle, won: true)
        }
    }

    func trainerBattlePayoutAmount(
        battle: RuntimeBattleState,
        defeatedEnemy: RuntimePokemonState
    ) -> Int {
        max(0, battle.baseRewardMoney * defeatedEnemy.level)
    }

    var hmMoveIDs: Set<String> {
        ["CUT", "FLY", "SURF", "STRENGTH", "FLASH"]
    }

    func awardStatExp(from defeatedPokemon: RuntimePokemonState, to statExp: PokemonStatExp) -> PokemonStatExp {
        guard let species = content.species(id: defeatedPokemon.speciesID) else {
            return statExp
        }

        return PokemonStatExp(
            hp: statExp.hp + species.baseHP,
            attack: statExp.attack + species.baseAttack,
            defense: statExp.defense + species.baseDefense,
            speed: statExp.speed + species.baseSpeed,
            special: statExp.special + species.baseSpecial
        )
    }

    func battleExperienceAward(for defeatedPokemon: RuntimePokemonState, isTrainerBattle: Bool) -> Int {
        guard let species = content.species(id: defeatedPokemon.speciesID) else { return 0 }
        var experience = (species.baseExp * defeatedPokemon.level) / 7
        if isTrainerBattle {
            experience += experience / 2
        }
        return experience
    }

    func levelAfterGainingExperience(currentLevel: Int, updatedExperience: Int, speciesID: String) -> Int {
        guard let growthRate = content.species(id: speciesID)?.growthRate else { return 1 }
        var level = currentLevel
        while level < 100 && updatedExperience >= experienceRequired(for: level + 1, growthRate: growthRate) {
            level += 1
        }
        return level
    }

    func maximumExperience(for speciesID: String) -> Int {
        experienceRequired(for: 100, speciesID: speciesID)
    }
}
