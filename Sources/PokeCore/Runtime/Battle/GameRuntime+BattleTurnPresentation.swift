import Foundation
import PokeAudio
import PokeDataModel

@MainActor
private struct BattleTurnPresentationBuilder {
    let runtime: GameRuntime

    func makeTurnPresentationBatches(
        for battle: inout RuntimeBattleState
    ) -> [[RuntimeBattlePresentationBeat]] {
        var simulatedPlayer = battle.playerPokemon
        var simulatedEnemy = battle.enemyPokemon
        var batches: [[RuntimeBattlePresentationBeat]] = []
        let playerMoveIndex = runtime.resolveActionMoveIndex(
            for: .player,
            battle: battle,
            playerPokemon: simulatedPlayer,
            enemyPokemon: simulatedEnemy
        )
        let enemyMoveIndex = runtime.peekActionMoveIndex(
            for: .enemy,
            battle: battle,
            playerPokemon: simulatedPlayer,
            enemyPokemon: simulatedEnemy
        )
        let actionSides = runtime.turnActionOrder(
            playerPokemon: simulatedPlayer,
            enemyPokemon: simulatedEnemy,
            playerMoveIndex: playerMoveIndex,
            enemyMoveIndex: enemyMoveIndex
        )

        for side in actionSides {
            runtime.consumeActionMoveSelectionRandomnessIfNeeded(
                for: side,
                battle: battle,
                playerPokemon: simulatedPlayer,
                enemyPokemon: simulatedEnemy
            )
            let moveIndex = side == .player ? playerMoveIndex : enemyMoveIndex
            let action = runtime.resolveBattleAction(
                side: side,
                attacker: side == .player ? simulatedPlayer : simulatedEnemy,
                defender: side == .player ? simulatedEnemy : simulatedPlayer,
                moveIndex: moveIndex,
                defenderCanActLaterInTurn: side != actionSides.last
            )
            var actionBeats = makeActionBeats(for: action)
            if let pendingAction = action.pendingAction,
               actionBeats.isEmpty == false {
                actionBeats[actionBeats.count - 1].pendingAction = pendingAction
            }
            batches.append(actionBeats)
            runtime.applyResolvedBattleAction(
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

            if runtime.appendPostActionResolutionIfNeeded(
                battle: battle,
                simulatedPlayer: &simulatedPlayer,
                simulatedEnemy: simulatedEnemy,
                batches: &batches
            ) {
                return batches
            }

            if runtime.appendResidualResolutionIfNeeded(
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
            runtime.commandReadyBeat(
                delay: runtime.battlePresentationDelay(base: 0.24),
                playerPokemon: simulatedPlayer,
                enemyPokemon: simulatedEnemy
            ),
        ])
        return batches
    }

    func makeActionBeats(for action: ResolvedBattleAction) -> [RuntimeBattlePresentationBeat] {
        let attackerPokemon = action.side == .player ? action.updatedAttacker : nil
        let enemyAttacker = action.side == .enemy ? action.updatedAttacker : nil
        let defenderMutationPlayer = action.side == .enemy ? action.updatedDefender : nil
        let defenderMutationEnemy = action.side == .player ? action.updatedDefender : nil

        if action.didExecuteMove == false {
            return action.messages.enumerated().map { index, message in
                .init(
                    delay: runtime.battlePresentationDelay(base: index == 0 ? 0 : 0.18),
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

        let move = runtime.content.move(id: action.moveID)
        let moveMissed = action.messages.contains("But it missed!")
        let skipAnimation = runtime.optionsBattleAnimation == .off
        let sourceMoveAnimation = skipAnimation || moveMissed ? nil : runtime.content.battleAnimation(moveID: action.moveID)
        let attackAnimationPlayback = sourceMoveAnimation.map {
            runtime.makeAttackAnimationPlayback(for: action, moveAnimation: $0)
        }
        let stagedAttackSoundEffectRequests = sourceMoveAnimation.map {
            runtime.attackAnimationSoundEffectRequests(
                for: $0,
                attackerSpeciesID: action.attackerSpeciesID
            )
        } ?? []
        let moveAudioRequest: SoundEffectPlaybackRequest?
        if let move = runtime.content.move(id: action.moveID) {
            moveAudioRequest = runtime.moveSoundEffectRequest(
                for: move,
                attackerSpeciesID: action.attackerSpeciesID
            )
        } else {
            moveAudioRequest = nil
        }
        let applyingHitEffect = move.flatMap {
            runtime.makeApplyingHitEffect(for: action, move: $0)
        }
        let fallbackMovePlaybackDelay = runtime.battlePresentationDelay(base: 30.0 / 60.0)
        let movePlaybackDelay: TimeInterval
        if moveMissed {
            movePlaybackDelay = 0
        } else {
            movePlaybackDelay = attackAnimationPlayback?.totalDuration ?? fallbackMovePlaybackDelay
        }
        let windupSoundEffectRequest = moveMissed ? nil : (attackAnimationPlayback == nil ? moveAudioRequest : nil)
        let movePhaseSoundEffectRequests = stagedAttackSoundEffectRequests.map(\.request) + (windupSoundEffectRequest.map { [$0] } ?? [])
        let impactSoundEffectRequest = action.dealtDamage > 0
            ? runtime.applyingHitSoundEffectRequest(typeMultiplier: action.typeMultiplier)
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
                    delay: skipAnimation ? 0 : runtime.battlePresentationDelay(base: 3.0 / 60.0),
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
                    meterAnimation: runtime.hpMeterAnimation(for: action),
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
                        delay: runtime.battlePresentationDelay(base: 0.24),
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
                ? runtime.enemyFaintedText(for: action.updatedDefender)
                : runtime.playerFaintedText(for: action.updatedDefender)
            let soundEffectRequests = action.side == .player
                ? runtime.enemyFaintSoundEffectRequests()
                : runtime.speciesCrySoundEffectRequest(speciesID: action.updatedDefender.speciesID).map { [$0] } ?? []

            beats.append(
                .init(
                    delay: runtime.battlePresentationDelay(base: 0.24),
                    stage: .faint,
                    uiVisibility: .visible,
                    activeSide: faintSide,
                    soundEffectRequest: soundEffectRequests.first
                )
            )

            for soundEffectRequest in soundEffectRequests.dropFirst() {
                beats.append(
                    .init(
                        delay: runtime.battlePresentationDelay(base: 0.3),
                        stage: .faint,
                        uiVisibility: .visible,
                        activeSide: faintSide,
                        soundEffectRequest: soundEffectRequest
                    )
                )
            }

            beats.append(
                .init(
                    delay: runtime.battlePresentationDelay(base: 0.24),
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
}

extension GameRuntime {
    func makeTurnPresentationBatches(for battle: inout RuntimeBattleState) -> [[RuntimeBattlePresentationBeat]] {
        BattleTurnPresentationBuilder(runtime: self).makeTurnPresentationBatches(for: &battle)
    }

    func makeBeats(for action: ResolvedBattleAction) -> [RuntimeBattlePresentationBeat] {
        BattleTurnPresentationBuilder(runtime: self).makeActionBeats(for: action)
    }
}
