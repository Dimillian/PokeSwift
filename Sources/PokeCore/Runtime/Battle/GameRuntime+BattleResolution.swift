import PokeDataModel

struct ResolvedBattleMove {
    let messages: [String]
    let dealtDamage: Int
    let typeMultiplier: Int
    let pendingAction: RuntimeBattlePendingAction?
    let payDayMoneyGain: Int
}

struct ResolvedBattleAction {
    let side: BattlePresentationSide
    let moveID: String
    let attackerSpeciesID: String
    let didExecuteMove: Bool
    let updatedAttacker: RuntimePokemonState
    let updatedDefender: RuntimePokemonState
    let messages: [String]
    let dealtDamage: Int
    let defenderHPBefore: Int
    let defenderHPAfter: Int
    let pendingAction: RuntimeBattlePendingAction?
    let payDayMoneyGain: Int
}

private enum BattleStatKind {
    case attack
    case defense
    case speed
    case special
    case accuracy
    case evasion

    var displayName: String {
        switch self {
        case .attack:
            return "Attack"
        case .defense:
            return "Defense"
        case .speed:
            return "Speed"
        case .special:
            return "Special"
        case .accuracy:
            return "Accuracy"
        case .evasion:
            return "Evasion"
        }
    }
}

private enum StatChangeTarget {
    case attacker
    case defender
}

private struct StatStageEffectDescriptor {
    let target: StatChangeTarget
    let stat: BattleStatKind
    let stageDelta: Int
    let isSideEffect: Bool
}

private struct BattleTurnPreparationResult {
    let messages: [String]
    let canAct: Bool
    let shouldSkipPP: Bool
    let shouldSkipAccuracy: Bool
    let shouldSkipEffect: Bool
    let forcedDamage: Int?
}

private struct ResolvedMultiHitMove {
    let dealtDamage: Int
    let lastHitDamage: Int
    let messages: [String]
}

private struct SubstituteDamageResult {
    let hitSubstitute: Bool
    let appliedDamage: Int
    let messages: [String]
}

extension GameRuntime {
    static let trainerAIStatusAilmentEffects: Set<String> = [
        "EFFECT_01",
        "SLEEP_EFFECT",
        "POISON_EFFECT",
        "PARALYZE_EFFECT",
    ]

    static let trainerAIModification2PreferredEffects: Set<String> = [
        "ATTACK_UP1_EFFECT",
        "DEFENSE_UP1_EFFECT",
        "SPEED_UP1_EFFECT",
        "SPECIAL_UP1_EFFECT",
        "ACCURACY_UP1_EFFECT",
        "EVASION_UP1_EFFECT",
        "PAY_DAY_EFFECT",
        "SWIFT_EFFECT",
        "ATTACK_DOWN1_EFFECT",
        "DEFENSE_DOWN1_EFFECT",
        "SPEED_DOWN1_EFFECT",
        "SPECIAL_DOWN1_EFFECT",
        "ACCURACY_DOWN1_EFFECT",
        "EVASION_DOWN1_EFFECT",
        "CONVERSION_EFFECT",
        "HAZE_EFFECT",
        "ATTACK_UP2_EFFECT",
        "DEFENSE_UP2_EFFECT",
        "SPEED_UP2_EFFECT",
        "SPECIAL_UP2_EFFECT",
        "ACCURACY_UP2_EFFECT",
        "EVASION_UP2_EFFECT",
        "HEAL_EFFECT",
        "TRANSFORM_EFFECT",
        "ATTACK_DOWN2_EFFECT",
        "DEFENSE_DOWN2_EFFECT",
        "SPEED_DOWN2_EFFECT",
        "SPECIAL_DOWN2_EFFECT",
        "ACCURACY_DOWN2_EFFECT",
        "EVASION_DOWN2_EFFECT",
        "LIGHT_SCREEN_EFFECT",
        "REFLECT_EFFECT",
    ]

    static let specialMoveTypes: Set<String> = [
        "FIRE",
        "WATER",
        "GRASS",
        "ELECTRIC",
        "ICE",
        "PSYCHIC_TYPE",
        "DRAGON",
    ]

    static let burnSideEffects: Set<String> = [
        "BURN_SIDE_EFFECT1",
        "BURN_SIDE_EFFECT2",
    ]

    static let freezeSideEffects: Set<String> = [
        "FREEZE_SIDE_EFFECT1",
        "FREEZE_SIDE_EFFECT2",
    ]

    static let paralysisSideEffects: Set<String> = [
        "PARALYZE_SIDE_EFFECT1",
        "PARALYZE_SIDE_EFFECT2",
    ]

    static let poisonSideEffects: Set<String> = [
        "POISON_SIDE_EFFECT1",
        "POISON_SIDE_EFFECT2",
        "TWINEEDLE_EFFECT",
    ]

    static let flinchSideEffects: Set<String> = [
        "FLINCH_SIDE_EFFECT1",
        "FLINCH_SIDE_EFFECT2",
    ]

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

        if move.effect == "MIRROR_MOVE_EFFECT" {
            guard let copiedMove = mirrorMoveTarget(for: defender),
                  copiedMove.effect != "MIRROR_MOVE_EFFECT" else {
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

        let skipsAccuracy = skipAccuracy || move.effect == "SWIFT_EFFECT"
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
            messages.append(contentsOf: multiHitResult.messages)
        } else if move.power > 0 || forcedDamage != nil {
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
            var appliedDamage = damage
            let substituteResult = applyDamageToSubstituteIfNeeded(
                move: move,
                dealtDamage: appliedDamage,
                defender: &defender
            )
            dealtDamage = substituteResult.appliedDamage
            messages.append(contentsOf: substituteResult.messages)

            if substituteResult.hitSubstitute == false {
                defender.currentHP = max(0, defender.currentHP - appliedDamage)
                defender.battleEffects.lastDamageTaken = appliedDamage
            } else {
                appliedDamage = substituteResult.appliedDamage
                shouldApplyEffect = false
            }

            if substituteResult.hitSubstitute == false, typeMultiplier == 0 {
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
        if shouldApplyEffect, move.power == 0 || (typeMultiplier > 0 && defender.currentHP > 0) {
            messages.append(
                contentsOf: applyMoveEffect(
                    move,
                    moveIndex: moveIndex,
                    dealtDamage: dealtDamage,
                    attacker: &attacker,
                    defender: &defender,
                    defenderCanActLaterInTurn: defenderCanActLaterInTurn
                )
            )
            if move.effect == "PAY_DAY_EFFECT", dealtDamage > 0 {
                payDayMoneyGain = max(1, attacker.level * 2)
            }
        } else if move.effect == "EXPLODE_EFFECT" {
            messages.append(contentsOf: applyExplosionRecoil(to: &attacker))
        }

        let pendingAction: RuntimeBattlePendingAction?
        if move.effect == "SWITCH_AND_TELEPORT_EFFECT",
           applySwitchAndTeleport(move: move, attacker: attacker, defender: defender) {
            pendingAction = .escape
        } else {
            pendingAction = nil
        }

        return ResolvedBattleMove(
            messages: messages,
            dealtDamage: dealtDamage,
            typeMultiplier: typeMultiplier,
            pendingAction: pendingAction,
            payDayMoneyGain: payDayMoneyGain
        )
    }

    func beginChargingIfNeeded(move: MoveManifest, attacker: inout RuntimePokemonState) -> [String] {
        if attacker.battleEffects.chargingMoveID == move.id {
            attacker.battleEffects.chargingMoveID = nil
            attacker.battleEffects.isInvulnerable = false
            return []
        }

        attacker.battleEffects.chargingMoveID = move.id
        attacker.battleEffects.isInvulnerable = move.effect == "FLY_EFFECT" || move.id == "DIG"
        return [chargeUpMessage(for: move.id)]
    }

    func chargeUpMessage(for moveID: String) -> String {
        switch moveID {
        case "RAZOR_WIND":
            return "Made a whirlwind!"
        case "SOLARBEAM":
            return "Took in sunlight!"
        case "SKULL_BASH":
            return "Lowered its head!"
        case "SKY_ATTACK":
            return "Is glowing!"
        case "FLY":
            return "Flew up high!"
        case "DIG":
            return "Dug a hole!"
        default:
            return "Is getting ready!"
        }
    }

    func mirrorMoveTarget(for defender: RuntimePokemonState) -> MoveManifest? {
        guard let lastMoveID = defender.battleEffects.lastMoveID else {
            return nil
        }
        return content.move(id: lastMoveID)
    }

    func metronomeMove() -> MoveManifest? {
        let candidates = content.gameplayManifest.moves.filter {
            $0.id != "METRONOME" && $0.id != "STRUGGLE"
        }
        guard candidates.isEmpty == false else {
            return nil
        }
        return candidates[nextBattleRandomByte() % candidates.count]
    }

    fileprivate func applyDamageToSubstituteIfNeeded(
        move: MoveManifest,
        dealtDamage: Int,
        defender: inout RuntimePokemonState
    ) -> SubstituteDamageResult {
        guard dealtDamage > 0,
              move.power > 0,
              defender.battleEffects.hasSubstitute else {
            return .init(hitSubstitute: false, appliedDamage: dealtDamage, messages: [])
        }

        let appliedDamage = min(defender.battleEffects.substituteHP, dealtDamage)
        defender.battleEffects.substituteHP = max(0, defender.battleEffects.substituteHP - appliedDamage)

        var messages = ["Substitute took damage!"]
        if defender.battleEffects.substituteHP == 0 {
            defender.battleEffects.hasSubstitute = false
            messages.append("Substitute broke!")
        }

        return .init(hitSubstitute: true, appliedDamage: appliedDamage, messages: messages)
    }

    func clearInterruptedMultiTurnState(for pokemon: inout RuntimePokemonState) {
        pokemon.battleEffects.bideTurnsRemaining = 0
        pokemon.battleEffects.pendingBideDamage = nil
        pokemon.battleEffects.bideAccumulatedDamage = 0
        pokemon.battleEffects.thrashTurnsRemaining = 0
        pokemon.battleEffects.thrashMoveID = nil
        pokemon.battleEffects.chargingMoveID = nil
        pokemon.battleEffects.isInvulnerable = false
        pokemon.battleEffects.trappingTurnsRemaining = 0
        pokemon.battleEffects.trappingMoveID = nil
        pokemon.battleEffects.trappingDamage = 0
    }

    func applySwitchAndTeleport(move: MoveManifest, attacker: RuntimePokemonState, defender: RuntimePokemonState) -> Bool {
        guard gameplayState?.battle?.kind == .wild else {
            return false
        }

        let attackerLevel = attacker.level
        let defenderLevel = defender.level
        if attackerLevel >= defenderLevel {
            return true
        }

        let threshold = max(1, defenderLevel / 4)
        let sampleRange = attackerLevel + defenderLevel + 1
        let sample = nextBattleRandomByte() % sampleRange
        if sample >= threshold {
            return true
        }

        return false
    }

    func applyMoveEffect(
        _ move: MoveManifest,
        moveIndex: Int,
        dealtDamage: Int,
        attacker: inout RuntimePokemonState,
        defender: inout RuntimePokemonState,
        defenderCanActLaterInTurn: Bool
    ) -> [String] {
        let effect = move.effect
        guard let descriptor = statStageEffectDescriptor(for: effect) else {
            return applyNonStatMoveEffect(
                move: move,
                moveIndex: moveIndex,
                dealtDamage: dealtDamage,
                attacker: &attacker,
                defender: &defender,
                defenderCanActLaterInTurn: defenderCanActLaterInTurn
            )
        }

        if defender.battleEffects.hasSubstitute,
           effectTargetsOpponent(effect),
           move.power == 0 {
            return ["But it failed!"]
        }

        if descriptor.target == .defender,
           defender.battleEffects.isProtectedByMist {
            return ["But it failed!"]
        }

        if descriptor.isSideEffect {
            guard nextBattleRandomByte() < 84 else {
                return []
            }
        }

        switch descriptor.target {
        case .attacker:
            return applyStageChange(
                delta: descriptor.stageDelta,
                stat: descriptor.stat,
                to: &attacker,
                failureMessage: descriptor.isSideEffect ? nil : "Nothing happened!"
            )
        case .defender:
            return applyStageChange(
                delta: descriptor.stageDelta,
                stat: descriptor.stat,
                to: &defender,
                failureMessage: descriptor.isSideEffect ? nil : "Nothing happened!"
            )
        }
    }

    func effectTargetsOpponent(_ effect: String) -> Bool {
        switch effect {
        case "DRAIN_HP_EFFECT",
             "DREAM_EATER_EFFECT",
             "SWITCH_AND_TELEPORT_EFFECT",
             "PAY_DAY_EFFECT",
             "SWIFT_EFFECT",
             "SPECIAL_DAMAGE_EFFECT",
             "OHKO_EFFECT",
             "SUPER_FANG_EFFECT",
             "JUMP_KICK_EFFECT",
             "HEAL_EFFECT",
             "CONVERSION_EFFECT",
             "MIST_EFFECT",
             "LIGHT_SCREEN_EFFECT",
             "REFLECT_EFFECT",
             "HAZE_EFFECT",
             "FOCUS_ENERGY_EFFECT",
             "FLY_EFFECT",
             "CHARGE_EFFECT",
             "TRANSFORM_EFFECT",
             "SUBSTITUTE_EFFECT",
             "RAGE_EFFECT",
             "MIMIC_EFFECT",
             "METRONOME_EFFECT",
             "SPLASH_EFFECT",
             "EXPLODE_EFFECT":
            return false
        default:
            return true
        }
    }

    fileprivate func preparePokemonForTurn(
        pokemon: inout RuntimePokemonState,
        opponent: RuntimePokemonState,
        selectedMoveIndex: Int
    ) -> BattleTurnPreparationResult {
        var messages: [String] = []

        if pokemon.majorStatus == .sleep {
            if pokemon.statusCounter > 0 {
                pokemon.statusCounter -= 1
            }
            if pokemon.statusCounter <= 0 {
                pokemon.majorStatus = .none
                pokemon.statusCounter = 0
                return .init(
                    messages: ["\(pokemon.nickname) woke up!"],
                    canAct: false,
                    shouldSkipPP: false,
                    shouldSkipAccuracy: false,
                    shouldSkipEffect: false,
                    forcedDamage: nil
                )
            }
            return .init(
                messages: ["\(pokemon.nickname) is fast asleep!"],
                canAct: false,
                shouldSkipPP: false,
                shouldSkipAccuracy: false,
                shouldSkipEffect: false,
                forcedDamage: nil
            )
        }

        if pokemon.majorStatus == .freeze {
            return .init(
                messages: ["\(pokemon.nickname) is frozen solid!"],
                canAct: false,
                shouldSkipPP: false,
                shouldSkipAccuracy: false,
                shouldSkipEffect: false,
                forcedDamage: nil
            )
        }

        if opponent.battleEffects.trappingTurnsRemaining > 0,
           opponent.currentHP > 0 {
            return .init(
                messages: ["\(pokemon.nickname) can't move!"],
                canAct: false,
                shouldSkipPP: false,
                shouldSkipAccuracy: false,
                shouldSkipEffect: false,
                forcedDamage: nil
            )
        }

        if pokemon.battleEffects.isFlinched {
            pokemon.battleEffects.isFlinched = false
            return .init(
                messages: ["\(pokemon.nickname) flinched!"],
                canAct: false,
                shouldSkipPP: false,
                shouldSkipAccuracy: false,
                shouldSkipEffect: false,
                forcedDamage: nil
            )
        }

        if pokemon.battleEffects.needsRecharge {
            pokemon.battleEffects.needsRecharge = false
            return .init(
                messages: ["\(pokemon.nickname) must recharge!"],
                canAct: false,
                shouldSkipPP: false,
                shouldSkipAccuracy: false,
                shouldSkipEffect: false,
                forcedDamage: nil
            )
        }

        if pokemon.battleEffects.disabledTurnsRemaining > 0 {
            pokemon.battleEffects.disabledTurnsRemaining -= 1
            if pokemon.battleEffects.disabledTurnsRemaining == 0 {
                pokemon.battleEffects.disabledMoveID = nil
                messages.append("\(pokemon.nickname)'s disabled move is no longer disabled!")
            }
        }

        if pokemon.battleEffects.disabledTurnsRemaining > 0,
           pokemon.moves.indices.contains(selectedMoveIndex),
           pokemon.moves[selectedMoveIndex].id == pokemon.battleEffects.disabledMoveID {
            let disabledMoveName = content.move(id: pokemon.moves[selectedMoveIndex].id)?.displayName
                ?? pokemon.moves[selectedMoveIndex].id
            messages.append("\(disabledMoveName) is disabled!")
            return .init(
                messages: messages,
                canAct: false,
                shouldSkipPP: false,
                shouldSkipAccuracy: false,
                shouldSkipEffect: false,
                forcedDamage: nil
            )
        }

        if pokemon.battleEffects.confusionTurnsRemaining > 0 {
            pokemon.battleEffects.confusionTurnsRemaining -= 1
            if pokemon.battleEffects.confusionTurnsRemaining == 0 {
                messages.append("\(pokemon.nickname) snapped out of confusion!")
            } else {
                messages.append("\(pokemon.nickname) is confused!")
                if nextBattleRandomByte() >= 128 {
                    clearInterruptedMultiTurnState(for: &pokemon)
                    messages.append(contentsOf: applyConfusionSelfDamage(to: &pokemon))
                    return .init(
                        messages: messages,
                        canAct: false,
                        shouldSkipPP: false,
                        shouldSkipAccuracy: false,
                        shouldSkipEffect: false,
                        forcedDamage: nil
                    )
                }
            }
        }

        if pokemon.majorStatus == .paralysis, nextBattleRandomByte() < 64 {
            clearInterruptedMultiTurnState(for: &pokemon)
            messages.append("\(pokemon.nickname) is fully paralyzed!")
            return .init(
                messages: messages,
                canAct: false,
                shouldSkipPP: false,
                shouldSkipAccuracy: false,
                shouldSkipEffect: false,
                forcedDamage: nil
            )
        }

        if pokemon.battleEffects.bideTurnsRemaining > 0 {
            pokemon.battleEffects.bideTurnsRemaining -= 1
            if pokemon.battleEffects.bideTurnsRemaining > 0 {
                return .init(
                    messages: messages,
                    canAct: false,
                    shouldSkipPP: true,
                    shouldSkipAccuracy: true,
                    shouldSkipEffect: true,
                    forcedDamage: nil
                )
            }

            pokemon.battleEffects.pendingBideDamage = max(0, pokemon.battleEffects.bideAccumulatedDamage * 2)
            messages.append("\(pokemon.nickname) unleashed energy!")
            return .init(
                messages: messages,
                canAct: true,
                shouldSkipPP: true,
                shouldSkipAccuracy: true,
                shouldSkipEffect: true,
                forcedDamage: max(0, pokemon.battleEffects.pendingBideDamage ?? 0)
            )
        }

        if pokemon.battleEffects.thrashTurnsRemaining > 0 {
            messages.append("\(pokemon.nickname) is thrashing about!")
            pokemon.battleEffects.thrashTurnsRemaining -= 1
            if pokemon.battleEffects.thrashTurnsRemaining == 0 {
                pokemon.battleEffects.confusionTurnsRemaining = 2 + (nextBattleRandomByte() & 0x3)
                pokemon.battleEffects.thrashMoveID = nil
            }
            return .init(
                messages: messages,
                canAct: true,
                shouldSkipPP: true,
                shouldSkipAccuracy: false,
                shouldSkipEffect: true,
                forcedDamage: nil
            )
        }

        if pokemon.battleEffects.trappingTurnsRemaining > 0 {
            messages.append("Attack continues!")
            pokemon.battleEffects.trappingTurnsRemaining -= 1
            if pokemon.battleEffects.trappingTurnsRemaining == 0 {
                pokemon.battleEffects.trappingMoveID = nil
            }
            return .init(
                messages: messages,
                canAct: true,
                shouldSkipPP: true,
                shouldSkipAccuracy: true,
                shouldSkipEffect: true,
                forcedDamage: pokemon.battleEffects.trappingDamage
            )
        }

        if pokemon.battleEffects.chargingMoveID != nil {
            return .init(
                messages: messages,
                canAct: true,
                shouldSkipPP: false,
                shouldSkipAccuracy: false,
                shouldSkipEffect: false,
                forcedDamage: nil
            )
        }

        if pokemon.battleEffects.isUsingRage {
            return .init(
                messages: messages,
                canAct: true,
                shouldSkipPP: true,
                shouldSkipAccuracy: false,
                shouldSkipEffect: true,
                forcedDamage: nil
            )
        }

        return .init(
            messages: messages,
            canAct: true,
            shouldSkipPP: false,
            shouldSkipAccuracy: false,
            shouldSkipEffect: false,
            forcedDamage: nil
        )
    }

    func resolvedMoveDamage(
        move: MoveManifest,
        attacker: RuntimePokemonState,
        defender: RuntimePokemonState,
        adjustedAttack: Int,
        adjustedDefense: Int,
        typeMultiplier: Int,
        criticalHit: Bool,
        forcedDamage: Int? = nil
    ) -> Int {
        if let forcedDamage {
            return forcedDamage
        }
        switch move.effect {
        case "OHKO_EFFECT":
            return max(1, defender.currentHP)
        case "SUPER_FANG_EFFECT":
            return max(1, defender.currentHP / 2)
        case "SPECIAL_DAMAGE_EFFECT":
            return fixedDamage(for: move.id, attackerLevel: attacker.level)
        default:
            break
        }

        let battleLevel = criticalHit ? attacker.level * 2 : attacker.level
        let effectiveDefense = max(1, adjustedDefense)
        var damage = max(1, (((((2 * battleLevel) / 5) + 2) * move.power * adjustedAttack) / effectiveDefense) / 50 + 2)

        if hasSTAB(attacker: attacker, moveType: move.type) {
            damage += damage / 2
        }

        return applyTypeMultiplier(typeMultiplier, to: damage)
    }

    func fixedDamage(for moveID: String, attackerLevel: Int) -> Int {
        switch moveID {
        case "SONICBOOM":
            return 20
        case "DRAGON_RAGE":
            return 40
        case "SEISMIC_TOSS", "NIGHT_SHADE":
            return max(1, attackerLevel)
        case "PSYWAVE":
            let upperBound = max(1, (attackerLevel * 3) / 2 - 1)
            return max(1, 1 + (nextBattleRandomByte() % upperBound))
        default:
            return max(1, attackerLevel)
        }
    }

    func rolledMultiHitCount(for effect: String) -> Int? {
        switch effect {
        case "ATTACK_TWICE_EFFECT", "TWINEEDLE_EFFECT":
            return 2
        case "TWO_TO_FIVE_ATTACKS_EFFECT":
            var value = nextBattleRandomByte() & 0x3
            if value >= 2 {
                value = nextBattleRandomByte() & 0x3
            }
            return value + 2
        default:
            return nil
        }
    }

    func expectedHitCount(for effect: String) -> Int {
        switch effect {
        case "ATTACK_TWICE_EFFECT", "TWINEEDLE_EFFECT":
            return 2
        case "TWO_TO_FIVE_ATTACKS_EFFECT":
            return 3
        default:
            return 1
        }
    }

    fileprivate func resolveMultiHitMove(
        move: MoveManifest,
        attacker: RuntimePokemonState,
        defender: inout RuntimePokemonState,
        plannedHits: Int,
        adjustedAttack: Int,
        adjustedDefense: Int,
        typeMultiplier: Int,
        criticalHit: Bool
    ) -> ResolvedMultiHitMove {
        guard typeMultiplier > 0 else {
            return .init(dealtDamage: 0, lastHitDamage: 0, messages: ["It doesn't affect \(defender.nickname)!"])
        }

        let damagePerHit = resolvedMoveDamage(
            move: move,
            attacker: attacker,
            defender: defender,
            adjustedAttack: adjustedAttack,
            adjustedDefense: adjustedDefense,
            typeMultiplier: typeMultiplier,
            criticalHit: criticalHit
        )

        var totalDamage = 0
        var actualHits = 0
        var lastHitDamage = 0
        for _ in 0..<plannedHits where defender.currentHP > 0 {
            let appliedDamage = min(defender.currentHP, damagePerHit)
            defender.currentHP -= appliedDamage
            totalDamage += appliedDamage
            actualHits += 1
            lastHitDamage = appliedDamage
        }

        var messages: [String] = []
        if criticalHit {
            messages.append("Critical hit!")
        }
        if typeMultiplier > 10 {
            messages.append("It's super effective!")
        } else if typeMultiplier < 10 {
            messages.append("It's not very effective...")
        }
        if defender.currentHP == 0 {
            messages.append("\(defender.nickname) fainted!")
        } else if actualHits > 1 {
            messages.append("Hit \(actualHits) times!")
        }

        return .init(dealtDamage: totalDamage, lastHitDamage: lastHitDamage, messages: messages)
    }

    func resolvedCounterDamage(attacker: RuntimePokemonState, defender: RuntimePokemonState) -> Int? {
        guard let lastMoveID = defender.battleEffects.lastMoveID,
              lastMoveID != "COUNTER",
              let lastMove = content.move(id: lastMoveID),
              lastMove.power > 0,
              lastMove.type == "NORMAL" || lastMove.type == "FIGHTING",
              attacker.battleEffects.lastDamageTaken > 0 else {
            return nil
        }

        return attacker.battleEffects.lastDamageTaken * 2
    }

    func applyNonStatMoveEffect(
        move: MoveManifest,
        moveIndex: Int,
        dealtDamage: Int,
        attacker: inout RuntimePokemonState,
        defender: inout RuntimePokemonState,
        defenderCanActLaterInTurn: Bool
    ) -> [String] {
        switch move.effect {
        case "SLEEP_EFFECT":
            return applySleep(move: move, defender: &defender)
        case "POISON_EFFECT":
            return applyPoison(move: move, defender: &defender, alwaysHits: true, badlyPoisoned: move.id == "TOXIC")
        case "POISON_SIDE_EFFECT1", "POISON_SIDE_EFFECT2", "TWINEEDLE_EFFECT":
            return applyPoison(move: move, defender: &defender, alwaysHits: false, badlyPoisoned: false)
        case "PARALYZE_EFFECT":
            return applyParalysis(move: move, defender: &defender, alwaysHits: true)
        case "PARALYZE_SIDE_EFFECT1", "PARALYZE_SIDE_EFFECT2":
            return applyParalysis(move: move, defender: &defender, alwaysHits: false)
        case "BURN_SIDE_EFFECT1", "BURN_SIDE_EFFECT2":
            return applyBurn(move: move, defender: &defender)
        case "FREEZE_SIDE_EFFECT1", "FREEZE_SIDE_EFFECT2":
            return applyFreeze(move: move, defender: &defender)
        case "CONFUSION_EFFECT":
            return applyConfusion(to: &defender, alwaysHits: true)
        case "CONFUSION_SIDE_EFFECT":
            return applyConfusion(to: &defender, alwaysHits: false)
        case "FLINCH_SIDE_EFFECT1", "FLINCH_SIDE_EFFECT2":
            return applyFlinch(to: &defender, effect: move.effect, defenderCanActLaterInTurn: defenderCanActLaterInTurn)
        case "DRAIN_HP_EFFECT", "DREAM_EATER_EFFECT":
            return applyDrainRecovery(
                move: move,
                dealtDamage: dealtDamage,
                attacker: &attacker,
                defender: defender
            )
        case "PAY_DAY_EFFECT":
            return dealtDamage > 0 ? ["Coins scattered everywhere!"] : []
        case "RECOIL_EFFECT":
            return applyRecoilDamage(move: move, dealtDamage: dealtDamage, attacker: &attacker)
        case "HEAL_EFFECT":
            return applyHealingMove(move: move, attacker: &attacker)
        case "CONVERSION_EFFECT":
            return applyConversion(attacker: &attacker, defender: defender)
        case "MIST_EFFECT":
            return applyMist(to: &attacker)
        case "LIGHT_SCREEN_EFFECT":
            return applyScreen(to: &attacker, kind: .special)
        case "REFLECT_EFFECT":
            return applyScreen(to: &attacker, kind: .physical)
        case "HAZE_EFFECT":
            return applyHaze(attacker: &attacker, defender: &defender)
        case "BIDE_EFFECT":
            return applyBide(to: &attacker)
        case "THRASH_PETAL_DANCE_EFFECT":
            return applyThrash(move: move, attacker: &attacker)
        case "SWITCH_AND_TELEPORT_EFFECT":
            return applySwitchAndTeleportMessages(move: move, attacker: attacker, defender: defender)
        case "TRAPPING_EFFECT":
            return applyTrapping(move: move, dealtDamage: dealtDamage, attacker: &attacker)
        case "LEECH_SEED_EFFECT":
            return applyLeechSeed(to: &defender)
        case "DISABLE_EFFECT":
            return applyDisable(to: &defender)
        case "FLY_EFFECT", "CHARGE_EFFECT":
            return []
        case "HYPER_BEAM_EFFECT":
            if dealtDamage > 0, defender.currentHP > 0 {
                attacker.battleEffects.needsRecharge = true
            }
            return []
        case "FOCUS_ENERGY_EFFECT":
            return applyFocusEnergy(to: &attacker)
        case "SPLASH_EFFECT":
            return ["But nothing happened!"]
        case "TRANSFORM_EFFECT":
            return applyTransform(attacker: &attacker, defender: defender)
        case "SUBSTITUTE_EFFECT":
            return applySubstitute(to: &attacker)
        case "RAGE_EFFECT":
            return applyRage(to: &attacker)
        case "MIMIC_EFFECT":
            return applyMimic(moveIndex: moveIndex, attacker: &attacker, defender: defender)
        case "EXPLODE_EFFECT":
            return applyExplosionRecoil(to: &attacker)
        case "SWIFT_EFFECT",
             "SPECIAL_DAMAGE_EFFECT",
             "OHKO_EFFECT",
             "SUPER_FANG_EFFECT",
             "JUMP_KICK_EFFECT":
            return []
        default:
            return []
        }
    }

    func requiresSleepingTarget(_ move: MoveManifest) -> Bool {
        move.effect == "DREAM_EATER_EFFECT"
    }

    func applySleep(move: MoveManifest, defender: inout RuntimePokemonState) -> [String] {
        guard defender.majorStatus == .none else {
            return defender.majorStatus == .sleep
                ? ["\(defender.nickname) is already asleep!"]
                : ["But it failed!"]
        }
        var sleepTurns = 0
        repeat {
            sleepTurns = nextBattleRandomByte() & 0x7
        } while sleepTurns == 0
        defender.majorStatus = .sleep
        defender.statusCounter = sleepTurns
        defender.battleEffects.needsRecharge = false
        return ["\(defender.nickname) fell asleep!"]
    }

    func applyPoison(
        move: MoveManifest,
        defender: inout RuntimePokemonState,
        alwaysHits: Bool,
        badlyPoisoned: Bool
    ) -> [String] {
        guard defender.majorStatus == .none else {
            return alwaysHits ? ["But it failed!"] : []
        }
        if typeMatchesTarget(moveType: "POISON", target: defender) {
            return alwaysHits ? ["It doesn't affect \(defender.nickname)!"] : []
        }
        if alwaysHits == false {
            let threshold = move.effect == "POISON_SIDE_EFFECT2" ? 103 : 52
            if nextBattleRandomByte() >= threshold {
                return []
            }
        }
        defender.majorStatus = .poison
        defender.isBadlyPoisoned = badlyPoisoned
        defender.battleEffects.toxicCounter = 0
        return [badlyPoisoned ? "\(defender.nickname) was badly poisoned!" : "\(defender.nickname) was poisoned!"]
    }

    func applyParalysis(
        move: MoveManifest,
        defender: inout RuntimePokemonState,
        alwaysHits: Bool
    ) -> [String] {
        guard defender.majorStatus == .none else {
            return alwaysHits ? ["But it failed!"] : []
        }
        if move.type == "ELECTRIC", typeMatchesTarget(moveType: "GROUND", target: defender) {
            return alwaysHits ? ["It doesn't affect \(defender.nickname)!"] : []
        }
        if alwaysHits == false, typeMatchesTarget(moveType: move.type, target: defender) {
            return []
        }
        if alwaysHits == false {
            let threshold = move.effect == "PARALYZE_SIDE_EFFECT2" ? 77 : 26
            if nextBattleRandomByte() >= threshold {
                return []
            }
        }
        defender.majorStatus = .paralysis
        return ["\(defender.nickname) may not attack!"]
    }

    func applyBurn(
        move: MoveManifest,
        defender: inout RuntimePokemonState
    ) -> [String] {
        guard defender.majorStatus == .none else { return [] }
        if typeMatchesTarget(moveType: move.type, target: defender) {
            return []
        }
        let threshold = move.effect == "BURN_SIDE_EFFECT2" ? 77 : 26
        if nextBattleRandomByte() >= threshold {
            return []
        }
        defender.majorStatus = .burn
        return ["\(defender.nickname) was burned!"]
    }

    func applyFreeze(
        move: MoveManifest,
        defender: inout RuntimePokemonState
    ) -> [String] {
        guard defender.majorStatus == .none else { return [] }
        if typeMatchesTarget(moveType: move.type, target: defender) {
            return []
        }
        let threshold = move.effect == "FREEZE_SIDE_EFFECT2" ? 77 : 26
        if nextBattleRandomByte() >= threshold {
            return []
        }
        defender.majorStatus = .freeze
        defender.battleEffects.needsRecharge = false
        return ["\(defender.nickname) was frozen solid!"]
    }

    func applyConfusion(to defender: inout RuntimePokemonState, alwaysHits: Bool) -> [String] {
        guard defender.battleEffects.confusionTurnsRemaining == 0 else {
            return alwaysHits ? ["But it failed!"] : []
        }
        if alwaysHits == false, nextBattleRandomByte() >= 26 {
            return []
        }
        defender.battleEffects.confusionTurnsRemaining = 2 + (nextBattleRandomByte() & 0x3)
        return ["\(defender.nickname) became confused!"]
    }

    func applyFlinch(
        to defender: inout RuntimePokemonState,
        effect: String,
        defenderCanActLaterInTurn: Bool
    ) -> [String] {
        guard defenderCanActLaterInTurn else { return [] }
        let threshold = effect == "FLINCH_SIDE_EFFECT2" ? 77 : 26
        if nextBattleRandomByte() >= threshold {
            return []
        }
        defender.battleEffects.isFlinched = true
        return []
    }

    func applyDrainRecovery(
        move: MoveManifest,
        dealtDamage: Int,
        attacker: inout RuntimePokemonState,
        defender: RuntimePokemonState
    ) -> [String] {
        guard dealtDamage > 0, attacker.currentHP > 0 else { return [] }
        let recovery = max(1, dealtDamage / 2)
        attacker.currentHP = min(attacker.maxHP, attacker.currentHP + recovery)
        if move.effect == "DREAM_EATER_EFFECT" {
            return ["\(defender.nickname)'s dream was eaten!"]
        }
        return ["Sucked health from \(defender.nickname)!"]
    }

    func applyRecoilDamage(
        move: MoveManifest,
        dealtDamage: Int,
        attacker: inout RuntimePokemonState
    ) -> [String] {
        guard dealtDamage > 0, attacker.currentHP > 0 else { return [] }
        let divisor = move.id == "STRUGGLE" ? 2 : 4
        let recoil = max(1, dealtDamage / divisor)
        attacker.currentHP = max(0, attacker.currentHP - recoil)
        return ["\(attacker.nickname) is hit with recoil!"]
    }

    func applyJumpKickCrashDamage(to attacker: inout RuntimePokemonState) -> [String] {
        guard attacker.currentHP > 0 else { return [] }
        attacker.currentHP = max(0, attacker.currentHP - 1)
        return ["\(attacker.nickname) kept going and crashed!"]
    }

    func applyHealingMove(move: MoveManifest, attacker: inout RuntimePokemonState) -> [String] {
        guard attacker.currentHP < attacker.maxHP else {
            return ["But it failed!"]
        }

        if move.id == "REST" {
            let hadStatus = attacker.majorStatus != .none
            attacker.majorStatus = .sleep
            attacker.statusCounter = 2
            attacker.currentHP = attacker.maxHP
            attacker.isBadlyPoisoned = false
            attacker.battleEffects.toxicCounter = 0
            return [hadStatus ? "\(attacker.nickname) fell asleep and became healthy!" : "\(attacker.nickname) started sleeping!"]
        }

        let recovery = max(1, attacker.maxHP / 2)
        attacker.currentHP = min(attacker.maxHP, attacker.currentHP + recovery)
        return ["\(attacker.nickname) regained health!"]
    }

    func applyMist(to attacker: inout RuntimePokemonState) -> [String] {
        guard attacker.battleEffects.isProtectedByMist == false else {
            return ["But it failed!"]
        }
        attacker.battleEffects.isProtectedByMist = true
        return ["\(attacker.nickname) is shrouded in mist!"]
    }

    enum BattleScreenKind {
        case physical
        case special
    }

    func applyScreen(to attacker: inout RuntimePokemonState, kind: BattleScreenKind) -> [String] {
        switch kind {
        case .physical:
            guard attacker.battleEffects.hasReflect == false else {
                return ["But it failed!"]
            }
            attacker.battleEffects.hasReflect = true
            return ["\(attacker.nickname) gained armor!"]
        case .special:
            guard attacker.battleEffects.hasLightScreen == false else {
                return ["But it failed!"]
            }
            attacker.battleEffects.hasLightScreen = true
            return ["\(attacker.nickname) is protected by Light Screen!"]
        }
    }

    func applyHaze(attacker: inout RuntimePokemonState, defender: inout RuntimePokemonState) -> [String] {
        resetBattleStages(for: &attacker)
        resetBattleStages(for: &defender)
        clearVolatileBattleState(for: &attacker)
        clearVolatileBattleState(for: &defender)
        defender.majorStatus = .none
        defender.statusCounter = 0
        defender.isBadlyPoisoned = false
        defender.battleEffects.toxicCounter = 0
        return ["All status changes were eliminated!"]
    }

    func applyLeechSeed(to defender: inout RuntimePokemonState) -> [String] {
        if typeMatchesTarget(moveType: "GRASS", target: defender) {
            return ["It doesn't affect \(defender.nickname)!"]
        }
        guard defender.battleEffects.isSeeded == false else {
            return ["But it failed!"]
        }
        defender.battleEffects.isSeeded = true
        return ["\(defender.nickname) was seeded!"]
    }

    func applyDisable(to defender: inout RuntimePokemonState) -> [String] {
        guard defender.battleEffects.disabledTurnsRemaining == 0 else {
            return ["But it failed!"]
        }
        let candidates = defender.moves.filter { $0.currentPP > 0 && $0.id != "NO_MOVE" }
        guard candidates.isEmpty == false else {
            return ["But it failed!"]
        }
        let selected = candidates[nextBattleRandomByte() % candidates.count]
        defender.battleEffects.disabledMoveID = selected.id
        defender.battleEffects.disabledTurnsRemaining = 1 + (nextBattleRandomByte() & 0x7)
        let moveName = content.move(id: selected.id)?.displayName ?? selected.id
        return ["\(moveName) was disabled!"]
    }

    func applyFocusEnergy(to attacker: inout RuntimePokemonState) -> [String] {
        guard attacker.battleEffects.isGettingPumped == false else {
            return ["But it failed!"]
        }
        attacker.battleEffects.isGettingPumped = true
        return ["\(attacker.nickname) is getting pumped!"]
    }

    func applyConversion(attacker: inout RuntimePokemonState, defender: RuntimePokemonState) -> [String] {
        guard defender.battleEffects.isInvulnerable == false else {
            return ["But it failed!"]
        }

        let defenderTypes = effectiveTypes(for: defender)
        attacker.battleEffects.typeOverridePrimary = defenderTypes.primary
        attacker.battleEffects.typeOverrideSecondary = defenderTypes.secondary
        return ["\(attacker.nickname) converted its type!"]
    }

    func applyBide(to attacker: inout RuntimePokemonState) -> [String] {
        if attacker.battleEffects.pendingBideDamage != nil {
            attacker.battleEffects.pendingBideDamage = nil
            attacker.battleEffects.bideAccumulatedDamage = 0
            return []
        }

        attacker.battleEffects.bideAccumulatedDamage = 0
        attacker.battleEffects.pendingBideDamage = nil
        attacker.battleEffects.bideTurnsRemaining = 2 + (nextBattleRandomByte() & 0x1)
        return []
    }

    func applyThrash(move: MoveManifest, attacker: inout RuntimePokemonState) -> [String] {
        if attacker.battleEffects.thrashTurnsRemaining > 0 {
            return []
        }

        attacker.battleEffects.thrashTurnsRemaining = 1 + (nextBattleRandomByte() & 0x1)
        attacker.battleEffects.thrashMoveID = move.id
        return []
    }

    func applySwitchAndTeleportMessages(move: MoveManifest, attacker: RuntimePokemonState, defender: RuntimePokemonState) -> [String] {
        if gameplayState?.battle?.kind != .wild {
            return move.id == "TELEPORT" ? ["But it failed!"] : ["Is unaffected!"]
        }

        if applySwitchAndTeleport(move: move, attacker: attacker, defender: defender) {
            switch move.id {
            case "TELEPORT":
                return ["Ran from battle!"]
            case "ROAR":
                return ["Ran away scared!"]
            default:
                return ["Was blown away!"]
            }
        }

        return move.id == "TELEPORT" ? ["But it failed!"] : ["But it failed!"]
    }

    func applyTrapping(move: MoveManifest, dealtDamage: Int, attacker: inout RuntimePokemonState) -> [String] {
        if attacker.battleEffects.trappingTurnsRemaining > 0 {
            return []
        }

        var turns = nextBattleRandomByte() & 0x3
        if turns >= 2 {
            turns = nextBattleRandomByte() & 0x3
        }
        attacker.battleEffects.trappingTurnsRemaining = turns + 1
        attacker.battleEffects.trappingMoveID = move.id
        attacker.battleEffects.trappingDamage = max(0, dealtDamage)
        return []
    }

    func applyTransform(attacker: inout RuntimePokemonState, defender: RuntimePokemonState) -> [String] {
        guard defender.battleEffects.isInvulnerable == false,
              attacker.battleEffects.transformedState == nil else {
            return ["But it failed!"]
        }

        attacker.battleEffects.transformedState = .init(
            originalSpeciesID: attacker.speciesID,
            originalAttack: attacker.attack,
            originalDefense: attacker.defense,
            originalSpeed: attacker.speed,
            originalSpecial: attacker.special,
            originalAttackStage: attacker.attackStage,
            originalDefenseStage: attacker.defenseStage,
            originalSpeedStage: attacker.speedStage,
            originalSpecialStage: attacker.specialStage,
            originalAccuracyStage: attacker.accuracyStage,
            originalEvasionStage: attacker.evasionStage,
            originalMoves: attacker.moves
        )
        attacker.speciesID = defender.speciesID
        attacker.attack = defender.attack
        attacker.defense = defender.defense
        attacker.speed = defender.speed
        attacker.special = defender.special
        attacker.attackStage = defender.attackStage
        attacker.defenseStage = defender.defenseStage
        attacker.speedStage = defender.speedStage
        attacker.specialStage = defender.specialStage
        attacker.accuracyStage = defender.accuracyStage
        attacker.evasionStage = defender.evasionStage
        attacker.moves = defender.moves.map { move in
            RuntimeMoveState(id: move.id, currentPP: move.id == "NO_MOVE" ? 0 : 5)
        }
        attacker.battleEffects.transformedSpeciesID = defender.speciesID
        attacker.battleEffects.typeOverridePrimary = nil
        attacker.battleEffects.typeOverrideSecondary = nil
        return ["\(attacker.nickname) transformed!"]
    }

    func applySubstitute(to attacker: inout RuntimePokemonState) -> [String] {
        guard attacker.battleEffects.hasSubstitute == false else {
            return ["But it failed!"]
        }

        let cost = max(1, attacker.maxHP / 4)
        guard attacker.currentHP > cost else {
            return ["Too weak to make a substitute!"]
        }

        attacker.currentHP -= cost
        attacker.battleEffects.hasSubstitute = true
        attacker.battleEffects.substituteHP = cost
        return ["\(attacker.nickname) made a substitute!"]
    }

    func applyRage(to attacker: inout RuntimePokemonState) -> [String] {
        attacker.battleEffects.isUsingRage = true
        return []
    }

    func applyRageBuild(to defender: inout RuntimePokemonState) -> [String] {
        guard defender.attackStage < 6 else {
            return []
        }
        defender.attackStage += 1
        return ["\(defender.nickname)'s Rage is building!", "\(defender.nickname)'s Attack rose!"]
    }

    func applyMimic(
        moveIndex: Int,
        attacker: inout RuntimePokemonState,
        defender: RuntimePokemonState
    ) -> [String] {
        guard attacker.moves.indices.contains(moveIndex),
              defender.battleEffects.isInvulnerable == false else {
            return ["But it failed!"]
        }

        let candidates = defender.moves.enumerated().filter { $0.element.id != "NO_MOVE" }
        guard candidates.isEmpty == false else {
            return ["But it failed!"]
        }
        let selected = candidates[nextBattleRandomByte() % candidates.count]

        if attacker.battleEffects.mimicState == nil {
            attacker.battleEffects.mimicState = .init(
                slotIndex: moveIndex,
                originalMove: attacker.moves[moveIndex]
            )
        }
        attacker.moves[moveIndex].id = selected.element.id

        let moveName = content.move(id: selected.element.id)?.displayName ?? selected.element.id
        return ["\(attacker.nickname) learned \(moveName)!"]
    }

    func applyExplosionRecoil(to attacker: inout RuntimePokemonState) -> [String] {
        attacker.currentHP = 0
        attacker.majorStatus = .none
        attacker.statusCounter = 0
        attacker.isBadlyPoisoned = false
        attacker.battleEffects.isSeeded = false
        attacker.battleEffects.toxicCounter = 0
        return []
    }

    func applyConfusionSelfDamage(to pokemon: inout RuntimePokemonState) -> [String] {
        pokemon.currentHP = max(0, pokemon.currentHP - confusionSelfDamage(for: pokemon))
        pokemon.battleEffects.isFlinched = false
        pokemon.battleEffects.needsRecharge = false
        return ["It hurt itself in its confusion!"]
    }

    func applyResidualBattleEffects(
        to actingPokemon: inout RuntimePokemonState,
        opponent: inout RuntimePokemonState
    ) -> [String] {
        var messages: [String] = []

        switch actingPokemon.majorStatus {
        case .burn:
            let damage = residualDamageAmount(for: &actingPokemon, toxic: false)
            actingPokemon.currentHP = max(0, actingPokemon.currentHP - damage)
            messages.append("\(actingPokemon.nickname) is hurt by its burn!")
        case .poison:
            let damage = residualDamageAmount(for: &actingPokemon, toxic: actingPokemon.isBadlyPoisoned)
            actingPokemon.currentHP = max(0, actingPokemon.currentHP - damage)
            messages.append(
                actingPokemon.isBadlyPoisoned
                    ? "\(actingPokemon.nickname) is hurt by poison!"
                    : "\(actingPokemon.nickname) is hurt by poison!"
            )
        default:
            break
        }

        if actingPokemon.currentHP > 0, actingPokemon.battleEffects.isSeeded {
            let drain = residualDamageAmount(for: &actingPokemon, toxic: actingPokemon.isBadlyPoisoned)
            actingPokemon.currentHP = max(0, actingPokemon.currentHP - drain)
            opponent.currentHP = min(opponent.maxHP, opponent.currentHP + drain)
            messages.append("\(actingPokemon.nickname) is drained by Leech Seed!")
        }

        return messages
    }

    func residualDamageAmount(for pokemon: inout RuntimePokemonState, toxic: Bool) -> Int {
        let baseDamage = max(1, pokemon.maxHP / 16)
        guard toxic else {
            return baseDamage
        }
        pokemon.battleEffects.toxicCounter += 1
        return max(1, baseDamage * max(1, pokemon.battleEffects.toxicCounter))
    }

    func confusionSelfDamage(for pokemon: RuntimePokemonState) -> Int {
        let adjustedAttack = max(1, scaledStat(pokemon.attack, stage: pokemon.attackStage))
        let adjustedDefense = max(1, scaledStat(pokemon.defense, stage: pokemon.defenseStage))
        let damage = (((((2 * pokemon.level) / 5) + 2) * 40 * adjustedAttack) / adjustedDefense) / 50 + 2
        return max(1, damage)
    }

    func effectiveTypes(for pokemon: RuntimePokemonState) -> (primary: String, secondary: String?) {
        if let primary = pokemon.battleEffects.typeOverridePrimary {
            return (primary, pokemon.battleEffects.typeOverrideSecondary)
        }

        guard let species = content.species(id: pokemon.speciesID) else {
            return ("NORMAL", nil)
        }
        return (species.primaryType, species.secondaryType)
    }

    func typeMatchesTarget(moveType: String, target: RuntimePokemonState) -> Bool {
        let types = effectiveTypes(for: target)
        return types.primary == moveType || types.secondary == moveType
    }

    func clearVolatileBattleState(for pokemon: inout RuntimePokemonState) {
        pokemon.battleEffects.confusionTurnsRemaining = 0
        pokemon.battleEffects.disabledMoveID = nil
        pokemon.battleEffects.disabledTurnsRemaining = 0
        pokemon.battleEffects.isProtectedByMist = false
        pokemon.battleEffects.hasLightScreen = false
        pokemon.battleEffects.hasReflect = false
        pokemon.battleEffects.isGettingPumped = false
        pokemon.battleEffects.isSeeded = false
        pokemon.battleEffects.needsRecharge = false
        pokemon.battleEffects.isFlinched = false
    }

    func forcedMoveIndex(for pokemon: RuntimePokemonState) -> Int? {
        let forcedMoveID: String?
        if pokemon.battleEffects.bideTurnsRemaining > 0 {
            forcedMoveID = "BIDE"
        } else if let chargingMoveID = pokemon.battleEffects.chargingMoveID {
            forcedMoveID = chargingMoveID
        } else if pokemon.battleEffects.thrashTurnsRemaining > 0 {
            forcedMoveID = pokemon.battleEffects.thrashMoveID
        } else if pokemon.battleEffects.trappingTurnsRemaining > 0 {
            forcedMoveID = pokemon.battleEffects.trappingMoveID
        } else if pokemon.battleEffects.isUsingRage {
            forcedMoveID = "RAGE"
        } else {
            forcedMoveID = nil
        }

        guard let forcedMoveID else {
            return nil
        }
        return pokemon.moves.firstIndex { $0.id == forcedMoveID }
    }

    func resetBattleStages(for pokemon: inout RuntimePokemonState) {
        pokemon.attackStage = 0
        pokemon.defenseStage = 0
        pokemon.speedStage = 0
        pokemon.specialStage = 0
        pokemon.accuracyStage = 0
        pokemon.evasionStage = 0
    }

    func selectEnemyMoveIndex(
        battle: RuntimeBattleState,
        enemyPokemon: RuntimePokemonState,
        playerPokemon: RuntimePokemonState
    ) -> Int {
        if let forcedMoveIndex = forcedMoveIndex(for: enemyPokemon) {
            return forcedMoveIndex
        }
        let availableMoves = enemyPokemon.moves.enumerated().filter { $0.element.currentPP > 0 }
        guard availableMoves.isEmpty == false else { return 0 }
        let selectableMoves = availableMoves.filter { entry in
            enemyPokemon.battleEffects.disabledTurnsRemaining == 0 ||
                entry.element.id != enemyPokemon.battleEffects.disabledMoveID
        }
        let candidateMoves = selectableMoves.isEmpty ? availableMoves : selectableMoves

        if battle.kind == .wild {
            return chooseRandomMoveIndex(from: candidateMoves)
        }

        let trainerClass = battle.trainerClass ?? ""
        let modifications = content.trainerAIMoveChoiceModifications(trainerClass: trainerClass)?.modifications ?? []
        guard modifications.isEmpty == false else {
            return chooseRandomMoveIndex(from: candidateMoves)
        }

        var discouragements = Array(repeating: 10, count: enemyPokemon.moves.count)
        applyTrainerAINoOpMoveDiscouragement(
            discouragements: &discouragements,
            enemyPokemon: enemyPokemon,
            playerPokemon: playerPokemon
        )

        for modification in modifications {
            switch modification {
            case 1:
                applyTrainerAIModification1(
                    discouragements: &discouragements,
                    enemyPokemon: enemyPokemon,
                    playerPokemon: playerPokemon
                )
            case 2:
                applyTrainerAIModification2(
                    discouragements: &discouragements,
                    enemyPokemon: enemyPokemon,
                    layer2EncouragementValue: battle.aiLayer2Encouragement
                )
            case 3:
                applyTrainerAIModification3(
                    discouragements: &discouragements,
                    enemyPokemon: enemyPokemon,
                    playerPokemon: playerPokemon
                )
            default:
                break
            }
        }

        let selectable = candidateMoves.filter { entry in
            discouragements.indices.contains(entry.offset)
        }
        let minimumDiscouragement = selectable.map { discouragements[$0.offset] }.min() ?? 10
        let candidates = selectable.filter { discouragements[$0.offset] == minimumDiscouragement }
        return chooseRandomMoveIndex(from: candidates)
    }

    func applyTrainerAINoOpMoveDiscouragement(
        discouragements: inout [Int],
        enemyPokemon: RuntimePokemonState,
        playerPokemon: RuntimePokemonState
    ) {
        for (index, runtimeMove) in enemyPokemon.moves.enumerated() {
            guard discouragements.indices.contains(index),
                  runtimeMove.currentPP > 0,
                  let move = content.move(id: runtimeMove.id),
                  move.power == 0,
                  let descriptor = statStageEffectDescriptor(for: move.effect),
                  descriptor.isSideEffect == false,
                  statStageMoveWouldBeNoOp(
                    descriptor: descriptor,
                    attacker: enemyPokemon,
                    defender: playerPokemon
                  ) else {
                continue
            }
            discouragements[index] += 5
        }
    }

    func chooseRandomMoveIndex(
        from availableMoves: [EnumeratedSequence<[RuntimeMoveState]>.Element]
    ) -> Int {
        guard availableMoves.isEmpty == false else { return 0 }
        let selected = nextBattleRandomByte() % availableMoves.count
        return availableMoves[selected].offset
    }

    func applyTrainerAIModification1(
        discouragements: inout [Int],
        enemyPokemon: RuntimePokemonState,
        playerPokemon: RuntimePokemonState
    ) {
        guard playerPokemon.majorStatus != .none else {
            return
        }

        for (index, runtimeMove) in enemyPokemon.moves.enumerated() {
            guard discouragements.indices.contains(index),
                  runtimeMove.currentPP > 0,
                  let move = content.move(id: runtimeMove.id),
                  move.power == 0,
                  Self.trainerAIStatusAilmentEffects.contains(move.effect) else {
                continue
            }
            discouragements[index] += 5
        }
    }

    func applyTrainerAIModification2(
        discouragements: inout [Int],
        enemyPokemon: RuntimePokemonState,
        layer2EncouragementValue: Int
    ) {
        guard layer2EncouragementValue == 1 else {
            return
        }

        for (index, runtimeMove) in enemyPokemon.moves.enumerated() {
            guard discouragements.indices.contains(index),
                  runtimeMove.currentPP > 0,
                  let move = content.move(id: runtimeMove.id),
                  Self.trainerAIModification2PreferredEffects.contains(move.effect) else {
                continue
            }
            discouragements[index] -= 1
        }
    }

    func applyTrainerAIModification3(
        discouragements: inout [Int],
        enemyPokemon: RuntimePokemonState,
        playerPokemon: RuntimePokemonState
    ) {
        for (index, runtimeMove) in enemyPokemon.moves.enumerated() {
            guard discouragements.indices.contains(index),
                  runtimeMove.currentPP > 0,
                  let move = content.move(id: runtimeMove.id) else {
                continue
            }

            let typeMultiplier = totalTypeMultiplier(for: move.type, defender: playerPokemon)
            if typeMultiplier > 10 {
                discouragements[index] -= 1
                continue
            }

            guard typeMultiplier < 10,
                  trainerAIHasBetterAlternativeMove(
                    currentMove: move,
                    enemyPokemon: enemyPokemon
                  ) else {
                continue
            }
            discouragements[index] += 1
        }
    }

    func trainerAIHasBetterAlternativeMove(currentMove: MoveManifest, enemyPokemon: RuntimePokemonState) -> Bool {
        for runtimeMove in enemyPokemon.moves where runtimeMove.currentPP > 0 {
            guard let move = content.move(id: runtimeMove.id) else {
                continue
            }
            switch move.effect {
            case "SUPER_FANG_EFFECT", "SPECIAL_DAMAGE_EFFECT", "FLY_EFFECT":
                return true
            default:
                break
            }

            if move.type != currentMove.type && move.power > 0 {
                return true
            }
        }

        return false
    }

    func projectedDamage(move: MoveManifest, attacker: RuntimePokemonState, defender: RuntimePokemonState) -> Int {
        guard move.power > 0 else { return 0 }
        let adjustedAttack = adjustedOffenseStat(for: attacker, moveType: move.type, criticalHit: false)
        let adjustedDefense = max(1, adjustedDefenseStat(for: defender, moveType: move.type, moveEffect: move.effect, criticalHit: false))
        var damage = max(1, (((((2 * attacker.level) / 5) + 2) * move.power * adjustedAttack) / adjustedDefense) / 50 + 2)
        if hasSTAB(attacker: attacker, moveType: move.type) {
            damage += damage / 2
        }
        let resolvedDamage = applyTypeMultiplier(totalTypeMultiplier(for: move.type, defender: defender), to: damage)
        return resolvedDamage * expectedHitCount(for: move.effect)
    }

    func hasSTAB(attacker: RuntimePokemonState, moveType: String) -> Bool {
        let types = effectiveTypes(for: attacker)
        return types.primary == moveType || types.secondary == moveType
    }

    func totalTypeMultiplier(for moveType: String, defender: RuntimePokemonState) -> Int {
        let types = effectiveTypes(for: defender)
        let defendingTypes = [types.primary, types.secondary].compactMap { $0 }
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

    func adjustedOffenseStat(for pokemon: RuntimePokemonState, moveType: String, criticalHit: Bool) -> Int {
        if usesSpecialDamage(for: moveType) {
            return adjustedSpecialStat(for: pokemon, criticalHit: criticalHit)
        }
        return adjustedAttackStat(for: pokemon, criticalHit: criticalHit)
    }

    func adjustedDefenseStat(
        for pokemon: RuntimePokemonState,
        moveType: String,
        moveEffect: String,
        criticalHit: Bool
    ) -> Int {
        if usesSpecialDamage(for: moveType) {
            let special = adjustedSpecialStat(for: pokemon, criticalHit: criticalHit)
            return pokemon.battleEffects.hasLightScreen && criticalHit == false ? max(1, special * 2) : special
        }
        let defense = adjustedPhysicalDefenseStat(for: pokemon, criticalHit: criticalHit)
        if moveEffect == "EXPLODE_EFFECT" {
            return max(1, defense / 2)
        }
        return pokemon.battleEffects.hasReflect && criticalHit == false ? max(1, defense * 2) : defense
    }

    func adjustedAttackStat(for pokemon: RuntimePokemonState, criticalHit: Bool) -> Int {
        if criticalHit {
            return pokemon.majorStatus == .burn ? max(1, pokemon.attack / 2) : max(1, pokemon.attack)
        }
        let scaled = max(1, scaledStat(pokemon.attack, stage: pokemon.attackStage))
        if pokemon.majorStatus == .burn {
            return max(1, scaled / 2)
        }
        return scaled
    }

    func adjustedPhysicalDefenseStat(for pokemon: RuntimePokemonState, criticalHit: Bool) -> Int {
        if criticalHit {
            return max(1, pokemon.defense)
        }
        return max(1, scaledStat(pokemon.defense, stage: pokemon.defenseStage))
    }

    func adjustedSpeedStat(for pokemon: RuntimePokemonState) -> Int {
        let scaled = max(1, scaledStat(pokemon.speed, stage: pokemon.speedStage))
        if pokemon.majorStatus == .paralysis {
            return max(1, scaled / 4)
        }
        return scaled
    }

    func adjustedSpecialStat(for pokemon: RuntimePokemonState, criticalHit: Bool) -> Int {
        if criticalHit {
            return max(1, pokemon.special)
        }
        return max(1, scaledStat(pokemon.special, stage: pokemon.specialStage))
    }

    func usesSpecialDamage(for moveType: String) -> Bool {
        Self.specialMoveTypes.contains(moveType)
    }

    func isCriticalHit(for pokemon: RuntimePokemonState) -> Bool {
        let baseSpeed = content.species(id: pokemon.speciesID)?.baseSpeed ?? 0
        var threshold = min(255, max(1, baseSpeed / 2))
        if pokemon.battleEffects.isGettingPumped {
            threshold = max(1, threshold / 4)
        }
        return nextBattleRandomByte() < threshold
    }

    private func statStageEffectDescriptor(for effect: String) -> StatStageEffectDescriptor? {
        switch effect {
        case "ATTACK_UP1_EFFECT":
            return .init(target: .attacker, stat: .attack, stageDelta: 1, isSideEffect: false)
        case "DEFENSE_UP1_EFFECT":
            return .init(target: .attacker, stat: .defense, stageDelta: 1, isSideEffect: false)
        case "SPEED_UP1_EFFECT":
            return .init(target: .attacker, stat: .speed, stageDelta: 1, isSideEffect: false)
        case "SPECIAL_UP1_EFFECT":
            return .init(target: .attacker, stat: .special, stageDelta: 1, isSideEffect: false)
        case "ACCURACY_UP1_EFFECT":
            return .init(target: .attacker, stat: .accuracy, stageDelta: 1, isSideEffect: false)
        case "EVASION_UP1_EFFECT":
            return .init(target: .attacker, stat: .evasion, stageDelta: 1, isSideEffect: false)
        case "ATTACK_DOWN1_EFFECT":
            return .init(target: .defender, stat: .attack, stageDelta: -1, isSideEffect: false)
        case "DEFENSE_DOWN1_EFFECT":
            return .init(target: .defender, stat: .defense, stageDelta: -1, isSideEffect: false)
        case "SPEED_DOWN1_EFFECT":
            return .init(target: .defender, stat: .speed, stageDelta: -1, isSideEffect: false)
        case "SPECIAL_DOWN1_EFFECT":
            return .init(target: .defender, stat: .special, stageDelta: -1, isSideEffect: false)
        case "ACCURACY_DOWN1_EFFECT":
            return .init(target: .defender, stat: .accuracy, stageDelta: -1, isSideEffect: false)
        case "EVASION_DOWN1_EFFECT":
            return .init(target: .defender, stat: .evasion, stageDelta: -1, isSideEffect: false)
        case "ATTACK_UP2_EFFECT":
            return .init(target: .attacker, stat: .attack, stageDelta: 2, isSideEffect: false)
        case "DEFENSE_UP2_EFFECT":
            return .init(target: .attacker, stat: .defense, stageDelta: 2, isSideEffect: false)
        case "SPEED_UP2_EFFECT":
            return .init(target: .attacker, stat: .speed, stageDelta: 2, isSideEffect: false)
        case "SPECIAL_UP2_EFFECT":
            return .init(target: .attacker, stat: .special, stageDelta: 2, isSideEffect: false)
        case "ACCURACY_UP2_EFFECT":
            return .init(target: .attacker, stat: .accuracy, stageDelta: 2, isSideEffect: false)
        case "EVASION_UP2_EFFECT":
            return .init(target: .attacker, stat: .evasion, stageDelta: 2, isSideEffect: false)
        case "ATTACK_DOWN2_EFFECT":
            return .init(target: .defender, stat: .attack, stageDelta: -2, isSideEffect: false)
        case "DEFENSE_DOWN2_EFFECT":
            return .init(target: .defender, stat: .defense, stageDelta: -2, isSideEffect: false)
        case "SPEED_DOWN2_EFFECT":
            return .init(target: .defender, stat: .speed, stageDelta: -2, isSideEffect: false)
        case "SPECIAL_DOWN2_EFFECT":
            return .init(target: .defender, stat: .special, stageDelta: -2, isSideEffect: false)
        case "ACCURACY_DOWN2_EFFECT":
            return .init(target: .defender, stat: .accuracy, stageDelta: -2, isSideEffect: false)
        case "EVASION_DOWN2_EFFECT":
            return .init(target: .defender, stat: .evasion, stageDelta: -2, isSideEffect: false)
        case "ATTACK_DOWN_SIDE_EFFECT":
            return .init(target: .defender, stat: .attack, stageDelta: -1, isSideEffect: true)
        case "DEFENSE_DOWN_SIDE_EFFECT":
            return .init(target: .defender, stat: .defense, stageDelta: -1, isSideEffect: true)
        case "SPEED_DOWN_SIDE_EFFECT":
            return .init(target: .defender, stat: .speed, stageDelta: -1, isSideEffect: true)
        case "SPECIAL_DOWN_SIDE_EFFECT":
            return .init(target: .defender, stat: .special, stageDelta: -1, isSideEffect: true)
        default:
            return nil
        }
    }

    private func applyStageChange(
        delta: Int,
        stat: BattleStatKind,
        to pokemon: inout RuntimePokemonState,
        failureMessage: String?
    ) -> [String] {
        let currentStage = stageValue(for: stat, in: pokemon)
        let boundedStage = max(-6, min(6, currentStage + delta))
        guard boundedStage != currentStage else {
            return failureMessage.map { [$0] } ?? []
        }

        setStageValue(boundedStage, for: stat, in: &pokemon)

        if delta > 0 {
            let roseText = abs(delta) >= 2 ? "greatly rose!" : "rose!"
            return ["\(pokemon.nickname)'s \(stat.displayName) \(roseText)"]
        }

        let fellText = abs(delta) >= 2 ? "greatly fell!" : "fell!"
        return ["\(pokemon.nickname)'s \(stat.displayName) \(fellText)"]
    }

    private func statStageMoveWouldBeNoOp(
        descriptor: StatStageEffectDescriptor,
        attacker: RuntimePokemonState,
        defender: RuntimePokemonState
    ) -> Bool {
        let affectedPokemon: RuntimePokemonState
        switch descriptor.target {
        case .attacker:
            affectedPokemon = attacker
        case .defender:
            affectedPokemon = defender
        }

        let currentStage = stageValue(for: descriptor.stat, in: affectedPokemon)
        if descriptor.stageDelta > 0 {
            return currentStage >= 6
        }
        return currentStage <= -6
    }

    private func stageValue(for stat: BattleStatKind, in pokemon: RuntimePokemonState) -> Int {
        switch stat {
        case .attack:
            return pokemon.attackStage
        case .defense:
            return pokemon.defenseStage
        case .speed:
            return pokemon.speedStage
        case .special:
            return pokemon.specialStage
        case .accuracy:
            return pokemon.accuracyStage
        case .evasion:
            return pokemon.evasionStage
        }
    }

    private func setStageValue(_ value: Int, for stat: BattleStatKind, in pokemon: inout RuntimePokemonState) {
        switch stat {
        case .attack:
            pokemon.attackStage = value
        case .defense:
            pokemon.defenseStage = value
        case .speed:
            pokemon.speedStage = value
        case .special:
            pokemon.specialStage = value
        case .accuracy:
            pokemon.accuracyStage = value
        case .evasion:
            pokemon.evasionStage = value
        }
    }
}
