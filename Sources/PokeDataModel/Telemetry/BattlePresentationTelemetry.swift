import Foundation

public enum BattlePresentationStage: String, Codable, Equatable, Sendable {
    case idle
    case introFlash1
    case introFlash2
    case introFlash3
    case introSpiral
    case introCrossing
    case introReveal
    case commandReady
    case attackWindup
    case attackImpact
    case hpDrain
    case resultText
    case faint
    case experience
    case levelUp
    case enemySendOut
    case turnSettle
    case battleComplete
}

public enum BattlePresentationSide: String, Codable, Equatable, Sendable {
    case player
    case enemy
}

public enum BattlePresentationUIVisibility: String, Codable, Equatable, Sendable {
    case hidden
    case visible
}

public enum BattleTransitionStyle: String, Codable, Equatable, Sendable {
    case none
    case circle
    case spiral
}

public enum BattleMeterKind: String, Codable, Equatable, Sendable {
    case hp
    case experience
}

public struct BattleMeterAnimationTelemetry: Codable, Equatable, Sendable {
    public let kind: BattleMeterKind
    public let side: BattlePresentationSide
    public let fromValue: Int
    public let toValue: Int
    public let maximumValue: Int
    public let startLevel: Int?
    public let endLevel: Int?
    public let startLevelStart: Int?
    public let startNextLevel: Int?
    public let endLevelStart: Int?
    public let endNextLevel: Int?

    public init(
        kind: BattleMeterKind,
        side: BattlePresentationSide,
        fromValue: Int,
        toValue: Int,
        maximumValue: Int,
        startLevel: Int? = nil,
        endLevel: Int? = nil,
        startLevelStart: Int? = nil,
        startNextLevel: Int? = nil,
        endLevelStart: Int? = nil,
        endNextLevel: Int? = nil
    ) {
        self.kind = kind
        self.side = side
        self.fromValue = fromValue
        self.toValue = toValue
        self.maximumValue = maximumValue
        self.startLevel = startLevel
        self.endLevel = endLevel
        self.startLevelStart = startLevelStart
        self.startNextLevel = startNextLevel
        self.endLevelStart = endLevelStart
        self.endNextLevel = endNextLevel
    }
}

public struct BattleAttackAnimationPlaybackTelemetry: Codable, Equatable, Sendable {
    public let playbackID: String
    public let moveID: String
    public let attackerSide: BattlePresentationSide
    public let totalDuration: TimeInterval

    public init(
        playbackID: String,
        moveID: String,
        attackerSide: BattlePresentationSide,
        totalDuration: TimeInterval
    ) {
        self.playbackID = playbackID
        self.moveID = moveID
        self.attackerSide = attackerSide
        self.totalDuration = totalDuration
    }
}

public enum BattleApplyingHitEffectKind: String, Codable, Equatable, Sendable {
    case shakeScreenVertical
    case shakeScreenHorizontalHeavy
    case shakeScreenHorizontalLight
    case shakeScreenHorizontalSlow
    case shakeScreenHorizontalSlow2
    case blinkDefender
}

public struct BattleApplyingHitEffectTelemetry: Codable, Equatable, Sendable {
    public let playbackID: String
    public let kind: BattleApplyingHitEffectKind
    public let attackerSide: BattlePresentationSide
    public let totalDuration: TimeInterval

    public init(
        playbackID: String,
        kind: BattleApplyingHitEffectKind,
        attackerSide: BattlePresentationSide,
        totalDuration: TimeInterval
    ) {
        self.playbackID = playbackID
        self.kind = kind
        self.attackerSide = attackerSide
        self.totalDuration = totalDuration
    }
}

public struct BattlePresentationTelemetry: Codable, Equatable, Sendable {
    public let stage: BattlePresentationStage
    public let revision: Int
    public let uiVisibility: BattlePresentationUIVisibility
    public let activeSide: BattlePresentationSide?
    public let hidePlayerPokemon: Bool
    public let transitionStyle: BattleTransitionStyle
    public let meterAnimation: BattleMeterAnimationTelemetry?
    public let attackAnimation: BattleAttackAnimationPlaybackTelemetry?
    public let applyingHitEffect: BattleApplyingHitEffectTelemetry?

    public init(
        stage: BattlePresentationStage,
        revision: Int,
        uiVisibility: BattlePresentationUIVisibility,
        activeSide: BattlePresentationSide? = nil,
        hidePlayerPokemon: Bool = false,
        transitionStyle: BattleTransitionStyle = .none,
        meterAnimation: BattleMeterAnimationTelemetry? = nil,
        attackAnimation: BattleAttackAnimationPlaybackTelemetry? = nil,
        applyingHitEffect: BattleApplyingHitEffectTelemetry? = nil
    ) {
        self.stage = stage
        self.revision = revision
        self.uiVisibility = uiVisibility
        self.activeSide = activeSide
        self.hidePlayerPokemon = hidePlayerPokemon
        self.transitionStyle = transitionStyle
        self.meterAnimation = meterAnimation
        self.attackAnimation = attackAnimation
        self.applyingHitEffect = applyingHitEffect
    }
}

public enum BattleApplyingHitEffectPlaybackDefaults {
    public static let framesPerSecond: Double = 60

    public static func frameCount(for kind: BattleApplyingHitEffectKind) -> Int {
        switch kind {
        case .shakeScreenVertical:
            return 48
        case .shakeScreenHorizontalHeavy:
            return 72
        case .shakeScreenHorizontalLight:
            return 18
        case .shakeScreenHorizontalSlow:
            return 48
        case .shakeScreenHorizontalSlow2:
            return 24
        case .blinkDefender:
            return 78
        }
    }
}
