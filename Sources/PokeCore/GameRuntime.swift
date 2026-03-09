import Foundation
import Observation
import PokeContent
import PokeDataModel
import PokeTelemetry

public struct FieldObjectRenderState: Equatable, Sendable {
    public let id: String
    public let displayName: String
    public let sprite: String
    public let position: TilePoint
    public let facing: FacingDirection
    public let interactionDialogueID: String?
    public let trainerBattleID: String?
}

private struct RuntimeObjectState {
    var position: TilePoint
    var facing: FacingDirection
    var visible: Bool
}

private struct RuntimeMoveState {
    let id: String
    var currentPP: Int
}

private struct RuntimePokemonState {
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

private struct RuntimeBattleState {
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

private struct DialogueState {
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

private enum DeferredAction {
    case dialogue(String)
    case battle(String)
    case startLabIntro
    case hideObject(String)
}

private struct GameplayState {
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

@MainActor
@Observable
public final class GameRuntime {
    public let content: LoadedContent

    public private(set) var scene: RuntimeScene = .launch
    public private(set) var focusedIndex = 0
    public private(set) var placeholderTitle: String?
    public private(set) var starterChoiceFocusedIndex = 0

    private let telemetryPublisher: (any TelemetryPublisher)?
    private let validationMode: Bool
    private var substate = "launching"
    private var recentInputEvents: [InputEventTelemetry] = []
    private var assetLoadingFailures: [String]
    private var windowScale = 4
    private var transitionTask: Task<Void, Never>?
    private var hasStarted = false
    private var gameplayState: GameplayState?
    private var dialogueState: DialogueState?
    private var deferredActions: [DeferredAction] = []

    public init(content: LoadedContent, telemetryPublisher: (any TelemetryPublisher)?) {
        self.content = content
        self.telemetryPublisher = telemetryPublisher
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

    public var playerPosition: TilePoint? {
        gameplayState?.playerPosition
    }

    public var playerFacing: FacingDirection {
        gameplayState?.facing ?? .down
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
            }
        }

        publishSnapshot()
    }

    public func updateWindowScale(_ scale: Int) {
        windowScale = max(1, scale)
        publishSnapshot()
    }

    public func currentSnapshot() -> RuntimeTelemetrySnapshot {
        RuntimeTelemetrySnapshot(
            appVersion: "0.3.0",
            contentVersion: content.gameManifest.contentVersion,
            scene: scene,
            substate: substate,
            titleMenu: scene == .titleMenu ? TitleMenuTelemetry(entries: menuEntries, focusedIndex: focusedIndex) : nil,
            field: makeFieldTelemetry(),
            dialogue: makeDialogueTelemetry(),
            starterChoice: makeStarterChoiceTelemetry(),
            party: makePartyTelemetry(),
            battle: makeBattleTelemetry(),
            eventFlags: makeFlagTelemetry(),
            recentInputEvents: recentInputEvents,
            assetLoadingFailures: assetLoadingFailures,
            window: .init(scale: windowScale, renderWidth: 160, renderHeight: 144)
        )
    }

    private func handleTitleMenu(button: RuntimeButton) {
        switch button {
        case .up:
            focusedIndex = (focusedIndex - 1 + menuEntries.count) % menuEntries.count
            substate = "title_menu"
        case .down:
            focusedIndex = (focusedIndex + 1) % menuEntries.count
            substate = "title_menu"
        case .confirm, .start:
            let selected = menuEntries[focusedIndex]
            guard selected.enabled else {
                substate = "continue_disabled"
                return
            }
            switch selected.id {
            case "newGame":
                beginNewGame()
            default:
                placeholderTitle = selected.label
                substate = selected.id
                scene = .placeholder
            }
        case .cancel:
            scene = .titleAttract
            substate = "attract"
        case .left, .right:
            break
        }
    }

    private func beginNewGame() {
        deferredActions.removeAll()
        gameplayState = makeInitialGameplayState()
        dialogueState = nil
        placeholderTitle = nil
        starterChoiceFocusedIndex = 0
        scene = .field
        substate = "field"
    }

    private func handleField(button: RuntimeButton) {
        switch button {
        case .up:
            movePlayer(in: .up)
        case .down:
            movePlayer(in: .down)
        case .left:
            movePlayer(in: .left)
        case .right:
            movePlayer(in: .right)
        case .confirm, .start:
            interactAhead()
        case .cancel:
            break
        }
    }

    private func handleDialogue(button: RuntimeButton) {
        guard button == .confirm || button == .start || button == .cancel,
              var dialogueState,
              let dialogue = content.dialogue(id: dialogueState.dialogueID) else {
            return
        }

        if dialogueState.pageIndex < dialogue.pages.count - 1 {
            dialogueState.pageIndex += 1
            self.dialogueState = dialogueState
            substate = "dialogue_\(dialogueState.dialogueID)"
            return
        }

        self.dialogueState = nil
        switch dialogueState.completionAction {
        case .returnToField:
            scene = .field
            substate = "field"
        case .continueScript:
            scene = .scriptedSequence
            runActiveScript()
        case let .healAndShow(dialogueID):
            healParty()
            showDialogue(id: dialogueID, completion: .returnToField)
        case let .openStarterChoice(preselectedSpeciesID):
            scene = .starterChoice
            substate = "starter_choice"
            starterChoiceFocusedIndex = max(0, starterChoiceOptions.firstIndex(where: { $0.id == preselectedSpeciesID }) ?? 0)
        case .beginPostChoiceSequence:
            scene = .field
            substate = "field"
            finalizeStarterChoiceSequence()
        case let .startPostBattleDialogue(won):
            scene = .field
            substate = "field"
            runPostBattleSequence(won: won)
        }
    }

    private func handleStarterChoice(button: RuntimeButton) {
        guard starterChoiceOptions.isEmpty == false else { return }
        switch button {
        case .left, .up:
            starterChoiceFocusedIndex = (starterChoiceFocusedIndex - 1 + starterChoiceOptions.count) % starterChoiceOptions.count
        case .right, .down:
            starterChoiceFocusedIndex = (starterChoiceFocusedIndex + 1) % starterChoiceOptions.count
        case .confirm, .start:
            chooseStarter(speciesID: starterChoiceOptions[starterChoiceFocusedIndex].id)
        case .cancel:
            scene = .field
            substate = "field"
        }
    }

    private func handleBattle(button: RuntimeButton) {
        guard var gameplayState, var battle = gameplayState.battle else { return }

        switch button {
        case .up:
            battle.focusedMoveIndex = max(0, battle.focusedMoveIndex - 1)
        case .down:
            battle.focusedMoveIndex = min(max(0, battle.playerPokemon.moves.count - 1), battle.focusedMoveIndex + 1)
        case .left, .right:
            break
        case .cancel:
            break
        case .confirm, .start:
            resolveBattleTurn(battle: &battle)
        }

        guard scene == .battle, self.gameplayState?.battle != nil else {
            return
        }

        gameplayState.battle = battle
        self.gameplayState = gameplayState
        scene = .battle
        substate = "battle"
    }

    private func movePlayer(in direction: FacingDirection) {
        guard var gameplayState, let map = currentMapManifest else { return }
        gameplayState.facing = direction
        let nextPoint = translated(gameplayState.playerPosition, by: direction)
        guard canMove(to: nextPoint, in: map, objectStates: gameplayState.objectStates) else {
            self.gameplayState = gameplayState
            substate = "blocked"
            return
        }

        gameplayState.playerPosition = nextPoint
        self.gameplayState = gameplayState
        if handleWarpIfNeeded() {
            return
        }
        evaluateTriggers(on: map, position: nextPoint)
    }

    private func interactAhead() {
        guard let gameplayState, let map = currentMapManifest else { return }
        let target = translated(gameplayState.playerPosition, by: gameplayState.facing)

        if let object = currentFieldObjects.first(where: { $0.position == target }) {
            interact(with: object)
            return
        }

        if let backgroundEvent = map.backgroundEvents.first(where: { $0.position == target }) {
            showDialogue(id: backgroundEvent.dialogueID, completion: .returnToField)
        }
    }

    private func interact(with object: FieldObjectRenderState) {
        switch object.id {
        case "reds_house_1f_mom":
            if gameplayState?.gotStarterBit == true {
                showDialogue(id: "reds_house_1f_mom_rest", completion: .healAndShow(dialogueID: "reds_house_1f_mom_looking_great"))
            } else {
                showDialogue(id: "reds_house_1f_mom_wakeup", completion: .returnToField)
            }
        case "oaks_lab_rival":
            if gameplayState?.gotStarterBit == true {
                showDialogue(id: "oaks_lab_rival_my_pokemon_looks_stronger", completion: .returnToField)
            } else {
                showDialogue(id: "oaks_lab_rival_gramps_isnt_around", completion: .returnToField)
            }
        case "oaks_lab_oak_1":
            if gameplayState?.gotStarterBit == true {
                showDialogue(id: "oaks_lab_oak_raise_your_young_pokemon", completion: .returnToField)
            } else if hasFlag("EVENT_OAK_ASKED_TO_CHOOSE_MON") {
                showDialogue(id: "oaks_lab_oak_which_pokemon_do_you_want", completion: .returnToField)
            } else {
                showDialogue(id: "oaks_lab_oak_choose_mon", completion: .returnToField)
            }
        case "oaks_lab_poke_ball_charmander":
            interactWithStarterBall(speciesID: "CHARMANDER", promptDialogueID: "oaks_lab_you_want_charmander")
        case "oaks_lab_poke_ball_squirtle":
            interactWithStarterBall(speciesID: "SQUIRTLE", promptDialogueID: "oaks_lab_you_want_squirtle")
        case "oaks_lab_poke_ball_bulbasaur":
            interactWithStarterBall(speciesID: "BULBASAUR", promptDialogueID: "oaks_lab_you_want_bulbasaur")
        default:
            if let dialogueID = object.interactionDialogueID {
                showDialogue(id: dialogueID, completion: .returnToField)
            }
        }
    }

    private func interactWithStarterBall(speciesID: String, promptDialogueID: String) {
        guard hasFlag("EVENT_OAK_ASKED_TO_CHOOSE_MON") else {
            showDialogue(id: "oaks_lab_those_are_pokeballs", completion: .returnToField)
            return
        }
        guard gameplayState?.gotStarterBit == false else {
            showDialogue(id: "oaks_lab_last_mon", completion: .returnToField)
            return
        }

        gameplayState?.pendingStarterSpeciesID = speciesID
        showDialogue(id: promptDialogueID, completion: .openStarterChoice(preselectedSpeciesID: speciesID))
    }

    private func chooseStarter(speciesID: String) {
        scene = .field
        substate = "field"
        gameplayState?.pendingStarterSpeciesID = speciesID
        showDialogue(id: "oaks_lab_mon_energetic", completion: .beginPostChoiceSequence)
    }

    private func finalizeStarterChoiceSequence() {
        guard var gameplayState, let speciesID = gameplayState.pendingStarterSpeciesID else { return }

        gameplayState.gotStarterBit = true
        gameplayState.chosenStarterSpeciesID = speciesID
        gameplayState.playerParty = [makePokemon(speciesID: speciesID, level: 5, nickname: speciesID.capitalized)]
        gameplayState.activeFlags.insert("EVENT_GOT_STARTER")
        let rivalSpeciesID = rivalStarter(for: speciesID)
        gameplayState.rivalStarterSpeciesID = rivalSpeciesID
        gameplayState.objectStates[selectedBallObjectID(for: speciesID)]?.visible = false
        gameplayState.objectStates[selectedBallObjectID(for: rivalSpeciesID)]?.visible = false
        self.gameplayState = gameplayState

        showDialogue(id: "oaks_lab_received_mon_\(speciesID.lowercased())", completion: .returnToField)
        queueDeferredActions([
            .dialogue("oaks_lab_rival_ill_take_this_one"),
            .dialogue("oaks_lab_rival_received_mon_\(rivalSpeciesID.lowercased())"),
        ])
    }

    private func resolveBattleTurn(battle: inout RuntimeBattleState) {
        guard battle.playerPokemon.moves.indices.contains(battle.focusedMoveIndex) else { return }

        let playerActsFirst = battle.playerPokemon.speed >= battle.enemyPokemon.speed
        if playerActsFirst {
            applyMove(attacker: &battle.playerPokemon, defender: &battle.enemyPokemon, moveIndex: battle.focusedMoveIndex, messageTarget: &battle.message)
            if battle.enemyPokemon.currentHP > 0 {
                applyEnemyTurn(battle: &battle)
            }
        } else {
            applyEnemyTurn(battle: &battle)
            if battle.playerPokemon.currentHP > 0 {
                applyMove(attacker: &battle.playerPokemon, defender: &battle.enemyPokemon, moveIndex: battle.focusedMoveIndex, messageTarget: &battle.message)
            }
        }

        if battle.enemyPokemon.currentHP == 0 || battle.playerPokemon.currentHP == 0 {
            finishBattle(won: battle.enemyPokemon.currentHP == 0)
        } else {
            battle.message = "Pick the next move."
        }
    }

    private func applyEnemyTurn(battle: inout RuntimeBattleState) {
        let availableMoves = battle.enemyPokemon.moves.enumerated().filter { $0.element.currentPP > 0 }
        guard let moveChoice = availableMoves.min(by: { $0.offset < $1.offset })?.offset else { return }
        applyMove(attacker: &battle.enemyPokemon, defender: &battle.playerPokemon, moveIndex: moveChoice, messageTarget: &battle.message)
    }

    private func applyMove(
        attacker: inout RuntimePokemonState,
        defender: inout RuntimePokemonState,
        moveIndex: Int,
        messageTarget: inout String
    ) {
        guard attacker.moves.indices.contains(moveIndex),
              attacker.moves[moveIndex].currentPP > 0,
              let move = content.move(id: attacker.moves[moveIndex].id) else {
            return
        }

        attacker.moves[moveIndex].currentPP -= 1
        if move.power > 0 {
            let adjustedAttack = scaledStat(attacker.attack, stage: attacker.attackStage)
            let adjustedDefense = max(1, scaledStat(defender.defense, stage: defender.defenseStage))
            let damage = max(1, (((((2 * attacker.level) / 5) + 2) * move.power * adjustedAttack) / adjustedDefense) / 50 + 2)
            defender.currentHP = max(0, defender.currentHP - damage)
            messageTarget = "\(attacker.nickname) used \(move.displayName)."
        } else {
            switch move.effect {
            case "ATTACK_DOWN1_EFFECT":
                defender.attackStage = max(-6, defender.attackStage - 1)
            case "DEFENSE_DOWN1_EFFECT":
                defender.defenseStage = max(-6, defender.defenseStage - 1)
            default:
                break
            }
            messageTarget = "\(attacker.nickname) used \(move.displayName)."
        }
    }

    private func finishBattle(won: Bool) {
        guard var gameplayState, let battle = gameplayState.battle else { return }
        gameplayState.activeFlags.insert(battle.completionFlagID)
        gameplayState.battle = nil
        self.gameplayState = gameplayState
        if battle.healsPartyAfterBattle {
            healParty()
        }
        showDialogue(id: won ? battle.winDialogueID : battle.loseDialogueID, completion: .startPostBattleDialogue(won: won))
    }

    private func runPostBattleSequence(won: Bool) {
        guard var gameplayState else { return }
        gameplayState.objectStates["oaks_lab_rival"]?.position = TilePoint(x: 4, y: 8)
        gameplayState.objectStates["oaks_lab_rival"]?.facing = .down
        self.gameplayState = gameplayState
        let _ = won
        showDialogue(id: "oaks_lab_rival_smell_you_later", completion: .returnToField)
        queueDeferredActions([.hideObject("oaks_lab_rival")])
    }

    private func handleWarpIfNeeded() -> Bool {
        guard var gameplayState,
              let map = content.map(id: gameplayState.mapID),
              let warp = map.warps.first(where: { $0.origin == gameplayState.playerPosition }),
              let targetMap = content.map(id: warp.targetMapID) else {
            return false
        }

        if map.id == "OAKS_LAB" {
            if gameplayState.gotStarterBit == false {
                runMapScriptIfAvailable(named: "oaks_lab_dont_go_away")
                return true
            }
            if gameplayState.activeFlags.contains("EVENT_BATTLED_RIVAL_IN_OAKS_LAB") == false {
                runMapScriptIfAvailable(named: "oaks_lab_rival_challenge")
                return true
            }
        }

        gameplayState.mapID = targetMap.id
        gameplayState.playerPosition = warp.targetPosition
        gameplayState.facing = warp.targetFacing
        self.gameplayState = gameplayState

        if targetMap.id == "OAKS_LAB" && hasFlag("EVENT_FOLLOWED_OAK_INTO_LAB") == false {
            runMapScriptIfAvailable(named: "oaks_lab_intro")
        } else {
            scene = .field
            substate = "field"
        }
        return true
    }

    private func evaluateTriggers(on map: MapManifest, position: TilePoint) {
        guard let trigger = map.triggerRegions.first(where: { $0.contains(point: position) && canRunScript(id: $0.scriptID) }) else {
            substate = "field"
            return
        }
        runMapScriptIfAvailable(named: trigger.scriptID)
    }

    private func canRunScript(id: String) -> Bool {
        switch id {
        case _ where id.contains("oak_intro"):
            return hasFlag("EVENT_FOLLOWED_OAK_INTO_LAB") == false
        case _ where id.contains("dont_go_away"):
            return gameplayState?.gotStarterBit == false
        case _ where id.contains("rival_challenge"):
            return gameplayState?.gotStarterBit == true && hasFlag("EVENT_BATTLED_RIVAL_IN_OAKS_LAB") == false
        default:
            return true
        }
    }

    private func runMapScriptIfAvailable(named id: String) {
        if content.script(id: id) != nil {
            beginScript(id: id)
            return
        }

        switch id {
        case _ where id.contains("oak_intro"):
            runFallbackOakIntro()
        case _ where id.contains("oaks_lab_intro"):
            runFallbackLabIntro()
        case _ where id.contains("dont_go_away"):
            showDialogue(id: "oaks_lab_oak_dont_go_away_yet", completion: .returnToField)
            if var gameplayState {
                gameplayState.playerPosition = TilePoint(x: 4, y: 5)
                gameplayState.facing = .up
                self.gameplayState = gameplayState
            }
        case _ where id.contains("rival_challenge"):
            runFallbackRivalChallenge()
        default:
            scene = .field
            substate = "field"
        }
    }

    private func beginScript(id: String) {
        gameplayState?.activeScriptID = id
        gameplayState?.activeScriptStep = 0
        scene = .scriptedSequence
        substate = "script_\(id)"
        runActiveScript()
    }

    private func runActiveScript() {
        guard let scriptID = gameplayState?.activeScriptID,
              let script = content.script(id: scriptID) else {
            finishScript()
            return
        }

        while let stepIndex = gameplayState?.activeScriptStep,
              script.steps.indices.contains(stepIndex) {
            let step = script.steps[stepIndex]
            gameplayState?.activeScriptStep = stepIndex + 1
            if execute(step: step) {
                return
            }
        }
        finishScript()
    }

    private func execute(step: ScriptStep) -> Bool {
        switch step.action {
        case "showDialogue":
            guard let dialogueID = step.dialogueID else { return false }
            showDialogue(id: dialogueID, completion: .continueScript)
            return true
        case "setFlag":
            if let flagID = step.flagID {
                gameplayState?.activeFlags.insert(flagID)
            }
        case "clearFlag":
            if let flagID = step.flagID {
                gameplayState?.activeFlags.remove(flagID)
            }
        case "setObjectVisibility":
            if let objectID = step.objectID, let visible = step.visible {
                gameplayState?.objectStates[objectID]?.visible = visible
            }
        case "moveObject":
            if let objectID = step.objectID {
                moveObject(id: objectID, through: step.path)
            }
        case "movePlayer":
            for direction in step.path {
                gameplayState?.playerPosition = translated(gameplayState?.playerPosition ?? TilePoint(x: 0, y: 0), by: direction)
                gameplayState?.facing = direction
            }
        case "faceObject":
            if let objectID = step.objectID, let raw = step.stringValue, let facing = FacingDirection(rawValue: raw) {
                gameplayState?.objectStates[objectID]?.facing = facing
            }
        case "facePlayer":
            if let raw = step.stringValue, let facing = FacingDirection(rawValue: raw) {
                gameplayState?.facing = facing
            }
        case "setObjectPosition":
            if let objectID = step.objectID, let point = step.point {
                gameplayState?.objectStates[objectID]?.position = point
            }
        case "setMap":
            if let mapID = step.stringValue, let point = step.point {
                gameplayState?.mapID = mapID
                gameplayState?.playerPosition = point
            }
        case "startStarterChoice":
            scene = .starterChoice
            substate = "starter_choice"
            if let speciesID = step.stringValue {
                starterChoiceFocusedIndex = starterChoiceOptions.firstIndex(where: { $0.id == speciesID }) ?? 0
            }
            return true
        case "startBattle":
            guard let battleID = step.battleID else { return false }
            startBattle(id: battleID)
            return true
        case "healParty":
            healParty()
        default:
            break
        }
        return false
    }

    private func finishScript() {
        gameplayState?.activeScriptID = nil
        gameplayState?.activeScriptStep = nil
        if scene == .scriptedSequence {
            scene = .field
            substate = "field"
        }
    }

    private func startBattle(id: String) {
        guard var gameplayState,
              let chosenStarter = gameplayState.chosenStarterSpeciesID else {
            return
        }

        let battleID: String
        if id == "AUTO" {
            switch rivalStarter(for: chosenStarter) {
            case "SQUIRTLE":
                battleID = "rival_lab_squirtle"
            case "BULBASAUR":
                battleID = "rival_lab_bulbasaur"
            default:
                battleID = "rival_lab_charmander"
            }
        } else {
            battleID = id
        }

        guard let battleManifest = content.trainerBattle(id: battleID) else {
            return
        }

        let playerPokemon = gameplayState.playerParty.first ?? makePokemon(speciesID: chosenStarter, level: 5, nickname: chosenStarter.capitalized)
        let enemyPokemon = makePokemon(speciesID: battleManifest.enemySpeciesID, level: battleManifest.enemyLevel, nickname: battleManifest.enemySpeciesID.capitalized)
        gameplayState.battle = RuntimeBattleState(
            battleID: battleManifest.id,
            trainerName: gameplayState.rivalName,
            playerStarterSpeciesID: chosenStarter,
            enemyStarterSpeciesID: battleManifest.enemySpeciesID,
            completionFlagID: battleManifest.completionFlagID,
            healsPartyAfterBattle: battleManifest.healsPartyAfterBattle,
            preventsBlackoutOnLoss: battleManifest.preventsBlackoutOnLoss,
            winDialogueID: battleManifest.winDialogueID,
            loseDialogueID: battleManifest.loseDialogueID,
            playerPokemon: playerPokemon,
            enemyPokemon: enemyPokemon,
            focusedMoveIndex: 0,
            message: "\(gameplayState.rivalName) challenges you."
        )
        self.gameplayState = gameplayState
        scene = .battle
        substate = "battle"
    }

    private func runFallbackOakIntro() {
        guard var gameplayState else { return }
        gameplayState.activeFlags.insert("EVENT_OAK_APPEARED_IN_PALLET")
        gameplayState.objectStates["pallet_town_oak"]?.visible = true
        gameplayState.objectStates["pallet_town_oak"]?.position = TilePoint(x: 8, y: 3)
        gameplayState.objectStates["pallet_town_oak"]?.facing = .down
        self.gameplayState = gameplayState
        showDialogue(id: "pallet_town_oak_hey_wait", completion: .returnToField)
        queueDeferredActions([
            .dialogue("pallet_town_oak_its_unsafe"),
            .startLabIntro,
        ])
    }

    private func runFallbackLabIntro() {
        guard var gameplayState else { return }
        gameplayState.mapID = "OAKS_LAB"
        gameplayState.playerPosition = TilePoint(x: 5, y: 10)
        gameplayState.facing = .up
        gameplayState.objectStates["oaks_lab_oak_1"]?.visible = true
        gameplayState.objectStates["oaks_lab_oak_2"]?.visible = false
        self.gameplayState = gameplayState

        showDialogue(id: "oaks_lab_rival_fed_up_with_waiting", completion: .returnToField)
        gameplayState.activeFlags.insert("EVENT_OAK_ASKED_TO_CHOOSE_MON")
        self.gameplayState = gameplayState
        queueDeferredActions([
            .dialogue("oaks_lab_oak_choose_mon"),
            .dialogue("oaks_lab_rival_what_about_me"),
            .dialogue("oaks_lab_oak_be_patient"),
        ])
    }

    private func runFallbackRivalChallenge() {
        guard gameplayState?.chosenStarterSpeciesID != nil else { return }
        showDialogue(id: "oaks_lab_rival_ill_take_you_on", completion: .returnToField)
        queueDeferredActions([.battle("AUTO")])
    }

    private func showDialogue(id: String, completion: DialogueState.CompletionAction) {
        guard let dialogue = content.dialogue(id: id) else {
            scene = .field
            substate = "field"
            return
        }
        dialogueState = DialogueState(dialogueID: dialogue.id, pageIndex: 0, completionAction: completion)
        scene = .dialogue
        substate = "dialogue_\(id)"
    }

    private func queueDeferredActions(_ actions: [DeferredAction]) {
        guard actions.isEmpty == false else { return }
        deferredActions.append(contentsOf: actions)
    }

    private func advanceDeferredQueueIfNeeded() {
        guard dialogueState == nil, scene == .field || scene == .scriptedSequence else {
            return
        }
        guard deferredActions.isEmpty == false else { return }

        let action = deferredActions.removeFirst()
        switch action {
        case let .dialogue(dialogueID):
            showDialogue(id: dialogueID, completion: .returnToField)
        case let .battle(battleID):
            startBattle(id: battleID)
        case .startLabIntro:
            if var gameplayState {
                gameplayState.objectStates["pallet_town_oak"]?.position = TilePoint(x: 12, y: 10)
                gameplayState.playerPosition = TilePoint(x: 12, y: 11)
                gameplayState.facing = .up
                gameplayState.mapID = "OAKS_LAB"
                gameplayState.activeFlags.insert("EVENT_FOLLOWED_OAK_INTO_LAB")
                gameplayState.activeFlags.insert("EVENT_FOLLOWED_OAK_INTO_LAB_2")
                self.gameplayState = gameplayState
            }
            runFallbackLabIntro()
        case let .hideObject(objectID):
            gameplayState?.objectStates[objectID]?.visible = false
            scene = .field
            substate = "field"
            return
        }
    }

    private func makeInitialGameplayState() -> GameplayState {
        let start = content.gameplayManifest.playerStart
        var objectStates: [String: RuntimeObjectState] = [:]
        for map in content.gameplayManifest.maps {
            for object in map.objects {
                objectStates[object.id] = RuntimeObjectState(position: object.position, facing: object.facing, visible: object.visibleByDefault)
            }
        }
        objectStates["pallet_town_oak"]?.visible = false
        objectStates["oaks_lab_oak_2"]?.visible = false

        return GameplayState(
            mapID: start.mapID,
            playerPosition: start.position,
            facing: start.facing,
            objectStates: objectStates,
            activeFlags: Set(start.initialFlags),
            gotStarterBit: false,
            playerName: start.playerName,
            rivalName: start.rivalName,
            playerParty: [],
            chosenStarterSpeciesID: nil,
            rivalStarterSpeciesID: nil,
            pendingStarterSpeciesID: nil,
            activeScriptID: nil,
            activeScriptStep: nil,
            battle: nil
        )
    }

    private func moveObject(id: String, through path: [FacingDirection]) {
        guard var object = gameplayState?.objectStates[id] else { return }
        for direction in path {
            object.position = translated(object.position, by: direction)
            object.facing = direction
        }
        gameplayState?.objectStates[id] = object
    }

    private func translated(_ point: TilePoint, by direction: FacingDirection) -> TilePoint {
        switch direction {
        case .up:
            return TilePoint(x: point.x, y: point.y - 1)
        case .down:
            return TilePoint(x: point.x, y: point.y + 1)
        case .left:
            return TilePoint(x: point.x - 1, y: point.y)
        case .right:
            return TilePoint(x: point.x + 1, y: point.y)
        }
    }

    private func canMove(to point: TilePoint, in map: MapManifest, objectStates: [String: RuntimeObjectState]) -> Bool {
        guard point.x >= 0, point.y >= 0, point.x < map.tileWidth, point.y < map.tileHeight else {
            return false
        }

        if currentFieldObjects.contains(where: { $0.position == point }) {
            return false
        }

        let blockedTiles = blockedTiles(for: map.id)
        return blockedTiles.contains(point) == false
    }

    private func blockedTiles(for mapID: String) -> Set<TilePoint> {
        switch mapID {
        case "REDS_HOUSE_2F":
            return perimeter(width: 8, height: 8).subtracting([TilePoint(x: 7, y: 1)])
        case "REDS_HOUSE_1F":
            var blocked = perimeter(width: 8, height: 8)
            blocked.subtract([TilePoint(x: 2, y: 7), TilePoint(x: 3, y: 7), TilePoint(x: 7, y: 1)])
            return blocked
        case "PALLET_TOWN":
            var blocked = perimeter(width: 20, height: 18)
            blocked.formUnion(rect(minX: 2, minY: 2, maxX: 6, maxY: 5))
            blocked.formUnion(rect(minX: 10, minY: 2, maxX: 14, maxY: 5))
            blocked.formUnion(rect(minX: 10, minY: 8, maxX: 14, maxY: 11))
            blocked.subtract([
                TilePoint(x: 5, y: 5),
                TilePoint(x: 13, y: 5),
                TilePoint(x: 12, y: 11),
                TilePoint(x: 8, y: 1),
                TilePoint(x: 9, y: 1),
                TilePoint(x: 10, y: 1),
            ])
            return blocked
        case "OAKS_LAB":
            var blocked = perimeter(width: 10, height: 12)
            blocked.subtract([TilePoint(x: 4, y: 11), TilePoint(x: 5, y: 11)])
            blocked.formUnion(rect(minX: 4, minY: 1, maxX: 8, maxY: 2))
            blocked.subtract([TilePoint(x: 6, y: 3), TilePoint(x: 7, y: 3), TilePoint(x: 8, y: 3)])
            return blocked
        default:
            return []
        }
    }

    private func perimeter(width: Int, height: Int) -> Set<TilePoint> {
        var points: Set<TilePoint> = []
        for x in 0..<width {
            points.insert(TilePoint(x: x, y: 0))
            points.insert(TilePoint(x: x, y: height - 1))
        }
        for y in 0..<height {
            points.insert(TilePoint(x: 0, y: y))
            points.insert(TilePoint(x: width - 1, y: y))
        }
        return points
    }

    private func rect(minX: Int, minY: Int, maxX: Int, maxY: Int) -> Set<TilePoint> {
        var points: Set<TilePoint> = []
        for x in minX...maxX {
            for y in minY...maxY {
                points.insert(TilePoint(x: x, y: y))
            }
        }
        return points
    }

    private func healParty() {
        guard var gameplayState else { return }
        gameplayState.playerParty = gameplayState.playerParty.map { pokemon in
            var healed = pokemon
            healed.currentHP = healed.maxHP
            healed.attackStage = 0
            healed.defenseStage = 0
            healed.moves = healed.moves.map { move in
                var restored = move
                restored.currentPP = content.move(id: move.id)?.maxPP ?? move.currentPP
                return restored
            }
            return healed
        }
        self.gameplayState = gameplayState
    }

    private func makePokemon(speciesID: String, level: Int, nickname: String) -> RuntimePokemonState {
        guard let species = content.species(id: speciesID) else {
            return RuntimePokemonState(speciesID: speciesID, nickname: nickname, level: level, maxHP: 20, currentHP: 20, attack: 10, defense: 10, speed: 10, special: 10, attackStage: 0, defenseStage: 0, moves: [])
        }

        let maxHP = ((species.baseHP * 2 * level) / 100) + level + 10
        let attack = ((species.baseAttack * 2 * level) / 100) + 5
        let defense = ((species.baseDefense * 2 * level) / 100) + 5
        let speed = ((species.baseSpeed * 2 * level) / 100) + 5
        let special = ((species.baseSpecial * 2 * level) / 100) + 5
        let moves = species.startingMoves.compactMap { moveID -> RuntimeMoveState? in
            guard moveID != "NO_MOVE", let move = content.move(id: moveID) else { return nil }
            return RuntimeMoveState(id: move.id, currentPP: move.maxPP)
        }

        return RuntimePokemonState(
            speciesID: species.id,
            nickname: nickname,
            level: level,
            maxHP: maxHP,
            currentHP: maxHP,
            attack: attack,
            defense: defense,
            speed: speed,
            special: special,
            attackStage: 0,
            defenseStage: 0,
            moves: moves
        )
    }

    private func rivalStarter(for playerStarter: String) -> String {
        switch playerStarter {
        case "CHARMANDER":
            return "SQUIRTLE"
        case "SQUIRTLE":
            return "BULBASAUR"
        default:
            return "CHARMANDER"
        }
    }

    private func selectedBallObjectID(for speciesID: String) -> String {
        switch speciesID {
        case "CHARMANDER":
            return "oaks_lab_poke_ball_charmander"
        case "SQUIRTLE":
            return "oaks_lab_poke_ball_squirtle"
        default:
            return "oaks_lab_poke_ball_bulbasaur"
        }
    }

    private func scaledStat(_ stat: Int, stage: Int) -> Int {
        let multipliers: [(Int, Int)] = [
            (2, 8),
            (2, 7),
            (2, 6),
            (2, 5),
            (2, 4),
            (2, 3),
            (2, 2),
            (3, 2),
            (4, 2),
            (5, 2),
            (6, 2),
            (7, 2),
            (8, 2),
        ]
        let index = max(0, min(multipliers.count - 1, stage + 6))
        let (numerator, denominator) = multipliers[index]
        return max(1, (stat * numerator) / denominator)
    }

    private func hasFlag(_ flagID: String) -> Bool {
        gameplayState?.activeFlags.contains(flagID) ?? false
    }

    private func record(button: RuntimeButton) {
        recentInputEvents.append(.init(button: button, timestamp: Self.timestamp()))
        if recentInputEvents.count > 20 {
            recentInputEvents.removeFirst(recentInputEvents.count - 20)
        }
    }

    private func publishSnapshot() {
        advanceDeferredQueueIfNeeded()
        guard let telemetryPublisher else { return }
        let snapshot = currentSnapshot()
        Task {
            await telemetryPublisher.publish(snapshot: snapshot)
        }
    }

    private func scheduleTitleFlow() {
        transitionTask?.cancel()
        let timings = content.titleManifest.timings
        let launchSeconds = validationMode ? 0.05 : max(0.1, timings.launchFadeSeconds)
        let splashSeconds = validationMode ? 0.10 : max(0.1, timings.splashDurationSeconds)

        transitionTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(launchSeconds * 1_000_000_000))
            guard Task.isCancelled == false else { return }
            await MainActor.run {
                guard let self else { return }
                self.scene = .splash
                self.substate = "splash"
                self.publishSnapshot()
            }

            try? await Task.sleep(nanoseconds: UInt64(splashSeconds * 1_000_000_000))
            guard Task.isCancelled == false else { return }
            await MainActor.run {
                guard let self else { return }
                self.scene = .titleAttract
                self.substate = "attract"
                self.publishSnapshot()
            }
        }
    }

    private func makeFieldTelemetry() -> FieldTelemetry? {
        guard let gameplayState, let map = content.map(id: gameplayState.mapID) else { return nil }
        return FieldTelemetry(
            mapID: map.id,
            mapName: map.displayName,
            playerPosition: gameplayState.playerPosition,
            facing: gameplayState.facing,
            activeScriptID: gameplayState.activeScriptID,
            activeScriptStep: gameplayState.activeScriptStep
        )
    }

    private func makeDialogueTelemetry() -> DialogueTelemetry? {
        guard let dialogueState, let dialogue = content.dialogue(id: dialogueState.dialogueID) else { return nil }
        let page = dialogue.pages[dialogueState.pageIndex]
        return DialogueTelemetry(dialogueID: dialogue.id, pageIndex: dialogueState.pageIndex, pageCount: dialogue.pages.count, lines: page.lines)
    }

    private func makeStarterChoiceTelemetry() -> StarterChoiceTelemetry? {
        guard scene == .starterChoice else { return nil }
        return StarterChoiceTelemetry(options: starterChoiceOptions.map(\.displayName), focusedIndex: starterChoiceFocusedIndex)
    }

    private func makePartyTelemetry() -> PartyTelemetry? {
        guard let gameplayState else { return nil }
        return PartyTelemetry(pokemon: gameplayState.playerParty.map { makePartyPokemonTelemetry(from: $0) })
    }

    private func makeBattleTelemetry() -> BattleTelemetry? {
        guard let battle = gameplayState?.battle else { return nil }
        return BattleTelemetry(
            battleID: battle.battleID,
            trainerName: battle.trainerName,
            playerPokemon: makePartyPokemonTelemetry(from: battle.playerPokemon),
            enemyPokemon: makePartyPokemonTelemetry(from: battle.enemyPokemon),
            focusedMoveIndex: battle.focusedMoveIndex,
            battleMessage: battle.message
        )
    }

    private func makeFlagTelemetry() -> EventFlagTelemetry? {
        guard let gameplayState else { return nil }
        return EventFlagTelemetry(activeFlags: gameplayState.activeFlags.sorted())
    }

    private func makePartyPokemonTelemetry(from pokemon: RuntimePokemonState) -> PartyPokemonTelemetry {
        PartyPokemonTelemetry(
            speciesID: pokemon.speciesID,
            displayName: pokemon.nickname,
            level: pokemon.level,
            currentHP: pokemon.currentHP,
            maxHP: pokemon.maxHP,
            moves: pokemon.moves.map(\.id)
        )
    }

    private static func timestamp() -> String {
        ISO8601DateFormatter().string(from: Date())
    }

    private static func missingAssets(in content: LoadedContent) -> [String] {
        content.titleManifest.assets.compactMap { asset in
            let url = content.rootURL.appendingPathComponent(asset.relativePath)
            return FileManager.default.fileExists(atPath: url.path) ? nil : asset.relativePath
        }
    }
}
