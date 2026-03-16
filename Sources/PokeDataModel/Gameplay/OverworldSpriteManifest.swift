import Foundation

public struct FacingFrameManifest: Codable, Equatable, Sendable {
    public let down: PixelRect
    public let up: PixelRect
    public let left: PixelRect
    public let right: PixelRect

    public init(down: PixelRect, up: PixelRect, left: PixelRect, right: PixelRect) {
        self.down = down
        self.up = up
        self.left = left
        self.right = right
    }
}

public struct OverworldSpriteManifest: Codable, Equatable, Sendable {
    public let id: String
    public let imagePath: String
    public let frameWidth: Int
    public let frameHeight: Int
    public let facingFrames: FacingFrameManifest
    public let walkingFrames: FacingFrameManifest?

    public init(
        id: String,
        imagePath: String,
        frameWidth: Int,
        frameHeight: Int,
        facingFrames: FacingFrameManifest,
        walkingFrames: FacingFrameManifest? = nil
    ) {
        self.id = id
        self.imagePath = imagePath
        self.frameWidth = frameWidth
        self.frameHeight = frameHeight
        self.facingFrames = facingFrames
        self.walkingFrames = walkingFrames
    }
}
