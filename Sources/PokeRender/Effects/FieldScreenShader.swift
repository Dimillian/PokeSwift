import SwiftUI
import PokeDataModel

private enum FieldScreenShader {
    static let function = ShaderFunction(
        library: .bundle(PokeRenderResources.bundle),
        name: "fieldScreenEffect"
    )
}

private enum BattleScreenShader {
    static let function = ShaderFunction(
        library: .bundle(PokeRenderResources.bundle),
        name: "battleScreenEffect"
    )
}

private enum BattleTransitionScreenShader {
    static let function = ShaderFunction(
        library: .bundle(PokeRenderResources.bundle),
        name: "battleTransitionEffect"
    )
}

struct GameplayScreenEffectConfiguration: Equatable {
    let viewportWidth: Float
    let viewportHeight: Float
    let pixelScale: Float
    let preset: Float
    let hdrBoost: Float
    let introStyle: Float
    let introProgress: Float
    let introAmount: Float

    init(
        displayStyle: FieldDisplayStyle,
        displayScale: CGFloat,
        hdrBoost: Float,
        presentation: BattlePresentationTelemetry? = nil,
        introProgress: CGFloat = 1,
        introAmount: CGFloat = 0
    ) {
        let resolvedScale = Float(max(1, displayScale))
        viewportWidth = Float(CGFloat(FieldSceneRenderer.viewportPixelSize.width) * displayScale)
        viewportHeight = Float(CGFloat(FieldSceneRenderer.viewportPixelSize.height) * displayScale)
        pixelScale = resolvedScale
        preset = displayStyle.shaderPresetValue
        self.hdrBoost = hdrBoost
        introStyle = presentation.map(Self.introStyleValue(for:)) ?? 0
        self.introProgress = Float(introProgress)
        self.introAmount = Float(introAmount)
    }

    static func introStyleValue(for presentation: BattlePresentationTelemetry) -> Float {
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

    var fieldArguments: [Shader.Argument] {
        [
            .float(viewportWidth),
            .float(viewportHeight),
            .float(pixelScale),
            .float(preset),
            .float(hdrBoost),
        ]
    }

    var battleArguments: [Shader.Argument] {
        [
            .float(viewportWidth),
            .float(viewportHeight),
            .float(pixelScale),
            .float(preset),
            .float(introStyle),
            .float(introProgress),
            .float(introAmount),
            .float(hdrBoost),
        ]
    }
}

extension View {
    public func gameplayScreenEffect(
        displayStyle: FieldDisplayStyle,
        displayScale: CGFloat,
        battlePresentation: BattlePresentationTelemetry? = nil,
        hdrBoost: Float = 0
    ) -> some View {
        modifier(
            GameplayScreenEffectModifier(
                displayStyle: displayStyle,
                displayScale: displayScale,
                battlePresentation: battlePresentation,
                hdrBoost: hdrBoost
            )
        )
    }

    public func fieldScreenEffect(
        displayStyle: FieldDisplayStyle,
        displayScale: CGFloat,
        hdrBoost: Float = 0
    ) -> some View {
        gameplayScreenEffect(
            displayStyle: displayStyle,
            displayScale: displayScale,
            hdrBoost: hdrBoost
        )
    }

    public func battleScreenEffect(
        displayStyle: FieldDisplayStyle,
        displayScale: CGFloat,
        presentation: BattlePresentationTelemetry,
        hdrBoost: Float = 0
    ) -> some View {
        gameplayScreenEffect(
            displayStyle: displayStyle,
            displayScale: displayScale,
            battlePresentation: presentation,
            hdrBoost: hdrBoost
        )
    }

    public func battleScreenEffect(
        displayScale: CGFloat,
        presentation: BattlePresentationTelemetry,
        hdrBoost: Float = 0
    ) -> some View {
        gameplayScreenEffect(
            displayStyle: .defaultGameplayStyle,
            displayScale: displayScale,
            battlePresentation: presentation,
            hdrBoost: hdrBoost
        )
    }

    public func battleTransitionEffect(
        displayScale: CGFloat,
        presentation: BattlePresentationTelemetry
    ) -> some View {
        modifier(
            BattleTransitionEffectModifier(
                displayScale: displayScale,
                presentation: presentation
            )
        )
    }
}

private struct GameplayScreenEffectModifier: ViewModifier {
    let displayStyle: FieldDisplayStyle
    let displayScale: CGFloat
    let battlePresentation: BattlePresentationTelemetry?
    let hdrBoost: Float

    func body(content: Content) -> some View {
        if let battlePresentation {
            return AnyView(
                content.modifier(
                    BattleScreenEffectModifier(
                        displayStyle: displayStyle,
                        displayScale: displayScale,
                        presentation: battlePresentation,
                        hdrBoost: hdrBoost
                    )
                )
            )
        }

        return AnyView(
            content.modifier(
                FieldScreenEffectModifier(
                    displayStyle: displayStyle,
                    displayScale: displayScale,
                    hdrBoost: hdrBoost
                )
            )
        )
    }
}

private struct FieldScreenEffectModifier: ViewModifier {
    let displayStyle: FieldDisplayStyle
    let displayScale: CGFloat
    let hdrBoost: Float

    func body(content: Content) -> some View {
        let configuration = GameplayScreenEffectConfiguration(
            displayStyle: displayStyle,
            displayScale: displayScale,
            hdrBoost: hdrBoost
        )

        return content
            .colorEffect(
                Shader(
                    function: FieldScreenShader.function,
                    arguments: configuration.fieldArguments
                )
            )
            .drawingGroup()
    }
}

private struct BattleScreenEffectModifier: ViewModifier {
    let displayStyle: FieldDisplayStyle
    let displayScale: CGFloat
    let presentation: BattlePresentationTelemetry
    let hdrBoost: Float
    @State private var displayedIntroProgress: CGFloat = 1
    @State private var displayedIntroAmount: CGFloat = 0
    @State private var seededIntroRevision: Int?

    func body(content: Content) -> some View {
        let configuration = GameplayScreenEffectConfiguration(
            displayStyle: displayStyle,
            displayScale: displayScale,
            hdrBoost: hdrBoost,
            presentation: presentation,
            introProgress: displayedIntroProgress,
            introAmount: displayedIntroAmount
        )

        content
            .layerEffect(
                Shader(
                    function: BattleScreenShader.function,
                    arguments: configuration.battleArguments
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

    private var maxSampleOffset: CGFloat {
        max(12, displayScale * 10)
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
}

private struct BattleTransitionEffectModifier: ViewModifier {
    let displayScale: CGFloat
    let presentation: BattlePresentationTelemetry
    @State private var displayedIntroProgress: CGFloat = 1
    @State private var displayedIntroAmount: CGFloat = 0
    @State private var seededIntroRevision: Int?

    func body(content: Content) -> some View {
        let configuration = GameplayScreenEffectConfiguration(
            displayStyle: .defaultGameplayStyle,
            displayScale: displayScale,
            hdrBoost: 0,
            presentation: presentation,
            introProgress: displayedIntroProgress,
            introAmount: displayedIntroAmount
        )

        return content
            .layerEffect(
                Shader(
                    function: BattleTransitionScreenShader.function,
                    arguments: [
                        .float(configuration.viewportWidth),
                        .float(configuration.viewportHeight),
                        .float(configuration.introStyle),
                        .float(configuration.introProgress),
                        .float(configuration.introAmount),
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

    private var maxSampleOffset: CGFloat {
        max(12, displayScale * 10)
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
