import Observation
import SwiftUI
import PokeCore
import PokeDataModel
import PokeUI

struct RuntimeSceneRouter: View {
    @Environment(AppPreferences.self) private var preferences
    @Bindable var runtime: GameRuntime

    var body: some View {
        sceneContent
            .pokeTextSpeed(preferences.textSpeed)
            .onChange(of: runtime.scene) { oldValue, newValue in
                if oldValue != .titleOptions, newValue == .titleOptions {
                    runtime.optionsTextSpeed = preferences.textSpeed
                    runtime.optionsBattleAnimation = preferences.battleAnimation
                    runtime.optionsBattleStyle = preferences.battleStyle
                } else if oldValue == .titleOptions, newValue != .titleOptions {
                    preferences.setTextSpeed(runtime.optionsTextSpeed)
                    preferences.setBattleAnimation(runtime.optionsBattleAnimation)
                    preferences.setBattleStyle(runtime.optionsBattleStyle)
                }
            }
    }

    @ViewBuilder
    private var sceneContent: some View {
        switch runtime.scene {
        case .launch:
            legacyPregameChrome {
                LaunchScene()
            }
        case .splash:
            legacyPregameChrome {
                SplashView(rootURL: runtime.content.rootURL)
            }
        case .titleAttract:
            legacyPregameChrome {
                TitleAttractView(rootURL: runtime.content.rootURL)
            }
        case .titleMenu:
            legacyPregameChrome {
                TitleMenuScene(
                    props: .init(
                        rootURL: runtime.content.rootURL,
                        entries: runtime.menuEntries,
                        saveMetadata: runtime.currentSaveMetadata,
                        focusedIndex: runtime.focusedIndex
                    )
                )
            }
        case .titleOptions:
            legacyPregameChrome {
                TitleOptionsScene(
                    props: .init(
                        focusedRow: runtime.optionsFocusedRow,
                        textSpeed: runtime.optionsTextSpeed,
                        battleAnimation: runtime.optionsBattleAnimation,
                        battleStyle: runtime.optionsBattleStyle
                    )
                )
            }
        case .oakIntro:
            legacyPregameChrome {
                OakIntroScene(runtime: runtime)
            }
        case .field, .dialogue, .scriptedSequence, .starterChoice, .battle, .evolution, .naming:
            if let gameplaySceneProps = GameplayScenePropsFactory.make(
                runtime: runtime,
                appearanceMode: preferences.appearanceMode,
                gameBoyShellStyle: preferences.gameBoyShellStyle,
                gameplayHDREnabled: preferences.gameplayHDREnabled
            ) {
                GameplayScene(props: gameplaySceneProps)
            }
        case .placeholder:
            PlaceholderScene(props: .init(title: runtime.placeholderTitle))
        }
    }
}

private struct LaunchScene: View {
    @Environment(\.pokeAppearanceMode) private var appearanceMode
    @Environment(\.pokeGameBoyShellStyle) private var gameBoyShellStyle
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GameBoyScreen {
            Text("PokeMac")
                .font(.system(size: 48, weight: .black, design: .rounded))
                .foregroundStyle(palette.primaryText.color)
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

private extension RuntimeSceneRouter {
    func legacyPregameChrome<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .preferredColorScheme(.light)
            .pokeAppearanceMode(.light)
            .pokeGameBoyShellStyle(.classic)
    }
}
