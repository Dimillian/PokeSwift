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

    var body: some View {
        GameBoyScreen {
            ZStack {
                Color.black

                VStack(spacing: 0) {
                    Spacer()

                    spriteView
                        .frame(height: 200)
                        .animation(.snappy, value: state?.phase.rawValue)

                    Spacer()

                    dialogueOrNamingView
                        .frame(maxWidth: 560)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 40)
                }
            }
        }
        .preferredColorScheme(.dark)
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

    @ViewBuilder
    private var oakSprite: some View {
        if let sprite = runtime.content.overworldSprite(id: "SPRITE_OAK") {
            let url = runtime.content.rootURL.appendingPathComponent(sprite.imagePath)
            PixelSpriteFrameView(url: url, frame: sprite.facingFrames.down, label: "Prof. Oak")
                .frame(width: 128, height: 128)
        }
    }

    @ViewBuilder
    private var nidorinoSprite: some View {
        if let frontPath = runtime.content.species(id: "NIDORINO")?.battleSprite?.frontImagePath {
            let url = runtime.content.rootURL.appendingPathComponent(frontPath)
            PixelAssetView(url: url, label: "Nidorino", whiteIsTransparent: true)
                .frame(width: 160, height: 160)
        }
    }

    private var playerSprite: some View {
        let url = runtime.content.rootURL.appendingPathComponent("Assets/title/player.png")
        return PixelAssetView(url: url, label: "Player")
            .frame(width: 160, height: 160)
    }

    @ViewBuilder
    private var rivalSprite: some View {
        if let sprite = runtime.content.overworldSprite(id: "SPRITE_BLUE") {
            let url = runtime.content.rootURL.appendingPathComponent(sprite.imagePath)
            PixelSpriteFrameView(url: url, frame: sprite.facingFrames.down, label: "Rival")
                .frame(width: 128, height: 128)
        }
    }

    // MARK: - Dialogue / naming

    @ViewBuilder
    private var dialogueOrNamingView: some View {
        if let state {
            switch state.phase {
            case .namingPlayer:
                introNamingPanel(prompt: "YOUR NAME?", characters: state.enteredCharacters)
            case .namingRival:
                introNamingPanel(prompt: "RIVAL'S NAME?", characters: state.enteredCharacters)
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
}
