import CoreGraphics
import Foundation
import PokeDataModel

enum BattleSendOutAnimationTimeline {
    static let poofTileSize = 8

    static let tossDuration = BattleSendOutAnimationTiming.tossDuration
    static let releaseHoldDuration = BattleSendOutAnimationTiming.releaseHoldDuration
    static let poofFrameDuration = BattleSendOutAnimationTiming.poofFrameDuration
    static let revealStep1Duration = BattleSendOutAnimationTiming.revealStep1Duration
    static let revealStep2Duration = BattleSendOutAnimationTiming.revealStep2Duration
    static let revealFinalDuration = BattleSendOutAnimationTiming.revealFinalDuration

    static let enemyPoofFrames = buildPoofFrames(
        frames: [
            .init(frameBlock: frameBlock06, baseX: 0x70, baseY: 0x30, transform: .horizontal),
            .init(frameBlock: frameBlock07, baseX: 0x70, baseY: 0x30, transform: .horizontal),
            .init(frameBlock: frameBlock08, baseX: 0x6C, baseY: 0x2C, transform: .horizontal),
            .init(frameBlock: frameBlock09, baseX: 0x6C, baseY: 0x2C, transform: .horizontal),
            .init(frameBlock: frameBlock0A, baseX: 0x68, baseY: 0x28, transform: .horizontal),
        ]
    )

    static let playerPoofFrames = buildPoofFrames(
        frames: [
            .init(frameBlock: frameBlock06, baseX: 0x20, baseY: 0x48, transform: .horizontalAndVertical),
            .init(frameBlock: frameBlock07, baseX: 0x20, baseY: 0x48, transform: .horizontalAndVertical),
            .init(frameBlock: frameBlock08, baseX: 0x1C, baseY: 0x44, transform: .horizontalAndVertical),
        ]
    )

    static let playerPoofFrameSequence = [0, 1, 2]
    static let enemyPoofFrameSequence = [0, 1, 2, 3, 4, 4]

    static let revealScaleStep1: CGFloat = 3.0 / 7.0
    static let revealScaleStep2: CGFloat = 5.0 / 7.0
    static let revealScaleFinal: CGFloat = 1

    static let defaultTotalDuration: TimeInterval = totalDuration(for: .player)

    static func totalDuration(for side: BattlePresentationSide) -> TimeInterval {
        tossDuration +
        releaseHoldDuration +
        (poofFrameDuration * Double(poofFrameSequence(for: side).count)) +
        revealStep1Duration +
        revealStep2Duration +
        revealFinalDuration
    }

    static func poofFrameSequence(for side: BattlePresentationSide) -> [Int] {
        switch side {
        case .enemy:
            return enemyPoofFrameSequence
        case .player:
            return playerPoofFrameSequence
        }
    }

    static func poofFrames(for side: BattlePresentationSide) -> [BattleSendOutPoofFrame] {
        switch side {
        case .enemy:
            return enemyPoofFrames
        case .player:
            return playerPoofFrames
        }
    }

    static func state(at elapsed: TimeInterval?, side: BattlePresentationSide = .player) -> BattleSendOutVisualState {
        guard let elapsed else {
            return .idle
        }

        let clampedElapsed = max(0, elapsed)
        if clampedElapsed < tossDuration {
            return .toss
        }

        let releaseHoldEnd = tossDuration + releaseHoldDuration
        if clampedElapsed < releaseHoldEnd {
            return .releaseHold
        }

        let poofSequence = poofFrameSequence(for: side)
        let poofStart = releaseHoldEnd
        let poofEnd = poofStart + (poofFrameDuration * Double(poofSequence.count))
        if clampedElapsed < poofEnd {
            let sequenceIndex = min(
                poofSequence.count - 1,
                Int((clampedElapsed - poofStart) / poofFrameDuration)
            )
            return .poof(frameIndex: poofSequence[sequenceIndex])
        }

        let revealStep1End = poofEnd + revealStep1Duration
        if clampedElapsed < revealStep1End {
            return .revealStep1
        }

        let revealStep2End = revealStep1End + revealStep2Duration
        if clampedElapsed < revealStep2End {
            return .revealStep2
        }

        return .revealFinal
    }

    private static func buildPoofFrames(frames: [BattleSendOutPoofSourceFrame]) -> [BattleSendOutPoofFrame] {
        let placements = frames.map(\.placements)
        let minX = placements.flatMap(\.self).map(\.x).min() ?? 0
        let minY = placements.flatMap(\.self).map(\.y).min() ?? 0
        let maxX = placements.flatMap(\.self).map { $0.x + poofTileSize }.max() ?? poofTileSize
        let maxY = placements.flatMap(\.self).map { $0.y + poofTileSize }.max() ?? poofTileSize
        let canvasSize = CGSize(width: maxX - minX, height: maxY - minY)

        return placements.map { placements in
            BattleSendOutPoofFrame(
                canvasSize: canvasSize,
                placements: placements.map {
                    BattleSendOutPoofTilePlacement(
                        x: $0.x - minX,
                        y: $0.y - minY,
                        tileID: $0.tileID,
                        flipH: $0.flipH,
                        flipV: $0.flipV
                    )
                }
            )
        }
    }
}

struct BattleSendOutPoofFrame: Equatable {
    let canvasSize: CGSize
    let placements: [BattleSendOutPoofTilePlacement]
}

struct BattleSendOutPoofTilePlacement: Equatable {
    let x: Int
    let y: Int
    let tileID: Int
    let flipH: Bool
    let flipV: Bool

    var atlasFrame: CGRect {
        CGRect(
            x: (tileID % 16) * BattleSendOutAnimationTimeline.poofTileSize,
            y: (tileID / 16) * BattleSendOutAnimationTimeline.poofTileSize,
            width: BattleSendOutAnimationTimeline.poofTileSize,
            height: BattleSendOutAnimationTimeline.poofTileSize
        )
    }
}

private struct BattleSendOutPoofSourceFrame {
    let frameBlock: [BattleSendOutPoofSourceTile]
    let baseX: Int
    let baseY: Int
    let transform: BattleSendOutPoofTransform

    var placements: [BattleSendOutPoofTilePlacement] {
        frameBlock.map { tile in
            let offsetX = tile.x * BattleSendOutAnimationTimeline.poofTileSize
            let offsetY = tile.y * BattleSendOutAnimationTimeline.poofTileSize
            switch transform {
            case .horizontal:
                return BattleSendOutPoofTilePlacement(
                    x: 168 - (baseX + offsetX),
                    y: baseY + offsetY + 40,
                    tileID: tile.tileID,
                    flipH: !tile.flipH,
                    flipV: tile.flipV
                )
            case .horizontalAndVertical:
                return BattleSendOutPoofTilePlacement(
                    x: 168 - (baseX + offsetX),
                    y: 136 - (baseY + offsetY),
                    tileID: tile.tileID,
                    flipH: !tile.flipH,
                    flipV: !tile.flipV
                )
            }
        }
    }
}

private struct BattleSendOutPoofSourceTile {
    let x: Int
    let y: Int
    let tileID: Int
    let flipH: Bool
    let flipV: Bool

    init(x: Int, y: Int, tileID: Int, flipH: Bool = false, flipV: Bool = false) {
        self.x = x
        self.y = y
        self.tileID = tileID
        self.flipH = flipH
        self.flipV = flipV
    }
}

private enum BattleSendOutPoofTransform {
    case horizontal
    case horizontalAndVertical
}

private let frameBlock06: [BattleSendOutPoofSourceTile] = [
    .init(x: 1, y: 0, tileID: 0x23),
    .init(x: 0, y: 1, tileID: 0x32),
    .init(x: 1, y: 1, tileID: 0x33),
    .init(x: 2, y: 0, tileID: 0x23, flipH: true),
    .init(x: 2, y: 1, tileID: 0x33, flipH: true),
    .init(x: 3, y: 1, tileID: 0x32, flipH: true),
    .init(x: 0, y: 2, tileID: 0x32, flipV: true),
    .init(x: 1, y: 2, tileID: 0x33, flipV: true),
    .init(x: 1, y: 3, tileID: 0x23, flipV: true),
    .init(x: 2, y: 2, tileID: 0x33, flipH: true, flipV: true),
    .init(x: 3, y: 2, tileID: 0x32, flipH: true, flipV: true),
    .init(x: 2, y: 3, tileID: 0x23, flipH: true, flipV: true),
]

private let frameBlock07: [BattleSendOutPoofSourceTile] = [
    .init(x: 0, y: 0, tileID: 0x20),
    .init(x: 1, y: 0, tileID: 0x21),
    .init(x: 0, y: 1, tileID: 0x30),
    .init(x: 1, y: 1, tileID: 0x31),
    .init(x: 2, y: 0, tileID: 0x21, flipH: true),
    .init(x: 3, y: 0, tileID: 0x20, flipH: true),
    .init(x: 2, y: 1, tileID: 0x31, flipH: true),
    .init(x: 3, y: 1, tileID: 0x30, flipH: true),
    .init(x: 0, y: 2, tileID: 0x30, flipV: true),
    .init(x: 1, y: 2, tileID: 0x31, flipV: true),
    .init(x: 0, y: 3, tileID: 0x20, flipV: true),
    .init(x: 1, y: 3, tileID: 0x21, flipV: true),
    .init(x: 2, y: 2, tileID: 0x31, flipH: true, flipV: true),
    .init(x: 3, y: 2, tileID: 0x30, flipH: true, flipV: true),
    .init(x: 2, y: 3, tileID: 0x21, flipH: true, flipV: true),
    .init(x: 3, y: 3, tileID: 0x20, flipH: true, flipV: true),
]

private let frameBlock08: [BattleSendOutPoofSourceTile] = [
    .init(x: 0, y: 0, tileID: 0x20),
    .init(x: 1, y: 0, tileID: 0x21),
    .init(x: 0, y: 1, tileID: 0x30),
    .init(x: 1, y: 1, tileID: 0x31),
    .init(x: 3, y: 0, tileID: 0x21, flipH: true),
    .init(x: 4, y: 0, tileID: 0x20, flipH: true),
    .init(x: 3, y: 1, tileID: 0x31, flipH: true),
    .init(x: 4, y: 1, tileID: 0x30, flipH: true),
    .init(x: 0, y: 3, tileID: 0x30, flipV: true),
    .init(x: 1, y: 3, tileID: 0x31, flipV: true),
    .init(x: 0, y: 4, tileID: 0x20, flipV: true),
    .init(x: 1, y: 4, tileID: 0x21, flipV: true),
    .init(x: 3, y: 3, tileID: 0x31, flipH: true, flipV: true),
    .init(x: 4, y: 3, tileID: 0x30, flipH: true, flipV: true),
    .init(x: 3, y: 4, tileID: 0x21, flipH: true, flipV: true),
    .init(x: 4, y: 4, tileID: 0x20, flipH: true, flipV: true),
]

private let frameBlock09: [BattleSendOutPoofSourceTile] = [
    .init(x: 0, y: 0, tileID: 0x24),
    .init(x: 1, y: 0, tileID: 0x25),
    .init(x: 0, y: 1, tileID: 0x34),
    .init(x: 3, y: 0, tileID: 0x25, flipH: true),
    .init(x: 4, y: 0, tileID: 0x24, flipH: true),
    .init(x: 4, y: 1, tileID: 0x34, flipH: true),
    .init(x: 0, y: 3, tileID: 0x34, flipV: true),
    .init(x: 0, y: 4, tileID: 0x24, flipV: true),
    .init(x: 1, y: 4, tileID: 0x25, flipV: true),
    .init(x: 4, y: 3, tileID: 0x34, flipH: true, flipV: true),
    .init(x: 3, y: 4, tileID: 0x25, flipH: true, flipV: true),
    .init(x: 4, y: 4, tileID: 0x24, flipH: true, flipV: true),
]

private let frameBlock0A: [BattleSendOutPoofSourceTile] = [
    .init(x: 0, y: 0, tileID: 0x24),
    .init(x: 1, y: 0, tileID: 0x25),
    .init(x: 0, y: 1, tileID: 0x34),
    .init(x: 4, y: 0, tileID: 0x25, flipH: true),
    .init(x: 5, y: 0, tileID: 0x24, flipH: true),
    .init(x: 5, y: 1, tileID: 0x34, flipH: true),
    .init(x: 0, y: 4, tileID: 0x34, flipV: true),
    .init(x: 0, y: 5, tileID: 0x24, flipV: true),
    .init(x: 1, y: 5, tileID: 0x25, flipV: true),
    .init(x: 5, y: 4, tileID: 0x34, flipH: true, flipV: true),
    .init(x: 4, y: 5, tileID: 0x25, flipH: true, flipV: true),
    .init(x: 5, y: 5, tileID: 0x24, flipH: true, flipV: true),
]

enum BattleSendOutVisualState: Equatable {
    case idle
    case toss
    case releaseHold
    case poof(frameIndex: Int)
    case revealStep1
    case revealStep2
    case revealFinal

    var ballOpacity: Double {
        switch self {
        case .toss, .releaseHold:
            return 1
        case .idle, .poof, .revealStep1, .revealStep2, .revealFinal:
            return 0
        }
    }

    var poofFrameIndex: Int? {
        switch self {
        case let .poof(frameIndex):
            return frameIndex
        case .idle, .toss, .releaseHold, .revealStep1, .revealStep2, .revealFinal:
            return nil
        }
    }

    var poofOpacity: Double {
        poofFrameIndex == nil ? 0 : 1
    }

    var pokemonOpacity: Double {
        switch self {
        case .revealStep1, .revealStep2, .revealFinal:
            return 1
        case .idle, .toss, .releaseHold, .poof:
            return 0
        }
    }

    var pokemonScale: CGFloat {
        switch self {
        case .revealStep1:
            return BattleSendOutAnimationTimeline.revealScaleStep1
        case .revealStep2:
            return BattleSendOutAnimationTimeline.revealScaleStep2
        case .revealFinal:
            return BattleSendOutAnimationTimeline.revealScaleFinal
        case .idle, .toss, .releaseHold, .poof:
            return BattleSendOutAnimationTimeline.revealScaleStep1
        }
    }

    var usesSendOutAnchor: Bool {
        switch self {
        case .idle:
            return false
        case .toss, .releaseHold, .poof, .revealStep1, .revealStep2, .revealFinal:
            return true
        }
    }
}
