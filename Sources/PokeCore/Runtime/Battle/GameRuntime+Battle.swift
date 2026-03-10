import Foundation
import PokeDataModel

extension GameRuntime {
    func handleBattle(button: RuntimeButton) {
        guard var gameplayState, var battle = gameplayState.battle else { return }

        switch button {
        case .up:
            battle.focusedMoveIndex = max(0, battle.focusedMoveIndex - 1)
        case .down:
            battle.focusedMoveIndex = min(max(0, battle.playerPokemon.moves.count - 1), battle.focusedMoveIndex + 1)
        case .left, .right:
            break
        case .cancel:
            break
        case .confirm, .start:
            resolveBattleTurn(battle: &battle)
        }

        guard scene == .battle, self.gameplayState?.battle != nil else {
            return
        }

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
        guard battle.playerPokemon.moves.indices.contains(battle.focusedMoveIndex) else { return }

        let playerActsFirst = battle.playerPokemon.speed >= battle.enemyPokemon.speed
        if playerActsFirst {
            applyMove(attacker: &battle.playerPokemon, defender: &battle.enemyPokemon, moveIndex: battle.focusedMoveIndex, messageTarget: &battle.message)
            if battle.enemyPokemon.currentHP > 0 {
                applyEnemyTurn(battle: &battle)
            }
        } else {
            applyEnemyTurn(battle: &battle)
            if battle.playerPokemon.currentHP > 0 {
                applyMove(attacker: &battle.playerPokemon, defender: &battle.enemyPokemon, moveIndex: battle.focusedMoveIndex, messageTarget: &battle.message)
            }
        }

        if battle.enemyPokemon.currentHP == 0 || battle.playerPokemon.currentHP == 0 {
            finishBattle(won: battle.enemyPokemon.currentHP == 0)
        } else {
            battle.message = "Pick the next move."
        }
    }

    func applyEnemyTurn(battle: inout RuntimeBattleState) {
        let availableMoves = battle.enemyPokemon.moves.enumerated().filter { $0.element.currentPP > 0 }
        guard let moveChoice = availableMoves.min(by: { $0.offset < $1.offset })?.offset else { return }
        applyMove(attacker: &battle.enemyPokemon, defender: &battle.playerPokemon, moveIndex: moveChoice, messageTarget: &battle.message)
    }

    func applyMove(
        attacker: inout RuntimePokemonState,
        defender: inout RuntimePokemonState,
        moveIndex: Int,
        messageTarget: inout String
    ) {
        guard attacker.moves.indices.contains(moveIndex),
              attacker.moves[moveIndex].currentPP > 0,
              let move = content.move(id: attacker.moves[moveIndex].id) else {
            return
        }

        attacker.moves[moveIndex].currentPP -= 1
        if move.power > 0 {
            let adjustedAttack = scaledStat(attacker.attack, stage: attacker.attackStage)
            let adjustedDefense = max(1, scaledStat(defender.defense, stage: defender.defenseStage))
            let damage = max(1, (((((2 * attacker.level) / 5) + 2) * move.power * adjustedAttack) / adjustedDefense) / 50 + 2)
            defender.currentHP = max(0, defender.currentHP - damage)
            messageTarget = "\(attacker.nickname) used \(move.displayName)."
        } else {
            switch move.effect {
            case "ATTACK_DOWN1_EFFECT":
                defender.attackStage = max(-6, defender.attackStage - 1)
            case "DEFENSE_DOWN1_EFFECT":
                defender.defenseStage = max(-6, defender.defenseStage - 1)
            default:
                break
            }
            messageTarget = "\(attacker.nickname) used \(move.displayName)."
        }
    }

    func finishBattle(won: Bool) {
        guard var gameplayState, let battle = gameplayState.battle else { return }
        gameplayState.activeFlags.insert(battle.completionFlagID)
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
        showDialogue(id: "oaks_lab_rival_smell_you_later", completion: .returnToField)
        queueDeferredActions([.hideObject("oaks_lab_rival")])
    }

    func startBattle(id: String) {
        guard var gameplayState,
              let chosenStarter = gameplayState.chosenStarterSpeciesID else {
            return
        }

        let battleID: String
        if id == "AUTO" {
            switch rivalStarter(for: chosenStarter) {
            case "SQUIRTLE":
                battleID = "rival_lab_squirtle"
            case "BULBASAUR":
                battleID = "rival_lab_bulbasaur"
            default:
                battleID = "rival_lab_charmander"
            }
        } else {
            battleID = id
        }

        guard let battleManifest = content.trainerBattle(id: battleID) else {
            return
        }

        let playerPokemon = gameplayState.playerParty.first ?? makePokemon(speciesID: chosenStarter, level: 5, nickname: chosenStarter.capitalized)
        let enemyPokemon = makePokemon(speciesID: battleManifest.enemySpeciesID, level: battleManifest.enemyLevel, nickname: battleManifest.enemySpeciesID.capitalized)
        gameplayState.battle = RuntimeBattleState(
            battleID: battleManifest.id,
            trainerName: gameplayState.rivalName,
            playerStarterSpeciesID: chosenStarter,
            enemyStarterSpeciesID: battleManifest.enemySpeciesID,
            completionFlagID: battleManifest.completionFlagID,
            healsPartyAfterBattle: battleManifest.healsPartyAfterBattle,
            preventsBlackoutOnLoss: battleManifest.preventsBlackoutOnLoss,
            winDialogueID: battleManifest.winDialogueID,
            loseDialogueID: battleManifest.loseDialogueID,
            playerPokemon: playerPokemon,
            enemyPokemon: enemyPokemon,
            focusedMoveIndex: 0,
            message: "\(gameplayState.rivalName) challenges you."
        )
        self.gameplayState = gameplayState
        scene = .battle
        substate = "battle"
    }

    func healParty() {
        guard var gameplayState else { return }
        gameplayState.playerParty = gameplayState.playerParty.map { pokemon in
            var healed = pokemon
            healed.currentHP = healed.maxHP
            healed.attackStage = 0
            healed.defenseStage = 0
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
            return RuntimePokemonState(speciesID: speciesID, nickname: nickname, level: level, maxHP: 20, currentHP: 20, attack: 10, defense: 10, speed: 10, special: 10, attackStage: 0, defenseStage: 0, moves: [])
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
}
