import Foundation

public struct BattleAnimationManifest: Codable, Equatable, Sendable {
    public let variant: GameVariant
    public let sourceFiles: [String]
    public let moveAnimations: [BattleMoveAnimationManifest]
    public let subanimations: [BattleSubanimationManifest]
    public let frameBlocks: [BattleAnimationFrameBlockManifest]
    public let baseCoordinates: [BattleAnimationBaseCoordinateManifest]
    public let specialEffects: [BattleAnimationSpecialEffectManifest]
    public let tilesets: [BattleAnimationTilesetManifest]

    public init(
        variant: GameVariant,
        sourceFiles: [String] = [],
        moveAnimations: [BattleMoveAnimationManifest],
        subanimations: [BattleSubanimationManifest],
        frameBlocks: [BattleAnimationFrameBlockManifest],
        baseCoordinates: [BattleAnimationBaseCoordinateManifest],
        specialEffects: [BattleAnimationSpecialEffectManifest],
        tilesets: [BattleAnimationTilesetManifest]
    ) {
        self.variant = variant
        self.sourceFiles = sourceFiles
        self.moveAnimations = moveAnimations
        self.subanimations = subanimations
        self.frameBlocks = frameBlocks
        self.baseCoordinates = baseCoordinates
        self.specialEffects = specialEffects
        self.tilesets = tilesets
    }

    public static let empty = BattleAnimationManifest(
        variant: .red,
        moveAnimations: [],
        subanimations: [],
        frameBlocks: [],
        baseCoordinates: [],
        specialEffects: [],
        tilesets: []
    )
}

public struct BattleMoveAnimationManifest: Codable, Equatable, Sendable {
    public let moveID: String
    public let commands: [BattleAnimationCommandManifest]

    public init(moveID: String, commands: [BattleAnimationCommandManifest]) {
        self.moveID = moveID
        self.commands = commands
    }
}

public enum BattleAnimationCommandKind: String, Codable, Equatable, Sendable {
    case subanimation
    case specialEffect
}

public struct BattleAnimationCommandManifest: Codable, Equatable, Sendable {
    public let kind: BattleAnimationCommandKind
    public let soundMoveID: String?
    public let subanimationID: String?
    public let specialEffectID: String?
    public let tilesetID: String?
    public let delayFrames: Int?

    public init(
        kind: BattleAnimationCommandKind,
        soundMoveID: String? = nil,
        subanimationID: String? = nil,
        specialEffectID: String? = nil,
        tilesetID: String? = nil,
        delayFrames: Int? = nil
    ) {
        self.kind = kind
        self.soundMoveID = soundMoveID
        self.subanimationID = subanimationID
        self.specialEffectID = specialEffectID
        self.tilesetID = tilesetID
        self.delayFrames = delayFrames
    }
}

public enum BattleAnimationTransform: String, Codable, Equatable, Sendable {
    case normal = "SUBANIMTYPE_NORMAL"
    case hvFlip = "SUBANIMTYPE_HVFLIP"
    case hFlip = "SUBANIMTYPE_HFLIP"
    case coordFlip = "SUBANIMTYPE_COORDFLIP"
    case reverse = "SUBANIMTYPE_REVERSE"
    case enemy = "SUBANIMTYPE_ENEMY"
}

public enum BattleAnimationFrameBlockMode: String, Codable, Equatable, Sendable {
    case mode00 = "FRAMEBLOCKMODE_00"
    case mode01 = "FRAMEBLOCKMODE_01"
    case mode02 = "FRAMEBLOCKMODE_02"
    case mode03 = "FRAMEBLOCKMODE_03"
    case mode04 = "FRAMEBLOCKMODE_04"
}

public struct BattleSubanimationManifest: Codable, Equatable, Sendable {
    public let id: String
    public let transform: BattleAnimationTransform
    public let steps: [BattleAnimationSubanimationStepManifest]

    public init(
        id: String,
        transform: BattleAnimationTransform,
        steps: [BattleAnimationSubanimationStepManifest]
    ) {
        self.id = id
        self.transform = transform
        self.steps = steps
    }
}

public struct BattleAnimationSubanimationStepManifest: Codable, Equatable, Sendable {
    public let frameBlockID: String
    public let baseCoordinateID: String
    public let frameBlockMode: BattleAnimationFrameBlockMode

    public init(
        frameBlockID: String,
        baseCoordinateID: String,
        frameBlockMode: BattleAnimationFrameBlockMode
    ) {
        self.frameBlockID = frameBlockID
        self.baseCoordinateID = baseCoordinateID
        self.frameBlockMode = frameBlockMode
    }
}

public struct BattleAnimationFrameBlockManifest: Codable, Equatable, Sendable {
    public let id: String
    public let tiles: [BattleAnimationFrameTileManifest]

    public init(id: String, tiles: [BattleAnimationFrameTileManifest]) {
        self.id = id
        self.tiles = tiles
    }
}

public struct BattleAnimationFrameTileManifest: Codable, Equatable, Sendable {
    public let x: Int
    public let y: Int
    public let tileID: Int
    public let flipH: Bool
    public let flipV: Bool

    public init(
        x: Int,
        y: Int,
        tileID: Int,
        flipH: Bool = false,
        flipV: Bool = false
    ) {
        self.x = x
        self.y = y
        self.tileID = tileID
        self.flipH = flipH
        self.flipV = flipV
    }
}

public struct BattleAnimationBaseCoordinateManifest: Codable, Equatable, Sendable {
    public let id: String
    public let x: Int
    public let y: Int

    public init(id: String, x: Int, y: Int) {
        self.id = id
        self.x = x
        self.y = y
    }
}

public struct BattleAnimationSpecialEffectManifest: Codable, Equatable, Sendable {
    public let id: String
    public let routine: String

    public init(id: String, routine: String) {
        self.id = id
        self.routine = routine
    }
}

public struct BattleAnimationTilesetManifest: Codable, Equatable, Sendable {
    public let id: String
    public let tileCount: Int
    public let imagePath: String

    public init(id: String, tileCount: Int, imagePath: String) {
        self.id = id
        self.tileCount = tileCount
        self.imagePath = imagePath
    }
}

public enum BattleAnimationPlaybackDefaults {
    public static let framesPerSecond: Double = 60

    public static func frameCount(for command: BattleAnimationCommandManifest) -> Int {
        switch command.kind {
        case .subanimation:
            return max(1, command.delayFrames ?? 1)
        case .specialEffect:
            return specialEffectFrameCount(id: command.specialEffectID)
        }
    }

    public static func specialEffectFrameCount(id: String?) -> Int {
        switch id {
        case "SE_DELAY_ANIMATION_10":
            return 10
        case "SE_FLASH_SCREEN_LONG",
             "SE_WAVY_SCREEN",
             "SE_SPIRAL_BALLS_INWARD",
             "SE_TRANSFORM_MON",
             "SE_PETALS_FALLING",
             "SE_LEAVES_FALLING",
             "SE_WATER_DROPLETS_EVERYWHERE":
            return 16
        case "SE_SHAKE_SCREEN",
             "SE_SHAKE_ENEMY_HUD",
             "SE_SHAKE_ENEMY_HUD_2",
             "SE_SHAKE_BACK_AND_FORTH":
            return 8
        case "SE_SLIDE_MON_UP",
             "SE_SLIDE_MON_DOWN",
             "SE_SLIDE_MON_OFF",
             "SE_SLIDE_MON_HALF_OFF",
             "SE_SLIDE_MON_DOWN_AND_HIDE",
             "SE_SLIDE_ENEMY_MON_OFF",
             "SE_SHOW_MON_PIC",
             "SE_SHOW_ENEMY_MON_PIC",
             "SE_HIDE_MON_PIC",
             "SE_HIDE_ENEMY_MON_PIC",
             "SE_BLINK_MON",
             "SE_BLINK_ENEMY_MON",
             "SE_FLASH_MON_PIC",
             "SE_FLASH_ENEMY_MON_PIC",
             "SE_MOVE_MON_HORIZONTALLY",
             "SE_RESET_MON_POSITION",
             "SE_DARK_SCREEN_FLASH",
             "SE_DARK_SCREEN_PALETTE",
             "SE_RESET_SCREEN_PALETTE",
             "SE_LIGHT_SCREEN_PALETTE",
             "SE_DARKEN_MON_PALETTE",
             "SE_SUBSTITUTE_MON",
             "SE_SQUISH_MON_PIC",
             "SE_BOUNCE_UP_AND_DOWN",
             "SE_MINIMIZE_MON",
             "SE_SHOOT_BALLS_UPWARD",
             "SE_SHOOT_MANY_BALLS_UPWARD":
            return 6
        default:
            return 4
        }
    }
}
