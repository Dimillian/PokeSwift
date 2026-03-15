import SwiftUI

struct CombatPixelText: View {
    let text: String
    let color: Color
    let primaryScale: CGFloat
    let minimumScale: CGFloat
    let alignment: Alignment
    let fallbackFont: Font

    init(
        _ text: String,
        color: Color = .primary,
        primaryScale: CGFloat = 2,
        minimumScale: CGFloat = 1,
        alignment: Alignment = .leading,
        fallbackFont: Font = .system(size: 12, weight: .bold, design: .monospaced)
    ) {
        self.text = text
        self.color = color
        self.primaryScale = primaryScale
        self.minimumScale = minimumScale
        self.alignment = alignment
        self.fallbackFont = fallbackFont
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            pixelText(scale: primaryScale)
            pixelText(scale: midpointScale)
            pixelText(scale: minimumScale)

            Text(text)
                .font(fallbackFont)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .allowsTightening(true)
                .frame(maxWidth: .infinity, alignment: alignment)
        }
    }

    @ViewBuilder
    private func pixelText(scale: CGFloat) -> some View {
        if scale >= minimumScale {
            GameBoyPixelText(
                text,
                scale: scale,
                color: color,
                spaceWidth: scale <= 1 ? 4 : 6,
                fallbackFont: fallbackFont
            )
            .frame(maxWidth: .infinity, alignment: alignment)
        }
    }

    private var midpointScale: CGFloat {
        let midpoint = (primaryScale + minimumScale) / 2
        return midpoint == primaryScale ? minimumScale : midpoint
    }
}
