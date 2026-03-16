import Foundation
import PokeAudio
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
        if side == .player {
            return forcedMoveIndex(for: playerPokemon) ?? battle.focusedMoveIndex
        }
        return selectEnemyMoveIndex(battle: battle, enemyPokemon: enemyPokemon, playerPokemon: playerPokemon)
    }

    func peekActionMoveIndex(
        for side: BattlePresentationSide,
        battle: RuntimeBattleState,
        playerPokemon: RuntimePokemonState,
        enemyPokemon: RuntimePokemonState
    ) -> Int {
        let savedBattleRandomOverrides = battleRandomOverrides
        let savedRuntimeRNGState = runtimeRNGState
        let moveIndex = resolveActionMoveIndex(
            for: side,
            battle: battle,
            playerPokemon: playerPokemon,
            enemyPokemon: enemyPokemon
        )
        battleRandomOverrides = savedBattleRandomOverrides
        runtimeRNGState = savedRuntimeRNGState
        return moveIndex
    }

    func consumeActionMoveSelectionRandomnessIfNeeded(
        for side: BattlePresentationSide,
        battle: RuntimeBattleState,
        playerPokemon: RuntimePokemonState,
        enemyPokemon: RuntimePokemonState
    ) {
        guard side == .enemy else {
            return
        }

        // Preserve the selection RNG burn while still executing the move that
        // was already peeked for ordering.
        _ = resolveActionMoveIndex(
            for: side,
            battle: battle,
            playerPokemon: playerPokemon,
            enemyPokemon: enemyPokemon
        )
    }

    func turnActionOrder(
        playerPokemon: RuntimePokemonState,
        enemyPokemon: RuntimePokemonState,
        playerMoveIndex: Int,
        enemyMoveIndex: Int
    ) -> [BattlePresentationSide] {
        let playerMoveID = playerPokemon.moves.indices.contains(playerMoveIndex) ? playerPokemon.moves[playerMoveIndex].id : nil
        let enemyMoveID = enemyPokemon.moves.indices.contains(enemyMoveIndex) ? enemyPokemon.moves[enemyMoveIndex].id : nil

        if playerMoveID == "COUNTER", enemyMoveID != "COUNTER" {
            return [.enemy, .player]
        }

        if enemyMoveID == "COUNTER", playerMoveID != "COUNTER" {
            return [.player, .enemy]
        }

        return adjustedSpeedStat(for: playerPokemon) >= adjustedSpeedStat(for: enemyPokemon)
            ? [.player, .enemy]
            : [.enemy, .player]
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
            batches.append(
                playerDefeatResolutionBatch(
                    faintedPlayer: simulatedPlayer,
                    activePartyIndex: battle.playerActiveIndex
                )
            )
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

    func appendResidualResolutionIfNeeded(
        actingSide: BattlePresentationSide,
        battle: RuntimeBattleState,
        simulatedPlayer: inout RuntimePokemonState,
        simulatedEnemy: inout RuntimePokemonState,
        batches: inout [[RuntimeBattlePresentationBeat]]
    ) -> Bool {
        var actingPokemon = actingSide == .player ? simulatedPlayer : simulatedEnemy
        var opposingPokemon = actingSide == .player ? simulatedEnemy : simulatedPlayer
        let messages = applyResidualBattleEffects(to: &actingPokemon, opponent: &opposingPokemon)

        if actingSide == .player {
            simulatedPlayer = actingPokemon
            simulatedEnemy = opposingPokemon
        } else {
            simulatedEnemy = actingPokemon
            simulatedPlayer = opposingPokemon
        }

        guard messages.isEmpty == false else {
            return false
        }

        batches.append(
            makeResidualMessageBatch(
                actingSide: actingSide,
                messages: messages,
                playerPokemon: simulatedPlayer,
                enemyPokemon: simulatedEnemy
            )
        )

        if simulatedPlayer.currentHP == 0 {
            batches.append(
                playerDefeatResolutionBatch(
                    faintedPlayer: simulatedPlayer,
                    activePartyIndex: battle.playerActiveIndex
                )
            )
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

    func makeResidualMessageBatch(
        actingSide: BattlePresentationSide,
        messages: [String],
        playerPokemon: RuntimePokemonState,
        enemyPokemon: RuntimePokemonState
    ) -> [RuntimeBattlePresentationBeat] {
        messages.enumerated().map { index, message in
            .init(
                delay: battlePresentationDelay(base: index == 0 ? 0.22 : 0.18),
                stage: .resultText,
                uiVisibility: .visible,
                activeSide: actingSide,
                requiresConfirmAfterDisplay: true,
                message: message,
                phase: .turnText,
                playerPokemon: index == 0 ? playerPokemon : nil,
                enemyPokemon: index == 0 ? enemyPokemon : nil
            )
        }
    }

    func playerDefeatResolutionBatch(
        faintedPlayer: RuntimePokemonState,
        activePartyIndex: Int
    ) -> [RuntimeBattlePresentationBeat] {
        let pendingAction: RuntimeBattlePendingAction = hasSwitchableBattleReplacement(
            afterFainting: faintedPlayer,
            activePartyIndex: activePartyIndex
        ) ? .continueForcedSwitch : .finish(won: false)

        return [
            .init(
                delay: battlePresentationDelay(base: 0.18),
                stage: .turnSettle,
                uiVisibility: .visible,
                phase: .turnText,
                pendingAction: pendingAction,
                playerPokemon: faintedPlayer
            ),
        ]
    }

    func hasSwitchableBattleReplacement(
        afterFainting faintedPlayer: RuntimePokemonState,
        activePartyIndex: Int
    ) -> Bool {
        guard var gameplayState, gameplayState.playerParty.isEmpty == false else {
            return false
        }

        if gameplayState.playerParty.indices.contains(activePartyIndex) {
            gameplayState.playerParty[activePartyIndex] = faintedPlayer
        }
        return firstSwitchablePartyIndex(
            gameplayState: gameplayState,
            excluding: activePartyIndex
        ) != nil
    }

    func battlePresentationDelay(base: TimeInterval) -> TimeInterval {
        let scale: Double = validationMode || isTestEnvironment ? 0.12 : 1.0
        return max(0, base * scale)
    }

    func makeAttackAnimationPlayback(
        for action: ResolvedBattleAction,
        moveAnimation: BattleMoveAnimationManifest
    ) -> BattleAttackAnimationPlaybackTelemetry {
        .init(
            playbackID: UUID().uuidString,
            moveID: action.moveID,
            attackerSide: action.side,
            totalDuration: battlePresentationDelay(base: attackAnimationBaseDuration(for: moveAnimation))
        )
    }

    func attackAnimationBaseDuration(for moveAnimation: BattleMoveAnimationManifest) -> TimeInterval {
        let totalFrames = moveAnimation.commands.reduce(0) { partialResult, command in
            partialResult + attackAnimationCommandFrameCount(command)
        }
        return Double(max(1, totalFrames)) / BattleAnimationPlaybackDefaults.framesPerSecond
    }

    func attackAnimationSoundEffectRequests(
        for moveAnimation: BattleMoveAnimationManifest,
        attackerSpeciesID: String
    ) -> [RuntimeStagedSoundEffectRequest] {
        var elapsedBaseTime: TimeInterval = 0
        var requests: [RuntimeStagedSoundEffectRequest] = []

        for command in moveAnimation.commands {
            if let soundMoveID = command.soundMoveID,
               let move = content.move(id: soundMoveID),
               let request = moveSoundEffectRequest(for: move, attackerSpeciesID: attackerSpeciesID) {
                requests.append(
                    RuntimeStagedSoundEffectRequest(
                        delay: battlePresentationDelay(base: elapsedBaseTime),
                        request: request
                    )
                )
            }
            let commandFrames = attackAnimationCommandFrameCount(command)
            elapsedBaseTime += Double(commandFrames) / BattleAnimationPlaybackDefaults.framesPerSecond
        }

        return requests
    }

    func attackAnimationCommandFrameCount(_ command: BattleAnimationCommandManifest) -> Int {
        switch command.kind {
        case .specialEffect:
            return BattleAnimationPlaybackDefaults.specialEffectFrameCount(id: command.specialEffectID)
        case .subanimation:
            let delayFrames = max(1, command.delayFrames ?? 1)
            guard let subanimationID = command.subanimationID,
                  let subanimation = content.battleAnimationSubanimation(id: subanimationID),
                  subanimation.steps.isEmpty == false else {
                return delayFrames
            }
            let totalFrames = subanimation.steps.reduce(0) { partialResult, step in
                partialResult + (step.frameBlockMode == .mode02 ? 0 : delayFrames)
            }
            return max(1, totalFrames)
        }
    }

    func makeApplyingHitEffect(
        for action: ResolvedBattleAction,
        move: MoveManifest
    ) -> BattleApplyingHitEffectTelemetry? {
        guard let kind = applyingHitEffectKind(for: action, move: move) else {
            return nil
        }

        let frameCount = BattleApplyingHitEffectPlaybackDefaults.frameCount(for: kind)
        return .init(
            playbackID: UUID().uuidString,
            kind: kind,
            attackerSide: action.side,
            totalDuration: battlePresentationDelay(
                base: Double(frameCount) / BattleApplyingHitEffectPlaybackDefaults.framesPerSecond
            )
        )
    }

    func applyingHitEffectKind(
        for action: ResolvedBattleAction,
        move: MoveManifest
    ) -> BattleApplyingHitEffectKind? {
        guard action.didExecuteMove else {
            return nil
        }

        let moveFailed = action.messages.contains { message in
            message == "But it failed!" ||
                message == "But it missed!" ||
                message.hasPrefix("It doesn't affect ")
        }
        guard moveFailed == false else {
            return nil
        }

        if move.power > 0 {
            guard action.dealtDamage > 0 else {
                return nil
            }

            if moveHasAdditionalAttackFeedback(effect: move.effect) {
                return action.side == .player ? .shakeScreenHorizontalLight : .shakeScreenHorizontalHeavy
            }
            return action.side == .player ? .blinkDefender : .shakeScreenVertical
        }

        return action.side == .player ? .shakeScreenHorizontalSlow2 : .shakeScreenHorizontalSlow
    }

    func moveHasAdditionalAttackFeedback(effect: String) -> Bool {
        if let descriptor = statStageEffectDescriptor(for: effect), descriptor.isSideEffect {
            return true
        }

        if Self.burnSideEffects.contains(effect) ||
            Self.freezeSideEffects.contains(effect) ||
            Self.paralysisSideEffects.contains(effect) ||
            Self.poisonSideEffects.contains(effect) ||
            Self.flinchSideEffects.contains(effect) {
            return true
        }

        switch effect {
        case "CONFUSION_SIDE_EFFECT", "PAY_DAY_EFFECT":
            return true
        default:
            return false
        }
    }

    private func cancelBattlePresentationTask() {
        battlePresentationTask?.cancel()
        battlePresentationTask = nil
    }

    private func cancelBattlePresentationStagedSoundTasks() {
        for task in battlePresentationStagedSoundTasks.values {
            task.cancel()
        }
        battlePresentationStagedSoundTasks.removeAll()
    }

    func cancelBattlePresentation() {
        cancelBattlePresentationTask()
        cancelBattlePresentationStagedSoundTasks()
    }

    func scheduleBattlePresentationStagedSoundEffect(
        _ stagedSoundEffectRequest: RuntimeStagedSoundEffectRequest,
        battleID: String,
        stage: BattlePresentationStage
    ) {
        let taskID = UUID()
        let task = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(stagedSoundEffectRequest.delay * 1_000_000_000))
            guard Task.isCancelled == false else { return }
            self?.playBattlePresentationStagedSoundEffect(
                taskID: taskID,
                stagedSoundEffectRequest: stagedSoundEffectRequest,
                battleID: battleID,
                stage: stage
            )
        }
        battlePresentationStagedSoundTasks[taskID] = task
    }

    func playBattlePresentationStagedSoundEffect(
        taskID: UUID,
        stagedSoundEffectRequest: RuntimeStagedSoundEffectRequest,
        battleID: String,
        stage: BattlePresentationStage
    ) {
        defer {
            battlePresentationStagedSoundTasks.removeValue(forKey: taskID)
        }

        guard let activeBattle = gameplayState?.battle,
              activeBattle.battleID == battleID else {
            return
        }

        _ = playSoundEffect(
            stagedSoundEffectRequest.request,
            reason: "battlePresentation.\(stage.rawValue).delayed"
        )
    }

    func updateBattlePresentation(
        battle: inout RuntimeBattleState,
        stage: BattlePresentationStage,
        uiVisibility: BattlePresentationUIVisibility,
        activeSide: BattlePresentationSide?,
        hidePlayerPokemon: Bool = false,
        meterAnimation: BattleMeterAnimationTelemetry?,
        transitionStyle: BattleTransitionStyle,
        attackAnimation: BattleAttackAnimationPlaybackTelemetry? = nil,
        applyingHitEffect: BattleApplyingHitEffectTelemetry? = nil
    ) {
        battle.presentation.stage = stage
        battle.presentation.revision += 1
        battle.presentation.uiVisibility = uiVisibility
        battle.presentation.activeSide = activeSide
        battle.presentation.hidePlayerPokemon = hidePlayerPokemon
        battle.presentation.meterAnimation = meterAnimation
        battle.presentation.transitionStyle = transitionStyle
        battle.presentation.attackAnimation = attackAnimation
        battle.presentation.applyingHitEffect = applyingHitEffect
    }

    func advanceBattlePresentationBatch(battle: inout RuntimeBattleState) {
        guard battle.pendingPresentationBatches.isEmpty == false else { return }
        let nextBatch = battle.pendingPresentationBatches.removeFirst()
        battle.phase = .resolvingTurn
        scheduleBattlePresentation(nextBatch, battleID: battle.battleID)
    }

    func scheduleBattlePresentation(_ beats: [RuntimeBattlePresentationBeat], battleID: String) {
        cancelBattlePresentationTask()
        guard beats.isEmpty == false else { return }

        battlePresentationTask = Task { [self] in
            for (index, beat) in beats.enumerated() {
                if beat.delay > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(beat.delay * 1_000_000_000))
                }
                guard Task.isCancelled == false else { return }
                applyBattlePresentationBeat(beat, battleID: battleID)

                if beat.requiresConfirmAfterDisplay {
                    let remainingBeats = Array(beats.dropFirst(index + 1))
                    if remainingBeats.isEmpty == false {
                        prependBattlePresentationBeats(remainingBeats, battleID: battleID)
                    }
                    battlePresentationTask = nil
                    return
                }
            }

            battlePresentationTask = nil
            autoAdvanceBattlePresentationIfNeeded(battleID: battleID)
        }
    }

    func autoAdvanceBattlePresentationIfNeeded(battleID: String) {
        guard var gameplayState,
              var battle = gameplayState.battle,
              battle.battleID == battleID,
              battle.pendingPresentationBatches.isEmpty == false,
              battle.pendingAction == nil,
              battle.phase != .moveSelection,
              battle.phase != .bagSelection,
              battle.phase != .partySelection,
              battle.phase != .trainerAboutToUseDecision,
              battle.phase != .learnMoveDecision,
              battle.phase != .learnMoveSelection,
              battle.phase != .battleComplete else {
            return
        }

        let nextBatch = battle.pendingPresentationBatches.removeFirst()
        battle.phase = .resolvingTurn
        gameplayState.battle = battle
        self.gameplayState = gameplayState
        scheduleBattlePresentation(nextBatch, battleID: battleID)
    }

    func prependBattlePresentationBeats(_ beats: [RuntimeBattlePresentationBeat], battleID: String) {
        guard var gameplayState, var battle = gameplayState.battle, battle.battleID == battleID else {
            return
        }

        battle.pendingPresentationBatches.insert(beats, at: 0)
        gameplayState.battle = battle
        self.gameplayState = gameplayState
        publishSnapshot()
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
        if let pendingEvolution = beat.pendingEvolution {
            battle.pendingEvolution = pendingEvolution
        }
        if let playerPokemon = beat.playerPokemon {
            battle.playerPokemon = playerPokemon
        }
        if let enemyPokemon = beat.enemyPokemon {
            battle.enemyPokemon = enemyPokemon
        }
        if let enemyParty = beat.enemyParty, let enemyActiveIndex = beat.enemyActiveIndex {
            let previousEnemyIndex = battle.enemyActiveIndex
            let previousSpeciesID = battle.enemyPokemon.speciesID
            battle.enemyParty = enemyParty
            battle.enemyActiveIndex = enemyActiveIndex
            let nextSpeciesID = enemyParty[enemyActiveIndex].speciesID
            if previousEnemyIndex != enemyActiveIndex || previousSpeciesID != nextSpeciesID {
                recordSpeciesEncounter(nextSpeciesID, in: &gameplayState)
            }
        }
        if let soundEffectRequest = beat.soundEffectRequest {
            _ = playSoundEffect(
                soundEffectRequest,
                reason: "battlePresentation.\(beat.stage.rawValue)"
            )
        }
        for stagedSoundEffectRequest in beat.stagedSoundEffectRequests {
            scheduleBattlePresentationStagedSoundEffect(
                stagedSoundEffectRequest,
                battleID: battleID,
                stage: beat.stage
            )
        }
        if let audioCueID = beat.audioCueID {
            requestAudioCue(
                id: audioCueID,
                reason: "battlePresentation.\(beat.stage.rawValue)"
            )
        }

        updateBattlePresentation(
            battle: &battle,
            stage: beat.stage,
            uiVisibility: beat.uiVisibility,
            activeSide: beat.activeSide,
            hidePlayerPokemon: beat.hidePlayerPokemon,
            meterAnimation: beat.meterAnimation,
            transitionStyle: beat.transitionStyle,
            attackAnimation: beat.attackAnimation,
            applyingHitEffect: beat.applyingHitEffect
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
        requiresConfirmAfterReveal: Bool = false,
        pendingActionAfterReveal: RuntimeBattlePendingAction? = nil,
        revealSoundEffectRequest: SoundEffectPlaybackRequest? = nil
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
                phase: requiresConfirmAfterReveal || pendingActionAfterReveal != nil ? .turnText : .introText,
                pendingAction: pendingActionAfterReveal ?? (requiresConfirmAfterReveal ? .moveSelection : nil),
                soundEffectRequest: revealSoundEffectRequest
            ),
        ]

        if requiresConfirmAfterReveal == false && pendingActionAfterReveal == nil {
            beats.append(commandReadyBeat(delay: battlePresentationDelay(base: 0.18)))
        }

        return beats
    }

    func makeTurnPresentationBatches(for battle: inout RuntimeBattleState) -> [[RuntimeBattlePresentationBeat]] {
        var simulatedPlayer = battle.playerPokemon
        var simulatedEnemy = battle.enemyPokemon
        var batches: [[RuntimeBattlePresentationBeat]] = []
        let playerMoveIndex = resolveActionMoveIndex(
            for: .player,
            battle: battle,
            playerPokemon: simulatedPlayer,
            enemyPokemon: simulatedEnemy
        )
        let enemyMoveIndex = peekActionMoveIndex(
            for: .enemy,
            battle: battle,
            playerPokemon: simulatedPlayer,
            enemyPokemon: simulatedEnemy
        )
        let actionSides = turnActionOrder(
            playerPokemon: simulatedPlayer,
            enemyPokemon: simulatedEnemy,
            playerMoveIndex: playerMoveIndex,
            enemyMoveIndex: enemyMoveIndex
        )

        for side in actionSides {
            consumeActionMoveSelectionRandomnessIfNeeded(
                for: side,
                battle: battle,
                playerPokemon: simulatedPlayer,
                enemyPokemon: simulatedEnemy
            )
            let moveIndex = side == .player
                ? playerMoveIndex
                : enemyMoveIndex
            let action = resolveBattleAction(
                side: side,
                attacker: side == .player ? simulatedPlayer : simulatedEnemy,
                defender: side == .player ? simulatedEnemy : simulatedPlayer,
                moveIndex: moveIndex,
                defenderCanActLaterInTurn: side != actionSides.last
            )
            var actionBeats = makeBeats(for: action)
            if let pendingAction = action.pendingAction,
               actionBeats.isEmpty == false {
                actionBeats[actionBeats.count - 1].pendingAction = pendingAction
            }
            batches.append(actionBeats)
            applyResolvedBattleAction(
                action,
                side: side,
                simulatedPlayer: &simulatedPlayer,
                simulatedEnemy: &simulatedEnemy
            )

            if side == .player, action.payDayMoneyGain > 0 {
                battle.payDayMoney += action.payDayMoneyGain
            }

            if side == .enemy {
                battle.aiLayer2Encouragement += 1
            }

            if action.pendingAction != nil {
                return batches
            }

            if appendPostActionResolutionIfNeeded(
                battle: battle,
                simulatedPlayer: &simulatedPlayer,
                simulatedEnemy: simulatedEnemy,
                batches: &batches
            ) {
                return batches
            }

            if appendResidualResolutionIfNeeded(
                actingSide: side,
                battle: battle,
                simulatedPlayer: &simulatedPlayer,
                simulatedEnemy: &simulatedEnemy,
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

        if action.didExecuteMove == false {
            return action.messages.enumerated().map { index, message in
                .init(
                    delay: battlePresentationDelay(base: index == 0 ? 0 : 0.18),
                    stage: .resultText,
                    uiVisibility: .visible,
                    activeSide: action.side,
                    requiresConfirmAfterDisplay: true,
                    message: message,
                    phase: .turnText,
                    playerPokemon: index == 0 ? (action.side == .player ? action.updatedAttacker : action.updatedDefender) : nil,
                    enemyPokemon: index == 0 ? (action.side == .enemy ? action.updatedAttacker : action.updatedDefender) : nil
                )
            }
        }

        let move = content.move(id: action.moveID)
        let moveMissed = action.messages.contains("But it missed!")
        let skipAnimation = optionsBattleAnimation == .off
        let sourceMoveAnimation = skipAnimation || moveMissed ? nil : content.battleAnimation(moveID: action.moveID)
        let attackAnimationPlayback = sourceMoveAnimation.map {
            makeAttackAnimationPlayback(for: action, moveAnimation: $0)
        }
        let stagedAttackSoundEffectRequests = sourceMoveAnimation.map {
            attackAnimationSoundEffectRequests(
                for: $0,
                attackerSpeciesID: action.attackerSpeciesID
            )
        } ?? []
        let moveAudioRequest: SoundEffectPlaybackRequest?
        if let move = content.move(id: action.moveID) {
            moveAudioRequest = moveSoundEffectRequest(
                for: move,
                attackerSpeciesID: action.attackerSpeciesID
            )
        } else {
            moveAudioRequest = nil
        }
        let applyingHitEffect = move.flatMap {
            makeApplyingHitEffect(for: action, move: $0)
        }
        let fallbackMovePlaybackDelay = battlePresentationDelay(base: 30.0 / 60.0)
        let movePlaybackDelay: TimeInterval
        if moveMissed {
            movePlaybackDelay = 0
        } else {
            movePlaybackDelay = attackAnimationPlayback?.totalDuration ?? fallbackMovePlaybackDelay
        }
        let windupSoundEffectRequest = moveMissed ? nil : (attackAnimationPlayback == nil ? moveAudioRequest : nil)
        let movePhaseSoundEffectRequests = stagedAttackSoundEffectRequests.map(\.request) + (windupSoundEffectRequest.map { [$0] } ?? [])
        let impactSoundEffectRequest = action.dealtDamage > 0
            ? applyingHitSoundEffectRequest(typeMultiplier: action.typeMultiplier)
            : nil
        let resolvedApplyingHitSoundEffectRequest = impactSoundEffectRequest.flatMap { request in
            movePhaseSoundEffectRequests.contains(request) ? nil : request
        }
        var beats: [RuntimeBattlePresentationBeat] = [
            .init(
                delay: 0,
                stage: .resultText,
                uiVisibility: .visible,
                activeSide: action.side,
                requiresConfirmAfterDisplay: true,
                message: action.messages.first,
                phase: .turnText,
                playerPokemon: attackerPokemon,
                enemyPokemon: enemyAttacker
            ),
        ]

        if moveMissed == false && (skipAnimation == false || windupSoundEffectRequest != nil) {
            beats.append(
                .init(
                    delay: skipAnimation ? 0 : battlePresentationDelay(base: 3.0 / 60.0),
                    stage: .attackWindup,
                    uiVisibility: .visible,
                    activeSide: action.side,
                    attackAnimation: attackAnimationPlayback,
                    phase: .resolvingTurn,
                    soundEffectRequest: windupSoundEffectRequest,
                    stagedSoundEffectRequests: stagedAttackSoundEffectRequests
                )
            )
        }

        if let applyingHitEffect {
            beats.append(
                .init(
                    delay: movePlaybackDelay,
                    stage: .attackImpact,
                    uiVisibility: .visible,
                    activeSide: action.side,
                    applyingHitEffect: applyingHitEffect,
                    soundEffectRequest: resolvedApplyingHitSoundEffectRequest
                )
            )
        }

        let trailingMessages = Array(action.messages.dropFirst())
        let postAttackDelay = applyingHitEffect?.totalDuration ?? movePlaybackDelay
        if action.dealtDamage > 0 {
            beats.append(
                .init(
                    delay: postAttackDelay,
                    stage: .hpDrain,
                    uiVisibility: .visible,
                    activeSide: action.side == .player ? .enemy : .player,
                    meterAnimation: hpMeterAnimation(for: action),
                    playerPokemon: defenderMutationPlayer,
                    enemyPokemon: defenderMutationEnemy
                )
            )
        } else if trailingMessages.isEmpty == false {
            let statusMessage = trailingMessages.first
            beats.append(
                .init(
                    delay: postAttackDelay,
                    stage: .resultText,
                    uiVisibility: .visible,
                    activeSide: action.side == .player ? .enemy : .player,
                    requiresConfirmAfterDisplay: statusMessage != nil,
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
            let isFaintMessage = message.contains("fainted!")
            guard isFaintMessage else {
                beats.append(
                    .init(
                        delay: battlePresentationDelay(base: 0.24),
                        stage: .resultText,
                        uiVisibility: .visible,
                        activeSide: action.side == .player ? .enemy : .player,
                        requiresConfirmAfterDisplay: true,
                        message: message
                    )
                )
                continue
            }

            let faintSide: BattlePresentationSide = action.side == .player ? .enemy : .player
            let displayMessage = action.side == .player
                ? enemyFaintedText(for: action.updatedDefender)
                : playerFaintedText(for: action.updatedDefender)
            let soundEffectRequests = action.side == .player
                ? enemyFaintSoundEffectRequests()
                : speciesCrySoundEffectRequest(speciesID: action.updatedDefender.speciesID).map { [$0] } ?? []

            beats.append(
                .init(
                    delay: battlePresentationDelay(base: 0.24),
                    stage: .faint,
                    uiVisibility: .visible,
                    activeSide: faintSide,
                    soundEffectRequest: soundEffectRequests.first
                )
            )

            for soundEffectRequest in soundEffectRequests.dropFirst() {
                beats.append(
                    .init(
                        delay: battlePresentationDelay(base: 0.3),
                        stage: .faint,
                        uiVisibility: .visible,
                        activeSide: faintSide,
                        soundEffectRequest: soundEffectRequest
                    )
                )
            }

            beats.append(
                .init(
                    delay: battlePresentationDelay(base: 0.24),
                    stage: .resultText,
                    uiVisibility: .visible,
                    activeSide: faintSide,
                    requiresConfirmAfterDisplay: true,
                    message: displayMessage
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
        pendingAction: RuntimeBattlePendingAction,
        audioCueID: String? = nil
    ) {
        if let audioCueID {
            requestAudioCue(id: audioCueID, reason: "battleText")
        }
        let pagedMessages = paginatedBattleMessages(messages)
        battle.pendingAction = pendingAction
        battle.phase = phase
        battle.queuedMessages = pagedMessages
        battle.message = pagedMessages.first ?? battlePrompt(for: .moveSelection)
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
            if battle.presentation.stage != .commandReady {
                battle.presentation.stage = .commandReady
                battle.presentation.revision += 1
                battle.presentation.transitionStyle = .none
                battle.presentation.uiVisibility = .visible
            }
            return
        }

        battle.pendingAction = nil
        switch pendingAction {
        case .moveSelection:
            returnToBattleMoveSelection(battle: &battle)
            if battle.presentation.stage != .commandReady {
                battle.presentation.stage = .commandReady
                battle.presentation.revision += 1
                battle.presentation.transitionStyle = .none
                battle.presentation.uiVisibility = .visible
            }
        case let .finish(won):
            if awardPayDayIfNeeded(battle: &battle, pendingAction: .finish(won: won)) {
                break
            }
            if won == false, shouldBlackoutOnLoss(for: battle) {
                beginBlackoutSequence(battle: &battle)
            } else {
                battle.phase = .battleComplete
                finishBattle(battle: battle, won: won)
            }
        case let .performBlackout(sourceTrainerObjectID):
            performBlackout(sourceTrainerObjectID: sourceTrainerObjectID)
        case .escape:
            if awardPayDayIfNeeded(battle: &battle, pendingAction: .escape) {
                break
            }
            finishWildBattleEscape()
        case let .captured(aftermath):
            if awardPayDayIfNeeded(battle: &battle, pendingAction: .captured(aftermath)) {
                break
            }
            beginCaptureAftermath(battle: battle, aftermath: aftermath)
        case let .enterTrainerAboutToUseDecision(nextIndex):
            enterTrainerAboutToUseDecision(battle: &battle, nextIndex: nextIndex)
        case let .completeTrainerVictory(payout):
            completeTrainerVictory(battle: battle, payout: payout)
        case .continueSwitchTurn:
            continueSwitchTurnAfterPlayerSwap(battle: &battle)
        case .continueForcedSwitch:
            guard let gameplayState,
                  let firstSwitchableIndex = firstSwitchablePartyIndex(
                      gameplayState: gameplayState,
                      excluding: battle.playerActiveIndex
                  ) else {
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

    func awardPayDayIfNeeded(
        battle: inout RuntimeBattleState,
        pendingAction: RuntimeBattlePendingAction
    ) -> Bool {
        guard battle.payDayMoney > 0,
              var gameplayState else {
            return false
        }

        let amount = battle.payDayMoney
        battle.payDayMoney = 0
        gameplayState.money += amount
        self.gameplayState = gameplayState
        presentBattleMessages(
            ["\(gameplayState.playerName) picked up ¥\(amount)!"],
            battle: &battle,
            pendingAction: pendingAction
        )
        return true
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

    func scheduleNextEnemySendOut(
        battle: inout RuntimeBattleState,
        nextIndex: Int,
        pendingAction: RuntimeBattlePendingAction = .moveSelection
    ) {
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
        battle.aiLayer2Encouragement = 0

        scheduleBattlePresentation(
            [
                .init(
                    delay: battlePresentationDelay(base: 0.34),
                    stage: .enemySendOut,
                    uiVisibility: .visible,
                    activeSide: .enemy,
                    message: trainerSentOutText(trainerName: battle.trainerName, pokemon: nextEnemy),
                    phase: .turnText,
                    pendingAction: pendingAction,
                    enemyParty: battle.enemyParty,
                    enemyActiveIndex: nextIndex,
                stagedSoundEffectRequests: sendOutSoundEffectRequests(
                    side: .enemy,
                    speciesID: nextEnemy.speciesID
                )
            ),
            ],
            battleID: battle.battleID
        )
    }

    func makePlayerSendOutBatch(
        playerPokemon: RuntimePokemonState,
        enemyPokemon: RuntimePokemonState,
        pendingAction: RuntimeBattlePendingAction? = nil
    ) -> [RuntimeBattlePresentationBeat] {
        [
            .init(
                delay: battlePresentationDelay(base: 0.34),
                stage: .enemySendOut,
                uiVisibility: .visible,
                activeSide: .player,
                message: playerSendOutText(for: playerPokemon, against: enemyPokemon),
                phase: .turnText,
                pendingAction: pendingAction,
                playerPokemon: playerPokemon,
                stagedSoundEffectRequests: sendOutSoundEffectRequests(
                    side: .player,
                    speciesID: playerPokemon.speciesID
                )
            ),
        ]
    }

    func makeTrainerOpeningSendOutBatches(
        battle: RuntimeBattleState
    ) -> [[RuntimeBattlePresentationBeat]] {
        [
            [
                .init(
                    delay: battlePresentationDelay(base: 0.34),
                    stage: .enemySendOut,
                    uiVisibility: .visible,
                    activeSide: .enemy,
                    hidePlayerPokemon: true,
                    message: trainerSentOutText(trainerName: battle.trainerName, pokemon: battle.enemyPokemon),
                    phase: .turnText,
                    enemyParty: battle.enemyParty,
                    enemyActiveIndex: battle.enemyActiveIndex,
                    stagedSoundEffectRequests: sendOutSoundEffectRequests(
                        side: .enemy,
                        speciesID: battle.enemyPokemon.speciesID
                    )
                ),
            ],
            makePlayerSendOutBatch(
                playerPokemon: battle.playerPokemon,
                enemyPokemon: battle.enemyPokemon
            )
        ]
    }

    func enterTrainerAboutToUseDecision(battle: inout RuntimeBattleState, nextIndex: Int) {
        guard battle.enemyParty.indices.contains(nextIndex) else {
            returnToBattleMoveSelection(battle: &battle)
            return
        }

        let message = trainerAboutToUseMessages(
            trainerName: battle.trainerName,
            pokemon: battle.enemyParty[nextIndex]
        ).last ?? trainerAboutToUseText(
            trainerName: battle.trainerName,
            pokemon: battle.enemyParty[nextIndex]
        )
        let previousMoveIndex = battle.focusedMoveIndex
        battle.phase = .trainerAboutToUseDecision
        battle.focusedMoveIndex = 1
        battle.rewardContinuation = .aboutToUse(index: nextIndex, previousMoveIndex: previousMoveIndex)
        battle.pendingAction = nil
        battle.pendingPresentationBatches = []
        battle.queuedMessages = []
        battle.message = paginatedBattleMessage(message).last ?? message
    }

    func completeTrainerVictory(battle: RuntimeBattleState, payout: Int) {
        if var gameplayState {
            gameplayState.money += payout
            self.gameplayState = gameplayState
        }
        finishBattle(battle: battle, won: true)
    }
}
