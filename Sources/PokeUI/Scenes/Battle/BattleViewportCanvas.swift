import SwiftUI
import PokeDataModel
import PokeRender

struct BattleViewportCanvas: View {
    let kind: BattleKind
    let playerPokemon: PartyPokemonTelemetry
    let enemyPokemon: PartyPokemonTelemetry
    let trainerSpriteURL: URL?
    let playerTrainerFrontSpriteURL: URL?
    let playerTrainerBackSpriteURL: URL?
    let playerSpriteURL: URL?
    let enemySpriteURL: URL?
    let presentation: BattlePresentationTelemetry

    @State private var sendOutBallProgress: CGFloat = 1
    @State private var sendOutBallOpacity: Double = 0
    @State private var sendOutPokemonProgress: CGFloat = 1
    @State private var sendOutPokemonVisibility: Double = 1

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let layout = BattleViewportLayout(size: size)

            ZStack(alignment: .topLeading) {
                battleBackground

                BattleStatusCard(
                    pokemon: enemyPokemon,
                    chrome: .enemy,
                    showsExperience: false,
                    presentation: presentation
                )
                .frame(width: layout.enemyCardSize.width, height: layout.enemyCardSize.height)
                .position(x: layout.enemyCardCenter.x, y: layout.enemyCardCenter.y)
                .opacity(enemyHudOpacity)
                .offset(y: enemyHudOffset)
                .animation(hudAnimation, value: presentation.revision)

                BattleStatusCard(
                    pokemon: playerPokemon,
                    chrome: .player,
                    showsExperience: true,
                    presentation: presentation
                )
                .frame(width: layout.playerCardSize.width, height: layout.playerCardSize.height)
                .position(x: layout.playerCardCenter.x, y: layout.playerCardCenter.y)
                .opacity(playerHudOpacity)
                .offset(y: playerHudOffset)
                .animation(hudAnimation, value: presentation.revision)

                if let trainerSpriteURL, shouldShowEnemyTrainer {
                    PixelAssetView(
                        url: trainerSpriteURL,
                        label: "Trainer",
                        whiteIsTransparent: true
                    )
                    .frame(width: layout.enemyTrainerSize.width, height: layout.enemyTrainerSize.height)
                    .position(enemyTrainerCenter(in: layout))
                    .scaleEffect(trainerScale)
                    .opacity(trainerOpacity)
                    .animation(spriteAnimation, value: presentation.revision)
                }

                if let playerTrainerSpriteURL, shouldShowPlayerTrainer {
                    PixelAssetView(
                        url: playerTrainerSpriteURL,
                        label: "Player Trainer",
                        whiteIsTransparent: true
                    )
                    .frame(width: layout.playerTrainerSize.width, height: layout.playerTrainerSize.height)
                    .position(playerTrainerCenter(in: layout))
                    .scaleEffect(trainerScale)
                    .opacity(trainerOpacity)
                    .animation(spriteAnimation, value: presentation.revision)
                }

                if let enemySpriteURL, shouldShowEnemyPokemon {
                    PixelAssetView(
                        url: enemySpriteURL,
                        label: enemyPokemon.displayName,
                        whiteIsTransparent: true
                    )
                    .frame(width: layout.enemySpriteSize.width, height: layout.enemySpriteSize.height)
                    .position(enemySpriteCenter(in: layout))
                    .scaleEffect(enemySpriteScale)
                    .rotationEffect(enemyPokemonRotation)
                    .opacity(enemyPokemonOpacity)
                    .animation(spriteAnimation, value: presentation.revision)
                }

                if let playerSpriteURL, shouldShowPlayerPokemon {
                    PixelAssetView(
                        url: playerSpriteURL,
                        label: playerPokemon.displayName,
                        whiteIsTransparent: true
                    )
                    .frame(width: layout.playerSpriteSize.width, height: layout.playerSpriteSize.height)
                    .position(playerSpriteCenter(in: layout))
                    .scaleEffect(playerSpriteScale)
                    .rotationEffect(playerPokemonRotation)
                    .opacity(playerPokemonOpacity)
                    .animation(spriteAnimation, value: presentation.revision)
                }

                if shouldShowPokeball {
                    BattlePokeballToken()
                        .frame(width: max(8, size.width * 0.05), height: max(8, size.width * 0.05))
                        .position(pokeballCenter(in: layout))
                        .opacity(sendOutBallOpacity)
                        .animation(spriteAnimation, value: presentation.revision)
                }
            }
            .task(id: sendOutAnimationTriggerKey) {
                await runSendOutAnimationSequence()
            }
        }
    }

    private var isTrainerBattle: Bool {
        kind == .trainer
    }

    private var isWildBattle: Bool {
        kind == .wild
    }

    private var playerTrainerSpriteURL: URL? {
        playerTrainerBackSpriteURL ?? playerTrainerFrontSpriteURL
    }

    private var shouldShowEnemyTrainer: Bool {
        guard isTrainerBattle else { return false }
        switch presentation.stage {
        case .introFlash1, .introFlash2, .introFlash3, .introSpiral, .introCrossing, .introReveal:
            return true
        case .enemySendOut:
            return presentation.activeSide == .enemy
        default:
            return false
        }
    }

    private var shouldShowPlayerTrainer: Bool {
        guard playerTrainerSpriteURL != nil else { return false }
        switch presentation.stage {
        case .introFlash1, .introFlash2, .introFlash3, .introSpiral, .introCrossing, .introReveal:
            return true
        case .enemySendOut:
            return presentation.activeSide == .player
        default:
            return false
        }
    }

    private var shouldShowEnemyPokemon: Bool {
        if isTrainerBattle {
            switch presentation.stage {
            case .introFlash1, .introFlash2, .introFlash3, .introSpiral, .introCrossing:
                return false
            default:
                break
            }
        }
        return true
    }

    private var shouldShowPlayerPokemon: Bool {
        if isTrainerBattle {
            switch presentation.stage {
            case .introFlash1, .introFlash2, .introFlash3, .introSpiral, .introCrossing:
                return false
            default:
                break
            }
        } else if isWildBattle {
            switch presentation.stage {
            case .introFlash1, .introFlash2, .introFlash3, .introSpiral, .introCrossing, .introReveal:
                return false
            case .enemySendOut where presentation.activeSide == .enemy:
                return false
            default:
                break
            }
        }
        return true
    }

    private var shouldShowPokeball: Bool {
        presentation.stage == .enemySendOut
    }

    private var sendOutAnimationTriggerKey: String {
        "\(presentation.stage)-\(String(describing: presentation.activeSide))-\(presentation.revision)"
    }

    private var enemyHudOpacity: Double {
        guard presentation.uiVisibility == .visible else { return 0 }

        if isTrainerBattle {
            switch presentation.stage {
            case .introReveal:
                return 0
            case .enemySendOut where presentation.activeSide == .enemy:
                return sendOutPokemonVisibility
            default:
                return 1
            }
        }

        return 1
    }

    private var playerHudOpacity: Double {
        guard presentation.uiVisibility == .visible else { return 0 }

        if isTrainerBattle {
            switch presentation.stage {
            case .introReveal:
                return 0
            case .enemySendOut where presentation.activeSide == .enemy:
                return 0
            case .enemySendOut where presentation.activeSide == .player:
                return sendOutPokemonVisibility
            default:
                return 1
            }
        }

        if isWildBattle {
            switch presentation.stage {
            case .enemySendOut where presentation.activeSide == .player:
                return sendOutPokemonVisibility
            default:
                return 1
            }
        }

        return 1
    }

    private var enemyHudOffset: CGFloat {
        enemyHudOpacity > 0 ? 0 : 14
    }

    private var playerHudOffset: CGFloat {
        playerHudOpacity > 0 ? 0 : 14
    }

    private var trainerOpacity: Double {
        switch presentation.stage {
        case .introReveal, .enemySendOut:
            return 1
        case .introCrossing:
            return 0.96
        default:
            return 0.92
        }
    }

    private var trainerScale: CGFloat {
        presentation.stage == .enemySendOut ? 1.02 : 1
    }

    private var enemySpriteScale: CGFloat {
        switch presentation.stage {
        case .introReveal where isTrainerBattle:
            return 0.34
        case .enemySendOut where presentation.activeSide == .enemy:
            return 0.18 + (0.82 * sendOutPokemonProgress)
        case .attackImpact where presentation.activeSide == .enemy:
            return 1.04
        default:
            return enemyPokemon.currentHP == 0 ? 0.18 : 1
        }
    }

    private var playerSpriteScale: CGFloat {
        switch presentation.stage {
        case .introReveal where isTrainerBattle:
            return 0.34
        case .enemySendOut where presentation.activeSide == .player:
            return 0.18 + (0.82 * sendOutPokemonProgress)
        case .attackImpact where presentation.activeSide == .player:
            return 1.04
        default:
            return playerPokemon.currentHP == 0 ? 0.18 : 1
        }
    }

    private var enemyPokemonOpacity: Double {
        let visibility: Double
        if isTrainerBattle, presentation.stage == .introReveal {
            visibility = 0
        } else if presentation.stage == .enemySendOut, presentation.activeSide == .enemy {
            visibility = sendOutPokemonVisibility
        } else if enemyPokemon.currentHP == 0 {
            visibility = 0
        } else {
            visibility = 1
        }
        return visibility
    }

    private var playerPokemonOpacity: Double {
        let visibility: Double
        if isTrainerBattle {
            switch presentation.stage {
            case .introReveal:
                visibility = 0
            case .enemySendOut where presentation.activeSide == .enemy && presentation.hidePlayerPokemon:
                visibility = 0
            case .enemySendOut where presentation.activeSide == .player:
                visibility = sendOutPokemonVisibility
            case _ where playerPokemon.currentHP == 0:
                visibility = 0
            default:
                visibility = 1
            }
        } else if isWildBattle {
            switch presentation.stage {
            case .introFlash1, .introFlash2, .introFlash3, .introSpiral, .introCrossing, .introReveal:
                visibility = 0
            case .enemySendOut where presentation.activeSide == .player:
                visibility = sendOutPokemonVisibility
            case _ where playerPokemon.currentHP == 0:
                visibility = 0
            default:
                visibility = 1
            }
        } else {
            visibility = playerPokemon.currentHP == 0 ? 0 : 1
        }
        return visibility
    }

    private var enemyPokemonRotation: Angle {
        .degrees(0)
    }

    private var playerPokemonRotation: Angle {
        .degrees(0)
    }

    private func enemyTrainerCenter(in layout: BattleViewportLayout) -> CGPoint {
        let settled = layout.enemyTrainerCenter
        switch presentation.stage {
        case .introFlash1, .introFlash2, .introFlash3, .introSpiral:
            return CGPoint(
                x: -(layout.enemyTrainerSize.width * 0.5) - 12,
                y: settled.y - 6
            )
        case .introCrossing, .introReveal:
            return settled
        case .enemySendOut where presentation.activeSide == .enemy:
            return CGPoint(
                x: layout.size.width + layout.enemyTrainerSize.width * 0.5 + 16,
                y: settled.y - 4
            )
        default:
            return settled
        }
    }

    private func playerTrainerCenter(in layout: BattleViewportLayout) -> CGPoint {
        let settled = layout.playerTrainerCenter
        switch presentation.stage {
        case .introFlash1, .introFlash2, .introFlash3, .introSpiral:
            return CGPoint(
                x: layout.size.width + layout.playerTrainerSize.width * 0.5 + 12,
                y: settled.y + 6
            )
        case .introCrossing, .introReveal:
            return settled
        case .enemySendOut where presentation.activeSide == .player:
            return CGPoint(
                x: -(layout.playerTrainerSize.width * 0.5) - 16,
                y: settled.y + 2
            )
        default:
            return settled
        }
    }

    private func enemySpriteCenter(in layout: BattleViewportLayout) -> CGPoint {
        let settled = layout.enemySpriteCenter
        let sendOutOrigin = layout.enemyTrainerPokemonOrigin
        switch presentation.stage {
        case .introFlash1, .introFlash2, .introFlash3, .introSpiral where isWildBattle:
            return CGPoint(
                x: -(layout.enemySpriteSize.width * 0.5) - 12,
                y: settled.y - 6
            )
        case .introReveal where isTrainerBattle:
            return sendOutOrigin
        case .enemySendOut where presentation.activeSide == .enemy:
            return interpolate(
                from: sendOutOrigin,
                to: settled,
                progress: sendOutPokemonProgress
            )
        case .attackWindup where presentation.activeSide == .enemy:
            return CGPoint(x: settled.x - layout.size.width * 0.07, y: settled.y + 2)
        case .attackImpact where presentation.activeSide == .enemy:
            return CGPoint(x: settled.x + layout.size.width * 0.02, y: settled.y)
        case .attackImpact where presentation.activeSide == .player:
            return CGPoint(x: settled.x + layout.size.width * 0.03, y: settled.y - 2)
        default:
            return settled
        }
    }

    private func playerSpriteCenter(in layout: BattleViewportLayout) -> CGPoint {
        let settled = layout.playerSpriteCenter
        let sendOutOrigin = layout.playerTrainerPokemonOrigin
        switch presentation.stage {
        case .introReveal where isTrainerBattle:
            return sendOutOrigin
        case .enemySendOut where presentation.activeSide == .player:
            return interpolate(
                from: sendOutOrigin,
                to: settled,
                progress: sendOutPokemonProgress
            )
        case .attackWindup where presentation.activeSide == .player:
            return CGPoint(x: settled.x + layout.size.width * 0.09, y: settled.y - 4)
        case .attackImpact where presentation.activeSide == .player:
            return CGPoint(x: settled.x - layout.size.width * 0.02, y: settled.y)
        case .attackImpact where presentation.activeSide == .enemy:
            return CGPoint(x: settled.x - layout.size.width * 0.03, y: settled.y + 2)
        default:
            return settled
        }
    }

    private func pokeballCenter(in layout: BattleViewportLayout) -> CGPoint {
        let start: CGPoint
        let end: CGPoint
        if presentation.activeSide == .enemy {
            start = layout.enemyTrainerPokeballOrigin
            end = layout.enemyTrainerPokemonOrigin
        } else {
            start = layout.playerTrainerPokeballOrigin
            end = layout.playerTrainerPokemonOrigin
        }

        return quadraticBezier(
            start: start,
            control: CGPoint(
                x: (start.x + end.x) / 2,
                y: min(start.y, end.y) - layout.size.height * 0.12
            ),
            end: end,
            progress: sendOutBallProgress
        )
    }

    private func interpolate(from start: CGPoint, to end: CGPoint, progress: CGFloat) -> CGPoint {
        CGPoint(
            x: start.x + ((end.x - start.x) * progress),
            y: start.y + ((end.y - start.y) * progress)
        )
    }

    private func quadraticBezier(start: CGPoint, control: CGPoint, end: CGPoint, progress: CGFloat) -> CGPoint {
        let t = max(0, min(1, progress))
        let inverseT = 1 - t
        let x = (inverseT * inverseT * start.x) + (2 * inverseT * t * control.x) + (t * t * end.x)
        let y = (inverseT * inverseT * start.y) + (2 * inverseT * t * control.y) + (t * t * end.y)
        return CGPoint(x: x, y: y)
    }

    @MainActor
    private func runSendOutAnimationSequence() async {
        guard presentation.stage == .enemySendOut else {
            sendOutBallProgress = 1
            sendOutBallOpacity = 0
            sendOutPokemonProgress = 1
            sendOutPokemonVisibility = 1
            return
        }

        sendOutBallProgress = 0
        sendOutBallOpacity = 1
        sendOutPokemonProgress = 0
        sendOutPokemonVisibility = 0

        withAnimation(.linear(duration: 0.16)) {
            sendOutBallProgress = 1
        }

        try? await Task.sleep(nanoseconds: 120_000_000)
        guard Task.isCancelled == false else { return }

        withAnimation(.easeOut(duration: 0.08)) {
            sendOutBallOpacity = 0
        }
        sendOutPokemonVisibility = 1
        withAnimation(.spring(response: 0.24, dampingFraction: 0.76)) {
            sendOutPokemonProgress = 1
        }
    }

    private var battleBackground: some View {
        ZStack {
            Rectangle()
                .fill(Color(red: 0.49, green: 0.56, blue: 0.17))

            LinearGradient(
                colors: [
                    Color.white.opacity(0.03),
                    Color.clear,
                    Color.black.opacity(0.04),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var spriteAnimation: Animation? {
        switch presentation.stage {
        case .introCrossing:
            return .linear(duration: 0.55)
        case .enemySendOut:
            return .spring(response: 0.34, dampingFraction: 0.8)
        default:
            return .easeInOut(duration: 0.24)
        }
    }

    private var hudAnimation: Animation {
        switch presentation.stage {
        case .introReveal:
            return .easeOut(duration: 0.18)
        default:
            return .easeInOut(duration: 0.24)
        }
    }
}

private struct BattlePokeballToken: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.95))
            Circle()
                .stroke(Color.black.opacity(0.82), lineWidth: 1.5)
            Rectangle()
                .fill(Color.black.opacity(0.82))
                .frame(height: 1.5)
            Circle()
                .fill(Color.black.opacity(0.82))
                .frame(width: 4, height: 4)
        }
    }
}

struct BattleViewportLayout {
    let size: CGSize

    var enemyCardSize: CGSize {
        CGSize(width: size.width * 0.38, height: size.height * 0.105)
    }

    var playerCardSize: CGSize {
        CGSize(width: size.width * 0.41, height: size.height * 0.135)
    }

    var enemyCardCenter: CGPoint {
        CGPoint(x: size.width * 0.26, y: size.height * 0.135)
    }

    var playerCardCenter: CGPoint {
        CGPoint(x: size.width * 0.7, y: size.height * 0.6)
    }

    var enemyTrainerSize: CGSize {
        CGSize(width: size.width * 0.25, height: size.height * 0.34)
    }

    var playerTrainerSize: CGSize {
        CGSize(width: size.width * 0.24, height: size.height * 0.34)
    }

    var enemyTrainerCenter: CGPoint {
        CGPoint(
            x: enemySpriteCenter.x,
            y: enemySpriteCenter.y + (enemySpriteSize.height - enemyTrainerSize.height) * 0.5
        )
    }

    var playerTrainerCenter: CGPoint {
        CGPoint(
            x: playerSpriteCenter.x,
            y: playerSpriteCenter.y + (playerSpriteSize.height - playerTrainerSize.height) * 0.5
        )
    }

    var enemySpriteSize: CGSize {
        CGSize(width: size.width * 0.3, height: size.height * 0.3)
    }

    var playerSpriteSize: CGSize {
        CGSize(width: size.width * 0.28, height: size.height * 0.28)
    }

    var enemySpriteCenter: CGPoint {
        CGPoint(x: size.width * 0.72, y: size.height * 0.3)
    }

    var playerSpriteCenter: CGPoint {
        CGPoint(x: size.width * 0.25, y: size.height * 0.69)
    }

    var enemyTrainerPokeballOrigin: CGPoint {
        CGPoint(
            x: enemyTrainerCenter.x - enemyTrainerSize.width * 0.24,
            y: enemyTrainerCenter.y + 4
        )
    }

    var playerTrainerPokeballOrigin: CGPoint {
        CGPoint(
            x: playerTrainerCenter.x + playerTrainerSize.width * 0.18,
            y: playerTrainerCenter.y - 2
        )
    }

    var enemyTrainerPokemonOrigin: CGPoint {
        CGPoint(
            x: enemyTrainerCenter.x - enemyTrainerSize.width * 0.3,
            y: enemyTrainerCenter.y - enemyTrainerSize.height * 0.04
        )
    }

    var playerTrainerPokemonOrigin: CGPoint {
        CGPoint(
            x: playerTrainerCenter.x + playerTrainerSize.width * 0.22,
            y: playerTrainerCenter.y - playerTrainerSize.height * 0.16
        )
    }
}
