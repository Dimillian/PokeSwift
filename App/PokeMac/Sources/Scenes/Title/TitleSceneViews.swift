import SwiftUI
import PokeDataModel
import PokeUI

struct TitleMenuSceneProps {
    let rootURL: URL
    let entries: [TitleMenuEntry]
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

    var body: some View {
        VStack(spacing: 18) {
            PixelAssetView(url: assetURL("Assets/title/pokemon_logo.png"), label: "Pokemon Logo")
                .frame(width: 540, height: 220)
            HStack(spacing: 24) {
                PixelAssetView(url: assetURL("Assets/title/player.png"), label: "Red")
                    .frame(width: 200, height: 200)
                PlainWhitePanel {
                    VStack(spacing: 18) {
                        PixelAssetView(url: assetURL("Assets/title/red_version.png"), label: "Red Version")
                            .frame(width: 220, height: 90)
                        Text("Press Return or Space to Start")
                            .font(.system(.title3, design: .monospaced))
                            .foregroundStyle(.black)
                        Text("Z confirms, X cancels, arrows navigate")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.black.opacity(0.64))
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
            VStack(spacing: 26) {
                TitleAttractContent(rootURL: props.rootURL)
                    .frame(height: 420)
                TitleMenuPanel(entries: props.entries, focusedIndex: props.focusedIndex)
                    .frame(width: 460)
            }
            .padding(30)
        }
    }
}
