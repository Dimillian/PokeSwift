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
            let adjustedAttack = adjustedOffenseStat(for: attacker, moveType: move.type, criticalHit: isCriticalHit)
            let adjustedDefense = max(1, adjustedDefenseStat(for: defender, moveType: move.type, criticalHit: isCriticalHit))
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

        if move.power == 0 || (typeMultiplier > 0 && defender.currentHP > 0) {
            messages.append(contentsOf: applyMoveEffect(move.effect, attacker: &attacker, defender: &defender))
        }

        return ResolvedBattleMove(messages: messages, dealtDamage: dealtDamage, typeMultiplier: typeMultiplier)
    }

    func applyMoveEffect(
        _ effect: String,
        attacker: inout RuntimePokemonState,
        defender: inout RuntimePokemonState
    ) -> [String] {
        guard let descriptor = statStageEffectDescriptor(for: effect) else {
            return []
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

    func selectEnemyMoveIndex(
        battle: RuntimeBattleState,
        enemyPokemon: RuntimePokemonState,
        playerPokemon: RuntimePokemonState
    ) -> Int {
        let availableMoves = enemyPokemon.moves.enumerated().filter { $0.element.currentPP > 0 }
        guard availableMoves.isEmpty == false else { return 0 }

        if battle.kind == .wild {
            return chooseRandomMoveIndex(from: availableMoves)
        }

        let trainerClass = battle.trainerClass ?? ""
        let modifications = content.trainerAIMoveChoiceModifications(trainerClass: trainerClass)?.modifications ?? []
        guard modifications.isEmpty == false else {
            return chooseRandomMoveIndex(from: availableMoves)
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

        let selectable = availableMoves.filter { entry in
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

            let typeMultiplier = totalTypeMultiplier(for: move.type, defenderSpeciesID: playerPokemon.speciesID)
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
        let adjustedDefense = max(1, adjustedDefenseStat(for: defender, moveType: move.type, criticalHit: false))
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

    func adjustedOffenseStat(for pokemon: RuntimePokemonState, moveType: String, criticalHit: Bool) -> Int {
        if usesSpecialDamage(for: moveType) {
            return adjustedSpecialStat(for: pokemon, criticalHit: criticalHit)
        }
        return adjustedAttackStat(for: pokemon, criticalHit: criticalHit)
    }

    func adjustedDefenseStat(for pokemon: RuntimePokemonState, moveType: String, criticalHit: Bool) -> Int {
        if usesSpecialDamage(for: moveType) {
            return adjustedSpecialStat(for: pokemon, criticalHit: criticalHit)
        }
        return adjustedPhysicalDefenseStat(for: pokemon, criticalHit: criticalHit)
    }

    func adjustedAttackStat(for pokemon: RuntimePokemonState, criticalHit: Bool) -> Int {
        if criticalHit {
            return max(1, pokemon.attack)
        }
        return max(1, scaledStat(pokemon.attack, stage: pokemon.attackStage))
    }

    func adjustedPhysicalDefenseStat(for pokemon: RuntimePokemonState, criticalHit: Bool) -> Int {
        if criticalHit {
            return max(1, pokemon.defense)
        }
        return max(1, scaledStat(pokemon.defense, stage: pokemon.defenseStage))
    }

    func adjustedSpeedStat(for pokemon: RuntimePokemonState) -> Int {
        max(1, scaledStat(pokemon.speed, stage: pokemon.speedStage))
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

    func isCriticalHit(for speciesID: String) -> Bool {
        let baseSpeed = content.species(id: speciesID)?.baseSpeed ?? 0
        let threshold = min(255, max(1, baseSpeed / 2))
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
