import CoreGraphics
import SwiftUI
import PokeDataModel
import PokeRender

struct BattleViewportCanvas: View {
    let kind: BattleKind
    let playerPokemon: PartyPokemonTelemetry
    let enemyPokemon: PartyPokemonTelemetry
    let enemyParty: [PartyPokemonTelemetry]
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
    let playerBattlePalette: FieldPaletteManifest?
    let enemyBattlePalette: FieldPaletteManifest?
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
            let rules = makeRules()

            ZStack(alignment: .topLeading) {
                battlefieldLayer(layout: layout, size: size, displayScale: displayScale, rules: rules)
                hudLayer(layout: layout, rules: rules)
            }
            .battleTransitionEffect(
                displayStyle: displayStyle,
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
        displayScale: CGFloat,
        rules: BattleViewportPresentationRules
    ) -> some View {
        let currentSendOutState = rules.currentSendOutState
        let currentAttackAnimationState = rules.currentAttackAnimationState
        let sendOutPoofFrame = rules.sendOutPoofFrame
        let sendOutPoofOpacity = rules.sendOutPoofOpacity

        ZStack(alignment: .topLeading) {
            battleBackground

            if let trainerSpriteURL, rules.shouldShowEnemyTrainer {
                PixelAssetView(
                    url: trainerSpriteURL,
                    label: "Trainer",
                    whiteIsTransparent: true
                )
                .frame(width: layout.enemyTrainerSize.width, height: layout.enemyTrainerSize.height)
                .position(rules.enemyTrainerCenter(in: layout))
                .scaleEffect(rules.trainerScale)
                .opacity(rules.trainerOpacity)
                .animation(spriteAnimation, value: presentation.revision)
            }

            if let playerTrainerSpriteURL, rules.shouldShowPlayerTrainer {
                PixelAssetView(
                    url: playerTrainerSpriteURL,
                    label: "Player Trainer",
                    whiteIsTransparent: true
                )
                .frame(width: layout.playerTrainerSize.width, height: layout.playerTrainerSize.height)
                .position(rules.playerTrainerCenter(in: layout))
                .scaleEffect(rules.trainerScale)
                .opacity(rules.trainerOpacity)
                .animation(spriteAnimation, value: presentation.revision)
            }

            if let enemySpriteURL, rules.shouldShowEnemyPokemon {
                PixelAssetView(
                    url: enemySpriteURL,
                    label: enemyPokemon.displayName,
                    whiteIsTransparent: true,
                    renderMode: .battlePokemonFront
                )
                .frame(width: layout.enemySpriteSize.width, height: layout.enemySpriteSize.height)
                .compatibilityPaletteEffect(
                    displayStyle == .gbcCompatibility ? enemyBattlePalette : nil
                )
                .scaleEffect(rules.enemySpriteScale, anchor: .center)
                .rotationEffect(enemyPokemonRotation)
                .opacity(rules.enemyPokemonOpacity)
                .position(rules.enemySpriteCenter(in: layout))
                .animation(
                    BattleViewportPresentationRules.usesImplicitPokemonRevisionAnimation(
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
                .position(rules.sendOutPoofCenter(in: layout))
                .opacity(sendOutPoofOpacity)
            }

            if let playerSpriteURL, rules.shouldShowPlayerPokemon {
                PixelAssetView(
                    url: playerSpriteURL,
                    label: playerPokemon.displayName,
                    whiteIsTransparent: true,
                    renderMode: .battlePokemonBack
                )
                .frame(width: layout.playerSpriteSize.width, height: layout.playerSpriteSize.height)
                .compatibilityPaletteEffect(
                    displayStyle == .gbcCompatibility ? playerBattlePalette : nil
                )
                .scaleEffect(rules.playerSpriteScale, anchor: .center)
                .rotationEffect(playerPokemonRotation)
                .opacity(rules.playerPokemonOpacity)
                .position(rules.playerSpriteCenter(in: layout))
                .animation(
                    BattleViewportPresentationRules.usesImplicitPokemonRevisionAnimation(
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

            if rules.shouldShowPokeball {
                BattlePokeballToken()
                    .frame(width: max(8, size.width * 0.05), height: max(8, size.width * 0.05))
                    .position(rules.pokeballCenter(in: layout))
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
            x: rules.combinedScreenShake.width * displayScale,
            y: rules.combinedScreenShake.height * displayScale
        )
        .gameplayScreenEffect(
            displayStyle: displayStyle,
            displayScale: displayScale,
            battlePresentation: presentation,
            hdrBoost: hdrBoost
        )
    }

    @ViewBuilder
    private func hudLayer(
        layout: BattleViewportLayout,
        rules: BattleViewportPresentationRules
    ) -> some View {
        let sharedNameScale = BattleStatusCard.sharedNameScale(
            enemyCardWidth: layout.enemyCardSize.width,
            playerCardWidth: layout.playerCardSize.width,
            enemyShowsCaughtIndicator: shouldShowEnemyCaughtIndicator
        )

        BattleTrainerPartyIndicator(
            slotStates: BattleTrainerPartyIndicator.slotStates(
                enemyParty: enemyParty,
                enemyPartyCount: enemyPartyCount,
                totalCount: 6
            ),
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
        .opacity(rules.trainerPartyIndicatorOpacity)
        .offset(x: rules.trainerPartyIndicatorOffset.width, y: rules.trainerPartyIndicatorOffset.height)
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
        .opacity(rules.enemyHudOpacity)
        .offset(x: rules.enemyHudOffset.width, y: rules.enemyHudOffset.height)
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
        .opacity(rules.playerHudOpacity)
        .offset(y: rules.playerHudOffset)
        .animation(hudAnimation, value: presentation.revision)
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

    private func makeRules() -> BattleViewportPresentationRules {
        BattleViewportPresentationRules(
            battleKind: kind,
            presentation: presentation,
            hasPlayerTrainerSprite: playerTrainerSpriteURL != nil,
            playerCurrentHP: playerPokemon.currentHP,
            enemyCurrentHP: enemyPokemon.currentHP,
            sendOutVisualState: sendOutVisualState,
            activeSendOutAnimationKey: activeSendOutAnimationKey,
            sendOutAnimationTriggerKey: sendOutAnimationTriggerKey,
            attackAnimationVisualState: attackAnimationVisualState,
            activeAttackAnimationKey: activeAttackAnimationKey,
            attackAnimationTriggerKey: attackAnimationTriggerKey,
            applyingHitEffectVisualState: applyingHitEffectVisualState,
            activeApplyingHitEffectKey: activeApplyingHitEffectKey,
            applyingHitEffectTriggerKey: applyingHitEffectTriggerKey
        )
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

    private var enemyPokemonRotation: Angle {
        .degrees(0)
    }

    private var playerPokemonRotation: Angle {
        .degrees(0)
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
            .fill(battleBackgroundColor)
    }

    private var battleBackgroundColor: Color {
        switch displayStyle {
        case .gbcCompatibility:
            return Color(red: 0.85, green: 0.87, blue: 0.9)
        default:
            return Color(red: 0.49, green: 0.56, blue: 0.17)
        }
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
