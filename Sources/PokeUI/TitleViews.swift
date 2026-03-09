import SwiftUI
import PokeDataModel

public struct GameBoyScreen<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        ZStack {
            Color.white
            content
        }
        .overlay {
            GameBoyGridOverlay()
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

public struct TitleMenuPanel: View {
    private let entries: [TitleMenuEntry]
    private let focusedIndex: Int

    public init(entries: [TitleMenuEntry], focusedIndex: Int) {
        self.entries = entries
        self.focusedIndex = focusedIndex
    }

    public var body: some View {
        GameBoyPanel {
            GlassEffectContainer(spacing: 10) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Title Menu")
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundStyle(.black.opacity(0.72))
                        .padding(.horizontal, 6)

                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        TitleMenuRow(entry: entry, isFocused: index == focusedIndex)
                    }
                }
            }
        }
    }
}

private struct TitleMenuRow: View {
    let entry: TitleMenuEntry
    let isFocused: Bool

    private let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)

    var body: some View {
        HStack(spacing: 10) {
            Text(isFocused ? "▶" : " ")
                .frame(width: 16, alignment: .leading)
                .foregroundStyle(.black.opacity(isFocused ? 0.92 : 0.64))
            Text(entry.label)
                .foregroundStyle(entry.enabledByDefault ? .black.opacity(0.92) : .black.opacity(0.46))
            Spacer()
            if !entry.enabledByDefault {
                Text("Disabled")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.black.opacity(0.62))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.05), in: Capsule())
            }
        }
        .font(.system(size: 18, weight: .medium, design: .monospaced))
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            isFocused
                ? Color(red: 0.80, green: 0.90, blue: 0.73).opacity(0.30)
                : Color.white.opacity(0.12),
            in: shape
        )
        .overlay {
            shape
                .stroke(isFocused ? .black.opacity(0.14) : .black.opacity(0.07), lineWidth: 1)
        }
        .glassEffect(
            isFocused
                ? .regular.tint(Color(red: 0.77, green: 0.89, blue: 0.72).opacity(0.45))
                : .regular.tint(Color.white.opacity(0.18)),
            in: shape
        )
    }
}

private struct GameBoyGridOverlay: View {
    var body: some View {
        GeometryReader { _ in
            Canvas { context, size in
                let spacing: CGFloat = 8
                var columns = Path()
                var rows = Path()
                let dotSize: CGFloat = 1.2

                var x: CGFloat = 0
                while x <= size.width {
                    columns.move(to: CGPoint(x: x, y: 0))
                    columns.addLine(to: CGPoint(x: x, y: size.height))
                    x += spacing
                }

                var y: CGFloat = 0
                while y <= size.height {
                    rows.move(to: CGPoint(x: 0, y: y))
                    rows.addLine(to: CGPoint(x: size.width, y: y))
                    y += spacing
                }

                context.stroke(columns, with: .color(.black.opacity(0.05)), lineWidth: 0.5)
                context.stroke(rows, with: .color(.black.opacity(0.035)), lineWidth: 0.5)

                var dotY: CGFloat = 0
                while dotY <= size.height {
                    var dotX: CGFloat = 0
                    while dotX <= size.width {
                        let rect = CGRect(
                            x: dotX - (dotSize / 2),
                            y: dotY - (dotSize / 2),
                            width: dotSize,
                            height: dotSize
                        )
                        context.fill(
                            Path(ellipseIn: rect),
                            with: .color(Color(red: 0.45, green: 0.5, blue: 0.35).opacity(0.12))
                        )
                        dotX += spacing
                    }
                    dotY += spacing
                }
            }
            .overlay {
                Rectangle()
                    .fill(Color(red: 0.88, green: 0.94, blue: 0.84).opacity(0.08))
            }
            .allowsHitTesting(false)
        }
    }
}
