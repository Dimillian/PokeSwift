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
            battle.focusedMoveIndex = min(maxBattleActionIndex(for: battle), battle.focusedMoveIndex + 1)
        case .left, .right:
            break
        case .cancel:
            guard battle.phase == .moveSelection, battle.canRun else { break }
            attemptBattleEscape(battle: &battle)
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
        self.gameplayState = gameplayState

        showDialogue(id: "oaks_lab_received_mon_\(speciesID.lowercased())", completion: .returnToField)
        queueDeferredActions([.script(rivalPickupScriptID(for: speciesID))])
    }

    func resolveBattleTurn(battle: inout RuntimeBattleState) {
        guard battle.phase == .moveSelection else {
            return
        }

        if battle.canRun, battle.focusedMoveIndex == battle.playerPokemon.moves.count {
            attemptBattleEscape(battle: &battle)
            return
        }

        guard battle.playerPokemon.moves.indices.contains(battle.focusedMoveIndex) else {
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
            turnMessages.append(
                contentsOf: applyBattleExperienceReward(
                    defeatedPokemon: enemyPokemon,
                    to: &battle.playerPokemon,
                    isTrainerBattle: battle.kind == .trainer
                )
            )
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
        case .escape:
            finishWildBattleEscape()
        }
    }

    func finishBattle(battle: RuntimeBattleState, won: Bool) {
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
        presentBattleMessages(
            ["Got away safely!"],
            battle: &battle,
            pendingAction: .escape
        )
    }

    func maxBattleActionIndex(for battle: RuntimeBattleState) -> Int {
        let moveActionCount = battle.playerPokemon.moves.count
        guard battle.canRun else {
            return max(0, moveActionCount - 1)
        }
        return moveActionCount
    }

    func finishWildBattleEscape() {
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

        reseedBattleRNG(for: battleManifest.id)
        var battle = RuntimeBattleState(
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
        reseedBattleRNG(for: battleID)

        var battle = RuntimeBattleState(
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
            message: "",
            queuedMessages: [],
            pendingAction: .moveSelection
        )
        presentBattleMessages(
            [
                "Wild \(enemyPokemon.nickname) appeared!",
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
        let dvs = nextAcquisitionDVs()
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
            moves: resolvedMoves
        )
    }

    func applyBattleExperienceReward(
        defeatedPokemon: RuntimePokemonState,
        to pokemon: inout RuntimePokemonState,
        isTrainerBattle: Bool
    ) -> [String] {
        let gainedExperience = battleExperienceAward(for: defeatedPokemon, isTrainerBattle: isTrainerBattle)
        let updatedStatExp = awardStatExp(from: defeatedPokemon, to: pokemon.statExp)
        let maximumExperience = maximumExperience(for: pokemon.speciesID)
        let updatedExperience = min(maximumExperience, pokemon.experience + gainedExperience)
        let updatedLevel = levelAfterGainingExperience(
            currentLevel: pokemon.level,
            updatedExperience: updatedExperience,
            speciesID: pokemon.speciesID
        )
        guard gainedExperience > 0 || updatedStatExp != pokemon.statExp else { return [] }

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
                moves: pokemon.moves
            )
        }

        if updatedLevel > previousLevel {
            for nextLevel in (previousLevel + 1)...updatedLevel {
                messages.append("\(pokemon.nickname) grew to Lv\(nextLevel)!")
            }
        }

        return messages
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

    func reseedAcquisitionRNG(for value: String) {
        var seed: UInt64 = 0x9e3779b97f4a7c15
        for byte in value.utf8 {
            seed ^= UInt64(byte)
            seed &*= 0xbf58476d1ce4e5b9
        }
        acquisitionRNGState = seed
    }

    func nextAcquisitionRandomByte() -> Int {
        if acquisitionRandomOverrides.isEmpty == false {
            return min(255, max(0, acquisitionRandomOverrides.removeFirst()))
        }

        acquisitionRNGState = acquisitionRNGState &* 6364136223846793005 &+ 1
        return Int((acquisitionRNGState >> 32) & 0xFF)
    }

    func nextAcquisitionDVs() -> PokemonDVs {
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
