import SwiftUI
import PokeUI

struct PlaceholderScene: View {
    let props: PlaceholderSceneProps
    private let palette = PokeThemePalette.lightPalette

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
}
