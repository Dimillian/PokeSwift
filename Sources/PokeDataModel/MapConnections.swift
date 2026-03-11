import Foundation

public extension MapManifest {
    static let connectionBorderWidth = 3

    func blockID(atBlockX blockX: Int, blockY: Int, includeConnections: Bool = true) -> Int {
        if (0..<blockWidth).contains(blockX), (0..<blockHeight).contains(blockY) {
            let mapIndex = (blockY * blockWidth) + blockX
            guard blockIDs.indices.contains(mapIndex) else {
                return borderBlockID
            }
            return blockIDs[mapIndex]
        }

        guard includeConnections else {
            return borderBlockID
        }

        var resolvedBlockID = borderBlockID
        for direction in MapConnectionDirection.allCases {
            for connection in connections where connection.direction == direction {
                if let blockID = connection.blockID(
                    currentBlockX: blockX,
                    currentBlockY: blockY,
                    currentMapWidth: blockWidth,
                    currentMapHeight: blockHeight
                ) {
                    resolvedBlockID = blockID
                }
            }
        }
        return resolvedBlockID
    }
}

public extension MapConnectionManifest {
    func blockID(
        currentBlockX: Int,
        currentBlockY: Int,
        currentMapWidth: Int,
        currentMapHeight: Int
    ) -> Int? {
        let targetPosition: TilePoint?
        switch direction {
        case .north:
            guard (-MapManifest.connectionBorderWidth..<0).contains(currentBlockY) else {
                return nil
            }
            targetPosition = TilePoint(
                x: currentBlockX - offset,
                y: targetBlockHeight + currentBlockY
            )
        case .south:
            guard (currentMapHeight..<(currentMapHeight + MapManifest.connectionBorderWidth)).contains(currentBlockY) else {
                return nil
            }
            targetPosition = TilePoint(
                x: currentBlockX - offset,
                y: currentBlockY - currentMapHeight
            )
        case .west:
            guard (-MapManifest.connectionBorderWidth..<0).contains(currentBlockX) else {
                return nil
            }
            targetPosition = TilePoint(
                x: targetBlockWidth + currentBlockX,
                y: currentBlockY - offset
            )
        case .east:
            guard (currentMapWidth..<(currentMapWidth + MapManifest.connectionBorderWidth)).contains(currentBlockX) else {
                return nil
            }
            targetPosition = TilePoint(
                x: currentBlockX - currentMapWidth,
                y: currentBlockY - offset
            )
        }

        guard let targetPosition else {
            return nil
        }

        guard (0..<targetBlockWidth).contains(targetPosition.x),
              (0..<targetBlockHeight).contains(targetPosition.y) else {
            return nil
        }

        let targetIndex = (targetPosition.y * targetBlockWidth) + targetPosition.x
        guard targetBlockIDs.indices.contains(targetIndex) else {
            return nil
        }
        return targetBlockIDs[targetIndex]
    }
}
