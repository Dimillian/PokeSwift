import Foundation
import PokeContent
import PokeDataModel

extension GameRuntime {
    static let battleStageRatios: [(Int, Int)] = [
        (25, 100),
        (28, 100),
        (33, 100),
        (40, 100),
        (50, 100),
        (66, 100),
        (1, 1),
        (15, 10),
        (2, 1),
        (25, 10),
        (3, 1),
        (35, 10),
        (4, 1),
    ]

    func translated(_ point: TilePoint, by direction: FacingDirection) -> TilePoint {
        switch direction {
        case .up:
            return TilePoint(x: point.x, y: point.y - 1)
        case .down:
            return TilePoint(x: point.x, y: point.y + 1)
        case .left:
            return TilePoint(x: point.x - 1, y: point.y)
        case .right:
            return TilePoint(x: point.x + 1, y: point.y)
        }
    }

    func scaledStat(_ stat: Int, stage: Int) -> Int {
        let (numerator, denominator) = stageRatio(for: stage)
        return max(1, (stat * numerator) / denominator)
    }

    func scaledAccuracy(baseAccuracyPercent: Int, accuracyStage: Int, evasionStage: Int) -> Int {
        let baseAccuracy = max(1, min(255, (baseAccuracyPercent * 255) / 100))
        let reflectedEvasionStage = max(-6, min(6, -evasionStage))
        let (accuracyNumerator, accuracyDenominator) = stageRatio(for: accuracyStage)
        let (evasionNumerator, evasionDenominator) = stageRatio(for: reflectedEvasionStage)
        let scaled = (((baseAccuracy * accuracyNumerator) / accuracyDenominator) * evasionNumerator) / evasionDenominator
        return max(1, min(255, scaled))
    }

    func stageRatio(for stage: Int) -> (Int, Int) {
        let index = max(0, min(Self.battleStageRatios.count - 1, stage + 6))
        return Self.battleStageRatios[index]
    }

    func hasFlag(_ flagID: String) -> Bool {
        gameplayState?.activeFlags.contains(flagID) ?? false
    }

    func record(button: RuntimeButton) {
        recentInputEvents.append(.init(button: button, timestamp: Self.timestamp()))
        if recentInputEvents.count > 20 {
            recentInputEvents.removeFirst(recentInputEvents.count - 20)
        }
    }

    static func timestamp() -> String {
        ISO8601DateFormatter().string(from: Date())
    }

    static func missingAssets(in content: LoadedContent) -> [String] {
        let requiredPaths =
            content.titleManifest.assets.map(\.relativePath) +
            content.gameplayManifest.tilesets.flatMap { [$0.imagePath, $0.blocksetPath] } +
            content.gameplayManifest.overworldSprites.map(\.imagePath)

        return requiredPaths.compactMap { relativePath in
            let url = content.rootURL.appendingPathComponent(relativePath)
            return FileManager.default.fileExists(atPath: url.path) ? nil : relativePath
        }
    }
}
