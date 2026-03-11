import SwiftUI

struct AccordionSidebarCard<Content: View>: View {
    let title: String
    let summary: String?
    let isExpanded: Bool
    let action: () -> Void
    let content: Content

    init(
        title: String,
        summary: String? = nil,
        isExpanded: Bool,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.summary = summary
        self.isExpanded = isExpanded
        self.action = action
        self.content = content()
    }

    var body: some View {
        GameplaySidebarCardSurface(
            padding: isExpanded ? 18 : 16,
            tint: isExpanded ? FieldRetroPalette.accentGlassTint : FieldRetroPalette.glassTint
        ) {
            VStack(alignment: .leading, spacing: isExpanded ? 14 : 0) {
                headerButton

                if isExpanded {
                    content
                        .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .top)), removal: .opacity))
                }
            }
        }
    }

    private var headerButton: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                GameBoyPixelText(
                    title.uppercased(),
                    scale: 1.5,
                    color: FieldRetroPalette.ink.opacity(0.6),
                    fallbackFont: .system(size: 12, weight: .bold, design: .rounded)
                )

                Spacer(minLength: 8)

                GlassEffectContainer(spacing: 8) {
                    HStack(spacing: 8) {
                        if let summary {
                            GameplaySidebarChipSurface(
                                tint: isExpanded ? FieldRetroPalette.accentGlassTint : FieldRetroPalette.interactiveGlassTint
                            ) {
                                Text(summary.uppercased())
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundStyle(FieldRetroPalette.ink.opacity(0.62))
                            }
                        }

                        GameplaySidebarChipSurface(
                            tint: isExpanded ? FieldRetroPalette.accentGlassTint : FieldRetroPalette.interactiveGlassTint
                        ) {
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(FieldRetroPalette.ink.opacity(0.56))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct PartyHPBar: View {
    let currentHP: Int
    let maxHP: Int

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
        .frame(height: 10)
    }
}

struct ExperienceBar: View {
    let totalExperience: Int
    let levelStartExperience: Int
    let nextLevelExperience: Int

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
        .frame(height: 8)
    }
}
