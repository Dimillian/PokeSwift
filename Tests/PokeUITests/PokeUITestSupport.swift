import ImageIO
import PokeCore
import PokeDataModel
import SwiftUI
import UniformTypeIdentifiers
import XCTest

@testable import PokeUI

func spriteDefinition(id: String, filename: String) -> FieldSpriteDefinition {
  let root = repoRoot()
  return FieldSpriteDefinition(
    id: id,
    imageURL: root.appendingPathComponent("gfx/sprites/\(filename)"),
    facingFrames: [
      .down: .init(x: 0, y: 0, width: 16, height: 16),
      .up: .init(x: 0, y: 16, width: 16, height: 16),
      .left: .init(x: 0, y: 32, width: 16, height: 16),
      .right: .init(x: 0, y: 32, width: 16, height: 16, flippedHorizontally: true),
    ],
    walkingFrames: [
      .down: .init(x: 0, y: 48, width: 16, height: 16),
      .up: .init(x: 0, y: 64, width: 16, height: 16),
      .left: .init(x: 0, y: 80, width: 16, height: 16),
      .right: .init(x: 0, y: 80, width: 16, height: 16, flippedHorizontally: true),
    ]
  )
}

func loadImage(_ url: URL) throws -> CGImage {
  guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
    let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
  else {
    throw XCTSkip("Unable to decode image at \(url.path)")
  }
  return image
}

func averageGrayscale(for image: CGImage) -> Double {
  guard let provider = image.dataProvider,
    let data = provider.data
  else {
    return 0
  }
  let bytes = CFDataGetBytePtr(data)!
  let length = CFDataGetLength(data)
  guard length > 0 else { return 0 }
  let sum = (0..<length).reduce(0) { partial, index in
    partial + Int(bytes[index])
  }
  return Double(sum) / Double(length)
}

func averageGrayscale(forTopRowsOf image: CGImage, rowCount: Int) -> Double {
  averageGrayscale(in: image, startRow: 0, rowCount: rowCount)
}

func averageGrayscale(forBottomRowsOf image: CGImage, rowCount: Int) -> Double {
  averageGrayscale(in: image, startRow: image.height - rowCount, rowCount: rowCount)
}

func averageGrayscale(in image: CGImage, startRow: Int, rowCount: Int) -> Double {
  guard let provider = image.dataProvider,
    let data = provider.data,
    let bytes = CFDataGetBytePtr(data)
  else {
    return 0
  }

  let bytesPerRow = image.bytesPerRow
  let clampedStartRow = max(0, min(image.height - 1, startRow))
  let clampedRowCount = max(1, min(rowCount, image.height - clampedStartRow))
  var sum = 0
  var count = 0

  for row in clampedStartRow..<(clampedStartRow + clampedRowCount) {
    let rowStart = row * bytesPerRow
    for column in 0..<image.width {
      sum += Int(bytes[rowStart + column])
      count += 1
    }
  }

  guard count > 0 else { return 0 }
  return Double(sum) / Double(count)
}

func grayscaleValues(in image: CGImage) -> Set<Int> {
  guard let provider = image.dataProvider,
    let data = provider.data,
    let bytes = CFDataGetBytePtr(data)
  else {
    return []
  }

  var values: Set<Int> = []
  for row in 0..<image.height {
    let rowStart = row * image.bytesPerRow
    for column in 0..<image.width {
      values.insert(Int(bytes[rowStart + column]))
    }
  }
  return values
}

func rgbValues(in image: CGImage) -> Set<RGBTriplet> {
  guard let provider = image.dataProvider,
    let data = provider.data,
    let bytes = CFDataGetBytePtr(data)
  else {
    return []
  }

  var values: Set<RGBTriplet> = []
  for row in 0..<image.height {
    let rowStart = row * image.bytesPerRow
    for column in 0..<image.width {
      let pixelStart = rowStart + (column * 4)
      values.insert(
        RGBTriplet(
          red: bytes[pixelStart],
          green: bytes[pixelStart + 1],
          blue: bytes[pixelStart + 2]
        )
      )
    }
  }
  return values
}

func alphaValues(in image: CGImage) -> Set<UInt8> {
  guard let provider = image.dataProvider,
    let data = provider.data,
    let bytes = CFDataGetBytePtr(data)
  else {
    return []
  }

  var values: Set<UInt8> = []
  for row in 0..<image.height {
    let rowStart = row * image.bytesPerRow
    for column in 0..<image.width {
      values.insert(bytes[rowStart + (column * 4) + 3])
    }
  }
  return values
}

func alphaValue(in image: CGImage, x: Int, y: Int) -> UInt8 {
  guard let provider = image.dataProvider,
    let data = provider.data,
    let bytes = CFDataGetBytePtr(data)
  else {
    return 0
  }

  let pixelStart = (y * image.bytesPerRow) + (x * 4)
  return bytes[pixelStart + 3]
}

func rgbValue(in image: CGImage, x: Int, y: Int) -> RGBTriplet {
  guard let provider = image.dataProvider,
    let data = provider.data,
    let bytes = CFDataGetBytePtr(data)
  else {
    return .init(red: 0, green: 0, blue: 0)
  }

  let pixelStart = (y * image.bytesPerRow) + (x * 4)
  return RGBTriplet(
    red: bytes[pixelStart],
    green: bytes[pixelStart + 1],
    blue: bytes[pixelStart + 2]
  )
}

func visibleRGBValues(in image: CGImage) -> Set<RGBTriplet> {
  guard let provider = image.dataProvider,
    let data = provider.data,
    let bytes = CFDataGetBytePtr(data)
  else {
    return []
  }

  var values: Set<RGBTriplet> = []
  for row in 0..<image.height {
    let rowStart = row * image.bytesPerRow
    for column in 0..<image.width {
      let pixelStart = rowStart + (column * 4)
      guard bytes[pixelStart + 3] > 0 else { continue }
      values.insert(
        RGBTriplet(
          red: bytes[pixelStart],
          green: bytes[pixelStart + 1],
          blue: bytes[pixelStart + 2]
        )
      )
    }
  }
  return values
}

func makeTestTileImage(topHalf: UInt8, bottomHalf: UInt8) throws -> CGImage {
  let width = 8
  let height = 8
  let bytesPerRow = width
  let topRows = Array(repeating: topHalf, count: width * 4)
  let bottomRows = Array(repeating: bottomHalf, count: width * 4)
  let data = Data(topRows + bottomRows) as CFData
  guard let provider = CGDataProvider(data: data),
    let image = CGImage(
      width: width,
      height: height,
      bitsPerComponent: 8,
      bitsPerPixel: 8,
      bytesPerRow: bytesPerRow,
      space: CGColorSpaceCreateDeviceGray(),
      bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
      provider: provider,
      decode: nil,
      shouldInterpolate: false,
      intent: .defaultIntent
    )
  else {
    throw XCTSkip("Unable to create synthetic tile image")
  }
  return image
}

func cropTopLeftTile(from image: CGImage, tileSize: Int, index: Int) throws -> CGImage {
  let columns = max(1, image.width / tileSize)
  let x = (index % columns) * tileSize
  let y = (index / columns) * tileSize
  guard let tile = image.cropping(to: CGRect(x: x, y: y, width: tileSize, height: tileSize)) else {
    throw XCTSkip("Unable to crop tile \(index)")
  }
  return tile
}

func makeSyntheticFieldFixture(tileValue: UInt8, spriteBodyValue: UInt8) throws -> URL {
  let root = FileManager.default.temporaryDirectory.appendingPathComponent(
    UUID().uuidString, isDirectory: true)
  try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

  let tilesetPixels = Array(repeating: tileValue, count: 8 * 8)
  try writeGrayscalePNG(
    width: 8,
    height: 8,
    pixels: tilesetPixels,
    to: root.appendingPathComponent("tileset.png")
  )

  var spritePixels = Array(repeating: UInt8(255), count: 16 * 16)
  for y in 4..<12 {
    for x in 4..<12 {
      spritePixels[(y * 16) + x] = spriteBodyValue
    }
  }
  try writeGrayscalePNG(
    width: 16,
    height: 16,
    pixels: spritePixels,
    to: root.appendingPathComponent("sprite.png")
  )

  try Data(Array(repeating: UInt8(0), count: 16)).write(to: root.appendingPathComponent("test.bst"))
  return root
}

func makeSyntheticPaletteFixture(tileValues: [UInt8]) throws -> URL {
  let root = FileManager.default.temporaryDirectory.appendingPathComponent(
    UUID().uuidString, isDirectory: true)
  try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

  var tilesetPixels: [UInt8] = []
  for value in tileValues {
    tilesetPixels.append(contentsOf: Array(repeating: value, count: 8 * 8))
  }

  try writeGrayscalePNG(
    width: tileValues.count * 8,
    height: 8,
    pixels: tilesetPixels,
    to: root.appendingPathComponent("tileset.png")
  )

  var blocksetBytes: [UInt8] = []
  for tileIndex in tileValues.indices {
    blocksetBytes.append(contentsOf: Array(repeating: UInt8(tileIndex), count: 16))
  }
  try Data(blocksetBytes).write(to: root.appendingPathComponent("test.bst"))
  return root
}

func makePaletteMap(blockWidth: Int, blockHeight: Int) -> MapManifest {
  MapManifest(
    id: "PALETTE_MAP",
    displayName: "Palette Map",
    defaultMusicID: "MUSIC_PALLET_TOWN",
    borderBlockID: 0,
    blockWidth: blockWidth,
    blockHeight: blockHeight,
    stepWidth: blockWidth * 2,
    stepHeight: blockHeight * 2,
    tileset: "TEST",
    blockIDs: Array(0..<(blockWidth * blockHeight)),
    stepCollisionTileIDs: Array(repeating: 0x00, count: blockWidth * blockHeight * 4),
    warps: [],
    backgroundEvents: [],
    objects: []
  )
}

func dmgPaletteValues() -> Set<RGBTriplet> {
  Set([
    RGBTriplet(red: 15, green: 56, blue: 15),
    RGBTriplet(red: 48, green: 98, blue: 48),
    RGBTriplet(red: 139, green: 172, blue: 15),
    RGBTriplet(red: 155, green: 188, blue: 15),
  ])
}

func writeGrayscalePNG(width: Int, height: Int, pixels: [UInt8], to url: URL) throws {
  let bytesPerRow = width
  let data = Data(pixels) as CFData
  guard let provider = CGDataProvider(data: data),
    let image = CGImage(
      width: width,
      height: height,
      bitsPerComponent: 8,
      bitsPerPixel: 8,
      bytesPerRow: bytesPerRow,
      space: CGColorSpaceCreateDeviceGray(),
      bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
      provider: provider,
      decode: nil,
      shouldInterpolate: false,
      intent: .defaultIntent
    ),
    let destination = CGImageDestinationCreateWithURL(
      url as CFURL, UTType.png.identifier as CFString, 1, nil)
  else {
    throw XCTSkip("Unable to write grayscale PNG fixture")
  }

  CGImageDestinationAddImage(destination, image, nil)
  guard CGImageDestinationFinalize(destination) else {
    throw XCTSkip("Unable to finalize PNG fixture at \(url.path)")
  }
}

func makeRGBAImage(width: Int, height: Int, pixels: [UInt8]) throws -> CGImage {
  let bytesPerRow = width * 4
  let data = Data(pixels) as CFData
  guard let provider = CGDataProvider(data: data),
    let image = CGImage(
      width: width,
      height: height,
      bitsPerComponent: 8,
      bitsPerPixel: 32,
      bytesPerRow: bytesPerRow,
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
      provider: provider,
      decode: nil,
      shouldInterpolate: false,
      intent: .defaultIntent
    )
  else {
    throw XCTSkip("Unable to create RGBA fixture image")
  }

  return image
}

func renderRGBAImage(_ image: CGImage, background: RGBTriplet? = nil) throws -> CGImage {
  let width = image.width
  let height = image.height
  let bytesPerRow = width * 4
  var bytes = [UInt8](repeating: 0, count: height * bytesPerRow)

  guard
    let context = CGContext(
      data: &bytes,
      width: width,
      height: height,
      bitsPerComponent: 8,
      bytesPerRow: bytesPerRow,
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )
  else {
    throw XCTSkip("Unable to create RGBA render context")
  }

  context.interpolationQuality = .none
  context.setShouldAntialias(false)

  if let background {
    context.setFillColor(
      CGColor(
        red: CGFloat(background.red) / 255,
        green: CGFloat(background.green) / 255,
        blue: CGFloat(background.blue) / 255,
        alpha: 1
      )
    )
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
  }

  context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

  guard let renderedImage = context.makeImage() else {
    throw XCTSkip("Unable to create composited RGBA image")
  }

  return renderedImage
}

func repoRoot() -> URL {
  URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
}

struct RGBTriplet: Hashable {
  let red: UInt8
  let green: UInt8
  let blue: UInt8
}
