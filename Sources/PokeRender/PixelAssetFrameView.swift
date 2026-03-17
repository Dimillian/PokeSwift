import AppKit
import SwiftUI

public struct PixelAssetFrameView: View {
    private let url: URL
    private let cropRect: CGRect
    private let label: String
    private let maskStrategy: PixelAssetMaskStrategy
    private let flipHorizontal: Bool
    private let flipVertical: Bool
    @State private var renderedImage: CGImage?
    @State private var didAttemptLoad = false

    public init(
        url: URL,
        cropRect: CGRect,
        label: String,
        maskStrategy: PixelAssetMaskStrategy = .none,
        flipHorizontal: Bool = false,
        flipVertical: Bool = false
    ) {
        self.url = url
        self.cropRect = cropRect.integral
        self.label = label
        self.maskStrategy = maskStrategy
        self.flipHorizontal = flipHorizontal
        self.flipVertical = flipVertical
    }

    public var body: some View {
        Group {
            if let renderedImage {
                imageView(image: renderedImage)
            } else if let syncImage = syncProcessedImage {
                imageView(image: syncImage)
            } else if didAttemptLoad {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color.black.opacity(0.12))
            }
        }
        .accessibilityLabel(label)
        .task(id: taskID) {
            let image = await PixelAssetImageRepository.shared.image(
                for: url,
                cropRect: cropRect,
                maskStrategy: maskStrategy,
                renderMode: .standard
            )
            guard Task.isCancelled == false else { return }
            renderedImage = image
            didAttemptLoad = true
        }
    }

    private func imageView(image: CGImage) -> some View {
        Image(decorative: image, scale: 1)
            .resizable()
            .interpolation(.none)
            .antialiased(false)
            .aspectRatio(contentMode: .fit)
            .scaleEffect(x: flipHorizontal ? -1 : 1, y: flipVertical ? -1 : 1)
    }

    private var taskID: String {
        "\(url.standardizedFileURL.path)|\(cropRect.debugDescription)|\(String(describing: maskStrategy))|\(flipHorizontal)|\(flipVertical)"
    }

    private var syncProcessedImage: CGImage? {
        PixelAssetImageRepository.loadImage(
            for: url,
            cropRect: cropRect,
            maskStrategy: maskStrategy,
            renderMode: .standard
        )
    }
}
