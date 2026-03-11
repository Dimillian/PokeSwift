import AppKit
import ImageIO
import PokeCore
import PokeDataModel
import SwiftUI
import UniformTypeIdentifiers
import XCTest

@testable import PokeUI

@MainActor
extension PokeUITests {
  func testTitleMenuPanelCanBeConstructed() {
    let view = TitleMenuPanel(
      entries: [.init(id: "newGame", label: "New Game", isEnabled: true)], focusedIndex: 0)
    XCTAssertNotNil(view)
  }
  func testGameBoyPixelTextCanBeConstructed() {
    let view = GameBoyPixelText(
      "TRAINER",
      scale: 2,
      color: .black,
      fallbackFont: .system(size: 12, weight: .bold, design: .monospaced)
    )

    XCTAssertNotNil(view)
  }
  func testDialogueBoxCanBeConstructedWithPixelText() {
    let view = DialogueBoxView(
      title: "Oak",
      lines: ["Hello there!", "Welcome to the world of Pokemon!"]
    )

    XCTAssertNotNil(view)
  }
  func testGameplayShellCanBeConstructedForFieldMode() {
    let sidebarMode = GameplaySidebarMode.fieldLike(
      GameplayFieldSidebarProps(
        profile: .init(
          trainerName: "RED",
          locationName: "Pallet Town",
          portrait: .init(label: "RED", spriteURL: nil, spriteFrame: nil),
          badges: [],
          badgeSummaryText: "0/8",
          moneyText: "¥3,000",
          statusItems: ["FIELD", "X4 Y6", "DOWN"]
        ),
        party: .init(
          pokemon: [
            .init(
              id: "bulbasaur-0",
              speciesID: "BULBASAUR",
              displayName: "Bulbasaur",
              level: 5,
              currentHP: 19,
              maxHP: 19,
              isLead: true
            )
          ]
        ),
        inventory: GameplaySidebarPropsBuilder.makeInventory(),
        save: GameplaySidebarPropsBuilder.makeSaveSection(),
        options: GameplaySidebarPropsBuilder.makeOptionsSection(
          isMusicEnabled: true,
          appearanceMode: .light
        )
      )
    )
    let view = GameplayShell(
      sidebarMode: sidebarMode,
      fieldDisplayStyle: .constant(.defaultGameplayStyle)
    ) {
      FieldMapStage {
        Color.black
      } footer: {
        Text("Dialogue")
      } overlayContent: {
        Text("Overlay")
      }
    }

    XCTAssertNotNil(view)
  }
  func testGameplayShellCanBeConstructedForBattleMode() {
    let sidebarMode = GameplaySidebarMode.battle(
      BattleSidebarProps(
        trainerName: "BLUE",
        kind: .trainer,
        phase: "moveSelection",
        promptText: "Pick the next move.",
        playerPokemon: .init(
          speciesID: "BULBASAUR",
          displayName: "Bulbasaur",
          level: 5,
          currentHP: 19,
          maxHP: 19,
          attack: 11,
          defense: 10,
          speed: 9,
          special: 12,
          moves: ["TACKLE", "GROWL"]
        ),
        enemyPokemon: .init(
          speciesID: "CHARMANDER",
          displayName: "Charmander",
          level: 5,
          currentHP: 18,
          maxHP: 20,
          attack: 10,
          defense: 9,
          speed: 11,
          special: 10,
          moves: ["SCRATCH", "GROWL"]
        ),
        moveSlots: [
          .init(
            moveID: "TACKLE", displayName: "Tackle", currentPP: 35, maxPP: 35, isSelectable: true),
          .init(
            moveID: "GROWL", displayName: "Growl", currentPP: 40, maxPP: 40, isSelectable: true),
        ],
        focusedMoveIndex: 1,
        canRun: false,
        party: .init(
          pokemon: [
            .init(
              id: "bulbasaur-0",
              speciesID: "BULBASAUR",
              displayName: "Bulbasaur",
              level: 5,
              currentHP: 19,
              maxHP: 19,
              isLead: true
            )
          ]
        )
      )
    )
    let view = GameplayShell(
      sidebarMode: sidebarMode,
      fieldDisplayStyle: .constant(.defaultGameplayStyle)
    ) {
      BattleViewportStage {
        Color.black
      } footer: {
        Text("Battle text")
      } overlayContent: {
        EmptyView()
      }
    }

    XCTAssertNotNil(view)
  }
  func testSidebarPropBuilderMapsEmptyPartyProfile() {
    let profile = GameplaySidebarPropsBuilder.makeProfile(
      trainerName: "RED",
      locationName: "Red's House",
      scene: .field,
      playerPosition: .init(x: 4, y: 4),
      facing: .down,
      portrait: .init(label: "RED", spriteURL: nil, spriteFrame: nil),
      money: 3000,
      ownedBadgeIDs: []
    )
    let party = GameplaySidebarPropsBuilder.makeParty(from: nil)
    let inventory = GameplaySidebarPropsBuilder.makeInventory()

    XCTAssertEqual(profile.moneyText, "¥3,000")
    XCTAssertEqual(profile.badgeSummaryText, "0/8")
    XCTAssertEqual(profile.badges.count, 8)
    XCTAssertEqual(profile.statusItems, ["FIELD", "X4 Y4", "DOWN"])
    XCTAssertTrue(party.pokemon.isEmpty)
    XCTAssertEqual(inventory.emptyStateTitle, "No items yet")
  }
  func testGameplaySidebarKindMapsRuntimeScenesForGameplayLayout() {
    XCTAssertEqual(GameplaySidebarKind.forScene(.field), .fieldLike)
    XCTAssertEqual(GameplaySidebarKind.forScene(.dialogue), .fieldLike)
    XCTAssertEqual(GameplaySidebarKind.forScene(.starterChoice), .fieldLike)
    XCTAssertEqual(GameplaySidebarKind.forScene(.battle), .battle)
  }
  func testBattleSidebarPropsPreservePhaseSpecificState() {
    let moveSelection = BattleSidebarProps(
      trainerName: "BLUE",
      kind: .trainer,
      phase: "moveSelection",
      promptText: "Pick the next move.",
      playerPokemon: .init(
        speciesID: "BULBASAUR",
        displayName: "Bulbasaur",
        level: 5,
        currentHP: 19,
        maxHP: 19,
        attack: 11,
        defense: 10,
        speed: 9,
        special: 12,
        moves: ["TACKLE", "GROWL"]
      ),
      enemyPokemon: .init(
        speciesID: "CHARMANDER",
        displayName: "Charmander",
        level: 5,
        currentHP: 18,
        maxHP: 20,
        attack: 10,
        defense: 9,
        speed: 11,
        special: 10,
        moves: ["SCRATCH", "GROWL"]
      ),
      moveSlots: [
        .init(moveID: "TACKLE", displayName: "Tackle", currentPP: 35, maxPP: 35, isSelectable: true)
      ],
      focusedMoveIndex: 0,
      canRun: false,
      party: .init(pokemon: [])
    )
    let resolve = BattleSidebarProps(
      trainerName: "BLUE",
      kind: .trainer,
      phase: "turnText",
      promptText: "Charmander used Scratch!",
      playerPokemon: moveSelection.playerPokemon,
      enemyPokemon: moveSelection.enemyPokemon,
      moveSlots: moveSelection.moveSlots,
      focusedMoveIndex: moveSelection.focusedMoveIndex,
      canRun: moveSelection.canRun,
      party: moveSelection.party
    )

    XCTAssertEqual(moveSelection.phase, "moveSelection")
    XCTAssertEqual(moveSelection.promptText, "Pick the next move.")
    XCTAssertEqual(resolve.phase, "turnText")
    XCTAssertEqual(resolve.promptText, "Charmander used Scratch!")
    XCTAssertEqual(resolve.moveSlots.first?.displayName, "Tackle")
  }
  func testBattleSidebarPropsBuildLearnMovePromptActions() {
    let playerPokemon = PartyPokemonTelemetry(
      speciesID: "CHARMANDER",
      displayName: "Charmander",
      level: 6,
      currentHP: 20,
      maxHP: 20,
      attack: 12,
      defense: 10,
      speed: 11,
      special: 11,
      moves: ["SCRATCH", "CUT", "GROWL", "LEER"]
    )
    let enemyPokemon = PartyPokemonTelemetry(
      speciesID: "BULBASAUR",
      displayName: "Bulbasaur",
      level: 5,
      currentHP: 0,
      maxHP: 21,
      attack: 10,
      defense: 10,
      speed: 9,
      special: 11,
      moves: ["GROWL"]
    )
    let moveSlots = [
      BattleMoveSlotTelemetry(moveID: "SCRATCH", displayName: "Scratch", currentPP: 35, maxPP: 35),
      BattleMoveSlotTelemetry(moveID: "CUT", displayName: "Cut", currentPP: 30, maxPP: 30),
      BattleMoveSlotTelemetry(moveID: "GROWL", displayName: "Growl", currentPP: 40, maxPP: 40),
      BattleMoveSlotTelemetry(moveID: "LEER", displayName: "Leer", currentPP: 30, maxPP: 30),
    ]

    let confirmPrompt = BattleSidebarProps(
      trainerName: "BLUE",
      kind: .trainer,
      phase: "learnMoveDecision",
      promptText: "Teach EMBER to Charmander?",
      playerPokemon: playerPokemon,
      enemyPokemon: enemyPokemon,
      learnMovePrompt: .init(pokemonName: "Charmander", moveID: "EMBER", moveDisplayName: "EMBER", stage: .confirm),
      moveSlots: moveSlots,
      focusedMoveIndex: 1,
      canRun: false,
      party: .init(pokemon: [])
    )
    let replacePrompt = BattleSidebarProps(
      trainerName: "BLUE",
      kind: .trainer,
      phase: "learnMoveSelection",
      promptText: "Choose a move to forget for EMBER.",
      playerPokemon: playerPokemon,
      enemyPokemon: enemyPokemon,
      learnMovePrompt: .init(pokemonName: "Charmander", moveID: "EMBER", moveDisplayName: "EMBER", stage: .replace),
      moveSlots: moveSlots,
      focusedMoveIndex: 2,
      canRun: false,
      party: .init(pokemon: [])
    )

    XCTAssertEqual(confirmPrompt.actionRows.map(\.kind), [.learn, .skip])
    XCTAssertEqual(confirmPrompt.actionRows.map(\.title), ["Learn EMBER", "Skip"])
    XCTAssertTrue(confirmPrompt.actionRows[1].isFocused)

    XCTAssertEqual(replacePrompt.actionRows.map(\.kind), [.forget, .forget, .forget, .forget])
    XCTAssertEqual(replacePrompt.actionRows[2].title, "Growl")
    XCTAssertTrue(replacePrompt.actionRows[2].isFocused)
  }
  func testGameplaySidebarModeUsesBattleAccordionDefaults() {
    let battleMode = GameplaySidebarMode.battle(
      BattleSidebarProps(
        trainerName: "BLUE",
        kind: .trainer,
        phase: "moveSelection",
        promptText: "Pick the next move.",
        playerPokemon: .init(
          speciesID: "BULBASAUR",
          displayName: "Bulbasaur",
          level: 5,
          currentHP: 19,
          maxHP: 19,
          attack: 11,
          defense: 10,
          speed: 9,
          special: 12,
          moves: ["TACKLE", "GROWL"]
        ),
        enemyPokemon: .init(
          speciesID: "CHARMANDER",
          displayName: "Charmander",
          level: 5,
          currentHP: 18,
          maxHP: 20,
          attack: 10,
          defense: 9,
          speed: 11,
          special: 10,
          moves: ["SCRATCH", "GROWL"]
        ),
        moveSlots: [
          .init(
            moveID: "TACKLE", displayName: "Tackle", currentPP: 35, maxPP: 35, isSelectable: true)
        ],
        focusedMoveIndex: 0,
        canRun: false,
        party: .init(pokemon: [])
      )
    )

    XCTAssertEqual(battleMode.defaultExpandedSection, GameplaySidebarExpandedSection.battleCombat)
    XCTAssertTrue(battleMode.supports(GameplaySidebarExpandedSection.battleCombat))
    XCTAssertTrue(battleMode.supports(GameplaySidebarExpandedSection.party))
    XCTAssertFalse(battleMode.supports(GameplaySidebarExpandedSection.trainer))
    XCTAssertFalse(battleMode.supports(GameplaySidebarExpandedSection.bag))
  }
  func testBattleSidebarMoveSelectionForcesCombatSectionOpen() {
    let battleMode = GameplaySidebarMode.battle(
      BattleSidebarProps(
        trainerName: "PIDGEY",
        kind: .wild,
        phase: "moveSelection",
        promptText: "Pick the next move.",
        playerPokemon: .init(
          speciesID: "BULBASAUR",
          displayName: "Bulbasaur",
          level: 5,
          currentHP: 19,
          maxHP: 19,
          attack: 11,
          defense: 10,
          speed: 9,
          special: 12,
          moves: ["TACKLE", "GROWL"]
        ),
        enemyPokemon: .init(
          speciesID: "PIDGEY",
          displayName: "Pidgey",
          level: 3,
          currentHP: 12,
          maxHP: 12,
          attack: 8,
          defense: 8,
          speed: 10,
          special: 7,
          moves: ["TACKLE"]
        ),
        moveSlots: [
          .init(
            moveID: "TACKLE", displayName: "Tackle", currentPP: 35, maxPP: 35, isSelectable: true),
          .init(
            moveID: "GROWL", displayName: "Growl", currentPP: 40, maxPP: 40, isSelectable: true),
        ],
        focusedMoveIndex: 1,
        canRun: true,
        party: .init(pokemon: [])
      )
    )

    XCTAssertEqual(battleMode.requiredExpandedSection, .battleCombat)
    XCTAssertEqual(
      battleMode.resolvedExpandedSection(afterRequesting: .party),
      .battleCombat
    )
  }
  func testBattleSidebarActionRowsAppendRunBelowMoves() {
    let props = BattleSidebarProps(
      trainerName: "PIDGEY",
      kind: .wild,
      phase: "moveSelection",
      promptText: "Pick the next move.",
      playerPokemon: .init(
        speciesID: "BULBASAUR",
        displayName: "Bulbasaur",
        level: 5,
        currentHP: 19,
        maxHP: 19,
        attack: 11,
        defense: 10,
        speed: 9,
        special: 12,
        moves: ["TACKLE", "GROWL"]
      ),
      enemyPokemon: .init(
        speciesID: "PIDGEY",
        displayName: "Pidgey",
        level: 3,
        currentHP: 12,
        maxHP: 12,
        attack: 8,
        defense: 8,
        speed: 10,
        special: 7,
        moves: ["TACKLE"]
      ),
      moveSlots: [
        .init(
          moveID: "TACKLE", displayName: "Tackle", currentPP: 35, maxPP: 35, isSelectable: true),
        .init(moveID: "GROWL", displayName: "Growl", currentPP: 40, maxPP: 40, isSelectable: true),
      ],
      focusedMoveIndex: 1,
      canRun: true,
      party: .init(pokemon: [])
    )

    XCTAssertEqual(props.actionRows.map(\.kind), [.move, .move, .run])
    XCTAssertEqual(props.actionRows.last?.title, "Run")
    XCTAssertEqual(props.actionRows.last?.detail, nil)
    XCTAssertEqual(props.actionRows[0].detail, "35/35")
    XCTAssertEqual(props.actionRows[1].isFocused, true)
    XCTAssertEqual(props.actionRows.last?.isSelectable, true)
  }
  func testBattleSidebarPropsHideCombatUiDuringIntroPresentation() {
    let props = BattleSidebarProps(
      trainerName: "BLUE",
      kind: .trainer,
      phase: "introText",
      promptText: "BLUE challenges you!",
      playerPokemon: .init(
        speciesID: "BULBASAUR",
        displayName: "Bulbasaur",
        level: 5,
        currentHP: 19,
        maxHP: 19,
        attack: 11,
        defense: 10,
        speed: 9,
        special: 12,
        moves: ["TACKLE", "GROWL"]
      ),
      enemyPokemon: .init(
        speciesID: "CHARMANDER",
        displayName: "Charmander",
        level: 5,
        currentHP: 18,
        maxHP: 20,
        attack: 10,
        defense: 9,
        speed: 11,
        special: 10,
        moves: ["SCRATCH", "GROWL"]
      ),
      moveSlots: [
        .init(moveID: "TACKLE", displayName: "Tackle", currentPP: 35, maxPP: 35, isSelectable: true)
      ],
      focusedMoveIndex: 0,
      canRun: false,
      party: .init(pokemon: []),
      presentation: .init(
        stage: .introFlash1,
        revision: 1,
        uiVisibility: .hidden,
        activeSide: nil,
        transitionStyle: .spiral
      )
    )

    XCTAssertFalse(props.showsInterface)
    XCTAssertFalse(props.shouldForceCombatSectionOpen)
    XCTAssertTrue(props.actionRows.isEmpty)
  }
  func testBattleSidebarActionRowsFocusRunOnlyForWildBattles() {
    let wildProps = BattleSidebarProps(
      trainerName: "PIDGEY",
      kind: .wild,
      phase: "moveSelection",
      promptText: "Pick the next move.",
      playerPokemon: .init(
        speciesID: "BULBASAUR",
        displayName: "Bulbasaur",
        level: 5,
        currentHP: 19,
        maxHP: 19,
        attack: 11,
        defense: 10,
        speed: 9,
        special: 12,
        moves: ["TACKLE", "GROWL"]
      ),
      enemyPokemon: .init(
        speciesID: "PIDGEY",
        displayName: "Pidgey",
        level: 3,
        currentHP: 12,
        maxHP: 12,
        attack: 8,
        defense: 8,
        speed: 10,
        special: 7,
        moves: ["TACKLE"]
      ),
      moveSlots: [
        .init(
          moveID: "TACKLE", displayName: "Tackle", currentPP: 35, maxPP: 35, isSelectable: true),
        .init(moveID: "GROWL", displayName: "Growl", currentPP: 40, maxPP: 40, isSelectable: true),
      ],
      focusedMoveIndex: 2,
      canRun: true,
      party: .init(pokemon: [])
    )
    let trainerProps = BattleSidebarProps(
      trainerName: "BLUE",
      kind: .trainer,
      phase: "moveSelection",
      promptText: "Pick the next move.",
      playerPokemon: wildProps.playerPokemon,
      enemyPokemon: wildProps.enemyPokemon,
      moveSlots: wildProps.moveSlots,
      focusedMoveIndex: 1,
      canRun: false,
      party: .init(pokemon: [])
    )

    XCTAssertEqual(wildProps.actionRows.map(\.kind), [.move, .move, .run])
    XCTAssertEqual(wildProps.actionRows.last?.isFocused, true)
    XCTAssertEqual(trainerProps.actionRows.map(\.kind), [.move, .move])
  }
  func testBattleSidebarActionRowsInsertBagBeforeRunWhenAvailable() {
    let props = BattleSidebarProps(
      trainerName: "PIDGEY",
      kind: .wild,
      phase: "moveSelection",
      promptText: "Pick the next move.",
      playerPokemon: .init(
        speciesID: "BULBASAUR",
        displayName: "Bulbasaur",
        level: 5,
        currentHP: 19,
        maxHP: 19,
        attack: 11,
        defense: 10,
        speed: 9,
        special: 12,
        moves: ["TACKLE", "GROWL"]
      ),
      enemyPokemon: .init(
        speciesID: "PIDGEY",
        displayName: "Pidgey",
        level: 3,
        currentHP: 12,
        maxHP: 12,
        attack: 8,
        defense: 8,
        speed: 10,
        special: 7,
        moves: ["TACKLE"]
      ),
      moveSlots: [
        .init(moveID: "TACKLE", displayName: "Tackle", currentPP: 35, maxPP: 35, isSelectable: true),
        .init(moveID: "GROWL", displayName: "Growl", currentPP: 40, maxPP: 40, isSelectable: true),
      ],
      focusedMoveIndex: 2,
      canRun: true,
      canUseBag: true,
      bagItemCount: 3,
      party: .init(pokemon: [])
    )

    XCTAssertEqual(props.actionRows.map(\.kind), [.move, .move, .bag, .run])
    XCTAssertEqual(props.actionRows[2].title, "Bag")
    XCTAssertEqual(props.actionRows[2].detail, "3")
    XCTAssertEqual(props.actionRows[2].isFocused, true)
    XCTAssertEqual(props.actionRows[3].isFocused, false)
  }
  func testBattleSidebarActionRowsInsertSwitchBeforeRunWhenAvailable() {
    let props = BattleSidebarProps(
      trainerName: "PIDGEY",
      kind: .wild,
      phase: "moveSelection",
      promptText: "Pick the next move.",
      playerPokemon: .init(
        speciesID: "BULBASAUR",
        displayName: "Bulbasaur",
        level: 5,
        currentHP: 19,
        maxHP: 19,
        attack: 11,
        defense: 10,
        speed: 9,
        special: 12,
        moves: ["TACKLE", "GROWL"]
      ),
      enemyPokemon: .init(
        speciesID: "PIDGEY",
        displayName: "Pidgey",
        level: 3,
        currentHP: 12,
        maxHP: 12,
        attack: 8,
        defense: 8,
        speed: 10,
        special: 7,
        moves: ["TACKLE"]
      ),
      moveSlots: [
        .init(moveID: "TACKLE", displayName: "Tackle", currentPP: 35, maxPP: 35, isSelectable: true),
        .init(moveID: "GROWL", displayName: "Growl", currentPP: 40, maxPP: 40, isSelectable: true),
      ],
      focusedMoveIndex: 3,
      canRun: true,
      canUseBag: true,
      canSwitch: true,
      bagItemCount: 2,
      party: .init(
        pokemon: [
          .init(id: "bulbasaur-0", speciesID: "BULBASAUR", displayName: "Bulbasaur", level: 5, currentHP: 19, maxHP: 19, isLead: true),
          .init(id: "pidgey-1", speciesID: "PIDGEY", displayName: "Pidgey", level: 3, currentHP: 12, maxHP: 12, isLead: false),
        ]
      )
    )

    XCTAssertEqual(props.actionRows.map(\.kind), [.move, .move, .bag, .partySwitch, .run])
    XCTAssertEqual(props.actionRows[3].title, "Switch")
    XCTAssertTrue(props.actionRows[3].isFocused)
    XCTAssertFalse(props.actionRows[4].isFocused)
  }
  func testBattleSidebarModeForcesPartySectionDuringSwitchSelection() {
    let battleMode = GameplaySidebarMode.battle(
      BattleSidebarProps(
        trainerName: "PIDGEY",
        kind: .wild,
        phase: "partySelection",
        promptText: "Bring out which #MON?",
        playerPokemon: .init(
          speciesID: "BULBASAUR",
          displayName: "Bulbasaur",
          level: 5,
          currentHP: 19,
          maxHP: 19,
          attack: 11,
          defense: 10,
          speed: 9,
          special: 12,
          moves: ["TACKLE", "GROWL"]
        ),
        enemyPokemon: .init(
          speciesID: "PIDGEY",
          displayName: "Pidgey",
          level: 3,
          currentHP: 12,
          maxHP: 12,
          attack: 8,
          defense: 8,
          speed: 10,
          special: 7,
          moves: ["TACKLE"]
        ),
        moveSlots: [
          .init(moveID: "TACKLE", displayName: "Tackle", currentPP: 35, maxPP: 35, isSelectable: true),
          .init(moveID: "GROWL", displayName: "Growl", currentPP: 40, maxPP: 40, isSelectable: true),
        ],
        focusedMoveIndex: 0,
        canRun: true,
        canSwitch: true,
        party: .init(
          pokemon: [
            .init(id: "bulbasaur-0", speciesID: "BULBASAUR", displayName: "Bulbasaur", level: 5, currentHP: 19, maxHP: 19, isLead: true),
            .init(id: "pidgey-1", speciesID: "PIDGEY", displayName: "Pidgey", level: 3, currentHP: 12, maxHP: 12, isLead: false, isSelectable: true, isFocused: true),
          ],
          mode: .battleSwitch,
          promptText: "Bring out which #MON?"
        )
      )
    )

    XCTAssertEqual(battleMode.requiredExpandedSection, .party)
    XCTAssertEqual(battleMode.resolvedExpandedSection(afterRequesting: .battleCombat), .party)
  }
  func testSidebarPropBuilderMapsSelectablePartyMetadata() {
    let party = PartyTelemetry(
      pokemon: [
        .init(
          speciesID: "BULBASAUR",
          displayName: "Bulbasaur",
          level: 5,
          currentHP: 19,
          maxHP: 19,
          attack: 11,
          defense: 10,
          speed: 9,
          special: 12,
          moves: ["TACKLE"],
          experience: .init(total: 150, levelStart: 135, nextLevel: 179),
          growthOutlook: .init(hp: .neutral, attack: .neutral, defense: .neutral, speed: .neutral, special: .neutral)
        ),
        .init(
          speciesID: "PIDGEY",
          displayName: "Pidgey",
          level: 3,
          currentHP: 0,
          maxHP: 12,
          attack: 8,
          defense: 8,
          speed: 10,
          special: 7,
          moves: ["TACKLE"],
          experience: .init(total: 27, levelStart: 27, nextLevel: 64),
          growthOutlook: .init(hp: .neutral, attack: .neutral, defense: .neutral, speed: .neutral, special: .neutral)
        ),
      ]
    )

    let sidebarParty = GameplaySidebarPropsBuilder.makeParty(
      from: party,
      mode: .battleSwitch,
      focusedIndex: 1,
      selectedIndex: 0,
      selectableIndices: [1],
      annotationByIndex: [0: "ACTIVE", 1: "FAINTED"],
      promptText: "Bring out which #MON?"
    )

    XCTAssertEqual(sidebarParty.mode, .battleSwitch)
    XCTAssertEqual(sidebarParty.promptText, "Bring out which #MON?")
    XCTAssertEqual(sidebarParty.pokemon[0].selectionAnnotation, "ACTIVE")
    XCTAssertTrue(sidebarParty.pokemon[0].isSelected)
    XCTAssertEqual(sidebarParty.pokemon[1].selectionAnnotation, "FAINTED")
    XCTAssertTrue(sidebarParty.pokemon[1].isFocused)
    XCTAssertTrue(sidebarParty.pokemon[1].isSelectable)
  }
  func testPartySidebarUsesCompactDensityWithThreeOrMorePokemon() {
    let twoPokemonParty = PartySidebarProps(
      pokemon: [
        .init(id: "bulbasaur-0", speciesID: "BULBASAUR", displayName: "Bulbasaur", level: 5, totalExperience: 150, levelStartExperience: 135, nextLevelExperience: 179, currentHP: 19, maxHP: 19, isLead: true),
        .init(id: "pidgey-1", speciesID: "PIDGEY", displayName: "Pidgey", level: 3, totalExperience: 27, levelStartExperience: 27, nextLevelExperience: 64, currentHP: 12, maxHP: 12, isLead: false),
      ]
    )
    let threePokemonParty = PartySidebarProps(
      pokemon: [
        .init(id: "bulbasaur-0", speciesID: "BULBASAUR", displayName: "Bulbasaur", level: 5, totalExperience: 150, levelStartExperience: 135, nextLevelExperience: 179, currentHP: 19, maxHP: 19, isLead: true),
        .init(id: "pidgey-1", speciesID: "PIDGEY", displayName: "Pidgey", level: 3, totalExperience: 27, levelStartExperience: 27, nextLevelExperience: 64, currentHP: 12, maxHP: 12, isLead: false),
        .init(id: "rattata-2", speciesID: "RATTATA", displayName: "Rattata", level: 2, totalExperience: 8, levelStartExperience: 0, nextLevelExperience: 27, currentHP: 10, maxHP: 10, isLead: false),
      ]
    )

    XCTAssertEqual(twoPokemonParty.rowDensity, .standard)
    XCTAssertEqual(threePokemonParty.rowDensity, .compact)
  }
  func testCompactPartyDensityPreservesBattleMetadataContract() {
    let compactBattleParty = PartySidebarProps(
      pokemon: [
        .init(id: "bulbasaur-0", speciesID: "BULBASAUR", displayName: "Bulbasaur", level: 5, totalExperience: 150, levelStartExperience: 135, nextLevelExperience: 179, currentHP: 19, maxHP: 19, isLead: true, isSelected: true, selectionAnnotation: "ACTIVE"),
        .init(id: "pidgey-1", speciesID: "PIDGEY", displayName: "Pidgey", level: 3, totalExperience: 27, levelStartExperience: 27, nextLevelExperience: 64, currentHP: 12, maxHP: 12, isLead: false, isSelectable: true, isFocused: true),
        .init(id: "rattata-2", speciesID: "RATTATA", displayName: "Rattata", level: 2, totalExperience: 8, levelStartExperience: 0, nextLevelExperience: 27, currentHP: 0, maxHP: 10, isLead: false, selectionAnnotation: "FAINTED"),
      ],
      mode: .battleSwitch,
      promptText: "Bring out which #MON?"
    )

    XCTAssertEqual(compactBattleParty.rowDensity, .compact)
    XCTAssertEqual(compactBattleParty.mode, .battleSwitch)
    XCTAssertEqual(compactBattleParty.promptText, "Bring out which #MON?")
    XCTAssertEqual(compactBattleParty.pokemon[0].selectionAnnotation, "ACTIVE")
    XCTAssertTrue(compactBattleParty.pokemon[0].isSelected)
    XCTAssertEqual(compactBattleParty.pokemon[1].currentHP, 12)
    XCTAssertEqual(compactBattleParty.pokemon[1].totalExperience, 27)
    XCTAssertTrue(compactBattleParty.pokemon[1].isFocused)
    XCTAssertTrue(compactBattleParty.pokemon[1].isSelectable)
    XCTAssertEqual(compactBattleParty.pokemon[2].selectionAnnotation, "FAINTED")
    XCTAssertEqual(compactBattleParty.pokemon[2].currentHP, 0)
  }
  func testCompactPartySectionContentStaysHeightBounded() {
    let party = PartySidebarProps(
      pokemon: [
        .init(id: "bulbasaur-0", speciesID: "BULBASAUR", displayName: "Bulbasaur", level: 5, totalExperience: 150, levelStartExperience: 135, nextLevelExperience: 179, currentHP: 19, maxHP: 19, isLead: true),
        .init(id: "pidgey-1", speciesID: "PIDGEY", displayName: "Pidgey", level: 3, totalExperience: 27, levelStartExperience: 27, nextLevelExperience: 64, currentHP: 12, maxHP: 12, isLead: false),
        .init(id: "rattata-2", speciesID: "RATTATA", displayName: "Rattata", level: 2, totalExperience: 8, levelStartExperience: 0, nextLevelExperience: 27, currentHP: 10, maxHP: 10, isLead: false),
        .init(id: "caterpie-3", speciesID: "CATERPIE", displayName: "Caterpie", level: 4, totalExperience: 60, levelStartExperience: 27, nextLevelExperience: 64, currentHP: 16, maxHP: 16, isLead: false),
        .init(id: "spearow-4", speciesID: "SPEAROW", displayName: "Spearow", level: 4, totalExperience: 58, levelStartExperience: 27, nextLevelExperience: 64, currentHP: 15, maxHP: 15, isLead: false),
        .init(id: "pikachu-5", speciesID: "PIKACHU", displayName: "Pikachu", level: 5, totalExperience: 130, levelStartExperience: 100, nextLevelExperience: 172, currentHP: 18, maxHP: 18, isLead: false),
      ]
    )

    let measuredHeight = measureFittingHeight(
      of: PartySidebarSectionContent(props: party, onRowSelected: nil),
      width: 280
    )

    XCTAssertEqual(party.rowDensity, .compact)
    XCTAssertLessThanOrEqual(measuredHeight, GameplayFieldMetrics.partyExpandedMaxHeight + 1)
  }
  func testSidebarPropBuilderMapsPartyAfterStarterSelection() {
    let party = PartyTelemetry(
      pokemon: [
        .init(
          speciesID: "BULBASAUR",
          displayName: "Bulbasaur",
          level: 5,
          currentHP: 19,
          maxHP: 19,
          attack: 11,
          defense: 10,
          speed: 9,
          special: 12,
          moves: ["TACKLE", "GROWL"],
          experience: .init(total: 150, levelStart: 135, nextLevel: 179),
          growthOutlook: .init(
            hp: .neutral,
            attack: .favored,
            defense: .neutral,
            speed: .lagging,
            special: .neutral
          )
        )
      ]
    )
    let speciesDetailsByID = [
      "BULBASAUR": PartySidebarSpeciesDetails(
        spriteURL: URL(fileURLWithPath: "/tmp/bulbasaur.png"),
        primaryType: "GRASS",
        secondaryType: "POISON"
      )
    ]
    let moveDisplayNamesByID = [
      "TACKLE": "Tackle",
      "GROWL": "Growl",
    ]

    let profile = GameplaySidebarPropsBuilder.makeProfile(
      trainerName: "RED",
      locationName: "Oak's Lab",
      scene: .starterChoice,
      playerPosition: .init(x: 5, y: 6),
      facing: .up,
      portrait: .init(
        label: "RED",
        spriteURL: URL(fileURLWithPath: "/tmp/red.png"),
        spriteFrame: .init(x: 0, y: 16, width: 16, height: 16)
      ),
      money: 4242,
      ownedBadgeIDs: ["cascade", "boulder"]
    )
    let sidebarParty = GameplaySidebarPropsBuilder.makeParty(
      from: party,
      speciesDetailsByID: speciesDetailsByID,
      moveDisplayNamesByID: moveDisplayNamesByID
    )

    XCTAssertEqual(profile.locationName, "Oak's Lab")
    XCTAssertEqual(profile.moneyText, "¥4,242")
    XCTAssertEqual(profile.badgeSummaryText, "2/8")
    XCTAssertEqual(profile.badges.prefix(2).map(\.isEarned), [true, true])
    XCTAssertEqual(profile.portrait.spriteURL?.path, "/tmp/red.png")
    XCTAssertEqual(sidebarParty.pokemon.count, 1)
    XCTAssertEqual(sidebarParty.pokemon.first?.displayName, "Bulbasaur")
    XCTAssertEqual(sidebarParty.pokemon.first?.level, 5)
    XCTAssertEqual(sidebarParty.pokemon.first?.totalExperience, 150)
    XCTAssertEqual(sidebarParty.pokemon.first?.levelStartExperience, 135)
    XCTAssertEqual(sidebarParty.pokemon.first?.nextLevelExperience, 179)
    XCTAssertEqual(sidebarParty.pokemon.first?.currentHP, 19)
    XCTAssertEqual(sidebarParty.pokemon.first?.maxHP, 19)
    XCTAssertEqual(sidebarParty.pokemon.first?.statHP, 19)
    XCTAssertEqual(sidebarParty.pokemon.first?.attack, 11)
    XCTAssertEqual(sidebarParty.pokemon.first?.defense, 10)
    XCTAssertEqual(sidebarParty.pokemon.first?.speed, 9)
    XCTAssertEqual(sidebarParty.pokemon.first?.special, 12)
    XCTAssertEqual(sidebarParty.pokemon.first?.attackGrowthOutlook, .favored)
    XCTAssertEqual(sidebarParty.pokemon.first?.speedGrowthOutlook, .lagging)
    XCTAssertEqual(sidebarParty.pokemon.first?.isLead, true)
    XCTAssertEqual(sidebarParty.pokemon.first?.typeLabels, ["GRASS", "POISON"])
    XCTAssertEqual(sidebarParty.pokemon.first?.moveNames, ["Tackle", "Growl"])
    XCTAssertEqual(sidebarParty.pokemon.first?.spriteURL?.path, "/tmp/bulbasaur.png")
  }
  func testSidebarExpansionStateKeepsExactlyOneSectionOpen() {
    var expansion = GameplaySidebarExpansionState()

    XCTAssertEqual(expansion.expandedSection, .trainer)

    expansion.activate(.bag)
    XCTAssertEqual(expansion.expandedSection, .bag)

    expansion.activate(.save)
    XCTAssertEqual(expansion.expandedSection, .save)

    expansion.activate(.save)
    XCTAssertEqual(expansion.expandedSection, .save)

    expansion.activate(.options)
    XCTAssertEqual(expansion.expandedSection, .options)

    expansion.activate(.battleCombat)
    XCTAssertEqual(expansion.expandedSection, .battleCombat)

    expansion.activate(.party)
    XCTAssertEqual(expansion.expandedSection, .party)
  }
  func testSaveAndOptionsBuildersProduceDisabledRows() {
    let save = GameplaySidebarPropsBuilder.makeSaveSection()
    let options = GameplaySidebarPropsBuilder.makeOptionsSection(
      isMusicEnabled: true,
      appearanceMode: .light
    )

    XCTAssertEqual(save.actions.map(\.title), ["Save Game", "Load Save"])
    XCTAssertTrue(save.actions.allSatisfy { $0.isEnabled == false })
    XCTAssertEqual(
      options.rows.map(\.title), ["Appearance", "Text Speed", "Battle Scene", "Battle Style", "Music"])
    XCTAssertEqual(options.rows.map(\.isEnabled), [true, false, false, false, true])
    XCTAssertEqual(options.rows.last?.detail, "On")
    XCTAssertEqual(options.rows.first?.detail, "Light")
  }
  func testThemePaletteResolvesDistinctLightAndDarkValues() {
    let light = PokeThemePalette.resolve(for: .light)
    let dark = PokeThemePalette.resolve(for: .retroDark)

    XCTAssertNotEqual(light.primaryText, dark.primaryText)
    XCTAssertNotEqual(light.field.ink, dark.field.ink)
    XCTAssertEqual(light.screenGlow.alpha, 0)
    XCTAssertGreaterThan(dark.screenGlow.alpha, 0)
  }
  func testOptionsBuilderReflectsAppearanceWithoutChangingMusicState() {
    let systemOptions = GameplaySidebarPropsBuilder.makeOptionsSection(
      isMusicEnabled: true,
      appearanceMode: .system
    )
    let lightOptions = GameplaySidebarPropsBuilder.makeOptionsSection(
      isMusicEnabled: true,
      appearanceMode: .light
    )
    let darkOptions = GameplaySidebarPropsBuilder.makeOptionsSection(
      isMusicEnabled: true,
      appearanceMode: .retroDark
    )

    XCTAssertEqual(systemOptions.rows.first?.detail, "System")
    XCTAssertEqual(lightOptions.rows.first?.detail, "Light")
    XCTAssertEqual(darkOptions.rows.first?.detail, "Dark")
    XCTAssertEqual(systemOptions.rows.last?.detail, "On")
    XCTAssertEqual(lightOptions.rows.last?.detail, "On")
    XCTAssertEqual(darkOptions.rows.last?.detail, "On")
  }
  func testAppearanceModeCyclesSystemDarkLight() {
    XCTAssertEqual(AppAppearanceMode.system.nextOptionMode, .retroDark)
    XCTAssertEqual(AppAppearanceMode.retroDark.nextOptionMode, .light)
    XCTAssertEqual(AppAppearanceMode.light.nextOptionMode, .system)
  }
  func testSystemAppearanceResolvesUsingCurrentColorScheme() {
    XCTAssertEqual(AppAppearanceMode.system.resolved(for: .light), .light)
    XCTAssertEqual(AppAppearanceMode.system.resolved(for: .dark), .retroDark)
    XCTAssertFalse(AppAppearanceMode.system.isDark(for: .light))
    XCTAssertTrue(AppAppearanceMode.system.isDark(for: .dark))
  }

  private func measureFittingHeight<Content: View>(of view: Content, width: CGFloat) -> CGFloat {
    let hostingView = NSHostingView(rootView: view.frame(width: width))
    hostingView.setFrameSize(NSSize(width: width, height: 10_000))
    hostingView.layoutSubtreeIfNeeded()
    return hostingView.fittingSize.height
  }
}
