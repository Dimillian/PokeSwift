import PokeDataModel

struct BattleExperienceRewardResult {
    let messages: [String]
    let pendingLearnMove: RuntimeBattleLearnMoveState?
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
                    playerPokemon: updatedPlayer
                )
            )

            for message in experienceMessages.dropFirst() {
                beats.append(
                    .init(
                        delay: battlePresentationDelay(base: 0.24),
                        stage: .levelUp,
                        uiVisibility: .visible,
                        activeSide: .player,
                        requiresConfirmAfterDisplay: true,
                        message: message
                    )
                )
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
        let gainedExperience = battleExperienceAward(for: defeatedPokemon, isTrainerBattle: isTrainerBattle)
        let updatedStatExp = awardStatExp(from: defeatedPokemon, to: pokemon.statExp)
        let maximumExperience = maximumExperience(for: pokemon.speciesID)
        let updatedExperience = min(maximumExperience, pokemon.experience + gainedExperience)
        let updatedLevel = levelAfterGainingExperience(
            currentLevel: pokemon.level,
            updatedExperience: updatedExperience,
            speciesID: pokemon.speciesID
        )
        guard gainedExperience > 0 || updatedStatExp != pokemon.statExp else {
            return BattleExperienceRewardResult(messages: [], pendingLearnMove: nil)
        }

        var messages = ["\(pokemon.nickname) gained \(gainedExperience) EXP!"]
        let previousLevel = pokemon.level
        let previousMaxHP = pokemon.maxHP

        if updatedLevel > previousLevel {
            let recalculatedPokemon = makeConfiguredPokemon(
                speciesID: pokemon.speciesID,
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
                moves: pokemon.moves
            )
            let gainedMaxHP = recalculatedPokemon.maxHP - previousMaxHP
            var leveledPokemon = recalculatedPokemon
            leveledPokemon.currentHP = min(
                recalculatedPokemon.maxHP,
                max(0, pokemon.currentHP + gainedMaxHP)
            )
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
                moves: pokemon.moves
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
                for: pokemon.speciesID,
                from: previousLevel,
                to: updatedLevel
            )
        )
        messages.append(contentsOf: learnMoveResult.messages)

        return BattleExperienceRewardResult(
            messages: messages,
            pendingLearnMove: learnMoveResult.pendingLearnMove
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

        while pendingMoveIDs.isEmpty == false {
            let moveID = pendingMoveIDs.removeFirst()
            guard pokemon.moves.contains(where: { $0.id == moveID }) == false,
                  let move = content.move(id: moveID) else {
                continue
            }

            if pokemon.moves.count < 4 {
                pokemon.moves.append(RuntimeMoveState(id: move.id, currentPP: move.maxPP))
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
              battle.playerPokemon.moves.indices.contains(battle.focusedMoveIndex),
              let newMove = content.move(id: learnMoveState.moveID) else {
            return
        }

        let forgottenMoveID = battle.playerPokemon.moves[battle.focusedMoveIndex].id
        guard hmMoveIDs.contains(forgottenMoveID) == false else {
            let moveDisplayName = content.move(id: forgottenMoveID)?.displayName ?? forgottenMoveID
            battle.message = "\(moveDisplayName) can't be forgotten."
            return
        }

        let forgottenMoveName = content.move(id: forgottenMoveID)?.displayName ?? forgottenMoveID
        battle.playerPokemon.moves[battle.focusedMoveIndex] = RuntimeMoveState(
            id: newMove.id,
            currentPP: newMove.maxPP
        )
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

    func resumeRewardContinuation(battle: inout RuntimeBattleState) {
        guard let rewardContinuation = battle.rewardContinuation else {
            returnToBattleMoveSelection(battle: &battle)
            return
        }

        battle.rewardContinuation = nil
        switch rewardContinuation {
        case let .aboutToUse(index, _):
            presentBattleMessages(
                trainerAboutToUseMessages(trainerName: battle.trainerName, pokemon: battle.enemyParty[index]),
                battle: &battle,
                pendingAction: .enterTrainerAboutToUseDecision(nextIndex: index)
            )
        case let .sendNextEnemy(index):
            scheduleNextEnemySendOut(battle: &battle, nextIndex: index)
        case let .finishTrainerWin(payout):
            presentBattleMessages(
                [
                    trainerDefeatedText(trainerName: battle.trainerName),
                    moneyForWinningText(amount: payout),
                ],
                battle: &battle,
                pendingAction: .completeTrainerVictory(payout: payout)
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
