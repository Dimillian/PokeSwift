import SwiftUI
import PokeDataModel
import PokeRender
import PokeUI

struct TitleMenuSceneProps {
    let rootURL: URL
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
    let rootURL: URL

    var body: some View {
        GameBoyScreen {
            TitleAttractContent(rootURL: rootURL)
        }
    }
}

struct TitleAttractContent: View {
    @Environment(\.pokeAppearanceMode) private var appearanceMode
    @Environment(\.pokeGameBoyShellStyle) private var gameBoyShellStyle
    @Environment(\.colorScheme) private var colorScheme
    let rootURL: URL

    var body: some View {
        VStack(spacing: 18) {
            PixelAssetView(url: assetURL("Assets/title/pokemon_logo.png"), label: "Pokemon Logo")
                .frame(width: 540, height: 220)
            HStack(spacing: 24) {
                PixelAssetView(url: assetURL("Assets/title/player.png"), label: "Red")
                    .frame(width: 200, height: 200)
                PlainWhitePanel {
                    VStack(spacing: 18) {
                        GameBoyPixelText("Swift Version", scale: 2, color: palette.primaryText.color)
                            .frame(width: 220, height: 90)
                        Text("Press Return or Space to Start")
                            .font(.system(.title3, design: .monospaced))
                            .foregroundStyle(palette.primaryText.color)
                        Text("Z confirms, X cancels, arrows navigate")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(palette.secondaryText.color)
                    }
                }
            }
            PixelAssetView(url: assetURL("Assets/title/gamefreak_inc.png"), label: "Game Freak Inc")
                .frame(width: 220, height: 80)
        }
        .padding(36)
    }

    private func assetURL(_ path: String) -> URL {
        rootURL.appendingPathComponent(path)
    }

    private var palette: PokeThemeResolvedPalette {
        PokeThemePalette.resolve(
            for: appearanceMode,
            shellStyle: gameBoyShellStyle,
            colorScheme: colorScheme
        )
    }
}

struct TitleMenuScene: View {
    let props: TitleMenuSceneProps

    var body: some View {
        GameBoyScreen {
            VStack(spacing: 24) {
                TitleAttractContent(rootURL: props.rootURL)
                    .frame(height: 360)
                HStack(alignment: .top, spacing: 18) {
                    TitleMenuPanel(entries: props.entries, focusedIndex: props.focusedIndex)
                        .frame(width: 460)

                    if let saveMetadata = props.saveMetadata {
                        TitleSaveSummaryCard(metadata: saveMetadata)
                            .frame(width: 250)
                    }
                }
            }
            .padding(30)
        }
    }
}

private struct TitleSaveSummaryCard: View {
    @Environment(\.pokeAppearanceMode) private var appearanceMode
    @Environment(\.pokeGameBoyShellStyle) private var gameBoyShellStyle
    @Environment(\.colorScheme) private var colorScheme
    let metadata: GameSaveMetadata

    var body: some View {
        PlainWhitePanel {
            VStack(alignment: .leading, spacing: 12) {
                Text("Continue Save")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundStyle(palette.secondaryText.color)

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
