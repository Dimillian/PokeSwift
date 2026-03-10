import SwiftUI

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
