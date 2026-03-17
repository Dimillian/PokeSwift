import Foundation

public extension LoadedContent {
    func requiredAssetPaths() -> [String] {
        let tilesetAssetPaths = gameplayManifest.tilesets.flatMap { [$0.imagePath, $0.blocksetPath] }
        let animatedTileAssetPaths = gameplayManifest.tilesets.flatMap { tileset in
            tileset.animation.animatedTiles.flatMap(\.frameImagePaths)
        }
        let speciesBattleAssetPaths = gameplayManifest.species.flatMap { species -> [String] in
            guard let battleSprite = species.battleSprite else { return [] }
            return [battleSprite.frontImagePath, battleSprite.backImagePath]
        }

        return deduplicatedAssetPaths(
            titleManifest.assets.map(\.relativePath) +
                ["Assets/battle/effects/send_out_poof.png"] +
                battleAnimationManifest.tilesets.map(\.imagePath) +
                tilesetAssetPaths +
                animatedTileAssetPaths +
                gameplayManifest.overworldSprites.map(\.imagePath) +
                speciesBattleAssetPaths
        )
    }

    func missingRequiredAssetPaths(fileManager: FileManager = .default) -> [String] {
        requiredAssetPaths().filter { relativePath in
            let assetURL = rootURL.appendingPathComponent(relativePath)
            return fileManager.fileExists(atPath: assetURL.path) == false
        }
    }

    private func deduplicatedAssetPaths(_ paths: [String]) -> [String] {
        var seen: Set<String> = []
        var orderedPaths: [String] = []
        orderedPaths.reserveCapacity(paths.count)

        for path in paths where seen.insert(path).inserted {
            orderedPaths.append(path)
        }

        return orderedPaths
    }
}
