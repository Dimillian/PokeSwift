import SwiftUI
import PokeDataModel

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

    func battleScreenEffect(
        displayScale: CGFloat,
        presentation: BattlePresentationTelemetry
    ) -> some View {
        modifier(BattleScreenEffectModifier(displayScale: displayScale, presentation: presentation))
    }
}

private struct FieldScreenEffectModifier: ViewModifier {
    let displayStyle: FieldDisplayStyle
    let displayScale: CGFloat
    @Environment(\.pokeAppearanceMode) private var appearanceMode
    @Environment(\.pokeGameplayHDREnabled) private var gameplayHDREnabled
    @Environment(\.colorScheme) private var colorScheme

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
                            .float(shaderHDRBoost),
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

    private var shaderHDRBoost: Float {
        guard displayStyle == .dmgTinted else { return 0 }
        return Float(
            PokeThemePalette.gameplayHDRProfile(
                appearanceMode: appearanceMode,
                colorScheme: colorScheme,
                isEnabled: gameplayHDREnabled
            ).fieldShaderBoost
        )
    }
}

private struct BattleScreenEffectModifier: ViewModifier {
    let displayScale: CGFloat
    let presentation: BattlePresentationTelemetry
    @State private var displayedIntroProgress: CGFloat = 1
    @State private var displayedIntroAmount: CGFloat = 0
    @State private var seededIntroRevision: Int?
    @Environment(\.pokeAppearanceMode) private var appearanceMode
    @Environment(\.pokeGameplayHDREnabled) private var gameplayHDREnabled
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .layerEffect(
                Shader(
                    function: BattleScreenShader.function,
                    arguments: [
                        .float(shaderViewportWidth),
                        .float(shaderViewportHeight),
                        .float(Float(max(1, displayScale))),
                        .float(introStyleValue),
                        .float(Float(displayedIntroProgress)),
                        .float(Float(displayedIntroAmount)),
                        .float(shaderHDRBoost),
                    ]
                ),
                maxSampleOffset: .init(width: maxSampleOffset, height: maxSampleOffset)
            )
            .drawingGroup()
            .onAppear {
                syncIntroState(animated: false)
            }
            .onChange(of: presentation.transitionStyle) { _, _ in
                syncIntroState(animated: true)
            }
            .onChange(of: presentation.stage) { _, _ in
                syncIntroState(animated: true)
            }
            .onChange(of: presentation.revision) { _, _ in
                syncIntroState(animated: true)
            }
    }

    private var shaderViewportWidth: Float {
        Float(CGFloat(FieldSceneRenderer.viewportPixelSize.width) * displayScale)
    }

    private var shaderViewportHeight: Float {
        Float(CGFloat(FieldSceneRenderer.viewportPixelSize.height) * displayScale)
    }

    private var maxSampleOffset: CGFloat {
        max(12, displayScale * 10)
    }

    private var introStyleValue: Float {
        guard presentation.stage == .introSpiral else {
            return 0
        }
        switch presentation.transitionStyle {
        case .none:
            return 0
        case .circle:
            return 1
        case .spiral:
            return 2
        }
    }

    private func syncIntroState(animated: Bool) {
        if presentation.stage == .introFlash1 {
            seededIntroRevision = nil
        }

        guard presentation.transitionStyle != .none, presentation.stage == .introSpiral else {
            displayedIntroProgress = 1
            displayedIntroAmount = 0
            return
        }

        if seededIntroRevision != presentation.revision {
            seededIntroRevision = presentation.revision
            displayedIntroProgress = 0.01
            displayedIntroAmount = 1
            DispatchQueue.main.async {
                withAnimation(transitionAnimation) {
                    displayedIntroProgress = 1
                    displayedIntroAmount = 1
                }
            }
            return
        }

        if animated == false {
            displayedIntroProgress = 1
            displayedIntroAmount = 1
        }
    }

    private var transitionAnimation: Animation {
        switch presentation.stage {
        case .introSpiral:
            return .easeOut(duration: 0.62)
        default:
            return .easeInOut(duration: 0.2)
        }
    }

    private var shaderHDRBoost: Float {
        Float(
            PokeThemePalette.gameplayHDRProfile(
                appearanceMode: appearanceMode,
                colorScheme: colorScheme,
                isEnabled: gameplayHDREnabled
            ).battleShaderBoost
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
