import SwiftUI
import PokeDataModel
import PokeRender

struct TrainerProfileContent: View {
    let props: TrainerProfileProps

    private var badgeCount: Int {
        props.badges.filter(\.isEarned).count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                TrainerPortraitTile(props: props.portrait, fallbackName: props.trainerName)

                VStack(alignment: .leading, spacing: 6) {
                    Text(props.trainerName.uppercased())
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundStyle(FieldRetroPalette.ink)
                    Text(props.locationName)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(FieldRetroPalette.ink.opacity(0.7))
                }
            }

            TrainerInfoRow(label: "Money", value: props.moneyText)

            if props.stats.isEmpty == false {
                TrainerStatsSection(stats: props.stats)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    GameBoyPixelText(
                        "BADGES",
                        scale: 1.5,
                        color: FieldRetroPalette.ink.opacity(0.52),
                        fallbackFont: .system(size: 11, weight: .bold, design: .rounded)
                    )
                    Spacer(minLength: 8)
                    Text(props.badgeSummaryText)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(FieldRetroPalette.ink.opacity(0.72))
                }

                TrainerBadgeStrip(badges: props.badges)

                Text("\(badgeCount) earned")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(FieldRetroPalette.ink.opacity(0.66))
            }
        }
    }
}

struct TrainerStatsSection: View {
    let stats: [TrainerStatProps]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GameBoyPixelText(
                "STATS",
                scale: 1.5,
                color: FieldRetroPalette.ink.opacity(0.52),
                fallbackFont: .system(size: 11, weight: .bold, design: .rounded)
            )

            HStack(spacing: 8) {
                ForEach(stats) { stat in
                    GameplaySidebarInsetSurface(tint: FieldRetroPalette.accentGlassTint) {
                        VStack(alignment: .leading, spacing: 4) {
                            GameBoyPixelText(
                                stat.label.uppercased(),
                                scale: 1,
                                color: FieldRetroPalette.ink.opacity(0.52),
                                fallbackFont: .system(size: 10, weight: .bold, design: .rounded)
                            )
                            Text(stat.valueText)
                                .font(.system(size: 15, weight: .bold, design: .monospaced))
                                .foregroundStyle(FieldRetroPalette.ink)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }
}

struct TrainerInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        GameplaySidebarInsetSurface(tint: FieldRetroPalette.accentGlassTint) {
            HStack {
                GameBoyPixelText(
                    label.uppercased(),
                    scale: 1.5,
                    color: FieldRetroPalette.ink.opacity(0.52),
                    fallbackFont: .system(size: 11, weight: .bold, design: .rounded)
                )
                Spacer(minLength: 8)
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundStyle(FieldRetroPalette.ink)
            }
        }
    }
}

struct TrainerBadgeStrip: View {
    let badges: [TrainerBadgeProps]

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 6) {
                ForEach(badges) { badge in
                    GameplaySidebarChipSurface(
                        tint: badge.isEarned ? FieldRetroPalette.accentGlassTint : FieldRetroPalette.interactiveGlassTint
                    ) {
                        Text(badge.shortLabel)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(badge.isEarned ? FieldRetroPalette.ink : FieldRetroPalette.ink.opacity(0.32))
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
}

struct TrainerPortraitTile: View {
    let props: TrainerPortraitProps
    let fallbackName: String

    private var monogram: String {
        let trimmed = fallbackName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "TR"
        }

        let pieces = trimmed.split(separator: " ")
        if pieces.count >= 2 {
            return pieces
                .prefix(2)
                .compactMap { $0.first.map(String.init) }
                .joined()
                .uppercased()
        }

        return String(trimmed.prefix(2)).uppercased()
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(FieldRetroPalette.portraitFill)

            VStack(spacing: 5) {
                if let spriteURL = props.spriteURL,
                   let spriteFrame = props.spriteFrame {
                    PixelSpriteFrameView(url: spriteURL, frame: spriteFrame, label: props.label)
                        .frame(width: 42, height: 42)
                } else {
                    Text(monogram)
                        .font(.system(size: 28, weight: .black, design: .monospaced))
                        .foregroundStyle(FieldRetroPalette.ink)
                }

                GameBoyPixelText(
                    "TRAINER",
                    scale: 1,
                    color: FieldRetroPalette.ink.opacity(0.6),
                    fallbackFont: .system(size: 9, weight: .bold, design: .rounded)
                )
            }
        }
        .frame(width: 84, height: 84)
        .glassEffect(
            .regular.tint(FieldRetroPalette.accentGlassTint),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
    }
}

public struct PixelSpriteFrameView: View {
    public let url: URL
    public let frame: PixelRect
    public let label: String

    public init(url: URL, frame: PixelRect, label: String) {
        self.url = url
        self.frame = frame
        self.label = label
    }

    public var body: some View {
        PixelAssetFrameView(
            url: url,
            cropRect: CGRect(x: frame.x, y: frame.y, width: frame.width, height: frame.height),
            label: label,
            maskStrategy: .allWhitePixels,
            flipHorizontal: frame.flippedHorizontally
        )
    }
}
