import Observation
import SwiftUI
import PokeCore
import PokeDataModel
import PokeUI

struct RuntimeSceneRouter: View {
    @Bindable var runtime: GameRuntime

    var body: some View {
        switch runtime.scene {
        case .launch:
            LaunchScene()
        case .splash:
            SplashView(rootURL: runtime.content.rootURL)
        case .titleAttract:
            TitleAttractView(rootURL: runtime.content.rootURL)
        case .titleMenu:
            TitleMenuScene(
                props: .init(
                    rootURL: runtime.content.rootURL,
                    entries: runtime.menuEntries,
                    focusedIndex: runtime.focusedIndex
                )
            )
        case .field, .dialogue, .scriptedSequence, .starterChoice:
            GameplayFieldScene(props: gameplayFieldSceneProps)
        case .battle:
            if let battleSceneProps {
                BattleScene(props: battleSceneProps)
            }
        case .placeholder:
            PlaceholderScene(props: .init(title: runtime.placeholderTitle))
        }
    }

    private var gameplayFieldSceneProps: GameplayFieldSceneProps {
        return GameplayFieldSceneProps(
            map: runtime.currentMapManifest,
            playerPosition: runtime.playerPosition,
            playerFacing: runtime.playerFacing,
            objects: runtime.currentFieldObjects,
            playerSpriteID: runtime.playerSpriteID,
            renderAssets: makeFieldRenderAssets(runtime: runtime),
            dialogueLines: runtime.currentDialoguePage?.lines,
            starterChoiceOptions: runtime.scene == .starterChoice ? runtime.starterChoiceOptions : [],
            starterChoiceFocusedIndex: runtime.starterChoiceFocusedIndex
        )
    }

    private var battleSceneProps: BattleSceneProps? {
        guard let battle = runtime.currentSnapshot().battle else { return nil }
        return BattleSceneProps(
            trainerName: battle.trainerName,
            message: battle.battleMessage,
            playerPokemon: battle.playerPokemon,
            enemyPokemon: battle.enemyPokemon,
            moveNames: runtime.currentBattleMoves.map(\.displayName),
            focusedMoveIndex: battle.focusedMoveIndex
        )
    }

}

private struct LaunchScene: View {
    var body: some View {
        GameBoyScreen {
            Text("PokeMac")
                .font(.system(size: 48, weight: .black, design: .rounded))
                .foregroundStyle(.black)
        }
    }
}
