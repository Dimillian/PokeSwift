import SwiftUI
import PokeRender

public enum GameplayFooterPlacement {
    case insideScreen
    case belowScreen
}

public struct GameplayShell<Stage: View>: View {
    @Environment(\.pokeAppearanceMode) private var appearanceMode
    @Environment(\.pokeGameBoyShellStyle) private var gameBoyShellStyle
    private let sidebarMode: GameplaySidebarMode
    private let onSidebarAction: ((String) -> Void)?
    private let onPartyRowSelected: ((Int) -> Void)?
    @Binding private var fieldDisplayStyle: FieldDisplayStyle
    @Binding private var sidebarExpansionState: GameplaySidebarExpansionState
    private let stage: Stage

    public init(
        sidebarMode: GameplaySidebarMode,
        onSidebarAction: ((String) -> Void)? = nil,
        onPartyRowSelected: ((Int) -> Void)? = nil,
        fieldDisplayStyle: Binding<FieldDisplayStyle>,
        sidebarExpansionState: Binding<GameplaySidebarExpansionState>,
        @ViewBuilder stage: () -> Stage
    ) {
        self.sidebarMode = sidebarMode
        self.onSidebarAction = onSidebarAction
        self.onPartyRowSelected = onPartyRowSelected
        _fieldDisplayStyle = fieldDisplayStyle
        _sidebarExpansionState = sidebarExpansionState
        self.stage = stage()
    }

    public var body: some View {
        HStack(alignment: .top, spacing: GameplayFieldMetrics.interColumnSpacing) {
            stage
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            GameplaySidebar(
                mode: sidebarMode,
                onSidebarAction: onSidebarAction,
                onPartyRowSelected: onPartyRowSelected,
                fieldDisplayStyle: $fieldDisplayStyle,
                expansionState: $sidebarExpansionState
            )
            .frame(width: GameplayFieldMetrics.sidebarWidth)
        }
        .padding(GameplayFieldMetrics.outerPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .id(themeRefreshKey)
    }

    private var themeRefreshKey: String {
        "\(appearanceMode.rawValue)-\(gameBoyShellStyle.rawValue)"
    }
}

public struct GameplayShellStage<ScreenContent: View, Footer: View, OverlayContent: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.pokeAppearanceMode) private var appearanceMode
    @Environment(\.pokeGameBoyShellStyle) private var gameBoyShellStyle
    private let screenContent: ScreenContent
    private let footer: Footer
    private let overlayContent: OverlayContent
    private let footerPlacement: GameplayFooterPlacement
    private let screenDisplayStyle: FieldDisplayStyle

    public init(
        screenDisplayStyle: FieldDisplayStyle = .defaultGameplayStyle,
        footerPlacement: GameplayFooterPlacement = .insideScreen,
        @ViewBuilder screenContent: () -> ScreenContent,
        @ViewBuilder footer: () -> Footer,
        @ViewBuilder overlayContent: () -> OverlayContent
    ) {
        self.screenDisplayStyle = screenDisplayStyle
        self.footerPlacement = footerPlacement
        self.screenContent = screenContent()
        self.footer = footer()
        self.overlayContent = overlayContent()
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            GameplayDisplayShell(screenDisplayStyle: screenDisplayStyle) {
                screenContent
            } footer: {
                footer
            } footerPlacement: {
                footerPlacement
            }
            .frame(maxWidth: 920)
            .padding(.top, 24)
            .padding(.leading, 28)
            .padding(.trailing, 48)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            overlayContent
                .frame(maxWidth: 420, alignment: .topTrailing)
                .padding(.top, 52)
                .padding(.trailing, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(shellPalette.backdrop.color)
        )
        .glassEffect(
            .regular.tint(FieldRetroPalette.glassTint),
            in: RoundedRectangle(cornerRadius: 34, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .stroke(FieldRetroPalette.outline.opacity(0.16), lineWidth: 1)
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(.white.opacity(0.3), lineWidth: 1)
                        .padding(8)
                }
        }
        .shadow(color: shellPalette.shadow.color.opacity(0.16), radius: 24, y: 12)
        .animation(.spring(response: 0.42, dampingFraction: 0.86), value: shellPalette)
    }

    private var shellPalette: GameBoyShellPalette {
        FieldRetroPalette.gameBoyShellPalette(
            shellStyle: gameBoyShellStyle,
            appearanceMode: appearanceMode,
            colorScheme: colorScheme
        )
    }
}

public struct FieldMapStage<MapContent: View, Footer: View, OverlayContent: View>: View {
    private let mapContent: MapContent
    private let footer: Footer
    private let overlayContent: OverlayContent
    private let screenDisplayStyle: FieldDisplayStyle

    public init(
        screenDisplayStyle: FieldDisplayStyle = .defaultGameplayStyle,
        @ViewBuilder mapContent: () -> MapContent,
        @ViewBuilder footer: () -> Footer,
        @ViewBuilder overlayContent: () -> OverlayContent
    ) {
        self.screenDisplayStyle = screenDisplayStyle
        self.mapContent = mapContent()
        self.footer = footer()
        self.overlayContent = overlayContent()
    }

    public var body: some View {
        GameplayShellStage(screenDisplayStyle: screenDisplayStyle) {
            mapContent
        } footer: {
            footer
        } overlayContent: {
            overlayContent
        }
    }
}

public struct BattleViewportStage<Content: View, Footer: View, OverlayContent: View>: View {
    private let content: Content
    private let footer: Footer
    private let overlayContent: OverlayContent
    private let screenDisplayStyle: FieldDisplayStyle

    public init(
        screenDisplayStyle: FieldDisplayStyle = .defaultGameplayStyle,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer,
        @ViewBuilder overlayContent: () -> OverlayContent
    ) {
        self.screenDisplayStyle = screenDisplayStyle
        self.content = content()
        self.footer = footer()
        self.overlayContent = overlayContent()
    }

    public var body: some View {
        GameplayShellStage(screenDisplayStyle: screenDisplayStyle) {
            content
        } footer: {
            footer
        } overlayContent: {
            overlayContent
        }
    }
}

private struct GameplayDisplayShell<Content: View, Footer: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.pokeAppearanceMode) private var appearanceMode
    @Environment(\.pokeGameBoyShellStyle) private var gameBoyShellStyle
    private let screenDisplayStyle: FieldDisplayStyle
    private let content: Content
    private let footer: Footer
    private let footerPlacement: GameplayFooterPlacement

    init(
        screenDisplayStyle: FieldDisplayStyle,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer,
        footerPlacement: @escaping () -> GameplayFooterPlacement
    ) {
        self.screenDisplayStyle = screenDisplayStyle
        self.content = content()
        self.footer = footer()
        self.footerPlacement = footerPlacement()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GameplayScreenWell(displayStyle: screenDisplayStyle) {
                content
            } footer: {
                footer
            } footerPlacement: {
                footerPlacement
            }
            .frame(maxWidth: 920)

            if footerPlacement == .belowScreen {
                footer
                    .frame(maxWidth: 760, alignment: .leading)
                    .padding(.leading, 10)
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Nintendo")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .tracking(-0.3)
                Text("GAME BOY")
                    .font(.system(size: 30, weight: .light, design: .rounded))
                    .tracking(0.4)
            }
            .foregroundStyle(shellChrome.wordmark.color)
            .padding(.leading, 10)
            .animation(.spring(response: 0.42, dampingFraction: 0.86), value: shellChrome)
        }
    }

    private var shellChrome: GameBoyShellChromePalette {
        PokeThemePalette.gameBoyShellChromePalette(
            shellStyle: gameBoyShellStyle,
            appearanceMode: appearanceMode,
            colorScheme: colorScheme
        )
    }
}

private struct GameplayScreenWell<Content: View, Footer: View>: View {
    @Environment(\.pokeAppearanceMode) private var appearanceMode
    @Environment(\.pokeGameplayHDREnabled) private var gameplayHDREnabled
    @Environment(\.colorScheme) private var colorScheme

    private let displayStyle: FieldDisplayStyle
    private let content: Content
    private let footer: Footer
    private let footerPlacement: GameplayFooterPlacement

    init(
        displayStyle: FieldDisplayStyle,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer,
        footerPlacement: @escaping () -> GameplayFooterPlacement
    ) {
        self.displayStyle = displayStyle
        self.content = content()
        self.footer = footer()
        self.footerPlacement = footerPlacement()
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let resolvedPalette = PokeThemePalette.resolve(for: appearanceMode.resolved(for: colorScheme))
            let glowPalette = PokeThemePalette.gameplayScreenGlowPalette(
                displayStyle: displayStyle,
                appearanceMode: appearanceMode,
                colorScheme: colorScheme
            )
            let hdrProfile = PokeThemePalette.gameplayHDRProfile(
                appearanceMode: appearanceMode,
                colorScheme: colorScheme,
                isEnabled: gameplayHDREnabled
            )
            let headerTopPadding: CGFloat = 12
            let headerLabelHeight = max(12, size.width * 0.015)
            let screenVerticalGap = max(8, size.height * 0.012)
            let screenSideInset = max(20, size.width * 0.05)
            let screenTopInset = headerTopPadding + headerLabelHeight + screenVerticalGap
            let screenBottomInset = screenVerticalGap
            let availableScreenWidth = max(40, size.width - (screenSideInset * 2))
            let availableScreenHeight = max(40, size.height - screenTopInset - screenBottomInset)
            let lcdScale = max(
                1,
                floor(
                    min(
                        availableScreenWidth / CGFloat(FieldSceneRenderer.viewportPixelSize.width),
                        availableScreenHeight / CGFloat(FieldSceneRenderer.viewportPixelSize.height)
                    )
                )
            )
            let screenWidth = CGFloat(FieldSceneRenderer.viewportPixelSize.width) * lcdScale
            let screenHeight = CGFloat(FieldSceneRenderer.viewportPixelSize.height) * lcdScale
            let screenOrigin = CGPoint(
                x: (size.width - screenWidth) / 2,
                y: screenTopInset + ((availableScreenHeight - screenHeight) / 2)
            )
            let screenRect = CGRect(
                origin: screenOrigin, size: CGSize(width: screenWidth, height: screenHeight))
            let outerGlowPadding = max(14, lcdScale * 3)
            let innerGlowPadding = max(6, lcdScale * 1.1)
            let wellShape = UnevenRoundedRectangle(
                cornerRadii: .init(
                    topLeading: 22,
                    bottomLeading: 16,
                    bottomTrailing: 56,
                    topTrailing: 16
                ),
                style: .continuous
            )

            ZStack(alignment: .topLeading) {
                wellShape
                    .fill(PokeThemePalette.screenWellFill)

                if hdrProfile.rendersBloom {
                    ZStack {
                        RoundedRectangle(cornerRadius: max(14, lcdScale * 3), style: .continuous)
                            .fill(
                                glowPalette.outer.hdrColor(
                                    linearExposure: hdrProfile.outerGlowExposure
                                )
                            )
                            .frame(
                                width: screenRect.width + (outerGlowPadding * CGFloat(hdrProfile.outerGlowPaddingMultiplier) * 2),
                                height: screenRect.height + (outerGlowPadding * CGFloat(hdrProfile.outerGlowPaddingMultiplier) * 2)
                            )
                            .blur(radius: max(12, lcdScale * CGFloat(hdrProfile.outerGlowBlurMultiplier)))
                            .opacity(hdrProfile.outerGlowOpacity)

                        RoundedRectangle(cornerRadius: max(10, lcdScale * 2.4), style: .continuous)
                            .fill(
                                glowPalette.inner.hdrColor(
                                    linearExposure: hdrProfile.innerGlowExposure
                                )
                            )
                            .frame(
                                width: screenRect.width + (innerGlowPadding * CGFloat(hdrProfile.innerGlowPaddingMultiplier) * 2),
                                height: screenRect.height + (innerGlowPadding * CGFloat(hdrProfile.innerGlowPaddingMultiplier) * 2)
                            )
                            .blur(radius: max(6, lcdScale * CGFloat(hdrProfile.innerGlowBlurMultiplier)))
                            .opacity(hdrProfile.innerGlowOpacity)
                    }
                    .blendMode(.plusLighter)
                    .pokeExtendedDynamicRange(
                        preferredDynamicRange: .high,
                        contentsHeadroom: hdrProfile.glowHeadroom
                    )
                    .position(x: screenRect.midX, y: screenRect.midY)
                }

                HStack(spacing: 12) {
                    DMGAccentBarStack()
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    Text("DOT MATRIX WITH STEREO SOUND")
                        .font(
                            .system(
                                size: max(8, size.width * 0.015), weight: .semibold,
                                design: .rounded)
                        )
                        .tracking(0.22)
                        .foregroundStyle(PokeThemePalette.screenLabel)
                        .fixedSize()

                    DMGAccentBarStack()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, headerTopPadding)
                .padding(.horizontal, 36)

                VStack(spacing: 6) {
                    Circle()
                        .fill(
                            hdrProfile.isEnabled
                                ? resolvedPalette.batteryIndicator.hdrColor(linearExposure: hdrProfile.batteryExposure)
                                : PokeThemePalette.batteryIndicator
                        )
                        .frame(width: 10, height: 10)
                        .shadow(
                            color: (
                                hdrProfile.isEnabled
                                    ? resolvedPalette.batteryIndicator.hdrColor(linearExposure: hdrProfile.batteryShadowExposure)
                                    : PokeThemePalette.batteryIndicator
                            ).opacity(hdrProfile.isEnabled ? hdrProfile.batteryShadowOpacity : 0.35),
                            radius: 6
                        )
                        .pokeExtendedDynamicRange(
                            enabled: hdrProfile.isEnabled,
                            preferredDynamicRange: .high,
                            contentsHeadroom: hdrProfile.batteryHeadroom
                        )
                    Text("BATTERY")
                        .font(
                            .system(
                                size: max(7, size.width * 0.013), weight: .bold, design: .rounded)
                        )
                        .foregroundStyle(PokeThemePalette.screenLabel.opacity(0.95))
                }
                .position(x: size.width * 0.07, y: screenRect.midY)

                content
                    .frame(width: screenRect.width, height: screenRect.height)
                    .pokeExtendedDynamicRange(
                        enabled: hdrProfile.isEnabled,
                        preferredDynamicRange: .high,
                        contentsHeadroom: hdrProfile.contentHeadroom
                    )
                    .position(x: screenRect.midX, y: screenRect.midY)

                if footerPlacement == .insideScreen {
                    ZStack(alignment: .bottom) {
                        footer
                            .frame(
                                width: screenRect.width - (max(10, lcdScale * 2) * 2),
                                alignment: .leading
                            )
                            .padding(.horizontal, max(10, lcdScale * 2))
                            .padding(.bottom, max(10, lcdScale * 2))
                    }
                    .frame(width: screenRect.width, height: screenRect.height, alignment: .bottom)
                    .position(x: screenRect.midX, y: screenRect.midY)
                }
            }
        }
        .aspectRatio(1.14, contentMode: .fit)
    }
}

private struct DMGAccentBar: View {
    let color: Color

    var body: some View {
        Capsule(style: .continuous)
            .fill(color)
            .frame(maxWidth: .infinity)
            .frame(height: 4)
    }
}

private struct DMGAccentBarStack: View {
    var body: some View {
        VStack(spacing: 4) {
            DMGAccentBar(color: PokeThemePalette.accentBarMagenta)
            DMGAccentBar(color: PokeThemePalette.accentBarBlue)
        }
        .frame(minWidth: 56, maxWidth: .infinity)
    }
}
