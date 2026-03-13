import PokeDataModel

extension GameRuntime {
    func resolveBattleAction(
        side: BattlePresentationSide,
        attacker: RuntimePokemonState,
        defender: RuntimePokemonState,
        moveIndex: Int,
        defenderCanActLaterInTurn: Bool
    ) -> ResolvedBattleAction {
        var updatedAttacker = attacker
        var updatedDefender = defender
        let defenderHPBefore = defender.currentHP
        let moveID = attacker.moves.indices.contains(moveIndex) ? attacker.moves[moveIndex].id : "NO_MOVE"
        let preparation = preparePokemonForTurn(
            pokemon: &updatedAttacker,
            opponent: updatedDefender,
            selectedMoveIndex: moveIndex
        )
        let resolvedMove: ResolvedBattleMove
        if preparation.canAct {
            resolvedMove = applyMove(
                attacker: &updatedAttacker,
                defender: &updatedDefender,
                moveIndex: moveIndex,
                defenderCanActLaterInTurn: defenderCanActLaterInTurn,
                skipPP: preparation.shouldSkipPP,
                skipAccuracy: preparation.shouldSkipAccuracy,
                skipEffect: preparation.shouldSkipEffect,
                forcedDamage: preparation.forcedDamage,
                playsAudio: false
            )
        } else {
            resolvedMove = ResolvedBattleMove(
                messages: [],
                dealtDamage: 0,
                typeMultiplier: 10,
                pendingAction: nil,
                payDayMoneyGain: 0
            )
        }
        return ResolvedBattleAction(
            side: side,
            moveID: moveID,
            attackerSpeciesID: attacker.speciesID,
            didExecuteMove: preparation.canAct,
            updatedAttacker: updatedAttacker,
            updatedDefender: updatedDefender,
            messages: preparation.messages + resolvedMove.messages,
            dealtDamage: resolvedMove.dealtDamage,
            defenderHPBefore: defenderHPBefore,
            defenderHPAfter: updatedDefender.currentHP,
            pendingAction: resolvedMove.pendingAction,
            payDayMoneyGain: resolvedMove.payDayMoneyGain
        )
    }

    func applyMove(
        attacker: inout RuntimePokemonState,
        defender: inout RuntimePokemonState,
        moveIndex: Int,
        defenderCanActLaterInTurn: Bool = false,
        skipPP: Bool = false,
        skipAccuracy: Bool = false,
        skipEffect: Bool = false,
        forcedDamage: Int? = nil,
        playsAudio: Bool = true
    ) -> ResolvedBattleMove {
        guard attacker.moves.indices.contains(moveIndex),
              attacker.moves[moveIndex].currentPP > 0 || skipPP,
              var move = content.move(id: attacker.moves[moveIndex].id) else {
            return ResolvedBattleMove(
                messages: [],
                dealtDamage: 0,
                typeMultiplier: 10,
                pendingAction: nil,
                payDayMoneyGain: 0
            )
        }

        if skipPP == false {
            attacker.moves[moveIndex].currentPP -= 1
        }

        if forcedDamage != nil, move.effect == "BIDE_EFFECT" {
            attacker.battleEffects.pendingBideDamage = nil
            attacker.battleEffects.bideAccumulatedDamage = 0
        }

        let selectedMove = move

        if move.effect == "MIRROR_MOVE_EFFECT" {
            guard let copiedMove = mirrorMoveTarget(for: defender),
                  copiedMove.effect != "MIRROR_MOVE_EFFECT" else {
                recordLastSelectedMoveMetadata(selectedMove, attacker: &attacker)
                return ResolvedBattleMove(
                    messages: ["But it failed!"],
                    dealtDamage: 0,
                    typeMultiplier: 10,
                    pendingAction: nil,
                    payDayMoneyGain: 0
                )
            }
            move = copiedMove
        } else if move.effect == "METRONOME_EFFECT" {
            guard let randomMove = metronomeMove() else {
                recordLastSelectedMoveMetadata(selectedMove, attacker: &attacker)
                return ResolvedBattleMove(
                    messages: ["But it failed!"],
                    dealtDamage: 0,
                    typeMultiplier: 10,
                    pendingAction: nil,
                    payDayMoneyGain: 0
                )
            }
            move = randomMove
        }

        recordLastSelectedMoveMetadata(move, attacker: &attacker)
        attacker.battleEffects.lastMoveID = move.id
        defender.battleEffects.lastDamageTaken = 0

        var messages = ["\(attacker.nickname) used \(move.displayName)!"]
        if playsAudio {
            _ = playMoveAudio(for: move, attackerSpeciesID: attacker.speciesID)
        }

        if move.effect == "CHARGE_EFFECT" || move.effect == "FLY_EFFECT" {
            let chargeMessages = beginChargingIfNeeded(move: move, attacker: &attacker)
            if chargeMessages.isEmpty == false {
                return ResolvedBattleMove(
                    messages: messages + chargeMessages,
                    dealtDamage: 0,
                    typeMultiplier: 10,
                    pendingAction: nil,
                    payDayMoneyGain: 0
                )
            }
        }

        if requiresSleepingTarget(move), defender.majorStatus != .sleep {
            messages.append("But it failed!")
            return ResolvedBattleMove(
                messages: messages,
                dealtDamage: 0,
                typeMultiplier: 10,
                pendingAction: nil,
                payDayMoneyGain: 0
            )
        }

        if move.effect == "OHKO_EFFECT", attacker.level < defender.level {
            messages.append("But it missed!")
            return ResolvedBattleMove(
                messages: messages,
                dealtDamage: 0,
                typeMultiplier: 10,
                pendingAction: nil,
                payDayMoneyGain: 0
            )
        }

        if defender.battleEffects.isInvulnerable, skipAccuracy == false, move.effect != "SWIFT_EFFECT" {
            messages.append("But it missed!")
            return ResolvedBattleMove(
                messages: messages,
                dealtDamage: 0,
                typeMultiplier: 10,
                pendingAction: nil,
                payDayMoneyGain: 0
            )
        }

        let skipsAccuracy = skipAccuracy ||
            move.effect == "SWIFT_EFFECT" ||
            (move.effect == "SLEEP_EFFECT" && defender.battleEffects.needsRecharge)
        if skipsAccuracy == false, move.accuracy > 0 {
            let hitChance = scaledAccuracy(
                baseAccuracyPercent: move.accuracy,
                accuracyStage: attacker.accuracyStage,
                evasionStage: defender.evasionStage
            )
            if nextBattleRandomByte() >= hitChance {
                messages.append("But it missed!")
                if move.effect == "JUMP_KICK_EFFECT" {
                    messages.append(contentsOf: applyJumpKickCrashDamage(to: &attacker))
                } else if move.effect == "EXPLODE_EFFECT" {
                    messages.append(contentsOf: applyExplosionRecoil(to: &attacker))
                }
                return ResolvedBattleMove(
                    messages: messages,
                    dealtDamage: 0,
                    typeMultiplier: 10,
                    pendingAction: nil,
                    payDayMoneyGain: 0
                )
            }
        }

        var dealtDamage = 0
        var shouldApplyEffect = skipEffect == false
        let isCounterMove = move.id == "COUNTER"
        let typeMultiplier = isCounterMove ? 10 : totalTypeMultiplier(for: move.type, defender: defender)

        if let plannedHits = rolledMultiHitCount(for: move.effect) {
            let isCriticalHit = isCriticalHit(for: attacker)
            let adjustedAttack = adjustedOffenseStat(for: attacker, moveType: move.type, criticalHit: isCriticalHit)
            let adjustedDefense = max(
                1,
                adjustedDefenseStat(for: defender, moveType: move.type, moveEffect: move.effect, criticalHit: isCriticalHit)
            )
            let multiHitResult = resolveMultiHitMove(
                move: move,
                attacker: attacker,
                defender: &defender,
                plannedHits: plannedHits,
                adjustedAttack: adjustedAttack,
                adjustedDefense: adjustedDefense,
                typeMultiplier: typeMultiplier,
                criticalHit: isCriticalHit
            )
            dealtDamage = multiHitResult.dealtDamage
            defender.battleEffects.lastDamageTaken = multiHitResult.lastHitDamage
            if multiHitResult.hitSubstitute {
                shouldApplyEffect = false
            }
            messages.append(contentsOf: multiHitResult.messages)
        } else if moveCanDealDamage(move, forcedDamage: forcedDamage) {
            let isCriticalHit = isCounterMove ? false : isCriticalHit(for: attacker)
            let damage: Int
            if isCounterMove {
                guard let counterDamage = resolvedCounterDamage(attacker: attacker, defender: defender) else {
                    messages.append("But it failed!")
                    return ResolvedBattleMove(
                        messages: messages,
                        dealtDamage: 0,
                        typeMultiplier: 10,
                        pendingAction: nil,
                        payDayMoneyGain: 0
                    )
                }
                damage = counterDamage
            } else {
                let adjustedAttack = adjustedOffenseStat(for: attacker, moveType: move.type, criticalHit: isCriticalHit)
                let adjustedDefense = max(
                    1,
                    adjustedDefenseStat(for: defender, moveType: move.type, moveEffect: move.effect, criticalHit: isCriticalHit)
                )
                damage = resolvedMoveDamage(
                    move: move,
                    attacker: attacker,
                    defender: defender,
                    adjustedAttack: adjustedAttack,
                    adjustedDefense: adjustedDefense,
                    typeMultiplier: typeMultiplier,
                    criticalHit: isCriticalHit,
                    forcedDamage: forcedDamage
                )
            }
            let damageResult = applyIncomingDamageToBattleDefender(
                dealtDamage: damage,
                defender: &defender
            )
            dealtDamage = damageResult.appliedDamage
            messages.append(contentsOf: damageResult.messages)

            if damageResult.hitSubstitute == false {
                defender.battleEffects.lastDamageTaken = damage
            } else {
                shouldApplyEffect = false
            }

            if damageResult.hitSubstitute == false, typeMultiplier == 0 {
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

        if dealtDamage > 0,
           defender.currentHP > 0,
           defender.battleEffects.isUsingRage,
           defender.battleEffects.hasSubstitute == false {
            messages.append(contentsOf: applyRageBuild(to: &defender))
        }

        var payDayMoneyGain = 0
        var effectPendingAction: RuntimeBattlePendingAction?
        if shouldApplyEffect, move.power == 0 || (typeMultiplier > 0 && defender.currentHP > 0) {
            messages.append(
                contentsOf: applyMoveEffect(
                    move,
                    moveIndex: moveIndex,
                    dealtDamage: dealtDamage,
                    attacker: &attacker,
                    defender: &defender,
                    defenderCanActLaterInTurn: defenderCanActLaterInTurn,
                    pendingAction: &effectPendingAction
                )
            )
            if move.effect == "PAY_DAY_EFFECT", dealtDamage > 0 {
                payDayMoneyGain = max(1, attacker.level * 2)
            }
        } else if move.effect == "EXPLODE_EFFECT" {
            messages.append(contentsOf: applyExplosionRecoil(to: &attacker))
        }

        return ResolvedBattleMove(
            messages: messages,
            dealtDamage: dealtDamage,
            typeMultiplier: typeMultiplier,
            pendingAction: effectPendingAction,
            payDayMoneyGain: payDayMoneyGain
        )
    }
}
