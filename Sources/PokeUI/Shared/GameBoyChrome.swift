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

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(18)
            .background(Color.white.opacity(0.18), in: shape)
            .overlay {
                shape
                    .stroke(.black.opacity(0.08), lineWidth: 1)
            }
            .glassEffect(
                .regular.tint(Color(red: 0.82, green: 0.91, blue: 0.78).opacity(0.38)),
                in: shape
            )
            .shadow(color: .black.opacity(0.08), radius: 20, y: 10)
    }
}

public struct PlainWhitePanel<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(18)
            .background(.white)
    }
}

private struct GameBoyScreenBackground: View {
    let style: GameBoyScreenStyle

    var body: some View {
        switch style {
        case .classic:
            Color.white
        case .fieldShell:
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.96, blue: 0.9),
                        Color(red: 0.84, green: 0.88, blue: 0.76),
                        Color(red: 0.73, green: 0.79, blue: 0.64),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                RadialGradient(
                    colors: [
                        Color.white.opacity(0.42),
                        Color.clear,
                    ],
                    center: .topLeading,
                    startRadius: 20,
                    endRadius: 420
                )

                RadialGradient(
                    colors: [
                        Color(red: 0.73, green: 0.84, blue: 0.74).opacity(0.22),
                        Color.clear,
                    ],
                    center: .bottomTrailing,
                    startRadius: 40,
                    endRadius: 360
                )

                LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.97, blue: 0.92).opacity(0.18),
                        Color.clear,
                        Color(red: 0.34, green: 0.39, blue: 0.26).opacity(0.06),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
}
