import SwiftUI
import PokeCore
import PokeDataModel

public struct FieldMapView: View {
    let map: MapManifest
    let playerPosition: TilePoint
    let playerFacing: FacingDirection
    let objects: [FieldObjectRenderState]

    public init(map: MapManifest, playerPosition: TilePoint, playerFacing: FacingDirection, objects: [FieldObjectRenderState]) {
        self.map = map
        self.playerPosition = playerPosition
        self.playerFacing = playerFacing
        self.objects = objects
    }

    public var body: some View {
        GeometryReader { proxy in
            let tileSize = min(proxy.size.width / CGFloat(map.tileWidth), proxy.size.height / CGFloat(map.tileHeight))
            let renderWidth = CGFloat(map.tileWidth) * tileSize
            let renderHeight = CGFloat(map.tileHeight) * tileSize

            ZStack(alignment: .topLeading) {
                ForEach(0..<map.tileHeight, id: \.self) { y in
                    ForEach(0..<map.tileWidth, id: \.self) { x in
                        Rectangle()
                            .fill(tileColor(x: x, y: y))
                            .frame(width: tileSize, height: tileSize)
                            .position(x: (CGFloat(x) * tileSize) + (tileSize / 2), y: (CGFloat(y) * tileSize) + (tileSize / 2))
                    }
                }

                ForEach(objects, id: \.id) { object in
                    Rectangle()
                        .fill(objectColor(for: object.sprite))
                        .frame(width: tileSize * 0.88, height: tileSize * 0.88)
                        .overlay {
                            Text(object.displayName.prefix(1))
                                .font(.system(size: tileSize * 0.45, weight: .black, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        .position(x: (CGFloat(object.position.x) * tileSize) + (tileSize / 2), y: (CGFloat(object.position.y) * tileSize) + (tileSize / 2))
                }

                Capsule()
                    .fill(Color.black)
                    .frame(width: tileSize * 0.8, height: tileSize * 0.9)
                    .overlay(alignment: overlayAlignment(for: playerFacing)) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: tileSize * 0.18, height: tileSize * 0.18)
                            .offset(directionOffset(for: playerFacing, tileSize: tileSize))
                    }
                    .position(x: (CGFloat(playerPosition.x) * tileSize) + (tileSize / 2), y: (CGFloat(playerPosition.y) * tileSize) + (tileSize / 2))
            }
            .frame(width: renderWidth, height: renderHeight)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
    }

    private func tileColor(x: Int, y: Int) -> Color {
        let blockX = max(0, min(map.blockWidth - 1, x / 2))
        let blockY = max(0, min(map.blockHeight - 1, y / 2))
        let index = min(map.blockIDs.count - 1, (blockY * map.blockWidth) + blockX)
        let blockID = map.blockIDs.isEmpty ? 0 : map.blockIDs[index]
        switch map.tileset {
        case "OVERWORLD":
            return (blockID % 5 == 0) ? Color(red: 0.86, green: 0.93, blue: 0.79) : Color(red: 0.79, green: 0.87, blue: 0.73)
        case "DOJO":
            return (blockID % 4 == 0) ? Color(red: 0.96, green: 0.92, blue: 0.83) : Color(red: 0.88, green: 0.84, blue: 0.74)
        default:
            return (blockID % 3 == 0) ? Color(red: 0.93, green: 0.93, blue: 0.9) : Color(red: 0.84, green: 0.84, blue: 0.8)
        }
    }

    private func objectColor(for sprite: String) -> Color {
        switch sprite {
        case _ where sprite.contains("OAK"):
            return Color(red: 0.28, green: 0.43, blue: 0.31)
        case _ where sprite.contains("BLUE"):
            return Color(red: 0.2, green: 0.33, blue: 0.62)
        case _ where sprite.contains("POKE_BALL"):
            return Color(red: 0.75, green: 0.2, blue: 0.18)
        case _ where sprite.contains("MOM"):
            return Color(red: 0.67, green: 0.42, blue: 0.58)
        default:
            return Color(red: 0.45, green: 0.45, blue: 0.45)
        }
    }

    private func overlayAlignment(for facing: FacingDirection) -> Alignment {
        switch facing {
        case .up:
            return .top
        case .down:
            return .bottom
        case .left:
            return .leading
        case .right:
            return .trailing
        }
    }

    private func directionOffset(for facing: FacingDirection, tileSize: CGFloat) -> CGSize {
        let amount = tileSize * 0.1
        switch facing {
        case .up:
            return CGSize(width: 0, height: amount)
        case .down:
            return CGSize(width: 0, height: -amount)
        case .left:
            return CGSize(width: amount, height: 0)
        case .right:
            return CGSize(width: -amount, height: 0)
        }
    }
}

public struct DialogueBoxView: View {
    let title: String?
    let lines: [String]

    public init(title: String? = nil, lines: [String]) {
        self.title = title
        self.lines = lines
    }

    public var body: some View {
        PlainWhitePanel {
            VStack(alignment: .leading, spacing: 10) {
                if let title {
                    Text(title)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(.black.opacity(0.55))
                }
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.system(size: 22, weight: .medium, design: .monospaced))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(6)
        }
    }
}

public struct StarterChoicePanel: View {
    let options: [SpeciesManifest]
    let focusedIndex: Int

    public init(options: [SpeciesManifest], focusedIndex: Int) {
        self.options = options
        self.focusedIndex = focusedIndex
    }

    public var body: some View {
        GameBoyPanel {
            VStack(alignment: .leading, spacing: 14) {
                Text("Choose Your Starter")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundStyle(.black)
                ForEach(Array(options.enumerated()), id: \.element.id) { index, species in
                    HStack(spacing: 12) {
                        Text(index == focusedIndex ? "▶" : " ")
                            .frame(width: 18, alignment: .leading)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(species.displayName)
                                .font(.system(size: 20, weight: .bold, design: .monospaced))
                            Text("HP \(species.baseHP)  ATK \(species.baseAttack)  DEF \(species.baseDefense)")
                                .font(.system(size: 11, weight: .regular, design: .monospaced))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(index == focusedIndex ? Color.white.opacity(0.3) : Color.clear, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
            .foregroundStyle(.black)
        }
    }
}

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
