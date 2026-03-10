import Foundation
import PokeDataModel

struct ResolvedBattleMove {
    let messages: [String]
    let dealtDamage: Int
    let typeMultiplier: Int
}

extension GameRuntime {
    func handleBattle(button: RuntimeButton) {
        guard var gameplayState, var battle = gameplayState.battle else { return }

        switch button {
        case .up:
            guard battle.phase == .moveSelection else { break }
            battle.focusedMoveIndex = max(0, battle.focusedMoveIndex - 1)
        case .down:
            guard battle.phase == .moveSelection else { break }
            battle.focusedMoveIndex = min(max(0, battle.playerPokemon.moves.count - 1), battle.focusedMoveIndex + 1)
        case .left, .right, .cancel:
            break
        case .confirm, .start:
            switch battle.phase {
            case .introText, .turnText:
                advanceBattleText(battle: &battle)
            case .moveSelection:
                resolveBattleTurn(battle: &battle)
            case .resolvingTurn:
                break
            case .battleComplete:
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
        gameplayState.objectStates[selectedBallObjectID(for: rivalSpeciesID)]?.visible = false
        self.gameplayState = gameplayState

        showDialogue(id: "oaks_lab_received_mon_\(speciesID.lowercased())", completion: .returnToField)
        queueDeferredActions([
            .dialogue("oaks_lab_rival_ill_take_this_one"),
            .dialogue("oaks_lab_rival_received_mon_\(rivalSpeciesID.lowercased())"),
        ])
    }

    func resolveBattleTurn(battle: inout RuntimeBattleState) {
        guard battle.phase == .moveSelection,
              battle.playerPokemon.moves.indices.contains(battle.focusedMoveIndex) else {
            return
        }

        battle.phase = .resolvingTurn

        var playerPokemon = battle.playerPokemon
        var enemyPokemon = battle.enemyPokemon
        let playerActsFirst = playerPokemon.speed >= enemyPokemon.speed
        var turnMessages: [String] = []

        if playerActsFirst {
            let playerMove = applyMove(attacker: &playerPokemon, defender: &enemyPokemon, moveIndex: battle.focusedMoveIndex)
            turnMessages.append(contentsOf: playerMove.messages)
            if enemyPokemon.currentHP > 0 {
                let enemyMoveIndex = selectEnemyMoveIndex(enemyPokemon: enemyPokemon, playerPokemon: playerPokemon)
                let enemyMove = applyMove(attacker: &enemyPokemon, defender: &playerPokemon, moveIndex: enemyMoveIndex)
                turnMessages.append(contentsOf: enemyMove.messages)
            }
        } else {
            let enemyMoveIndex = selectEnemyMoveIndex(enemyPokemon: enemyPokemon, playerPokemon: playerPokemon)
            let enemyMove = applyMove(attacker: &enemyPokemon, defender: &playerPokemon, moveIndex: enemyMoveIndex)
            turnMessages.append(contentsOf: enemyMove.messages)
            if playerPokemon.currentHP > 0 {
                let playerMove = applyMove(attacker: &playerPokemon, defender: &enemyPokemon, moveIndex: battle.focusedMoveIndex)
                turnMessages.append(contentsOf: playerMove.messages)
            }
        }

        battle.playerPokemon = playerPokemon
        battle.enemyPokemon = enemyPokemon

        if playerPokemon.currentHP == 0 {
            presentBattleMessages(
                turnMessages,
                battle: &battle,
                pendingAction: .finish(won: false)
            )
            return
        }

        if enemyPokemon.currentHP == 0 {
            if let switchMessages = advanceEnemyPartyIfNeeded(battle: &battle) {
                turnMessages.append(contentsOf: switchMessages)
                presentBattleMessages(
                    turnMessages,
                    battle: &battle,
                    pendingAction: .moveSelection
                )
            } else {
                presentBattleMessages(
                    turnMessages,
                    battle: &battle,
                    pendingAction: .finish(won: true)
                )
            }
            return
        }

        presentBattleMessages(
            turnMessages,
            battle: &battle,
            pendingAction: .moveSelection
        )
    }

    func advanceEnemyPartyIfNeeded(battle: inout RuntimeBattleState) -> [String]? {
        guard battle.enemyActiveIndex + 1 < battle.enemyParty.count else {
            return nil
        }

        battle.enemyActiveIndex += 1
        let nextPokemon = battle.enemyPokemon
        return ["\(battle.trainerName) sent out \(nextPokemon.nickname)!"]
    }

    func applyMove(
        attacker: inout RuntimePokemonState,
        defender: inout RuntimePokemonState,
        moveIndex: Int
    ) -> ResolvedBattleMove {
        guard attacker.moves.indices.contains(moveIndex),
              attacker.moves[moveIndex].currentPP > 0,
              let move = content.move(id: attacker.moves[moveIndex].id) else {
            return ResolvedBattleMove(messages: [], dealtDamage: 0, typeMultiplier: 10)
        }

        attacker.moves[moveIndex].currentPP -= 1

        var messages = ["\(attacker.nickname) used \(move.displayName)!"]

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
        case let .finish(won):
            battle.phase = .battleComplete
            finishBattle(battle: battle, won: won)
        }
    }

    func finishBattle(battle: RuntimeBattleState, won: Bool) {
        guard var gameplayState else { return }
        gameplayState.activeFlags.insert(battle.completionFlagID)
        gameplayState.playerParty = syncedPlayerParty(from: battle, gameplayState: gameplayState)
        gameplayState.battle = nil
        self.gameplayState = gameplayState
        if battle.healsPartyAfterBattle {
            healParty()
        }
        showDialogue(id: won ? battle.winDialogueID : battle.loseDialogueID, completion: .startPostBattleDialogue(won: won))
    }

    func runPostBattleSequence(won: Bool) {
        guard var gameplayState else { return }
        gameplayState.objectStates["oaks_lab_rival"]?.position = TilePoint(x: 4, y: 8)
        gameplayState.objectStates["oaks_lab_rival"]?.facing = .down
        self.gameplayState = gameplayState
        let _ = won
        requestRivalExitMusic()
        showDialogue(id: "oaks_lab_rival_smell_you_later", completion: .returnToField)
        queueDeferredActions([.hideObject("oaks_lab_rival"), .restoreMapMusic])
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
            makePokemon(speciesID: $0.speciesID, level: $0.level, nickname: $0.speciesID.capitalized)
        }
        guard enemyParty.isEmpty == false else { return }

        reseedBattleRNG(for: battleManifest.id)
        var battle = RuntimeBattleState(
            battleID: battleManifest.id,
            trainerName: battleManifest.displayName,
            completionFlagID: battleManifest.completionFlagID,
            healsPartyAfterBattle: battleManifest.healsPartyAfterBattle,
            preventsBlackoutOnLoss: battleManifest.preventsBlackoutOnLoss,
            winDialogueID: battleManifest.winDialogueID,
            loseDialogueID: battleManifest.loseDialogueID,
            playerPokemon: playerPokemon,
            enemyParty: enemyParty,
            enemyActiveIndex: 0,
            phase: .introText,
            focusedMoveIndex: 0,
            message: "",
            queuedMessages: [],
            pendingAction: .moveSelection
        )
        presentBattleMessages(
            [
                "\(battleManifest.displayName) challenges you!",
                "\(battleManifest.displayName) sent out \(battle.enemyPokemon.nickname)!",
                "Go! \(playerPokemon.nickname)!",
            ],
            battle: &battle,
            phase: .introText,
            pendingAction: .moveSelection
        )

        gameplayState.playerParty = syncedPlayerParty(from: battle, gameplayState: gameplayState)
        gameplayState.battle = battle
        self.gameplayState = gameplayState
        scene = .battle
        substate = "battle"
        requestTrainerBattleMusic()
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
    }

    func makePokemon(speciesID: String, level: Int, nickname: String) -> RuntimePokemonState {
        guard let species = content.species(id: speciesID) else {
            return RuntimePokemonState(
                speciesID: speciesID,
                nickname: nickname,
                level: level,
                maxHP: 20,
                currentHP: 20,
                attack: 10,
                defense: 10,
                speed: 10,
                special: 10,
                attackStage: 0,
                defenseStage: 0,
                accuracyStage: 0,
                evasionStage: 0,
                moves: []
            )
        }

        let maxHP = ((species.baseHP * 2 * level) / 100) + level + 10
        let attack = ((species.baseAttack * 2 * level) / 100) + 5
        let defense = ((species.baseDefense * 2 * level) / 100) + 5
        let speed = ((species.baseSpeed * 2 * level) / 100) + 5
        let special = ((species.baseSpecial * 2 * level) / 100) + 5
        let moves = species.startingMoves.compactMap { moveID -> RuntimeMoveState? in
            guard moveID != "NO_MOVE", let move = content.move(id: moveID) else { return nil }
            return RuntimeMoveState(id: move.id, currentPP: move.maxPP)
        }

        return RuntimePokemonState(
            speciesID: species.id,
            nickname: nickname,
            level: level,
            maxHP: maxHP,
            currentHP: maxHP,
            attack: attack,
            defense: defense,
            speed: speed,
            special: special,
            attackStage: 0,
            defenseStage: 0,
            accuracyStage: 0,
            evasionStage: 0,
            moves: moves
        )
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

    func reseedBattleRNG(for battleID: String) {
        var seed: UInt64 = 0xcbf29ce484222325
        for byte in battleID.utf8 {
            seed ^= UInt64(byte)
            seed &*= 0x100000001b3
        }
        battleRNGState = seed
    }

    func nextBattleRandomByte() -> Int {
        if battleRandomOverrides.isEmpty == false {
            return min(255, max(0, battleRandomOverrides.removeFirst()))
        }

        battleRNGState = battleRNGState &* 6364136223846793005 &+ 1
        return Int((battleRNGState >> 32) & 0xFF)
    }
}
