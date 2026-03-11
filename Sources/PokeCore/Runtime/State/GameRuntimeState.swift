import Foundation
import PokeDataModel

public struct FieldObjectRenderState: Equatable, Sendable {
    public let id: String
    public let displayName: String
    public let sprite: String
    public let position: TilePoint
    public let facing: FacingDirection
    public let movementBehavior: ObjectMovementBehavior
    public let movementMode: ActorMovementMode?
    public let interactionDialogueID: String?
    public let trainerBattleID: String?

    public init(
        id: String,
        displayName: String,
        sprite: String,
        position: TilePoint,
        facing: FacingDirection,
        movementBehavior: ObjectMovementBehavior = .init(
            idleMode: .stay,
            axis: .none,
            home: .init(x: 0, y: 0),
            maxDistanceFromHome: 0
        ),
        movementMode: ActorMovementMode? = nil,
        interactionDialogueID: String?,
        trainerBattleID: String?
    ) {
        self.id = id
        self.displayName = displayName
        self.sprite = sprite
        self.position = position
        self.facing = facing
        self.movementBehavior = movementBehavior
        self.movementMode = movementMode
        self.interactionDialogueID = interactionDialogueID
        self.trainerBattleID = trainerBattleID
    }
}

struct RuntimeObjectState {
    var position: TilePoint
    var facing: FacingDirection
    var visible: Bool
    var movementMode: ActorMovementMode?
    var idleStepIndex: Int

    init(
        position: TilePoint,
        facing: FacingDirection,
        visible: Bool,
        movementMode: ActorMovementMode? = nil,
        idleStepIndex: Int = 0
    ) {
        self.position = position
        self.facing = facing
        self.visible = visible
        self.movementMode = movementMode
        self.idleStepIndex = idleStepIndex
    }
}

struct RuntimeMoveState {
    let id: String
    var currentPP: Int
}

struct RuntimeInventoryItemState {
    let itemID: String
    var quantity: Int
}

struct RuntimePokemonState {
    let speciesID: String
    let nickname: String
    let level: Int
    let experience: Int
    let dvs: PokemonDVs
    let statExp: PokemonStatExp
    let maxHP: Int
    var currentHP: Int
    let attack: Int
    let defense: Int
    let speed: Int
    let special: Int
    var attackStage: Int
    var defenseStage: Int
    var accuracyStage: Int
    var evasionStage: Int
    var moves: [RuntimeMoveState]
}

enum RuntimeBattlePhase: String {
    case introText
    case moveSelection
    case resolvingTurn
    case turnText
    case battleComplete
}

enum RuntimeBattlePendingAction {
    case moveSelection
    case finish(won: Bool)
    case escape
}

struct RuntimeBattleState {
    let battleID: String
    let kind: BattleKind
    let trainerName: String
    let completionFlagID: String
    let healsPartyAfterBattle: Bool
    let preventsBlackoutOnLoss: Bool
    let winDialogueID: String
    let loseDialogueID: String
    let canRun: Bool
    var playerPokemon: RuntimePokemonState
    var enemyParty: [RuntimePokemonState]
    var enemyActiveIndex: Int
    var phase: RuntimeBattlePhase
    var focusedMoveIndex: Int
    var message: String
    var queuedMessages: [String]
    var pendingAction: RuntimeBattlePendingAction?

    var enemyPokemon: RuntimePokemonState {
        get { enemyParty[enemyActiveIndex] }
        set { enemyParty[enemyActiveIndex] = newValue }
    }
}

struct DialogueState {
    enum CompletionAction {
        case returnToField
        case continueScript
        case healAndShow(dialogueID: String)
        case openStarterChoice(preselectedSpeciesID: String)
        case beginPostChoiceSequence
        case startPostBattleDialogue(won: Bool)
    }

    let dialogueID: String
    var pageIndex: Int
    let completionAction: CompletionAction
}

enum DeferredAction {
    case dialogue(String)
    case battle(String)
    case script(String)
    case hideObject(String)
    case restoreMapMusic
}

struct RuntimeAudioState: Equatable {
    var trackID: String
    var entryID: String
    var reason: String
    var playbackRevision: Int
}

enum RuntimeFieldTransitionKind: String {
    case door
    case warp
}

enum RuntimeFieldTransitionPhase: String {
    case fadingOut
    case fadingIn
    case steppingOut
}

struct RuntimeFieldTransitionState: Equatable {
    var kind: RuntimeFieldTransitionKind
    var phase: RuntimeFieldTransitionPhase
}

struct GameplayState {
    var mapID: String
    var playerPosition: TilePoint
    var facing: FacingDirection
    var objectStates: [String: RuntimeObjectState]
    var activeFlags: Set<String>
    var money: Int
    var inventory: [RuntimeInventoryItemState]
    var earnedBadgeIDs: Set<String>
    var gotStarterBit: Bool
    var playerName: String
    var rivalName: String
    var playerParty: [RuntimePokemonState]
    var chosenStarterSpeciesID: String?
    var rivalStarterSpeciesID: String?
    var pendingStarterSpeciesID: String?
    var activeMapScriptTriggerID: String?
    var activeScriptID: String?
    var activeScriptStep: Int?
    var battle: RuntimeBattleState?
    var encounterStepCounter: Int
    var playTimeSeconds: Int
}
