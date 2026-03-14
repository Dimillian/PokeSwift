import SwiftUI
import PokeRender
import PokeUI

private enum GameplayEvolutionStageLayout {
    static let dialogueMaxWidth: CGFloat = 760
}

struct EvolutionStageView: View {
    let props: EvolutionViewportProps
    let fieldDisplayStyle: FieldDisplayStyle

    var body: some View {
        BattleViewportStage(screenDisplayStyle: fieldDisplayStyle) {
            EvolutionViewportCanvas(props: props)
        } footer: {
            if props.textLines.isEmpty == false {
                DialogueBoxView(title: "Evolution", lines: props.textLines)
                    .frame(maxWidth: GameplayEvolutionStageLayout.dialogueMaxWidth)
            }
        } overlayContent: {
            EmptyView()
        }
    }
}

private struct EvolutionViewportCanvas: View {
    let props: EvolutionViewportProps

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                EvolutionBackdrop(isAnimating: props.phase == "animating", animationStep: props.animationStep)

                Ellipse()
                    .fill(.black.opacity(0.16))
                    .frame(width: size.width * 0.34, height: size.height * 0.08)
                    .offset(y: size.height * 0.22)

                if let originalSpriteURL = props.originalSpriteURL {
                    PixelAssetView(
                        url: originalSpriteURL,
                        label: props.originalDisplayName,
                        whiteIsTransparent: true,
                        renderMode: .battlePokemonFront
                    )
                    .frame(width: size.width * 0.36, height: size.height * 0.36)
                    .opacity(originalOpacity)
                    .scaleEffect(spriteScale)
                    .brightness(spriteBrightness)
                }

                if let evolvedSpriteURL = props.evolvedSpriteURL {
                    PixelAssetView(
                        url: evolvedSpriteURL,
                        label: props.evolvedDisplayName,
                        whiteIsTransparent: true,
                        renderMode: .battlePokemonFront
                    )
                    .frame(width: size.width * 0.36, height: size.height * 0.36)
                    .opacity(evolvedOpacity)
                    .scaleEffect(spriteScale)
                    .brightness(spriteBrightness)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var originalOpacity: Double {
        switch props.phase {
        case "animating":
            return props.showsEvolvedSprite ? 0 : 1
        case "evolved", "into":
            return 0
        default:
            return 1
        }
    }

    private var evolvedOpacity: Double {
        switch props.phase {
        case "animating":
            return props.showsEvolvedSprite ? 1 : 0
        case "evolved", "into":
            return 1
        default:
            return 0
        }
    }

    private var spriteScale: CGFloat {
        props.phase == "animating" ? 1.02 : 1
    }

    private var spriteBrightness: Double {
        props.phase == "animating" ? 0.08 : 0
    }
}

private struct EvolutionBackdrop: View {
    let isAnimating: Bool
    let animationStep: Int

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.91, green: 0.97, blue: 0.89),
                    Color(red: 0.73, green: 0.86, blue: 0.72),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            if isAnimating {
                Color.white
                    .opacity(flashOpacity)
            }

            VStack(spacing: 12) {
                ForEach(0..<8, id: \.self) { _ in
                    Capsule()
                        .fill(.white.opacity(0.18))
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, 36)
        }
        .clipShape(.rect(cornerRadius: 18))
    }

    private var flashOpacity: Double {
        animationStep.isMultiple(of: 2) ? 0.18 : 0.06
    }
}
