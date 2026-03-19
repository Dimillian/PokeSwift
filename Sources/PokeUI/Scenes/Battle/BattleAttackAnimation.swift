import CoreGraphics
import Foundation
import PokeDataModel

struct BattleAttackAnimationTilePlacement: Equatable {
    let tilesetID: String
    let x: Int
    let y: Int
    let tileID: Int
    let flipH: Bool
    let flipV: Bool

    static let oamViewportOrigin = CGSize(width: 8, height: 16)

    var atlasFrame: CGRect {
        CGRect(
            x: (tileID % 16) * BattleAttackAnimationTimeline.tileSize,
            y: (tileID / 16) * BattleAttackAnimationTimeline.tileSize,
            width: BattleAttackAnimationTimeline.tileSize,
            height: BattleAttackAnimationTimeline.tileSize
        )
    }

    var viewportOffset: CGSize {
        // Battle animation placements are extracted in GB OAM coordinates.
        // Convert them to the visible viewport origin before SwiftUI renders
        // them so overlays line up with the battle sprites.
        CGSize(
            width: CGFloat(x) - Self.oamViewportOrigin.width,
            height: CGFloat(y) - Self.oamViewportOrigin.height
        )
    }

}

enum BattleAttackAnimationParticleKind: Equatable {
    case orb
    case droplet
    case leaf
    case petal
}

struct BattleAttackAnimationParticlePlacement: Equatable {
    let kind: BattleAttackAnimationParticleKind
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
    let rotationDegrees: Double
    let opacity: Double
}

struct BattleAttackAnimationVisualState: Equatable {
    let playerOffset: CGSize
    let enemyOffset: CGSize
    let playerScale: CGFloat
    let enemyScale: CGFloat
    let playerOpacity: Double
    let enemyOpacity: Double
    let overlayPlacements: [BattleAttackAnimationTilePlacement]
    let particlePlacements: [BattleAttackAnimationParticlePlacement]
    let screenShake: CGSize
    let flashOpacity: Double
    let darknessOpacity: Double
    let enemyHUDOffset: CGSize

    init(
        playerOffset: CGSize = .zero,
        enemyOffset: CGSize = .zero,
        playerScale: CGFloat = 1,
        enemyScale: CGFloat = 1,
        playerOpacity: Double = 1,
        enemyOpacity: Double = 1,
        overlayPlacements: [BattleAttackAnimationTilePlacement] = [],
        particlePlacements: [BattleAttackAnimationParticlePlacement] = [],
        screenShake: CGSize = .zero,
        flashOpacity: Double = 0,
        darknessOpacity: Double = 0,
        enemyHUDOffset: CGSize = .zero
    ) {
        self.playerOffset = playerOffset
        self.enemyOffset = enemyOffset
        self.playerScale = playerScale
        self.enemyScale = enemyScale
        self.playerOpacity = playerOpacity
        self.enemyOpacity = enemyOpacity
        self.overlayPlacements = overlayPlacements
        self.particlePlacements = particlePlacements
        self.screenShake = screenShake
        self.flashOpacity = flashOpacity
        self.darknessOpacity = darknessOpacity
        self.enemyHUDOffset = enemyHUDOffset
    }

    func with(
        playerOffset: CGSize? = nil,
        enemyOffset: CGSize? = nil,
        playerScale: CGFloat? = nil,
        enemyScale: CGFloat? = nil,
        playerOpacity: Double? = nil,
        enemyOpacity: Double? = nil,
        overlayPlacements: [BattleAttackAnimationTilePlacement]? = nil,
        particlePlacements: [BattleAttackAnimationParticlePlacement]? = nil,
        screenShake: CGSize? = nil,
        flashOpacity: Double? = nil,
        darknessOpacity: Double? = nil,
        enemyHUDOffset: CGSize? = nil
    ) -> BattleAttackAnimationVisualState {
        .init(
            playerOffset: playerOffset ?? self.playerOffset,
            enemyOffset: enemyOffset ?? self.enemyOffset,
            playerScale: playerScale ?? self.playerScale,
            enemyScale: enemyScale ?? self.enemyScale,
            playerOpacity: playerOpacity ?? self.playerOpacity,
            enemyOpacity: enemyOpacity ?? self.enemyOpacity,
            overlayPlacements: overlayPlacements ?? self.overlayPlacements,
            particlePlacements: particlePlacements ?? self.particlePlacements,
            screenShake: screenShake ?? self.screenShake,
            flashOpacity: flashOpacity ?? self.flashOpacity,
            darknessOpacity: darknessOpacity ?? self.darknessOpacity,
            enemyHUDOffset: enemyHUDOffset ?? self.enemyHUDOffset
        )
    }

    static let idle = BattleAttackAnimationVisualState()
}

struct BattleAttackAnimationKeyframe: Equatable {
    let duration: TimeInterval
    let state: BattleAttackAnimationVisualState
}

enum BattleAttackAnimationTimeline {
    static let tileSize = 8
    private static let viewportWidth = 160
    private static let viewportHeight = 144
    private static let oamWidth = 168
    private static let oamHeight = 136

    static func sequence(
        for playback: BattleAttackAnimationPlaybackTelemetry,
        manifest: BattleAnimationManifest
    ) -> [BattleAttackAnimationKeyframe] {
        guard let moveAnimation = manifest.moveAnimations.first(where: { $0.moveID == playback.moveID }) else {
            return []
        }

        let totalFrames = max(1, totalFrameCount(for: moveAnimation, manifest: manifest))
        let secondsPerFrame = playback.totalDuration / Double(totalFrames)
        var keyframes: [BattleAttackAnimationKeyframe] = []

        for command in moveAnimation.commands {
            switch command.kind {
            case .subanimation:
                keyframes.append(
                    contentsOf: subanimationKeyframes(
                        for: command,
                        attackerSide: playback.attackerSide,
                        manifest: manifest,
                        secondsPerFrame: secondsPerFrame
                    )
                )
            case .specialEffect:
                keyframes.append(
                    contentsOf: specialEffectKeyframes(
                        for: command.specialEffectID,
                        attackerSide: playback.attackerSide,
                        secondsPerFrame: secondsPerFrame
                    )
                )
            }
        }

        return keyframes
    }

    static func totalFrameCount(
        for moveAnimation: BattleMoveAnimationManifest,
        manifest: BattleAnimationManifest
    ) -> Int {
        moveAnimation.commands.reduce(0) { partialResult, command in
            partialResult + commandFrameCount(command, manifest: manifest)
        }
    }

    static func commandFrameCount(
        _ command: BattleAnimationCommandManifest,
        manifest: BattleAnimationManifest
    ) -> Int {
        switch command.kind {
        case .specialEffect:
            return BattleAnimationPlaybackDefaults.specialEffectFrameCount(id: command.specialEffectID)
        case .subanimation:
            let delayFrames = max(1, command.delayFrames ?? 1)
            guard let subanimationID = command.subanimationID,
                  let subanimation = manifest.subanimations.first(where: { $0.id == subanimationID }),
                  subanimation.steps.isEmpty == false else {
                return delayFrames
            }
            let visibleFrames = subanimation.steps.reduce(0) { partialResult, step in
                partialResult + (step.frameBlockMode == .mode02 ? 0 : delayFrames)
            }
            return max(1, visibleFrames)
        }
    }

    private static func subanimationKeyframes(
        for command: BattleAnimationCommandManifest,
        attackerSide: BattlePresentationSide,
        manifest: BattleAnimationManifest,
        secondsPerFrame: TimeInterval
    ) -> [BattleAttackAnimationKeyframe] {
        guard let subanimationID = command.subanimationID,
              let tilesetID = command.tilesetID,
              let subanimation = manifest.subanimations.first(where: { $0.id == subanimationID }) else {
            return []
        }

        let actualTransform = resolvedTransform(for: subanimation.transform, attackerSide: attackerSide)
        let drawTransform: BattleAnimationTransform = actualTransform == .reverse ? .normal : actualTransform
        let orderedSteps = actualTransform == .reverse ? Array(subanimation.steps.reversed()) : subanimation.steps
        let delayFrames = max(1, command.delayFrames ?? 1)

        var keyframes: [BattleAttackAnimationKeyframe] = []
        var buffer: [BattleAttackAnimationTilePlacement] = []
        var destinationIndex = 0

        for step in orderedSteps {
            guard let frameBlock = manifest.frameBlocks.first(where: { $0.id == step.frameBlockID }),
                  let baseCoordinate = manifest.baseCoordinates.first(where: { $0.id == step.baseCoordinateID }) else {
                continue
            }

            let placements = renderPlacements(
                frameBlock: frameBlock,
                baseCoordinate: baseCoordinate,
                transform: drawTransform,
                tilesetID: tilesetID
            )
            write(placements: placements, to: &buffer, startingAt: destinationIndex)

            if step.frameBlockMode != .mode02 {
                keyframes.append(
                    BattleAttackAnimationKeyframe(
                        duration: secondsPerFrame * Double(delayFrames),
                        state: .init(
                            playerOffset: .zero,
                            enemyOffset: .zero,
                            playerScale: 1,
                            enemyScale: 1,
                            playerOpacity: 1,
                            enemyOpacity: 1,
                            overlayPlacements: buffer,
                            screenShake: .zero,
                            flashOpacity: 0,
                            darknessOpacity: 0
                        )
                    )
                )
            }

            switch step.frameBlockMode {
            case .mode02, .mode03:
                destinationIndex += placements.count
            case .mode04:
                break
            case .mode00, .mode01:
                buffer.removeAll()
                destinationIndex = 0
            }
        }

        return keyframes
    }

    private static func specialEffectKeyframes(
        for effectID: String?,
        attackerSide: BattlePresentationSide,
        secondsPerFrame: TimeInterval
    ) -> [BattleAttackAnimationKeyframe] {
        let frameCount = BattleAnimationPlaybackDefaults.specialEffectFrameCount(id: effectID)
        return (0..<max(1, frameCount)).map { index in
            let denominator = max(1, frameCount - 1)
            let progress = CGFloat(Double(index) / Double(denominator))
            return BattleAttackAnimationKeyframe(
                duration: secondsPerFrame,
                state: visualState(
                    for: effectID,
                    attackerSide: attackerSide,
                    progress: progress,
                    isBlinkFrame: index.isMultiple(of: 2)
                )
            )
        }
    }

    private static func visualState(
        for effectID: String?,
        attackerSide: BattlePresentationSide,
        progress: CGFloat,
        isBlinkFrame: Bool
    ) -> BattleAttackAnimationVisualState {
        var state = BattleAttackAnimationVisualState.idle
        let attackerDirection: CGFloat = attackerSide == .player ? 1 : -1

        func applyToAttacker(offset: CGSize = .zero, scale: CGFloat = 1, opacity: Double = 1) {
            if attackerSide == .player {
                state = state.with(
                    playerOffset: offset,
                    playerScale: scale,
                    playerOpacity: opacity
                )
            } else {
                state = state.with(
                    enemyOffset: offset,
                    enemyScale: scale,
                    enemyOpacity: opacity
                )
            }
        }

        func applyToDefender(offset: CGSize = .zero, scale: CGFloat = 1, opacity: Double = 1) {
            if attackerSide == .player {
                state = state.with(
                    enemyOffset: offset,
                    enemyScale: scale,
                    enemyOpacity: opacity
                )
            } else {
                state = state.with(
                    playerOffset: offset,
                    playerScale: scale,
                    playerOpacity: opacity
                )
            }
        }

        func defenderFocusPoint() -> CGPoint {
            attackerSide == .player
                ? CGPoint(x: 112, y: 46)
                : CGPoint(x: 52, y: 96)
        }

        func attackerFocusPoint() -> CGPoint {
            attackerSide == .player
                ? CGPoint(x: 52, y: 96)
                : CGPoint(x: 112, y: 46)
        }

        switch effectID {
        case "SE_DARK_SCREEN_FLASH":
            state = .init(
                playerOffset: .zero,
                enemyOffset: .zero,
                playerScale: 1,
                enemyScale: 1,
                playerOpacity: 1,
                enemyOpacity: 1,
                overlayPlacements: [],
                particlePlacements: [],
                screenShake: .zero,
                flashOpacity: Double(0.75 - (0.35 * progress)),
                darknessOpacity: Double(0.2 + (0.2 * progress)),
                enemyHUDOffset: .zero
            )
        case "SE_FLASH_SCREEN_LONG", "SE_LIGHT_SCREEN_PALETTE":
            state = .init(
                playerOffset: .zero,
                enemyOffset: .zero,
                playerScale: 1,
                enemyScale: 1,
                playerOpacity: 1,
                enemyOpacity: 1,
                overlayPlacements: [],
                particlePlacements: [],
                screenShake: .zero,
                flashOpacity: Double(0.55 - (0.3 * progress)),
                darknessOpacity: 0,
                enemyHUDOffset: .zero
            )
        case "SE_DARK_SCREEN_PALETTE", "SE_DARKEN_MON_PALETTE":
            state = .init(
                playerOffset: .zero,
                enemyOffset: .zero,
                playerScale: 1,
                enemyScale: 1,
                playerOpacity: 1,
                enemyOpacity: 1,
                overlayPlacements: [],
                particlePlacements: [],
                screenShake: .zero,
                flashOpacity: 0,
                darknessOpacity: 0.35,
                enemyHUDOffset: .zero
            )
        case "SE_SHAKE_SCREEN":
            state = .init(
                playerOffset: .zero,
                enemyOffset: .zero,
                playerScale: 1,
                enemyScale: 1,
                playerOpacity: 1,
                enemyOpacity: 1,
                overlayPlacements: [],
                particlePlacements: [],
                screenShake: CGSize(width: sin(progress * .pi * 6) * 3, height: cos(progress * .pi * 4) * 1.5),
                flashOpacity: 0,
                darknessOpacity: 0,
                enemyHUDOffset: .zero
            )
        case "SE_MOVE_MON_HORIZONTALLY":
            applyToAttacker(offset: .init(width: attackerDirection * sin(progress * .pi) * 14, height: 0))
        case "SE_SHAKE_BACK_AND_FORTH":
            applyToAttacker(offset: .init(width: attackerDirection * sin(progress * .pi * 6) * 8, height: 0))
        case "SE_BOUNCE_UP_AND_DOWN":
            applyToAttacker(offset: .init(width: 0, height: -abs(sin(progress * .pi * 2)) * 10))
        case "SE_SLIDE_MON_UP":
            applyToAttacker(offset: .init(width: 0, height: -14 * progress))
        case "SE_SLIDE_MON_DOWN":
            applyToAttacker(offset: .init(width: 0, height: 14 * progress))
        case "SE_SLIDE_MON_OFF":
            applyToAttacker(offset: .init(width: attackerDirection * 42 * progress, height: 0), opacity: Double(1 - progress))
        case "SE_SLIDE_MON_HALF_OFF":
            applyToAttacker(offset: .init(width: attackerDirection * 20 * progress, height: 0))
        case "SE_SLIDE_MON_DOWN_AND_HIDE":
            applyToAttacker(offset: .init(width: 0, height: 18 * progress), opacity: Double(1 - progress))
        case "SE_SHOW_MON_PIC":
            applyToAttacker(opacity: Double(progress))
        case "SE_HIDE_MON_PIC":
            applyToAttacker(opacity: 0)
        case "SE_BLINK_MON":
            applyToAttacker(opacity: isBlinkFrame ? 0.2 : 1)
        case "SE_FLASH_MON_PIC":
            applyToAttacker(opacity: isBlinkFrame ? 0.2 : 1)
        case "SE_MINIMIZE_MON":
            applyToAttacker(scale: max(0.55, 1 - (0.45 * progress)))
        case "SE_SUBSTITUTE_MON", "SE_SQUISH_MON_PIC":
            applyToAttacker(scale: max(0.65, 1 - (0.35 * progress)))
        case "SE_SHOW_ENEMY_MON_PIC":
            applyToDefender(opacity: Double(progress))
        case "SE_HIDE_ENEMY_MON_PIC":
            applyToDefender(opacity: 0)
        case "SE_BLINK_ENEMY_MON", "SE_FLASH_ENEMY_MON_PIC":
            applyToDefender(opacity: isBlinkFrame ? 0.2 : 1)
        case "SE_SLIDE_ENEMY_MON_OFF":
            applyToDefender(offset: .init(width: -attackerDirection * 42 * progress, height: 0), opacity: Double(1 - progress))
        case "SE_TRANSFORM_MON":
            let pulse = 0.8 + (abs(sin(progress * .pi * 4)) * 0.22)
            let shimmerOpacity = Double(0.58 + (abs(cos(progress * .pi * 4)) * 0.42))
            applyToAttacker(scale: pulse, opacity: shimmerOpacity)
            state = state.with(
                flashOpacity: Double(abs(sin(progress * .pi * 4)) * 0.2),
                darknessOpacity: Double((1 - progress) * 0.12)
            )
        case "SE_SPIRAL_BALLS_INWARD":
            state = state.with(
                particlePlacements: spiralParticles(
                    around: defenderFocusPoint(),
                    progress: progress
                )
            )
        case "SE_WATER_DROPLETS_EVERYWHERE":
            state = state.with(
                particlePlacements: waterDropletParticles(progress: progress)
            )
        case "SE_LEAVES_FALLING":
            state = state.with(
                particlePlacements: fallingParticles(
                    kind: .leaf,
                    progress: progress,
                    driftAmplitude: 14,
                    verticalTravel: 118,
                    baseRotation: 75
                )
            )
        case "SE_PETALS_FALLING":
            state = state.with(
                particlePlacements: fallingParticles(
                    kind: .petal,
                    progress: progress,
                    driftAmplitude: 10,
                    verticalTravel: 108,
                    baseRotation: 130
                )
            )
        case "SE_SHOOT_BALLS_UPWARD":
            state = state.with(
                particlePlacements: upwardShotParticles(
                    origin: attackerFocusPoint(),
                    progress: progress,
                    count: 3
                )
            )
        case "SE_SHOOT_MANY_BALLS_UPWARD":
            state = state.with(
                particlePlacements: upwardShotParticles(
                    origin: attackerFocusPoint(),
                    progress: progress,
                    count: 5
                )
            )
        case "SE_SHAKE_ENEMY_HUD", "SE_SHAKE_ENEMY_HUD_2":
            state = state.with(
                enemyHUDOffset: .init(width: sin(progress * .pi * 8) * 3, height: 0)
            )
        case "SE_WAVY_SCREEN":
            state = .init(
                playerOffset: .zero,
                enemyOffset: .zero,
                playerScale: 1,
                enemyScale: 1,
                playerOpacity: 1,
                enemyOpacity: 1,
                overlayPlacements: [],
                particlePlacements: [],
                screenShake: CGSize(width: sin(progress * .pi * 4) * 2, height: 0),
                flashOpacity: 0,
                darknessOpacity: 0,
                enemyHUDOffset: .zero
            )
        default:
            break
        }

        return state
    }

    private static func spiralParticles(
        around center: CGPoint,
        progress: CGFloat
    ) -> [BattleAttackAnimationParticlePlacement] {
        let rotations: CGFloat = 1.8
        let radius = max(4, 28 - (progress * 22))
        return (0..<4).map { index in
            let phase = (CGFloat(index) / 4) * (.pi * 2)
            let angle = (progress * (.pi * 2) * rotations) + phase
            return .init(
                kind: .orb,
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius * 0.7,
                width: 6,
                height: 6,
                rotationDegrees: Double(angle * 180 / .pi),
                opacity: Double(0.55 + ((1 - progress) * 0.35))
            )
        }
    }

    private static func waterDropletParticles(
        progress: CGFloat
    ) -> [BattleAttackAnimationParticlePlacement] {
        (0..<8).map { index in
            let baseX = CGFloat(12 + (index * 18))
            let startY = CGFloat(-18 - ((index % 3) * 8))
            let travel = progress * 132
            let drift = sin((progress * .pi * 2) + (CGFloat(index) * 0.6)) * 4
            return .init(
                kind: .droplet,
                x: min(CGFloat(viewportWidth - 8), baseX + drift),
                y: startY + travel,
                width: 4,
                height: 9,
                rotationDegrees: Double(drift * 3),
                opacity: Double(0.7 + (0.2 * (1 - progress)))
            )
        }
    }

    private static func fallingParticles(
        kind: BattleAttackAnimationParticleKind,
        progress: CGFloat,
        driftAmplitude: CGFloat,
        verticalTravel: CGFloat,
        baseRotation: Double
    ) -> [BattleAttackAnimationParticlePlacement] {
        (0..<6).map { index in
            let laneProgress = progress + (CGFloat(index) * 0.03)
            let wrappedProgress = laneProgress.truncatingRemainder(dividingBy: 1)
            let baseX = CGFloat(18 + (index * 22))
            let startY = CGFloat(-20 - ((index % 2) * 10))
            let drift = sin((wrappedProgress * .pi * 2) + (CGFloat(index) * 0.75)) * driftAmplitude
            let size: CGFloat = kind == .leaf ? 8 : 6
            return .init(
                kind: kind,
                x: baseX + drift,
                y: startY + (wrappedProgress * verticalTravel),
                width: size,
                height: kind == .leaf ? 4 : 5,
                rotationDegrees: baseRotation + Double((wrappedProgress * 360) + (CGFloat(index) * 20)),
                opacity: Double(0.65 + (0.25 * (1 - wrappedProgress)))
            )
        }
    }

    private static func upwardShotParticles(
        origin: CGPoint,
        progress: CGFloat,
        count: Int
    ) -> [BattleAttackAnimationParticlePlacement] {
        let halfSpread = CGFloat(count - 1) / 2
        return (0..<count).map { index in
            let relativeIndex = CGFloat(index) - halfSpread
            let xSpread = relativeIndex * 8
            let arcLift = abs(sin((progress * .pi * 2) + (CGFloat(index) * 0.4))) * 5
            return .init(
                kind: .orb,
                x: origin.x + xSpread + (relativeIndex * progress * 2),
                y: origin.y - (progress * 48) - arcLift,
                width: 5,
                height: 5,
                rotationDegrees: Double(relativeIndex * 24),
                opacity: Double(0.5 + ((1 - progress) * 0.45))
            )
        }
    }

    private static func renderPlacements(
        frameBlock: BattleAnimationFrameBlockManifest,
        baseCoordinate: BattleAnimationBaseCoordinateManifest,
        transform: BattleAnimationTransform,
        tilesetID: String
    ) -> [BattleAttackAnimationTilePlacement] {
        frameBlock.tiles.map { tile in
            let transformed = transformedTile(tile, baseCoordinate: baseCoordinate, transform: transform)
            return BattleAttackAnimationTilePlacement(
                tilesetID: tilesetID,
                x: transformed.x,
                y: transformed.y,
                tileID: tile.tileID,
                flipH: transformed.flipH,
                flipV: transformed.flipV
            )
        }
    }

    private static func transformedTile(
        _ tile: BattleAnimationFrameTileManifest,
        baseCoordinate: BattleAnimationBaseCoordinateManifest,
        transform: BattleAnimationTransform
    ) -> (x: Int, y: Int, flipH: Bool, flipV: Bool) {
        switch transform {
        case .hvFlip:
            return (
                x: oamWidth - (baseCoordinate.x + tile.x),
                y: oamHeight - (baseCoordinate.y + tile.y),
                flipH: !tile.flipH,
                flipV: !tile.flipV
            )
        case .hFlip:
            return (
                x: oamWidth - (baseCoordinate.x + tile.x),
                y: baseCoordinate.y + tile.y + 40,
                flipH: !tile.flipH,
                flipV: tile.flipV
            )
        case .coordFlip:
            return (
                x: oamWidth - baseCoordinate.x + tile.x,
                y: oamHeight - baseCoordinate.y + tile.y,
                flipH: tile.flipH,
                flipV: tile.flipV
            )
        case .normal, .reverse, .enemy:
            return (
                x: baseCoordinate.x + tile.x,
                y: baseCoordinate.y + tile.y,
                flipH: tile.flipH,
                flipV: tile.flipV
            )
        }
    }

    private static func resolvedTransform(
        for transform: BattleAnimationTransform,
        attackerSide: BattlePresentationSide
    ) -> BattleAnimationTransform {
        switch transform {
        case .enemy:
            return attackerSide == .player ? .hFlip : .normal
        default:
            return attackerSide == .player ? .normal : transform
        }
    }

    private static func write(
        placements: [BattleAttackAnimationTilePlacement],
        to buffer: inout [BattleAttackAnimationTilePlacement],
        startingAt destinationIndex: Int
    ) {
        for (offset, placement) in placements.enumerated() {
            let targetIndex = destinationIndex + offset
            if buffer.indices.contains(targetIndex) {
                buffer[targetIndex] = placement
            } else {
                buffer.append(placement)
            }
        }
    }
}
