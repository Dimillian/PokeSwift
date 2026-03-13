import SwiftUI
import PokeDataModel
import PokeUI

struct NicknameConfirmationFooter: View {
    let confirmation: NicknameConfirmationViewProps

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            NicknameYesNoOverlay(focusedIndex: confirmation.focusedIndex)
                .frame(width: 140)
                .frame(maxWidth: .infinity, alignment: .trailing)
            DialogueBoxView(lines: ["Give a nickname to", "\(confirmation.speciesDisplayName.uppercased())?"])
        }
        .frame(maxWidth: 760)
    }
}

private struct NicknameYesNoOverlay: View {
    let focusedIndex: Int

    var body: some View {
        GameplayHoverCardSurface {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(["YES", "NO"].enumerated()), id: \.offset) { index, label in
                    HStack(spacing: 8) {
                        Text(focusedIndex == index ? "▶" : " ")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                        Text(label)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                    }
                    .foregroundStyle(GameplayFieldStyleTokens.ink.opacity(focusedIndex == index ? 1 : 0.58))
                }
            }
        }
    }
}

struct NamingOverlayPanel: View {
    let props: NamingOverlayProps

    var body: some View {
        GameplayHoverCardSurface {
            VStack(alignment: .leading, spacing: 14) {
                Text("YOUR \(props.speciesDisplayName.uppercased())'S NICKNAME?")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(GameplayFieldStyleTokens.ink)

                nameDisplay
            }
        }
    }

    private var nameDisplay: some View {
        let characters = Array(props.enteredText)
        return HStack(spacing: 2) {
            ForEach(0..<props.maxLength, id: \.self) { index in
                let char = index < characters.count
                    ? String(characters[index])
                    : ""
                Text(char)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundStyle(GameplayFieldStyleTokens.ink)
                    .frame(width: 18, height: 22)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(GameplayFieldStyleTokens.ink.opacity(
                                index == characters.count ? 1 : 0.24
                            ))
                            .frame(height: 2)
                    }
            }
        }
    }
}

struct FieldPromptOverlay: View {
    let prompt: FieldPromptTelemetry

    var body: some View {
        GameplayHoverCardSurface(padding: 14) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(prompt.options.enumerated()), id: \.offset) { index, option in
                    HStack(spacing: 10) {
                        Text(index == prompt.focusedIndex ? "▶" : " ")
                        Text(option.uppercased())
                        Spacer(minLength: 8)
                    }
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(GameplayFieldStyleTokens.ink.opacity(index == prompt.focusedIndex ? 1 : 0.78))
                }
            }
        }
    }
}
