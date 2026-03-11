import SwiftUI

private enum FieldScreenShader {
    static let function = ShaderFunction(
        library: .bundle(PokeUIResources.bundle),
        name: "fieldScreenEffect"
    )
}

private enum BattleScreenShader {
    static let function = ShaderFunction(
        library: .bundle(PokeUIResources.bundle),
        name: "battleScreenEffect"
    )
}

extension View {
    func fieldScreenEffect(displayStyle: FieldDisplayStyle, displayScale: CGFloat) -> some View {
        modifier(FieldScreenEffectModifier(displayStyle: displayStyle, displayScale: displayScale))
    }

    func battleScreenEffect(displayScale: CGFloat) -> some View {
        modifier(BattleScreenEffectModifier(displayScale: displayScale))
    }
}

private struct FieldScreenEffectModifier: ViewModifier {
    let displayStyle: FieldDisplayStyle
    let displayScale: CGFloat

    func body(content: Content) -> some View {
        guard displayStyle != .rawGrayscale else {
            return AnyView(content)
        }

        return AnyView(
            content
                .colorEffect(
                    Shader(
                        function: FieldScreenShader.function,
                        arguments: [
                            .float(shaderViewportWidth),
                            .float(shaderViewportHeight),
                            .float(Float(max(1, displayScale))),
                            .float(displayStyle.shaderPresetValue),
                        ]
                    )
                )
                .drawingGroup()
        )
    }

    private var shaderViewportWidth: Float {
        Float(CGFloat(FieldSceneRenderer.viewportPixelSize.width) * displayScale)
    }

    private var shaderViewportHeight: Float {
        Float(CGFloat(FieldSceneRenderer.viewportPixelSize.height) * displayScale)
    }
}

private struct BattleScreenEffectModifier: ViewModifier {
    let displayScale: CGFloat

    func body(content: Content) -> some View {
        content
            .colorEffect(
                Shader(
                    function: BattleScreenShader.function,
                    arguments: [
                        .float(Float(max(1, displayScale))),
                    ]
                )
            )
    }
}

private extension FieldDisplayStyle {
    var shaderPresetValue: Float {
        switch self {
        case .rawGrayscale:
            return 0
        case .dmgAuthentic:
            return 1
        case .dmgTinted:
            return 2
        }
    }
}
