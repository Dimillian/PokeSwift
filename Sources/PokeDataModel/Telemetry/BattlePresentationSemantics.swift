import Foundation

public enum BattlePresentationSemanticPhase: Equatable, Sendable {
    case idle
    case introFlash
    case introSpiral
    case introCrossing
    case introReveal
    case sendOut(side: BattlePresentationSide?)
    case capture
    case active
}

public struct BattlePresentationSemantics: Equatable, Sendable {
    public let stage: BattlePresentationStage
    public let phase: BattlePresentationSemanticPhase
    public let uiVisibility: BattlePresentationUIVisibility
    public let hidePlayerPokemon: Bool
    public let transitionStyle: BattleTransitionStyle

    public init(_ presentation: BattlePresentationTelemetry) {
        stage = presentation.stage
        uiVisibility = presentation.uiVisibility
        hidePlayerPokemon = presentation.hidePlayerPokemon
        transitionStyle = presentation.transitionStyle

        switch presentation.stage {
        case .idle:
            phase = .idle
        case .introFlash1, .introFlash2, .introFlash3:
            phase = .introFlash
        case .introSpiral:
            phase = .introSpiral
        case .introCrossing:
            phase = .introCrossing
        case .introReveal:
            phase = .introReveal
        case .enemySendOut:
            phase = .sendOut(side: presentation.activeSide)
        case .wildCapture:
            phase = .capture
        default:
            phase = .active
        }
    }

    public var isFlashStage: Bool {
        if case .introFlash = phase {
            return true
        }
        return false
    }

    public var isIntroRevealStage: Bool {
        if case .introReveal = phase {
            return true
        }
        return false
    }

    public var isIntroSpiralStage: Bool {
        if case .introSpiral = phase {
            return true
        }
        return false
    }

    public var isIntroCrossingStage: Bool {
        if case .introCrossing = phase {
            return true
        }
        return false
    }

    public var isSendOutStage: Bool {
        if case .sendOut = phase {
            return true
        }
        return false
    }

    public var isCaptureStage: Bool {
        if case .capture = phase {
            return true
        }
        return false
    }

    public var sendOutSide: BattlePresentationSide? {
        if case let .sendOut(side) = phase {
            return side
        }
        return nil
    }

    public var showsIntroTrainers: Bool {
        isFlashStage || isIntroSpiralStage || isIntroCrossingStage || isIntroRevealStage
    }

    public var hidesTrainerPokemonDuringIntro: Bool {
        isFlashStage || isIntroSpiralStage || isIntroCrossingStage
    }

    public var resetsTransitionSeed: Bool {
        stage == .introFlash1
    }

    public var isTransitionEffectActive: Bool {
        transitionStyle != .none && isIntroSpiralStage
    }

    public var transitionShaderStyle: BattleTransitionStyle? {
        isTransitionEffectActive ? transitionStyle : nil
    }
}

public extension BattlePresentationTelemetry {
    var semantics: BattlePresentationSemantics {
        BattlePresentationSemantics(self)
    }
}
