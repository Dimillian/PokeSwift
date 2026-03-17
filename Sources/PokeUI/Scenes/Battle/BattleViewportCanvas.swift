import CoreGraphics
import SwiftUI
import PokeDataModel
import PokeRender

struct BattleViewportCanvas: View {
    let kind: BattleKind
    let playerPokemon: PartyPokemonTelemetry
    let enemyPokemon: PartyPokemonTelemetry
    let enemyPartyCount: Int
    let isEnemySpeciesOwned: Bool
    let trainerSpriteURL: URL?
    let playerTrainerFrontSpriteURL: URL?
    let playerTrainerBackSpriteURL: URL?
    let sendOutPoofSpriteURL: URL?
    let battleAnimationManifest: BattleAnimationManifest
    let battleAnimationTilesetURLs: [String: URL]
    let playerSpriteURL: URL?
    let enemySpriteURL: URL?
    let displayStyle: FieldDisplayStyle
    let hdrBoost: Float
    let presentation: BattlePresentationTelemetry

    @State private var sendOutVisualState: BattleSendOutVisualState = .idle
    @State private var activeSendOutAnimationKey: String?
    @State private var attackAnimationVisualState: BattleAttackAnimationVisualState = .idle
    @State private var activeAttackAnimationKey: String?
    @State private var applyingHitEffectVisualState: BattleApplyingHitEffectVisualState = .idle
    @State private var activeApplyingHitEffectKey: String?

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let layout = BattleViewportLayout(size: size)
            let displayScale = GameplayViewportScale.snappedFieldViewportScale(for: size)

            ZStack(alignment: .topLeading) {
                battlefieldLayer(layout: layout, size: size, displayScale: displayScale)
                hudLayer(layout: layout)
            }
            .battleTransitionEffect(
                displayScale: displayScale,
                presentation: presentation
            )
            .task(id: sendOutAnimationTriggerKey) {
                await runSendOutAnimationSequence()
            }
            .task(id: attackAnimationTriggerKey) {
                await runAttackAnimationSequence()
            }
            .task(id: applyingHitEffectTriggerKey) {
                await runApplyingHitEffectSequence()
            }
        }
    }

    @ViewBuilder
    private func battlefieldLayer(
        layout: BattleViewportLayout,
        size: CGSize,
        displayScale: CGFloat
    ) -> some View {
        ZStack(alignment: .topLeading) {
            battleBackground

            if let trainerSpriteURL, shouldShowEnemyTrainer {
                PixelAssetView(
                    url: trainerSpriteURL,
                    label: "Trainer",
                    whiteIsTransparent: true
                )
                .frame(width: layout.enemyTrainerSize.width, height: layout.enemyTrainerSize.height)
                .position(enemyTrainerCenter(in: layout))
                .scaleEffect(trainerScale)
                .opacity(trainerOpacity)
                .animation(spriteAnimation, value: presentation.revision)
            }

            if let playerTrainerSpriteURL, shouldShowPlayerTrainer {
                PixelAssetView(
                    url: playerTrainerSpriteURL,
                    label: "Player Trainer",
                    whiteIsTransparent: true
                )
                .frame(width: layout.playerTrainerSize.width, height: layout.playerTrainerSize.height)
                .position(playerTrainerCenter(in: layout))
                .scaleEffect(trainerScale)
                .opacity(trainerOpacity)
                .animation(spriteAnimation, value: presentation.revision)
            }

            if let enemySpriteURL, shouldShowEnemyPokemon {
                PixelAssetView(
                    url: enemySpriteURL,
                    label: enemyPokemon.displayName,
                    whiteIsTransparent: true,
                    renderMode: .battlePokemonFront
                )
                .frame(width: layout.enemySpriteSize.width, height: layout.enemySpriteSize.height)
                .scaleEffect(
                    enemySpriteScale,
                    anchor: Self.pokemonScaleAnchor(
                        stage: presentation.stage,
                        activeSide: presentation.activeSide,
                        side: .enemy
                    )
                )
                .rotationEffect(enemyPokemonRotation)
                .opacity(enemyPokemonOpacity)
                .position(enemySpriteCenter(in: layout))
                .animation(
                    Self.usesImplicitPokemonRevisionAnimation(
                        stage: presentation.stage,
                        activeSide: presentation.activeSide,
                        attackAnimation: presentation.attackAnimation,
                        hidePlayerPokemon: presentation.hidePlayerPokemon,
                        side: .enemy
                    ) ? spriteAnimation : nil,
                    value: presentation.revision
                )
            }

            if let sendOutPoofSpriteURL, let sendOutPoofFrame {
                BattleSendOutPoofView(
                    url: sendOutPoofSpriteURL,
                    frame: sendOutPoofFrame,
                    label: "Send Out Poof",
                    whiteIsTransparent: true
                )
                .frame(width: layout.sendOutPoofSize.width, height: layout.sendOutPoofSize.height)
                .position(sendOutPoofCenter(in: layout))
                .opacity(sendOutPoofOpacity)
            }

            if let playerSpriteURL, shouldShowPlayerPokemon {
                PixelAssetView(
                    url: playerSpriteURL,
                    label: playerPokemon.displayName,
                    whiteIsTransparent: true,
                    renderMode: .battlePokemonBack
                )
                .frame(width: layout.playerSpriteSize.width, height: layout.playerSpriteSize.height)
                .scaleEffect(
                    playerSpriteScale,
                    anchor: Self.pokemonScaleAnchor(
                        stage: presentation.stage,
                        activeSide: presentation.activeSide,
                        side: .player
                    )
                )
                .rotationEffect(playerPokemonRotation)
                .opacity(playerPokemonOpacity)
                .position(playerSpriteCenter(in: layout))
                .animation(
                    Self.usesImplicitPokemonRevisionAnimation(
                        stage: presentation.stage,
                        activeSide: presentation.activeSide,
                        attackAnimation: presentation.attackAnimation,
                        hidePlayerPokemon: presentation.hidePlayerPokemon,
                        side: .player
                    ) ? spriteAnimation : nil,
                    value: presentation.revision
                )
            }

            if currentAttackAnimationState.overlayPlacements.isEmpty == false {
                BattleAttackAnimationLayerView(
                    placements: currentAttackAnimationState.overlayPlacements,
                    tilesetURLs: battleAnimationTilesetURLs,
                    displayScale: displayScale
                )
            }

            if currentAttackAnimationState.particlePlacements.isEmpty == false {
                BattleAttackAnimationParticleLayerView(
                    placements: currentAttackAnimationState.particlePlacements,
                    displayScale: displayScale
                )
            }

            if shouldShowPokeball {
                BattlePokeballToken()
                    .frame(width: max(8, size.width * 0.05), height: max(8, size.width * 0.05))
                    .position(pokeballCenter(in: layout))
                    .opacity(currentSendOutState.ballOpacity)
                    .animation(spriteAnimation, value: presentation.revision)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .overlay {
            Rectangle()
                .fill(Color.white.opacity(currentAttackAnimationState.flashOpacity))
                .blendMode(.plusLighter)
        }
        .overlay {
            Rectangle()
                .fill(Color.black.opacity(currentAttackAnimationState.darknessOpacity))
        }
        .offset(
            x: combinedScreenShake.width * displayScale,
            y: combinedScreenShake.height * displayScale
        )
        .gameplayScreenEffect(
            displayStyle: displayStyle,
            displayScale: displayScale,
            battlePresentation: presentation,
            hdrBoost: hdrBoost
        )
    }

    @ViewBuilder
    private func hudLayer(layout: BattleViewportLayout) -> some View {
        let sharedNameScale = BattleStatusCard.sharedNameScale(
            enemyCardWidth: layout.enemyCardSize.width,
            playerCardWidth: layout.playerCardSize.width,
            enemyShowsCaughtIndicator: shouldShowEnemyCaughtIndicator
        )

        BattleTrainerPartyIndicator(
            filledCount: enemyPartyCount,
            totalCount: 6,
            stage: presentation.stage,
            animationRevision: presentation.revision
        )
        .frame(
            width: layout.enemyCardSize.width * 0.84,
            height: layout.enemyCardSize.height * 0.76
        )
        .position(
            x: layout.enemyCardCenter.x + (layout.enemyCardSize.width * 0.015),
            y: layout.enemyCardCenter.y
        )
        .opacity(trainerPartyIndicatorOpacity)
        .offset(x: trainerPartyIndicatorOffset.width, y: trainerPartyIndicatorOffset.height)
        .animation(hudAnimation, value: presentation.revision)

        BattleStatusCard(
            pokemon: enemyPokemon,
            chrome: .enemy,
            showsCaughtIndicator: shouldShowEnemyCaughtIndicator,
            showsExperience: false,
            presentation: presentation,
            nameScale: sharedNameScale
        )
        .frame(width: layout.enemyCardSize.width, height: layout.enemyCardSize.height)
        .position(x: layout.enemyCardCenter.x, y: layout.enemyCardCenter.y)
        .opacity(enemyHudOpacity)
        .offset(x: enemyHudOffset.width, y: enemyHudOffset.height)
        .animation(hudAnimation, value: presentation.revision)

        BattleStatusCard(
            pokemon: playerPokemon,
            chrome: .player,
            showsCaughtIndicator: false,
            showsExperience: true,
            presentation: presentation,
            nameScale: sharedNameScale
        )
        .frame(width: layout.playerCardSize.width, height: layout.playerCardSize.height)
        .position(x: layout.playerCardCenter.x, y: layout.playerCardCenter.y)
        .opacity(playerHudOpacity)
        .offset(y: playerHudOffset)
        .animation(hudAnimation, value: presentation.revision)
    }

    private var isTrainerBattle: Bool {
        kind == .trainer
    }

    private var isWildBattle: Bool {
        kind == .wild
    }

    private var shouldShowEnemyCaughtIndicator: Bool {
        BattleStatusCard.showsCaughtIndicator(
            chrome: .enemy,
            battleKind: kind,
            isSpeciesOwned: isEnemySpeciesOwned
        )
    }

    private var playerTrainerSpriteURL: URL? {
        playerTrainerBackSpriteURL ?? playerTrainerFrontSpriteURL
    }

    private var shouldShowEnemyTrainer: Bool {
        guard isTrainerBattle else { return false }
        switch presentation.stage {
        case .introFlash1, .introFlash2, .introFlash3, .introSpiral, .introCrossing, .introReveal:
            return true
        case .enemySendOut:
            return presentation.activeSide == .enemy
        default:
            return false
        }
    }

    private var shouldShowPlayerTrainer: Bool {
        guard playerTrainerSpriteURL != nil else { return false }
        switch presentation.stage {
        case .introFlash1, .introFlash2, .introFlash3, .introSpiral, .introCrossing, .introReveal:
            return true
        case .enemySendOut:
            return presentation.activeSide == .player
        default:
            return false
        }
    }

    private var shouldShowEnemyPokemon: Bool {
        if isTrainerBattle {
            switch presentation.stage {
            case .introFlash1, .introFlash2, .introFlash3, .introSpiral, .introCrossing:
                return false
            default:
                break
            }
        }
        return true
    }

    private var shouldShowPlayerPokemon: Bool {
        if isTrainerBattle {
            switch presentation.stage {
            case .introFlash1, .introFlash2, .introFlash3, .introSpiral, .introCrossing:
                return false
            default:
                break
            }
        } else if isWildBattle {
            switch presentation.stage {
            case .introFlash1, .introFlash2, .introFlash3, .introSpiral, .introCrossing, .introReveal:
                return false
            case .enemySendOut where presentation.activeSide == .enemy:
                return false
            default:
                break
            }
        }
        return true
    }

    private var shouldShowPokeball: Bool {
        presentation.stage == .enemySendOut
    }

    private var currentSendOutState: BattleSendOutVisualState {
        Self.resolvedSendOutState(
            stage: presentation.stage,
            sendOutVisualState: sendOutVisualState,
            animationTriggerKey: sendOutAnimationTriggerKey,
            activeAnimationKey: activeSendOutAnimationKey
        )
    }

    private var currentAttackAnimationState: BattleAttackAnimationVisualState {
        Self.resolvedAttackAnimationState(
            attackAnimation: presentation.attackAnimation,
            attackAnimationVisualState: attackAnimationVisualState,
            animationTriggerKey: attackAnimationTriggerKey,
            activeAnimationKey: activeAttackAnimationKey
        )
    }

    private var currentApplyingHitEffectState: BattleApplyingHitEffectVisualState {
        Self.resolvedApplyingHitEffectState(
            applyingHitEffect: presentation.applyingHitEffect,
            applyingHitEffectVisualState: applyingHitEffectVisualState,
            animationTriggerKey: applyingHitEffectTriggerKey,
            activeAnimationKey: activeApplyingHitEffectKey
        )
    }

    private var combinedScreenShake: CGSize {
        CGSize(
            width: currentAttackAnimationState.screenShake.width + currentApplyingHitEffectState.screenShake.width,
            height: currentAttackAnimationState.screenShake.height + currentApplyingHitEffectState.screenShake.height
        )
    }

    private var sendOutPoofFrame: BattleSendOutPoofFrame? {
        let activeSide = presentation.activeSide ?? .player
        guard let frameIndex = currentSendOutState.poofFrameIndex,
              BattleSendOutAnimationTimeline.poofFrames(for: activeSide).indices.contains(frameIndex) else {
            return nil
        }
        return BattleSendOutAnimationTimeline.poofFrames(for: activeSide)[frameIndex]
    }

    private var sendOutPoofOpacity: Double {
        currentSendOutState.poofOpacity
    }

    private var sendOutAnimationTriggerKey: String {
        "\(presentation.stage)-\(String(describing: presentation.activeSide))-\(presentation.revision)"
    }

    private var attackAnimationTriggerKey: String {
        presentation.attackAnimation?.playbackID ?? "attack-idle-\(presentation.revision)"
    }

    private var applyingHitEffectTriggerKey: String {
        presentation.applyingHitEffect?.playbackID ?? "hit-idle-\(presentation.revision)"
    }

    private var sendOutPoofSequence: [Int] {
        BattleSendOutAnimationTimeline.poofFrameSequence(for: presentation.activeSide ?? .player)
    }

    private var enemyHudOpacity: Double {
        guard presentation.uiVisibility == .visible else { return 0 }

        if isTrainerBattle {
            switch presentation.stage {
            case .introReveal:
                return 0
            case .enemySendOut where presentation.activeSide == .enemy:
                return currentSendOutState.pokemonOpacity
            default:
                return 1
            }
        }

        return 1
    }

    private var trainerPartyIndicatorOpacity: Double {
        guard presentation.uiVisibility == .visible else { return 0 }
        return Self.trainerPartyIndicatorOpacity(
            battleKind: kind,
            stage: presentation.stage,
            activeSide: presentation.activeSide,
            sendOutPokemonOpacity: currentSendOutState.pokemonOpacity
        )
    }

    private var playerHudOpacity: Double {
        guard presentation.uiVisibility == .visible else { return 0 }
        return Self.playerHudOpacity(
            battleKind: kind,
            stage: presentation.stage,
            activeSide: presentation.activeSide,
            hidePlayerPokemon: presentation.hidePlayerPokemon,
            sendOutPokemonOpacity: currentSendOutState.pokemonOpacity
        )
    }

    private var enemyHudOffset: CGSize {
        let hiddenOffset: CGFloat = enemyHudOpacity > 0 ? 0 : 14
        return .init(
            width: currentAttackAnimationState.enemyHUDOffset.width,
            height: hiddenOffset + currentAttackAnimationState.enemyHUDOffset.height
        )
    }

    private var trainerPartyIndicatorOffset: CGSize {
        if presentation.stage == .enemySendOut, presentation.activeSide == .enemy {
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

    private var playerHudOffset: CGFloat {
        playerHudOpacity > 0 ? 0 : 14
    }

    private var trainerOpacity: Double {
        switch presentation.stage {
        case .introReveal, .enemySendOut:
            return 1
        case .introCrossing:
            return 0.96
        default:
            return 0.92
        }
    }

    private var trainerScale: CGFloat {
        presentation.stage == .enemySendOut ? 1.01 : 1
    }

    private var enemySpriteScale: CGFloat {
        let baseScale: CGFloat
        switch presentation.stage {
        case .introReveal where isTrainerBattle:
            baseScale = 0.34
        case .enemySendOut where presentation.activeSide == .enemy:
            baseScale = currentSendOutState.pokemonScale
        case .attackImpact
            where presentation.activeSide == .enemy &&
            presentation.attackAnimation == nil &&
            presentation.applyingHitEffect == nil:
            baseScale = 1.04
        default:
            baseScale = enemyPokemon.currentHP == 0 ? 0.18 : 1
        }
        return baseScale * currentAttackAnimationState.enemyScale
    }

    private var playerSpriteScale: CGFloat {
        let baseScale: CGFloat
        switch presentation.stage {
        case .introReveal where isTrainerBattle:
            baseScale = 0.34
        case .enemySendOut where presentation.activeSide == .player:
            baseScale = currentSendOutState.pokemonScale
        case .attackImpact
            where presentation.activeSide == .player &&
            presentation.attackAnimation == nil &&
            presentation.applyingHitEffect == nil:
            baseScale = 1.04
        default:
            baseScale = playerPokemon.currentHP == 0 ? 0.18 : 1
        }
        return baseScale * currentAttackAnimationState.playerScale
    }

    private var enemyPokemonOpacity: Double {
        let visibility: Double
        if isTrainerBattle, presentation.stage == .introReveal {
            visibility = 0
        } else if presentation.stage == .enemySendOut, presentation.activeSide == .enemy {
            visibility = currentSendOutState.pokemonOpacity
        } else if enemyPokemon.currentHP == 0 {
            visibility = 0
        } else {
            visibility = 1
        }
        return visibility * currentAttackAnimationState.enemyOpacity * currentApplyingHitEffectState.enemyOpacity
    }

    private var playerPokemonOpacity: Double {
        Self.playerPokemonOpacity(
            battleKind: kind,
            stage: presentation.stage,
            activeSide: presentation.activeSide,
            hidePlayerPokemon: presentation.hidePlayerPokemon,
            playerCurrentHP: playerPokemon.currentHP,
            sendOutPokemonOpacity: currentSendOutState.pokemonOpacity
        ) * currentAttackAnimationState.playerOpacity * currentApplyingHitEffectState.playerOpacity
    }

    private var enemyPokemonRotation: Angle {
        .degrees(0)
    }

    private var playerPokemonRotation: Angle {
        .degrees(0)
    }

    private func enemyTrainerCenter(in layout: BattleViewportLayout) -> CGPoint {
        let settled = layout.enemyTrainerCenter
        switch presentation.stage {
        case .introFlash1, .introFlash2, .introFlash3, .introSpiral:
            return CGPoint(
                x: -(layout.enemyTrainerSize.width * 0.5) - 12,
                y: settled.y - 6
            )
        case .introCrossing, .introReveal:
            return settled
        case .enemySendOut where presentation.activeSide == .enemy:
            return CGPoint(
                x: layout.size.width + layout.enemyTrainerSize.width * 0.5 + 16,
                y: settled.y - 4
            )
        default:
            return settled
        }
    }

    private func playerTrainerCenter(in layout: BattleViewportLayout) -> CGPoint {
        let settled = layout.playerTrainerCenter
        switch presentation.stage {
        case .introFlash1, .introFlash2, .introFlash3, .introSpiral:
            return CGPoint(
                x: layout.size.width + layout.playerTrainerSize.width * 0.5 + 12,
                y: settled.y + 6
            )
        case .introCrossing, .introReveal:
            return settled
        case .enemySendOut where presentation.activeSide == .player:
            return CGPoint(
                x: -(layout.playerTrainerSize.width * 0.5) - 16,
                y: settled.y + 2
            )
        default:
            return settled
        }
    }

    private func enemySpriteCenter(in layout: BattleViewportLayout) -> CGPoint {
        let settled = layout.enemySpriteCenter
        let sendOutAnchor = layout.enemySendOutAnchor
        switch presentation.stage {
        case .introFlash1, .introFlash2, .introFlash3, .introSpiral:
            guard isWildBattle else { return settled }
            return CGPoint(
                x: -(layout.enemySpriteSize.width * 0.5) - 12,
                y: settled.y - 6
            )
        case .introReveal where isTrainerBattle:
            return sendOutAnchor
        case .enemySendOut where presentation.activeSide == .enemy:
            return currentSendOutState.usesSendOutAnchor ? sendOutAnchor : settled
        case .attackWindup where presentation.activeSide == .enemy && presentation.attackAnimation == nil:
            return CGPoint(x: settled.x - layout.size.width * 0.07, y: settled.y + 2)
        case .attackImpact
            where presentation.activeSide == .enemy &&
            presentation.attackAnimation == nil &&
            presentation.applyingHitEffect == nil:
            return CGPoint(x: settled.x + layout.size.width * 0.02, y: settled.y)
        case .attackImpact
            where presentation.activeSide == .player &&
            presentation.attackAnimation == nil &&
            presentation.applyingHitEffect == nil:
            return CGPoint(x: settled.x + layout.size.width * 0.03, y: settled.y - 2)
        default:
            return CGPoint(
                x: settled.x + currentAttackAnimationState.enemyOffset.width,
                y: settled.y + currentAttackAnimationState.enemyOffset.height
            )
        }
    }

    private func playerSpriteCenter(in layout: BattleViewportLayout) -> CGPoint {
        let settled = layout.playerSpriteCenter
        let sendOutAnchor = layout.playerSendOutAnchor
        switch presentation.stage {
        case .introReveal where isTrainerBattle:
            return sendOutAnchor
        case .enemySendOut where presentation.activeSide == .player:
            return currentSendOutState.usesSendOutAnchor ? sendOutAnchor : settled
        case .attackWindup where presentation.activeSide == .player && presentation.attackAnimation == nil:
            return CGPoint(x: settled.x + layout.size.width * 0.09, y: settled.y - 4)
        case .attackImpact
            where presentation.activeSide == .player &&
            presentation.attackAnimation == nil &&
            presentation.applyingHitEffect == nil:
            return CGPoint(x: settled.x - layout.size.width * 0.02, y: settled.y)
        case .attackImpact
            where presentation.activeSide == .enemy &&
            presentation.attackAnimation == nil &&
            presentation.applyingHitEffect == nil:
            return CGPoint(x: settled.x - layout.size.width * 0.03, y: settled.y + 2)
        default:
            return CGPoint(
                x: settled.x + currentAttackAnimationState.playerOffset.width,
                y: settled.y + currentAttackAnimationState.playerOffset.height
            )
        }
    }

    private func pokeballCenter(in layout: BattleViewportLayout) -> CGPoint {
        let start: CGPoint
        let end: CGPoint
        if presentation.activeSide == .enemy {
            start = layout.enemyTrainerPokeballOrigin
            end = layout.enemySendOutAnchor
        } else {
            start = layout.playerTrainerPokeballOrigin
            end = layout.playerSendOutAnchor
        }

        return quadraticBezier(
            start: start,
            control: CGPoint(
                x: (start.x + end.x) / 2,
                y: min(start.y, end.y) - layout.size.height * 0.18
            ),
            end: end,
            progress: currentSendOutState.ballProgress
        )
    }

    private func sendOutPoofCenter(in layout: BattleViewportLayout) -> CGPoint {
        presentation.activeSide == .enemy ? layout.enemySendOutAnchor : layout.playerSendOutAnchor
    }

    private func quadraticBezier(start: CGPoint, control: CGPoint, end: CGPoint, progress: CGFloat) -> CGPoint {
        let t = max(0, min(1, progress))
        let inverseT = 1 - t
        let x = (inverseT * inverseT * start.x) + (2 * inverseT * t * control.x) + (t * t * end.x)
        let y = (inverseT * inverseT * start.y) + (2 * inverseT * t * control.y) + (t * t * end.y)
        return CGPoint(x: x, y: y)
    }

    static func pokemonScaleAnchor(
        stage: BattlePresentationStage,
        activeSide: BattlePresentationSide?,
        side: BattlePresentationSide
    ) -> UnitPoint {
        if stage == .enemySendOut, activeSide == side {
            // Keep the reveal locked to the settled battlefield position so the
            // sprite only scales up instead of drifting as it appears.
            return .center
        }
        return .center
    }

    static func usesImplicitPokemonRevisionAnimation(
        stage: BattlePresentationStage,
        activeSide: BattlePresentationSide?,
        attackAnimation: BattleAttackAnimationPlaybackTelemetry?,
        hidePlayerPokemon: Bool,
        side: BattlePresentationSide
    ) -> Bool {
        // Send-out reveal beats are driven by local sendOutVisualState. Letting
        // the stage revision animate the whole sprite causes SwiftUI to tween
        // more than just scale/opacity, which reads as the Pokemon drifting.
        if stage == .enemySendOut && activeSide == side {
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

    @MainActor
    private func runSendOutAnimationSequence() async {
        guard presentation.stage == .enemySendOut else {
            activeSendOutAnimationKey = nil
            sendOutVisualState = .idle
            return
        }

        activeSendOutAnimationKey = sendOutAnimationTriggerKey
        sendOutVisualState = .toss(progress: 0)

        withAnimation(.linear(duration: BattleSendOutAnimationTimeline.tossDuration)) {
            sendOutVisualState = .toss(progress: 1)
        }
        guard await sleepForSendOutStep(BattleSendOutAnimationTimeline.tossDuration) else { return }

        sendOutVisualState = .releaseHold
        guard await sleepForSendOutStep(BattleSendOutAnimationTimeline.releaseHoldDuration) else { return }

        for frameIndex in sendOutPoofSequence {
            sendOutVisualState = .poof(frameIndex: frameIndex)
            guard await sleepForSendOutStep(BattleSendOutAnimationTimeline.poofFrameDuration) else { return }
        }

        withAnimation(.linear(duration: BattleSendOutAnimationTimeline.revealStep1Duration)) {
            sendOutVisualState = .revealStep1
        }
        guard await sleepForSendOutStep(BattleSendOutAnimationTimeline.revealStep1Duration) else { return }

        withAnimation(.linear(duration: BattleSendOutAnimationTimeline.revealStep2Duration)) {
            sendOutVisualState = .revealStep2
        }
        guard await sleepForSendOutStep(BattleSendOutAnimationTimeline.revealStep2Duration) else { return }

        withAnimation(.linear(duration: BattleSendOutAnimationTimeline.revealFinalDuration)) {
            sendOutVisualState = .revealFinal
        }
    }

    @MainActor
    private func runAttackAnimationSequence() async {
        guard let attackAnimation = presentation.attackAnimation else {
            activeAttackAnimationKey = nil
            attackAnimationVisualState = .idle
            return
        }

        let keyframes = BattleAttackAnimationTimeline.sequence(
            for: attackAnimation,
            manifest: battleAnimationManifest
        )
        activeAttackAnimationKey = attackAnimationTriggerKey
        attackAnimationVisualState = .idle

        for keyframe in keyframes {
            attackAnimationVisualState = keyframe.state
            guard await sleepForAttackStep(keyframe.duration) else { return }
        }

        attackAnimationVisualState = .idle
    }

    @MainActor
    private func runApplyingHitEffectSequence() async {
        guard let applyingHitEffect = presentation.applyingHitEffect else {
            activeApplyingHitEffectKey = nil
            applyingHitEffectVisualState = .idle
            return
        }

        let keyframes = BattleApplyingHitEffectTimeline.sequence(for: applyingHitEffect)
        activeApplyingHitEffectKey = applyingHitEffectTriggerKey
        applyingHitEffectVisualState = .idle

        for keyframe in keyframes {
            applyingHitEffectVisualState = keyframe.state
            guard await sleepForAttackStep(keyframe.duration) else { return }
        }

        applyingHitEffectVisualState = .idle
    }

    private func sleepForSendOutStep(_ duration: TimeInterval) async -> Bool {
        let nanoseconds = UInt64(duration * 1_000_000_000)
        try? await Task.sleep(nanoseconds: nanoseconds)
        return Task.isCancelled == false
    }

    private func sleepForAttackStep(_ duration: TimeInterval) async -> Bool {
        let nanoseconds = UInt64(max(0, duration) * 1_000_000_000)
        try? await Task.sleep(nanoseconds: nanoseconds)
        return Task.isCancelled == false
    }

    private var battleBackground: some View {
        Rectangle()
            .fill(Color(red: 0.49, green: 0.56, blue: 0.17))
    }

    private var spriteAnimation: Animation? {
        switch presentation.stage {
        case .introCrossing:
            return .linear(duration: 0.55)
        case .enemySendOut:
            return .easeInOut(duration: BattleSendOutAnimationTimeline.tossDuration)
        default:
            return .easeInOut(duration: 0.24)
        }
    }

    private var hudAnimation: Animation {
        switch presentation.stage {
        case .introReveal:
            return .easeOut(duration: 0.18)
        default:
            return .easeInOut(duration: 0.24)
        }
    }

}

private struct BattleSendOutPoofView: View {
    let url: URL
    let frame: BattleSendOutPoofFrame
    let label: String
    let whiteIsTransparent: Bool

    var body: some View {
        GeometryReader { proxy in
            let scale = min(
                proxy.size.width / max(1, frame.canvasSize.width),
                proxy.size.height / max(1, frame.canvasSize.height)
            )
            ZStack(alignment: .topLeading) {
                ForEach(Array(frame.placements.enumerated()), id: \.offset) { _, placement in
                    PixelAssetFrameView(
                        url: url,
                        cropRect: placement.atlasFrame,
                        label: label,
                        maskStrategy: whiteIsTransparent ? .floodFillBorderWhite : .none,
                        flipHorizontal: placement.flipH,
                        flipVertical: placement.flipV
                    )
                    .frame(
                        width: BattleSendOutAnimationTimeline.poofTileSize.cgFloat * scale,
                        height: BattleSendOutAnimationTimeline.poofTileSize.cgFloat * scale
                    )
                    .offset(
                        x: placement.x.cgFloat * scale,
                        y: placement.y.cgFloat * scale
                    )
                }
            }
            .frame(
                width: frame.canvasSize.width * scale,
                height: frame.canvasSize.height * scale,
                alignment: .topLeading
            )
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .accessibilityLabel(label)
    }
}

private struct BattleAttackAnimationLayerView: View {
    let placements: [BattleAttackAnimationTilePlacement]
    let tilesetURLs: [String: URL]
    let displayScale: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(placements.enumerated()), id: \.offset) { _, placement in
                if let tilesetURL = tilesetURLs[placement.tilesetID] {
                    PixelAssetFrameView(
                        url: tilesetURL,
                        cropRect: placement.atlasFrame,
                        label: "Attack Animation Tile",
                        maskStrategy: .floodFillBorderWhite,
                        flipHorizontal: placement.flipH,
                        flipVertical: placement.flipV
                    )
                    .frame(
                        width: BattleAttackAnimationTimeline.tileSize.cgFloat * displayScale,
                        height: BattleAttackAnimationTimeline.tileSize.cgFloat * displayScale
                    )
                    .offset(
                        x: placement.x.cgFloat * displayScale,
                        y: placement.y.cgFloat * displayScale
                    )
                }
            }
        }
    }
}

private struct BattleAttackAnimationParticleLayerView: View {
    let placements: [BattleAttackAnimationParticlePlacement]
    let displayScale: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(placements.enumerated()), id: \.offset) { _, placement in
                particleView(for: placement)
                    .frame(
                        width: placement.width * displayScale,
                        height: placement.height * displayScale
                    )
                    .rotationEffect(.degrees(placement.rotationDegrees))
                    .opacity(placement.opacity)
                    .offset(
                        x: placement.x * displayScale,
                        y: placement.y * displayScale
                    )
            }
        }
    }

    @ViewBuilder
    private func particleView(
        for placement: BattleAttackAnimationParticlePlacement
    ) -> some View {
        switch placement.kind {
        case .orb:
            Circle()
                .fill(Color(white: 0.2))
                .overlay {
                    Circle()
                        .stroke(Color(white: 0.85), lineWidth: max(1, 0.8 * displayScale))
                }
        case .droplet:
            Capsule(style: .circular)
                .fill(Color(white: 0.78))
        case .leaf:
            Capsule(style: .circular)
                .fill(Color(white: 0.32))
        case .petal:
            Ellipse()
                .fill(Color(white: 0.68))
        }
    }
}

private extension Int {
    var cgFloat: CGFloat { CGFloat(self) }
}

struct BattleViewportLayout {
    let size: CGSize
    private let pokemonSpriteScaleFactor: CGFloat = 0.3
    private let playerPokemonFloorRatio: CGFloat = 0.79
    private let playerTrainerFloorRatio: CGFloat = 0.85
    private let playerFloorClearance: CGFloat = 2

    var enemyCardSize: CGSize {
        CGSize(width: size.width * 0.38, height: size.height * 0.105)
    }

    var playerCardSize: CGSize {
        CGSize(width: size.width * 0.41, height: size.height * 0.135)
    }

    var enemyCardCenter: CGPoint {
        CGPoint(x: size.width * 0.26, y: size.height * 0.135)
    }

    var playerCardCenter: CGPoint {
        CGPoint(x: size.width * 0.7, y: size.height * 0.6)
    }

    var enemyTrainerSize: CGSize {
        CGSize(width: size.width * 0.25, height: size.height * 0.34)
    }

    var playerTrainerSize: CGSize {
        CGSize(width: size.width * 0.24, height: size.height * 0.34)
    }

    var enemyTrainerCenter: CGPoint {
        CGPoint(
            x: enemySpriteCenter.x,
            y: enemySpriteCenter.y + (enemySpriteSize.height - enemyTrainerSize.height) * 0.5
        )
    }

    var playerTrainerCenter: CGPoint {
        CGPoint(
            x: size.width * 0.25,
            y: (size.height * playerTrainerFloorRatio) - playerFloorClearance - (playerTrainerSize.height * 0.5)
        )
    }

    var enemySpriteSize: CGSize {
        CGSize(width: size.width * pokemonSpriteScaleFactor, height: size.height * pokemonSpriteScaleFactor)
    }

    var playerSpriteSize: CGSize {
        CGSize(width: size.width * pokemonSpriteScaleFactor, height: size.height * pokemonSpriteScaleFactor)
    }

    var sendOutPoofSize: CGSize {
        CGSize(width: size.width * 0.2, height: size.width * 0.2)
    }

    var enemySpriteCenter: CGPoint {
        CGPoint(x: size.width * 0.72, y: size.height * 0.3)
    }

    var playerSpriteCenter: CGPoint {
        CGPoint(
            x: size.width * 0.25,
            y: (size.height * playerPokemonFloorRatio) - playerFloorClearance - (playerSpriteSize.height * 0.5)
        )
    }

    var enemyTrainerPokeballOrigin: CGPoint {
        CGPoint(
            x: enemyTrainerCenter.x - enemyTrainerSize.width * 0.24,
            y: enemyTrainerCenter.y + 4
        )
    }

    var playerTrainerPokeballOrigin: CGPoint {
        CGPoint(
            x: playerTrainerCenter.x + playerTrainerSize.width * 0.18,
            y: playerTrainerCenter.y - 2
        )
    }

    var enemySendOutAnchor: CGPoint {
        enemySpriteCenter
    }

    var playerSendOutAnchor: CGPoint {
        playerSpriteCenter
    }

    var enemyTrainerPokemonOrigin: CGPoint {
        CGPoint(
            x: enemyTrainerCenter.x - enemyTrainerSize.width * 0.3,
            y: enemyTrainerCenter.y - enemyTrainerSize.height * 0.04
        )
    }

    var playerTrainerPokemonOrigin: CGPoint {
        CGPoint(
            x: playerTrainerCenter.x + playerTrainerSize.width * 0.22,
            y: playerTrainerCenter.y - playerTrainerSize.height * 0.16
        )
    }
}
