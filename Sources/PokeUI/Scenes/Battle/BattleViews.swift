import SwiftUI
import PokeDataModel

public struct BattlePanel: View {
    let trainerName: String
    let phase: String
    let textLines: [String]
    let playerPokemon: PartyPokemonTelemetry
    let enemyPokemon: PartyPokemonTelemetry
    let moveSlots: [BattleMoveSlotTelemetry]
    let focusedMoveIndex: Int
    let playerSpriteURL: URL?
    let enemySpriteURL: URL?

    public init(
        trainerName: String,
        phase: String,
        textLines: [String],
        playerPokemon: PartyPokemonTelemetry,
        enemyPokemon: PartyPokemonTelemetry,
        moveSlots: [BattleMoveSlotTelemetry],
        focusedMoveIndex: Int,
        playerSpriteURL: URL?,
        enemySpriteURL: URL?
    ) {
        self.trainerName = trainerName
        self.phase = phase
        self.textLines = textLines
        self.playerPokemon = playerPokemon
        self.enemyPokemon = enemyPokemon
        self.moveSlots = moveSlots
        self.focusedMoveIndex = focusedMoveIndex
        self.playerSpriteURL = playerSpriteURL
        self.enemySpriteURL = enemySpriteURL
    }

    public var body: some View {
        VStack(spacing: 20) {
            HStack {
                battleCard(title: trainerName, pokemon: enemyPokemon)
                Spacer()
                if let enemySpriteURL {
                    PixelAssetView(url: enemySpriteURL, label: enemyPokemon.displayName)
                        .frame(width: 180, height: 180)
                }
            }
            HStack {
                if let playerSpriteURL {
                    PixelAssetView(url: playerSpriteURL, label: playerPokemon.displayName)
                        .frame(width: 180, height: 180)
                }
                Spacer()
                battleCard(title: "RED", pokemon: playerPokemon)
            }
            HStack(alignment: .top, spacing: 20) {
                DialogueBoxView(title: "Battle", lines: textLines.isEmpty ? ["Pick the next move."] : textLines)
                GameBoyPanel {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(phase == "moveSelection" ? "Moves" : "Resolve")
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                        ForEach(Array(moveSlots.enumerated()), id: \.offset) { index, slot in
                            Text(moveSlotLabel(index: index, slot: slot))
                                .font(.system(size: 17, weight: .medium, design: .monospaced))
                                .foregroundStyle(slotForeground(index: index, slot: slot))
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
                HStack(spacing: 8) {
                    Text("HP")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(.black.opacity(0.12))
                            RoundedRectangle(cornerRadius: 3)
                                .fill(.black)
                                .frame(width: geometry.size.width * hpFraction(for: pokemon))
                            Text("\(pokemon.currentHP)/\(pokemon.maxHP)")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(hpTextColor(for: pokemon))
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        }
                    }
                    .frame(height: 12)
                }
            }
            .foregroundStyle(.black)
            .frame(width: 240, alignment: .leading)
        }
    }

    private func hpFraction(for pokemon: PartyPokemonTelemetry) -> CGFloat {
        guard pokemon.maxHP > 0 else { return 0 }
        let ratio = CGFloat(pokemon.currentHP) / CGFloat(pokemon.maxHP)
        return min(max(ratio, 0), 1)
    }

    private func hpTextColor(for pokemon: PartyPokemonTelemetry) -> Color {
        hpFraction(for: pokemon) > 0.5 ? .white : .black
    }

    private func moveSlotLabel(index: Int, slot: BattleMoveSlotTelemetry) -> String {
        let prefix = phase == "moveSelection" && index == focusedMoveIndex ? "▶" : " "
        return "\(prefix) \(slot.displayName) \(slot.currentPP)/\(slot.maxPP)"
    }

    private func slotForeground(index: Int, slot: BattleMoveSlotTelemetry) -> Color {
        guard slot.isSelectable else {
            return .black.opacity(0.35)
        }
        if phase == "moveSelection" && index == focusedMoveIndex {
            return .black
        }
        return .black.opacity(phase == "moveSelection" ? 0.82 : 0.5)
    }
}
