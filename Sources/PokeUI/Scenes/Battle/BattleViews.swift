import SwiftUI
import PokeDataModel

public struct BattlePanel: View {
    let trainerName: String
    let message: String
    let playerPokemon: PartyPokemonTelemetry
    let enemyPokemon: PartyPokemonTelemetry
    let moveNames: [String]
    let focusedMoveIndex: Int

    public init(
        trainerName: String,
        message: String,
        playerPokemon: PartyPokemonTelemetry,
        enemyPokemon: PartyPokemonTelemetry,
        moveNames: [String],
        focusedMoveIndex: Int
    ) {
        self.trainerName = trainerName
        self.message = message
        self.playerPokemon = playerPokemon
        self.enemyPokemon = enemyPokemon
        self.moveNames = moveNames
        self.focusedMoveIndex = focusedMoveIndex
    }

    public var body: some View {
        VStack(spacing: 20) {
            HStack {
                battleCard(title: trainerName, pokemon: enemyPokemon)
                Spacer()
            }
            HStack {
                Spacer()
                battleCard(title: "RED", pokemon: playerPokemon)
            }
            HStack(alignment: .top, spacing: 20) {
                DialogueBoxView(title: "Battle", lines: [message])
                GameBoyPanel {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Moves")
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                        ForEach(Array(moveNames.enumerated()), id: \.offset) { index, move in
                            Text("\(index == focusedMoveIndex ? "▶" : " ") \(move)")
                                .font(.system(size: 17, weight: .medium, design: .monospaced))
                                .foregroundStyle(.black)
                        }
                    }
                    .frame(width: 260, alignment: .leading)
                }
            }
        }
    }

    private func battleCard(title: String, pokemon: PartyPokemonTelemetry) -> some View {
        PlainWhitePanel {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.black.opacity(0.55))
                Text("\(pokemon.displayName) Lv\(pokemon.level)")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                Text("HP \(pokemon.currentHP)/\(pokemon.maxHP)")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
            }
            .foregroundStyle(.black)
            .frame(width: 240, alignment: .leading)
        }
    }
}
