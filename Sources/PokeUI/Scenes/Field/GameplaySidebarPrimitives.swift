import SwiftUI

struct AccordionSidebarCard<Content: View>: View {
    let title: String
    let summary: String?
    let isExpanded: Bool
    let isHighlighted: Bool
    let action: () -> Void
    let content: Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var highlightPulse = false

    init(
        title: String,
        summary: String? = nil,
        isExpanded: Bool,
        isHighlighted: Bool = false,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.summary = summary
        self.isExpanded = isExpanded
        self.isHighlighted = isHighlighted
        self.action = action
        self.content = content()
    }

    var body: some View {
        GameplaySidebarCardSurface(
            padding: isExpanded ? 18 : 16,
            tint: surfaceTint
        ) {
            VStack(alignment: .leading, spacing: isExpanded ? 14 : 0) {
                headerButton

                if isExpanded {
                    content
                        .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .top)), removal: .opacity))
                }
            }
        }
        .background {
            if isHighlighted {
                cardShape
                    .fill(highlightWash)
                    .padding(-4)
                    .blur(radius: reduceMotion ? 10 : 16)
            }
        }
        .overlay {
            if isHighlighted {
                ZStack {
                    cardShape
                        .stroke(highlightOuterStrokeColor, lineWidth: isExpanded ? 4 : 3)
                        .blur(radius: reduceMotion ? 0 : 2)

                    cardShape
                        .stroke(highlightStrokeColor, lineWidth: isExpanded ? 2.5 : 2)

                    innerCardShape
                        .stroke(highlightInnerStrokeColor, lineWidth: 1.2)
                        .padding(5)
                }
            }
        }
        .shadow(color: highlightShadowColor, radius: highlightShadowRadius, y: 0)
        .shadow(color: highlightOuterShadowColor, radius: highlightOuterShadowRadius, y: 0)
        .onAppear {
            updateHighlightAnimation(isActive: isHighlighted)
        }
        .onChange(of: isHighlighted) { _, isActive in
            updateHighlightAnimation(isActive: isActive)
        }
    }

    private var headerButton: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                GameBoyPixelText(
                    title.uppercased(),
                    scale: 1.5,
                    color: FieldRetroPalette.ink.opacity(isHighlighted ? 0.82 : 0.6),
                    fallbackFont: .system(size: 12, weight: .bold, design: .rounded)
                )

                Spacer(minLength: 8)

                GlassEffectContainer(spacing: 8) {
                    HStack(spacing: 8) {
                        if let summary {
                            GameplaySidebarChipSurface(
                                tint: chipTint
                            ) {
                                Text(summary.uppercased())
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundStyle(FieldRetroPalette.ink.opacity(isHighlighted ? 0.74 : 0.62))
                            }
                        }

                        GameplaySidebarChipSurface(
                            tint: chipTint
                        ) {
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(FieldRetroPalette.ink.opacity(isHighlighted ? 0.68 : 0.56))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var surfaceTint: Color {
        (isExpanded || isHighlighted) ? FieldRetroPalette.accentGlassTint : FieldRetroPalette.glassTint
    }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
    }

    private var innerCardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 19, style: .continuous)
    }

    private var chipTint: Color {
        (isExpanded || isHighlighted) ? FieldRetroPalette.accentGlassTint : FieldRetroPalette.interactiveGlassTint
    }

    private var highlightIntensity: Double {
        guard isHighlighted else { return 0 }
        guard reduceMotion == false else { return 0.82 }
        return highlightPulse ? 1 : 0.68
    }

    private var highlightWash: LinearGradient {
        LinearGradient(
            colors: [
                attentionColor.opacity(0.1 + (0.08 * highlightIntensity)),
                attentionColor.opacity(0.04 + (0.05 * highlightIntensity)),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var attentionColor: Color {
        Color(red: 0.72, green: 0.9, blue: 0.48)
    }

    private var highlightOuterStrokeColor: Color {
        attentionColor.opacity(0.24 + (0.18 * highlightIntensity))
    }

    private var highlightStrokeColor: Color {
        attentionColor.opacity(0.52 + (0.22 * highlightIntensity))
    }

    private var highlightInnerStrokeColor: Color {
        .white.opacity(0.22 + (0.18 * highlightIntensity))
    }

    private var highlightShadowColor: Color {
        attentionColor.opacity(0.14 + (0.18 * highlightIntensity))
    }

    private var highlightOuterShadowColor: Color {
        attentionColor.opacity(0.08 + (0.12 * highlightIntensity))
    }

    private var highlightShadowRadius: CGFloat {
        isHighlighted ? (reduceMotion ? 24 : (highlightPulse ? 30 : 22)) : 0
    }

    private var highlightOuterShadowRadius: CGFloat {
        isHighlighted ? (reduceMotion ? 34 : (highlightPulse ? 42 : 30)) : 0
    }

    private func updateHighlightAnimation(isActive: Bool) {
        guard isActive else {
            highlightPulse = false
            return
        }

        highlightPulse = false
        guard reduceMotion == false else { return }

        withAnimation(.easeInOut(duration: 1.08).repeatForever(autoreverses: true)) {
            highlightPulse = true
        }
    }
}

struct PartyHPBar: View {
    let currentHP: Int
    let maxHP: Int
    let height: CGFloat

    init(currentHP: Int, maxHP: Int, height: CGFloat = 10) {
        self.currentHP = currentHP
        self.maxHP = maxHP
        self.height = height
    }

    private var hpFraction: CGFloat {
        CGFloat(currentHP) / CGFloat(max(1, maxHP))
    }

    private var barGradient: LinearGradient {
        switch hpFraction {
        case ..<0.25:
            return LinearGradient(
                colors: [
                    Color(red: 0.74, green: 0.39, blue: 0.33),
                    Color(red: 0.62, green: 0.25, blue: 0.22),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        case ..<0.5:
            return LinearGradient(
                colors: [
                    Color(red: 0.79, green: 0.66, blue: 0.28),
                    Color(red: 0.65, green: 0.5, blue: 0.18),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        default:
            return LinearGradient(
                colors: [
                    Color(red: 0.47, green: 0.67, blue: 0.33),
                    Color(red: 0.32, green: 0.5, blue: 0.23),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let width = max(0, proxy.size.width * hpFraction)

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(FieldRetroPalette.track.opacity(0.82))

                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(barGradient)
                    .frame(width: width)
            }
        }
        .frame(height: height)
    }
}

struct ExperienceBar: View {
    let totalExperience: Int
    let levelStartExperience: Int
    let nextLevelExperience: Int
    let height: CGFloat

    init(
        totalExperience: Int,
        levelStartExperience: Int,
        nextLevelExperience: Int,
        height: CGFloat = 8
    ) {
        self.totalExperience = totalExperience
        self.levelStartExperience = levelStartExperience
        self.nextLevelExperience = nextLevelExperience
        self.height = height
    }

    private var experienceFraction: CGFloat {
        let range = max(0, nextLevelExperience - levelStartExperience)
        guard range > 0 else { return 1 }
        let progress = min(range, max(0, totalExperience - levelStartExperience))
        return CGFloat(progress) / CGFloat(range)
    }

    var body: some View {
        GeometryReader { proxy in
            let width = max(0, proxy.size.width * experienceFraction)

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(FieldRetroPalette.track.opacity(0.82))

                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.39, green: 0.58, blue: 0.76),
                                Color(red: 0.23, green: 0.41, blue: 0.58),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: width)
            }
        }
        .frame(height: height)
    }
}
