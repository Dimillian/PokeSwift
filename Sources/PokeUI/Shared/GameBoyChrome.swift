import SwiftUI

public enum GameBoyScreenStyle: Sendable {
    case classic
    case fieldShell
}

public struct GameBoyScreen<Content: View>: View {
    private let style: GameBoyScreenStyle
    private let content: Content

    public init(style: GameBoyScreenStyle = .classic, @ViewBuilder content: () -> Content) {
        self.style = style
        self.content = content()
    }

    public var body: some View {
        ZStack {
            GameBoyScreenBackground(style: style)
            content
        }
    }
}

public struct GameBoyPanel<Content: View>: View {
    private let content: Content
    private let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
    private let palette = PokeThemePalette.lightPalette

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(18)
            .background(palette.panelBackground.color, in: shape)
            .overlay {
                shape
                    .stroke(palette.panelOutline.color, lineWidth: 1)
            }
            .glassEffect(
                .regular.tint(palette.panelGlassTint.color),
                in: shape
            )
            .shadow(color: palette.dialogueShadow.color, radius: 20, y: 10)
    }
}

public struct PlainWhitePanel<Content: View>: View {
    private let content: Content
    private let palette = PokeThemePalette.lightPalette

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(18)
            .background(palette.plainPanelFill.color)
    }
}

private struct GameBoyScreenBackground: View {
    let style: GameBoyScreenStyle
    private let palette = PokeThemePalette.lightPalette

    var body: some View {
        switch style {
        case .classic:
            palette.classicBackground.color
        case .fieldShell:
            ZStack {
                LinearGradient(
                    colors: [
                        PokeThemePalette.appBackgroundTop,
                        PokeThemePalette.appBackgroundMiddle,
                        PokeThemePalette.appBackgroundBottom,
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                RadialGradient(
                    colors: [
                        PokeThemePalette.appHighlightGlow,
                        Color.clear,
                    ],
                    center: .topLeading,
                    startRadius: 20,
                    endRadius: 420
                )

                RadialGradient(
                    colors: [
                        PokeThemePalette.appAccentGlow,
                        Color.clear,
                    ],
                    center: .bottomTrailing,
                    startRadius: 40,
                    endRadius: 360
                )

                LinearGradient(
                    colors: [
                        PokeThemePalette.appHighlightGlow.opacity(0.45),
                        Color.clear,
                        PokeThemePalette.appDepthShadow,
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
}
