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
                trainerName: trainerName,
                playerPokemon: playerPokemon,
                enemyPokemon: enemyPokemon,
                playerSpriteURL: playerSpriteURL,
                enemySpriteURL: enemySpriteURL
            )
            .frame(width: viewportSize.width, height: viewportSize.height)
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
    let trainerName: String
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

                BattleSpritePlatform(curveHeight: layout.platformCurveHeight)
                    .stroke(FieldRetroPalette.ink.opacity(0.22), lineWidth: layout.platformStrokeWidth)
                    .frame(width: layout.platformWidth, height: layout.platformHeight)
                    .position(x: layout.enemyPlatformCenter.x, y: layout.enemyPlatformCenter.y)

                BattleSpritePlatform(curveHeight: layout.platformCurveHeight)
                    .stroke(FieldRetroPalette.ink.opacity(0.18), lineWidth: layout.platformStrokeWidth)
                    .frame(width: layout.platformWidth, height: layout.platformHeight)
                    .position(x: layout.playerPlatformCenter.x, y: layout.playerPlatformCenter.y)

                BattleStatusCard(
                    title: trainerName,
                    pokemon: enemyPokemon,
                    alignment: .leading
                )
                .frame(width: layout.enemyCardSize.width, height: layout.enemyCardSize.height)
                .position(x: layout.enemyCardCenter.x, y: layout.enemyCardCenter.y)

                BattleStatusCard(
                    title: "RED",
                    pokemon: playerPokemon,
                    alignment: .leading
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
                    Color.white.opacity(0.08),
                    Color.clear,
                    Color.black.opacity(0.1),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

private struct BattleViewportLayout {
    let size: CGSize

    var enemyCardSize: CGSize {
        CGSize(width: size.width * 0.38, height: size.height * 0.18)
    }

    var playerCardSize: CGSize {
        CGSize(width: size.width * 0.41, height: size.height * 0.18)
    }

    var enemyCardCenter: CGPoint {
        CGPoint(x: size.width * 0.26, y: size.height * 0.17)
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
        CGPoint(x: size.width * 0.25, y: size.height * 0.62)
    }

    var platformWidth: CGFloat {
        size.width * 0.34
    }

    var platformHeight: CGFloat {
        size.height * 0.06
    }

    var platformCurveHeight: CGFloat {
        size.height * 0.018
    }

    var platformStrokeWidth: CGFloat {
        max(2, size.height * 0.008)
    }

    var enemyPlatformCenter: CGPoint {
        CGPoint(x: size.width * 0.73, y: size.height * 0.43)
    }

    var playerPlatformCenter: CGPoint {
        CGPoint(x: size.width * 0.33, y: size.height * 0.74)
    }
}

private struct BattleSpritePlatform: Shape {
    let curveHeight: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control: CGPoint(x: rect.midX, y: rect.midY + curveHeight)
        )
        return path
    }
}

private struct BattleStatusCard: View {
    let title: String
    let pokemon: PartyPokemonTelemetry
    let alignment: HorizontalAlignment

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let contentPadding = max(10, size.height * 0.16)
            let nameFont = max(14, size.height * 0.28)
            let metaFont = max(11, size.height * 0.18)
            let hpLabelFont = max(10, size.height * 0.17)
            let hpValueFont = max(12, size.height * 0.2)

            VStack(alignment: alignment, spacing: size.height * 0.08) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(title.uppercased())
                        .font(.system(size: metaFont, weight: .bold, design: .monospaced))
                        .foregroundStyle(FieldRetroPalette.ink.opacity(0.58))

                    Spacer(minLength: 8)

                    Text("Lv\(pokemon.level)")
                        .font(.system(size: hpValueFont, weight: .bold, design: .monospaced))
                        .foregroundStyle(FieldRetroPalette.ink.opacity(0.74))
                }

                Text(pokemon.displayName.uppercased())
                    .font(.system(size: nameFont, weight: .bold, design: .monospaced))
                    .foregroundStyle(FieldRetroPalette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(alignment: .center, spacing: 10) {
                    Text("HP")
                        .font(.system(size: hpLabelFont, weight: .bold, design: .monospaced))
                        .foregroundStyle(FieldRetroPalette.ink.opacity(0.74))

                    BattleHPBar(currentHP: pokemon.currentHP, maxHP: pokemon.maxHP)
                        .frame(maxWidth: .infinity)
                        .frame(height: max(10, size.height * 0.14))
                }
            }
            .padding(contentPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(FieldRetroPalette.cardFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(FieldRetroPalette.outline.opacity(0.16), lineWidth: 1)
                    .overlay {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .stroke(.white.opacity(0.22), lineWidth: 1)
                            .padding(3)
                    }
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(FieldRetroPalette.outline.opacity(0.06), lineWidth: 1)
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
