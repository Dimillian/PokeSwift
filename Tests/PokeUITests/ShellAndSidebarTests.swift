import AppKit
import ImageIO
import PokeCore
import PokeDataModel
import PokeRender
import SwiftUI
import UniformTypeIdentifiers
import XCTest

@testable import PokeUI

@MainActor
extension PokeUITests {
  func testGameplayScreenGlowPaletteKeepsLegacyTintedGlowInLightAppearance() {
    let glowPalette = PokeThemePalette.gameplayScreenGlowPalette(
      displayStyle: .dmgTinted,
      appearanceMode: .light,
      colorScheme: .light
    )

    XCTAssertEqual(glowPalette.outer, ThemeRGBA(red: 0.52, green: 0.78, blue: 0.46, alpha: 0.22))
    XCTAssertEqual(glowPalette.inner, ThemeRGBA(red: 0.92, green: 0.98, blue: 0.84, alpha: 0.14))
  }

  func testGameplayScreenGlowPaletteKeepsLegacyTintedGlowInRetroDarkAppearance() {
    let glowPalette = PokeThemePalette.gameplayScreenGlowPalette(
      displayStyle: .dmgTinted,
      appearanceMode: .retroDark,
      colorScheme: .dark
    )

    XCTAssertEqual(glowPalette.outer, ThemeRGBA(red: 0.22, green: 0.96, blue: 0.24, alpha: 0.38))
    XCTAssertEqual(glowPalette.inner, ThemeRGBA(red: 0.74, green: 1, blue: 0.72, alpha: 0.2))
  }

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
        pokedex: GameplaySidebarPropsBuilder.makePokedex(
          allSpecies: [],
          ownedSpeciesIDs: [],
          seenSpeciesIDs: []
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
          appearanceMode: .light,
          gameBoyShellStyle: .classic,
          gameplayHDREnabled: true
        )
      )
    )
    let view = GameplayShell(
      sidebarMode: sidebarMode,
      fieldDisplayStyle: .constant(.defaultGameplayStyle),
      sidebarExpansionState: .constant(
        GameplaySidebarExpansionState(expandedSection: sidebarMode.defaultExpandedSection)
      )
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
        phase: .moveSelection,
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
      fieldDisplayStyle: .constant(.defaultGameplayStyle),
      sidebarExpansionState: .constant(
        GameplaySidebarExpansionState(expandedSection: sidebarMode.defaultExpandedSection)
      )
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
  func testBattlePanelCanBeConstructedWithDisplayStyleAwareBattlefieldLayer() {
    let view = BattlePanel(
      trainerName: "BLUE",
      kind: .trainer,
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
      isEnemySpeciesOwned: false,
      trainerSpriteURL: nil,
      playerTrainerFrontSpriteURL: nil,
      playerTrainerBackSpriteURL: nil,
      sendOutPoofSpriteURL: nil,
      battleAnimationManifest: .empty,
      battleAnimationTilesetURLs: [:],
      playerSpriteURL: nil,
      enemySpriteURL: nil,
      displayStyle: .dmgAuthentic,
      presentation: .init(
        stage: .commandReady,
        revision: 1,
        uiVisibility: .visible
      )
    )

    XCTAssertNotNil(view)
  }
  func testBattleStatusCardSharedNameScaleFitsTenCharacterNamesOnCompactViewport() {
    let layout = BattleViewportLayout(size: CGSize(width: 320, height: 288))
    let nameScale = BattleStatusCard.sharedNameScale(
      enemyCardWidth: layout.enemyCardSize.width,
      playerCardWidth: layout.playerCardSize.width,
      enemyShowsCaughtIndicator: true
    )
    let availableWidth = BattleStatusCard.availableNameWidth(
      cardWidth: layout.enemyCardSize.width,
      showsCaughtIndicator: true
    )

    XCTAssertLessThan(nameScale, BattleStatusCard.preferredNameScale)
    XCTAssertLessThanOrEqual(
      BattleStatusCard.requiredNameWidth(scale: nameScale),
      availableWidth + 0.001
    )
  }
  func testBattleStatusCardSharedNameScaleKeepsPreferredSizeOnRoomyViewport() {
    let layout = BattleViewportLayout(size: CGSize(width: 640, height: 576))
    let nameScale = BattleStatusCard.sharedNameScale(
      enemyCardWidth: layout.enemyCardSize.width,
      playerCardWidth: layout.playerCardSize.width
    )

    XCTAssertEqual(nameScale, BattleStatusCard.preferredNameScale, accuracy: 0.001)
  }
  func testBattleStatusCardCaughtIndicatorShowsOnlyForOwnedEnemy() {
    XCTAssertTrue(BattleStatusCard.showsCaughtIndicator(chrome: .enemy, battleKind: .wild, isSpeciesOwned: true))
    XCTAssertFalse(BattleStatusCard.showsCaughtIndicator(chrome: .enemy, battleKind: .wild, isSpeciesOwned: false))
    XCTAssertFalse(BattleStatusCard.showsCaughtIndicator(chrome: .enemy, battleKind: .trainer, isSpeciesOwned: true))
    XCTAssertFalse(BattleStatusCard.showsCaughtIndicator(chrome: .player, battleKind: .wild, isSpeciesOwned: true))
  }
  func testBattleStatusCardCaughtIndicatorUsesVisibleAccessorySize() {
    XCTAssertGreaterThan(BattleStatusCard.caughtIndicatorDiameter(scale: BattleStatusCard.metadataScale), 0)
    XCTAssertGreaterThan(
      BattleStatusCard.caughtIndicatorReservedWidth(scale: BattleStatusCard.metadataScale),
      BattleStatusCard.caughtIndicatorDiameter(scale: BattleStatusCard.metadataScale)
    )
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
      ownedBadgeIDs: [],
      totalStepCount: 1234,
      wildEncounterCount: 56,
      trainerBattleCount: 7
    )
    let party = GameplaySidebarPropsBuilder.makeParty(from: nil)
    let inventory = GameplaySidebarPropsBuilder.makeInventory()

    XCTAssertEqual(profile.moneyText, "¥3,000")
    XCTAssertEqual(
      profile.stats,
      [
        .init(id: "steps", label: "Steps", valueText: "1,234"),
        .init(id: "wild", label: "Wild", valueText: "56"),
        .init(id: "trainer", label: "Trainers", valueText: "7"),
      ]
    )
    XCTAssertEqual(profile.badgeSummaryText, "0/8")
    XCTAssertEqual(profile.badges.count, 8)
    XCTAssertEqual(profile.statusItems, ["FIELD", "X4 Y4", "DOWN"])
    XCTAssertTrue(party.pokemon.isEmpty)
    XCTAssertEqual(inventory.emptyStateTitle, "No items yet")
    XCTAssertTrue(inventory.sections.isEmpty)
  }
  func testInventoryBuilderPreservesSectionedBagMetadata() {
    let inventory = GameplaySidebarPropsBuilder.makeInventory(
      sections: [
        .init(
          id: "tmhm",
          title: "TM/HM",
          items: [
            .init(
              id: "TM_BUBBLEBEAM",
              name: "TM11",
              quantityText: "x1",
              iconURL: URL(fileURLWithPath: "/tmp/tm-water.png"),
              descriptionText: "A technical machine that teaches BUBBLEBEAM.",
              tmhm: .init(moveName: "BUBBLEBEAM", typeLabel: "WATER", maxPPText: "PP 20"),
              isFocused: true
            )
          ]
        )
      ]
    )

    XCTAssertEqual(inventory.sections.map(\.title), ["TM/HM"])
    XCTAssertEqual(inventory.sections.first?.items.first?.descriptionText, "A technical machine that teaches BUBBLEBEAM.")
    XCTAssertEqual(inventory.sections.first?.items.first?.tmhm?.moveName, "BUBBLEBEAM")
    XCTAssertEqual(inventory.sections.first?.items.first?.tmhm?.typeLabel, "WATER")
    XCTAssertTrue(inventory.sections.first?.items.first?.isFocused == true)
  }
  func testPokedexSidebarBuilderIncludesStructuredDetailFields() {
    let props = GameplaySidebarPropsBuilder.makePokedex(
      allSpecies: [
        .init(
          id: "PIDGEY",
          dexNumber: 16,
          displayName: "Pidgey",
          primaryType: "NORMAL",
          secondaryType: "FLYING",
          spriteURL: nil,
          speciesCategory: "Tiny Bird",
          heightText: "1'00\"",
          weightText: "4.0 LB",
          descriptionText: "A common sight in forests and woods.",
          baseHP: 40,
          baseAttack: 45,
          baseDefense: 40,
          baseSpeed: 56,
          baseSpecial: 35
        )
      ],
      ownedSpeciesIDs: ["PIDGEY"],
      seenSpeciesIDs: ["PIDGEY"],
      speciesEncounterCounts: ["PIDGEY": 3]
    )

    guard let entry = props.entries.first else {
      XCTFail("Expected a Pokedex entry")
      return
    }

    XCTAssertEqual(entry.detailFields.map(\.id), ["height", "weight", "encounters"])
    XCTAssertEqual(entry.detailFields.last?.label, "ENCOUNTERS")
    XCTAssertEqual(entry.detailFields.last?.value, "3")
  }

  func testPokedexSidebarBuilderExposesOwnedEvolutionAndLearnsetDetails() {
    let props = GameplaySidebarPropsBuilder.makePokedex(
      allSpecies: [
        .init(
          id: "IVYSAUR",
          dexNumber: 2,
          displayName: "Ivysaur",
          primaryType: "GRASS",
          secondaryType: "POISON",
          spriteURL: nil,
          speciesCategory: "Seed",
          heightText: "3'03\"",
          weightText: "28.7 LB",
          descriptionText: "When the bulb grows large, it appears to lose the ability to stand on its hind legs.",
          preEvolution: .init(id: "BULBASAUR", displayName: "Bulbasaur", triggerText: "Lv 16"),
          evolutions: [
            .init(id: "VENUSAUR", displayName: "Venusaur", triggerText: "Lv 32")
          ],
          learnedMoves: [
            .init(id: "IVYSAUR-LEECH_SEED-7", levelText: "Lv 7", displayName: "Leech Seed"),
            .init(id: "IVYSAUR-VINE_WHIP-13", levelText: "Lv 13", displayName: "Vine Whip")
          ],
          baseHP: 60,
          baseAttack: 62,
          baseDefense: 63,
          baseSpeed: 60,
          baseSpecial: 80
        )
      ],
      ownedSpeciesIDs: ["IVYSAUR"],
      seenSpeciesIDs: ["IVYSAUR"]
    )

    guard let entry = props.entries.first else {
      XCTFail("Expected a Pokedex entry")
      return
    }

    XCTAssertEqual(entry.preEvolution?.displayName, "Bulbasaur")
    XCTAssertEqual(entry.preEvolution?.triggerText, "Lv 16")
    XCTAssertEqual(entry.evolutions.map(\.displayName), ["Venusaur"])
    XCTAssertEqual(entry.evolutions.map(\.triggerText), ["Lv 32"])
    XCTAssertEqual(entry.learnedMoves.map(\.levelText), ["Lv 7", "Lv 13"])
    XCTAssertEqual(entry.learnedMoves.map(\.displayName), ["Leech Seed", "Vine Whip"])
  }

  func testPokedexSidebarBuilderCarriesSelectedEntryID() {
    let props = GameplaySidebarPropsBuilder.makePokedex(
      allSpecies: [
        .init(
          id: "PIDGEY",
          dexNumber: 16,
          displayName: "Pidgey",
          primaryType: "NORMAL",
          secondaryType: "FLYING",
          spriteURL: nil,
          speciesCategory: nil,
          heightText: nil,
          weightText: nil,
          descriptionText: nil,
          baseHP: 40,
          baseAttack: 45,
          baseDefense: 40,
          baseSpeed: 56,
          baseSpecial: 35
        )
      ],
      ownedSpeciesIDs: ["PIDGEY"],
      seenSpeciesIDs: ["PIDGEY"],
      selectedEntryID: "PIDGEY"
    )

    XCTAssertEqual(props.selectedEntryID, "PIDGEY")
  }

  func testGameBoyUppercasedLabelPreservesPokemonAccentConvention() {
    XCTAssertEqual(gameBoyUppercasedLabel("Trainer"), "TRAINER")
    XCTAssertEqual(gameBoyUppercasedLabel("Pokédex"), "POKéDEX")
  }

  func testPokedexSidebarBuilderKeepsSeenSpritesWithoutOwnedOnlyDetails() {
    let spriteURL = URL(fileURLWithPath: "/tmp/pidgey.png")
    let props = GameplaySidebarPropsBuilder.makePokedex(
      allSpecies: [
        .init(
          id: "PIDGEY",
          dexNumber: 16,
          displayName: "Pidgey",
          primaryType: "NORMAL",
          secondaryType: "FLYING",
          spriteURL: spriteURL,
          speciesCategory: "Tiny Bird",
          heightText: "1'00\"",
          weightText: "4.0 LB",
          descriptionText: "A common sight in forests and woods.",
          baseHP: 40,
          baseAttack: 45,
          baseDefense: 40,
          baseSpeed: 56,
          baseSpecial: 35
        )
      ],
      ownedSpeciesIDs: [],
      seenSpeciesIDs: ["PIDGEY"],
      speciesEncounterCounts: ["PIDGEY": 3]
    )

    guard let entry = props.entries.first else {
      XCTFail("Expected a Pokedex entry")
      return
    }

    XCTAssertEqual(props.ownedCount, 0)
    XCTAssertEqual(props.seenCount, 1)
    XCTAssertEqual(entry.spriteURL, spriteURL)
    XCTAssertTrue(entry.isSeen)
    XCTAssertFalse(entry.isOwned)
    XCTAssertNil(entry.speciesCategory)
    XCTAssertNil(entry.heightText)
    XCTAssertNil(entry.weightText)
    XCTAssertNil(entry.descriptionText)
    XCTAssertNil(entry.preEvolution)
    XCTAssertTrue(entry.evolutions.isEmpty)
    XCTAssertTrue(entry.learnedMoves.isEmpty)
    XCTAssertTrue(entry.detailFields.isEmpty)
    XCTAssertEqual(entry.baseHP, 0)
    XCTAssertEqual(entry.baseAttack, 0)
    XCTAssertEqual(entry.baseDefense, 0)
    XCTAssertEqual(entry.baseSpeed, 0)
    XCTAssertEqual(entry.baseSpecial, 0)
  }
  func testGameplaySidebarKindMapsRuntimeScenesForGameplayLayout() {
    XCTAssertEqual(GameplaySidebarKind.forScene(.field), .fieldLike)
    XCTAssertEqual(GameplaySidebarKind.forScene(.dialogue), .fieldLike)
    XCTAssertEqual(GameplaySidebarKind.forScene(.starterChoice), .fieldLike)
    XCTAssertEqual(GameplaySidebarKind.forScene(.evolution), .fieldLike)
    XCTAssertEqual(GameplaySidebarKind.forScene(.battle), .battle)
  }
  func testSidebarPropBuilderMapsEvolutionProfileStatus() {
    let profile = GameplaySidebarPropsBuilder.makeProfile(
      trainerName: "RED",
      locationName: "Red's House",
      scene: .evolution,
      playerPosition: .init(x: 4, y: 4),
      facing: .down,
      portrait: .init(label: "RED", spriteURL: nil, spriteFrame: nil),
      money: 3000,
      ownedBadgeIDs: [],
      totalStepCount: 0,
      wildEncounterCount: 0,
      trainerBattleCount: 0
    )

    XCTAssertEqual(profile.statusItems, ["EVOLVE", "X4 Y4", "DOWN"])
  }
  func testBattleSidebarPropsPreservePhaseSpecificState() {
    let moveSelection = BattleSidebarProps(
      trainerName: "BLUE",
      kind: .trainer,
      phase: .moveSelection,
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
      phase: .turnText,
      promptText: "Charmander used Scratch!",
      playerPokemon: moveSelection.playerPokemon,
      enemyPokemon: moveSelection.enemyPokemon,
      moveSlots: moveSelection.moveSlots,
      focusedMoveIndex: moveSelection.focusedMoveIndex,
      canRun: moveSelection.canRun,
      party: moveSelection.party
    )

    XCTAssertEqual(moveSelection.phase, .moveSelection)
    XCTAssertEqual(moveSelection.promptText, "Pick the next move.")
    XCTAssertEqual(resolve.phase, .turnText)
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
      phase: .learnMoveDecision,
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
      phase: .learnMoveSelection,
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
        phase: .moveSelection,
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
        phase: .moveSelection,
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
      phase: .moveSelection,
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
      party: .init(pokemon: []),
      presentation: .init(
        stage: .commandReady,
        revision: 1,
        uiVisibility: .visible
      )
    )

    XCTAssertEqual(props.actionRows.map(\.kind), [.move, .move, .run])
    XCTAssertEqual(props.actionRows.last?.title, "Run")
    XCTAssertEqual(props.actionRows.last?.detail, nil)
    XCTAssertEqual(props.actionRows[0].detail, "35/35")
    XCTAssertEqual(props.actionRows[1].isFocused, true)
    XCTAssertEqual(props.actionRows.last?.isSelectable, true)
  }
  func testBattleSidebarMoveCardPropsUseDetailedMoveMetadata() throws {
    let props = BattleSidebarProps(
      trainerName: "PIDGEY",
      kind: .wild,
      phase: .moveSelection,
      promptText: "Pick the next move.",
      playerPokemon: .init(
        speciesID: "PIKACHU",
        displayName: "Pikachu",
        level: 12,
        currentHP: 32,
        maxHP: 32,
        attack: 18,
        defense: 14,
        speed: 24,
        special: 19,
        moves: ["THUNDERBOLT"]
      ),
      enemyPokemon: .init(
        speciesID: "PIDGEY",
        displayName: "Pidgey",
        level: 9,
        currentHP: 20,
        maxHP: 20,
        attack: 13,
        defense: 12,
        speed: 15,
        special: 10,
        moves: ["TACKLE"]
      ),
      moveSlots: [
        .init(moveID: "THUNDERBOLT", displayName: "Thunderbolt", currentPP: 15, maxPP: 15, isSelectable: true)
      ],
      focusedMoveIndex: 0,
      canRun: true,
      moveDetailsByID: [
        "THUNDERBOLT": .init(
          displayName: "Thunderbolt",
          typeLabel: "ELECTRIC",
          maxPP: 15,
          power: 95,
          accuracy: 100
        )
      ],
      party: .init(pokemon: []),
      presentation: .init(
        stage: .commandReady,
        revision: 1,
        uiVisibility: .visible
      )
    )

    let moveAction = try XCTUnwrap(props.actionRows.first)
    let moveCard = try XCTUnwrap(props.moveCardProps(for: moveAction))

    XCTAssertEqual(moveCard.displayName, "Thunderbolt")
    XCTAssertEqual(moveCard.typeChipText, "ELECTRIC")
    XCTAssertEqual(moveCard.metadataChips.map(\.displayText), ["PP 15/15", "POW 95", "ACC 100"])
    XCTAssertNil(props.moveCardProps(for: props.actionRows.last!))
  }
  func testBattleSidebarPropsHideCombatUiDuringIntroPresentation() {
    let props = BattleSidebarProps(
      trainerName: "BLUE",
      kind: .trainer,
      phase: .introText,
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
  func testBattleSidebarPropsRevealCombatantsAlongsidePresentationTiming() {
    func makeProps(kind: BattleKind, presentation: BattlePresentationTelemetry) -> BattleSidebarProps {
      BattleSidebarProps(
        trainerName: "BLUE",
        kind: kind,
        phase: .turnText,
        promptText: "Battle intro text.",
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
        moveSlots: [],
        focusedMoveIndex: 0,
        canRun: false,
        party: .init(pokemon: []),
        presentation: presentation
      )
    }

    let trainerIntroProps = makeProps(
      kind: .trainer,
      presentation: .init(
        stage: .introReveal,
        revision: 1,
        uiVisibility: .visible
      )
    )
    XCTAssertFalse(trainerIntroProps.showsEnemyCombatantStatus)
    XCTAssertFalse(trainerIntroProps.showsPlayerCombatantStatus)

    let trainerEnemySendOutProps = makeProps(
      kind: .trainer,
      presentation: .init(
        stage: .enemySendOut,
        revision: 2,
        uiVisibility: .visible,
        activeSide: .enemy
      )
    )
    XCTAssertTrue(trainerEnemySendOutProps.showsEnemyCombatantStatus)
    XCTAssertFalse(trainerEnemySendOutProps.showsPlayerCombatantStatus)

    let trainerPlayerSendOutProps = makeProps(
      kind: .trainer,
      presentation: .init(
        stage: .enemySendOut,
        revision: 3,
        uiVisibility: .visible,
        activeSide: .player
      )
    )
    XCTAssertTrue(trainerPlayerSendOutProps.showsEnemyCombatantStatus)
    XCTAssertTrue(trainerPlayerSendOutProps.showsPlayerCombatantStatus)

    let wildIntroProps = makeProps(
      kind: .wild,
      presentation: .init(
        stage: .introReveal,
        revision: 4,
        uiVisibility: .visible
      )
    )
    XCTAssertTrue(wildIntroProps.showsEnemyCombatantStatus)
    XCTAssertFalse(wildIntroProps.showsPlayerCombatantStatus)

    let wildPlayerSendOutProps = makeProps(
      kind: .wild,
      presentation: .init(
        stage: .enemySendOut,
        revision: 5,
        uiVisibility: .visible,
        activeSide: .player
      )
    )
    XCTAssertTrue(wildPlayerSendOutProps.showsEnemyCombatantStatus)
    XCTAssertTrue(wildPlayerSendOutProps.showsPlayerCombatantStatus)
  }
  func testBattleSidebarActionRowsOnlyAppearWhenBattleInputIsReady() {
    func makeProps(
      phase: BattlePhaseTelemetry,
      presentation: BattlePresentationTelemetry,
      learnMovePrompt: BattleLearnMovePromptTelemetry? = nil
    ) -> BattleSidebarProps {
      BattleSidebarProps(
        trainerName: "PIDGEY",
        kind: .wild,
        phase: phase,
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
        learnMovePrompt: learnMovePrompt,
        moveSlots: [
          .init(moveID: "TACKLE", displayName: "Tackle", currentPP: 35, maxPP: 35, isSelectable: true),
          .init(moveID: "GROWL", displayName: "Growl", currentPP: 40, maxPP: 40, isSelectable: true),
        ],
        focusedMoveIndex: 0,
        canRun: true,
        party: .init(pokemon: []),
        presentation: presentation
      )
    }

    let introProps = makeProps(
      phase: .introText,
      presentation: .init(
        stage: .introReveal,
        revision: 1,
        uiVisibility: .visible
      )
    )
    let sendOutProps = makeProps(
      phase: .moveSelection,
      presentation: .init(
        stage: .enemySendOut,
        revision: 2,
        uiVisibility: .visible,
        activeSide: .player
      )
    )
    let turnTextProps = makeProps(
      phase: .turnText,
      presentation: .init(
        stage: .resultText,
        revision: 3,
        uiVisibility: .visible,
        activeSide: .player
      )
    )
    let bagSelectionProps = makeProps(
      phase: .bagSelection,
      presentation: .init(
        stage: .commandReady,
        revision: 4,
        uiVisibility: .visible
      )
    )
    let commandReadyProps = makeProps(
      phase: .moveSelection,
      presentation: .init(
        stage: .commandReady,
        revision: 5,
        uiVisibility: .visible
      )
    )
    let learnPromptProps = makeProps(
      phase: .learnMoveDecision,
      presentation: .init(
        stage: .resultText,
        revision: 6,
        uiVisibility: .visible
      ),
      learnMovePrompt: .init(
        pokemonName: "Bulbasaur",
        moveID: "VINE_WHIP",
        moveDisplayName: "VINE WHIP",
        stage: .confirm
      )
    )
    let trainerDecisionProps = BattleSidebarProps(
      trainerName: "BUG CATCHER",
      kind: .trainer,
      phase: .trainerAboutToUseDecision,
      promptText: "Will RED change #MON?",
      playerPokemon: commandReadyProps.playerPokemon,
      enemyPokemon: commandReadyProps.enemyPokemon,
      moveSlots: commandReadyProps.moveSlots,
      focusedMoveIndex: 0,
      canRun: false,
      party: .init(pokemon: []),
      presentation: .init(
        stage: .resultText,
        revision: 7,
        uiVisibility: .visible
      )
    )

    XCTAssertTrue(introProps.actionRows.isEmpty)
    XCTAssertTrue(sendOutProps.actionRows.isEmpty)
    XCTAssertTrue(turnTextProps.actionRows.isEmpty)
    XCTAssertTrue(bagSelectionProps.actionRows.isEmpty)
    XCTAssertEqual(
      commandReadyProps.actionRows.map(\.kind),
      [.move, .move, .run] as [BattleSidebarActionRowProps.Kind]
    )
    XCTAssertEqual(
      learnPromptProps.actionRows.map(\.kind),
      [.learn, .skip] as [BattleSidebarActionRowProps.Kind]
    )
    XCTAssertEqual(
      trainerDecisionProps.actionRows.map(\.kind),
      [.confirm, .deny] as [BattleSidebarActionRowProps.Kind]
    )
  }

  func testBattleSidebarViewStateUsesCanonicalSummaryLabels() {
    let props = BattleSidebarProps(
      trainerName: "PIDGEY",
      kind: .wild,
      phase: .moveSelection,
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
        .init(moveID: "TACKLE", displayName: "Tackle", currentPP: 35, maxPP: 35, isSelectable: true)
      ],
      focusedMoveIndex: 0,
      canRun: true,
      party: .init(pokemon: []),
      presentation: .init(stage: .commandReady, revision: 1, uiVisibility: .visible)
    )

    XCTAssertEqual(props.viewState.summaryLabel, "Command")
    XCTAssertEqual(BattleSidebarProps(
      trainerName: props.trainerName,
      kind: props.kind,
      phase: .bagSelection,
      promptText: props.promptText,
      playerPokemon: props.playerPokemon,
      enemyPokemon: props.enemyPokemon,
      moveSlots: props.moveSlots,
      focusedMoveIndex: props.focusedMoveIndex,
      canRun: props.canRun,
      party: props.party,
      presentation: props.presentation
    ).viewState.summaryLabel, "Bag")
    XCTAssertEqual(BattleSidebarProps(
      trainerName: props.trainerName,
      kind: props.kind,
      phase: .learnMoveSelection,
      promptText: props.promptText,
      playerPokemon: props.playerPokemon,
      enemyPokemon: props.enemyPokemon,
      learnMovePrompt: .init(
        pokemonName: "Bulbasaur",
        moveID: "VINE_WHIP",
        moveDisplayName: "VINE WHIP",
        stage: .replace
      ),
      moveSlots: props.moveSlots,
      focusedMoveIndex: props.focusedMoveIndex,
      canRun: props.canRun,
      party: props.party,
      presentation: props.presentation
    ).viewState.summaryLabel, "Forget")
  }
  func testBattleSidebarBagOverlayTracksDerivedViewStatePolicy() {
    func makeProps(
      phase: BattlePhaseTelemetry,
      bagItemCount: Int,
      presentation: BattlePresentationTelemetry
    ) -> BattleSidebarProps {
      BattleSidebarProps(
        trainerName: "PIDGEY",
        kind: .wild,
        phase: phase,
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
        moveSlots: [],
        focusedMoveIndex: 0,
        canRun: true,
        canUseBag: true,
        bagItemCount: bagItemCount,
        party: .init(pokemon: []),
        presentation: presentation
      )
    }

    let visibleBagSelection = makeProps(
      phase: .bagSelection,
      bagItemCount: 2,
      presentation: .init(stage: .commandReady, revision: 1, uiVisibility: .visible)
    )
    let hiddenBagSelection = makeProps(
      phase: .bagSelection,
      bagItemCount: 2,
      presentation: .init(stage: .commandReady, revision: 2, uiVisibility: .hidden)
    )
    let emptyBagSelection = makeProps(
      phase: .bagSelection,
      bagItemCount: 0,
      presentation: .init(stage: .commandReady, revision: 3, uiVisibility: .visible)
    )
    let moveSelection = makeProps(
      phase: .moveSelection,
      bagItemCount: 3,
      presentation: .init(stage: .commandReady, revision: 4, uiVisibility: .visible)
    )

    XCTAssertTrue(visibleBagSelection.viewState.showsBagOverlay)
    XCTAssertTrue(visibleBagSelection.showsBagOverlay)
    XCTAssertFalse(hiddenBagSelection.viewState.showsBagOverlay)
    XCTAssertFalse(hiddenBagSelection.showsBagOverlay)
    XCTAssertFalse(emptyBagSelection.viewState.showsBagOverlay)
    XCTAssertFalse(emptyBagSelection.showsBagOverlay)
    XCTAssertFalse(moveSelection.viewState.showsBagOverlay)
    XCTAssertFalse(moveSelection.showsBagOverlay)
  }

  func testBattleSummaryViewsShareCanonicalSummaryLabel() {
    let props = BattleSidebarProps(
      trainerName: "BLUE",
      kind: .trainer,
      phase: .trainerAboutToUseDecision,
      promptText: "Will RED change #MON?",
      playerPokemon: .init(
        speciesID: "SQUIRTLE",
        displayName: "Squirtle",
        level: 18,
        currentHP: 44,
        maxHP: 44,
        attack: 25,
        defense: 28,
        speed: 22,
        special: 24,
        moves: ["TACKLE", "BUBBLE"]
      ),
      enemyPokemon: .init(
        speciesID: "PIDGEOTTO",
        displayName: "Pidgeotto",
        level: 17,
        currentHP: 38,
        maxHP: 38,
        attack: 24,
        defense: 20,
        speed: 25,
        special: 18,
        moves: ["GUST", "QUICK_ATTACK"]
      ),
      moveSlots: [],
      focusedMoveIndex: 0,
      canRun: false,
      party: .init(pokemon: []),
      presentation: .init(stage: .resultText, revision: 1, uiVisibility: .visible)
    )

    let summaryContent = BattleSummaryContent(props: props)
    let sidebarContent = BattleModeSidebarContent(
      props: props,
      expansionState: GameplaySidebarExpansionState(expandedSection: .battleCombat),
      onPartyRowSelected: nil,
      onActivateSection: { _ in }
    )

    XCTAssertEqual(summaryContent.summaryChipText, "Shift")
    XCTAssertEqual(summaryContent.summaryChipText, props.summaryLabel)
    XCTAssertEqual(sidebarContent.combatSummaryText, props.summaryLabel)
    XCTAssertEqual(summaryContent.summaryChipText, sidebarContent.combatSummaryText)
  }
  func testBattleSidebarActionRowsFocusRunOnlyForWildBattles() {
    let wildProps = BattleSidebarProps(
      trainerName: "PIDGEY",
      kind: .wild,
      phase: .moveSelection,
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
      party: .init(pokemon: []),
      presentation: .init(
        stage: .commandReady,
        revision: 1,
        uiVisibility: .visible
      )
    )
    let trainerProps = BattleSidebarProps(
      trainerName: "BLUE",
      kind: .trainer,
      phase: .moveSelection,
      promptText: "Pick the next move.",
      playerPokemon: wildProps.playerPokemon,
      enemyPokemon: wildProps.enemyPokemon,
      moveSlots: wildProps.moveSlots,
      focusedMoveIndex: 1,
      canRun: false,
      party: .init(pokemon: []),
      presentation: .init(
        stage: .commandReady,
        revision: 2,
        uiVisibility: .visible
      )
    )

    XCTAssertEqual(wildProps.actionRows.map(\.kind), [.move, .move, .run])
    XCTAssertEqual(wildProps.actionRows.last?.isFocused, true)
    XCTAssertEqual(trainerProps.actionRows.map(\.kind), [.move, .move])
  }
  func testBattleSidebarActionRowsInsertBagBeforeRunWhenAvailable() {
    let props = BattleSidebarProps(
      trainerName: "PIDGEY",
      kind: .wild,
      phase: .moveSelection,
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
      party: .init(pokemon: []),
      presentation: .init(
        stage: .commandReady,
        revision: 1,
        uiVisibility: .visible
      )
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
      phase: .moveSelection,
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
      ),
      presentation: .init(
        stage: .commandReady,
        revision: 1,
        uiVisibility: .visible
      )
    )

    XCTAssertEqual(props.actionRows.map(\.kind), [.move, .move, .bag, .partySwitch, .run])
    XCTAssertEqual(props.actionRows[3].title, "Switch")
    XCTAssertTrue(props.actionRows[3].isFocused)
    XCTAssertFalse(props.actionRows[4].isFocused)
  }
  func testBattleSidebarAttentionSectionTracksBlockingSidebarInput() {
    let basePlayerPokemon = PartyPokemonTelemetry(
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
    )
    let baseEnemyPokemon = PartyPokemonTelemetry(
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
    )
    let moveSlots = [
      BattleMoveSlotTelemetry(
        moveID: "TACKLE",
        displayName: "Tackle",
        currentPP: 35,
        maxPP: 35,
        isSelectable: true
      ),
      BattleMoveSlotTelemetry(
        moveID: "GROWL",
        displayName: "Growl",
        currentPP: 40,
        maxPP: 40,
        isSelectable: true
      ),
    ]

    let moveSelection = BattleSidebarProps(
      trainerName: "PIDGEY",
      kind: .wild,
      phase: .moveSelection,
      promptText: "Pick the next move.",
      playerPokemon: basePlayerPokemon,
      enemyPokemon: baseEnemyPokemon,
      moveSlots: moveSlots,
      focusedMoveIndex: 0,
      canRun: true,
      party: .init(pokemon: [])
    )
    let trainerDecision = BattleSidebarProps(
      trainerName: "BUG CATCHER",
      kind: .trainer,
      phase: .trainerAboutToUseDecision,
      promptText: "Will RED change #MON?",
      playerPokemon: basePlayerPokemon,
      enemyPokemon: baseEnemyPokemon,
      moveSlots: moveSlots,
      focusedMoveIndex: 1,
      canRun: false,
      party: .init(pokemon: [])
    )
    let partySelection = BattleSidebarProps(
      trainerName: "PIDGEY",
      kind: .wild,
      phase: .partySelection,
      promptText: "Bring out which #MON?",
      playerPokemon: basePlayerPokemon,
      enemyPokemon: baseEnemyPokemon,
      moveSlots: moveSlots,
      focusedMoveIndex: 0,
      canRun: true,
      canSwitch: true,
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
          ),
          .init(
            id: "pidgey-1",
            speciesID: "PIDGEY",
            displayName: "Pidgey",
            level: 3,
            currentHP: 12,
            maxHP: 12,
            isLead: false,
            isSelectable: true,
            isFocused: true
          ),
        ],
        mode: .battleSwitch,
        promptText: "Bring out which #MON?"
      )
    )
    let turnText = BattleSidebarProps(
      trainerName: "PIDGEY",
      kind: .wild,
      phase: .turnText,
      promptText: "Bulbasaur used Tackle!",
      playerPokemon: basePlayerPokemon,
      enemyPokemon: baseEnemyPokemon,
      moveSlots: moveSlots,
      focusedMoveIndex: 0,
      canRun: true,
      party: .init(pokemon: [])
    )

    XCTAssertEqual(moveSelection.attentionSection, .battleCombat)
    XCTAssertEqual(trainerDecision.attentionSection, .battleCombat)
    XCTAssertEqual(partySelection.attentionSection, .party)
    XCTAssertNil(turnText.attentionSection)
  }
  func testBattleSidebarModeForcesPartySectionDuringSwitchSelection() {
    let battleMode = GameplaySidebarMode.battle(
      BattleSidebarProps(
        trainerName: "PIDGEY",
        kind: .wild,
        phase: .partySelection,
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
  func testPartySidebarBuilderMapsMedicineTargetingState() {
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
          currentHP: 8,
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
      mode: .itemUseTarget,
      focusedIndex: 1,
      selectableIndices: [1],
      annotationByIndex: [0: "FULL HP", 1: "ACTIVE"],
      promptText: "Use POTION on which #MON?"
    )

    XCTAssertEqual(sidebarParty.mode, .itemUseTarget)
    XCTAssertEqual(sidebarParty.promptText, "Use POTION on which #MON?")
    XCTAssertEqual(sidebarParty.pokemon[0].selectionAnnotation, "FULL HP")
    XCTAssertFalse(sidebarParty.pokemon[0].isSelectable)
    XCTAssertEqual(sidebarParty.pokemon[1].selectionAnnotation, "ACTIVE")
    XCTAssertTrue(sidebarParty.pokemon[1].isSelectable)
    XCTAssertTrue(sidebarParty.pokemon[1].isFocused)
  }
  func testBattleSidebarRoutesMedicineTargetingAttentionToParty() {
    let props = BattleSidebarProps(
      trainerName: "PIDGEY",
      kind: .wild,
      phase: .partySelection,
      promptText: "Use POTION on which #MON?",
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
        moves: ["TACKLE"]
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
        .init(moveID: "TACKLE", displayName: "Tackle", currentPP: 35, maxPP: 35, isSelectable: true)
      ],
      focusedMoveIndex: 0,
      canRun: true,
      party: .init(
        pokemon: [],
        mode: .itemUseTarget,
        promptText: "Use POTION on which #MON?"
      ),
      presentation: .init(
        stage: .commandReady,
        revision: 1,
        uiVisibility: .visible
      )
    )

    XCTAssertFalse(props.shouldForceCombatSectionOpen)
    XCTAssertEqual(props.attentionSection, GameplaySidebarExpandedSection.party)
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
    let moveDetailsByID = [
      "TACKLE": PartySidebarMoveDetails(
        displayName: "Tackle",
        typeLabel: "NORMAL",
        maxPP: 35,
        power: 40,
        accuracy: 100
      ),
      "GROWL": PartySidebarMoveDetails(
        displayName: "Growl",
        typeLabel: "NORMAL",
        maxPP: 40,
        power: nil,
        accuracy: 100
      ),
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
      ownedBadgeIDs: ["CASCADE_BADGE", "BoulderBadge"],
      totalStepCount: 9876,
      wildEncounterCount: 12,
      trainerBattleCount: 3
    )
    let sidebarParty = GameplaySidebarPropsBuilder.makeParty(
      from: party,
      speciesDetailsByID: speciesDetailsByID,
      moveDetailsByID: moveDetailsByID
    )

    XCTAssertEqual(profile.locationName, "Oak's Lab")
    XCTAssertEqual(profile.moneyText, "¥4,242")
    XCTAssertEqual(profile.stats.map(\.valueText), ["9,876", "12", "3"])
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
    XCTAssertEqual(
      sidebarParty.pokemon.first?.moves,
      [
        PartySidebarMoveProps(
          id: "BULBASAUR-move-0-TACKLE",
          moveID: "TACKLE",
          displayName: "Tackle",
          typeLabel: "NORMAL",
          currentPP: nil,
          maxPP: 35,
          power: 40,
          accuracy: 100
        ),
        PartySidebarMoveProps(
          id: "BULBASAUR-move-1-GROWL",
          moveID: "GROWL",
          displayName: "Growl",
          typeLabel: "NORMAL",
          currentPP: nil,
          maxPP: 40,
          power: nil,
          accuracy: 100
        ),
      ]
    )
    XCTAssertEqual(sidebarParty.pokemon.first?.spriteURL?.path, "/tmp/bulbasaur.png")
  }
  func testPartySidebarMovePropsFormatDetailedMetadataChips() {
    let thunderbolt = PartySidebarMoveProps(
      id: "pikachu-0-thunderbolt",
      moveID: "THUNDERBOLT",
      displayName: "Thunderbolt",
      typeLabel: "ELECTRIC",
      currentPP: 15,
      maxPP: 15,
      power: 95,
      accuracy: 100
    )
    let swift = PartySidebarMoveProps(
      id: "pikachu-0-swift",
      moveID: "SWIFT",
      displayName: "Swift",
      typeLabel: "NORMAL",
      currentPP: nil,
      maxPP: 20,
      power: 60,
      accuracy: nil
    )

    XCTAssertEqual(thunderbolt.typeChipText, "ELECTRIC")
    XCTAssertEqual(thunderbolt.metadataChips.map(\.displayText), ["PP 15/15", "POW 95", "ACC 100"])
    XCTAssertEqual(swift.typeChipText, "NORMAL")
    XCTAssertEqual(swift.metadataChips.map(\.displayText), ["PP 20", "POW 60", "ACC --"])
  }

  func testPartyPokemonHoverCardDetailedMoveRowsStayCompact() {
    let props = PartySidebarPokemonProps(
      id: "bulbasaur-0",
      speciesID: "BULBASAUR",
      displayName: "Bulbasaur",
      level: 18,
      totalExperience: 7_300,
      levelStartExperience: 5_832,
      nextLevelExperience: 8_000,
      currentHP: 49,
      maxHP: 49,
      statHP: 49,
      attack: 35,
      defense: 33,
      speed: 29,
      special: 37,
      isLead: true,
      typeLabels: ["GRASS", "POISON"],
      moves: [
        PartySidebarMoveProps(id: "move-0", moveID: "TACKLE", displayName: "Tackle", typeLabel: "NORMAL", currentPP: 27, maxPP: 35, power: 40, accuracy: 100),
        PartySidebarMoveProps(id: "move-1", moveID: "VINE_WHIP", displayName: "Vine Whip", typeLabel: "GRASS", currentPP: 10, maxPP: 10, power: 45, accuracy: 100),
        PartySidebarMoveProps(id: "move-2", moveID: "POISONPOWDER", displayName: "Poisonpowder", typeLabel: "POISON", currentPP: 24, maxPP: 35, power: nil, accuracy: 75),
        PartySidebarMoveProps(id: "move-3", moveID: "SLEEP_POWDER", displayName: "Sleep Powder", typeLabel: "GRASS", currentPP: 11, maxPP: 15, power: nil, accuracy: 75),
      ]
    )

    let measuredHeight = measureFittingHeight(
      of: PartyPokemonHoverCard(props: props),
      width: PartyPokemonHoverCard.layoutWidth
    )

    XCTAssertLessThanOrEqual(measuredHeight, 500)
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

  func testFieldSidebarModeUsesPreferredExpandedSectionWhenProvided() {
    let mode = GameplaySidebarMode.fieldLike(
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
        pokedex: GameplaySidebarPropsBuilder.makePokedex(
          allSpecies: [],
          ownedSpeciesIDs: [],
          seenSpeciesIDs: []
        ),
        party: .init(pokemon: [], totalSlots: 6, mode: .passive, promptText: nil),
        inventory: GameplaySidebarPropsBuilder.makeInventory(),
        save: GameplaySidebarPropsBuilder.makeSaveSection(),
        options: GameplaySidebarPropsBuilder.makeOptionsSection(
          isMusicEnabled: true,
          appearanceMode: .light,
          gameBoyShellStyle: .classic,
          gameplayHDREnabled: true
        ),
        preferredExpandedSection: .pokedex
      )
    )

    XCTAssertEqual(mode.defaultExpandedSection, .pokedex)
  }
  func testSaveAndOptionsBuildersProduceDisabledRows() {
    let save = GameplaySidebarPropsBuilder.makeSaveSection()
    let options = GameplaySidebarPropsBuilder.makeOptionsSection(
      isMusicEnabled: true,
      appearanceMode: .light,
      gameBoyShellStyle: .classic,
      gameplayHDREnabled: true
    )

    XCTAssertEqual(save.actions.map(\.title), ["Save Game", "Load Save"])
    XCTAssertTrue(save.actions.allSatisfy { $0.isEnabled == false })
    XCTAssertEqual(
      options.rows.map(\.title), ["Appearance", "HDR Effects", "Text Speed", "Battle Scene", "Battle Style", "Music"])
    XCTAssertEqual(options.rows.map(\.isEnabled), [true, true, true, true, true, true])
    XCTAssertEqual(options.shellPickerTitle, "GB Shell")
    XCTAssertEqual(options.shellOptions.map(\.shellStyle), [.classic, .kiwi, .dandelion, .teal, .grape])
    XCTAssertEqual(options.shellOptions.filter(\.isSelected).map(\.shellStyle), [.classic])
    XCTAssertEqual(options.rows.last?.detail, "On")
    XCTAssertEqual(options.rows.first?.detail, "Light")
    XCTAssertEqual(options.rows.dropFirst().first?.detail, "On")
  }
  func testThemePaletteResolvesDistinctLightAndDarkValues() {
    let light = PokeThemePalette.resolve(for: .light)
    let dark = PokeThemePalette.resolve(for: .retroDark)

    XCTAssertNotEqual(light.primaryText, dark.primaryText)
    XCTAssertNotEqual(light.field.ink, dark.field.ink)
    XCTAssertGreaterThan(light.screenGlow.alpha, 0)
    XCTAssertGreaterThan(dark.screenGlow.alpha, 0)
  }
  func testShellAwareThemePaletteLeavesClassicOnBaseAppearancePalette() {
    let lightClassic = PokeThemePalette.resolve(
      for: .light,
      shellStyle: .classic,
      colorScheme: .light
    )
    let darkClassic = PokeThemePalette.resolve(
      for: .retroDark,
      shellStyle: .classic,
      colorScheme: .dark
    )

    XCTAssertEqual(lightClassic, PokeThemePalette.resolve(for: .light))
    XCTAssertEqual(darkClassic, PokeThemePalette.resolve(for: .retroDark))
  }
  func testShellAwareThemePaletteTintsChromeForNonClassicShells() {
    let classicLight = PokeThemePalette.resolve(
      for: .light,
      shellStyle: .classic,
      colorScheme: .light
    )
    let classicDark = PokeThemePalette.resolve(
      for: .retroDark,
      shellStyle: .classic,
      colorScheme: .dark
    )

    for shellStyle in [GameBoyShellStyle.kiwi, .dandelion, .teal, .grape] {
      let lightPalette = PokeThemePalette.resolve(
        for: .light,
        shellStyle: shellStyle,
        colorScheme: .light
      )
      let darkPalette = PokeThemePalette.resolve(
        for: .retroDark,
        shellStyle: shellStyle,
        colorScheme: .dark
      )

      XCTAssertNotEqual(lightPalette.panelBackground, classicLight.panelBackground)
      XCTAssertNotEqual(lightPalette.menuFocusFill, classicLight.menuFocusFill)
      XCTAssertNotEqual(lightPalette.field.hoverCardGlassTint, classicLight.field.hoverCardGlassTint)
      XCTAssertNotEqual(darkPalette.panelBackground, classicDark.panelBackground)
      XCTAssertNotEqual(darkPalette.appBackgroundMiddle, classicDark.appBackgroundMiddle)
      XCTAssertNotEqual(lightPalette.menuFocusFill, darkPalette.menuFocusFill)
      XCTAssertNotEqual(lightPalette.dialoguePaper, darkPalette.dialoguePaper)
    }
  }
  func testGameplayScreenGlowPaletteTracksDisplayStyle() {
    let tinted = PokeThemePalette.gameplayScreenGlowPalette(
      displayStyle: .dmgTinted,
      appearanceMode: .retroDark,
      colorScheme: .dark
    )
    let raw = PokeThemePalette.gameplayScreenGlowPalette(
      displayStyle: .rawGrayscale,
      appearanceMode: .retroDark,
      colorScheme: .dark
    )
    let authentic = PokeThemePalette.gameplayScreenGlowPalette(
      displayStyle: .dmgAuthentic,
      appearanceMode: .retroDark,
      colorScheme: .dark
    )
    let dark = PokeThemePalette.resolve(for: .retroDark)

    XCTAssertEqual(tinted.outer, dark.screenGlow)
    XCTAssertEqual(tinted.inner, dark.screenGlowInner)
    XCTAssertEqual(raw.outer.red, raw.outer.green)
    XCTAssertEqual(raw.outer.green, raw.outer.blue)
    XCTAssertEqual(raw.inner.red, raw.inner.green)
    XCTAssertEqual(raw.inner.green, raw.inner.blue)
    XCTAssertNotEqual(raw.outer, tinted.outer)
    XCTAssertNotEqual(authentic.outer, tinted.outer)
  }
  func testGameplayScreenGlowPaletteUsesRestoredTintedValues() {
    let tinted = PokeThemePalette.gameplayScreenGlowPalette(
      displayStyle: .dmgTinted,
      appearanceMode: .retroDark,
      colorScheme: .dark
    )
    let authentic = PokeThemePalette.gameplayScreenGlowPalette(
      displayStyle: .dmgAuthentic,
      appearanceMode: .retroDark,
      colorScheme: .dark
    )

    XCTAssertEqual(tinted.outer.red, 0.22, accuracy: 0.0001)
    XCTAssertEqual(tinted.outer.green, 0.96, accuracy: 0.0001)
    XCTAssertEqual(tinted.outer.blue, 0.24, accuracy: 0.0001)
    XCTAssertEqual(tinted.inner.red, 0.74, accuracy: 0.0001)
    XCTAssertEqual(tinted.inner.green, 1.0, accuracy: 0.0001)
    XCTAssertEqual(tinted.inner.blue, 0.72, accuracy: 0.0001)

    XCTAssertEqual(authentic.outer.red, 0.42, accuracy: 0.0001)
    XCTAssertEqual(authentic.outer.green, 0.55, accuracy: 0.0001)
    XCTAssertEqual(authentic.outer.blue, 0.18, accuracy: 0.0001)
    XCTAssertEqual(authentic.inner.red, 0.75, accuracy: 0.0001)
    XCTAssertEqual(authentic.inner.green, 0.79, accuracy: 0.0001)
    XCTAssertEqual(authentic.inner.blue, 0.41, accuracy: 0.0001)
  }
  func testGameplayHDRProfileUsesModeratedScreenBoosts() {
    let light = PokeThemePalette.gameplayHDRProfile(
      appearanceMode: .light,
      colorScheme: .light,
      isEnabled: true
    )
    let dark = PokeThemePalette.gameplayHDRProfile(
      appearanceMode: .retroDark,
      colorScheme: .dark,
      isEnabled: true
    )

    XCTAssertEqual(light.fieldShaderBoost, 0.14, accuracy: 0.0001)
    XCTAssertEqual(light.battleShaderBoost, 0.1, accuracy: 0.0001)
    XCTAssertEqual(dark.fieldShaderBoost, 0.28, accuracy: 0.0001)
    XCTAssertEqual(dark.battleShaderBoost, 0.22, accuracy: 0.0001)
    XCTAssertEqual(dark.outerGlowOpacity, 0.5, accuracy: 0.0001)
    XCTAssertEqual(dark.innerGlowOpacity, 0.34, accuracy: 0.0001)
  }
  func testBattleCardPaletteUsesHigherContrastGlassValues() {
    let light = PokeThemePalette.resolve(for: .light)
    let dark = PokeThemePalette.resolve(for: .retroDark)

    XCTAssertEqual(light.battleEnemyTint.alpha, 0.54, accuracy: 0.0001)
    XCTAssertEqual(light.battleEnemyBackground.alpha, 0.26, accuracy: 0.0001)
    XCTAssertEqual(light.battlePlayerTint.alpha, 0.62, accuracy: 0.0001)
    XCTAssertEqual(light.battlePlayerBackground.alpha, 0.3, accuracy: 0.0001)

    XCTAssertEqual(dark.battleEnemyTint.green, 0.28, accuracy: 0.0001)
    XCTAssertEqual(dark.battleEnemyBackground.alpha, 0.42, accuracy: 0.0001)
    XCTAssertEqual(dark.battlePlayerTint.green, 0.38, accuracy: 0.0001)
    XCTAssertEqual(dark.battlePlayerBackground.alpha, 0.48, accuracy: 0.0001)
  }
  func testOptionsBuilderReflectsAppearanceWithoutChangingMusicState() {
    let systemOptions = GameplaySidebarPropsBuilder.makeOptionsSection(
      isMusicEnabled: true,
      appearanceMode: .system,
      gameBoyShellStyle: .classic,
      gameplayHDREnabled: false
    )
    let lightOptions = GameplaySidebarPropsBuilder.makeOptionsSection(
      isMusicEnabled: true,
      appearanceMode: .light,
      gameBoyShellStyle: .kiwi,
      gameplayHDREnabled: true
    )
    let darkOptions = GameplaySidebarPropsBuilder.makeOptionsSection(
      isMusicEnabled: true,
      appearanceMode: .retroDark,
      gameBoyShellStyle: .dandelion,
      gameplayHDREnabled: true
    )

    XCTAssertEqual(systemOptions.rows.first?.detail, "System")
    XCTAssertEqual(lightOptions.rows.first?.detail, "Light")
    XCTAssertEqual(darkOptions.rows.first?.detail, "Dark")
    XCTAssertEqual(systemOptions.rows[1].detail, "Off")
    XCTAssertEqual(lightOptions.rows[1].detail, "On")
    XCTAssertEqual(darkOptions.rows[1].detail, "On")
    XCTAssertEqual(systemOptions.rows.last?.detail, "On")
    XCTAssertEqual(lightOptions.rows.last?.detail, "On")
    XCTAssertEqual(darkOptions.rows.last?.detail, "On")
    XCTAssertEqual(systemOptions.shellOptions.filter(\.isSelected).map(\.shellStyle), [.classic])
    XCTAssertEqual(lightOptions.shellOptions.filter(\.isSelected).map(\.shellStyle), [.kiwi])
    XCTAssertEqual(darkOptions.shellOptions.filter(\.isSelected).map(\.shellStyle), [.dandelion])
  }
  func testClassicGameBoyShellPaletteTracksAppearanceMode() {
    let lightClassic = PokeThemePalette.gameBoyShellPalette(
      shellStyle: .classic,
      appearanceMode: .light,
      colorScheme: .light
    )
    let darkClassic = PokeThemePalette.gameBoyShellPalette(
      shellStyle: .classic,
      appearanceMode: .retroDark,
      colorScheme: .dark
    )

    XCTAssertEqual(lightClassic.backdrop, PokeThemePalette.resolve(for: .light).field.shellBackdrop)
    XCTAssertEqual(lightClassic.shadow, PokeThemePalette.resolve(for: .light).field.shellBackdropShadow)
    XCTAssertEqual(darkClassic.backdrop, PokeThemePalette.resolve(for: .retroDark).field.shellBackdrop)
    XCTAssertEqual(darkClassic.shadow, PokeThemePalette.resolve(for: .retroDark).field.shellBackdropShadow)
  }
  func testClassicGameBoyShellChromeTracksAppearanceMode() {
    let lightClassic = PokeThemePalette.gameBoyShellChromePalette(
      shellStyle: .classic,
      appearanceMode: .light,
      colorScheme: .light
    )
    let darkClassic = PokeThemePalette.gameBoyShellChromePalette(
      shellStyle: .classic,
      appearanceMode: .retroDark,
      colorScheme: .dark
    )

    XCTAssertEqual(lightClassic.wordmark, PokeThemePalette.resolve(for: .light).gameBoyWordmark)
    XCTAssertEqual(darkClassic.wordmark, PokeThemePalette.resolve(for: .retroDark).gameBoyWordmark)
  }
  func testExplicitGameBoyShellPalettesStayStableAcrossAppearanceModes() {
    for shellStyle in [GameBoyShellStyle.kiwi, .dandelion, .teal, .grape] {
      let lightPalette = PokeThemePalette.gameBoyShellPalette(
        shellStyle: shellStyle,
        appearanceMode: .light,
        colorScheme: .light
      )
      let darkPalette = PokeThemePalette.gameBoyShellPalette(
        shellStyle: shellStyle,
        appearanceMode: .retroDark,
        colorScheme: .dark
      )

      XCTAssertEqual(lightPalette, darkPalette)
      XCTAssertNotEqual(lightPalette.backdrop, PokeThemePalette.resolve(for: .light).field.shellBackdrop)
    }
  }
  func testExplicitGameBoyShellWordmarksStayStableAcrossAppearanceModes() {
    for shellStyle in [GameBoyShellStyle.kiwi, .dandelion, .teal, .grape] {
      let lightChrome = PokeThemePalette.gameBoyShellChromePalette(
        shellStyle: shellStyle,
        appearanceMode: .light,
        colorScheme: .light
      )
      let darkChrome = PokeThemePalette.gameBoyShellChromePalette(
        shellStyle: shellStyle,
        appearanceMode: .retroDark,
        colorScheme: .dark
      )

      XCTAssertEqual(lightChrome.wordmark, darkChrome.wordmark)
      XCTAssertNotEqual(lightChrome.wordmark, PokeThemePalette.resolve(for: .light).gameBoyWordmark)
    }
  }
  func testOptionsSidebarContentWithShellPickerFitsSidebarWidth() {
    let props = GameplaySidebarPropsBuilder.makeOptionsSection(
      isMusicEnabled: true,
      appearanceMode: .light,
      gameBoyShellStyle: .kiwi,
      gameplayHDREnabled: true
    )
    let view = OptionsSidebarContent(
      props: props,
      fieldDisplayStyle: .constant(.defaultGameplayStyle),
      onAction: nil
    )

    let measuredHeight = measureFittingHeight(of: view, width: 320)
    XCTAssertGreaterThan(measuredHeight, 140)
    XCTAssertLessThanOrEqual(measuredHeight, GameplayFieldMetrics.optionsExpandedMaxHeight)
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
