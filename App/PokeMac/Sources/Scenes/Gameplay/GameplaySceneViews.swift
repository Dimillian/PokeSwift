import SwiftUI
import PokeCore
import PokeDataModel
import PokeUI

struct GameplayFieldSceneProps {
    let map: MapManifest?
    let playerPosition: TilePoint?
    let playerFacing: FacingDirection
    let objects: [FieldObjectRenderState]
    let playerSpriteID: String
    let renderAssets: FieldRenderAssets?
    let dialogueLines: [String]?
    let starterChoiceOptions: [SpeciesManifest]
    let starterChoiceFocusedIndex: Int
}

struct BattleSceneProps {
    let trainerName: String
    let message: String
    let playerPokemon: PartyPokemonTelemetry
    let enemyPokemon: PartyPokemonTelemetry
    let moveNames: [String]
    let focusedMoveIndex: Int
}

struct PlaceholderSceneProps {
    let title: String?
}

struct GameplayFieldScene: View {
    let props: GameplayFieldSceneProps

    var body: some View {
        GameBoyScreen {
            ZStack {
                if let map = props.map,
                   let playerPosition = props.playerPosition {
                    FieldMapView(
                        map: map,
                        playerPosition: playerPosition,
                        playerFacing: props.playerFacing,
                        objects: props.objects,
                        playerSpriteID: props.playerSpriteID,
                        renderAssets: props.renderAssets
                    )
                    .padding(36)
                }

                if let dialogueLines = props.dialogueLines {
                    VStack {
                        Spacer()
                        DialogueBoxView(lines: dialogueLines)
                            .frame(maxWidth: 760)
                    }
                    .padding(28)
                } else if props.starterChoiceOptions.isEmpty == false {
                    StarterChoicePanel(
                        options: props.starterChoiceOptions,
                        focusedIndex: props.starterChoiceFocusedIndex
                    )
                    .frame(width: 420)
                }
            }
        }
    }
}

struct BattleScene: View {
    let props: BattleSceneProps

    var body: some View {
        GameBoyScreen {
            BattlePanel(
                trainerName: props.trainerName,
                message: props.message,
                playerPokemon: props.playerPokemon,
                enemyPokemon: props.enemyPokemon,
                moveNames: props.moveNames,
                focusedMoveIndex: props.focusedMoveIndex
            )
            .padding(36)
        }
    }
}

struct PlaceholderScene: View {
    let props: PlaceholderSceneProps

    var body: some View {
        GameBoyScreen {
            GameBoyPanel {
                VStack(spacing: 16) {
                    Text(props.title ?? "Placeholder")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                    Text("This route is intentionally reserved for Milestone 3 and beyond.")
                        .foregroundStyle(.black.opacity(0.64))
                    Text("Press Escape or X to return to the title menu.")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.black.opacity(0.85))
                }
                .padding(22)
            }
            .frame(width: 580)
        }
    }
}
