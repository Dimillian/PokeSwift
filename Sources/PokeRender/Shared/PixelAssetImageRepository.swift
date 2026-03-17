import CoreGraphics
import Foundation
import ImageIO

public enum PixelAssetRenderMode: Hashable, Sendable {
    case standard
    case battlePokemonFront
    case battlePokemonBack
}

public enum PixelAssetMaskStrategy: Hashable, Sendable {
    case none
    case allWhitePixels
    case floodFillBorderWhite
}

enum PixelAssetMasking {
    static func applyWhiteTransparencyMask(to image: CGImage) -> CGImage? {
        applyWhiteTransparencyMask(to: image, strategy: .floodFillBorderWhite)
    }

    static func applyWhiteTransparencyMask(
        to image: CGImage,
        strategy: PixelAssetMaskStrategy
    ) -> CGImage? {
        guard strategy != .none else {
            return image
        }

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
        let maskBytes: [UInt8]
        switch strategy {
        case .none:
            return image
        case .allWhitePixels:
            maskBytes = grayscaleBytes.map { $0 >= threshold ? UInt8(255) : UInt8(0) }
        case .floodFillBorderWhite:
            var resolvedMaskBytes = [UInt8](repeating: 0, count: width * height)
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
                resolvedMaskBytes[index] = 255

                let x = index % width
                let y = index / width
                enqueueIfNeeded(x: x - 1, y: y)
                enqueueIfNeeded(x: x + 1, y: y)
                enqueueIfNeeded(x: x, y: y - 1)
                enqueueIfNeeded(x: x, y: y + 1)
            }

            maskBytes = resolvedMaskBytes
        }

        let rgbaBytesPerRow = width * 4
        var rgbaBytes = [UInt8](repeating: 0, count: width * height * 4)

        for index in 0..<(width * height) {
            let isMasked = maskBytes[index] == 255
            let alpha: UInt8 = isMasked ? 0 : 255
            let value: UInt8 = isMasked ? 0 : grayscaleBytes[index]
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
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }
}

enum PixelAssetImageProcessing {
    private static let battleCanvasSize = 56
    private static let battleBackCropSize = 28

    static func processImage(
        _ image: CGImage,
        cropRect: CGRect? = nil,
        maskStrategy: PixelAssetMaskStrategy,
        renderMode: PixelAssetRenderMode
    ) -> CGImage? {
        let croppedImage: CGImage
        if let cropRect {
            guard let resolvedImage = image.cropping(to: cropRect.integral) else {
                return nil
            }
            croppedImage = resolvedImage
        } else {
            croppedImage = image
        }

        let maskedImage: CGImage
        if maskStrategy == .none {
            maskedImage = croppedImage
        } else {
            guard let resolvedImage = PixelAssetMasking.applyWhiteTransparencyMask(
                to: croppedImage,
                strategy: maskStrategy
            ) else {
                return nil
            }
            maskedImage = resolvedImage
        }

        switch renderMode {
        case .standard:
            return maskedImage
        case .battlePokemonFront:
            return centeredOnBattleCanvas(maskedImage)
        case .battlePokemonBack:
            return normalizedBattleBackSprite(maskedImage)
        }
    }

    private static func centeredOnBattleCanvas(_ image: CGImage) -> CGImage? {
        return drawIntoCanvas(width: battleCanvasSize, height: battleCanvasSize) { context in
            let originX = CGFloat(battleCanvasSize - image.width) / 2
            let originY = CGFloat(battleCanvasSize - image.height) / 2
            context.draw(
                image,
                in: CGRect(
                    x: originX,
                    y: originY,
                    width: CGFloat(image.width),
                    height: CGFloat(image.height)
                )
            )
        }
    }

    private static func normalizedBattleBackSprite(_ image: CGImage) -> CGImage? {
        let cropWidth = min(battleBackCropSize, image.width)
        let cropHeight = min(battleBackCropSize, image.height)
        guard cropWidth > 0, cropHeight > 0 else {
            return nil
        }

        guard let croppedImage = image.cropping(
            to: CGRect(x: 0, y: 0, width: cropWidth, height: cropHeight)
        ) else {
            return nil
        }

        let scaledWidth = cropWidth * 2
        let scaledHeight = cropHeight * 2
        guard let scaledImage = drawIntoCanvas(width: scaledWidth, height: scaledHeight, draw: { context in
            context.draw(
                croppedImage,
                in: CGRect(x: 0, y: 0, width: scaledWidth, height: scaledHeight)
            )
        }) else {
            return nil
        }

        guard scaledWidth != battleCanvasSize || scaledHeight != battleCanvasSize else {
            return scaledImage
        }
        return centeredOnBattleCanvas(scaledImage)
    }

    private static func drawIntoCanvas(
        width: Int,
        height: Int,
        draw: (CGContext) -> Void
    ) -> CGImage? {
        guard
            let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else {
            return nil
        }

        context.interpolationQuality = .none
        context.setShouldAntialias(false)
        context.clear(CGRect(x: 0, y: 0, width: width, height: height))
        draw(context)
        return context.makeImage()
    }
}

actor PixelAssetImageRepository {
    enum CacheKey: Hashable {
        case asset(
            path: String,
            cropRect: CGRect?,
            maskStrategy: PixelAssetMaskStrategy,
            renderMode: PixelAssetRenderMode
        )

        init(
            url: URL,
            cropRect: CGRect?,
            maskStrategy: PixelAssetMaskStrategy,
            renderMode: PixelAssetRenderMode
        ) {
            let path = url.standardizedFileURL.path
            self = .asset(
                path: path,
                cropRect: cropRect?.integral,
                maskStrategy: maskStrategy,
                renderMode: renderMode
            )
        }
    }

    private enum CachedImage {
        case image(CGImage)
        case missing
    }

    static let shared = PixelAssetImageRepository()

    private var cachedImages: [CacheKey: CachedImage] = [:]
    private var inFlightLoads: [CacheKey: Task<CGImage?, Never>] = [:]

    func image(
        for url: URL,
        cropRect: CGRect? = nil,
        maskStrategy: PixelAssetMaskStrategy = .none,
        renderMode: PixelAssetRenderMode
    ) async -> CGImage? {
        let key = CacheKey(
            url: url,
            cropRect: cropRect,
            maskStrategy: maskStrategy,
            renderMode: renderMode
        )

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
            Self.loadImage(
                for: url,
                cropRect: cropRect,
                maskStrategy: maskStrategy,
                renderMode: renderMode
            )
        }
        inFlightLoads[key] = task

        let image = await task.value
        cachedImages[key] = image.map(CachedImage.image) ?? .missing
        inFlightLoads[key] = nil
        return image
    }

    nonisolated static func loadImage(
        for url: URL,
        cropRect: CGRect? = nil,
        maskStrategy: PixelAssetMaskStrategy = .none,
        renderMode: PixelAssetRenderMode
    ) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return nil
        }

        return PixelAssetImageProcessing.processImage(
            image,
            cropRect: cropRect,
            maskStrategy: maskStrategy,
            renderMode: renderMode
        )
    }
}
