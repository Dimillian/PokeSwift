import Foundation
import PokeDataModel

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
    var majorStatus: MajorStatusCondition
    var moves: [RuntimeMoveState]
}

enum RuntimeBattlePhase: String {
    case introText
    case moveSelection
    case bagSelection
    case partySelection
    case learnMoveDecision
    case learnMoveSelection
    case resolvingTurn
    case turnText
    case battleComplete
}

enum RuntimeBattleCaptureResult: Equatable {
    case uncatchable
    case boxFull
    case failed(shakes: Int)
    case success
}

enum RuntimeBattlePendingAction {
    case moveSelection
    case finish(won: Bool)
    case escape
    case captured
    case continueSwitchTurn
    case continueForcedSwitch
    case continueLevelUpResolution
}

enum RuntimeBattlePartySelectionMode {
    case optionalSwitch
    case forcedReplacement
}

struct RuntimeBattleLearnMoveState {
    let moveID: String
    let remainingMoveIDs: [String]
}

enum RuntimeBattleRewardContinuation {
    case sendNextEnemy(index: Int)
    case finishWin
}

struct RuntimePokemonBoxState {
    var index: Int
    var pokemon: [RuntimePokemonState]
}

enum RuntimeShopPhase: String {
    case mainMenu
    case buyList
    case sellList
    case quantity
    case confirmation
    case result
}

enum RuntimeShopTransactionKind: String {
    case buy
    case sell
}

struct RuntimeShopTransactionState {
    let kind: RuntimeShopTransactionKind
    let itemID: String
}

struct RuntimeShopState {
    let martID: String
    var phase: RuntimeShopPhase
    var focusedMainMenuIndex: Int
    var focusedItemIndex: Int
    var focusedConfirmationIndex: Int
    var selectedQuantity: Int
    var transaction: RuntimeShopTransactionState?
    var message: String
    var nextPhaseAfterResult: RuntimeShopPhase?
}

struct RuntimeFieldPartyReorderState {
    var selectedIndex: Int
}

struct RuntimeBattlePresentationState {
    var stage: BattlePresentationStage
    var revision: Int
    var uiVisibility: BattlePresentationUIVisibility
    var activeSide: BattlePresentationSide?
    var transitionStyle: BattleTransitionStyle
    var meterAnimation: BattleMeterAnimationTelemetry?

    init(
        stage: BattlePresentationStage = .idle,
        revision: Int = 0,
        uiVisibility: BattlePresentationUIVisibility = .visible,
        activeSide: BattlePresentationSide? = nil,
        transitionStyle: BattleTransitionStyle = .none,
        meterAnimation: BattleMeterAnimationTelemetry? = nil
    ) {
        self.stage = stage
        self.revision = revision
        self.uiVisibility = uiVisibility
        self.activeSide = activeSide
        self.transitionStyle = transitionStyle
        self.meterAnimation = meterAnimation
    }
}

struct RuntimeBattlePresentationBeat {
    let delay: TimeInterval
    let stage: BattlePresentationStage
    let uiVisibility: BattlePresentationUIVisibility
    let activeSide: BattlePresentationSide?
    let transitionStyle: BattleTransitionStyle
    let meterAnimation: BattleMeterAnimationTelemetry?
    let message: String?
    let phase: RuntimeBattlePhase?
    let pendingAction: RuntimeBattlePendingAction?
    let learnMoveState: RuntimeBattleLearnMoveState?
    let rewardContinuation: RuntimeBattleRewardContinuation?
    let playerPokemon: RuntimePokemonState?
    let enemyPokemon: RuntimePokemonState?
    let enemyParty: [RuntimePokemonState]?
    let enemyActiveIndex: Int?
    let moveAudioMoveID: String?
    let moveAudioAttackerSpeciesID: String?
    let finishBattleWon: Bool?
    let escapeBattle: Bool

    init(
        delay: TimeInterval,
        stage: BattlePresentationStage,
        uiVisibility: BattlePresentationUIVisibility,
        activeSide: BattlePresentationSide? = nil,
        transitionStyle: BattleTransitionStyle = .none,
        meterAnimation: BattleMeterAnimationTelemetry? = nil,
        message: String? = nil,
        phase: RuntimeBattlePhase? = nil,
        pendingAction: RuntimeBattlePendingAction? = nil,
        learnMoveState: RuntimeBattleLearnMoveState? = nil,
        rewardContinuation: RuntimeBattleRewardContinuation? = nil,
        playerPokemon: RuntimePokemonState? = nil,
        enemyPokemon: RuntimePokemonState? = nil,
        enemyParty: [RuntimePokemonState]? = nil,
        enemyActiveIndex: Int? = nil,
        moveAudioMoveID: String? = nil,
        moveAudioAttackerSpeciesID: String? = nil,
        finishBattleWon: Bool? = nil,
        escapeBattle: Bool = false
    ) {
        self.delay = delay
        self.stage = stage
        self.uiVisibility = uiVisibility
        self.activeSide = activeSide
        self.transitionStyle = transitionStyle
        self.meterAnimation = meterAnimation
        self.message = message
        self.phase = phase
        self.pendingAction = pendingAction
        self.learnMoveState = learnMoveState
        self.rewardContinuation = rewardContinuation
        self.playerPokemon = playerPokemon
        self.enemyPokemon = enemyPokemon
        self.enemyParty = enemyParty
        self.enemyActiveIndex = enemyActiveIndex
        self.moveAudioMoveID = moveAudioMoveID
        self.moveAudioAttackerSpeciesID = moveAudioAttackerSpeciesID
        self.finishBattleWon = finishBattleWon
        self.escapeBattle = escapeBattle
    }
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
    var focusedBagItemIndex: Int
    var focusedPartyIndex: Int
    var partySelectionMode: RuntimeBattlePartySelectionMode
    var message: String
    var queuedMessages: [String]
    var pendingAction: RuntimeBattlePendingAction?
    var lastCaptureResult: RuntimeBattleCaptureResult?
    var pendingPresentationBatches: [[RuntimeBattlePresentationBeat]]
    var learnMoveState: RuntimeBattleLearnMoveState?
    var rewardContinuation: RuntimeBattleRewardContinuation?
    var presentation: RuntimeBattlePresentationState

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

struct RuntimeSoundEffectState: Equatable {
    var soundEffectID: String
    var reason: String
    var playbackRevision: Int
    var status: SoundEffectPlaybackStatusTelemetry
    var replacedSoundEffectID: String?
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
    var currentBoxIndex: Int
    var boxedPokemon: [RuntimePokemonBoxState]
    var ownedSpeciesIDs: Set<String>
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
