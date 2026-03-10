import Foundation
import PokeContent
import PokeDataModel

extension GameRuntime {
    func moveObject(id: String, through path: [FacingDirection]) {
        guard var object = gameplayState?.objectStates[id] else { return }
        for direction in path {
            object.position = translated(object.position, by: direction)
            object.facing = direction
        }
        gameplayState?.objectStates[id] = object
    }

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

    func perimeter(width: Int, height: Int) -> Set<TilePoint> {
        var points: Set<TilePoint> = []
        for x in 0..<width {
            points.insert(TilePoint(x: x, y: 0))
            points.insert(TilePoint(x: x, y: height - 1))
        }
        for y in 0..<height {
            points.insert(TilePoint(x: 0, y: y))
            points.insert(TilePoint(x: width - 1, y: y))
        }
        return points
    }

    func rect(minX: Int, minY: Int, maxX: Int, maxY: Int) -> Set<TilePoint> {
        var points: Set<TilePoint> = []
        for x in minX...maxX {
            for y in minY...maxY {
                points.insert(TilePoint(x: x, y: y))
            }
        }
        return points
    }

    func scaledStat(_ stat: Int, stage: Int) -> Int {
        let multipliers: [(Int, Int)] = [
            (2, 8),
            (2, 7),
            (2, 6),
            (2, 5),
            (2, 4),
            (2, 3),
            (2, 2),
            (3, 2),
            (4, 2),
            (5, 2),
            (6, 2),
            (7, 2),
            (8, 2),
        ]
        let index = max(0, min(multipliers.count - 1, stage + 6))
        let (numerator, denominator) = multipliers[index]
        return max(1, (stat * numerator) / denominator)
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
