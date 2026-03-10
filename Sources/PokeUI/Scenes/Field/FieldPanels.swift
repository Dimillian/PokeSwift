import SwiftUI
import PokeDataModel

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
                    GameBoyPixelText(
                        title.uppercased(),
                        scale: 1,
                        color: .black.opacity(0.55),
                        fallbackFont: .system(size: 12, weight: .bold, design: .monospaced)
                    )
                }

                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    GameBoyPixelText(
                        line,
                        scale: 1.5,
                        color: .black,
                        fallbackFont: .system(size: 22, weight: .medium, design: .monospaced)
                    )
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
