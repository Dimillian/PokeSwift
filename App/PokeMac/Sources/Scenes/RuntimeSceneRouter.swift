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
            LaunchScene()
                .preferredColorScheme(.light)
                .pokeAppearanceMode(.light)
        case .splash:
            SplashView(rootURL: runtime.content.rootURL)
                .preferredColorScheme(.light)
                .pokeAppearanceMode(.light)
        case .titleAttract:
            TitleAttractView(rootURL: runtime.content.rootURL)
                .preferredColorScheme(.light)
                .pokeAppearanceMode(.light)
        case .titleMenu:
            TitleMenuScene(
                props: .init(
                    rootURL: runtime.content.rootURL,
                    entries: runtime.menuEntries,
                    saveMetadata: runtime.currentSaveMetadata,
                    focusedIndex: runtime.focusedIndex
                )
            )
            .preferredColorScheme(.light)
            .pokeAppearanceMode(.light)
        case .titleOptions:
            TitleOptionsScene(
                props: .init(
                    focusedRow: runtime.optionsFocusedRow,
                    textSpeed: runtime.optionsTextSpeed,
                    battleAnimation: runtime.optionsBattleAnimation,
                    battleStyle: runtime.optionsBattleStyle
                )
            )
            .preferredColorScheme(.light)
            .pokeAppearanceMode(.light)
        case .oakIntro:
            OakIntroScene(runtime: runtime)
        case .field, .dialogue, .scriptedSequence, .starterChoice, .battle, .naming:
            if let gameplaySceneProps = GameplayScenePropsFactory.make(
                runtime: runtime,
                appearanceMode: preferences.appearanceMode,
                gameplayHDREnabled: preferences.gameplayHDREnabled
            ) {
                GameplayScene(props: gameplaySceneProps)
            }
        case .placeholder:
            PlaceholderScene(props: .init(title: runtime.placeholderTitle))
                .preferredColorScheme(.light)
                .pokeAppearanceMode(.light)
        }
    }
}

private struct LaunchScene: View {
    private let palette = PokeThemePalette.lightPalette

    var body: some View {
        GameBoyScreen {
            Text("PokeMac")
                .font(.system(size: 48, weight: .black, design: .rounded))
                .foregroundStyle(palette.primaryText.color)
        }
    }
}
