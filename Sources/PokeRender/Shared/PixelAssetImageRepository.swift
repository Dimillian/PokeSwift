import CoreGraphics
import Foundation
import ImageIO

enum PixelAssetMasking {
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

actor PixelAssetImageRepository {
    enum CacheKey: Hashable {
        case direct(path: String)
        case whiteMasked(path: String)

        init(url: URL, whiteIsTransparent: Bool) {
            let path = url.standardizedFileURL.path
            self = whiteIsTransparent ? .whiteMasked(path: path) : .direct(path: path)
        }
    }

    private enum CachedImage {
        case image(CGImage)
        case missing
    }

    static let shared = PixelAssetImageRepository()

    private var cachedImages: [CacheKey: CachedImage] = [:]
    private var inFlightLoads: [CacheKey: Task<CGImage?, Never>] = [:]

    func image(for url: URL, whiteIsTransparent: Bool) async -> CGImage? {
        let key = CacheKey(url: url, whiteIsTransparent: whiteIsTransparent)

        if let cached = cachedImages[key] {
            switch cached {
            case let .image(image):
                return image
            case .missing:
                return nil
            }
        }

        if let existingTask = inFlightLoads[key] {
            return await existingTask.value
        }

        let task = Task.detached(priority: .userInitiated) {
            Self.loadImage(for: url, whiteIsTransparent: whiteIsTransparent)
        }
        inFlightLoads[key] = task

        let image = await task.value
        cachedImages[key] = image.map(CachedImage.image) ?? .missing
        inFlightLoads[key] = nil
        return image
    }

    nonisolated private static func loadImage(for url: URL, whiteIsTransparent: Bool) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return nil
        }

        guard whiteIsTransparent else {
            return image
        }

        return PixelAssetMasking.applyWhiteTransparencyMask(to: image)
    }
}
