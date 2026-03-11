import SwiftUI

enum GameplayFieldMetrics {
    static let sidebarWidth: CGFloat = 320
    static let outerPadding: CGFloat = 24
    static let interColumnSpacing: CGFloat = 20
    static let sidebarSectionSpacing: CGFloat = 12
    static let hoverCardSpacing: CGFloat = 22
    static let inventoryExpandedMaxHeight: CGFloat = 210
    static let glassMergeSpacing: CGFloat = 16
}

enum FieldRetroPalette {
    static let ink = Color(red: 0.16, green: 0.18, blue: 0.12)
    static let outline = Color.black
    static let cardFill = Color(red: 0.88, green: 0.9, blue: 0.78)
    static let slotFill = Color(red: 0.8, green: 0.84, blue: 0.69)
    static let leadSlotFill = Color(red: 0.74, green: 0.8, blue: 0.63)
    static let track = Color(red: 0.55, green: 0.62, blue: 0.49)
    static let portraitFill = Color(red: 0.76, green: 0.82, blue: 0.68)
    static let stageOuter = Color(red: 0.68, green: 0.74, blue: 0.58)
    static let stageMiddle = Color(red: 0.79, green: 0.84, blue: 0.68)
    static let stageInner = Color(red: 0.92, green: 0.92, blue: 0.84)
    static let glassTint = Color(red: 0.82, green: 0.9, blue: 0.77).opacity(0.42)
    static let accentGlassTint = Color(red: 0.73, green: 0.84, blue: 0.74).opacity(0.48)
    static let interactiveGlassTint = Color(red: 0.91, green: 0.94, blue: 0.86).opacity(0.4)
    static let hoverCardGlassTint = Color(red: 0.79, green: 0.88, blue: 0.79).opacity(0.34)
    static let hoverCardBackgroundTint = Color(red: 0.84, green: 0.9, blue: 0.8).opacity(0.16)
    static let shellBackdrop = Color(red: 0.94, green: 0.94, blue: 0.89)
    static let shellBackdropShadow = Color(red: 0.33, green: 0.39, blue: 0.26)

    static func pokemonTypeGlassTint(for typeLabel: String) -> Color {
        switch typeLabel.uppercased() {
        case "NORMAL":
            return Color(red: 0.8, green: 0.78, blue: 0.7).opacity(0.4)
        case "FIRE":
            return Color(red: 0.95, green: 0.53, blue: 0.42).opacity(0.5)
        case "WATER":
            return Color(red: 0.48, green: 0.67, blue: 0.96).opacity(0.48)
        case "ELECTRIC":
            return Color(red: 0.97, green: 0.82, blue: 0.34).opacity(0.48)
        case "GRASS":
            return Color(red: 0.51, green: 0.82, blue: 0.45).opacity(0.48)
        case "ICE":
            return Color(red: 0.65, green: 0.89, blue: 0.93).opacity(0.42)
        case "FIGHTING":
            return Color(red: 0.84, green: 0.45, blue: 0.4).opacity(0.46)
        case "POISON":
            return Color(red: 0.72, green: 0.57, blue: 0.88).opacity(0.46)
        case "GROUND":
            return Color(red: 0.81, green: 0.65, blue: 0.4).opacity(0.44)
        case "FLYING":
            return Color(red: 0.68, green: 0.76, blue: 0.96).opacity(0.42)
        case "PSYCHIC":
            return Color(red: 0.95, green: 0.58, blue: 0.74).opacity(0.48)
        case "BUG":
            return Color(red: 0.7, green: 0.82, blue: 0.32).opacity(0.46)
        case "ROCK":
            return Color(red: 0.74, green: 0.64, blue: 0.44).opacity(0.42)
        case "GHOST":
            return Color(red: 0.58, green: 0.55, blue: 0.82).opacity(0.48)
        case "DRAGON":
            return Color(red: 0.53, green: 0.6, blue: 0.96).opacity(0.5)
        default:
            return FieldRetroPalette.interactiveGlassTint
        }
    }

    static func pokemonTypeBadgeBackground(for typeLabel: String) -> Color {
        pokemonTypeGlassTint(for: typeLabel).opacity(0.45)
    }
}

private enum GameplayFieldShapes {
    static let card = RoundedRectangle(cornerRadius: 24, style: .continuous)
    static let cardInner = RoundedRectangle(cornerRadius: 19, style: .continuous)
    static let inset = RoundedRectangle(cornerRadius: 16, style: .continuous)
    static let insetInner = RoundedRectangle(cornerRadius: 12, style: .continuous)
    static let tile = RoundedRectangle(cornerRadius: 14, style: .continuous)
}

struct GameplaySidebarCardSurface<Content: View>: View {
    private let padding: CGFloat
    private let tint: Color
    private let backgroundColor: Color
    private let showsOutline: Bool
    private let content: Content

    init(
        padding: CGFloat = 18,
        tint: Color = FieldRetroPalette.glassTint,
        backgroundColor: Color = .clear,
        showsOutline: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.tint = tint
        self.backgroundColor = backgroundColor
        self.showsOutline = showsOutline
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundStyle, in: GameplayFieldShapes.card)
            .overlay {
                if showsOutline {
                    GameplayFieldShapes.card
                        .stroke(FieldRetroPalette.outline.opacity(0.12), lineWidth: 1)
                        .overlay {
                            GameplayFieldShapes.cardInner
                                .stroke(.white.opacity(0.28), lineWidth: 1)
                                .padding(5)
                        }
                }
            }
            .glassEffect(
                .regular.tint(tint),
                in: GameplayFieldShapes.card
            )
            .shadow(color: FieldRetroPalette.shellBackdropShadow.opacity(0.12), radius: 18, y: 10)
    }

    private var backgroundStyle: AnyShapeStyle {
        if backgroundColor != .clear {
            return AnyShapeStyle(
                backgroundColor
            )
        }

        return AnyShapeStyle(
            LinearGradient(
                colors: [
                    FieldRetroPalette.cardFill.opacity(0.82),
                    FieldRetroPalette.slotFill.opacity(0.72),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

struct GameplaySidebarInsetSurface<Content: View>: View {
    private let padding: EdgeInsets
    private let tint: Color
    private let content: Content

    init(
        padding: EdgeInsets = EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12),
        tint: Color = FieldRetroPalette.interactiveGlassTint,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [
                        FieldRetroPalette.slotFill.opacity(0.88),
                        FieldRetroPalette.cardFill.opacity(0.58),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: GameplayFieldShapes.inset
            )
            .overlay {
                GameplayFieldShapes.inset
                    .stroke(FieldRetroPalette.outline.opacity(0.08), lineWidth: 1)
                    .overlay {
                        GameplayFieldShapes.insetInner
                            .stroke(.white.opacity(0.18), lineWidth: 0.75)
                            .padding(4)
                    }
            }
            .glassEffect(
                .regular.tint(tint),
                in: GameplayFieldShapes.inset
            )
    }
}

struct GameplaySidebarChipSurface<Content: View>: View {
    private let backgroundColor: Color
    private let tint: Color
    private let content: Content

    init(
        backgroundColor: Color = FieldRetroPalette.slotFill.opacity(0.78),
        tint: Color = FieldRetroPalette.interactiveGlassTint,
        @ViewBuilder content: () -> Content
    ) {
        self.backgroundColor = backgroundColor
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(backgroundColor, in: Capsule(style: .continuous))
            .overlay {
                Capsule(style: .continuous)
                    .stroke(FieldRetroPalette.outline.opacity(0.08), lineWidth: 1)
            }
            .glassEffect(
                .regular.tint(tint),
                in: Capsule(style: .continuous)
            )
    }
}
