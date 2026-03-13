import PokeDataModel

extension GameRuntime {
    func applyMoveEffect(
        _ move: MoveManifest,
        moveIndex: Int,
        dealtDamage: Int,
        attacker: inout RuntimePokemonState,
        defender: inout RuntimePokemonState,
        defenderCanActLaterInTurn: Bool,
        pendingAction: inout RuntimeBattlePendingAction?
    ) -> [String] {
        let effect = move.effect
        guard let descriptor = statStageEffectDescriptor(for: effect) else {
            return applyNonStatMoveEffect(
                move: move,
                moveIndex: moveIndex,
                dealtDamage: dealtDamage,
                attacker: &attacker,
                defender: &defender,
                defenderCanActLaterInTurn: defenderCanActLaterInTurn,
                pendingAction: &pendingAction
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

    func requiresSleepingTarget(_ move: MoveManifest) -> Bool {
        move.effect == "DREAM_EATER_EFFECT"
    }

    func applyJumpKickCrashDamage(to attacker: inout RuntimePokemonState) -> [String] {
        guard attacker.currentHP > 0 else { return [] }
        attacker.currentHP = max(0, attacker.currentHP - 1)
        return ["\(attacker.nickname) kept going and crashed!"]
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

    private func effectTargetsOpponent(_ effect: String) -> Bool {
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

    private func applyNonStatMoveEffect(
        move: MoveManifest,
        moveIndex: Int,
        dealtDamage: Int,
        attacker: inout RuntimePokemonState,
        defender: inout RuntimePokemonState,
        defenderCanActLaterInTurn: Bool,
        pendingAction: inout RuntimeBattlePendingAction?
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
            return applyHaze(
                attacker: &attacker,
                defender: &defender,
                defenderCanActLaterInTurn: defenderCanActLaterInTurn
            )
        case "BIDE_EFFECT":
            return applyBide(to: &attacker)
        case "THRASH_PETAL_DANCE_EFFECT":
            return applyThrash(move: move, attacker: &attacker)
        case "SWITCH_AND_TELEPORT_EFFECT":
            return applySwitchAndTeleportEffect(
                move: move,
                attacker: attacker,
                defender: defender,
                pendingAction: &pendingAction
            )
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

    private func applySleep(move: MoveManifest, defender: inout RuntimePokemonState) -> [String] {
        let bypassStatusAndAccuracyChecks = defender.battleEffects.needsRecharge
        defender.battleEffects.needsRecharge = false

        if bypassStatusAndAccuracyChecks == false {
            guard defender.majorStatus == .none else {
                return defender.majorStatus == .sleep
                    ? ["\(defender.nickname) is already asleep!"]
                    : ["But it failed!"]
            }
        }
        var sleepTurns = 0
        repeat {
            sleepTurns = nextBattleRandomByte() & 0x7
        } while sleepTurns == 0
        defender.majorStatus = .sleep
        defender.statusCounter = sleepTurns
        return ["\(defender.nickname) fell asleep!"]
    }

    private func applyPoison(
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

    private func applyParalysis(
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

    private func applyBurn(
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

    private func applyFreeze(
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

    private func applyConfusion(to defender: inout RuntimePokemonState, alwaysHits: Bool) -> [String] {
        guard defender.battleEffects.confusionTurnsRemaining == 0 else {
            return alwaysHits ? ["But it failed!"] : []
        }
        if alwaysHits == false, nextBattleRandomByte() >= 26 {
            return []
        }
        defender.battleEffects.confusionTurnsRemaining = 2 + (nextBattleRandomByte() & 0x3)
        return ["\(defender.nickname) became confused!"]
    }

    private func applyFlinch(
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

    private func applyDrainRecovery(
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

    private func applyRecoilDamage(
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

    private func applyHealingMove(move: MoveManifest, attacker: inout RuntimePokemonState) -> [String] {
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

    private func applyMist(to attacker: inout RuntimePokemonState) -> [String] {
        guard attacker.battleEffects.isProtectedByMist == false else {
            return ["But it failed!"]
        }
        attacker.battleEffects.isProtectedByMist = true
        return ["\(attacker.nickname) is shrouded in mist!"]
    }

    private enum BattleScreenKind {
        case physical
        case special
    }

    private func applyScreen(to attacker: inout RuntimePokemonState, kind: BattleScreenKind) -> [String] {
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

    private func applyHaze(
        attacker: inout RuntimePokemonState,
        defender: inout RuntimePokemonState,
        defenderCanActLaterInTurn: Bool
    ) -> [String] {
        let curedSleepOrFreeze = defenderCanActLaterInTurn &&
            (defender.majorStatus == .sleep || defender.majorStatus == .freeze)
        resetBattleStages(for: &attacker)
        resetBattleStages(for: &defender)
        clearHazeVolatileBattleState(for: &attacker)
        clearHazeVolatileBattleState(for: &defender)
        attacker.isBadlyPoisoned = false
        attacker.battleEffects.toxicCounter = 0
        defender.majorStatus = .none
        defender.statusCounter = 0
        defender.isBadlyPoisoned = false
        defender.battleEffects.toxicCounter = 0
        defender.battleEffects.skipTurnOnce = curedSleepOrFreeze
        return ["All status changes were eliminated!"]
    }

    private func clearHazeVolatileBattleState(for pokemon: inout RuntimePokemonState) {
        pokemon.battleEffects.confusionTurnsRemaining = 0
        pokemon.battleEffects.disabledMoveID = nil
        pokemon.battleEffects.disabledTurnsRemaining = 0
        pokemon.battleEffects.isProtectedByMist = false
        pokemon.battleEffects.hasLightScreen = false
        pokemon.battleEffects.hasReflect = false
        pokemon.battleEffects.isGettingPumped = false
        pokemon.battleEffects.isSeeded = false
    }

    private func applyLeechSeed(to defender: inout RuntimePokemonState) -> [String] {
        if typeMatchesTarget(moveType: "GRASS", target: defender) {
            return ["It doesn't affect \(defender.nickname)!"]
        }
        guard defender.battleEffects.isSeeded == false else {
            return ["But it failed!"]
        }
        defender.battleEffects.isSeeded = true
        return ["\(defender.nickname) was seeded!"]
    }

    private func applyDisable(to defender: inout RuntimePokemonState) -> [String] {
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

    private func applyFocusEnergy(to attacker: inout RuntimePokemonState) -> [String] {
        guard attacker.battleEffects.isGettingPumped == false else {
            return ["But it failed!"]
        }
        attacker.battleEffects.isGettingPumped = true
        return ["\(attacker.nickname) is getting pumped!"]
    }

    private func applyConversion(attacker: inout RuntimePokemonState, defender: RuntimePokemonState) -> [String] {
        guard defender.battleEffects.isInvulnerable == false else {
            return ["But it failed!"]
        }

        let defenderTypes = effectiveTypes(for: defender)
        attacker.battleEffects.typeOverridePrimary = defenderTypes.primary
        attacker.battleEffects.typeOverrideSecondary = defenderTypes.secondary
        return ["\(attacker.nickname) converted its type!"]
    }

    private func applyBide(to attacker: inout RuntimePokemonState) -> [String] {
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

    private func applyThrash(move: MoveManifest, attacker: inout RuntimePokemonState) -> [String] {
        if attacker.battleEffects.thrashTurnsRemaining > 0 {
            return []
        }

        attacker.battleEffects.thrashTurnsRemaining = 2 + (nextBattleRandomByte() & 0x1)
        attacker.battleEffects.thrashMoveID = move.id
        return []
    }

    private func applySwitchAndTeleportEffect(
        move: MoveManifest,
        attacker: RuntimePokemonState,
        defender: RuntimePokemonState,
        pendingAction: inout RuntimeBattlePendingAction?
    ) -> [String] {
        let succeeded = applySwitchAndTeleport(attacker: attacker, defender: defender)
        if succeeded {
            pendingAction = .escape
        }

        if gameplayState?.battle?.kind != .wild {
            return move.id == "TELEPORT" ? ["But it failed!"] : ["Is unaffected!"]
        }

        if succeeded {
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

    private func applySwitchAndTeleport(attacker: RuntimePokemonState, defender: RuntimePokemonState) -> Bool {
        guard gameplayState?.battle?.kind == .wild else {
            return false
        }

        let attackerLevel = attacker.level
        let defenderLevel = defender.level
        if attackerLevel >= defenderLevel {
            return true
        }

        let threshold = defenderLevel / 4
        let sampleRange = attackerLevel + defenderLevel + 1
        let sample = nextBattleRandomByte() % sampleRange
        if sample >= threshold {
            return true
        }

        return false
    }

    private func applyTrapping(move: MoveManifest, dealtDamage: Int, attacker: inout RuntimePokemonState) -> [String] {
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

    private func applyTransform(attacker: inout RuntimePokemonState, defender: RuntimePokemonState) -> [String] {
        guard defender.battleEffects.isInvulnerable == false,
              attacker.battleEffects.transformedState == nil else {
            return ["But it failed!"]
        }

        let originalMoves = originalMovesForTransformSnapshot(attacker)
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
            originalMoves: originalMoves
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

    func originalMovesForTransformSnapshot(_ pokemon: RuntimePokemonState) -> [RuntimeMoveState] {
        var originalMoves = pokemon.moves
        if let mimicState = pokemon.battleEffects.mimicState,
           originalMoves.indices.contains(mimicState.slotIndex) {
            originalMoves[mimicState.slotIndex] = mimicState.originalMove
        }
        return originalMoves
    }

    private func applySubstitute(to attacker: inout RuntimePokemonState) -> [String] {
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

    private func applyRage(to attacker: inout RuntimePokemonState) -> [String] {
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

    private func applyMimic(
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

    func statStageEffectDescriptor(for effect: String) -> StatStageEffectDescriptor? {
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

    func statStageMoveWouldBeNoOp(
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
