import SwiftUI
import PokeDataModel

struct BattleIntroTransitionState: Equatable {
    var displayedIntroProgress: CGFloat = 1
    var displayedIntroAmount: CGFloat = 0
    var seededRevision: Int?

    var settled: BattleIntroTransitionState {
        BattleIntroTransitionState(
            displayedIntroProgress: 1,
            displayedIntroAmount: 1,
            seededRevision: seededRevision
        )
    }
}

struct BattleIntroTransitionSyncResult: Equatable {
    let immediateState: BattleIntroTransitionState
    let animatedState: BattleIntroTransitionState?
}

enum BattleIntroTransitionAnimationSpec: Equatable {
    case easeOut(duration: Double)
    case easeInOut(duration: Double)

    var animation: Animation {
        switch self {
        case let .easeOut(duration):
            return .easeOut(duration: duration)
        case let .easeInOut(duration):
            return .easeInOut(duration: duration)
        }
    }
}

enum BattleIntroTransitionDriver {
    static func maxSampleOffset(displayScale: CGFloat) -> CGFloat {
        max(12, displayScale * 10)
    }

    static func animationSpec(for presentation: BattlePresentationTelemetry) -> BattleIntroTransitionAnimationSpec {
        switch presentation.semantics.phase {
        case .introSpiral:
            return .easeOut(duration: 0.62)
        default:
            return .easeInOut(duration: 0.2)
        }
    }

    static func sync(
        presentation: BattlePresentationTelemetry,
        previousState: BattleIntroTransitionState,
        animated: Bool
    ) -> BattleIntroTransitionSyncResult {
        var state = previousState
        let semantics = presentation.semantics

        if semantics.resetsTransitionSeed {
            state.seededRevision = nil
        }

        guard semantics.isTransitionEffectActive else {
            state.displayedIntroProgress = 1
            state.displayedIntroAmount = 0
            return BattleIntroTransitionSyncResult(immediateState: state, animatedState: nil)
        }

        if state.seededRevision != presentation.revision {
            let seededState = BattleIntroTransitionState(
                displayedIntroProgress: 0.01,
                displayedIntroAmount: 1,
                seededRevision: presentation.revision
            )
            return BattleIntroTransitionSyncResult(
                immediateState: seededState,
                animatedState: seededState.settled
            )
        }

        if animated == false {
            if state.seededRevision == nil {
                state.seededRevision = presentation.revision
            }
            state.displayedIntroProgress = 1
            state.displayedIntroAmount = 1
        }

        return BattleIntroTransitionSyncResult(immediateState: state, animatedState: nil)
    }
}
