import Foundation
import PokeDataModel

extension GameRuntime {
    func commandReadyBeat(
        delay: TimeInterval,
        playerPokemon: RuntimePokemonState? = nil,
        enemyPokemon: RuntimePokemonState? = nil
    ) -> RuntimeBattlePresentationBeat {
        .init(
            delay: delay,
            stage: .commandReady,
            uiVisibility: .visible,
            transitionStyle: .none,
            message: battlePrompt(for: .moveSelection),
            phase: .moveSelection,
            pendingAction: nil,
            playerPokemon: playerPokemon,
            enemyPokemon: enemyPokemon
        )
    }

    func losingBattleBatch() -> [RuntimeBattlePresentationBeat] {
        [
            .init(
                delay: battlePresentationDelay(base: 0.28),
                stage: .battleComplete,
                uiVisibility: .visible,
                finishBattleWon: false
            ),
        ]
    }

    func resolveActionMoveIndex(
        for side: BattlePresentationSide,
        battle: RuntimeBattleState,
        playerPokemon: RuntimePokemonState,
        enemyPokemon: RuntimePokemonState
    ) -> Int {
        side == .player
            ? battle.focusedMoveIndex
            : selectEnemyMoveIndex(enemyPokemon: enemyPokemon, playerPokemon: playerPokemon)
    }

    func applyResolvedBattleAction(
        _ action: ResolvedBattleAction,
        side: BattlePresentationSide,
        simulatedPlayer: inout RuntimePokemonState,
        simulatedEnemy: inout RuntimePokemonState
    ) {
        if side == .player {
            simulatedPlayer = action.updatedAttacker
            simulatedEnemy = action.updatedDefender
        } else {
            simulatedEnemy = action.updatedAttacker
            simulatedPlayer = action.updatedDefender
        }
    }

    func appendPostActionResolutionIfNeeded(
        battle: RuntimeBattleState,
        simulatedPlayer: inout RuntimePokemonState,
        simulatedEnemy: RuntimePokemonState,
        batches: inout [[RuntimeBattlePresentationBeat]]
    ) -> Bool {
        if simulatedPlayer.currentHP == 0 {
            batches.append(losingBattleBatch())
            return true
        }

        if simulatedEnemy.currentHP == 0 {
            let resolution = makeEnemyDefeatResolution(
                battle: battle,
                defeatedEnemy: simulatedEnemy,
                playerPokemon: simulatedPlayer
            )
            simulatedPlayer = resolution.updatedPlayer
            if resolution.beats.isEmpty == false {
                batches.append(resolution.beats)
            }
            return true
        }

        return false
    }

    func battlePresentationDelay(base: TimeInterval) -> TimeInterval {
        let scale: Double
        if validationMode || isTestEnvironment {
            scale = 0.12
        } else {
            scale = 1
        }
        return max(0, base * scale)
    }

    func cancelBattlePresentation() {
        battlePresentationTask?.cancel()
        battlePresentationTask = nil
    }

    func updateBattlePresentation(
        battle: inout RuntimeBattleState,
        stage: BattlePresentationStage,
        uiVisibility: BattlePresentationUIVisibility,
        activeSide: BattlePresentationSide?,
        meterAnimation: BattleMeterAnimationTelemetry?,
        transitionStyle: BattleTransitionStyle
    ) {
        battle.presentation.stage = stage
        battle.presentation.revision += 1
        battle.presentation.uiVisibility = uiVisibility
        battle.presentation.activeSide = activeSide
        battle.presentation.meterAnimation = meterAnimation
        battle.presentation.transitionStyle = transitionStyle
    }

    func advanceBattlePresentationBatch(battle: inout RuntimeBattleState) {
        guard battle.pendingPresentationBatches.isEmpty == false else { return }
        let nextBatch = battle.pendingPresentationBatches.removeFirst()
        battle.phase = .resolvingTurn
        scheduleBattlePresentation(nextBatch, battleID: battle.battleID)
    }

    func scheduleBattlePresentation(_ beats: [RuntimeBattlePresentationBeat], battleID: String) {
        cancelBattlePresentation()
        guard beats.isEmpty == false else { return }

        battlePresentationTask = Task { [self] in
            for beat in beats {
                if beat.delay > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(beat.delay * 1_000_000_000))
                }
                guard Task.isCancelled == false else { return }
                applyBattlePresentationBeat(beat, battleID: battleID)
            }

            battlePresentationTask = nil
        }
    }

    func applyBattlePresentationBeat(_ beat: RuntimeBattlePresentationBeat, battleID: String) {
        guard var gameplayState, var battle = gameplayState.battle, battle.battleID == battleID else {
            battlePresentationTask = nil
            return
        }

        if let message = beat.message {
            battle.message = message
        }
        if let phase = beat.phase {
            battle.phase = phase
        }
        if let pendingAction = beat.pendingAction {
            battle.pendingAction = pendingAction
        }
        if let learnMoveState = beat.learnMoveState {
            battle.learnMoveState = learnMoveState
        }
        if let rewardContinuation = beat.rewardContinuation {
            battle.rewardContinuation = rewardContinuation
        }
        if let playerPokemon = beat.playerPokemon {
            battle.playerPokemon = playerPokemon
        }
        if let enemyPokemon = beat.enemyPokemon {
            battle.enemyPokemon = enemyPokemon
        }
        if let enemyParty = beat.enemyParty, let enemyActiveIndex = beat.enemyActiveIndex {
            battle.enemyParty = enemyParty
            battle.enemyActiveIndex = enemyActiveIndex
        }
        if let moveAudioMoveID = beat.moveAudioMoveID,
           let move = content.move(id: moveAudioMoveID),
           let attackerSpeciesID = beat.moveAudioAttackerSpeciesID {
            _ = playMoveAudio(for: move, attackerSpeciesID: attackerSpeciesID)
        }

        updateBattlePresentation(
            battle: &battle,
            stage: beat.stage,
            uiVisibility: beat.uiVisibility,
            activeSide: beat.activeSide,
            meterAnimation: beat.meterAnimation,
            transitionStyle: beat.transitionStyle
        )

        gameplayState.playerParty = syncedPlayerParty(from: battle, gameplayState: gameplayState)
        gameplayState.battle = battle
        self.gameplayState = gameplayState
        publishSnapshot()

        if let won = beat.finishBattleWon {
            finishBattle(battle: battle, won: won)
            return
        }

        if beat.escapeBattle {
            finishWildBattleEscape()
        }
    }

    func makeIntroPresentationBeats(
        openingMessage: String,
        transitionStyle: BattleTransitionStyle,
        requiresConfirmAfterReveal: Bool = false
    ) -> [RuntimeBattlePresentationBeat] {
        var beats: [RuntimeBattlePresentationBeat] = [
            .init(
                delay: battlePresentationDelay(base: 0),
                stage: .introFlash1,
                uiVisibility: .hidden,
                transitionStyle: transitionStyle,
                phase: .introText,
                pendingAction: .moveSelection
            ),
            .init(
                delay: battlePresentationDelay(base: 0.18),
                stage: .introFlash2,
                uiVisibility: .hidden,
                transitionStyle: transitionStyle,
                phase: .introText
            ),
            .init(
                delay: battlePresentationDelay(base: 0.18),
                stage: .introFlash3,
                uiVisibility: .hidden,
                transitionStyle: transitionStyle,
                phase: .introText
            ),
            .init(
                delay: battlePresentationDelay(base: 0.16),
                stage: .introSpiral,
                uiVisibility: .hidden,
                transitionStyle: transitionStyle,
                phase: .introText
            ),
            .init(
                delay: battlePresentationDelay(base: 0.92),
                stage: .introCrossing,
                uiVisibility: .hidden,
                transitionStyle: transitionStyle,
                phase: .introText
            ),
            .init(
                delay: battlePresentationDelay(base: 0.55),
                stage: .introReveal,
                uiVisibility: .visible,
                transitionStyle: transitionStyle,
                message: openingMessage,
                phase: requiresConfirmAfterReveal ? .turnText : .introText,
                pendingAction: requiresConfirmAfterReveal ? .moveSelection : nil
            ),
        ]

        if requiresConfirmAfterReveal == false {
            beats.append(commandReadyBeat(delay: battlePresentationDelay(base: 0.18)))
        }

        return beats
    }

    func makeTurnPresentationBatches(for battle: RuntimeBattleState) -> [[RuntimeBattlePresentationBeat]] {
        var simulatedPlayer = battle.playerPokemon
        var simulatedEnemy = battle.enemyPokemon
        var batches: [[RuntimeBattlePresentationBeat]] = []
        let actionSides: [BattlePresentationSide] = simulatedPlayer.speed >= simulatedEnemy.speed
            ? [.player, .enemy]
            : [.enemy, .player]

        for side in actionSides {
            let moveIndex = resolveActionMoveIndex(
                for: side,
                battle: battle,
                playerPokemon: simulatedPlayer,
                enemyPokemon: simulatedEnemy
            )
            let action = resolveBattleAction(
                side: side,
                attacker: side == .player ? simulatedPlayer : simulatedEnemy,
                defender: side == .player ? simulatedEnemy : simulatedPlayer,
                moveIndex: moveIndex
            )
            batches.append(makeBeats(for: action))
            applyResolvedBattleAction(
                action,
                side: side,
                simulatedPlayer: &simulatedPlayer,
                simulatedEnemy: &simulatedEnemy
            )

            if appendPostActionResolutionIfNeeded(
                battle: battle,
                simulatedPlayer: &simulatedPlayer,
                simulatedEnemy: simulatedEnemy,
                batches: &batches
            ) {
                return batches
            }
        }

        batches.append([
            commandReadyBeat(
                delay: battlePresentationDelay(base: 0.24),
                playerPokemon: simulatedPlayer,
                enemyPokemon: simulatedEnemy
            ),
        ])
        return batches
    }

    func makeBeats(for action: ResolvedBattleAction) -> [RuntimeBattlePresentationBeat] {
        let attackerPokemon = action.side == .player ? action.updatedAttacker : nil
        let enemyAttacker = action.side == .enemy ? action.updatedAttacker : nil
        let defenderMutationPlayer = action.side == .enemy ? action.updatedDefender : nil
        let defenderMutationEnemy = action.side == .player ? action.updatedDefender : nil
        var beats: [RuntimeBattlePresentationBeat] = [
            .init(
                delay: battlePresentationDelay(base: 0),
                stage: .attackWindup,
                uiVisibility: .visible,
                activeSide: action.side,
                message: action.messages.first,
                phase: .turnText,
                playerPokemon: attackerPokemon,
                enemyPokemon: enemyAttacker
            ),
            .init(
                delay: battlePresentationDelay(base: 0.22),
                stage: .attackImpact,
                uiVisibility: .visible,
                activeSide: action.side,
                moveAudioMoveID: action.moveID,
                moveAudioAttackerSpeciesID: action.attackerSpeciesID
            ),
        ]

        let trailingMessages = Array(action.messages.dropFirst())
        if action.dealtDamage > 0 {
            beats.append(
                .init(
                    delay: battlePresentationDelay(base: 0.18),
                    stage: .hpDrain,
                    uiVisibility: .visible,
                    activeSide: action.side == .player ? .enemy : .player,
                    meterAnimation: hpMeterAnimation(for: action),
                    playerPokemon: defenderMutationPlayer,
                    enemyPokemon: defenderMutationEnemy
                )
            )
        } else if defenderMutationPlayer != nil || defenderMutationEnemy != nil {
            let statusMessage = trailingMessages.first
            beats.append(
                .init(
                    delay: battlePresentationDelay(base: 0.18),
                    stage: .resultText,
                    uiVisibility: .visible,
                    activeSide: action.side == .player ? .enemy : .player,
                    message: statusMessage,
                    playerPokemon: defenderMutationPlayer,
                    enemyPokemon: defenderMutationEnemy
                )
            )
        }

        let remainingMessages: [String]
        if action.dealtDamage > 0 {
            remainingMessages = trailingMessages
        } else if trailingMessages.isEmpty {
            remainingMessages = []
        } else {
            remainingMessages = Array(trailingMessages.dropFirst())
        }

        for message in remainingMessages {
            let stage: BattlePresentationStage = message.contains("fainted!") ? .faint : .resultText
            beats.append(
                .init(
                    delay: battlePresentationDelay(base: 0.24),
                    stage: stage,
                    uiVisibility: .visible,
                    activeSide: action.side == .player ? .enemy : .player,
                    message: message
                )
            )
        }

        return beats
    }

    func hpMeterAnimation(for action: ResolvedBattleAction) -> BattleMeterAnimationTelemetry {
        BattleMeterAnimationTelemetry(
            kind: .hp,
            side: action.side == .player ? .enemy : .player,
            fromValue: action.defenderHPBefore,
            toValue: action.defenderHPAfter,
            maximumValue: max(1, action.updatedDefender.maxHP)
        )
    }

    func experienceMeterAnimation(
        from previousPokemon: RuntimePokemonState,
        to updatedPokemon: RuntimePokemonState
    ) -> BattleMeterAnimationTelemetry {
        BattleMeterAnimationTelemetry(
            kind: .experience,
            side: .player,
            fromValue: previousPokemon.experience,
            toValue: updatedPokemon.experience,
            maximumValue: max(1, maximumExperience(for: updatedPokemon.speciesID)),
            startLevel: previousPokemon.level,
            endLevel: updatedPokemon.level,
            startLevelStart: experienceRequired(for: previousPokemon.level, speciesID: previousPokemon.speciesID),
            startNextLevel: previousPokemon.level >= 100
                ? experienceRequired(for: previousPokemon.level, speciesID: previousPokemon.speciesID)
                : experienceRequired(for: previousPokemon.level + 1, speciesID: previousPokemon.speciesID),
            endLevelStart: experienceRequired(for: updatedPokemon.level, speciesID: updatedPokemon.speciesID),
            endNextLevel: updatedPokemon.level >= 100
                ? experienceRequired(for: updatedPokemon.level, speciesID: updatedPokemon.speciesID)
                : experienceRequired(for: updatedPokemon.level + 1, speciesID: updatedPokemon.speciesID)
        )
    }

    func presentBattleMessages(
        _ messages: [String],
        battle: inout RuntimeBattleState,
        phase: RuntimeBattlePhase = .turnText,
        pendingAction: RuntimeBattlePendingAction
    ) {
        battle.pendingAction = pendingAction
        battle.phase = phase
        battle.queuedMessages = messages
        battle.message = messages.first ?? battlePrompt(for: .moveSelection)
        if battle.queuedMessages.isEmpty == false {
            battle.queuedMessages.removeFirst()
        }
    }

    func advanceBattleText(battle: inout RuntimeBattleState) {
        if let nextMessage = battle.queuedMessages.first {
            battle.message = nextMessage
            battle.queuedMessages.removeFirst()
            return
        }

        guard let pendingAction = battle.pendingAction else {
            returnToBattleMoveSelection(battle: &battle)
            return
        }

        battle.pendingAction = nil
        switch pendingAction {
        case .moveSelection:
            returnToBattleMoveSelection(battle: &battle)
            if battle.presentation.stage == .introReveal {
                battle.presentation.stage = .commandReady
                battle.presentation.revision += 1
                battle.presentation.transitionStyle = .none
                battle.presentation.uiVisibility = .visible
            }
        case let .finish(won):
            battle.phase = .battleComplete
            finishBattle(battle: battle, won: won)
        case .escape:
            finishWildBattleEscape()
        case .captured:
            finishWildBattleCapture(battle: battle)
        case .capturedNicknamePrompt:
            beginNamingAfterCapture(battle: battle)
        case .continueSwitchTurn:
            continueSwitchTurnAfterPlayerSwap(battle: &battle)
        case .continueForcedSwitch:
            guard let gameplayState,
                  let firstSwitchableIndex = firstSwitchablePartyIndex(gameplayState: gameplayState) else {
                battle.phase = .battleComplete
                finishBattle(battle: battle, won: false)
                return
            }
            battle.focusedPartyIndex = firstSwitchableIndex
            enterForcedBattleSwitchSelection(battle: &battle, gameplayState: gameplayState)
        case .continueLevelUpResolution:
            continueLevelUpResolution(battle: &battle)
        }
    }

    func attemptBattleEscape(battle: inout RuntimeBattleState) {
        battle.phase = .resolvingTurn
        updateBattlePresentation(
            battle: &battle,
            stage: .resultText,
            uiVisibility: .visible,
            activeSide: nil,
            meterAnimation: nil,
            transitionStyle: .none
        )
        scheduleBattlePresentation(
            [
                .init(
                    delay: battlePresentationDelay(base: 0),
                    stage: .resultText,
                    uiVisibility: .visible,
                    message: "Got away safely!",
                    phase: .turnText
                ),
                .init(
                    delay: battlePresentationDelay(base: 0.32),
                    stage: .turnSettle,
                    uiVisibility: .visible,
                    escapeBattle: true
                ),
            ],
            battleID: battle.battleID
        )
    }

    func scheduleNextEnemySendOut(battle: inout RuntimeBattleState, nextIndex: Int) {
        guard battle.enemyParty.indices.contains(nextIndex) else {
            returnToBattleMoveSelection(battle: &battle)
            return
        }

        let nextEnemy = battle.enemyParty[nextIndex]
        battle.phase = .resolvingTurn
        battle.pendingAction = nil
        battle.pendingPresentationBatches = []
        battle.queuedMessages = []
        battle.message = ""

        scheduleBattlePresentation(
            [
                .init(
                    delay: battlePresentationDelay(base: 0.34),
                    stage: .enemySendOut,
                    uiVisibility: .visible,
                    activeSide: .enemy,
                    message: "\(battle.trainerName) sent out \(nextEnemy.nickname)!",
                    enemyParty: battle.enemyParty,
                    enemyActiveIndex: nextIndex
                ),
                commandReadyBeat(
                    delay: battlePresentationDelay(base: 0.26),
                    playerPokemon: battle.playerPokemon
                ),
            ],
            battleID: battle.battleID
        )
    }
}
