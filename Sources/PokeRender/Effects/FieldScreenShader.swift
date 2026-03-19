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

private enum CompatibilityPaletteShader {
    static let function = ShaderFunction(
        library: .bundle(PokeRenderResources.bundle),
        name: "compatibilityPaletteEffect"
    )
}

struct GameplayScreenEffectConfiguration: Equatable {
    let viewportWidth: Float
    let viewportHeight: Float
    let pixelScale: Float
    let preset: Float
    let hdrBoost: Float
    let fieldPaletteComponents: [Float]
    let introStyle: Float
    let introProgress: Float
    let introAmount: Float

    init(
        displayStyle: FieldDisplayStyle,
        displayScale: CGFloat,
        hdrBoost: Float,
        fieldPalette: FieldPaletteManifest? = nil,
        presentation: BattlePresentationTelemetry? = nil,
        introProgress: CGFloat = 1,
        introAmount: CGFloat = 0
    ) {
        let resolvedScale = Float(max(1, displayScale))
        let resolvedDisplayStyle = displayStyle == .gbcCompatibility && fieldPalette == nil && presentation == nil
            ? .defaultGameplayStyle
            : displayStyle
        viewportWidth = Float(CGFloat(FieldSceneRenderer.viewportPixelSize.width) * displayScale)
        viewportHeight = Float(CGFloat(FieldSceneRenderer.viewportPixelSize.height) * displayScale)
        pixelScale = resolvedScale
        preset = resolvedDisplayStyle.shaderPresetValue
        self.hdrBoost = hdrBoost
        fieldPaletteComponents = Self.fieldPaletteComponents(for: fieldPalette)
        introStyle = presentation.map(Self.introStyleValue(for:)) ?? 0
        self.introProgress = Float(introProgress)
        self.introAmount = Float(introAmount)
    }

    static func introStyleValue(for presentation: BattlePresentationTelemetry) -> Float {
        switch presentation.semantics.transitionShaderStyle ?? .none {
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
        ] + fieldPaletteComponents.map(Shader.Argument.float)
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

    static func fieldPaletteComponents(for fieldPalette: FieldPaletteManifest?) -> [Float] {
        let colors = fieldPalette?.colors ?? defaultFieldPalette.colors
        let clampedColors = colors.prefix(4)
        guard clampedColors.count == 4 else {
            return Array(repeating: 0, count: 12)
        }
        return clampedColors.flatMap { color in
            [
                Float(max(0, min(31, color.red))) / 31.0,
                Float(max(0, min(31, color.green))) / 31.0,
                Float(max(0, min(31, color.blue))) / 31.0,
            ]
        }
    }

    private static let defaultFieldPalette = FieldPaletteManifest(
        id: "DEFAULT_FIELD_PALETTE",
        colors: [
            .init(red: 31, green: 31, blue: 31),
            .init(red: 21, green: 21, blue: 21),
            .init(red: 10, green: 10, blue: 10),
            .init(red: 0, green: 0, blue: 0),
        ]
    )
}

extension View {
    public func gameplayScreenEffect(
        displayStyle: FieldDisplayStyle,
        displayScale: CGFloat,
        fieldPalette: FieldPaletteManifest? = nil,
        battlePresentation: BattlePresentationTelemetry? = nil,
        hdrBoost: Float = 0
    ) -> some View {
        modifier(
            GameplayScreenEffectModifier(
                displayStyle: displayStyle,
                displayScale: displayScale,
                fieldPalette: fieldPalette,
                battlePresentation: battlePresentation,
                hdrBoost: hdrBoost
            )
        )
    }

    public func fieldScreenEffect(
        displayStyle: FieldDisplayStyle,
        displayScale: CGFloat,
        fieldPalette: FieldPaletteManifest? = nil,
        hdrBoost: Float = 0
    ) -> some View {
        gameplayScreenEffect(
            displayStyle: displayStyle,
            displayScale: displayScale,
            fieldPalette: fieldPalette,
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
        displayStyle: FieldDisplayStyle = .defaultGameplayStyle,
        displayScale: CGFloat,
        presentation: BattlePresentationTelemetry
    ) -> some View {
        modifier(
            BattleTransitionEffectModifier(
                displayStyle: displayStyle,
                displayScale: displayScale,
                presentation: presentation
            )
        )
    }

    public func compatibilityPaletteEffect(_ palette: FieldPaletteManifest?) -> some View {
        modifier(CompatibilityPaletteEffectModifier(palette: palette))
    }
}

private struct GameplayScreenEffectModifier: ViewModifier {
    let displayStyle: FieldDisplayStyle
    let displayScale: CGFloat
    let fieldPalette: FieldPaletteManifest?
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
                    fieldPalette: fieldPalette,
                    hdrBoost: hdrBoost
                )
            )
        )
    }
}

private struct CompatibilityPaletteEffectModifier: ViewModifier {
    let palette: FieldPaletteManifest?

    func body(content: Content) -> some View {
        guard let palette else {
            return AnyView(content)
        }

        return AnyView(
            content
                .colorEffect(
                    Shader(
                        function: CompatibilityPaletteShader.function,
                        arguments: GameplayScreenEffectConfiguration
                            .fieldPaletteComponents(for: palette)
                            .map(Shader.Argument.float)
                    )
                )
                .drawingGroup()
        )
    }
}

private struct FieldScreenEffectModifier: ViewModifier {
    let displayStyle: FieldDisplayStyle
    let displayScale: CGFloat
    let fieldPalette: FieldPaletteManifest?
    let hdrBoost: Float

    func body(content: Content) -> some View {
        let configuration = GameplayScreenEffectConfiguration(
            displayStyle: displayStyle,
            displayScale: displayScale,
            hdrBoost: hdrBoost,
            fieldPalette: fieldPalette
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
    @State private var transitionState = BattleIntroTransitionState()

    func body(content: Content) -> some View {
        let configuration = GameplayScreenEffectConfiguration(
            displayStyle: displayStyle,
            displayScale: displayScale,
            hdrBoost: hdrBoost,
            presentation: presentation,
            introProgress: transitionState.displayedIntroProgress,
            introAmount: transitionState.displayedIntroAmount
        )

        content
            .layerEffect(
                Shader(
                    function: BattleScreenShader.function,
                    arguments: configuration.battleArguments
                ),
                maxSampleOffset: .init(width: BattleIntroTransitionDriver.maxSampleOffset(displayScale: displayScale), height: BattleIntroTransitionDriver.maxSampleOffset(displayScale: displayScale))
            )
            .drawingGroup()
            .onAppear {
                applyTransitionSync(animated: false)
            }
            .onChange(of: presentation.transitionStyle) { _, _ in
                applyTransitionSync(animated: true)
            }
            .onChange(of: presentation.stage) { _, _ in
                applyTransitionSync(animated: true)
            }
            .onChange(of: presentation.revision) { _, _ in
                applyTransitionSync(animated: true)
            }
    }

    private func applyTransitionSync(animated: Bool) {
        let sync = BattleIntroTransitionDriver.sync(
            presentation: presentation,
            previousState: transitionState,
            animated: animated
        )
        transitionState = sync.immediateState

        guard let animatedState = sync.animatedState else {
            return
        }
        let animation = BattleIntroTransitionDriver.animationSpec(for: presentation).animation
        DispatchQueue.main.async {
            withAnimation(animation) {
                transitionState = animatedState
            }
        }
    }
}

private struct BattleTransitionEffectModifier: ViewModifier {
    let displayStyle: FieldDisplayStyle
    let displayScale: CGFloat
    let presentation: BattlePresentationTelemetry
    @State private var transitionState = BattleIntroTransitionState()

    func body(content: Content) -> some View {
        let configuration = GameplayScreenEffectConfiguration(
            displayStyle: displayStyle,
            displayScale: displayScale,
            hdrBoost: 0,
            presentation: presentation,
            introProgress: transitionState.displayedIntroProgress,
            introAmount: transitionState.displayedIntroAmount
        )

        return content
            .layerEffect(
                Shader(
                    function: BattleTransitionScreenShader.function,
                    arguments: [
                        .float(configuration.viewportWidth),
                        .float(configuration.viewportHeight),
                        .float(configuration.preset),
                        .float(configuration.introStyle),
                        .float(transitionState.displayedIntroProgress),
                        .float(transitionState.displayedIntroAmount),
                    ]
                ),
                maxSampleOffset: .init(width: BattleIntroTransitionDriver.maxSampleOffset(displayScale: displayScale), height: BattleIntroTransitionDriver.maxSampleOffset(displayScale: displayScale))
            )
            .drawingGroup()
            .onAppear {
                applyTransitionSync(animated: false)
            }
            .onChange(of: presentation.transitionStyle) { _, _ in
                applyTransitionSync(animated: true)
            }
            .onChange(of: presentation.stage) { _, _ in
                applyTransitionSync(animated: true)
            }
            .onChange(of: presentation.revision) { _, _ in
                applyTransitionSync(animated: true)
            }
    }

    private func applyTransitionSync(animated: Bool) {
        let sync = BattleIntroTransitionDriver.sync(
            presentation: presentation,
            previousState: transitionState,
            animated: animated
        )
        transitionState = sync.immediateState

        guard let animatedState = sync.animatedState else {
            return
        }
        let animation = BattleIntroTransitionDriver.animationSpec(for: presentation).animation
        DispatchQueue.main.async {
            withAnimation(animation) {
                transitionState = animatedState
            }
        }
    }
}
