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
        options: GameplaySidebarPropsBuilder.makeOptionsSection(isMusicEnabled: true)
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
    let options = GameplaySidebarPropsBuilder.makeOptionsSection(isMusicEnabled: true)

    XCTAssertEqual(save.actions.map(\.title), ["Save Game", "Load Save"])
    XCTAssertTrue(save.actions.allSatisfy { $0.isEnabled == false })
    XCTAssertEqual(
      options.rows.map(\.title), ["Text Speed", "Battle Scene", "Battle Style", "Music"])
    XCTAssertEqual(options.rows.map(\.isEnabled), [false, false, false, true])
    XCTAssertEqual(options.rows.last?.detail, "On")
  }
}
