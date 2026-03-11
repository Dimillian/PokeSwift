import SwiftUI
import PokeDataModel

public struct BattlePanel: View {
    let trainerName: String
    let playerPokemon: PartyPokemonTelemetry
    let enemyPokemon: PartyPokemonTelemetry
    let playerSpriteURL: URL?
    let enemySpriteURL: URL?
    let displayStyle: FieldDisplayStyle

    public init(
        trainerName: String,
        playerPokemon: PartyPokemonTelemetry,
        enemyPokemon: PartyPokemonTelemetry,
        playerSpriteURL: URL?,
        enemySpriteURL: URL?,
        displayStyle: FieldDisplayStyle
    ) {
        self.trainerName = trainerName
        self.playerPokemon = playerPokemon
        self.enemyPokemon = enemyPokemon
        self.playerSpriteURL = playerSpriteURL
        self.enemySpriteURL = enemySpriteURL
        self.displayStyle = displayStyle
    }

    public var body: some View {
        GeometryReader { proxy in
            let scale = viewportScale(for: proxy.size)
            let viewportSize = CGSize(
                width: CGFloat(FieldSceneRenderer.viewportPixelSize.width) * scale,
                height: CGFloat(FieldSceneRenderer.viewportPixelSize.height) * scale
            )

            BattleViewportCanvas(
                playerPokemon: playerPokemon,
                enemyPokemon: enemyPokemon,
                playerSpriteURL: playerSpriteURL,
                enemySpriteURL: enemySpriteURL
            )
            .frame(width: viewportSize.width, height: viewportSize.height)
            .battleScreenEffect(displayScale: scale)
            .clipShape(RoundedRectangle(cornerRadius: max(6, scale * 2.5), style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: max(6, scale * 2.5), style: .continuous)
                    .stroke(Color.black.opacity(0.16), lineWidth: max(1, scale * 0.16))
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
}

private struct BattleViewportCanvas: View {
    let playerPokemon: PartyPokemonTelemetry
    let enemyPokemon: PartyPokemonTelemetry
    let playerSpriteURL: URL?
    let enemySpriteURL: URL?

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let layout = BattleViewportLayout(size: size)

            ZStack(alignment: .topLeading) {
                battleBackground

                BattleStatusCard(
                    pokemon: enemyPokemon,
                    chrome: .enemy,
                    alignment: .leading,
                    showsExperience: false
                )
                .frame(width: layout.enemyCardSize.width, height: layout.enemyCardSize.height)
                .position(x: layout.enemyCardCenter.x, y: layout.enemyCardCenter.y)

                BattleStatusCard(
                    pokemon: playerPokemon,
                    chrome: .player,
                    alignment: .leading,
                    showsExperience: true
                )
                .frame(width: layout.playerCardSize.width, height: layout.playerCardSize.height)
                .position(x: layout.playerCardCenter.x, y: layout.playerCardCenter.y)

                if let enemySpriteURL {
                    PixelAssetView(
                        url: enemySpriteURL,
                        label: enemyPokemon.displayName,
                        whiteIsTransparent: true
                    )
                        .frame(width: layout.enemySpriteSize.width, height: layout.enemySpriteSize.height)
                        .position(x: layout.enemySpriteCenter.x, y: layout.enemySpriteCenter.y)
                }

                if let playerSpriteURL {
                    PixelAssetView(
                        url: playerSpriteURL,
                        label: playerPokemon.displayName,
                        whiteIsTransparent: true
                    )
                        .frame(width: layout.playerSpriteSize.width, height: layout.playerSpriteSize.height)
                        .position(x: layout.playerSpriteCenter.x, y: layout.playerSpriteCenter.y)
                }
            }
        }
    }

    private var battleBackground: some View {
        ZStack {
            Rectangle()
                .fill(Color(red: 0.49, green: 0.56, blue: 0.17))

            LinearGradient(
                colors: [
                    Color.white.opacity(0.03),
                    Color.clear,
                    Color.black.opacity(0.04),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

private struct BattleViewportLayout {
    let size: CGSize

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

    var enemySpriteSize: CGSize {
        CGSize(width: size.width * 0.3, height: size.height * 0.3)
    }

    var playerSpriteSize: CGSize {
        CGSize(width: size.width * 0.28, height: size.height * 0.28)
    }

    var enemySpriteCenter: CGPoint {
        CGPoint(x: size.width * 0.72, y: size.height * 0.3)
    }

    var playerSpriteCenter: CGPoint {
        CGPoint(x: size.width * 0.25, y: size.height * 0.69)
    }
}

private struct BattleStatusCard: View {
    enum Chrome {
        case enemy
        case player

        var tint: Color {
            switch self {
            case .enemy:
                return Color(red: 0.92, green: 0.96, blue: 0.84).opacity(0.42)
            case .player:
                return Color(red: 0.78, green: 0.9, blue: 0.76).opacity(0.46)
            }
        }

        var backgroundTint: Color {
            switch self {
            case .enemy:
                return Color.white.opacity(0.18)
            case .player:
                return Color(red: 0.86, green: 0.93, blue: 0.8).opacity(0.22)
            }
        }
    }

    let pokemon: PartyPokemonTelemetry
    let chrome: Chrome
    let alignment: HorizontalAlignment
    let showsExperience: Bool

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let horizontalPadding = max(8, size.width * 0.035)
            let topPadding = max(4, size.height * 0.05)
            let bottomPadding = max(4, size.height * 0.05)
            let topInset = max(5, size.height * 0.12)
            let pixelNameScale: CGFloat = 0.9
            let pixelMetaScale: CGFloat = 0.9
            let cardShape = RoundedRectangle(cornerRadius: 16, style: .continuous)

            VStack(alignment: alignment, spacing: max(4, size.height * 0.045)) {
                Color.clear
                    .frame(height: topInset)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    CombatPixelText(
                        pokemon.displayName.uppercased(),
                        color: FieldRetroPalette.ink,
                        primaryScale: pixelNameScale,
                        minimumScale: pixelNameScale,
                        fallbackFont: .system(size: max(14, size.height * 0.28), weight: .bold, design: .monospaced)
                    )

                    Spacer(minLength: 8)

                    CombatPixelText(
                        "LV\(pokemon.level)",
                        color: FieldRetroPalette.ink.opacity(0.74),
                        primaryScale: pixelMetaScale,
                        alignment: .trailing,
                        fallbackFont: .system(size: max(12, size.height * 0.2), weight: .bold, design: .monospaced)
                    )
                }

                HStack(alignment: .center, spacing: 10) {
                    CombatPixelText(
                        "HP",
                        color: FieldRetroPalette.ink.opacity(0.74),
                        primaryScale: pixelMetaScale,
                        fallbackFont: .system(size: max(10, size.height * 0.17), weight: .bold, design: .monospaced)
                    )

                    BattleHPBar(currentHP: pokemon.currentHP, maxHP: pokemon.maxHP)
                        .frame(maxWidth: .infinity)
                        .frame(height: max(10, size.height * 0.14))
                }

                if showsExperience {
                    HStack(alignment: .center, spacing: 10) {
                        CombatPixelText(
                            "EXP",
                            color: FieldRetroPalette.ink.opacity(0.74),
                            primaryScale: pixelMetaScale,
                            fallbackFont: .system(size: max(10, size.height * 0.17), weight: .bold, design: .monospaced)
                        )

                        BattleExperienceBar(experience: pokemon.experience)
                            .frame(maxWidth: .infinity)
                        .frame(height: max(8, size.height * 0.11))
                    }
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.top, topPadding)
            .padding(.bottom, bottomPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(chrome.backgroundTint, in: cardShape)
            .overlay {
                cardShape
                    .stroke(.white.opacity(0.2), lineWidth: 1)
                    .padding(3)
            }
            .glassEffect(.regular.tint(chrome.tint), in: cardShape)
            .shadow(color: .black.opacity(0.08), radius: 16, y: 8)
        }
    }
}

private struct BattleExperienceBar: View {
    let experience: ExperienceProgressTelemetry

    private var fraction: CGFloat {
        let range = max(0, experience.nextLevel - experience.levelStart)
        guard range > 0 else { return 1 }
        let progress = min(range, max(0, experience.total - experience.levelStart))
        return CGFloat(progress) / CGFloat(range)
    }

    var body: some View {
        GeometryReader { proxy in
            let width = max(0, proxy.size.width * fraction)

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(FieldRetroPalette.track)

                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color(red: 0.28, green: 0.46, blue: 0.62))
                    .frame(width: width)
            }
        }
    }
}

private struct BattleHPBar: View {
    let currentHP: Int
    let maxHP: Int

    private var hpFraction: CGFloat {
        CGFloat(currentHP) / CGFloat(max(1, maxHP))
    }

    private var barColor: Color {
        switch hpFraction {
        case ..<0.25:
            return Color(red: 0.63, green: 0.27, blue: 0.24)
        case ..<0.5:
            return Color(red: 0.72, green: 0.55, blue: 0.21)
        default:
            return Color(red: 0.2, green: 0.32, blue: 0.14)
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let width = max(0, proxy.size.width * hpFraction)

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(FieldRetroPalette.track)

                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(barColor)
                    .frame(width: width)
            }
        }
    }
}
