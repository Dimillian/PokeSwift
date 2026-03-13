import CoreGraphics
import ImageIO
import SwiftUI
import PokeDataModel

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

            StatusStrip(items: props.statusItems)
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

struct StatusStrip: View {
    let items: [String]

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 6) {
                ForEach(items, id: \.self) { item in
                    GameplaySidebarChipSurface {
                        GameBoyPixelText(
                            item.uppercased(),
                            scale: 1,
                            color: FieldRetroPalette.ink.opacity(0.74),
                            fallbackFont: .system(size: 10, weight: .bold, design: .monospaced)
                        )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(FieldRetroPalette.outline.opacity(0.18), lineWidth: 1)
                .padding(5)

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
        Group {
            if let image = croppedFrameImage {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .interpolation(.none)
                    .antialiased(false)
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(x: frame.flippedHorizontally ? -1 : 1, y: 1)
            } else {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(FieldRetroPalette.outline.opacity(0.12))
                    .overlay {
                        Text("??")
                            .font(.system(size: 15, weight: .black, design: .monospaced))
                            .foregroundStyle(FieldRetroPalette.ink.opacity(0.6))
                    }
            }
        }
        .accessibilityLabel(label)
    }

    private var croppedFrameImage: CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
              let croppedImage = image.cropping(to: CGRect(x: frame.x, y: frame.y, width: frame.width, height: frame.height).integral),
              let maskedImage = applyTransparencyMask(to: croppedImage) else {
            return nil
        }
        return maskedImage
    }

    private func applyTransparencyMask(to image: CGImage) -> CGImage? {
        let width = image.width
        let height = image.height
        let bytesPerRow = width
        var grayscaleBytes = [UInt8](repeating: 0, count: width * height)

        guard let grayscaleContext = CGContext(
            data: &grayscaleBytes,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            return nil
        }

        grayscaleContext.interpolationQuality = .none
        grayscaleContext.setShouldAntialias(false)
        grayscaleContext.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        let maskBytes = grayscaleBytes.map { $0 == 255 ? UInt8(255) : UInt8(0) }
        let maskData = Data(maskBytes) as CFData

        guard let provider = CGDataProvider(data: maskData),
              let mask = CGImage(
                maskWidth: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 8,
                bytesPerRow: width,
                provider: provider,
                decode: nil,
                shouldInterpolate: false
              ) else {
            return nil
        }

        return image.masking(mask)
    }
}
