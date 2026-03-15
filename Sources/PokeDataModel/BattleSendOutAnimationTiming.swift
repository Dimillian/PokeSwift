import Foundation

public enum BattleSendOutAnimationTiming {
    public static let tossDuration: TimeInterval = 0.28
    public static let releaseHoldDuration: TimeInterval = 0.05
    public static let poofFrameDuration: TimeInterval = 0.07
    public static let revealStep1Duration: TimeInterval = 0.08
    public static let revealStep2Duration: TimeInterval = 0.10
    public static let revealFinalDuration: TimeInterval = 0.14

    // In the original battle animation, the poof SFX fires after the second
    // poof frame has appeared.
    public static let poofSoundDelay: TimeInterval =
        tossDuration +
        releaseHoldDuration +
        (poofFrameDuration * 2)

    public static func crySoundDelay(for side: BattlePresentationSide) -> TimeInterval {
        tossDuration +
        releaseHoldDuration +
        (poofFrameDuration * Double(poofFrameCount(for: side))) +
        revealStep1Duration +
        revealStep2Duration
    }

    private static func poofFrameCount(for side: BattlePresentationSide) -> Int {
        switch side {
        case .enemy:
            return 6
        case .player:
            return 3
        }
    }
}
