import SwiftUI
import PokeDataModel
import PokeRender

public struct BattlePanel: View {
    @Environment(\.pokeAppearanceMode) private var appearanceMode
    @Environment(\.pokeGameplayHDREnabled) private var gameplayHDREnabled
    @Environment(\.colorScheme) private var colorScheme

    let trainerName: String
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
    let presentation: BattlePresentationTelemetry

    public init(
        trainerName: String,
        kind: BattleKind,
        playerPokemon: PartyPokemonTelemetry,
        enemyPokemon: PartyPokemonTelemetry,
        enemyPartyCount: Int = 1,
        isEnemySpeciesOwned: Bool,
        trainerSpriteURL: URL?,
        playerTrainerFrontSpriteURL: URL?,
        playerTrainerBackSpriteURL: URL?,
        sendOutPoofSpriteURL: URL?,
        battleAnimationManifest: BattleAnimationManifest,
        battleAnimationTilesetURLs: [String: URL],
        playerSpriteURL: URL?,
        enemySpriteURL: URL?,
        displayStyle: FieldDisplayStyle,
        presentation: BattlePresentationTelemetry
    ) {
        self.trainerName = trainerName
        self.kind = kind
        self.playerPokemon = playerPokemon
        self.enemyPokemon = enemyPokemon
        self.enemyPartyCount = enemyPartyCount
        self.isEnemySpeciesOwned = isEnemySpeciesOwned
        self.trainerSpriteURL = trainerSpriteURL
        self.playerTrainerFrontSpriteURL = playerTrainerFrontSpriteURL
        self.playerTrainerBackSpriteURL = playerTrainerBackSpriteURL
        self.sendOutPoofSpriteURL = sendOutPoofSpriteURL
        self.battleAnimationManifest = battleAnimationManifest
        self.battleAnimationTilesetURLs = battleAnimationTilesetURLs
        self.playerSpriteURL = playerSpriteURL
        self.enemySpriteURL = enemySpriteURL
        self.displayStyle = displayStyle
        self.presentation = presentation
    }

    public var body: some View {
        GeometryReader { proxy in
            let scale = viewportScale(for: proxy.size)
            let viewportSize = CGSize(
                width: CGFloat(FieldSceneRenderer.viewportPixelSize.width) * scale,
                height: CGFloat(FieldSceneRenderer.viewportPixelSize.height) * scale
            )

            BattleViewportCanvas(
                kind: kind,
                playerPokemon: playerPokemon,
                enemyPokemon: enemyPokemon,
                enemyPartyCount: enemyPartyCount,
                isEnemySpeciesOwned: isEnemySpeciesOwned,
                trainerSpriteURL: trainerSpriteURL,
                playerTrainerFrontSpriteURL: playerTrainerFrontSpriteURL,
                playerTrainerBackSpriteURL: playerTrainerBackSpriteURL,
                sendOutPoofSpriteURL: sendOutPoofSpriteURL,
                battleAnimationManifest: battleAnimationManifest,
                battleAnimationTilesetURLs: battleAnimationTilesetURLs,
                playerSpriteURL: playerSpriteURL,
                enemySpriteURL: enemySpriteURL,
                displayStyle: displayStyle,
                hdrBoost: battleShaderHDRBoost,
                presentation: presentation
            )
            .frame(width: viewportSize.width, height: viewportSize.height)
            .overlay {
                BattleIntroFlashOverlay(presentation: presentation)
            }
            .clipShape(RoundedRectangle(cornerRadius: max(6, scale * 2.5), style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: max(6, scale * 2.5), style: .continuous)
                    .stroke(FieldRetroPalette.outline.opacity(0.16), lineWidth: max(1, scale * 0.16))
            }
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
    }

    private func viewportScale(for size: CGSize) -> CGFloat {
        let rawScale = min(
            size.width / CGFloat(FieldSceneRenderer.viewportPixelSize.width),
            size.height / CGFloat(FieldSceneRenderer.viewportPixelSize.height)
        )
        guard rawScale.isFinite, rawScale > 0 else {
            return 1
        }
        if rawScale >= 1 {
            return max(1, floor(rawScale))
        }
        return rawScale
    }

    private var battleShaderHDRBoost: Float {
        Float(
            PokeThemePalette.gameplayHDRProfile(
                appearanceMode: appearanceMode,
                colorScheme: colorScheme,
                isEnabled: gameplayHDREnabled
            )
            .battleShaderBoost
        )
    }
}

private extension BattlePresentationStage {
    var isFlashStage: Bool {
        switch self {
        case .introFlash1, .introFlash2, .introFlash3:
            return true
        default:
            return false
        }
    }
}

private struct BattleIntroFlashOverlay: View {
    let presentation: BattlePresentationTelemetry

    @State private var opacity: Double = 0
    @State private var seededRevision: Int?

    var body: some View {
        Rectangle()
            .fill(.black)
            .opacity(opacity)
            .allowsHitTesting(false)
            .onAppear {
                syncFlashState()
            }
            .onChange(of: presentation.stage) { _, _ in
                syncFlashState()
            }
            .onChange(of: presentation.revision) { _, _ in
                syncFlashState()
            }
    }

    private func syncFlashState() {
        guard presentation.stage.isFlashStage else {
            opacity = 0
            seededRevision = nil
            return
        }
        guard seededRevision != presentation.revision else { return }

        seededRevision = presentation.revision
        opacity = 1
        withAnimation(.linear(duration: 0.10)) {
            opacity = 0
        }
    }
}
