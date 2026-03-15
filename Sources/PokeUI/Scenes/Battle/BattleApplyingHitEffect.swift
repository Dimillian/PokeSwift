import CoreGraphics
import Foundation
import PokeDataModel

struct BattleApplyingHitEffectVisualState: Equatable {
    let playerOpacity: Double
    let enemyOpacity: Double
    let screenShake: CGSize

    static let idle = BattleApplyingHitEffectVisualState(
        playerOpacity: 1,
        enemyOpacity: 1,
        screenShake: .zero
    )
}

struct BattleApplyingHitEffectKeyframe: Equatable {
    let duration: TimeInterval
    let state: BattleApplyingHitEffectVisualState
}

enum BattleApplyingHitEffectTimeline {
    static func sequence(for effect: BattleApplyingHitEffectTelemetry) -> [BattleApplyingHitEffectKeyframe] {
        let secondsPerFrame = effect.totalDuration /
            Double(max(1, BattleApplyingHitEffectPlaybackDefaults.frameCount(for: effect.kind)))

        switch effect.kind {
        case .shakeScreenVertical:
            return descendingShakeSequence(
                startingAt: 8,
                durations: (active: 3, idle: 3),
                secondsPerFrame: secondsPerFrame,
                offset: { amplitude in .init(width: 0, height: CGFloat(amplitude)) }
            )
        case .shakeScreenHorizontalHeavy:
            return descendingShakeSequence(
                startingAt: 8,
                durations: (active: 5, idle: 4),
                secondsPerFrame: secondsPerFrame,
                offset: { amplitude in .init(width: CGFloat(amplitude), height: 0) }
            )
        case .shakeScreenHorizontalLight:
            return descendingShakeSequence(
                startingAt: 2,
                durations: (active: 5, idle: 4),
                secondsPerFrame: secondsPerFrame,
                offset: { amplitude in .init(width: CGFloat(amplitude), height: 0) }
            )
        case .shakeScreenHorizontalSlow:
            return slowHorizontalShakeSequence(
                amplitude: 6,
                cycles: 2,
                framesPerStep: 2,
                secondsPerFrame: secondsPerFrame
            )
        case .shakeScreenHorizontalSlow2:
            return slowHorizontalShakeSequence(
                amplitude: 3,
                cycles: 2,
                framesPerStep: 2,
                secondsPerFrame: secondsPerFrame
            )
        case .blinkDefender:
            return blinkSequence(
                repeats: 6,
                hiddenFrames: 5,
                shownFrames: 8,
                attackerSide: effect.attackerSide,
                secondsPerFrame: secondsPerFrame
            )
        }
    }

    private static func descendingShakeSequence(
        startingAt amplitude: Int,
        durations: (active: Int, idle: Int),
        secondsPerFrame: TimeInterval,
        offset: (Int) -> CGSize
    ) -> [BattleApplyingHitEffectKeyframe] {
        var keyframes: [BattleApplyingHitEffectKeyframe] = []
        for currentAmplitude in stride(from: amplitude, through: 1, by: -1) {
            keyframes.append(
                .init(
                    duration: secondsPerFrame * Double(durations.active),
                    state: .init(playerOpacity: 1, enemyOpacity: 1, screenShake: offset(currentAmplitude))
                )
            )
            keyframes.append(
                .init(
                    duration: secondsPerFrame * Double(durations.idle),
                    state: .idle
                )
            )
        }
        return keyframes
    }

    private static func slowHorizontalShakeSequence(
        amplitude: Int,
        cycles: Int,
        framesPerStep: Int,
        secondsPerFrame: TimeInterval
    ) -> [BattleApplyingHitEffectKeyframe] {
        var keyframes: [BattleApplyingHitEffectKeyframe] = []
        for _ in 0..<cycles {
            for step in 1...amplitude {
                keyframes.append(
                    .init(
                        duration: secondsPerFrame * Double(framesPerStep),
                        state: .init(playerOpacity: 1, enemyOpacity: 1, screenShake: .init(width: CGFloat(step), height: 0))
                    )
                )
            }
            for step in stride(from: amplitude - 1, through: 0, by: -1) {
                keyframes.append(
                    .init(
                        duration: secondsPerFrame * Double(framesPerStep),
                        state: .init(playerOpacity: 1, enemyOpacity: 1, screenShake: .init(width: CGFloat(step), height: 0))
                    )
                )
            }
        }
        return keyframes
    }

    private static func blinkSequence(
        repeats: Int,
        hiddenFrames: Int,
        shownFrames: Int,
        attackerSide: BattlePresentationSide,
        secondsPerFrame: TimeInterval
    ) -> [BattleApplyingHitEffectKeyframe] {
        var keyframes: [BattleApplyingHitEffectKeyframe] = []
        for _ in 0..<repeats {
            keyframes.append(
                .init(
                    duration: secondsPerFrame * Double(hiddenFrames),
                    state: blinkState(attackerSide: attackerSide, opacity: 0)
                )
            )
            keyframes.append(
                .init(
                    duration: secondsPerFrame * Double(shownFrames),
                    state: .idle
                )
            )
        }
        return keyframes
    }

    private static func blinkState(
        attackerSide: BattlePresentationSide,
        opacity: Double
    ) -> BattleApplyingHitEffectVisualState {
        if attackerSide == .player {
            return .init(playerOpacity: 1, enemyOpacity: opacity, screenShake: .zero)
        }
        return .init(playerOpacity: opacity, enemyOpacity: 1, screenShake: .zero)
    }
}
