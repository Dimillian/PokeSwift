import AppKit
import ImageIO
import SwiftUI

public struct PixelAssetView: View {
    private let url: URL
    private let label: String
    private let whiteIsTransparent: Bool

    public init(url: URL, label: String, whiteIsTransparent: Bool = false) {
        self.url = url
        self.label = label
        self.whiteIsTransparent = whiteIsTransparent
    }

    public var body: some View {
        Group {
            if let image = renderedImage {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .interpolation(.none)
                    .antialiased(false)
                    .aspectRatio(contentMode: .fit)
            } else if let image = NSImage(contentsOf: url) {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.none)
                    .antialiased(false)
                    .aspectRatio(contentMode: .fit)
            } else {
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
    }

    private var renderedImage: CGImage? {
        guard whiteIsTransparent,
              let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
              let maskedImage = Self.applyWhiteTransparencyMask(to: image) else {
            return nil
        }
        return maskedImage
    }

    static func applyWhiteTransparencyMask(to image: CGImage) -> CGImage? {
        let width = image.width
        let height = image.height
        let grayscaleBytesPerRow = width
        var grayscaleBytes = [UInt8](repeating: 0, count: width * height)

        guard let grayscaleContext = CGContext(
            data: &grayscaleBytes,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: grayscaleBytesPerRow,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            return nil
        }

        grayscaleContext.interpolationQuality = .none
        grayscaleContext.setShouldAntialias(false)
        grayscaleContext.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        let threshold: UInt8 = 250
        var maskBytes = [UInt8](repeating: 0, count: width * height)
        var visited = [Bool](repeating: false, count: width * height)
        var queue: [Int] = []
        queue.reserveCapacity((width * 2) + (height * 2))

        func enqueueIfNeeded(x: Int, y: Int) {
            guard x >= 0, x < width, y >= 0, y < height else { return }
            let index = (y * width) + x
            guard visited[index] == false, grayscaleBytes[index] >= threshold else { return }
            visited[index] = true
            queue.append(index)
        }

        for x in 0..<width {
            enqueueIfNeeded(x: x, y: 0)
            enqueueIfNeeded(x: x, y: height - 1)
        }

        for y in 0..<height {
            enqueueIfNeeded(x: 0, y: y)
            enqueueIfNeeded(x: width - 1, y: y)
        }

        var queueIndex = 0
        while queueIndex < queue.count {
            let index = queue[queueIndex]
            queueIndex += 1
            maskBytes[index] = 255

            let x = index % width
            let y = index / width
            enqueueIfNeeded(x: x - 1, y: y)
            enqueueIfNeeded(x: x + 1, y: y)
            enqueueIfNeeded(x: x, y: y - 1)
            enqueueIfNeeded(x: x, y: y + 1)
        }

        let rgbaBytesPerRow = width * 4
        var rgbaBytes = [UInt8](repeating: 0, count: width * height * 4)

        for index in 0..<(width * height) {
            let alpha: UInt8 = maskBytes[index] == 255 ? 0 : 255
            let value = grayscaleBytes[index]
            let rgbaIndex = index * 4
            rgbaBytes[rgbaIndex] = value
            rgbaBytes[rgbaIndex + 1] = value
            rgbaBytes[rgbaIndex + 2] = value
            rgbaBytes[rgbaIndex + 3] = alpha
        }

        let rgbaData = Data(rgbaBytes) as CFData

        guard let provider = CGDataProvider(data: rgbaData) else {
            return nil
        }

        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: rgbaBytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }
}
