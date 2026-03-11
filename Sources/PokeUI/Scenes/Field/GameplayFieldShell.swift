import SwiftUI

public enum GameplayFooterPlacement {
    case insideScreen
    case belowScreen
}

public struct GameplayShell<Stage: View>: View {
    private let sidebarMode: GameplaySidebarMode
    private let onSidebarAction: ((String) -> Void)?
    @Binding private var fieldDisplayStyle: FieldDisplayStyle
    private let stage: Stage

    public init(
        sidebarMode: GameplaySidebarMode,
        onSidebarAction: ((String) -> Void)? = nil,
        fieldDisplayStyle: Binding<FieldDisplayStyle>,
        @ViewBuilder stage: () -> Stage
    ) {
        self.sidebarMode = sidebarMode
        self.onSidebarAction = onSidebarAction
        _fieldDisplayStyle = fieldDisplayStyle
        self.stage = stage()
    }

    public var body: some View {
        HStack(alignment: .top, spacing: GameplayFieldMetrics.interColumnSpacing) {
            stage
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            GameplaySidebar(
                mode: sidebarMode,
                onSidebarAction: onSidebarAction,
                fieldDisplayStyle: $fieldDisplayStyle
            )
            .frame(width: GameplayFieldMetrics.sidebarWidth)
        }
        .padding(GameplayFieldMetrics.outerPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

public struct GameplayShellStage<ScreenContent: View, Footer: View, OverlayContent: View>: View {
    private let screenContent: ScreenContent
    private let footer: Footer
    private let overlayContent: OverlayContent
    private let footerPlacement: GameplayFooterPlacement

    public init(
        footerPlacement: GameplayFooterPlacement = .insideScreen,
        @ViewBuilder screenContent: () -> ScreenContent,
        @ViewBuilder footer: () -> Footer,
        @ViewBuilder overlayContent: () -> OverlayContent
    ) {
        self.footerPlacement = footerPlacement
        self.screenContent = screenContent()
        self.footer = footer()
        self.overlayContent = overlayContent()
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            GameplayDisplayShell {
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
                .fill(
                    LinearGradient(
                        colors: [
                            FieldRetroPalette.shellBackdrop,
                            FieldRetroPalette.stageInner,
                            FieldRetroPalette.stageMiddle.opacity(0.86),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.5),
                                    Color.clear,
                                ],
                                center: .topLeading,
                                startRadius: 20,
                                endRadius: 280
                            )
                        )
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    FieldRetroPalette.shellBackdropShadow.opacity(0.06),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
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
        .shadow(color: FieldRetroPalette.shellBackdropShadow.opacity(0.16), radius: 24, y: 12)
    }
}

public struct FieldMapStage<MapContent: View, Footer: View, OverlayContent: View>: View {
    private let mapContent: MapContent
    private let footer: Footer
    private let overlayContent: OverlayContent

    public init(
        @ViewBuilder mapContent: () -> MapContent,
        @ViewBuilder footer: () -> Footer,
        @ViewBuilder overlayContent: () -> OverlayContent
    ) {
        self.mapContent = mapContent()
        self.footer = footer()
        self.overlayContent = overlayContent()
    }

    public var body: some View {
        GameplayShellStage {
            mapContent
        } footer: {
            footer
        } overlayContent: {
            overlayContent
        }
    }
}

public struct BattleViewportStage<Content: View, Footer: View>: View {
    private let content: Content
    private let footer: Footer

    public init(@ViewBuilder content: () -> Content, @ViewBuilder footer: () -> Footer) {
        self.content = content()
        self.footer = footer()
    }

    public var body: some View {
        GameplayShellStage {
            content
        } footer: {
            footer
        } overlayContent: {
            EmptyView()
        }
    }
}

private struct GameplayDisplayShell<Content: View, Footer: View>: View {
    private let content: Content
    private let footer: Footer
    private let footerPlacement: GameplayFooterPlacement

    init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer,
        footerPlacement: @escaping () -> GameplayFooterPlacement
    ) {
        self.content = content()
        self.footer = footer()
        self.footerPlacement = footerPlacement()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GameplayScreenWell {
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
            .foregroundStyle(Color(red: 0.17, green: 0.22, blue: 0.68))
            .padding(.leading, 10)
        }
    }
}

private struct GameplayScreenWell<Content: View, Footer: View>: View {
    private let content: Content
    private let footer: Footer
    private let footerPlacement: GameplayFooterPlacement

    init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer,
        footerPlacement: @escaping () -> GameplayFooterPlacement
    ) {
        self.content = content()
        self.footer = footer()
        self.footerPlacement = footerPlacement()
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
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
                    .fill(Color(red: 0.36, green: 0.37, blue: 0.43))
                    .overlay {
                        wellShape
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.08),
                                        Color.clear,
                                        Color.black.opacity(0.12),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
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
                        .foregroundStyle(Color.white.opacity(0.78))
                        .fixedSize()

                    DMGAccentBarStack()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, headerTopPadding)
                .padding(.horizontal, 36)

                VStack(spacing: 6) {
                    Circle()
                        .fill(Color(red: 0.96, green: 0.23, blue: 0.2))
                        .frame(width: 10, height: 10)
                        .shadow(color: Color.red.opacity(0.35), radius: 6)
                    Text("BATTERY")
                        .font(
                            .system(
                                size: max(7, size.width * 0.013), weight: .bold, design: .rounded)
                        )
                        .foregroundStyle(Color.white.opacity(0.74))
                }
                .position(x: size.width * 0.07, y: screenRect.midY)

                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(Color(red: 0.18, green: 0.28, blue: 0.08), lineWidth: 1)
                    .frame(width: screenRect.width, height: screenRect.height)
                    .position(x: screenRect.midX, y: screenRect.midY)

                content
                    .frame(width: screenRect.width, height: screenRect.height)
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
            DMGAccentBar(color: Color(red: 0.42, green: 0.07, blue: 0.27))
            DMGAccentBar(color: Color(red: 0.16, green: 0.17, blue: 0.55))
        }
        .frame(minWidth: 56, maxWidth: .infinity)
    }
}
