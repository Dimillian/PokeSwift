import SwiftUI
import PokeDataModel

struct BattleStatusCard: View {
    let pokemon: PartyPokemonTelemetry
    let chrome: Chrome
    let showsExperience: Bool
    let presentation: BattlePresentationTelemetry

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let horizontalPadding = max(12, size.width * 0.055)
            let topPadding = max(6, size.height * 0.06)
            let bottomPadding = max(8, size.height * 0.085)
            let topInset = max(2, size.height * 0.045)
            let pixelNameScale: CGFloat = 0.9
            let pixelMetaScale: CGFloat = 0.9
            let cardShape = RoundedRectangle(cornerRadius: 12, style: .continuous)

            VStack(alignment: .leading, spacing: max(7, size.height * 0.065)) {
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

                    BattleHPBar(
                        currentHP: pokemon.currentHP,
                        maxHP: pokemon.maxHP,
                        meterAnimation: hpMeterAnimation,
                        animationRevision: presentation.revision
                    )
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

                        BattleExperienceBar(
                            experience: pokemon.experience,
                            meterAnimation: experienceMeterAnimation,
                            animationRevision: presentation.revision
                        )
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
                    .fill(chrome.panelBaseTint)
                    .padding(1)
                    .blendMode(.overlay)
                    .opacity(0.9)
            }
            .overlay {
                cardShape
                    .stroke(chrome.borderTint, lineWidth: 1.2)
            }
            .glassEffect(.regular.tint(chrome.tint), in: cardShape)
            .shadow(color: chrome.shadowTint, radius: 20, y: 10)
        }
    }

    private var hpMeterAnimation: BattleMeterAnimationTelemetry? {
        guard let meterAnimation = presentation.meterAnimation,
              meterAnimation.kind == .hp,
              meterAnimation.side == chrome.side else {
            return nil
        }
        return meterAnimation
    }

    private var experienceMeterAnimation: BattleMeterAnimationTelemetry? {
        guard let meterAnimation = presentation.meterAnimation,
              meterAnimation.kind == .experience,
              meterAnimation.side == chrome.side else {
            return nil
        }
        return meterAnimation
    }
}

extension BattleStatusCard {
    enum Chrome {
        case enemy
        case player

        var tint: Color {
            switch self {
            case .enemy:
                return PokeThemePalette.battleEnemyTint.opacity(0.94)
            case .player:
                return PokeThemePalette.battlePlayerTint.opacity(0.94)
            }
        }

        var backgroundTint: Color {
            switch self {
            case .enemy:
                return PokeThemePalette.battleEnemyBackground.opacity(0.92)
            case .player:
                return PokeThemePalette.battlePlayerBackground.opacity(0.94)
            }
        }

        var panelBaseTint: Color {
            switch self {
            case .enemy:
                return Color.white.opacity(0.12)
            case .player:
                return Color.white.opacity(0.15)
            }
        }

        var borderTint: Color {
            switch self {
            case .enemy:
                return Color.white.opacity(0.22)
            case .player:
                return Color.white.opacity(0.26)
            }
        }

        var shadowTint: Color {
            switch self {
            case .enemy:
                return PokeThemePalette.dialogueShadow.opacity(0.55)
            case .player:
                return PokeThemePalette.dialogueShadow.opacity(0.62)
            }
        }

        var side: BattlePresentationSide {
            switch self {
            case .enemy:
                return .enemy
            case .player:
                return .player
            }
        }
    }
}
