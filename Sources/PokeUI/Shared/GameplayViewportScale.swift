import CoreGraphics
import PokeRender

public enum GameplayViewportScale {
    public static func snappedFieldViewportScale(for availableSize: CGSize) -> CGFloat {
        snappedScale(
            for: availableSize,
            viewportPixelSize: CGSize(
                width: CGFloat(FieldSceneRenderer.viewportPixelSize.width),
                height: CGFloat(FieldSceneRenderer.viewportPixelSize.height)
            )
        )
    }

    public static func snappedScale(for availableSize: CGSize, viewportPixelSize: CGSize) -> CGFloat {
        let rawScale = min(
            availableSize.width / viewportPixelSize.width,
            availableSize.height / viewportPixelSize.height
        )
        guard rawScale.isFinite, rawScale > 0 else {
            return 1
        }
        if rawScale >= 1 {
            return max(1, floor(rawScale))
        }
        return rawScale
    }
}
