import Foundation
import PokeDataModel

struct ResolvedBattleMove {
    let messages: [String]
    let dealtDamage: Int
    let typeMultiplier: Int
}

struct ResolvedBattleAction {
    let side: BattlePresentationSide
    let moveID: String
    let attackerSpeciesID: String
    let updatedAttacker: RuntimePokemonState
    let updatedDefender: RuntimePokemonState
    let messages: [String]
    let dealtDamage: Int
    let defenderHPBefore: Int
    let defenderHPAfter: Int
}

struct BattleExperienceRewardResult {
    let messages: [String]
    let pendingLearnMove: RuntimeBattleLearnMoveState?
}

struct LevelUpMoveProcessingResult {
    let messages: [String]
    let pendingLearnMove: RuntimeBattleLearnMoveState?
}

extension GameRuntime {
    func handleBattle(button: RuntimeButton) {
        guard var gameplayState, var battle = gameplayState.battle else { return }

        switch button {
        case .up:
            switch battle.phase {
            case .moveSelection:
                battle.focusedMoveIndex = max(0, battle.focusedMoveIndex - 1)
            case .bagSelection:
                battle.focusedBagItemIndex = max(0, battle.focusedBagItemIndex - 1)
            case .learnMoveDecision, .learnMoveSelection:
                battle.focusedMoveIndex = max(0, battle.focusedMoveIndex - 1)
            default:
                break
            }
        case .down:
            switch battle.phase {
            case .moveSelection:
                battle.focusedMoveIndex = min(maxBattleActionIndex(for: battle), battle.focusedMoveIndex + 1)
            case .bagSelection:
                battle.focusedBagItemIndex = min(max(0, currentBattleBagItems.count - 1), battle.focusedBagItemIndex + 1)
            case .learnMoveDecision:
                battle.focusedMoveIndex = min(1, battle.focusedMoveIndex + 1)
            case .learnMoveSelection:
                battle.focusedMoveIndex = min(max(0, battle.playerPokemon.moves.count - 1), battle.focusedMoveIndex + 1)
            default:
                break
            }
        case .left:
            if battle.phase == .bagSelection {
                battle.focusedBagItemIndex = max(0, battle.focusedBagItemIndex - 1)
            }
        case .right:
            if battle.phase == .bagSelection {
                battle.focusedBagItemIndex = min(max(0, currentBattleBagItems.count - 1), battle.focusedBagItemIndex + 1)
            }
        case .cancel:
            switch battle.phase {
            case .moveSelection:
                guard battle.canRun else { break }
                playUIConfirmSound()
                attemptBattleEscape(battle: &battle)
            case .bagSelection:
                playUIConfirmSound()
                battle.phase = .moveSelection
                battle.message = "Pick the next move."
            case .learnMoveSelection:
                playUIConfirmSound()
                enterLearnMoveDecisionPrompt(battle: &battle)
            default:
                break
            }
        case .confirm, .start:
            switch battle.phase {
            case .introText:
                break
            case .turnText, .resolvingTurn:
                guard battlePresentationTask == nil else { break }
                playUIConfirmSound()
                if battle.pendingPresentationBatches.isEmpty == false {
                    advanceBattlePresentationBatch(battle: &battle)
                } else {
                    advanceBattleText(battle: &battle)
                }
            case .moveSelection:
                playUIConfirmSound()
                resolveBattleTurn(battle: &battle, gameplayState: &gameplayState)
            case .bagSelection:
                playUIConfirmSound()
                resolveBattleBagSelection(battle: &battle, gameplayState: &gameplayState)
            case .learnMoveDecision:
                playUIConfirmSound()
                resolveLearnMoveDecision(battle: &battle)
            case .learnMoveSelection:
                playUIConfirmSound()
                resolveLearnMoveSelection(battle: &battle)
            case .battleComplete:
                playUIConfirmSound()
                advanceBattleText(battle: &battle)
            }
        }

        guard scene == .battle, self.gameplayState?.battle != nil else {
            return
        }

        gameplayState.playerParty = syncedPlayerParty(from: battle, gameplayState: gameplayState)
        gameplayState.battle = battle
        self.gameplayState = gameplayState
        scene = .battle
        substate = "battle"
    }

    func finalizeStarterChoiceSequence() {
        guard var gameplayState, let speciesID = gameplayState.pendingStarterSpeciesID else { return }

        gameplayState.gotStarterBit = true
        gameplayState.chosenStarterSpeciesID = speciesID
        gameplayState.playerParty = [makePokemon(speciesID: speciesID, level: 5, nickname: speciesID.capitalized)]
        gameplayState.activeFlags.insert("EVENT_GOT_STARTER")
        let rivalSpeciesID = rivalStarter(for: speciesID)
        gameplayState.rivalStarterSpeciesID = rivalSpeciesID
        gameplayState.objectStates[selectedBallObjectID(for: speciesID)]?.visible = false
        self.gameplayState = gameplayState

        showDialogue(id: "oaks_lab_received_mon_\(speciesID.lowercased())", completion: .returnToField)
        queueDeferredActions([.script(rivalPickupScriptID(for: speciesID))])
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
            beats.append(
                .init(
                    delay: battlePresentationDelay(base: 0.18),
                    stage: .commandReady,
                    uiVisibility: .visible,
                    transitionStyle: .none,
                    message: "Pick the next move.",
                    phase: .moveSelection,
                    pendingAction: nil
                )
            )
        }

        return beats
    }

    func makeTurnPresentationBatches(for battle: RuntimeBattleState) -> [[RuntimeBattlePresentationBeat]] {
        var simulatedPlayer = battle.playerPokemon
        var simulatedEnemy = battle.enemyPokemon
        var batches: [[RuntimeBattlePresentationBeat]] = []

        let playerActsFirst = simulatedPlayer.speed >= simulatedEnemy.speed
        let firstSide: BattlePresentationSide = playerActsFirst ? .player : .enemy
        let firstMoveIndex = playerActsFirst
            ? battle.focusedMoveIndex
            : selectEnemyMoveIndex(enemyPokemon: simulatedEnemy, playerPokemon: simulatedPlayer)
        let firstAction = resolveBattleAction(
            side: firstSide,
            attacker: playerActsFirst ? simulatedPlayer : simulatedEnemy,
            defender: playerActsFirst ? simulatedEnemy : simulatedPlayer,
            moveIndex: firstMoveIndex
        )
        batches.append(makeBeats(for: firstAction))
        if firstSide == .player {
            simulatedPlayer = firstAction.updatedAttacker
            simulatedEnemy = firstAction.updatedDefender
        } else {
            simulatedEnemy = firstAction.updatedAttacker
            simulatedPlayer = firstAction.updatedDefender
        }

        if simulatedPlayer.currentHP == 0 {
            batches.append([
                .init(
                    delay: battlePresentationDelay(base: 0.28),
                    stage: .battleComplete,
                    uiVisibility: .visible,
                    finishBattleWon: false
                ),
            ])
            return batches
        }

        if simulatedEnemy.currentHP == 0 {
            let resolution = makeEnemyDefeatResolution(
                battle: battle,
                defeatedEnemy: simulatedEnemy,
                playerPokemon: simulatedPlayer
            )
            simulatedPlayer = resolution.updatedPlayer
            let resolutionBatch = resolution.beats
            if resolutionBatch.isEmpty == false {
                batches.append(resolutionBatch)
            }
            return batches
        }

        let secondSide: BattlePresentationSide = firstSide == .player ? .enemy : .player
        let secondMoveIndex = secondSide == .player
            ? battle.focusedMoveIndex
            : selectEnemyMoveIndex(enemyPokemon: simulatedEnemy, playerPokemon: simulatedPlayer)
        let secondAction = resolveBattleAction(
            side: secondSide,
            attacker: secondSide == .player ? simulatedPlayer : simulatedEnemy,
            defender: secondSide == .player ? simulatedEnemy : simulatedPlayer,
            moveIndex: secondMoveIndex
        )
        batches.append(makeBeats(for: secondAction))
        if secondSide == .player {
            simulatedPlayer = secondAction.updatedAttacker
            simulatedEnemy = secondAction.updatedDefender
        } else {
            simulatedEnemy = secondAction.updatedAttacker
            simulatedPlayer = secondAction.updatedDefender
        }

        if simulatedPlayer.currentHP == 0 {
            batches.append([
                .init(
                    delay: battlePresentationDelay(base: 0.28),
                    stage: .battleComplete,
                    uiVisibility: .visible,
                    finishBattleWon: false
                ),
            ])
            return batches
        }

        if simulatedEnemy.currentHP == 0 {
            let resolution = makeEnemyDefeatResolution(
                battle: battle,
                defeatedEnemy: simulatedEnemy,
                playerPokemon: simulatedPlayer
            )
            simulatedPlayer = resolution.updatedPlayer
            let resolutionBatch = resolution.beats
            if resolutionBatch.isEmpty == false {
                batches.append(resolutionBatch)
            }
            return batches
        }

        batches.append([
            .init(
                delay: battlePresentationDelay(base: 0.24),
                stage: .commandReady,
                uiVisibility: .visible,
                message: "Pick the next move.",
                phase: .moveSelection,
                playerPokemon: simulatedPlayer,
                enemyPokemon: simulatedEnemy
            ),
        ])
        return batches
    }

    func resolveBattleAction(
        side: BattlePresentationSide,
        attacker: RuntimePokemonState,
        defender: RuntimePokemonState,
        moveIndex: Int
    ) -> ResolvedBattleAction {
        var updatedAttacker = attacker
        var updatedDefender = defender
        let defenderHPBefore = defender.currentHP
        let moveID = attacker.moves[moveIndex].id
        let resolvedMove = applyMove(
            attacker: &updatedAttacker,
            defender: &updatedDefender,
            moveIndex: moveIndex,
            playsAudio: false
        )
        return ResolvedBattleAction(
            side: side,
            moveID: moveID,
            attackerSpeciesID: attacker.speciesID,
            updatedAttacker: updatedAttacker,
            updatedDefender: updatedDefender,
            messages: resolvedMove.messages,
            dealtDamage: resolvedMove.dealtDamage,
            defenderHPBefore: defenderHPBefore,
            defenderHPAfter: updatedDefender.currentHP
        )
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

    func resolveBattleTurn(battle: inout RuntimeBattleState, gameplayState: inout GameplayState) {
        guard battle.phase == .moveSelection else {
            return
        }

        if canUseBattleBag(for: battle), battle.focusedMoveIndex == bagActionIndex(for: battle) {
            battle.phase = .bagSelection
            battle.focusedBagItemIndex = 0
            battle.message = "Choose an item."
            return
        }

        if battle.canRun, battle.focusedMoveIndex == runActionIndex(for: battle) {
            attemptBattleEscape(battle: &battle)
            return
        }

        guard battle.playerPokemon.moves.indices.contains(battle.focusedMoveIndex) else {
            return
        }

        battle.phase = .resolvingTurn
        battle.pendingAction = nil
        battle.queuedMessages = []
        battle.pendingPresentationBatches = []
        battle.message = ""
        updateBattlePresentation(
            battle: &battle,
            stage: .attackWindup,
            uiVisibility: .visible,
            activeSide: nil,
            meterAnimation: nil,
            transitionStyle: .none
        )

        let batches = makeTurnPresentationBatches(for: battle)
        guard let firstBatch = batches.first else { return }
        battle.pendingPresentationBatches = Array(batches.dropFirst())
        scheduleBattlePresentation(firstBatch, battleID: battle.battleID)
    }

    func resolveBattleBagSelection(battle: inout RuntimeBattleState, gameplayState: inout GameplayState) {
        guard battle.phase == .bagSelection else { return }
        let bagItems = currentBattleBagItems
        guard bagItems.indices.contains(battle.focusedBagItemIndex) else {
            battle.phase = .moveSelection
            battle.message = "Pick the next move."
            return
        }

        let itemState = bagItems[battle.focusedBagItemIndex]
        guard let item = content.item(id: itemState.itemID), item.battleUse == .ball else {
            battle.phase = .moveSelection
            battle.message = "That item can't be used here."
            return
        }
        guard removeItem(item.id, quantity: 1, from: &gameplayState) else {
            battle.phase = .moveSelection
            battle.message = "No items left."
            return
        }

        if battle.kind != .wild {
            presentBattleMessages(
                ["Items can't be used here yet."],
                battle: &battle,
                pendingAction: .moveSelection
            )
            return
        }

        if gameplayState.playerParty.count >= 6,
           canSendCapturedPokemonToCurrentBox(gameplayState) == false {
            addItem(item.id, quantity: 1, to: &gameplayState)
            presentBattleMessages(
                ["The #MON BOX is full! Can't use that item!"],
                battle: &battle,
                pendingAction: .moveSelection
            )
            return
        }

        battle.phase = .resolvingTurn
        battle.pendingAction = nil

        if attemptWildCapture(battle: &battle, gameplayState: &gameplayState, item: item) {
            return
        }

        var enemyPokemon = battle.enemyPokemon
        var playerPokemon = battle.playerPokemon
        let enemyMoveIndex = selectEnemyMoveIndex(enemyPokemon: enemyPokemon, playerPokemon: playerPokemon)
        let enemyMove = applyMove(attacker: &enemyPokemon, defender: &playerPokemon, moveIndex: enemyMoveIndex)
        battle.enemyPokemon = enemyPokemon
        battle.playerPokemon = playerPokemon

        var messages = ["Aww! It appeared to be caught!"]
        messages.append(contentsOf: enemyMove.messages)
        if playerPokemon.currentHP == 0 {
            presentBattleMessages(messages, battle: &battle, pendingAction: .finish(won: false))
        } else {
            presentBattleMessages(messages, battle: &battle, pendingAction: .moveSelection)
        }
    }

    func applyMove(
        attacker: inout RuntimePokemonState,
        defender: inout RuntimePokemonState,
        moveIndex: Int,
        playsAudio: Bool = true
    ) -> ResolvedBattleMove {
        guard attacker.moves.indices.contains(moveIndex),
              attacker.moves[moveIndex].currentPP > 0,
              let move = content.move(id: attacker.moves[moveIndex].id) else {
            return ResolvedBattleMove(messages: [], dealtDamage: 0, typeMultiplier: 10)
        }

        attacker.moves[moveIndex].currentPP -= 1

        var messages = ["\(attacker.nickname) used \(move.displayName)!"]
        if playsAudio {
            _ = playMoveAudio(for: move, attackerSpeciesID: attacker.speciesID)
        }

        if move.accuracy > 0 {
            let hitChance = scaledAccuracy(
                baseAccuracyPercent: move.accuracy,
                accuracyStage: attacker.accuracyStage,
                evasionStage: defender.evasionStage
            )
            if nextBattleRandomByte() >= hitChance {
                messages.append("But it missed!")
                return ResolvedBattleMove(messages: messages, dealtDamage: 0, typeMultiplier: 10)
            }
        }

        var dealtDamage = 0
        let typeMultiplier = totalTypeMultiplier(for: move.type, defenderSpeciesID: defender.speciesID)

        if move.power > 0 {
            let isCriticalHit = isCriticalHit(for: attacker.speciesID)
            let adjustedAttack = adjustedAttackStat(for: attacker, criticalHit: isCriticalHit)
            let adjustedDefense = max(1, adjustedDefenseStat(for: defender, criticalHit: isCriticalHit))
            let battleLevel = isCriticalHit ? attacker.level * 2 : attacker.level
            var damage = max(1, (((((2 * battleLevel) / 5) + 2) * move.power * adjustedAttack) / adjustedDefense) / 50 + 2)

            if hasSTAB(attackerSpeciesID: attacker.speciesID, moveType: move.type) {
                damage += damage / 2
            }

            damage = applyTypeMultiplier(typeMultiplier, to: damage)
            dealtDamage = damage
            defender.currentHP = max(0, defender.currentHP - damage)

            if typeMultiplier == 0 {
                messages.append("It doesn't affect \(defender.nickname)!")
            } else {
                if isCriticalHit {
                    messages.append("Critical hit!")
                }
                if typeMultiplier > 10 {
                    messages.append("It's super effective!")
                } else if typeMultiplier < 10 {
                    messages.append("It's not very effective...")
                }
                if defender.currentHP == 0 {
                    messages.append("\(defender.nickname) fainted!")
                }
            }
        }

        messages.append(contentsOf: applyMoveEffect(move.effect, defender: &defender))
        return ResolvedBattleMove(messages: messages, dealtDamage: dealtDamage, typeMultiplier: typeMultiplier)
    }

    func applyMoveEffect(
        _ effect: String,
        defender: inout RuntimePokemonState
    ) -> [String] {
        switch effect {
        case "ATTACK_DOWN1_EFFECT":
            return applyStageDrop(
                to: &defender.attackStage,
                nickname: defender.nickname,
                statName: "Attack"
            )
        case "DEFENSE_DOWN1_EFFECT":
            return applyStageDrop(
                to: &defender.defenseStage,
                nickname: defender.nickname,
                statName: "Defense"
            )
        case "NO_ADDITIONAL_EFFECT":
            return []
        default:
            return []
        }
    }

    func applyStageDrop(to stage: inout Int, nickname: String, statName: String) -> [String] {
        guard stage > -6 else {
            return ["But it failed!"]
        }

        stage -= 1
        return ["\(nickname)'s \(statName) fell!"]
    }

    func selectEnemyMoveIndex(enemyPokemon: RuntimePokemonState, playerPokemon: RuntimePokemonState) -> Int {
        let availableMoves = enemyPokemon.moves.enumerated().filter { $0.element.currentPP > 0 }
        guard availableMoves.isEmpty == false else { return 0 }

        let bestDamagingScore = availableMoves.reduce(0) { partialResult, entry in
            guard let move = content.move(id: entry.element.id), move.power > 0 else { return partialResult }
            return max(partialResult, expectedMoveScore(move: move, attacker: enemyPokemon, defender: playerPokemon))
        }
        let bestDamagingMoveCanKO = availableMoves.contains { entry in
            guard let move = content.move(id: entry.element.id), move.power > 0 else { return false }
            return projectedDamage(move: move, attacker: enemyPokemon, defender: playerPokemon) >= playerPokemon.currentHP
        }

        var bestIndex = availableMoves[0].offset
        var bestScore = Int.min

        for entry in availableMoves {
            guard let move = content.move(id: entry.element.id) else { continue }
            let score: Int
            if move.power > 0 {
                score = expectedMoveScore(move: move, attacker: enemyPokemon, defender: playerPokemon)
            } else {
                score = statusMoveScore(
                    move: move,
                    attacker: enemyPokemon,
                    defender: playerPokemon,
                    bestDamagingScore: bestDamagingScore,
                    bestDamagingMoveCanKO: bestDamagingMoveCanKO
                )
            }

            if score > bestScore {
                bestScore = score
                bestIndex = entry.offset
            }
        }

        return bestIndex
    }

    func expectedMoveScore(move: MoveManifest, attacker: RuntimePokemonState, defender: RuntimePokemonState) -> Int {
        let damage = projectedDamage(move: move, attacker: attacker, defender: defender)
        let hitChance = move.accuracy > 0
            ? scaledAccuracy(
                baseAccuracyPercent: move.accuracy,
                accuracyStage: attacker.accuracyStage,
                evasionStage: defender.evasionStage
            )
            : 255
        let expectedScore = damage * hitChance
        let lethalityBonus = damage >= defender.currentHP ? 20_000 : 0
        return expectedScore + lethalityBonus
    }

    func statusMoveScore(
        move: MoveManifest,
        attacker: RuntimePokemonState,
        defender: RuntimePokemonState,
        bestDamagingScore: Int,
        bestDamagingMoveCanKO: Bool
    ) -> Int {
        let _ = attacker
        let targetStage: Int
        switch move.effect {
        case "ATTACK_DOWN1_EFFECT":
            targetStage = defender.attackStage
        case "DEFENSE_DOWN1_EFFECT":
            targetStage = defender.defenseStage
        default:
            return Int.min / 2
        }

        guard targetStage > -6 else {
            return Int.min / 2
        }

        if bestDamagingMoveCanKO {
            return bestDamagingScore - 1
        }

        if targetStage == 0 {
            return bestDamagingScore + 250
        }

        return bestDamagingScore - (abs(targetStage) * 250)
    }

    func projectedDamage(move: MoveManifest, attacker: RuntimePokemonState, defender: RuntimePokemonState) -> Int {
        guard move.power > 0 else { return 0 }
        let adjustedAttack = adjustedAttackStat(for: attacker, criticalHit: false)
        let adjustedDefense = max(1, adjustedDefenseStat(for: defender, criticalHit: false))
        var damage = max(1, (((((2 * attacker.level) / 5) + 2) * move.power * adjustedAttack) / adjustedDefense) / 50 + 2)
        if hasSTAB(attackerSpeciesID: attacker.speciesID, moveType: move.type) {
            damage += damage / 2
        }
        return applyTypeMultiplier(totalTypeMultiplier(for: move.type, defenderSpeciesID: defender.speciesID), to: damage)
    }

    func hasSTAB(attackerSpeciesID: String, moveType: String) -> Bool {
        guard let species = content.species(id: attackerSpeciesID) else { return false }
        return species.primaryType == moveType || species.secondaryType == moveType
    }

    func totalTypeMultiplier(for moveType: String, defenderSpeciesID: String) -> Int {
        guard let species = content.species(id: defenderSpeciesID) else { return 10 }
        let defendingTypes = [species.primaryType, species.secondaryType].compactMap { $0 }
        guard defendingTypes.isEmpty == false else { return 10 }

        return defendingTypes.reduce(10) { partialResult, defendingType in
            let nextMultiplier = content.typeEffectiveness(attackingType: moveType, defendingType: defendingType)?.multiplier ?? 10
            return (partialResult * nextMultiplier) / 10
        }
    }

    func applyTypeMultiplier(_ multiplier: Int, to damage: Int) -> Int {
        guard multiplier > 0 else { return 0 }
        return max(1, (damage * multiplier) / 10)
    }

    func adjustedAttackStat(for pokemon: RuntimePokemonState, criticalHit: Bool) -> Int {
        if criticalHit {
            return max(1, pokemon.attack)
        }
        return max(1, scaledStat(pokemon.attack, stage: pokemon.attackStage))
    }

    func adjustedDefenseStat(for pokemon: RuntimePokemonState, criticalHit: Bool) -> Int {
        if criticalHit {
            return max(1, pokemon.defense)
        }
        return max(1, scaledStat(pokemon.defense, stage: pokemon.defenseStage))
    }

    func isCriticalHit(for speciesID: String) -> Bool {
        let baseSpeed = content.species(id: speciesID)?.baseSpeed ?? 0
        let threshold = min(255, max(1, baseSpeed / 2))
        return nextBattleRandomByte() < threshold
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
        battle.message = messages.first ?? "Pick the next move."
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
            battle.phase = .moveSelection
            battle.message = "Pick the next move."
            return
        }

        battle.pendingAction = nil
        switch pendingAction {
        case .moveSelection:
            battle.phase = .moveSelection
            battle.message = "Pick the next move."
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
        case .continueLevelUpResolution:
            continueLevelUpResolution(battle: &battle)
        }
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

    func maxBattleActionIndex(for battle: RuntimeBattleState) -> Int {
        let moveActionCount = battle.playerPokemon.moves.count
        var count = moveActionCount
        if canUseBattleBag(for: battle) {
            count += 1
        }
        if battle.canRun {
            count += 1
        }
        return max(0, count - 1)
    }

    func canUseBattleBag(for battle: RuntimeBattleState) -> Bool {
        battle.kind == .wild && currentBattleBagItems.isEmpty == false
    }

    func bagActionIndex(for battle: RuntimeBattleState) -> Int {
        battle.playerPokemon.moves.count
    }

    func runActionIndex(for battle: RuntimeBattleState) -> Int {
        battle.playerPokemon.moves.count + (canUseBattleBag(for: battle) ? 1 : 0)
    }

    func canSendCapturedPokemonToCurrentBox(_ gameplayState: GameplayState) -> Bool {
        guard gameplayState.boxedPokemon.indices.contains(gameplayState.currentBoxIndex) else {
            return true
        }
        return gameplayState.boxedPokemon[gameplayState.currentBoxIndex].pokemon.count < Self.storageBoxCapacity
    }

    @discardableResult
    func attemptWildCapture(
        battle: inout RuntimeBattleState,
        gameplayState: inout GameplayState,
        item: ItemManifest
    ) -> Bool {
        let captureScore = captureScore(for: battle.enemyPokemon, item: item)

        guard nextBattleRandomByte() < captureScore else {
            return false
        }

        let capturedPokemon = battle.enemyPokemon
        gameplayState.ownedSpeciesIDs.insert(capturedPokemon.speciesID)
        var messages = ["All right! \(capturedPokemon.nickname) was caught!"]

        if gameplayState.playerParty.count < 6 {
            gameplayState.playerParty.append(capturedPokemon)
        } else if addPokemonToCurrentBox(capturedPokemon, in: &gameplayState) {
            messages.append("\(capturedPokemon.nickname) was transferred to BOX \(gameplayState.currentBoxIndex + 1).")
        } else {
            addItem(item.id, quantity: 1, to: &gameplayState)
            messages = ["The #MON BOX is full! Can't use that item!"]
            presentBattleMessages(messages, battle: &battle, pendingAction: .moveSelection)
            return true
        }

        presentBattleMessages(messages, battle: &battle, pendingAction: .captured)
        return true
    }

    func captureScore(for pokemon: RuntimePokemonState, item: ItemManifest) -> Int {
        let baseCatchRate = content.species(id: pokemon.speciesID)?.catchRate ?? 0
        let maxHP = max(1, pokemon.maxHP)
        let currentHP = max(1, pokemon.currentHP)
        let hpFactor = ((3 * maxHP) - (2 * currentHP)) * baseCatchRate / (3 * maxHP)
        let ballBonus: Int
        switch item.id {
        case "MASTER_BALL":
            return 255
        case "ULTRA_BALL", "SAFARI_BALL":
            ballBonus = 25
        case "GREAT_BALL":
            ballBonus = 15
        default:
            ballBonus = 0
        }
        return min(255, hpFactor + ballBonus + pokemon.majorStatus.captureBonus)
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
            message: "",
            queuedMessages: [],
            pendingAction: .moveSelection,
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
            message: "",
            queuedMessages: [],
            pendingAction: .moveSelection,
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

    func makePokemon(speciesID: String, level: Int, nickname: String) -> RuntimePokemonState {
        let dvs = nextRuntimeDVs()
        return makeConfiguredPokemon(
            speciesID: speciesID,
            nickname: nickname,
            level: level,
            experience: experienceRequired(for: level, speciesID: speciesID),
            dvs: dvs,
            statExp: .zero,
            currentHP: nil,
            attackStage: 0,
            defenseStage: 0,
            accuracyStage: 0,
            evasionStage: 0,
            moves: nil
        )
    }

    func makeTrainerBattlePokemon(speciesID: String, level: Int, nickname: String) -> RuntimePokemonState {
        makeConfiguredPokemon(
            speciesID: speciesID,
            nickname: nickname,
            level: level,
            experience: experienceRequired(for: level, speciesID: speciesID),
            dvs: trainerBattleDVs,
            statExp: .zero,
            currentHP: nil,
            attackStage: 0,
            defenseStage: 0,
            accuracyStage: 0,
            evasionStage: 0,
            moves: nil
        )
    }

    var trainerBattleDVs: PokemonDVs {
        PokemonDVs(attack: 9, defense: 8, speed: 8, special: 8)
    }

    func makeConfiguredPokemon(
        speciesID: String,
        nickname: String,
        level: Int,
        experience: Int,
        dvs: PokemonDVs,
        statExp: PokemonStatExp,
        currentHP: Int?,
        attackStage: Int,
        defenseStage: Int,
        accuracyStage: Int,
        evasionStage: Int,
        majorStatus: MajorStatusCondition = .none,
        moves: [RuntimeMoveState]?
    ) -> RuntimePokemonState {
        guard let species = content.species(id: speciesID) else {
            return RuntimePokemonState(
                speciesID: speciesID,
                nickname: nickname,
                level: level,
                experience: experience,
                dvs: dvs,
                statExp: statExp,
                maxHP: 20,
                currentHP: min(20, max(0, currentHP ?? 20)),
                attack: 10,
                defense: 10,
                speed: 10,
                special: 10,
                attackStage: attackStage,
                defenseStage: defenseStage,
                accuracyStage: accuracyStage,
                evasionStage: evasionStage,
                majorStatus: majorStatus,
                moves: moves ?? []
            )
        }

        let resolvedMoves = moves ?? species.startingMoves.compactMap { moveID -> RuntimeMoveState? in
            guard moveID != "NO_MOVE", let move = content.move(id: moveID) else { return nil }
            return RuntimeMoveState(id: move.id, currentPP: move.maxPP)
        }

        let calculatedStats = calculatedStats(for: species, level: level, dvs: dvs, statExp: statExp)

        return RuntimePokemonState(
            speciesID: species.id,
            nickname: nickname,
            level: level,
            experience: experience,
            dvs: dvs,
            statExp: statExp,
            maxHP: calculatedStats.maxHP,
            currentHP: min(calculatedStats.maxHP, max(0, currentHP ?? calculatedStats.maxHP)),
            attack: calculatedStats.attack,
            defense: calculatedStats.defense,
            speed: calculatedStats.speed,
            special: calculatedStats.special,
            attackStage: attackStage,
            defenseStage: defenseStage,
            accuracyStage: accuracyStage,
            evasionStage: evasionStage,
            majorStatus: majorStatus,
            moves: resolvedMoves
        )
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
                        message: message
                    )
                )
            }
        }

        let rewardContinuation: RuntimeBattleRewardContinuation
        if battle.enemyActiveIndex + 1 < battle.enemyParty.count {
            rewardContinuation = .sendNextEnemy(index: battle.enemyActiveIndex + 1)
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
            battle.phase = .moveSelection
            battle.message = "Pick the next move."
            return
        }

        battle.rewardContinuation = nil
        switch rewardContinuation {
        case let .sendNextEnemy(index):
            scheduleNextEnemySendOut(battle: &battle, nextIndex: index)
        case .finishWin:
            battle.phase = .battleComplete
            finishBattle(battle: battle, won: true)
        }
    }

    func scheduleNextEnemySendOut(battle: inout RuntimeBattleState, nextIndex: Int) {
        guard battle.enemyParty.indices.contains(nextIndex) else {
            battle.phase = .moveSelection
            battle.message = "Pick the next move."
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
                .init(
                    delay: battlePresentationDelay(base: 0.26),
                    stage: .commandReady,
                    uiVisibility: .visible,
                    message: "Pick the next move.",
                    phase: .moveSelection,
                    playerPokemon: battle.playerPokemon
                ),
            ],
            battleID: battle.battleID
        )
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

    func calculatedStats(for species: SpeciesManifest, level: Int, dvs: PokemonDVs, statExp: PokemonStatExp) -> (maxHP: Int, attack: Int, defense: Int, speed: Int, special: Int) {
        (
            maxHP: calculatedStat(baseStat: species.baseHP, level: level, dv: dvs.hp, statExp: statExp.hp, isHP: true),
            attack: calculatedStat(baseStat: species.baseAttack, level: level, dv: dvs.attack, statExp: statExp.attack, isHP: false),
            defense: calculatedStat(baseStat: species.baseDefense, level: level, dv: dvs.defense, statExp: statExp.defense, isHP: false),
            speed: calculatedStat(baseStat: species.baseSpeed, level: level, dv: dvs.speed, statExp: statExp.speed, isHP: false),
            special: calculatedStat(baseStat: species.baseSpecial, level: level, dv: dvs.special, statExp: statExp.special, isHP: false)
        )
    }

    func calculatedStat(baseStat: Int, level: Int, dv: Int, statExp: Int, isHP: Bool) -> Int {
        let statExpTerm = ceilSquareRoot(of: statExp) / 4
        let scaledBase = (((baseStat + dv) * 2) + statExpTerm) * level
        let baseValue = scaledBase / 100
        return isHP ? baseValue + level + 10 : baseValue + 5
    }

    func ceilSquareRoot(of value: Int) -> Int {
        guard value > 0 else { return 0 }
        var candidate = 1
        while candidate * candidate < value && candidate < 255 {
            candidate += 1
        }
        return candidate
    }

    func reseedRuntimeRNG() {
        runtimeRNGState = runtimeRNGSeedSource()
    }

    func nextAcquisitionRandomByte() -> Int {
        if acquisitionRandomOverrides.isEmpty == false {
            return min(255, max(0, acquisitionRandomOverrides.removeFirst()))
        }

        return nextRuntimeRandomByte()
    }

    func nextRuntimeDVs() -> PokemonDVs {
        let attackDefenseByte = nextAcquisitionRandomByte()
        let speedSpecialByte = nextAcquisitionRandomByte()
        return PokemonDVs(
            attack: (attackDefenseByte >> 4) & 0xF,
            defense: attackDefenseByte & 0xF,
            speed: (speedSpecialByte >> 4) & 0xF,
            special: speedSpecialByte & 0xF
        )
    }

    func experienceRequired(for level: Int, speciesID: String) -> Int {
        guard let growthRate = content.species(id: speciesID)?.growthRate else {
            return 0
        }
        return experienceRequired(for: level, growthRate: growthRate)
    }

    func experienceRequired(for level: Int, growthRate: PokemonGrowthRate) -> Int {
        let boundedLevel = min(100, max(1, level))
        let levelSquared = boundedLevel * boundedLevel
        let levelCubed = levelSquared * boundedLevel

        switch growthRate {
        case .mediumFast:
            return levelCubed
        case .slightlyFast:
            return ((3 * levelCubed) / 4) + (10 * levelSquared) - 30
        case .slightlySlow:
            return ((3 * levelCubed) / 4) + (20 * levelSquared) - 70
        case .mediumSlow:
            return ((6 * levelCubed) / 5) - (15 * levelSquared) + (100 * boundedLevel) - 140
        case .fast:
            return (4 * levelCubed) / 5
        case .slow:
            return (5 * levelCubed) / 4
        }
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

    func nextBattleRandomByte() -> Int {
        if battleRandomOverrides.isEmpty == false {
            return min(255, max(0, battleRandomOverrides.removeFirst()))
        }

        return nextRuntimeRandomByte()
    }

    func nextRuntimeRandomByte() -> Int {
        runtimeRNGState = runtimeRNGState &* 6364136223846793005 &+ 1
        return Int((runtimeRNGState >> 32) & 0xFF)
    }
}
