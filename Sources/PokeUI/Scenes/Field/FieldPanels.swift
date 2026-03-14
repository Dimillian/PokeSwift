import SwiftUI
import PokeDataModel

public struct DialogueBoxView: View {
    let title: String?
    let lines: [String]
    var instantReveal: Bool
    var onFullyRevealed: (() -> Void)?

    @Environment(\.pokeTextSpeed) private var textSpeed
    @State private var revealedCharacters = 0

    private var totalCharacters: Int {
        lines.reduce(0) { $0 + $1.count }
    }

    private var isFullyRevealed: Bool {
        revealedCharacters >= totalCharacters
    }

    public init(
        title: String? = nil,
        lines: [String],
        instantReveal: Bool = false,
        onFullyRevealed: (() -> Void)? = nil
    ) {
        self.title = title
        self.lines = lines
        self.instantReveal = instantReveal
        self.onFullyRevealed = onFullyRevealed
    }

    public var body: some View {
        GameBoyDialogueFrame(showPromptIndicator: isFullyRevealed) {
            VStack(alignment: .leading, spacing: 8) {
                if let title {
                    GameBoyPixelText(
                        title.uppercased(),
                        scale: 1,
                        color: PokeThemePalette.tertiaryText,
                        fallbackFont: .system(size: 11, weight: .bold, design: .monospaced)
                    )
                    .padding(.bottom, 2)
                }

                ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                    GameBoyPixelText(
                        revealedPortion(of: line, lineIndex: index),
                        scale: 2,
                        color: PokeThemePalette.primaryText,
                        fallbackFont: .system(size: 20, weight: .medium, design: .monospaced)
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task(id: lines) {
            revealedCharacters = 0
            let total = totalCharacters
            guard total > 0 else {
                onFullyRevealed?()
                return
            }
            let delay = textSpeed.characterDelay
            for i in 1...total {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                if Task.isCancelled { return }
                if revealedCharacters >= total { return }
                revealedCharacters = i
            }
            onFullyRevealed?()
        }
        .onChange(of: lines) { _, _ in
            revealedCharacters = 0
        }
        .onChange(of: instantReveal) { _, newValue in
            if newValue, isFullyRevealed == false {
                revealedCharacters = totalCharacters
                onFullyRevealed?()
            }
        }
    }

    private func revealedPortion(of line: String, lineIndex: Int) -> String {
        var charsBefore = 0
        for i in 0..<lineIndex {
            charsBefore += lines[i].count
        }
        let available = max(0, revealedCharacters - charsBefore)
        if available >= line.count { return line }
        return String(line.prefix(available))
    }
}

private struct GameBoyDialogueFrame<Content: View>: View {
    private let content: Content
    private let showPromptIndicator: Bool

    init(showPromptIndicator: Bool = true, @ViewBuilder content: () -> Content) {
        self.showPromptIndicator = showPromptIndicator
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 22)
            .padding(.vertical, 18)
            .frame(minHeight: 92, alignment: .topLeading)
            .background {
                ZStack {
                    Rectangle()
                        .fill(PokeThemePalette.dialogueBorder)

                    Rectangle()
                        .fill(PokeThemePalette.dialoguePaper)
                        .padding(4)

                    Rectangle()
                        .fill(PokeThemePalette.dialogueInsetBorder)
                        .padding(8)

                    Rectangle()
                        .fill(PokeThemePalette.dialogueFill)
                        .padding(12)
                }
            }
        .overlay(alignment: .bottomTrailing) {
            HStack(spacing: 4) {
                Rectangle()
                    .fill(PokeThemePalette.dialogueDotSoft)
                    .frame(width: 6, height: 6)
                Rectangle()
                    .fill(PokeThemePalette.dialogueDotMid)
                    .frame(width: 6, height: 6)
                Rectangle()
                    .fill(PokeThemePalette.dialogueDotStrong)
                    .frame(width: 6, height: 6)
            }
            .padding(.trailing, 18)
            .padding(.bottom, 16)
            .opacity(showPromptIndicator ? 1 : 0)
        }
        .shadow(color: PokeThemePalette.dialogueShadow, radius: 18, y: 8)
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
                    .foregroundStyle(PokeThemePalette.primaryText)

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
                    .background(index == focusedIndex ? PokeThemePalette.menuFocusFill : Color.clear, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
            .foregroundStyle(PokeThemePalette.primaryText)
        }
    }
}
