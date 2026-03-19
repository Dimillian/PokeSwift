import SwiftUI
import PokeDataModel
import PokeRender
import PokeUI

struct TitlePresentationProps {
    let logoURL: URL?
    let playerURL: URL?
    let wordmarkURL: URL?
    let pokemonSpriteURL: URL?
    let pokemonDisplayName: String
    let logoYOffset: Int
    let pokemonOffsetX: Int
}

struct TitleMenuSceneProps {
    let presentation: TitlePresentationProps
    let entries: [TitleMenuEntryState]
    let saveMetadata: GameSaveMetadata?
    let focusedIndex: Int
}

struct TitleOptionsSceneProps {
    let focusedRow: Int
    let textSpeed: TextSpeed
    let battleAnimation: BattleAnimation
    let battleStyle: BattleStyle
}

struct SplashView: View {
    let rootURL: URL

    var body: some View {
        GameBoyScreen {
            VStack(spacing: 20) {
                PixelAssetView(url: assetURL("Assets/splash/falling_star.png"), label: "Falling Star")
                    .frame(width: 96, height: 96)
                PixelAssetView(url: assetURL("Assets/splash/gamefreak_logo.png"), label: "Game Freak")
                    .frame(width: 320, height: 160)
                PixelAssetView(url: assetURL("Assets/splash/gamefreak_presents.png"), label: "Game Freak Presents")
                    .frame(width: 320, height: 80)
                PixelAssetView(url: assetURL("Assets/splash/copyright.png"), label: "Copyright")
                    .frame(width: 360, height: 80)
            }
            .padding(40)
        }
    }

    private func assetURL(_ path: String) -> URL {
        rootURL.appendingPathComponent(path)
    }
}

struct TitleAttractView: View {
    let presentation: TitlePresentationProps

    var body: some View {
        GameBoyScreen {
            TitleScreenCanvas(
                presentation: presentation,
                entries: [],
                saveMetadata: nil,
                focusedIndex: nil
            )
        }
    }
}

struct TitleMenuScene: View {
    let props: TitleMenuSceneProps

    var body: some View {
        GameBoyScreen {
            TitleScreenCanvas(
                presentation: props.presentation,
                entries: props.entries,
                saveMetadata: props.saveMetadata,
                focusedIndex: props.focusedIndex
            )
        }
    }
}

private struct TitleScreenCanvas: View {
    let presentation: TitlePresentationProps
    let entries: [TitleMenuEntryState]
    let saveMetadata: GameSaveMetadata?
    let focusedIndex: Int?

    var body: some View {
        GeometryReader { geometry in
            let screenScale = min(geometry.size.width / 160, geometry.size.height / 144) * 0.88
            let stageSize = CGSize(width: 160 * screenScale, height: 144 * screenScale)

            ZStack(alignment: .topLeading) {
                if let logoURL = presentation.logoURL {
                    pixelAsset(
                        url: logoURL,
                        label: "Pokemon Logo",
                        originX: 16,
                        originY: max(0, 64 + presentation.logoYOffset),
                        width: 128,
                        height: 56,
                        scale: screenScale
                    )
                }

                GameBoyPixelText(
                    "SWIFT VERSION",
                    scale: max(1, screenScale * 0.9),
                    color: .black,
                    fallbackFont: .system(size: 11 * max(1, screenScale * 0.75), weight: .bold, design: .monospaced)
                )
                .position(
                    x: 80 * screenScale,
                    y: 66 * screenScale
                )

                if let playerURL = presentation.playerURL {
                    pixelAsset(
                        url: playerURL,
                        label: "Red",
                        originX: 18,
                        originY: 72,
                        width: 40,
                        height: 56,
                        scale: screenScale
                    )
                }

                if let pokemonSpriteURL = presentation.pokemonSpriteURL {
                    pixelAsset(
                        url: pokemonSpriteURL,
                        label: presentation.pokemonDisplayName,
                        originX: 92 + presentation.pokemonOffsetX,
                        originY: 70,
                        width: 56,
                        height: 56,
                        scale: screenScale,
                        whiteIsTransparent: true
                    )
                }

                if let wordmarkURL = presentation.wordmarkURL {
                    pixelAsset(
                        url: wordmarkURL,
                        label: "Game Freak Inc",
                        originX: 44,
                        originY: 134,
                        width: 72,
                        height: 8,
                        scale: screenScale
                    )
                }

                if let focusedIndex {
                    TitleMenuOverlay(entries: entries, focusedIndex: focusedIndex, saveMetadata: saveMetadata)
                        .frame(width: 152 * screenScale)
                        .position(
                            x: 80 * screenScale,
                            y: 106 * screenScale
                        )
                } else {
                    TitleAttractPrompt(screenScale: screenScale)
                        .position(
                            x: 80 * screenScale,
                            y: 143 * screenScale
                        )
                }
            }
            .frame(width: stageSize.width, height: stageSize.height)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            .drawingGroup(opaque: false)
        }
    }

    private func pixelAsset(
        url: URL,
        label: String,
        originX: Int,
        originY: Int,
        width: Int,
        height: Int,
        scale: CGFloat,
        whiteIsTransparent: Bool = false
    ) -> some View {
        PixelAssetView(url: url, label: label, whiteIsTransparent: whiteIsTransparent)
            .frame(width: CGFloat(width) * scale, height: CGFloat(height) * scale)
            .position(
                x: (CGFloat(originX) + CGFloat(width) / 2) * scale,
                y: (CGFloat(originY) + CGFloat(height) / 2) * scale
            )
    }
}

private struct TitleMenuOverlay: View {
    let entries: [TitleMenuEntryState]
    let focusedIndex: Int
    let saveMetadata: GameSaveMetadata?

    var body: some View {
        GlassEffectContainer(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                TitleMenuPanel(entries: entries, focusedIndex: focusedIndex)

                if let saveMetadata {
                    TitleSaveSummaryCard(metadata: saveMetadata)
                }
            }
        }
    }
}

private struct TitleAttractPrompt: View {
    let screenScale: CGFloat

    var body: some View {
        GameBoyPixelText(
            "PRESS SPACE",
            scale: max(0.7, screenScale * 0.38),
            color: .black,
            fallbackFont: .system(size: 7 * max(1, screenScale * 0.45), weight: .bold, design: .monospaced)
        )
    }
}

private struct TitleSaveSummaryCard: View {
    @Environment(\.pokeAppearanceMode) private var appearanceMode
    @Environment(\.pokeGameBoyShellStyle) private var gameBoyShellStyle
    @Environment(\.colorScheme) private var colorScheme
    let metadata: GameSaveMetadata
    private let cardShape = RoundedRectangle(cornerRadius: 24, style: .continuous)

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Continue Save")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundStyle(palette.secondaryText.color.opacity(0.92))

                titleRow(label: "Player", value: metadata.playerName)
                titleRow(label: "Map", value: metadata.locationName)
                titleRow(label: "Badges", value: "\(metadata.badgeCount)")
                titleRow(label: "Time", value: formatPlayTime(metadata.playTimeSeconds))

                Text("Updated \(metadata.savedAt)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(palette.tertiaryText.color)
                    .padding(.top, 4)
            }
            .padding(18)
        }
        .background(
            LinearGradient(
                colors: [
                    palette.panelBackground.color.opacity(0.84),
                    palette.panelBackground.color.opacity(0.62),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: cardShape
        )
        .overlay {
            cardShape
                .stroke(.white.opacity(0.22), lineWidth: 1)
                .overlay {
                    cardShape
                        .inset(by: 5)
                        .stroke(palette.panelOutline.color.opacity(0.14), lineWidth: 1)
                }
        }
        .glassEffect(
            .regular.tint(palette.panelGlassTint.color.opacity(0.8)),
            in: cardShape
        )
        .shadow(color: palette.dialogueShadow.color.opacity(0.16), radius: 18, y: 10)
    }

    private func titleRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(palette.tertiaryText.color)
            Spacer(minLength: 8)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(palette.primaryText.color)
                .lineLimit(1)
        }
    }

    private func formatPlayTime(_ seconds: Int) -> String {
        let hours = max(0, seconds) / 3600
        let minutes = (max(0, seconds) % 3600) / 60
        return String(format: "%03d:%02d", hours, minutes)
    }

    private var palette: PokeThemeResolvedPalette {
        PokeThemePalette.resolve(
            for: appearanceMode,
            shellStyle: gameBoyShellStyle,
            colorScheme: colorScheme
        )
    }
}

struct TitleOptionsScene: View {
    @Environment(\.pokeAppearanceMode) private var appearanceMode
    @Environment(\.pokeGameBoyShellStyle) private var gameBoyShellStyle
    @Environment(\.colorScheme) private var colorScheme
    let props: TitleOptionsSceneProps

    @State private var cursorVisible = true

    private let panelShape = RoundedRectangle(cornerRadius: 14, style: .continuous)

    var body: some View {
        GameBoyScreen {
            VStack(spacing: 0) {
                OptionsSection(
                    title: "TEXT SPEED",
                    options: TextSpeed.allCases.map(\.label),
                    selectedIndex: TextSpeed.allCases.firstIndex(of: props.textSpeed) ?? 1,
                    isFocused: props.focusedRow == 0,
                    cursorVisible: cursorVisible
                )

                OptionsSectionBorder()

                OptionsSection(
                    title: "BATTLE ANIMATION",
                    options: BattleAnimation.allCases.map(\.label),
                    selectedIndex: BattleAnimation.allCases.firstIndex(of: props.battleAnimation) ?? 0,
                    isFocused: props.focusedRow == 1,
                    cursorVisible: cursorVisible
                )

                OptionsSectionBorder()

                OptionsSection(
                    title: "BATTLE STYLE",
                    options: BattleStyle.allCases.map(\.label),
                    selectedIndex: BattleStyle.allCases.firstIndex(of: props.battleStyle) ?? 0,
                    isFocused: props.focusedRow == 2,
                    cursorVisible: cursorVisible
                )

                OptionsSectionBorder()

                OptionsCancelRow(isFocused: props.focusedRow == 3, cursorVisible: cursorVisible)
            }
            .padding(20)
            .background(palette.dialoguePaper.color, in: panelShape)
            .overlay {
                panelShape.stroke(palette.dialogueBorder.color, lineWidth: 3)
            }
            .overlay {
                panelShape.inset(by: 5).stroke(palette.dialogueBorder.color, lineWidth: 1.5)
            }
            .frame(width: 500)
            .shadow(color: palette.dialogueShadow.color, radius: 12, y: 6)
        }
        .task {
            while Task.isCancelled == false {
                try? await Task.sleep(nanoseconds: 320_000_000)
                if Task.isCancelled { break }
                cursorVisible.toggle()
            }
        }
        .onChange(of: props.focusedRow) { _, _ in
            cursorVisible = true
        }
    }

    private var palette: PokeThemeResolvedPalette {
        PokeThemePalette.resolve(
            for: appearanceMode,
            shellStyle: gameBoyShellStyle,
            colorScheme: colorScheme
        )
    }
}

private struct OptionsSection: View {
    @Environment(\.pokeAppearanceMode) private var appearanceMode
    @Environment(\.pokeGameBoyShellStyle) private var gameBoyShellStyle
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let options: [String]
    let selectedIndex: Int
    let isFocused: Bool
    let cursorVisible: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GameBoyPixelText(title, scale: 2.5, color: ink)
                .padding(.leading, 10)
                .padding(.top, 12)

            HStack(spacing: 24) {
                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                    HStack(spacing: 2) {
                        GameBoyPixelText(">", scale: 2.5, color: ink)
                            .opacity(cursorOpacity(for: index))
                        GameBoyPixelText(option, scale: 2.5, color: ink)
                            .opacity(index == selectedIndex ? 1 : 0.4)
                    }
                }
            }
            .padding(.leading, 24)
            .padding(.bottom, 12)
        }
    }

    private func cursorOpacity(for index: Int) -> Double {
        guard index == selectedIndex else { return 0 }
        if isFocused {
            return cursorVisible ? 1 : 0
        }
        return 1
    }

    private var palette: PokeThemeResolvedPalette {
        PokeThemePalette.resolve(
            for: appearanceMode,
            shellStyle: gameBoyShellStyle,
            colorScheme: colorScheme
        )
    }

    private var ink: Color {
        palette.primaryText.color
    }
}

private struct OptionsSectionBorder: View {
    var body: some View {
        VStack(spacing: 2) {
            Rectangle().fill(.black)
            Rectangle().fill(.black)
        }
        .frame(height: 5)
        .padding(.horizontal, 6)
    }
}

private struct OptionsCancelRow: View {
    let isFocused: Bool
    let cursorVisible: Bool

    private let ink: Color = .black

    var body: some View {
        HStack(spacing: 2) {
            GameBoyPixelText(">", scale: 2.5, color: ink)
                .opacity(isFocused ? (cursorVisible ? 1 : 0) : 0)
            GameBoyPixelText("CANCEL", scale: 2.5, color: ink)
        }
        .padding(.leading, 24)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
