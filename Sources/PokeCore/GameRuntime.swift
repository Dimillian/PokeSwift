import Foundation
import Observation
import PokeContent
import PokeDataModel

@MainActor
@Observable
public final class GameRuntime {
    nonisolated public static let saveSchemaVersion = 10

    public let content: LoadedContent

    public internal(set) var scene: RuntimeScene = .launch {
        didSet {
            if scene != .field {
                clearHeldFieldDirections()
            }
        }
    }
    public internal(set) var focusedIndex = 0
    public internal(set) var placeholderTitle: String?
    public internal(set) var starterChoiceFocusedIndex = 0
    public internal(set) var optionsFocusedRow = 0
    public var optionsTextSpeed: TextSpeed = .medium
    public var optionsBattleAnimation: BattleAnimation = .on
    public var optionsBattleStyle: BattleStyle = .shift
    public var dialogueTextFullyRevealed = true

    let telemetryPublisher: (any TelemetryPublisher)?
    let audioPlayer: (any RuntimeAudioPlaying)?
    let saveStore: (any SaveStore)?
    let runtimeRNGSeedSource: @Sendable () -> UInt64
    let validationMode: Bool
    let isTestEnvironment: Bool
    var substate = "launching"
    var recentInputEvents: [InputEventTelemetry] = []
    var assetLoadingFailures: [String]
    var windowScale = 4
    var transitionTask: Task<Void, Never>?
    var fieldTransitionTask: Task<Void, Never>?
    var fieldMovementTask: Task<Void, Never>?
    var scriptedMovementTask: Task<Void, Never>?
    var idleMovementTask: Task<Void, Never>?
    var trainerEngagementTask: Task<Void, Never>?
    var battlePresentationTask: Task<Void, Never>?
    var battlePresentationStagedSoundTasks: [UUID: Task<Void, Never>] = [:]
    var fieldInteractionTask: Task<Void, Never>?
    var evolutionTask: Task<Void, Never>?
    var hasStarted = false
    var gameplayState: GameplayState?
    var dialogueState: DialogueState?
    var fieldPromptState: RuntimeFieldPromptState?
    var scriptItemPromptState: RuntimeScriptItemPromptState?
    var scriptChoicePromptState: RuntimeScriptChoicePromptState?
    var fieldHealingState: RuntimeFieldHealingState?
    var shopState: RuntimeShopState?
    var fieldPartyReorderState: RuntimeFieldPartyReorderState?
    public internal(set) var namingState: RuntimeNamingState?
    public internal(set) var nicknameConfirmation: RuntimeNicknameConfirmationState?
    var evolutionState: RuntimeEvolutionState?
    public internal(set) var captureAftermathPokedexSelectionID: String?
    public internal(set) var oakIntroState: OakIntroState?
    var deferredActions: [DeferredAction] = []
    var currentAudioState: RuntimeAudioState?
    var recentSoundEffects: [RuntimeSoundEffectState] = []
    public internal(set) var isMusicEnabled = true
    var fieldTransitionState: RuntimeFieldTransitionState?
    var fieldAlertState: RuntimeFieldAlertState?
    var dialogueAudioRevision = 0
    var isDialogueAudioBlockingInput = false
    var collisionSoundInFlight = false
    var runtimeRNGState: UInt64 = 0x504f4b4553574946
    var battleRandomOverrides: [Int] = []
    var acquisitionRandomOverrides: [Int] = []
    var saveMetadata: GameSaveMetadata?
    var saveErrorMessage: String?
    var lastSaveResult: RuntimeSaveResult?
    var gameplaySessionStartedAt: Date?
    var playthroughID = UUID().uuidString
    var heldFieldDirections: [FacingDirection] = []

    public init(
        content: LoadedContent,
        telemetryPublisher: (any TelemetryPublisher)?,
        audioPlayer: (any RuntimeAudioPlaying)? = nil,
        saveStore: (any SaveStore)? = nil,
        runtimeRNGSeedSource: @escaping @Sendable () -> UInt64 = { UInt64.random(in: UInt64.min...UInt64.max) }
    ) {
        self.content = content
        self.telemetryPublisher = telemetryPublisher
        self.audioPlayer = audioPlayer
        self.saveStore = saveStore
        self.runtimeRNGSeedSource = runtimeRNGSeedSource
        self.assetLoadingFailures = Self.missingAssets(in: content)
        self.validationMode = ProcessInfo.processInfo.environment["POKESWIFT_VALIDATION_MODE"] == "1"
        self.isTestEnvironment = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        refreshSaveState()
    }

    public var menuEntries: [TitleMenuEntryState] {
        content.titleManifest.menuEntries.map { entry in
            if entry.id == "continue" {
                return TitleMenuEntryState(
                    id: entry.id,
                    label: entry.label,
                    isEnabled: saveMetadata != nil,
                    detail: saveMetadata.map(\.locationName) ?? saveErrorMessage
                )
            }

            return TitleMenuEntryState(
                id: entry.id,
                label: entry.label,
                isEnabled: entry.enabledByDefault
            )
        }
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

    public var fieldPartyReorderSelectionIndex: Int? {
        fieldPartyReorderState?.selectedIndex
    }

    public var playerName: String {
        gameplayState?.playerName ?? "RED"
    }

    public var playerMoney: Int {
        gameplayState?.money ?? 0
    }

    public var earnedBadgeIDs: Set<String> {
        Self.normalizedBadgeIDs(gameplayState?.earnedBadgeIDs ?? [])
    }

    public var ownedSpeciesIDs: Set<String> {
        gameplayState?.ownedSpeciesIDs ?? []
    }

    public var seenSpeciesIDs: Set<String> {
        gameplayState?.seenSpeciesIDs ?? []
    }

    public var encounterCountsBySpeciesID: [String: Int] {
        gameplayState?.speciesEncounterCounts ?? [:]
    }

    public var totalStepCount: Int {
        gameplayState?.totalStepCount ?? 0
    }

    public var wildEncounterCount: Int {
        gameplayState?.wildEncounterCount ?? 0
    }

    public var trainerBattleCount: Int {
        gameplayState?.trainerBattleCount ?? 0
    }

    var currentInventoryItems: [RuntimeInventoryItemState] {
        gameplayState?.inventory.sorted { $0.itemID < $1.itemID } ?? []
    }

    var currentBoxedPokemon: [RuntimePokemonBoxState] {
        gameplayState?.boxedPokemon.sorted { $0.index < $1.index } ?? []
    }

    var currentBattleBagItems: [RuntimeInventoryItemState] {
        currentInventoryItems.filter { item in
            content.item(id: item.itemID)?.battleUse == .ball
        }
    }

    public var chosenStarterSpeciesID: String? {
        gameplayState?.chosenStarterSpeciesID
    }

    static func normalizedBadgeID(_ badgeID: String) -> String {
        badgeID
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "_badge", with: "")
            .replacingOccurrences(of: "badge", with: "")
    }

    static func normalizedBadgeIDs<S: Sequence>(_ badgeIDs: S) -> Set<String> where S.Element == String {
        Set(badgeIDs.map(Self.normalizedBadgeID))
    }

    public var currentFieldObjects: [FieldRenderableObjectState] {
        guard let gameplayState, let map = currentMapManifest else { return [] }
        return map.objects.compactMap { object in
            let state = gameplayState.objectStates[object.id]
            let visible = state?.visible ?? object.visibleByDefault
            guard visible else { return nil }
            return FieldRenderableObjectState(
                id: object.id,
                sprite: object.sprite,
                position: state?.position ?? object.position,
                facing: state?.facing ?? object.facing,
                movementMode: state?.movementMode
            )
        }
    }

    public var currentDialogueManifest: DialogueManifest? {
        guard let dialogueState else { return nil }
        if let pages = dialogueState.pages {
            return DialogueManifest(id: dialogueState.dialogueID, pages: pages)
        }
        return content.dialogue(id: dialogueState.dialogueID)
    }

    var currentFieldPromptState: RuntimeFieldPromptState? {
        fieldPromptState
    }

    var currentFieldHealingState: RuntimeFieldHealingState? {
        fieldHealingState
    }

    var isFieldInputLocked: Bool {
        fieldTransitionState != nil ||
            fieldMovementTask != nil ||
            scriptedMovementTask != nil ||
            trainerEngagementTask != nil ||
            fieldInteractionTask != nil ||
            fieldHealingState != nil ||
            shopState != nil
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
        let page = dialogue.pages[dialogueState.pageIndex]
        let substitutedLines = resolvedDialogueLines(page.lines, replacements: dialogueState.replacements)
        return DialoguePage(lines: substitutedLines, waitsForPrompt: page.waitsForPrompt, events: page.events)
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

    public var currentSaveMetadata: GameSaveMetadata? {
        saveMetadata
    }

    public var currentSaveErrorMessage: String? {
        saveErrorMessage
    }

    public var currentLastSaveResult: RuntimeSaveResult? {
        lastSaveResult
    }

    var isSaveableFieldGameplay: Bool {
        gameplayState != nil &&
            scene == .field &&
            dialogueState == nil &&
            fieldPromptState == nil &&
            scriptItemPromptState == nil &&
            scriptChoicePromptState == nil &&
            fieldHealingState == nil &&
            fieldTransitionState == nil &&
            scriptedMovementTask == nil &&
            trainerEngagementTask == nil &&
            gameplayState?.battle == nil
    }

    var isSettledFieldGameplay: Bool {
        isSaveableFieldGameplay &&
            fieldMovementTask == nil &&
            gameplayState?.objectStates.values.contains(where: { $0.movementMode != nil }) == false
    }

    public var canSaveGame: Bool {
        isSaveableFieldGameplay
    }

    public var canLoadGame: Bool {
        isSaveableFieldGameplay && saveMetadata != nil
    }

    public var namingCharacterHandler: ((Character) -> Void)? {
        if scene == .naming {
            return { [self] char in self.typeNamingCharacter(char) }
        }
        if scene == .oakIntro,
           let state = oakIntroState,
           (state.phase == .namingPlayer || state.phase == .namingRival),
           state.isTypingCustomName {
            return { [self] char in self.typeOakIntroCharacter(char) }
        }
        return nil
    }

    public func typeOakIntroCharacter(_ character: Character) {
        guard var state = oakIntroState,
              state.phase == .namingPlayer || state.phase == .namingRival else { return }
        let upper = Character(character.uppercased())
        guard RuntimeNamingState.validCharacters.contains(upper) else { return }
        guard state.enteredCharacters.count < RuntimeNamingState.maxLength else { return }
        state.enteredCharacters.append(upper)
        oakIntroState = state
        publishSnapshot()
    }

    public func setAcquisitionRandomOverrides(_ values: [Int]) {
        acquisitionRandomOverrides = values
    }

    public func setBattleRandomOverrides(_ values: [Int]) {
        battleRandomOverrides = values
    }

    public func start() {
        guard hasStarted == false else { return }
        hasStarted = true
        focusedIndex = 0
        scene = .launch
        substate = "launching"
        traceEvent(.sessionStarted, "Runtime session started.", mapID: gameplayState?.mapID)
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
                playUIConfirmSound()
                scene = .titleMenu
                substate = "title_menu"
                focusedIndex = 0
                placeholderTitle = nil
                requestTitleMusic()
            }
        case .titleMenu:
            handleTitleMenu(button: button)
        case .titleOptions:
            handleTitleOptions(button: button)
        case .field:
            handleField(button: button)
        case .dialogue:
            if fieldPromptState != nil {
                handleFieldPrompt(button: button)
            } else {
                handleDialogue(button: button)
            }
        case .scriptedSequence:
            break
        case .starterChoice:
            handleStarterChoice(button: button)
        case .battle:
            handleBattle(button: button)
        case .evolution:
            handleEvolution(button: button)
        case .naming:
            handleNaming(button: button)
        case .oakIntro:
            handleOakIntro(button: button)
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

    public func setDirectionalButton(_ button: RuntimeButton, isPressed: Bool) {
        guard let direction = facingDirection(for: button) else {
            if isPressed {
                handle(button: button)
            }
            return
        }

        guard scene == .field else {
            if isPressed {
                handle(button: button)
            }
            return
        }

        if isPressed {
            record(button: button)
            pressHeldFieldDirection(direction)
            publishSnapshot()
        } else {
            releaseHeldFieldDirection(direction)
        }
    }

    public func updateWindowScale(_ scale: Int) {
        windowScale = max(1, scale)
        publishSnapshot()
    }

    func refreshSaveState() {
        guard let saveStore else {
            saveMetadata = nil
            saveErrorMessage = nil
            return
        }

        do {
            saveMetadata = try saveStore.loadMetadata()
            saveErrorMessage = nil
        } catch {
            saveMetadata = nil
            saveErrorMessage = error.localizedDescription
        }
    }

}

private extension GameRuntime {
    func facingDirection(for button: RuntimeButton) -> FacingDirection? {
        switch button {
        case .up:
            return .up
        case .down:
            return .down
        case .left:
            return .left
        case .right:
            return .right
        case .confirm, .cancel, .start:
            return nil
        }
    }
}
