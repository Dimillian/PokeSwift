import Foundation

public enum BattleCaptureAnimationTiming {
    public static let spawnHoldDuration: TimeInterval = 0.08
    public static let poofFrameDuration: TimeInterval = BattleSendOutAnimationTiming.poofFrameDuration
    public static let dropDuration: TimeInterval = 0.16
    public static let reboundUpDuration: TimeInterval = 0.08
    public static let reboundDownDuration: TimeInterval = 0.08
    public static let shakeDuration: TimeInterval = 12.0 / 60.0
    public static let shakePauseDuration: TimeInterval = 40.0 / 60.0
    public static let caughtSettleDuration: TimeInterval = 0.22
    public static let breakoutRevealStep1Duration: TimeInterval = BattleSendOutAnimationTiming.revealStep1Duration
    public static let breakoutRevealStep2Duration: TimeInterval = BattleSendOutAnimationTiming.revealStep2Duration
    public static let breakoutRevealFinalDuration: TimeInterval = BattleSendOutAnimationTiming.revealFinalDuration

    public static let poofSoundFrameIndex = 1

    public static let absorbPoofFrameSequence = BattleSendOutAnimationTimeline.enemyPoofFrameSequence
    public static let breakoutPoofFrameSequence = BattleSendOutAnimationTimeline.enemyPoofFrameSequence

    public static var absorbPoofDuration: TimeInterval {
        poofFrameDuration * Double(absorbPoofFrameSequence.count)
    }

    public static var breakoutPoofDuration: TimeInterval {
        poofFrameDuration * Double(breakoutPoofFrameSequence.count)
    }

    public static func poofSoundDelay(frameSequence: [Int]) -> TimeInterval {
        spawnHoldDuration + (poofFrameDuration * Double(min(poofSoundFrameIndex + 1, frameSequence.count)))
    }

    public static func resultStartDelay(shakes: Int) -> TimeInterval {
        spawnHoldDuration +
        absorbPoofDuration +
        dropDuration +
        reboundUpDuration +
        reboundDownDuration +
        (Double(shakes) * (shakePauseDuration + shakeDuration))
    }

    public static func shakeStartDelay(index: Int) -> TimeInterval {
        resultStartDelay(shakes: index)
    }

    public static func totalDuration(shakes: Int, result: BattleCaptureAnimationResult) -> TimeInterval {
        let baseDuration = resultStartDelay(shakes: shakes)

        switch result {
        case .captured:
            return baseDuration + caughtSettleDuration
        case .brokeFree:
            return baseDuration +
                breakoutPoofDuration +
                breakoutRevealStep1Duration +
                breakoutRevealStep2Duration +
                breakoutRevealFinalDuration
        }
    }
}
