import Foundation
import PokeAudio
import PokeDataModel

extension GameRuntime {
    func makeCaptureAnimation(
        itemID: String,
        result: RuntimeBattleCaptureResult
    ) -> BattleCaptureAnimationTelemetry? {
        let captureResult: BattleCaptureAnimationResult
        let shakes: Int

        switch result {
        case .success:
            captureResult = .captured
            shakes = 3
        case let .failed(failureShakes):
            captureResult = .brokeFree
            shakes = failureShakes
        case .uncatchable, .boxFull:
            return nil
        }

        return .init(
            playbackID: UUID().uuidString,
            itemID: itemID,
            shakes: shakes,
            result: captureResult,
            totalDuration: battlePresentationDelay(
                base: BattleCaptureAnimationTiming.totalDuration(
                    shakes: shakes,
                    result: captureResult
                )
            )
        )
    }

    func makeCaptureAnimationBatch(
        captureAnimation: BattleCaptureAnimationTelemetry,
        message: String,
        pendingAction: RuntimeBattlePendingAction? = nil,
        soundEffectRequest: SoundEffectPlaybackRequest? = nil
    ) -> [RuntimeBattlePresentationBeat] {
        [
            .init(
                delay: 0,
                stage: .wildCapture,
                uiVisibility: .visible,
                activeSide: .enemy,
                captureAnimation: captureAnimation,
                phase: .resolvingTurn,
                stagedSoundEffectRequests: captureAnimationSoundEffectRequests(captureAnimation)
            ),
            .init(
                delay: captureAnimation.totalDuration,
                stage: .wildCapture,
                uiVisibility: .visible,
                activeSide: .enemy,
                requiresConfirmAfterDisplay: true,
                captureAnimation: captureAnimation,
                message: message,
                phase: .turnText,
                pendingAction: pendingAction,
                soundEffectRequest: soundEffectRequest
            ),
        ]
    }

    func makeEnemyResponseBatchesAfterFailedCapture(
        battle: RuntimeBattleState
    ) -> [[RuntimeBattlePresentationBeat]] {
        var simulatedPlayer = battle.playerPokemon
        var simulatedEnemy = battle.enemyPokemon
        var batches: [[RuntimeBattlePresentationBeat]] = []
        let enemyMoveIndex = resolveActionMoveIndex(
            for: .enemy,
            battle: battle,
            playerPokemon: simulatedPlayer,
            enemyPokemon: simulatedEnemy
        )
        let enemyAction = resolveBattleAction(
            side: .enemy,
            attacker: simulatedEnemy,
            defender: simulatedPlayer,
            moveIndex: enemyMoveIndex,
            defenderCanActLaterInTurn: false
        )

        var enemyActionBeats = makeBeats(for: enemyAction)
        if let pendingAction = enemyAction.pendingAction,
           enemyActionBeats.isEmpty == false {
            enemyActionBeats[enemyActionBeats.count - 1].pendingAction = pendingAction
        }
        if enemyActionBeats.isEmpty == false {
            batches.append(enemyActionBeats)
        }

        applyResolvedBattleAction(
            enemyAction,
            side: .enemy,
            simulatedPlayer: &simulatedPlayer,
            simulatedEnemy: &simulatedEnemy
        )

        if enemyAction.pendingAction != nil {
            return batches
        }

        if appendPostActionResolutionIfNeeded(
            battle: battle,
            simulatedPlayer: &simulatedPlayer,
            simulatedEnemy: simulatedEnemy,
            batches: &batches
        ) {
            return batches
        }

        if appendResidualResolutionIfNeeded(
            actingSide: .enemy,
            battle: battle,
            simulatedPlayer: &simulatedPlayer,
            simulatedEnemy: &simulatedEnemy,
            batches: &batches
        ) {
            return batches
        }

        batches.append(
            [
                commandReadyBeat(
                    delay: battlePresentationDelay(base: 0.24),
                    playerPokemon: simulatedPlayer,
                    enemyPokemon: simulatedEnemy
                ),
            ]
        )
        return batches
    }
}
