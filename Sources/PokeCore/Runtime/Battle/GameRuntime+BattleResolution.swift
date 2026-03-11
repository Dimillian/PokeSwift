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

extension GameRuntime {
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
}
