import Foundation
import PokeDataModel

@MainActor
private struct BattleSendOutPresentationBuilder {
    let runtime: GameRuntime

    func makeEnemySendOutBatch(
        trainerName: String,
        pokemon: RuntimePokemonState,
        enemyParty: [RuntimePokemonState],
        enemyActiveIndex: Int,
        hidePlayerPokemon: Bool,
        pendingAction: RuntimeBattlePendingAction?,
        delayBase: TimeInterval
    ) -> [RuntimeBattlePresentationBeat] {
        [
            makeSendOutBeat(
                side: .enemy,
                message: runtime.trainerSentOutText(trainerName: trainerName, pokemon: pokemon),
                enemyParty: enemyParty,
                enemyActiveIndex: enemyActiveIndex,
                hidePlayerPokemon: hidePlayerPokemon,
                pendingAction: pendingAction,
                delayBase: delayBase,
                speciesID: pokemon.speciesID
            ),
        ]
    }

    func makePlayerSendOutBatch(
        playerPokemon: RuntimePokemonState,
        enemyPokemon: RuntimePokemonState,
        pendingAction: RuntimeBattlePendingAction?,
        delayBase: TimeInterval
    ) -> [RuntimeBattlePresentationBeat] {
        [
            makeSendOutBeat(
                side: .player,
                message: runtime.playerSendOutText(for: playerPokemon, against: enemyPokemon),
                playerPokemon: playerPokemon,
                pendingAction: pendingAction,
                delayBase: delayBase,
                speciesID: playerPokemon.speciesID
            ),
        ]
    }

    private func makeSendOutBeat(
        side: BattlePresentationSide,
        message: String,
        playerPokemon: RuntimePokemonState? = nil,
        enemyParty: [RuntimePokemonState]? = nil,
        enemyActiveIndex: Int? = nil,
        hidePlayerPokemon: Bool = false,
        pendingAction: RuntimeBattlePendingAction? = nil,
        delayBase: TimeInterval,
        speciesID: String
    ) -> RuntimeBattlePresentationBeat {
        .init(
            delay: runtime.battlePresentationDelay(base: delayBase),
            stage: .enemySendOut,
            uiVisibility: .visible,
            activeSide: side,
            hidePlayerPokemon: hidePlayerPokemon,
            message: message,
            phase: .turnText,
            pendingAction: pendingAction,
            playerPokemon: playerPokemon,
            enemyParty: enemyParty,
            enemyActiveIndex: enemyActiveIndex,
            stagedSoundEffectRequests: runtime.sendOutSoundEffectRequests(
                side: side,
                speciesID: speciesID
            )
        )
    }
}

extension GameRuntime {
    func makeEnemySendOutBatch(
        trainerName: String,
        pokemon: RuntimePokemonState,
        enemyParty: [RuntimePokemonState],
        enemyActiveIndex: Int,
        hidePlayerPokemon: Bool = false,
        pendingAction: RuntimeBattlePendingAction? = nil,
        delayBase: TimeInterval = 0.34
    ) -> [RuntimeBattlePresentationBeat] {
        BattleSendOutPresentationBuilder(runtime: self).makeEnemySendOutBatch(
            trainerName: trainerName,
            pokemon: pokemon,
            enemyParty: enemyParty,
            enemyActiveIndex: enemyActiveIndex,
            hidePlayerPokemon: hidePlayerPokemon,
            pendingAction: pendingAction,
            delayBase: delayBase
        )
    }

    func scheduleNextEnemySendOut(
        battle: inout RuntimeBattleState,
        nextIndex: Int,
        pendingAction: RuntimeBattlePendingAction = .moveSelection
    ) {
        guard battle.enemyParty.indices.contains(nextIndex) else {
            returnToBattleMoveSelection(battle: &battle)
            return
        }

        let nextEnemy = battle.enemyParty[nextIndex]
        battle.phase = .resolvingTurn
        battle.pendingAction = nil
        battle.pendingPresentationBatches = []
        battle.queuedMessages = []
        battle.message = ""
        battle.aiLayer2Encouragement = 0

        let beats = makeEnemySendOutBatch(
            trainerName: battle.trainerName,
            pokemon: nextEnemy,
            enemyParty: battle.enemyParty,
            enemyActiveIndex: nextIndex,
            pendingAction: pendingAction
        )

        scheduleBattlePresentation(beats, battleID: battle.battleID)
    }

    func makePlayerSendOutBatch(
        playerPokemon: RuntimePokemonState,
        enemyPokemon: RuntimePokemonState,
        pendingAction: RuntimeBattlePendingAction? = nil,
        delayBase: TimeInterval = 0.34
    ) -> [RuntimeBattlePresentationBeat] {
        BattleSendOutPresentationBuilder(runtime: self).makePlayerSendOutBatch(
            playerPokemon: playerPokemon,
            enemyPokemon: enemyPokemon,
            pendingAction: pendingAction,
            delayBase: delayBase
        )
    }

    func makeTrainerOpeningSendOutBatches(
        battle: RuntimeBattleState
    ) -> [[RuntimeBattlePresentationBeat]] {
        [
            makeEnemySendOutBatch(
                trainerName: battle.trainerName,
                pokemon: battle.enemyPokemon,
                enemyParty: battle.enemyParty,
                enemyActiveIndex: battle.enemyActiveIndex,
                hidePlayerPokemon: true
            ),
            makePlayerSendOutBatch(
                playerPokemon: battle.playerPokemon,
                enemyPokemon: battle.enemyPokemon
            ),
        ]
    }
}
