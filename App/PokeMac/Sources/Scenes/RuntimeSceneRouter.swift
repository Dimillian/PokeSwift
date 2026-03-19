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
                TitleAttractView(presentation: titlePresentationProps)
            }
        case .titleMenu:
            legacyPregameChrome {
                TitleMenuScene(
                    props: .init(
                        presentation: titlePresentationProps,
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
    var titlePresentationProps: TitlePresentationProps {
        let titleState = runtime.titlePresentationState
        let currentSpeciesID = titleState?.currentSpeciesID ?? runtime.content.titleManifest.titleMonSpecies
        let species = runtime.content.species(id: currentSpeciesID)

        return TitlePresentationProps(
            logoURL: titleAssetURL(id: "pokemon_logo"),
            playerURL: titleAssetURL(id: "player"),
            wordmarkURL: titleAssetURL(id: "gamefreak_inc"),
            pokemonSpriteURL: species?.battleSprite.map { runtime.content.rootURL.appendingPathComponent($0.frontImagePath) },
            pokemonDisplayName: species?.displayName ?? currentSpeciesID,
            logoYOffset: titleState?.logoYOffset ?? 0,
            pokemonOffsetX: titleState?.monOffsetX ?? 0
        )
    }

    func titleAssetURL(id: String) -> URL? {
        runtime.content.titleAsset(id: id).map { runtime.content.rootURL.appendingPathComponent($0.relativePath) }
    }

    func legacyPregameChrome<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .preferredColorScheme(.light)
            .pokeAppearanceMode(.light)
            .pokeGameBoyShellStyle(.classic)
    }
}
