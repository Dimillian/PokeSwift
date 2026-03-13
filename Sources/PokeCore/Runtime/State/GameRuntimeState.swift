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
    var id: String
    var currentPP: Int
}

struct RuntimeMimicState {
    var slotIndex: Int
    var originalMove: RuntimeMoveState
}

struct RuntimeTransformState {
    var originalSpeciesID: String
    var originalAttack: Int
    var originalDefense: Int
    var originalSpeed: Int
    var originalSpecial: Int
    var originalAttackStage: Int
    var originalDefenseStage: Int
    var originalSpeedStage: Int
    var originalSpecialStage: Int
    var originalAccuracyStage: Int
    var originalEvasionStage: Int
    var originalMoves: [RuntimeMoveState]
}

struct RuntimePokemonBattleEffectsState {
    var toxicCounter: Int
    var confusionTurnsRemaining: Int
    var disabledMoveID: String?
    var disabledTurnsRemaining: Int
    var isProtectedByMist: Bool
    var hasLightScreen: Bool
    var hasReflect: Bool
    var isGettingPumped: Bool
    var isSeeded: Bool
    var needsRecharge: Bool
    var isFlinched: Bool
    var lastMoveID: String?
    var bideTurnsRemaining: Int
    var bideAccumulatedDamage: Int
    var pendingBideDamage: Int?
    var thrashTurnsRemaining: Int
    var thrashMoveID: String?
    var chargingMoveID: String?
    var isInvulnerable: Bool
    var trappingTurnsRemaining: Int
    var trappingMoveID: String?
    var trappingDamage: Int
    var isUsingRage: Bool
    var hasSubstitute: Bool
    var substituteHP: Int
    var transformedState: RuntimeTransformState?
    var transformedSpeciesID: String?
    var typeOverridePrimary: String?
    var typeOverrideSecondary: String?
    var mimicState: RuntimeMimicState?

    init(
        toxicCounter: Int = 0,
        confusionTurnsRemaining: Int = 0,
        disabledMoveID: String? = nil,
        disabledTurnsRemaining: Int = 0,
        isProtectedByMist: Bool = false,
        hasLightScreen: Bool = false,
        hasReflect: Bool = false,
        isGettingPumped: Bool = false,
        isSeeded: Bool = false,
        needsRecharge: Bool = false,
        isFlinched: Bool = false,
        lastMoveID: String? = nil,
        bideTurnsRemaining: Int = 0,
        bideAccumulatedDamage: Int = 0,
        pendingBideDamage: Int? = nil,
        thrashTurnsRemaining: Int = 0,
        thrashMoveID: String? = nil,
        chargingMoveID: String? = nil,
        isInvulnerable: Bool = false,
        trappingTurnsRemaining: Int = 0,
        trappingMoveID: String? = nil,
        trappingDamage: Int = 0,
        isUsingRage: Bool = false,
        hasSubstitute: Bool = false,
        substituteHP: Int = 0,
        transformedState: RuntimeTransformState? = nil,
        transformedSpeciesID: String? = nil,
        typeOverridePrimary: String? = nil,
        typeOverrideSecondary: String? = nil,
        mimicState: RuntimeMimicState? = nil
    ) {
        self.toxicCounter = toxicCounter
        self.confusionTurnsRemaining = confusionTurnsRemaining
        self.disabledMoveID = disabledMoveID
        self.disabledTurnsRemaining = disabledTurnsRemaining
        self.isProtectedByMist = isProtectedByMist
        self.hasLightScreen = hasLightScreen
        self.hasReflect = hasReflect
        self.isGettingPumped = isGettingPumped
        self.isSeeded = isSeeded
        self.needsRecharge = needsRecharge
        self.isFlinched = isFlinched
        self.lastMoveID = lastMoveID
        self.bideTurnsRemaining = bideTurnsRemaining
        self.bideAccumulatedDamage = bideAccumulatedDamage
        self.pendingBideDamage = pendingBideDamage
        self.thrashTurnsRemaining = thrashTurnsRemaining
        self.thrashMoveID = thrashMoveID
        self.chargingMoveID = chargingMoveID
        self.isInvulnerable = isInvulnerable
        self.trappingTurnsRemaining = trappingTurnsRemaining
        self.trappingMoveID = trappingMoveID
        self.trappingDamage = trappingDamage
        self.isUsingRage = isUsingRage
        self.hasSubstitute = hasSubstitute
        self.substituteHP = substituteHP
        self.transformedState = transformedState
        self.transformedSpeciesID = transformedSpeciesID
        self.typeOverridePrimary = typeOverridePrimary
        self.typeOverrideSecondary = typeOverrideSecondary
        self.mimicState = mimicState
    }
}

struct RuntimeInventoryItemState {
    let itemID: String
    var quantity: Int
}

struct RuntimePokemonState {
    var speciesID: String
    var nickname: String
    let level: Int
    let experience: Int
    let dvs: PokemonDVs
    let statExp: PokemonStatExp
    let maxHP: Int
    var currentHP: Int
    var attack: Int
    var defense: Int
    var speed: Int
    var special: Int
    var attackStage: Int
    var defenseStage: Int
    var speedStage: Int
    var specialStage: Int
    var accuracyStage: Int
    var evasionStage: Int
    var majorStatus: MajorStatusCondition
    var statusCounter: Int
    var isBadlyPoisoned: Bool
    var moves: [RuntimeMoveState]
    var battleEffects: RuntimePokemonBattleEffectsState

    init(
        speciesID: String,
        nickname: String,
        level: Int,
        experience: Int,
        dvs: PokemonDVs,
        statExp: PokemonStatExp,
        maxHP: Int,
        currentHP: Int,
        attack: Int,
        defense: Int,
        speed: Int,
        special: Int,
        attackStage: Int = 0,
        defenseStage: Int = 0,
        speedStage: Int = 0,
        specialStage: Int = 0,
        accuracyStage: Int = 0,
        evasionStage: Int = 0,
        majorStatus: MajorStatusCondition = .none,
        statusCounter: Int = 0,
        isBadlyPoisoned: Bool = false,
        moves: [RuntimeMoveState],
        battleEffects: RuntimePokemonBattleEffectsState = .init()
    ) {
        self.speciesID = speciesID
        self.nickname = nickname
        self.level = level
        self.experience = experience
        self.dvs = dvs
        self.statExp = statExp
        self.maxHP = maxHP
        self.currentHP = currentHP
        self.attack = attack
        self.defense = defense
        self.speed = speed
        self.special = special
        self.attackStage = attackStage
        self.defenseStage = defenseStage
        self.speedStage = speedStage
        self.specialStage = specialStage
        self.accuracyStage = accuracyStage
        self.evasionStage = evasionStage
        self.majorStatus = majorStatus
        self.statusCounter = statusCounter
        self.isBadlyPoisoned = isBadlyPoisoned
        self.moves = moves
        self.battleEffects = battleEffects
    }
}

enum RuntimeBattlePhase: String {
    case introText
    case moveSelection
    case bagSelection
    case partySelection
    case trainerAboutToUseDecision
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
    case performBlackout(sourceTrainerObjectID: String?)
    case escape
    case captured
    case capturedNicknamePrompt
    case enterTrainerAboutToUseDecision(nextIndex: Int)
    case completeTrainerVictory(payout: Int)
    case continueSwitchTurn
    case continueForcedSwitch
    case continueLevelUpResolution
}

enum RuntimeBattlePartySelectionMode: Equatable {
    case optionalSwitch
    case forcedReplacement
    case trainerShift(nextEnemyIndex: Int)
}

struct RuntimeBattleLearnMoveState {
    let moveID: String
    let remainingMoveIDs: [String]
}

enum RuntimeBattleRewardContinuation {
    case aboutToUse(index: Int, previousMoveIndex: Int)
    case sendNextEnemy(index: Int)
    case finishTrainerWin(payout: Int)
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
    var hidePlayerPokemon: Bool
    var transitionStyle: BattleTransitionStyle
    var meterAnimation: BattleMeterAnimationTelemetry?

    init(
        stage: BattlePresentationStage = .idle,
        revision: Int = 0,
        uiVisibility: BattlePresentationUIVisibility = .visible,
        activeSide: BattlePresentationSide? = nil,
        hidePlayerPokemon: Bool = false,
        transitionStyle: BattleTransitionStyle = .none,
        meterAnimation: BattleMeterAnimationTelemetry? = nil
    ) {
        self.stage = stage
        self.revision = revision
        self.uiVisibility = uiVisibility
        self.activeSide = activeSide
        self.hidePlayerPokemon = hidePlayerPokemon
        self.transitionStyle = transitionStyle
        self.meterAnimation = meterAnimation
    }
}

struct RuntimeBattlePresentationBeat {
    let delay: TimeInterval
    let stage: BattlePresentationStage
    let uiVisibility: BattlePresentationUIVisibility
    let activeSide: BattlePresentationSide?
    let hidePlayerPokemon: Bool
    let requiresConfirmAfterDisplay: Bool
    let transitionStyle: BattleTransitionStyle
    let meterAnimation: BattleMeterAnimationTelemetry?
    let message: String?
    let phase: RuntimeBattlePhase?
    var pendingAction: RuntimeBattlePendingAction?
    let learnMoveState: RuntimeBattleLearnMoveState?
    let rewardContinuation: RuntimeBattleRewardContinuation?
    let playerPokemon: RuntimePokemonState?
    let enemyPokemon: RuntimePokemonState?
    let enemyParty: [RuntimePokemonState]?
    let enemyActiveIndex: Int?
    let soundEffectRequest: SoundEffectPlaybackRequest?
    let audioCueID: String?
    let finishBattleWon: Bool?
    let escapeBattle: Bool

    init(
        delay: TimeInterval,
        stage: BattlePresentationStage,
        uiVisibility: BattlePresentationUIVisibility,
        activeSide: BattlePresentationSide? = nil,
        hidePlayerPokemon: Bool = false,
        requiresConfirmAfterDisplay: Bool = false,
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
        soundEffectRequest: SoundEffectPlaybackRequest? = nil,
        audioCueID: String? = nil,
        finishBattleWon: Bool? = nil,
        escapeBattle: Bool = false
    ) {
        self.delay = delay
        self.stage = stage
        self.uiVisibility = uiVisibility
        self.activeSide = activeSide
        self.hidePlayerPokemon = hidePlayerPokemon
        self.requiresConfirmAfterDisplay = requiresConfirmAfterDisplay
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
        self.soundEffectRequest = soundEffectRequest
        self.audioCueID = audioCueID
        self.finishBattleWon = finishBattleWon
        self.escapeBattle = escapeBattle
    }
}

struct RuntimeBattleState {
    let battleID: String
    let kind: BattleKind
    let trainerName: String
    let trainerSpritePath: String?
    let baseRewardMoney: Int
    let completionFlagID: String
    let healsPartyAfterBattle: Bool
    let preventsBlackoutOnLoss: Bool
    let playerWinDialogueID: String
    let playerLoseDialogueID: String?
    let postBattleScriptID: String?
    let canRun: Bool
    let trainerClass: String?
    let sourceTrainerObjectID: String?
    var playerPokemon: RuntimePokemonState
    var enemyParty: [RuntimePokemonState]
    var enemyActiveIndex: Int
    var aiLayer2Encouragement: Int
    var payDayMoney: Int
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
    indirect enum CompletionAction {
        case returnToField
        case continueScript
        case healAndShow(dialogueID: String)
        case openStarterChoice(preselectedSpeciesID: String)
        case beginPostChoiceSequence
        case beginPostChoiceNaming
        case finishTrainerBattle(
            won: Bool,
            preventsBlackoutOnLoss: Bool,
            postBattleScriptID: String?,
            sourceTrainerObjectID: String?
        )
        case startBattle(battleID: String, sourceTrainerObjectID: String?)
        case showDialogue(dialogueID: String, completionAction: CompletionAction)
        case fieldPrompt(interactionID: String, completionAction: CompletionAction)
        case startFieldHealing(interactionID: String, completionAction: CompletionAction)
    }

    let dialogueID: String
    var pageIndex: Int
    let completionAction: CompletionAction
}

struct RuntimeFieldPromptState {
    let interactionID: String
    let kind: FieldPromptKind
    let completionAction: DialogueState.CompletionAction
    var focusedIndex: Int
}

enum RuntimeFieldHealingPhase: String {
    case priming
    case machineActive
    case healedJingle
}

struct RuntimeFieldHealingState {
    let interactionID: String
    let nurseObjectID: String?
    let originalFacing: FacingDirection?
    let completionAction: DialogueState.CompletionAction
    var phase: RuntimeFieldHealingPhase
    var activeBallCount: Int
    var totalBallCount: Int
    var pulseStep: Int
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

enum RuntimeNamingCompletionAction {
    case returnToFieldAfterCapture
    case returnToFieldAfterStarter
}

public struct RuntimeNicknameConfirmationState {
    let speciesID: String
    public let defaultName: String
    public internal(set) var focusedIndex: Int
    let completionAction: RuntimeNamingCompletionAction
}

public struct RuntimeNamingState {
    public static let maxLength = 10
    public static let validCharacters: Set<Character> = Set("ABCDEFGHIJKLMNOPQRSTUVWXYZ ")

    let speciesID: String
    public let defaultName: String
    var enteredCharacters: [Character]
    var completionAction: RuntimeNamingCompletionAction

    public var enteredText: String { String(enteredCharacters) }
}

struct RuntimeFieldAlertState: Equatable {
    var objectID: String
    var kind: FieldAlertBubbleKind
}

struct GameplayState {
    var mapID: String
    var playerPosition: TilePoint
    var facing: FacingDirection
    var blackoutCheckpoint: BlackoutCheckpointManifest?
    var objectStates: [String: RuntimeObjectState]
    var activeFlags: Set<String>
    var money: Int
    var inventory: [RuntimeInventoryItemState]
    var currentBoxIndex: Int
    var boxedPokemon: [RuntimePokemonBoxState]
    var ownedSpeciesIDs: Set<String>
    var seenSpeciesIDs: Set<String>
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
