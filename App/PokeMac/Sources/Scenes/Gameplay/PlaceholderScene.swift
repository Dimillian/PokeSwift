import SwiftUI
import PokeUI

struct PlaceholderScene: View {
    @Environment(\.pokeAppearanceMode) private var appearanceMode
    @Environment(\.pokeGameBoyShellStyle) private var gameBoyShellStyle
    @Environment(\.colorScheme) private var colorScheme
    let props: PlaceholderSceneProps

    var body: some View {
        GameBoyScreen {
            GameBoyPanel {
                VStack(spacing: 16) {
                    Text(props.title ?? "Placeholder")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(palette.primaryText.color)
                    Text("This route is intentionally reserved for Milestone 3 and beyond.")
                        .foregroundStyle(palette.secondaryText.color)
                    Text("Press Escape or X to return to the title menu.")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(palette.primaryText.color)
                }
                .padding(22)
            }
            .frame(width: 580)
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
