import CoreGraphics
import PokeDataModel

struct BattleViewportPresentationRules {
    let battleKind: BattleKind
    let presentation: BattlePresentationTelemetry
    let hasPlayerTrainerSprite: Bool
    let playerCurrentHP: Int
    let enemyCurrentHP: Int
    let sendOutVisualState: BattleSendOutVisualState
    let activeSendOutAnimationKey: String?
    let sendOutAnimationTriggerKey: String
    let attackAnimationVisualState: BattleAttackAnimationVisualState
    let activeAttackAnimationKey: String?
    let attackAnimationTriggerKey: String
    let applyingHitEffectVisualState: BattleApplyingHitEffectVisualState
    let activeApplyingHitEffectKey: String?
    let applyingHitEffectTriggerKey: String

    var semantics: BattlePresentationSemantics {
        presentation.semantics
    }

    var isTrainerBattle: Bool {
        battleKind == .trainer
    }

    var isWildBattle: Bool {
        battleKind == .wild
    }

    var shouldShowEnemyTrainer: Bool {
        isTrainerBattle && (
            semantics.showsIntroTrainers ||
                semantics.sendOutSide == .enemy
        )
    }

    var shouldShowPlayerTrainer: Bool {
        hasPlayerTrainerSprite && (
            semantics.showsIntroTrainers ||
                semantics.sendOutSide == .player
        )
    }

    var shouldShowEnemyPokemon: Bool {
        if isTrainerBattle && semantics.hidesTrainerPokemonDuringIntro {
            return false
        }
        return true
    }

    var shouldShowPlayerPokemon: Bool {
        if isTrainerBattle && semantics.hidesTrainerPokemonDuringIntro {
            return false
        }
        if isWildBattle {
            switch semantics.phase {
            case .introFlash, .introSpiral, .introCrossing, .introReveal:
                return false
            case .sendOut(side: .enemy):
                return false
            default:
                break
            }
        }
        return true
    }

    var shouldShowPokeball: Bool {
        semantics.isSendOutStage
    }

    var currentSendOutState: BattleSendOutVisualState {
        Self.resolvedSendOutState(
            stage: presentation.stage,
            sendOutVisualState: sendOutVisualState,
            animationTriggerKey: sendOutAnimationTriggerKey,
            activeAnimationKey: activeSendOutAnimationKey
        )
    }

    var currentAttackAnimationState: BattleAttackAnimationVisualState {
        Self.resolvedAttackAnimationState(
            attackAnimation: presentation.attackAnimation,
            attackAnimationVisualState: attackAnimationVisualState,
            animationTriggerKey: attackAnimationTriggerKey,
            activeAnimationKey: activeAttackAnimationKey
        )
    }

    var currentApplyingHitEffectState: BattleApplyingHitEffectVisualState {
        Self.resolvedApplyingHitEffectState(
            applyingHitEffect: presentation.applyingHitEffect,
            applyingHitEffectVisualState: applyingHitEffectVisualState,
            animationTriggerKey: applyingHitEffectTriggerKey,
            activeAnimationKey: activeApplyingHitEffectKey
        )
    }

    var combinedScreenShake: CGSize {
        CGSize(
            width: currentAttackAnimationState.screenShake.width + currentApplyingHitEffectState.screenShake.width,
            height: currentAttackAnimationState.screenShake.height + currentApplyingHitEffectState.screenShake.height
        )
    }

    var sendOutPoofFrame: BattleSendOutPoofFrame? {
        let activeSide = presentation.activeSide ?? .player
        guard let frameIndex = currentSendOutState.poofFrameIndex,
              BattleSendOutAnimationTimeline.poofFrames(for: activeSide).indices.contains(frameIndex) else {
            return nil
        }
        return BattleSendOutAnimationTimeline.poofFrames(for: activeSide)[frameIndex]
    }

    var sendOutPoofOpacity: Double {
        currentSendOutState.poofOpacity
    }

    var enemyHudOpacity: Double {
        guard presentation.uiVisibility == .visible else { return 0 }

        if isTrainerBattle {
            if semantics.isIntroRevealStage {
                return 0
            }
            if semantics.sendOutSide == .enemy {
                return currentSendOutState.pokemonOpacity
            }
        }

        return 1
    }

    var trainerPartyIndicatorOpacity: Double {
        guard presentation.uiVisibility == .visible else { return 0 }
        return Self.trainerPartyIndicatorOpacity(
            battleKind: battleKind,
            stage: presentation.stage,
            activeSide: presentation.activeSide,
            sendOutPokemonOpacity: currentSendOutState.pokemonOpacity
        )
    }

    var playerHudOpacity: Double {
        guard presentation.uiVisibility == .visible else { return 0 }
        return Self.playerHudOpacity(
            battleKind: battleKind,
            stage: presentation.stage,
            activeSide: presentation.activeSide,
            hidePlayerPokemon: presentation.hidePlayerPokemon,
            sendOutPokemonOpacity: currentSendOutState.pokemonOpacity
        )
    }

    var enemyHudOffset: CGSize {
        let hiddenOffset: CGFloat = enemyHudOpacity > 0 ? 0 : 14
        return CGSize(
            width: currentAttackAnimationState.enemyHUDOffset.width,
            height: hiddenOffset + currentAttackAnimationState.enemyHUDOffset.height
        )
    }

    var trainerPartyIndicatorOffset: CGSize {
        if semantics.sendOutSide == .enemy {
            let progress = max(0, min(1, currentSendOutState.pokemonOpacity))
            return CGSize(
                width: progress * 18,
                height: progress * -8
            )
        }

        if trainerPartyIndicatorOpacity == 0 {
            return CGSize(width: -14, height: -10)
        }

        return .zero
    }

    var playerHudOffset: CGFloat {
        playerHudOpacity > 0 ? 0 : 14
    }

    var trainerOpacity: Double {
        switch semantics.phase {
        case .introReveal, .sendOut:
            return 1
        case .introCrossing:
            return 0.96
        default:
            return 0.92
        }
    }

    var trainerScale: CGFloat {
        semantics.isSendOutStage ? 1.01 : 1
    }

    var enemySpriteScale: CGFloat {
        let baseScale: CGFloat
        switch semantics.phase {
        case .introReveal where isTrainerBattle:
            baseScale = 0.34
        case .sendOut(side: .enemy):
            baseScale = currentSendOutState.pokemonScale
        default:
            if presentation.stage == .attackImpact &&
                presentation.activeSide == .enemy &&
                presentation.attackAnimation == nil &&
                presentation.applyingHitEffect == nil {
                baseScale = 1.04
            } else {
                baseScale = enemyCurrentHP == 0 ? 0.18 : 1
            }
        }
        return baseScale * currentAttackAnimationState.enemyScale
    }

    var playerSpriteScale: CGFloat {
        let baseScale: CGFloat
        switch semantics.phase {
        case .introReveal where isTrainerBattle:
            baseScale = 0.34
        case .sendOut(side: .player):
            baseScale = currentSendOutState.pokemonScale
        default:
            if presentation.stage == .attackImpact &&
                presentation.activeSide == .player &&
                presentation.attackAnimation == nil &&
                presentation.applyingHitEffect == nil {
                baseScale = 1.04
            } else {
                baseScale = playerCurrentHP == 0 ? 0.18 : 1
            }
        }
        return baseScale * currentAttackAnimationState.playerScale
    }

    var enemyPokemonOpacity: Double {
        let visibility: Double
        if isTrainerBattle && semantics.isIntroRevealStage {
            visibility = 0
        } else if semantics.sendOutSide == .enemy {
            visibility = currentSendOutState.pokemonOpacity
        } else if enemyCurrentHP == 0 {
            visibility = 0
        } else {
            visibility = 1
        }
        return visibility * currentAttackAnimationState.enemyOpacity * currentApplyingHitEffectState.enemyOpacity
    }

    var playerPokemonOpacity: Double {
        Self.playerPokemonOpacity(
            battleKind: battleKind,
            stage: presentation.stage,
            activeSide: presentation.activeSide,
            hidePlayerPokemon: presentation.hidePlayerPokemon,
            playerCurrentHP: playerCurrentHP,
            sendOutPokemonOpacity: currentSendOutState.pokemonOpacity
        ) * currentAttackAnimationState.playerOpacity * currentApplyingHitEffectState.playerOpacity
    }

    func enemyTrainerCenter(in layout: BattleViewportLayout) -> CGPoint {
        let settled = layout.enemyTrainerCenter
        switch semantics.phase {
        case .introFlash, .introSpiral:
            return CGPoint(
                x: -(layout.enemyTrainerSize.width * 0.5) - 12,
                y: settled.y - 6
            )
        case .introCrossing, .introReveal:
            return settled
        case .sendOut(side: .enemy):
            return CGPoint(
                x: layout.size.width + layout.enemyTrainerSize.width * 0.5 + 16,
                y: settled.y - 4
            )
        default:
            return settled
        }
    }

    func playerTrainerCenter(in layout: BattleViewportLayout) -> CGPoint {
        let settled = layout.playerTrainerCenter
        switch semantics.phase {
        case .introFlash, .introSpiral:
            return CGPoint(
                x: layout.size.width + layout.playerTrainerSize.width * 0.5 + 12,
                y: settled.y + 6
            )
        case .introCrossing, .introReveal:
            return settled
        case .sendOut(side: .player):
            return CGPoint(
                x: -(layout.playerTrainerSize.width * 0.5) - 16,
                y: settled.y + 2
            )
        default:
            return settled
        }
    }

    func enemySpriteCenter(in layout: BattleViewportLayout) -> CGPoint {
        let settled = layout.enemySpriteCenter
        let sendOutAnchor = layout.enemySendOutAnchor
        switch semantics.phase {
        case .introFlash, .introSpiral:
            guard isWildBattle else { return settled }
            return CGPoint(
                x: -(layout.enemySpriteSize.width * 0.5) - 12,
                y: settled.y - 6
            )
        case .introReveal where isTrainerBattle:
            return sendOutAnchor
        case .sendOut(side: .enemy):
            return currentSendOutState.usesSendOutAnchor ? sendOutAnchor : settled
        default:
            if presentation.stage == .attackWindup &&
                presentation.activeSide == .enemy &&
                presentation.attackAnimation == nil {
                return CGPoint(x: settled.x - layout.size.width * 0.07, y: settled.y + 2)
            }
            if presentation.stage == .attackImpact &&
                presentation.activeSide == .enemy &&
                presentation.attackAnimation == nil &&
                presentation.applyingHitEffect == nil {
                return CGPoint(x: settled.x + layout.size.width * 0.02, y: settled.y)
            }
            if presentation.stage == .attackImpact &&
                presentation.activeSide == .player &&
                presentation.attackAnimation == nil &&
                presentation.applyingHitEffect == nil {
                return CGPoint(x: settled.x + layout.size.width * 0.03, y: settled.y - 2)
            }
            return CGPoint(
                x: settled.x + currentAttackAnimationState.enemyOffset.width,
                y: settled.y + currentAttackAnimationState.enemyOffset.height
            )
        }
    }

    func playerSpriteCenter(in layout: BattleViewportLayout) -> CGPoint {
        let settled = layout.playerSpriteCenter
        let sendOutAnchor = layout.playerSendOutAnchor
        switch semantics.phase {
        case .introReveal where isTrainerBattle:
            return sendOutAnchor
        case .sendOut(side: .player):
            return currentSendOutState.usesSendOutAnchor ? sendOutAnchor : settled
        default:
            if presentation.stage == .attackWindup &&
                presentation.activeSide == .player &&
                presentation.attackAnimation == nil {
                return CGPoint(x: settled.x + layout.size.width * 0.09, y: settled.y - 4)
            }
            if presentation.stage == .attackImpact &&
                presentation.activeSide == .player &&
                presentation.attackAnimation == nil &&
                presentation.applyingHitEffect == nil {
                return CGPoint(x: settled.x - layout.size.width * 0.02, y: settled.y)
            }
            if presentation.stage == .attackImpact &&
                presentation.activeSide == .enemy &&
                presentation.attackAnimation == nil &&
                presentation.applyingHitEffect == nil {
                return CGPoint(x: settled.x - layout.size.width * 0.03, y: settled.y + 2)
            }
            return CGPoint(
                x: settled.x + currentAttackAnimationState.playerOffset.width,
                y: settled.y + currentAttackAnimationState.playerOffset.height
            )
        }
    }

    func pokeballCenter(in layout: BattleViewportLayout) -> CGPoint {
        if presentation.activeSide == .enemy {
            return layout.enemySendOutAnchor
        } else {
            return layout.playerSendOutAnchor
        }
    }

    func sendOutPoofCenter(in layout: BattleViewportLayout) -> CGPoint {
        presentation.activeSide == .enemy ? layout.enemySendOutAnchor : layout.playerSendOutAnchor
    }

    static func usesImplicitPokemonRevisionAnimation(
        stage: BattlePresentationStage,
        activeSide: BattlePresentationSide?,
        attackAnimation: BattleAttackAnimationPlaybackTelemetry?,
        hidePlayerPokemon: Bool,
        side: BattlePresentationSide
    ) -> Bool {
        if stage == .enemySendOut, activeSide == side {
            return false
        }
        if hidePlayerPokemon && side == .player {
            return false
        }
        return !(attackAnimation != nil && activeSide == side)
    }

    static func playerHudOpacity(
        battleKind: BattleKind,
        stage: BattlePresentationStage,
        activeSide: BattlePresentationSide?,
        hidePlayerPokemon: Bool,
        sendOutPokemonOpacity: Double
    ) -> Double {
        if hidePlayerPokemon {
            return 0
        }

        switch battleKind {
        case .trainer:
            switch stage {
            case .introReveal:
                return 0
            case .enemySendOut where activeSide == .enemy:
                return 0
            case .enemySendOut where activeSide == .player:
                return sendOutPokemonOpacity
            default:
                return 1
            }
        case .wild:
            switch stage {
            case .introReveal:
                return 0
            case .enemySendOut where activeSide == .player:
                return sendOutPokemonOpacity
            default:
                return 1
            }
        }
    }

    static func trainerPartyIndicatorOpacity(
        battleKind: BattleKind,
        stage: BattlePresentationStage,
        activeSide: BattlePresentationSide?,
        sendOutPokemonOpacity: Double
    ) -> Double {
        guard battleKind == .trainer else { return 0 }

        switch stage {
        case .introReveal:
            return 1
        case .enemySendOut where activeSide == .enemy:
            return max(0, 1 - sendOutPokemonOpacity)
        default:
            return 0
        }
    }

    static func playerPokemonOpacity(
        battleKind: BattleKind,
        stage: BattlePresentationStage,
        activeSide: BattlePresentationSide?,
        hidePlayerPokemon: Bool,
        playerCurrentHP: Int,
        sendOutPokemonOpacity: Double
    ) -> Double {
        if hidePlayerPokemon {
            return 0
        }

        switch battleKind {
        case .trainer:
            switch stage {
            case .introReveal:
                return 0
            case .enemySendOut where activeSide == .player:
                return sendOutPokemonOpacity
            default:
                return playerCurrentHP == 0 ? 0 : 1
            }
        case .wild:
            switch stage {
            case .introFlash1, .introFlash2, .introFlash3, .introSpiral, .introCrossing, .introReveal:
                return 0
            case .enemySendOut where activeSide == .player:
                return sendOutPokemonOpacity
            default:
                return playerCurrentHP == 0 ? 0 : 1
            }
        }
    }

    static func resolvedSendOutState(
        stage: BattlePresentationStage,
        sendOutVisualState: BattleSendOutVisualState,
        animationTriggerKey: String,
        activeAnimationKey: String?
    ) -> BattleSendOutVisualState {
        guard stage == .enemySendOut, activeAnimationKey == animationTriggerKey else {
            return .idle
        }
        return sendOutVisualState
    }

    static func resolvedAttackAnimationState(
        attackAnimation: BattleAttackAnimationPlaybackTelemetry?,
        attackAnimationVisualState: BattleAttackAnimationVisualState,
        animationTriggerKey: String,
        activeAnimationKey: String?
    ) -> BattleAttackAnimationVisualState {
        guard attackAnimation != nil, activeAnimationKey == animationTriggerKey else {
            return .idle
        }
        return attackAnimationVisualState
    }

    static func resolvedApplyingHitEffectState(
        applyingHitEffect: BattleApplyingHitEffectTelemetry?,
        applyingHitEffectVisualState: BattleApplyingHitEffectVisualState,
        animationTriggerKey: String,
        activeAnimationKey: String?
    ) -> BattleApplyingHitEffectVisualState {
        guard applyingHitEffect != nil, activeAnimationKey == animationTriggerKey else {
            return .idle
        }
        return applyingHitEffectVisualState
    }
}
