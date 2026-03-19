import CoreGraphics
import Foundation
import PokeDataModel

struct BattleCaptureAnimationTimeline {
    static func state(
        at elapsed: TimeInterval?,
        captureAnimation: BattleCaptureAnimationTelemetry
    ) -> BattleCaptureVisualState {
        guard let elapsed else {
            return .idle
        }

        let baseTotalDuration = BattleCaptureAnimationTiming.totalDuration(
            shakes: captureAnimation.shakes,
            result: captureAnimation.result
        )
        let durationScale = baseTotalDuration > 0 ? captureAnimation.totalDuration / baseTotalDuration : 1
        let clampedElapsed = max(0, min(elapsed, captureAnimation.totalDuration))
        let scaledSpawnHold = BattleCaptureAnimationTiming.spawnHoldDuration * durationScale
        let scaledPoofFrame = BattleCaptureAnimationTiming.poofFrameDuration * durationScale
        let scaledAbsorbPoof = BattleCaptureAnimationTiming.absorbPoofDuration * durationScale
        let scaledDrop = BattleCaptureAnimationTiming.dropDuration * durationScale
        let scaledReboundUp = BattleCaptureAnimationTiming.reboundUpDuration * durationScale
        let scaledReboundDown = BattleCaptureAnimationTiming.reboundDownDuration * durationScale
        let scaledShakePause = BattleCaptureAnimationTiming.shakePauseDuration * durationScale
        let scaledShake = BattleCaptureAnimationTiming.shakeDuration * durationScale
        let scaledCaughtSettle = BattleCaptureAnimationTiming.caughtSettleDuration * durationScale
        let scaledBreakoutPoof = BattleCaptureAnimationTiming.breakoutPoofDuration * durationScale
        let scaledRevealStep1 = BattleCaptureAnimationTiming.breakoutRevealStep1Duration * durationScale
        let scaledRevealStep2 = BattleCaptureAnimationTiming.breakoutRevealStep2Duration * durationScale
        let scaledRevealFinal = BattleCaptureAnimationTiming.breakoutRevealFinalDuration * durationScale

        var cursor = scaledSpawnHold
        if clampedElapsed < cursor {
            return .init(
                ballOpacity: 1,
                ballGroundProgress: 0,
                ballHorizontalFactor: 0,
                ballVerticalFactor: 0,
                ballRotationDegrees: 0,
                poofFrameIndex: nil,
                enemyOpacity: 1,
                enemyScale: 1
            )
        }

        let absorbPoofStart = cursor
        cursor += scaledAbsorbPoof
        if clampedElapsed < cursor {
            let localElapsed = clampedElapsed - absorbPoofStart
            let sequenceIndex = min(
                BattleCaptureAnimationTiming.absorbPoofFrameSequence.count - 1,
                Int(localElapsed / max(0.001, scaledPoofFrame))
            )
            let progress = min(1, localElapsed / max(0.001, scaledAbsorbPoof))
            return .init(
                ballOpacity: 1,
                ballGroundProgress: 0,
                ballHorizontalFactor: 0,
                ballVerticalFactor: 0,
                ballRotationDegrees: 0,
                poofFrameIndex: BattleCaptureAnimationTiming.absorbPoofFrameSequence[sequenceIndex],
                enemyOpacity: max(0, 1 - (progress * 1.15)),
                enemyScale: max(0.12, 1 - (progress * 0.88))
            )
        }

        let dropStart = cursor
        cursor += scaledDrop
        if clampedElapsed < cursor {
            let progress = min(1, (clampedElapsed - dropStart) / max(0.001, scaledDrop))
            return .init(
                ballOpacity: 1,
                ballGroundProgress: CGFloat(progress),
                ballHorizontalFactor: 0,
                ballVerticalFactor: 0,
                ballRotationDegrees: 0,
                poofFrameIndex: nil,
                enemyOpacity: 0,
                enemyScale: 0.12
            )
        }

        let reboundUpStart = cursor
        cursor += scaledReboundUp
        if clampedElapsed < cursor {
            let progress = min(1, (clampedElapsed - reboundUpStart) / max(0.001, scaledReboundUp))
            return .init(
                ballOpacity: 1,
                ballGroundProgress: 1,
                ballHorizontalFactor: 0,
                ballVerticalFactor: CGFloat(-0.28 * progress),
                ballRotationDegrees: progress * 6,
                poofFrameIndex: nil,
                enemyOpacity: 0,
                enemyScale: 0.12
            )
        }

        let reboundDownStart = cursor
        cursor += scaledReboundDown
        if clampedElapsed < cursor {
            let progress = min(1, (clampedElapsed - reboundDownStart) / max(0.001, scaledReboundDown))
            return .init(
                ballOpacity: 1,
                ballGroundProgress: 1,
                ballHorizontalFactor: 0,
                ballVerticalFactor: CGFloat(-0.28 + (0.28 * progress)),
                ballRotationDegrees: 6 - (progress * 6),
                poofFrameIndex: nil,
                enemyOpacity: 0,
                enemyScale: 0.12
            )
        }

        for _ in 0..<captureAnimation.shakes {
            cursor += scaledShakePause
            if clampedElapsed < cursor {
                return .groundedClosedBall
            }

            let shakeStart = cursor
            cursor += scaledShake
            if clampedElapsed < cursor {
                let progress = min(1, (clampedElapsed - shakeStart) / max(0.001, scaledShake))
                let wave = sin(progress * .pi * 2) * sin(progress * .pi)
                return .init(
                    ballOpacity: 1,
                    ballGroundProgress: 1,
                    ballHorizontalFactor: 0,
                    ballVerticalFactor: 0,
                    ballRotationDegrees: wave * 12,
                    poofFrameIndex: nil,
                    enemyOpacity: 0,
                    enemyScale: 0.12
                )
            }
        }

        switch captureAnimation.result {
        case .captured:
            let settleStart = cursor
            cursor += scaledCaughtSettle
            if clampedElapsed < cursor {
                let progress = min(1, (clampedElapsed - settleStart) / max(0.001, scaledCaughtSettle))
                return .init(
                    ballOpacity: 1,
                    ballGroundProgress: 1,
                    ballHorizontalFactor: 0,
                    ballVerticalFactor: CGFloat(-0.04 * (1 - progress)),
                    ballRotationDegrees: 0,
                    poofFrameIndex: nil,
                    enemyOpacity: 0,
                    enemyScale: 0.12
                )
            }
            return .groundedClosedBall
        case .brokeFree:
            let breakoutPoofStart = cursor
            cursor += scaledBreakoutPoof
            if clampedElapsed < cursor {
                let localElapsed = clampedElapsed - breakoutPoofStart
                let sequenceIndex = min(
                    BattleCaptureAnimationTiming.breakoutPoofFrameSequence.count - 1,
                    Int(localElapsed / max(0.001, scaledPoofFrame))
                )
                return .init(
                    ballOpacity: 0,
                    ballGroundProgress: 1,
                    ballHorizontalFactor: 0,
                    ballVerticalFactor: 0,
                    ballRotationDegrees: 0,
                    poofFrameIndex: BattleCaptureAnimationTiming.breakoutPoofFrameSequence[sequenceIndex],
                    enemyOpacity: 0,
                    enemyScale: BattleSendOutAnimationTimeline.revealScaleStep1
                )
            }

            cursor += scaledRevealStep1
            if clampedElapsed < cursor {
                return .init(
                    ballOpacity: 0,
                    ballGroundProgress: 1,
                    ballHorizontalFactor: 0,
                    ballVerticalFactor: 0,
                    ballRotationDegrees: 0,
                    poofFrameIndex: nil,
                    enemyOpacity: 1,
                    enemyScale: BattleSendOutAnimationTimeline.revealScaleStep1
                )
            }

            cursor += scaledRevealStep2
            if clampedElapsed < cursor {
                return .init(
                    ballOpacity: 0,
                    ballGroundProgress: 1,
                    ballHorizontalFactor: 0,
                    ballVerticalFactor: 0,
                    ballRotationDegrees: 0,
                    poofFrameIndex: nil,
                    enemyOpacity: 1,
                    enemyScale: BattleSendOutAnimationTimeline.revealScaleStep2
                )
            }

            cursor += scaledRevealFinal
            if clampedElapsed < cursor {
                return .init(
                    ballOpacity: 0,
                    ballGroundProgress: 1,
                    ballHorizontalFactor: 0,
                    ballVerticalFactor: 0,
                    ballRotationDegrees: 0,
                    poofFrameIndex: nil,
                    enemyOpacity: 1,
                    enemyScale: BattleSendOutAnimationTimeline.revealScaleFinal
                )
            }

            return .idle
        }
    }
}

struct BattleCaptureVisualState: Equatable {
    let ballOpacity: Double
    let ballGroundProgress: CGFloat
    let ballHorizontalFactor: CGFloat
    let ballVerticalFactor: CGFloat
    let ballRotationDegrees: Double
    let poofFrameIndex: Int?
    let enemyOpacity: Double
    let enemyScale: CGFloat

    static let idle = BattleCaptureVisualState(
        ballOpacity: 0,
        ballGroundProgress: 0,
        ballHorizontalFactor: 0,
        ballVerticalFactor: 0,
        ballRotationDegrees: 0,
        poofFrameIndex: nil,
        enemyOpacity: 1,
        enemyScale: 1
    )

    static let groundedClosedBall = BattleCaptureVisualState(
        ballOpacity: 1,
        ballGroundProgress: 1,
        ballHorizontalFactor: 0,
        ballVerticalFactor: 0,
        ballRotationDegrees: 0,
        poofFrameIndex: nil,
        enemyOpacity: 0,
        enemyScale: 0.12
    )
}
