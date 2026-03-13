import SwiftUI
import PokeCore
import PokeDataModel
import PokeRender
import PokeUI

struct OakIntroScene: View {
    @Bindable var runtime: GameRuntime

    private var state: OakIntroState? {
        runtime.oakIntroState
    }

    private var spriteGroupKey: String {
        guard let phase = state?.phase else { return "none" }
        switch phase {
        case .oakAppears:
            return "oak"
        case .nidorinoAppears:
            return "nidorino"
        case .playerAppears, .namingPlayer, .playerNamed:
            return "player"
        case .rivalAppears, .namingRival, .rivalNamed:
            return "rival"
        case .finalSpeech, .fadeOut:
            return "player_final"
        }
    }

    private var isPresetSelection: Bool {
        guard let state else { return false }
        return (state.phase == .namingPlayer || state.phase == .namingRival) && !state.isTypingCustomName
    }

    var body: some View {
        GameBoyScreen {
            ZStack {
                Color.black

                VStack(spacing: 0) {
                    Spacer()

                    spriteView
                        .frame(height: 200)
                        .id(spriteGroupKey)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.4), value: spriteGroupKey)

                    Spacer()

                    dialogueOrNamingView
                        .frame(maxWidth: 560)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 40)
                }
                .opacity(isPresetSelection ? 0 : 1)

                presetSelectionLayout
                    .opacity(isPresetSelection ? 1 : 0)
            }
        }
        .preferredColorScheme(.dark)
        .opacity(state?.phase == .fadeOut ? 0 : 1)
        .animation(.easeOut(duration: 0.6), value: state?.phase == .fadeOut)
    }

    // MARK: - Sprite display

    @ViewBuilder
    private var spriteView: some View {
        switch state?.phase {
        case .oakAppears:
            oakSprite
        case .nidorinoAppears:
            nidorinoSprite
        case .playerAppears, .namingPlayer, .playerNamed:
            playerSprite
        case .rivalAppears, .namingRival, .rivalNamed:
            rivalSprite
        case .finalSpeech, .fadeOut:
            playerSprite
        case nil:
            EmptyView()
        }
    }

    private var oakSprite: some View {
        let url = runtime.content.rootURL.appendingPathComponent("Assets/battle/trainers/prof.oak.png")
        return PixelAssetView(url: url, label: "Prof. Oak", whiteIsTransparent: true)
            .frame(width: 160, height: 160)
    }

    @ViewBuilder
    private var nidorinoSprite: some View {
        if let frontPath = runtime.content.species(id: "NIDORINO")?.battleSprite?.frontImagePath {
            let url = runtime.content.rootURL.appendingPathComponent(frontPath)
            PixelAssetView(url: url, label: "Nidorino", whiteIsTransparent: true)
                .scaleEffect(x: -1, y: 1)
                .frame(width: 160, height: 160)
        }
    }

    private var playerSprite: some View {
        let url = runtime.content.rootURL.appendingPathComponent("Assets/title/player.png")
        return PixelAssetView(url: url, label: "Player", whiteIsTransparent: true)
            .frame(width: 160, height: 160)
    }

    private var rivalSprite: some View {
        let url = runtime.content.rootURL.appendingPathComponent("Assets/battle/trainers/rival1.png")
        return PixelAssetView(url: url, label: "Rival", whiteIsTransparent: true)
            .frame(width: 160, height: 160)
    }

    // MARK: - Dialogue / naming

    @ViewBuilder
    private var dialogueOrNamingView: some View {
        if let state {
            switch state.phase {
            case .namingPlayer:
                if state.isTypingCustomName {
                    introNamingPanel(prompt: "YOUR NAME?", characters: state.enteredCharacters)
                } else {
                    EmptyView()
                }
            case .namingRival:
                if state.isTypingCustomName {
                    introNamingPanel(prompt: "RIVAL'S NAME?", characters: state.enteredCharacters)
                } else {
                    EmptyView()
                }
            default:
                if state.dialoguePages.indices.contains(state.currentPageIndex) {
                    DialogueBoxView(lines: state.dialoguePages[state.currentPageIndex])
                }
            }
        }
    }

    private func introNamingPanel(prompt: String, characters: [Character]) -> some View {
        GameBoyPanel {
            VStack(alignment: .leading, spacing: 14) {
                Text(prompt)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(PokeThemePalette.lightPalette.primaryText.color)

                nameSlots(characters: characters)
            }
        }
    }

    private func nameSlots(characters: [Character]) -> some View {
        let maxLength = RuntimeNamingState.maxLength
        return HStack(spacing: 2) {
            ForEach(0..<maxLength, id: \.self) { index in
                let char = index < characters.count
                    ? String(characters[index])
                    : ""
                Text(char)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundStyle(PokeThemePalette.lightPalette.primaryText.color)
                    .frame(width: 18, height: 22)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(PokeThemePalette.lightPalette.primaryText.color.opacity(
                                index == characters.count ? 1 : 0.24
                            ))
                            .frame(height: 2)
                    }
            }
        }
    }

    // MARK: - Preset name selection

    private var presetSelectionLayout: some View {
        VStack(spacing: 0) {
            // Top panel: name options + sprite
            presetSelectionPanel
                .frame(maxWidth: 560)
                .padding(.horizontal, 32)
                .padding(.top, 40)

            Spacer()

            // Bottom dialogue
            presetDialogueView
                .frame(maxWidth: 560)
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
        }
    }

    private var presetSelectionPanel: some View {
        GameBoyPanel {
            VStack(alignment: .leading, spacing: 0) {
                // "NAME" title
                GameBoyPixelText(
                    "NAME",
                    scale: 2,
                    color: PokeThemePalette.primaryText,
                    fallbackFont: .system(size: 20, weight: .bold, design: .monospaced)
                )
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 16)

                HStack(alignment: .top, spacing: 16) {
                    // Left: name options
                    presetOptionsList
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Right: character sprite
                    presetSprite
                        .frame(width: 120, height: 120)
                }
            }
        }
    }

    @ViewBuilder
    private var presetOptionsList: some View {
        if let state {
            let presets = state.currentPresets
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(presets.enumerated()), id: \.offset) { index, name in
                    HStack(spacing: 8) {
                        GameBoyPixelText(
                            index == state.namePresetFocusedIndex ? "▶" : " ",
                            scale: 2,
                            color: PokeThemePalette.primaryText,
                            fallbackFont: .system(size: 18, weight: .bold, design: .monospaced)
                        )
                        .frame(width: 20, alignment: .leading)

                        GameBoyPixelText(
                            name,
                            scale: 2,
                            color: PokeThemePalette.primaryText,
                            fallbackFont: .system(size: 18, weight: .bold, design: .monospaced)
                        )
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        index == state.namePresetFocusedIndex
                            ? PokeThemePalette.menuFocusFill
                            : Color.clear,
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var presetSprite: some View {
        if let phase = state?.phase {
            switch phase {
            case .namingPlayer:
                playerSprite
            case .namingRival:
                rivalSprite
            default:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private var presetDialogueView: some View {
        if let phase = state?.phase {
            switch phase {
            case .namingPlayer:
                DialogueBoxView(lines: ["First, what is", "your name?"])
            case .namingRival:
                DialogueBoxView(lines: ["…Erm, what is", "his name again?"])
            default:
                EmptyView()
            }
        }
    }
}
