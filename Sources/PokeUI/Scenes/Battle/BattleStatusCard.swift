import SwiftUI
import PokeDataModel

struct BattleStatusCard: View {
    let pokemon: PartyPokemonTelemetry
    let chrome: Chrome
    let showsCaughtIndicator: Bool
    let showsExperience: Bool
    let presentation: BattlePresentationTelemetry
    let nameScale: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let horizontalPadding = max(12, size.width * 0.055)
            let topPadding = max(6, size.height * 0.06)
            let bottomPadding = max(8, size.height * 0.085)
            let topInset = max(2, size.height * 0.045)
            let cardShape = RoundedRectangle(cornerRadius: 12, style: .continuous)

            VStack(alignment: .leading, spacing: max(7, size.height * 0.065)) {
                Color.clear
                    .frame(height: topInset)

                HStack(alignment: .center, spacing: Self.nameRowSpacing) {
                    HStack(alignment: .center, spacing: Self.caughtIndicatorSpacing) {
                        if showsCaughtIndicatorVisible {
                            BattlePokeballToken()
                                .frame(
                                    width: Self.caughtIndicatorDiameter(scale: Self.metadataScale),
                                    height: Self.caughtIndicatorDiameter(scale: Self.metadataScale)
                                )
                                .accessibilityHidden(true)
                        }

                        CombatPixelText(
                            pokemon.displayName.uppercased(),
                            color: FieldRetroPalette.ink,
                            primaryScale: nameScale,
                            minimumScale: nameScale,
                            fallbackFont: .system(size: max(14, size.height * 0.28), weight: .bold, design: .monospaced)
                        )
                    }
                    .layoutPriority(1)

                    CombatPixelText(
                        "LV\(pokemon.level)",
                        color: FieldRetroPalette.ink.opacity(0.74),
                        primaryScale: Self.metadataScale,
                        alignment: .trailing,
                        fallbackFont: .system(size: max(12, size.height * 0.2), weight: .bold, design: .monospaced)
                    )
                    .frame(width: Self.levelLabelWidth(scale: Self.metadataScale), alignment: .trailing)
                }

                HStack(alignment: .center, spacing: 10) {
                    CombatPixelText(
                        "HP",
                        color: FieldRetroPalette.ink.opacity(0.74),
                        primaryScale: Self.metadataScale,
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
                            primaryScale: Self.metadataScale,
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

    private var showsCaughtIndicatorVisible: Bool {
        showsCaughtIndicator
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
    static let metadataScale: CGFloat = 0.9
    static let preferredNameScale: CGFloat = 0.9
    static let minimumNameScale: CGFloat = 0.55
    static let glyphTileWidth: CGFloat = 8
    static let maxBattleNameCharacters = 10
    static let levelLabelCharacterCount = 5
    static let nameRowSpacing: CGFloat = 8
    static let caughtIndicatorSpacing: CGFloat = 3

    static func sharedNameScale(
        enemyCardWidth: CGFloat,
        playerCardWidth: CGFloat,
        enemyShowsCaughtIndicator: Bool = false
    ) -> CGFloat {
        let enemyAvailableWidth = availableNameWidth(
            cardWidth: enemyCardWidth,
            showsCaughtIndicator: enemyShowsCaughtIndicator
        )
        let playerAvailableWidth = availableNameWidth(cardWidth: playerCardWidth)
        let availableWidth = min(enemyAvailableWidth, playerAvailableWidth)
        let scale = availableWidth / (CGFloat(maxBattleNameCharacters) * glyphTileWidth)
        return min(preferredNameScale, max(minimumNameScale, scale))
    }

    static func availableNameWidth(cardWidth: CGFloat, showsCaughtIndicator: Bool = false) -> CGFloat {
        let horizontalPadding = max(12, cardWidth * 0.055)
        let contentWidth = max(0, cardWidth - (horizontalPadding * 2))
        let accessoryWidth = showsCaughtIndicator ? caughtIndicatorReservedWidth(scale: metadataScale) : 0
        return max(0, contentWidth - levelLabelWidth(scale: metadataScale) - nameRowSpacing - accessoryWidth)
    }

    static func requiredNameWidth(scale: CGFloat) -> CGFloat {
        CGFloat(maxBattleNameCharacters) * glyphTileWidth * scale
    }

    static func levelLabelWidth(scale: CGFloat) -> CGFloat {
        CGFloat(levelLabelCharacterCount) * glyphTileWidth * scale
    }

    static func caughtIndicatorDiameter(scale: CGFloat) -> CGFloat {
        glyphTileWidth * 0.9 * scale
    }

    static func caughtIndicatorReservedWidth(scale: CGFloat) -> CGFloat {
        caughtIndicatorDiameter(scale: scale) + caughtIndicatorSpacing
    }

    static func showsCaughtIndicator(chrome: Chrome, battleKind: BattleKind, isSpeciesOwned: Bool) -> Bool {
        switch chrome {
        case .enemy:
            return battleKind == .wild && isSpeciesOwned
        case .player:
            return false
        }
    }
}

struct BattlePokeballToken: View {
    var body: some View {
        GeometryReader { proxy in
            let centerDiameter = max(2, proxy.size.width * 0.34)
            let bandHeight = max(1, proxy.size.height * 0.14)

            ZStack {
                Circle()
                    .fill(Self.bottomColor)

                Circle()
                    .fill(Self.topColor)
                    .mask(
                        VStack(spacing: 0) {
                            Rectangle()
                            Color.clear
                        }
                    )

                Rectangle()
                    .fill(Self.bandColor)
                    .frame(height: bandHeight)

                Circle()
                    .fill(Self.centerFill)
                    .frame(width: centerDiameter, height: centerDiameter)
            }
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(Self.outlineColor, lineWidth: max(1, proxy.size.width * 0.12))
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

private extension BattlePokeballToken {
    static let topColor = Color(red: 0.86, green: 0.14, blue: 0.18)
    static let bottomColor = Color(red: 0.97, green: 0.97, blue: 0.95)
    static let bandColor = Color.black.opacity(0.86)
    static let centerFill = Color(red: 0.96, green: 0.96, blue: 0.94)
    static let outlineColor = Color.black.opacity(0.9)
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
