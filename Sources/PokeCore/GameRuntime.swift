import Foundation
import Observation
import PokeContent
import PokeDataModel

@MainActor
@Observable
public final class GameRuntime {
    public let content: LoadedContent

    public internal(set) var scene: RuntimeScene = .launch
    public internal(set) var focusedIndex = 0
    public internal(set) var placeholderTitle: String?
    public internal(set) var starterChoiceFocusedIndex = 0

    let telemetryPublisher: (any TelemetryPublisher)?
    let audioPlayer: (any RuntimeAudioPlaying)?
    let validationMode: Bool
    var substate = "launching"
    var recentInputEvents: [InputEventTelemetry] = []
    var assetLoadingFailures: [String]
    var windowScale = 4
    var transitionTask: Task<Void, Never>?
    var fieldTransitionTask: Task<Void, Never>?
    var fieldMovementTask: Task<Void, Never>?
    var scriptedMovementTask: Task<Void, Never>?
    var hasStarted = false
    var gameplayState: GameplayState?
    var dialogueState: DialogueState?
    var deferredActions: [DeferredAction] = []
    var currentAudioState: RuntimeAudioState?
    var fieldTransitionState: RuntimeFieldTransitionState?
    var battleRNGState: UInt64 = 0x504f4b4553574946
    var battleRandomOverrides: [Int] = []

    public init(
        content: LoadedContent,
        telemetryPublisher: (any TelemetryPublisher)?,
        audioPlayer: (any RuntimeAudioPlaying)? = nil
    ) {
        self.content = content
        self.telemetryPublisher = telemetryPublisher
        self.audioPlayer = audioPlayer
        self.assetLoadingFailures = Self.missingAssets(in: content)
        self.validationMode = ProcessInfo.processInfo.environment["POKESWIFT_VALIDATION_MODE"] == "1"
    }

    public var menuEntries: [TitleMenuEntry] {
        content.titleManifest.menuEntries
    }

    public var currentMapManifest: MapManifest? {
        guard let gameplayState else { return nil }
        return content.map(id: gameplayState.mapID)
    }

    public var playerSpriteID: String {
        "SPRITE_RED"
    }

    public var currentTilesetManifest: TilesetManifest? {
        guard let map = currentMapManifest else { return nil }
        return content.tileset(id: map.tileset)
    }

    public var currentFieldSpriteIDs: [String] {
        Array(Set(currentFieldObjects.map(\.sprite) + [playerSpriteID])).sorted()
    }

    public var currentFieldRenderMode: String {
        currentFieldRenderIssues.isEmpty ? "realAssets" : "placeholder"
    }

    public var playerPosition: TilePoint? {
        gameplayState?.playerPosition
    }

    public var playerFacing: FacingDirection {
        gameplayState?.facing ?? .down
    }

    public var playerName: String {
        gameplayState?.playerName ?? "RED"
    }

    public var playerMoney: Int {
        gameplayState?.money ?? 0
    }

    public var earnedBadgeIDs: Set<String> {
        gameplayState?.earnedBadgeIDs ?? []
    }

    public var chosenStarterSpeciesID: String? {
        gameplayState?.chosenStarterSpeciesID
    }

    public var currentFieldObjects: [FieldObjectRenderState] {
        guard let gameplayState, let map = currentMapManifest else { return [] }
        return map.objects.compactMap { object in
            let state = gameplayState.objectStates[object.id]
            let visible = state?.visible ?? object.visibleByDefault
            guard visible else { return nil }
            return FieldObjectRenderState(
                id: object.id,
                displayName: object.displayName,
                sprite: object.sprite,
                position: state?.position ?? object.position,
                facing: state?.facing ?? object.facing,
                interactionDialogueID: object.interactionDialogueID,
                trainerBattleID: object.trainerBattleID
            )
        }
    }

    public var currentDialogueManifest: DialogueManifest? {
        guard let dialogueState else { return nil }
        return content.dialogue(id: dialogueState.dialogueID)
    }

    var isFieldInputLocked: Bool {
        fieldTransitionState != nil || fieldMovementTask != nil || scriptedMovementTask != nil
    }

    var currentFieldRenderIssues: [String] {
        guard let map = currentMapManifest else { return [] }
        return content.fieldRenderIssues(map: map, spriteIDs: currentFieldSpriteIDs)
    }

    public var currentDialoguePage: DialoguePage? {
        guard let dialogueState,
              let dialogue = currentDialogueManifest,
              dialogue.pages.indices.contains(dialogueState.pageIndex) else {
            return nil
        }
        return dialogue.pages[dialogueState.pageIndex]
    }

    public var starterChoiceOptions: [SpeciesManifest] {
        ["CHARMANDER", "SQUIRTLE", "BULBASAUR"].compactMap { content.species(id: $0) }
    }

    public var currentBattleMoves: [MoveManifest] {
        guard let battle = gameplayState?.battle else { return [] }
        return battle.playerPokemon.moves.compactMap { content.move(id: $0.id) }
    }

    public var fieldAnimationStepDuration: TimeInterval {
        validationMode ? 0.03 : (16.0 / 60.0)
    }

    public var canAcceptFieldDirectionalInput: Bool {
        scene == .field && isFieldInputLocked == false
    }

    public func start() {
        guard hasStarted == false else { return }
        hasStarted = true
        focusedIndex = 0
        scene = .launch
        substate = "launching"
        publishSnapshot()
        scheduleTitleFlow()
    }

    public func handle(button: RuntimeButton) {
        record(button: button)

        switch scene {
        case .launch, .splash:
            break
        case .titleAttract:
            if button == .start || button == .confirm {
                scene = .titleMenu
                substate = "title_menu"
                focusedIndex = 0
                placeholderTitle = nil
                requestTitleMusic()
            }
        case .titleMenu:
            handleTitleMenu(button: button)
        case .field:
            handleField(button: button)
        case .dialogue:
            handleDialogue(button: button)
        case .scriptedSequence:
            break
        case .starterChoice:
            handleStarterChoice(button: button)
        case .battle:
            handleBattle(button: button)
        case .placeholder:
            if button == .cancel {
                scene = .titleMenu
                substate = "title_menu"
                placeholderTitle = nil
                requestTitleMusic()
            }
        }

        publishSnapshot()
    }

    public func updateWindowScale(_ scale: Int) {
        windowScale = max(1, scale)
        publishSnapshot()
    }
}
