import Foundation
import PokeDataModel

public struct FieldObjectRenderState: Equatable, Sendable {
    public let id: String
    public let displayName: String
    public let sprite: String
    public let position: TilePoint
    public let facing: FacingDirection
    public let interactionDialogueID: String?
    public let trainerBattleID: String?

    public init(
        id: String,
        displayName: String,
        sprite: String,
        position: TilePoint,
        facing: FacingDirection,
        interactionDialogueID: String?,
        trainerBattleID: String?
    ) {
        self.id = id
        self.displayName = displayName
        self.sprite = sprite
        self.position = position
        self.facing = facing
        self.interactionDialogueID = interactionDialogueID
        self.trainerBattleID = trainerBattleID
    }
}

struct RuntimeObjectState {
    var position: TilePoint
    var facing: FacingDirection
    var visible: Bool
}

struct RuntimeMoveState {
    let id: String
    var currentPP: Int
}

struct RuntimePokemonState {
    let speciesID: String
    let nickname: String
    let level: Int
    let maxHP: Int
    var currentHP: Int
    let attack: Int
    let defense: Int
    let speed: Int
    let special: Int
    var attackStage: Int
    var defenseStage: Int
    var moves: [RuntimeMoveState]
}

struct RuntimeBattleState {
    let battleID: String
    let trainerName: String
    let playerStarterSpeciesID: String
    let enemyStarterSpeciesID: String
    let completionFlagID: String
    let healsPartyAfterBattle: Bool
    let preventsBlackoutOnLoss: Bool
    let winDialogueID: String
    let loseDialogueID: String
    var playerPokemon: RuntimePokemonState
    var enemyPokemon: RuntimePokemonState
    var focusedMoveIndex: Int
    var message: String
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
    case startLabIntro
    case hideObject(String)
}

struct GameplayState {
    var mapID: String
    var playerPosition: TilePoint
    var facing: FacingDirection
    var objectStates: [String: RuntimeObjectState]
    var activeFlags: Set<String>
    var gotStarterBit: Bool
    var playerName: String
    var rivalName: String
    var playerParty: [RuntimePokemonState]
    var chosenStarterSpeciesID: String?
    var rivalStarterSpeciesID: String?
    var pendingStarterSpeciesID: String?
    var activeScriptID: String?
    var activeScriptStep: Int?
    var battle: RuntimeBattleState?
}
