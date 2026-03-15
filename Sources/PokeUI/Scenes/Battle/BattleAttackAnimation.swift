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

    var atlasFrame: CGRect {
        CGRect(
            x: (tileID % 16) * BattleAttackAnimationTimeline.tileSize,
            y: (tileID / 16) * BattleAttackAnimationTimeline.tileSize,
            width: BattleAttackAnimationTimeline.tileSize,
            height: BattleAttackAnimationTimeline.tileSize
        )
    }
}

struct BattleAttackAnimationVisualState: Equatable {
    let playerOffset: CGSize
    let enemyOffset: CGSize
    let playerScale: CGFloat
    let enemyScale: CGFloat
    let playerOpacity: Double
    let enemyOpacity: Double
    let overlayPlacements: [BattleAttackAnimationTilePlacement]
    let screenShake: CGSize
    let flashOpacity: Double
    let darknessOpacity: Double

    static let idle = BattleAttackAnimationVisualState(
        playerOffset: .zero,
        enemyOffset: .zero,
        playerScale: 1,
        enemyScale: 1,
        playerOpacity: 1,
        enemyOpacity: 1,
        overlayPlacements: [],
        screenShake: .zero,
        flashOpacity: 0,
        darknessOpacity: 0
    )
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
                state = .init(
                    playerOffset: offset,
                    enemyOffset: state.enemyOffset,
                    playerScale: scale,
                    enemyScale: state.enemyScale,
                    playerOpacity: opacity,
                    enemyOpacity: state.enemyOpacity,
                    overlayPlacements: state.overlayPlacements,
                    screenShake: state.screenShake,
                    flashOpacity: state.flashOpacity,
                    darknessOpacity: state.darknessOpacity
                )
            } else {
                state = .init(
                    playerOffset: state.playerOffset,
                    enemyOffset: offset,
                    playerScale: state.playerScale,
                    enemyScale: scale,
                    playerOpacity: state.playerOpacity,
                    enemyOpacity: opacity,
                    overlayPlacements: state.overlayPlacements,
                    screenShake: state.screenShake,
                    flashOpacity: state.flashOpacity,
                    darknessOpacity: state.darknessOpacity
                )
            }
        }

        func applyToDefender(offset: CGSize = .zero, scale: CGFloat = 1, opacity: Double = 1) {
            if attackerSide == .player {
                state = .init(
                    playerOffset: state.playerOffset,
                    enemyOffset: offset,
                    playerScale: state.playerScale,
                    enemyScale: scale,
                    playerOpacity: state.playerOpacity,
                    enemyOpacity: opacity,
                    overlayPlacements: state.overlayPlacements,
                    screenShake: state.screenShake,
                    flashOpacity: state.flashOpacity,
                    darknessOpacity: state.darknessOpacity
                )
            } else {
                state = .init(
                    playerOffset: offset,
                    enemyOffset: state.enemyOffset,
                    playerScale: scale,
                    enemyScale: state.enemyScale,
                    playerOpacity: opacity,
                    enemyOpacity: state.enemyOpacity,
                    overlayPlacements: state.overlayPlacements,
                    screenShake: state.screenShake,
                    flashOpacity: state.flashOpacity,
                    darknessOpacity: state.darknessOpacity
                )
            }
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
                screenShake: .zero,
                flashOpacity: Double(0.75 - (0.35 * progress)),
                darknessOpacity: Double(0.2 + (0.2 * progress))
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
                screenShake: .zero,
                flashOpacity: Double(0.55 - (0.3 * progress)),
                darknessOpacity: 0
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
                screenShake: .zero,
                flashOpacity: 0,
                darknessOpacity: 0.35
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
                screenShake: CGSize(width: sin(progress * .pi * 6) * 3, height: cos(progress * .pi * 4) * 1.5),
                flashOpacity: 0,
                darknessOpacity: 0
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
        case "SE_WAVY_SCREEN":
            state = .init(
                playerOffset: .zero,
                enemyOffset: .zero,
                playerScale: 1,
                enemyScale: 1,
                playerOpacity: 1,
                enemyOpacity: 1,
                overlayPlacements: [],
                screenShake: CGSize(width: sin(progress * .pi * 4) * 2, height: 0),
                flashOpacity: 0,
                darknessOpacity: 0
            )
        default:
            break
        }

        return state
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
