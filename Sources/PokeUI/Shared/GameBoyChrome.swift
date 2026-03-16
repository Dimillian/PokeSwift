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
    @Environment(\.pokeAppearanceMode) private var appearanceMode
    @Environment(\.pokeGameBoyShellStyle) private var gameBoyShellStyle
    @Environment(\.colorScheme) private var colorScheme
    private let content: Content
    private let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)

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

    private var palette: PokeThemeResolvedPalette {
        PokeThemePalette.resolve(
            for: appearanceMode,
            shellStyle: gameBoyShellStyle,
            colorScheme: colorScheme
        )
    }
}

public struct PlainWhitePanel<Content: View>: View {
    @Environment(\.pokeAppearanceMode) private var appearanceMode
    @Environment(\.pokeGameBoyShellStyle) private var gameBoyShellStyle
    @Environment(\.colorScheme) private var colorScheme
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(18)
            .background(palette.plainPanelFill.color)
    }

    private var palette: PokeThemeResolvedPalette {
        PokeThemePalette.resolve(
            for: appearanceMode,
            shellStyle: gameBoyShellStyle,
            colorScheme: colorScheme
        )
    }
}

private struct GameBoyScreenBackground: View {
    @Environment(\.pokeAppearanceMode) private var appearanceMode
    @Environment(\.pokeGameBoyShellStyle) private var gameBoyShellStyle
    @Environment(\.colorScheme) private var colorScheme
    let style: GameBoyScreenStyle

    var body: some View {
        switch style {
        case .classic:
            palette.classicBackground.color
        case .fieldShell:
            palette.appBackgroundMiddle.color
        }
    }

    private var palette: PokeThemeResolvedPalette {
        PokeThemePalette.resolve(
            for: appearanceMode,
            shellStyle: gameBoyShellStyle,
            colorScheme: colorScheme
        )
    }
}
