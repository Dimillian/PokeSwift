import SwiftUI
import PokeDataModel
import PokeUI

struct TitleMenuSceneProps {
    let rootURL: URL
    let entries: [TitleMenuEntryState]
    let saveMetadata: GameSaveMetadata?
    let focusedIndex: Int
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
    let rootURL: URL
    private let palette = PokeThemePalette.lightPalette

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
    let metadata: GameSaveMetadata
    private let palette = PokeThemePalette.lightPalette

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
}
