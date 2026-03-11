import Observation
import SwiftUI
import PokeCore
import PokeDataModel
import PokeUI

struct RuntimeSceneRouter: View {
    @Bindable var runtime: GameRuntime
    let appearanceMode: AppAppearanceMode
    let onCycleAppearanceMode: @MainActor () -> Void

    var body: some View {
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
        case .field, .dialogue, .scriptedSequence, .starterChoice, .battle:
            if let gameplaySceneProps = GameplayScenePropsFactory.make(
                runtime: runtime,
                appearanceMode: appearanceMode,
                onCycleAppearanceMode: onCycleAppearanceMode
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
