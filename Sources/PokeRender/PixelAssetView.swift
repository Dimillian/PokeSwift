import AppKit
import SwiftUI

public struct PixelAssetView: View {
    private let url: URL
    private let label: String
    private let whiteIsTransparent: Bool
    @State private var renderedImage: CGImage?
    @State private var didAttemptLoad = false

    public init(url: URL, label: String, whiteIsTransparent: Bool = false) {
        self.url = url
        self.label = label
        self.whiteIsTransparent = whiteIsTransparent
    }

    public var body: some View {
        Group {
            if let renderedImage {
                Image(decorative: renderedImage, scale: 1)
                    .resizable()
                    .interpolation(.none)
                    .antialiased(false)
                    .aspectRatio(contentMode: .fit)
            } else if let syncImage = syncProcessedImage {
                Image(decorative: syncImage, scale: 1)
                    .resizable()
                    .interpolation(.none)
                    .antialiased(false)
                    .aspectRatio(contentMode: .fit)
            } else if didAttemptLoad {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.black.opacity(0.24))
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                            Text(label)
                                .font(.system(.caption, design: .monospaced))
                        }
                        .foregroundStyle(.secondary)
                        .padding(8)
                    }
            }
        }
        .accessibilityLabel(label)
        .task(id: taskID) {
            let image = await PixelAssetImageRepository.shared.image(
                for: url,
                whiteIsTransparent: whiteIsTransparent
            )
            guard Task.isCancelled == false else { return }
            renderedImage = image
            didAttemptLoad = true
        }
    }

    private var taskID: String {
        "\(url.standardizedFileURL.path)|\(whiteIsTransparent)"
    }

    private var syncProcessedImage: CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return nil
        }
        if whiteIsTransparent {
            return PixelAssetMasking.applyWhiteTransparencyMask(to: image)
        }
        return image
    }
}
