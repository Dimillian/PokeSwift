import XCTest
import ImageIO
import UniformTypeIdentifiers
import SwiftUI
@testable import PokeUI
import PokeDataModel
import PokeCore

@MainActor
final class PokeUITests: XCTestCase {
    func testTitleMenuPanelCanBeConstructed() {
        let view = TitleMenuPanel(entries: [.init(id: "newGame", label: "New Game", isEnabled: true)], focusedIndex: 0)
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
                        ),
                    ]
                ),
                inventory: GameplaySidebarPropsBuilder.makeInventory(),
                save: GameplaySidebarPropsBuilder.makeSaveSection(),
                options: GameplaySidebarPropsBuilder.makeOptionsSection()
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
                    .init(moveID: "TACKLE", displayName: "Tackle", currentPP: 35, maxPP: 35, isSelectable: true),
                    .init(moveID: "GROWL", displayName: "Growl", currentPP: 40, maxPP: 40, isSelectable: true),
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
                        ),
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
            }
        }

        XCTAssertNotNil(view)
    }

    func testFieldDisplayStyleLabelsRemainStableForSidebarSwitcher() {
        XCTAssertEqual(FieldDisplayStyle.defaultGameplayStyle, .dmgTinted)
        XCTAssertEqual(FieldDisplayStyle.dmgAuthentic.sidebarSummaryLabel, "DMG")
        XCTAssertEqual(FieldDisplayStyle.dmgTinted.sidebarSummaryLabel, "TINTED")
        XCTAssertEqual(FieldDisplayStyle.rawGrayscale.sidebarSummaryLabel, "RAW")
        XCTAssertEqual(FieldDisplayStyle.dmgAuthentic.sidebarOptionTitle, "Authentic DMG")
        XCTAssertEqual(FieldDisplayStyle.dmgTinted.sidebarOptionTitle, "Tinted")
        XCTAssertEqual(FieldDisplayStyle.rawGrayscale.sidebarOptionTitle, "Raw Gray")
    }

    func testFieldSceneRenderTaskIdentityIgnoresDisplayStyle() {
        let map = makePaletteMap(blockWidth: 2, blockHeight: 2)
        let root = repoRoot()
        let assets = FieldRenderAssets(
            tileset: .init(
                id: "OVERWORLD",
                imageURL: root.appendingPathComponent("gfx/tilesets/overworld.png"),
                blocksetURL: root.appendingPathComponent("gfx/blocksets/overworld.bst")
            ),
            overworldSprites: [
                "SPRITE_RED": spriteDefinition(id: "SPRITE_RED", filename: "red.png"),
                "SPRITE_OAK": spriteDefinition(id: "SPRITE_OAK", filename: "oak.png"),
            ]
        )
        let objects = [
            FieldObjectRenderState(
                id: "oak",
                displayName: "Oak",
                sprite: "SPRITE_OAK",
                position: .init(x: 1, y: 1),
                facing: .left,
                interactionDialogueID: nil,
                trainerBattleID: nil
            ),
        ]

        let tintedIdentity = FieldMapView.sceneRenderTaskIdentity(
            map: map,
            playerFacing: .down,
            playerSpriteID: "SPRITE_RED",
            objects: objects,
            renderAssets: assets,
            displayStyle: .dmgTinted
        )
        let authenticIdentity = FieldMapView.sceneRenderTaskIdentity(
            map: map,
            playerFacing: .down,
            playerSpriteID: "SPRITE_RED",
            objects: objects,
            renderAssets: assets,
            displayStyle: .dmgAuthentic
        )

        XCTAssertEqual(tintedIdentity, authenticIdentity)
    }

    func testFieldSceneMetricsUseFixedGameplayViewportPadding() {
        let metrics = FieldSceneRenderer.sceneMetrics(for: makePaletteMap(blockWidth: 2, blockHeight: 2))

        XCTAssertEqual(FieldSceneRenderer.viewportPixelSize, .init(width: 160, height: 144))
        XCTAssertEqual(metrics.mapPixelSize, .init(width: 64, height: 64))
        XCTAssertEqual(metrics.paddingPixels, .init(width: 160, height: 160))
        XCTAssertEqual(metrics.contentPixelSize, .init(width: 384, height: 384))
    }

    func testFieldCameraTargetsCenteredPlayerInFixedViewport() {
        let map = makePaletteMap(blockWidth: 10, blockHeight: 9)
        let metrics = FieldSceneRenderer.sceneMetrics(for: map)
        let playerWorld = FieldSceneRenderer.playerWorldPosition(for: .init(x: 8, y: 7), metrics: metrics)

        let camera = FieldCameraState.target(
            playerWorldPosition: playerWorld,
            contentPixelSize: metrics.contentPixelSize
        )

        XCTAssertEqual(camera.origin, .init(x: 216, y: 208))
        XCTAssertEqual(camera.viewportSize, FieldSceneRenderer.viewportPixelSize)
    }

    func testFieldCameraKeepsSmallMapsInsideBorderPaddedScene() {
        let map = makePaletteMap(blockWidth: 1, blockHeight: 1)
        let metrics = FieldSceneRenderer.sceneMetrics(for: map)
        let playerWorld = FieldSceneRenderer.playerWorldPosition(for: .init(x: 0, y: 0), metrics: metrics)

        let camera = FieldCameraState.target(
            playerWorldPosition: playerWorld,
            contentPixelSize: metrics.contentPixelSize
        )

        XCTAssertGreaterThan(camera.origin.x, 0)
        XCTAssertGreaterThan(camera.origin.y, 0)
        XCTAssertLessThanOrEqual(camera.origin.x + camera.viewportSize.width, metrics.contentPixelSize.width)
        XCTAssertLessThanOrEqual(camera.origin.y + camera.viewportSize.height, metrics.contentPixelSize.height)
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
                .init(moveID: "TACKLE", displayName: "Tackle", currentPP: 35, maxPP: 35, isSelectable: true),
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
                    .init(moveID: "TACKLE", displayName: "Tackle", currentPP: 35, maxPP: 35, isSelectable: true),
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
                    .init(moveID: "TACKLE", displayName: "Tackle", currentPP: 35, maxPP: 35, isSelectable: true),
                    .init(moveID: "GROWL", displayName: "Growl", currentPP: 40, maxPP: 40, isSelectable: true),
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
                .init(moveID: "TACKLE", displayName: "Tackle", currentPP: 35, maxPP: 35, isSelectable: true),
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
                .init(moveID: "TACKLE", displayName: "Tackle", currentPP: 35, maxPP: 35, isSelectable: true),
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
                ),
            ]
        )
        let speciesDetailsByID = [
            "BULBASAUR": PartySidebarSpeciesDetails(
                spriteURL: URL(fileURLWithPath: "/tmp/bulbasaur.png"),
                primaryType: "GRASS",
                secondaryType: "POISON"
            ),
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
        let options = GameplaySidebarPropsBuilder.makeOptionsSection()

        XCTAssertEqual(save.actions.map(\.title), ["Save Game", "Load Save"])
        XCTAssertTrue(save.actions.allSatisfy { $0.isEnabled == false })
        XCTAssertEqual(options.rows.map(\.title), ["Text Speed", "Battle Scene", "Battle Style", "Sound"])
        XCTAssertTrue(options.rows.allSatisfy { $0.isEnabled == false })
    }

    func testBlocksetDecoderBuilds4x4BlocksFromRepoData() throws {
        let blocksetURL = repoRoot().appendingPathComponent("gfx/blocksets/overworld.bst")
        let data = try Data(contentsOf: blocksetURL)
        let blockset = try FieldBlockset.decode(data: data)

        XCTAssertEqual(blockset.blockTileWidth, 4)
        XCTAssertEqual(blockset.blockTileHeight, 4)
        XCTAssertEqual(blockset.blocks.count, 128)
        XCTAssertEqual(blockset.blocks.first?.count, 16)
    }

    func testTileAtlasUsesTopLeftOriginForRepoPNGExports() throws {
        let image = try loadImage(repoRoot().appendingPathComponent("gfx/tilesets/overworld.png"))
        let tileZero = try cropTopLeftTile(from: image, tileSize: 8, index: 0)
        XCTAssertGreaterThan(averageGrayscale(for: tileZero), 240)
    }

    func testTileAtlasPreparesTilesForFlippedFieldContext() throws {
        let sourceTile = try makeTestTileImage(topHalf: 0, bottomHalf: 255)
        let atlas = FieldSceneRenderer.TileAtlas(image: sourceTile, tileSize: 8)

        let preparedTile = try atlas.tile(at: 0)

        XCTAssertGreaterThan(averageGrayscale(forTopRowsOf: preparedTile, rowCount: 4), 240)
        XCTAssertLessThan(averageGrayscale(forBottomRowsOf: preparedTile, rowCount: 4), 15)
    }

    func testSpriteFrameLookupUsesExplicitFacingFrames() {
        let definition = FieldSpriteDefinition(
            id: "SPRITE_RED",
            imageURL: URL(fileURLWithPath: "/tmp/red.png"),
            facingFrames: [
                .down: .init(x: 0, y: 0, width: 16, height: 16),
                .up: .init(x: 0, y: 16, width: 16, height: 16),
                .left: .init(x: 0, y: 32, width: 16, height: 16),
                .right: .init(x: 0, y: 32, width: 16, height: 16, flippedHorizontally: true),
            ]
        )

        XCTAssertEqual(definition.frame(for: .down), .init(x: 0, y: 0, width: 16, height: 16))
        XCTAssertEqual(definition.frame(for: .right), .init(x: 0, y: 32, width: 16, height: 16, flippedHorizontally: true))
    }

    func testSpriteFrameLookupUsesWalkingFramesWhenRequested() {
        let definition = spriteDefinition(id: "SPRITE_RED", filename: "red.png")

        XCTAssertEqual(definition.frame(for: .down, isWalking: true), .init(x: 0, y: 48, width: 16, height: 16))
        XCTAssertEqual(definition.frame(for: .up, isWalking: true), .init(x: 0, y: 64, width: 16, height: 16))
        XCTAssertEqual(definition.frame(for: .right, isWalking: true), .init(x: 0, y: 80, width: 16, height: 16, flippedHorizontally: true))
    }

    func testPlayerWalkFrameUsesSourceFourPhaseCadence() {
        let stepDuration = 16.0 / 60.0

        XCTAssertEqual(FieldMapView.playerWalkAnimationPhase(elapsed: 0, stepDuration: stepDuration), 0)
        XCTAssertEqual(FieldMapView.playerWalkAnimationPhase(elapsed: stepDuration * 0.30, stepDuration: stepDuration), 1)
        XCTAssertEqual(FieldMapView.playerWalkAnimationPhase(elapsed: stepDuration * 0.55, stepDuration: stepDuration), 2)
        XCTAssertEqual(FieldMapView.playerWalkAnimationPhase(elapsed: stepDuration * 0.80, stepDuration: stepDuration), 3)
        XCTAssertNil(FieldMapView.playerWalkAnimationPhase(elapsed: stepDuration, stepDuration: stepDuration))

        XCTAssertFalse(FieldMapView.playerUsesWalkingFrame(phase: 0))
        XCTAssertTrue(FieldMapView.playerUsesWalkingFrame(phase: 1))
        XCTAssertFalse(FieldMapView.playerUsesWalkingFrame(phase: 2))
        XCTAssertTrue(FieldMapView.playerUsesWalkingFrame(phase: 3))
    }

    func testChainedWalkPhaseOffsetStartsHeldStrideOnVisibleWalkFrame() {
        let stepDuration = 16.0 / 60.0
        let now = Date()
        let previousStartedAt = now.addingTimeInterval(-stepDuration)

        let phaseOffset = FieldMapView.chainedWalkPhaseOffset(
            previousDirection: .right,
            nextDirection: .right,
            previousStartedAt: previousStartedAt,
            now: now,
            stepDuration: stepDuration
        )

        XCTAssertEqual(phaseOffset, 1)
        XCTAssertEqual(
            FieldMapView.playerWalkAnimationPhase(
                elapsed: 0,
                stepDuration: stepDuration,
                phaseOffset: phaseOffset
            ),
            1
        )
        XCTAssertTrue(FieldMapView.playerUsesWalkingFrame(phase: 1))
    }

    func testChainedWalkPhaseOffsetDoesNotCarryAcrossTurnsOrDelayedSteps() {
        let stepDuration = 16.0 / 60.0
        let now = Date()

        XCTAssertEqual(
            FieldMapView.chainedWalkPhaseOffset(
                previousDirection: .right,
                nextDirection: .up,
                previousStartedAt: now.addingTimeInterval(-stepDuration),
                now: now,
                stepDuration: stepDuration
            ),
            0
        )

        XCTAssertEqual(
            FieldMapView.chainedWalkPhaseOffset(
                previousDirection: .right,
                nextDirection: .right,
                previousStartedAt: now.addingTimeInterval(-(stepDuration * 2)),
                now: now,
                stepDuration: stepDuration
            ),
            0
        )
    }

    func testPlayerStepAnimationIsRetainedDuringNpcOnlyUpdatesWhileStepIsActive() {
        let stepDuration = 16.0 / 60.0
        let now = Date()

        XCTAssertTrue(
            FieldMapView.shouldRetainPlayerStepAnimation(
                currentDestinationPosition: .init(x: 10, y: 7),
                startedAt: now.addingTimeInterval(-(stepDuration * 0.5)),
                nextPlayerPosition: .init(x: 10, y: 7),
                now: now,
                stepDuration: stepDuration
            )
        )
    }

    func testPlayerStepAnimationIsNotRetainedAfterStepFinishesOrPlayerChangesTile() {
        let stepDuration = 16.0 / 60.0
        let now = Date()

        XCTAssertFalse(
            FieldMapView.shouldRetainPlayerStepAnimation(
                currentDestinationPosition: .init(x: 10, y: 7),
                startedAt: now.addingTimeInterval(-(stepDuration * 1.1)),
                nextPlayerPosition: .init(x: 10, y: 7),
                now: now,
                stepDuration: stepDuration
            )
        )

        XCTAssertFalse(
            FieldMapView.shouldRetainPlayerStepAnimation(
                currentDestinationPosition: .init(x: 10, y: 7),
                startedAt: now.addingTimeInterval(-(stepDuration * 0.5)),
                nextPlayerPosition: .init(x: 11, y: 7),
                now: now,
                stepDuration: stepDuration
            )
        )
    }

    func testPlayerWalkFrameMirrorsSecondStepForVerticalMovement() {
        XCTAssertFalse(FieldMapView.playerUsesMirroredWalkingFrame(facing: .left, phase: 3))
        XCTAssertFalse(FieldMapView.playerUsesMirroredWalkingFrame(facing: .right, phase: 3))
        XCTAssertFalse(FieldMapView.playerUsesMirroredWalkingFrame(facing: .down, phase: 1))
        XCTAssertTrue(FieldMapView.playerUsesMirroredWalkingFrame(facing: .down, phase: 3))
        XCTAssertTrue(FieldMapView.playerUsesMirroredWalkingFrame(facing: .up, phase: 3))
    }

    func testConnectedStepDirectionResolvesNorthBoundaryCrossing() {
        let route1 = MapManifest(
            id: "ROUTE_1",
            displayName: "Route 1",
            defaultMusicID: "MUSIC_ROUTES1",
            borderBlockID: 0,
            blockWidth: 5,
            blockHeight: 4,
            stepWidth: 10,
            stepHeight: 8,
            tileset: "TEST",
            blockIDs: Array(repeating: 0, count: 20),
            stepCollisionTileIDs: Array(repeating: 0x00, count: 80),
            warps: [],
            backgroundEvents: [],
            objects: []
        )
        let palletTown = MapManifest(
            id: "PALLET_TOWN",
            displayName: "Pallet Town",
            defaultMusicID: "MUSIC_PALLET_TOWN",
            borderBlockID: 0,
            blockWidth: 5,
            blockHeight: 4,
            stepWidth: 10,
            stepHeight: 8,
            tileset: "TEST",
            blockIDs: Array(repeating: 0, count: 20),
            stepCollisionTileIDs: Array(repeating: 0x00, count: 80),
            warps: [],
            backgroundEvents: [],
            objects: [],
            connections: [
                .init(
                    direction: .north,
                    targetMapID: "ROUTE_1",
                    offset: 1,
                    targetBlockWidth: route1.blockWidth,
                    targetBlockHeight: route1.blockHeight,
                    targetBlockIDs: route1.blockIDs
                ),
            ]
        )

        XCTAssertEqual(
            FieldMapView.connectedStepDirection(
                from: palletTown,
                previousPosition: .init(x: 6, y: 0),
                to: route1,
                nextPosition: .init(x: 4, y: 7)
            ),
            .up
        )
    }

    func testConnectedStepDirectionRejectsNonMatchingBoundarySwap() {
        let route1 = makePaletteMap(blockWidth: 5, blockHeight: 4)
        let palletTown = MapManifest(
            id: "PALLET_TOWN",
            displayName: "Pallet Town",
            defaultMusicID: "MUSIC_PALLET_TOWN",
            borderBlockID: 0,
            blockWidth: 5,
            blockHeight: 4,
            stepWidth: 10,
            stepHeight: 8,
            tileset: "TEST",
            blockIDs: Array(repeating: 0, count: 20),
            stepCollisionTileIDs: Array(repeating: 0x00, count: 80),
            warps: [],
            backgroundEvents: [],
            objects: [],
            connections: [
                .init(
                    direction: .north,
                    targetMapID: route1.id,
                    offset: 0,
                    targetBlockWidth: route1.blockWidth,
                    targetBlockHeight: route1.blockHeight,
                    targetBlockIDs: route1.blockIDs
                ),
            ]
        )

        XCTAssertNil(
            FieldMapView.connectedStepDirection(
                from: palletTown,
                previousPosition: .init(x: 4, y: 1),
                to: route1,
                nextPosition: .init(x: 4, y: route1.stepHeight - 1)
            )
        )
    }

    func testConnectedStepOriginPositionPlacesStartOneTileBehindDestination() {
        XCTAssertEqual(
            FieldMapView.connectedStepOriginPosition(nextPosition: .init(x: 4, y: 7), direction: .up),
            .init(x: 4, y: 8)
        )
        XCTAssertEqual(
            FieldMapView.connectedStepOriginPosition(nextPosition: .init(x: 4, y: 0), direction: .down),
            .init(x: 4, y: -1)
        )
        XCTAssertEqual(
            FieldMapView.connectedStepOriginPosition(nextPosition: .init(x: 9, y: 3), direction: .left),
            .init(x: 10, y: 3)
        )
        XCTAssertEqual(
            FieldMapView.connectedStepOriginPosition(nextPosition: .init(x: 0, y: 3), direction: .right),
            .init(x: -1, y: 3)
        )
    }

    func testRendererCanCompositeRealFieldAssets() throws {
        let root = repoRoot()
        let assets = FieldRenderAssets(
            tileset: .init(
                id: "OVERWORLD",
                imageURL: root.appendingPathComponent("gfx/tilesets/overworld.png"),
                blocksetURL: root.appendingPathComponent("gfx/blocksets/overworld.bst")
            ),
            overworldSprites: [
                "SPRITE_RED": spriteDefinition(id: "SPRITE_RED", filename: "red.png"),
                "SPRITE_OAK": spriteDefinition(id: "SPRITE_OAK", filename: "oak.png"),
            ]
        )
        let map = MapManifest(
            id: "PALLET_TOWN",
            displayName: "Pallet Town",
            defaultMusicID: "MUSIC_PALLET_TOWN",
            borderBlockID: 0x0B,
            blockWidth: 2,
            blockHeight: 2,
            stepWidth: 4,
            stepHeight: 4,
            tileset: "OVERWORLD",
            blockIDs: [0, 1, 2, 3],
            stepCollisionTileIDs: Array(repeating: 0x00, count: 16),
            warps: [],
            backgroundEvents: [],
            objects: []
        )
        let objects = [
            FieldObjectRenderState(
                id: "oak",
                displayName: "Oak",
                sprite: "SPRITE_OAK",
                position: .init(x: 1, y: 1),
                facing: .left,
                interactionDialogueID: nil,
                trainerBattleID: nil
            ),
        ]

        let image = try FieldSceneRenderer.render(
            map: map,
            playerPosition: .init(x: 0, y: 0),
            playerFacing: .down,
            playerSpriteID: "SPRITE_RED",
            objects: objects,
            assets: assets
        )

        XCTAssertEqual(image.width, 64)
        XCTAssertEqual(image.height, 64)
    }

    func testRendererCanCompositeRealFieldAssetsAsRawGrayscale() throws {
        let root = repoRoot()
        let assets = FieldRenderAssets(
            tileset: .init(
                id: "OVERWORLD",
                imageURL: root.appendingPathComponent("gfx/tilesets/overworld.png"),
                blocksetURL: root.appendingPathComponent("gfx/blocksets/overworld.bst")
            ),
            overworldSprites: [
                "SPRITE_RED": spriteDefinition(id: "SPRITE_RED", filename: "red.png"),
                "SPRITE_OAK": spriteDefinition(id: "SPRITE_OAK", filename: "oak.png"),
            ]
        )
        let map = MapManifest(
            id: "PALLET_TOWN",
            displayName: "Pallet Town",
            defaultMusicID: "MUSIC_PALLET_TOWN",
            borderBlockID: 0x0B,
            blockWidth: 2,
            blockHeight: 2,
            stepWidth: 4,
            stepHeight: 4,
            tileset: "OVERWORLD",
            blockIDs: [0, 1, 2, 3],
            stepCollisionTileIDs: Array(repeating: 0x00, count: 16),
            warps: [],
            backgroundEvents: [],
            objects: []
        )
        let objects = [
            FieldObjectRenderState(
                id: "oak",
                displayName: "Oak",
                sprite: "SPRITE_OAK",
                position: .init(x: 1, y: 1),
                facing: .left,
                interactionDialogueID: nil,
                trainerBattleID: nil
            ),
        ]

        let image = try FieldSceneRenderer.render(
            map: map,
            playerPosition: .init(x: 0, y: 0),
            playerFacing: .down,
            playerSpriteID: "SPRITE_RED",
            objects: objects,
            assets: assets
        )

        XCTAssertEqual(image.width, 64)
        XCTAssertEqual(image.height, 64)
        XCTAssertFalse(grayscaleValues(in: image).isEmpty)
    }

    func testRenderSceneBuildsBorderPaddedBackgroundAndLayeredActors() throws {
        let fixtureRoot = try makeSyntheticFieldFixture(tileValue: 85, spriteBodyValue: 170)
        defer { try? FileManager.default.removeItem(at: fixtureRoot) }

        let assets = FieldRenderAssets(
            tileset: .init(
                id: "TEST",
                imageURL: fixtureRoot.appendingPathComponent("tileset.png"),
                blocksetURL: fixtureRoot.appendingPathComponent("test.bst")
            ),
            overworldSprites: [
                "SPRITE_RED": FieldSpriteDefinition(
                    id: "SPRITE_RED",
                    imageURL: fixtureRoot.appendingPathComponent("sprite.png"),
                    facingFrames: [
                        .down: .init(x: 0, y: 0, width: 16, height: 16),
                        .up: .init(x: 0, y: 0, width: 16, height: 16),
                        .left: .init(x: 0, y: 0, width: 16, height: 16),
                        .right: .init(x: 0, y: 0, width: 16, height: 16),
                    ]
                ),
            ]
        )
        let map = MapManifest(
            id: "TEST_MAP",
            displayName: "Test Map",
            defaultMusicID: "MUSIC_PALLET_TOWN",
            borderBlockID: 0,
            blockWidth: 1,
            blockHeight: 1,
            stepWidth: 2,
            stepHeight: 2,
            tileset: "TEST",
            blockIDs: [0],
            stepCollisionTileIDs: Array(repeating: 0x00, count: 4),
            warps: [],
            backgroundEvents: [],
            objects: []
        )

        let scene = try FieldSceneRenderer.renderScene(
            map: map,
            playerPosition: .init(x: 0, y: 0),
            playerFacing: .down,
            playerSpriteID: "SPRITE_RED",
            objects: [],
            assets: assets
        )

        XCTAssertEqual(scene.backgroundImage.width, scene.metrics.contentPixelSize.width)
        XCTAssertEqual(scene.backgroundImage.height, scene.metrics.contentPixelSize.height)
        XCTAssertEqual(scene.actors.count, 1)
        XCTAssertEqual(scene.actors.first?.worldPosition, FieldSceneRenderer.playerWorldPosition(for: .init(x: 0, y: 0), metrics: scene.metrics))
        XCTAssertEqual(grayscaleValues(in: scene.backgroundImage), Set([85]))
    }

    func testRenderSceneOverlaysConnectedMapStripsInsideBorderPadding() throws {
        let fixtureRoot = try makeSyntheticPaletteFixture(tileValues: [10, 80, 160])
        defer { try? FileManager.default.removeItem(at: fixtureRoot) }

        let assets = FieldRenderAssets(
            tileset: .init(
                id: "TEST",
                imageURL: fixtureRoot.appendingPathComponent("tileset.png"),
                blocksetURL: fixtureRoot.appendingPathComponent("test.bst")
            ),
            overworldSprites: [:]
        )
        let map = MapManifest(
            id: "TEST_MAP",
            displayName: "Test Map",
            defaultMusicID: "MUSIC_PALLET_TOWN",
            borderBlockID: 0,
            blockWidth: 1,
            blockHeight: 1,
            stepWidth: 2,
            stepHeight: 2,
            tileset: "TEST",
            blockIDs: [1],
            stepCollisionTileIDs: Array(repeating: 0x00, count: 4),
            warps: [],
            backgroundEvents: [],
            objects: [],
            connections: [
                .init(
                    direction: .north,
                    targetMapID: "TEST_ROUTE",
                    offset: 0,
                    targetBlockWidth: 1,
                    targetBlockHeight: 3,
                    targetBlockIDs: [2, 2, 2]
                ),
            ]
        )

        let scene = try FieldSceneRenderer.renderScene(
            map: map,
            playerPosition: .init(x: 0, y: 0),
            playerFacing: .down,
            playerSpriteID: "MISSING",
            objects: [],
            assets: assets
        )

        XCTAssertEqual(grayscaleValues(in: scene.backgroundImage), Set([10, 80, 160]))
    }

    func testRendererProducesByteStableRawOutputAcrossRepeatedCalls() throws {
        let fixtureRoot = try makeSyntheticFieldFixture(tileValue: 85, spriteBodyValue: 170)
        defer { try? FileManager.default.removeItem(at: fixtureRoot) }

        let assets = FieldRenderAssets(
            tileset: .init(
                id: "TEST",
                imageURL: fixtureRoot.appendingPathComponent("tileset.png"),
                blocksetURL: fixtureRoot.appendingPathComponent("test.bst")
            ),
            overworldSprites: [
                "SPRITE_RED": FieldSpriteDefinition(
                    id: "SPRITE_RED",
                    imageURL: fixtureRoot.appendingPathComponent("sprite.png"),
                    facingFrames: [
                        .down: .init(x: 0, y: 0, width: 16, height: 16),
                        .up: .init(x: 0, y: 0, width: 16, height: 16),
                        .left: .init(x: 0, y: 0, width: 16, height: 16),
                        .right: .init(x: 0, y: 0, width: 16, height: 16),
                    ]
                ),
            ]
        )

        let map = MapManifest(
            id: "TEST_MAP",
            displayName: "Test Map",
            defaultMusicID: "MUSIC_PALLET_TOWN",
            borderBlockID: 0,
            blockWidth: 1,
            blockHeight: 1,
            stepWidth: 2,
            stepHeight: 2,
            tileset: "TEST",
            blockIDs: [0],
            stepCollisionTileIDs: Array(repeating: 0x00, count: 4),
            warps: [],
            backgroundEvents: [],
            objects: []
        )

        let firstImage = try FieldSceneRenderer.render(
            map: map,
            playerPosition: .init(x: 0, y: 0),
            playerFacing: .down,
            playerSpriteID: "SPRITE_RED",
            objects: [],
            assets: assets
        )
        let secondImage = try FieldSceneRenderer.render(
            map: map,
            playerPosition: .init(x: 0, y: 0),
            playerFacing: .down,
            playerSpriteID: "SPRITE_RED",
            objects: [],
            assets: assets
        )

        XCTAssertEqual(grayscaleValues(in: firstImage), grayscaleValues(in: secondImage))
        XCTAssertEqual(alphaValues(in: firstImage), alphaValues(in: secondImage))
    }

    func testRendererTreatsWhiteSpritePixelsAsTransparentInsteadOfMultiplying() throws {
        let fixtureRoot = try makeSyntheticFieldFixture(tileValue: 85, spriteBodyValue: 170)
        defer { try? FileManager.default.removeItem(at: fixtureRoot) }

        let assets = FieldRenderAssets(
            tileset: .init(
                id: "TEST",
                imageURL: fixtureRoot.appendingPathComponent("tileset.png"),
                blocksetURL: fixtureRoot.appendingPathComponent("test.bst")
            ),
            overworldSprites: [
                "SPRITE_RED": FieldSpriteDefinition(
                    id: "SPRITE_RED",
                    imageURL: fixtureRoot.appendingPathComponent("sprite.png"),
                    facingFrames: [
                        .down: .init(x: 0, y: 0, width: 16, height: 16),
                        .up: .init(x: 0, y: 0, width: 16, height: 16),
                        .left: .init(x: 0, y: 0, width: 16, height: 16),
                        .right: .init(x: 0, y: 0, width: 16, height: 16),
                    ]
                ),
            ]
        )
        let map = MapManifest(
            id: "TEST_MAP",
            displayName: "Test Map",
            defaultMusicID: "MUSIC_PALLET_TOWN",
            borderBlockID: 0,
            blockWidth: 1,
            blockHeight: 1,
            stepWidth: 2,
            stepHeight: 2,
            tileset: "TEST",
            blockIDs: [0],
            stepCollisionTileIDs: Array(repeating: 0x00, count: 4),
            warps: [],
            backgroundEvents: [],
            objects: []
        )

        let image = try FieldSceneRenderer.render(
            map: map,
            playerPosition: .init(x: 0, y: 0),
            playerFacing: .down,
            playerSpriteID: "SPRITE_RED",
            objects: [],
            assets: assets
        )

        XCTAssertEqual(grayscaleValues(in: image), Set([85, 170]))
    }

    func testRendererPreservesRawGrayscaleThresholdBuckets() throws {
        let fixtureRoot = try makeSyntheticPaletteFixture(tileValues: [32, 96, 160, 224])
        defer { try? FileManager.default.removeItem(at: fixtureRoot) }

        let assets = FieldRenderAssets(
            tileset: .init(
                id: "TEST",
                imageURL: fixtureRoot.appendingPathComponent("tileset.png"),
                blocksetURL: fixtureRoot.appendingPathComponent("test.bst")
            ),
            overworldSprites: [:]
        )

        let image = try FieldSceneRenderer.render(
            map: makePaletteMap(blockWidth: 2, blockHeight: 2),
            playerPosition: .init(x: 0, y: 0),
            playerFacing: .down,
            playerSpriteID: "MISSING",
            objects: [],
            assets: assets
        )

        XCTAssertEqual(grayscaleValues(in: image), Set([32, 96, 160, 224]))
    }

    func testRendererPreservesDistinctGrayscaleShades() throws {
        let fixtureRoot = try makeSyntheticPaletteFixture(tileValues: [0, 64, 128, 192, 255])
        defer { try? FileManager.default.removeItem(at: fixtureRoot) }

        let assets = FieldRenderAssets(
            tileset: .init(
                id: "TEST",
                imageURL: fixtureRoot.appendingPathComponent("tileset.png"),
                blocksetURL: fixtureRoot.appendingPathComponent("test.bst")
            ),
            overworldSprites: [:]
        )

        let image = try FieldSceneRenderer.render(
            map: makePaletteMap(blockWidth: 5, blockHeight: 1),
            playerPosition: .init(x: 0, y: 0),
            playerFacing: .down,
            playerSpriteID: "MISSING",
            objects: [],
            assets: assets
        )

        XCTAssertEqual(grayscaleValues(in: image), Set([0, 64, 128, 192, 255]))
    }

    func testRendererKeepsWhiteSpritePixelsTransparentInRawOutput() throws {
        let fixtureRoot = try makeSyntheticFieldFixture(tileValue: 85, spriteBodyValue: 170)
        defer { try? FileManager.default.removeItem(at: fixtureRoot) }

        let assets = FieldRenderAssets(
            tileset: .init(
                id: "TEST",
                imageURL: fixtureRoot.appendingPathComponent("tileset.png"),
                blocksetURL: fixtureRoot.appendingPathComponent("test.bst")
            ),
            overworldSprites: [
                "SPRITE_RED": FieldSpriteDefinition(
                    id: "SPRITE_RED",
                    imageURL: fixtureRoot.appendingPathComponent("sprite.png"),
                    facingFrames: [
                        .down: .init(x: 0, y: 0, width: 16, height: 16),
                        .up: .init(x: 0, y: 0, width: 16, height: 16),
                        .left: .init(x: 0, y: 0, width: 16, height: 16),
                        .right: .init(x: 0, y: 0, width: 16, height: 16),
                    ]
                ),
            ]
        )

        let image = try FieldSceneRenderer.render(
            map: MapManifest(
                id: "TEST_MAP",
                displayName: "Test Map",
                defaultMusicID: "MUSIC_PALLET_TOWN",
                borderBlockID: 0,
                blockWidth: 1,
                blockHeight: 1,
                stepWidth: 2,
                stepHeight: 2,
                tileset: "TEST",
                blockIDs: [0],
                stepCollisionTileIDs: Array(repeating: 0x00, count: 4),
                warps: [],
                backgroundEvents: [],
                objects: []
            ),
            playerPosition: .init(x: 0, y: 0),
            playerFacing: .down,
            playerSpriteID: "SPRITE_RED",
            objects: [],
            assets: assets
        )

        XCTAssertEqual(grayscaleValues(in: image), Set([85, 170]))
    }

    func testRenderSceneKeepsSpriteTransparencyInRawOutput() throws {
        let fixtureRoot = try makeSyntheticFieldFixture(tileValue: 85, spriteBodyValue: 170)
        defer { try? FileManager.default.removeItem(at: fixtureRoot) }

        let assets = FieldRenderAssets(
            tileset: .init(
                id: "TEST",
                imageURL: fixtureRoot.appendingPathComponent("tileset.png"),
                blocksetURL: fixtureRoot.appendingPathComponent("test.bst")
            ),
            overworldSprites: [
                "SPRITE_RED": FieldSpriteDefinition(
                    id: "SPRITE_RED",
                    imageURL: fixtureRoot.appendingPathComponent("sprite.png"),
                    facingFrames: [
                        .down: .init(x: 0, y: 0, width: 16, height: 16),
                        .up: .init(x: 0, y: 0, width: 16, height: 16),
                        .left: .init(x: 0, y: 0, width: 16, height: 16),
                        .right: .init(x: 0, y: 0, width: 16, height: 16),
                    ]
                ),
            ]
        )

        let scene = try FieldSceneRenderer.renderScene(
            map: MapManifest(
                id: "TEST_MAP",
                displayName: "Test Map",
                defaultMusicID: "MUSIC_PALLET_TOWN",
                borderBlockID: 0,
                blockWidth: 1,
                blockHeight: 1,
                stepWidth: 2,
                stepHeight: 2,
                tileset: "TEST",
                blockIDs: [0],
                stepCollisionTileIDs: Array(repeating: 0x00, count: 4),
                warps: [],
                backgroundEvents: [],
                objects: []
            ),
            playerPosition: .init(x: 0, y: 0),
            playerFacing: .down,
            playerSpriteID: "SPRITE_RED",
            objects: [],
            assets: assets
        )

        guard let playerActor = scene.actors.first else {
            return XCTFail("Expected layered player actor")
        }

        XCTAssertTrue(alphaValues(in: playerActor.image).contains(0))
        XCTAssertEqual(
            visibleRGBValues(in: playerActor.image),
            Set([RGBTriplet(red: 170, green: 170, blue: 170)])
        )
        XCTAssertNotNil(playerActor.walkingImage)
    }

    func testPixelAssetMaskKeepsInteriorWhiteHighlightsOpaque() throws {
        let image = try makeRGBAImage(
            width: 5,
            height: 5,
            pixels: [
                255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
                255, 255, 255, 255, 0, 0, 0, 255, 0, 0, 0, 255, 0, 0, 0, 255, 255, 255, 255, 255,
                255, 255, 255, 255, 0, 0, 0, 255, 255, 255, 255, 255, 0, 0, 0, 255, 255, 255, 255, 255,
                255, 255, 255, 255, 0, 0, 0, 255, 0, 0, 0, 255, 0, 0, 0, 255, 255, 255, 255, 255,
                255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
            ]
        )

        guard let maskedImage = PixelAssetView.applyWhiteTransparencyMask(to: image) else {
            return XCTFail("Expected white background masking to succeed")
        }

        let background = RGBTriplet(red: 255, green: 0, blue: 0)
        let compositedImage = try renderRGBAImage(maskedImage, background: background)
        let corner = rgbValue(in: compositedImage, x: 0, y: 0)

        XCTAssertGreaterThan(Int(corner.red), 200)
        XCTAssertLessThan(Int(corner.green), 64)
        XCTAssertLessThan(Int(corner.blue), 16)
        XCTAssertEqual(rgbValue(in: compositedImage, x: 1, y: 1), .init(red: 0, green: 0, blue: 0))
        XCTAssertEqual(rgbValue(in: compositedImage, x: 2, y: 2), .init(red: 255, green: 255, blue: 255))
    }

    private func spriteDefinition(id: String, filename: String) -> FieldSpriteDefinition {
        let root = repoRoot()
        return FieldSpriteDefinition(
            id: id,
            imageURL: root.appendingPathComponent("gfx/sprites/\(filename)"),
            facingFrames: [
                .down: .init(x: 0, y: 0, width: 16, height: 16),
                .up: .init(x: 0, y: 16, width: 16, height: 16),
                .left: .init(x: 0, y: 32, width: 16, height: 16),
                .right: .init(x: 0, y: 32, width: 16, height: 16, flippedHorizontally: true),
            ],
            walkingFrames: [
                .down: .init(x: 0, y: 48, width: 16, height: 16),
                .up: .init(x: 0, y: 64, width: 16, height: 16),
                .left: .init(x: 0, y: 80, width: 16, height: 16),
                .right: .init(x: 0, y: 80, width: 16, height: 16, flippedHorizontally: true),
            ]
        )
    }

    private func loadImage(_ url: URL) throws -> CGImage {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw XCTSkip("Unable to decode image at \(url.path)")
        }
        return image
    }

    private func averageGrayscale(for image: CGImage) -> Double {
        guard let provider = image.dataProvider,
              let data = provider.data else {
            return 0
        }
        let bytes = CFDataGetBytePtr(data)!
        let length = CFDataGetLength(data)
        guard length > 0 else { return 0 }
        let sum = (0..<length).reduce(0) { partial, index in
            partial + Int(bytes[index])
        }
        return Double(sum) / Double(length)
    }

    private func averageGrayscale(forTopRowsOf image: CGImage, rowCount: Int) -> Double {
        averageGrayscale(in: image, startRow: 0, rowCount: rowCount)
    }

    private func averageGrayscale(forBottomRowsOf image: CGImage, rowCount: Int) -> Double {
        averageGrayscale(in: image, startRow: image.height - rowCount, rowCount: rowCount)
    }

    private func averageGrayscale(in image: CGImage, startRow: Int, rowCount: Int) -> Double {
        guard let provider = image.dataProvider,
              let data = provider.data,
              let bytes = CFDataGetBytePtr(data) else {
            return 0
        }

        let bytesPerRow = image.bytesPerRow
        let clampedStartRow = max(0, min(image.height - 1, startRow))
        let clampedRowCount = max(1, min(rowCount, image.height - clampedStartRow))
        var sum = 0
        var count = 0

        for row in clampedStartRow..<(clampedStartRow + clampedRowCount) {
            let rowStart = row * bytesPerRow
            for column in 0..<image.width {
                sum += Int(bytes[rowStart + column])
                count += 1
            }
        }

        guard count > 0 else { return 0 }
        return Double(sum) / Double(count)
    }

    private func grayscaleValues(in image: CGImage) -> Set<Int> {
        guard let provider = image.dataProvider,
              let data = provider.data,
              let bytes = CFDataGetBytePtr(data) else {
            return []
        }

        var values: Set<Int> = []
        for row in 0..<image.height {
            let rowStart = row * image.bytesPerRow
            for column in 0..<image.width {
                values.insert(Int(bytes[rowStart + column]))
            }
        }
        return values
    }

    private func rgbValues(in image: CGImage) -> Set<RGBTriplet> {
        guard let provider = image.dataProvider,
              let data = provider.data,
              let bytes = CFDataGetBytePtr(data) else {
            return []
        }

        var values: Set<RGBTriplet> = []
        for row in 0..<image.height {
            let rowStart = row * image.bytesPerRow
            for column in 0..<image.width {
                let pixelStart = rowStart + (column * 4)
                values.insert(
                    RGBTriplet(
                        red: bytes[pixelStart],
                        green: bytes[pixelStart + 1],
                        blue: bytes[pixelStart + 2]
                    )
                )
            }
        }
        return values
    }

    private func alphaValues(in image: CGImage) -> Set<UInt8> {
        guard let provider = image.dataProvider,
              let data = provider.data,
              let bytes = CFDataGetBytePtr(data) else {
            return []
        }

        var values: Set<UInt8> = []
        for row in 0..<image.height {
            let rowStart = row * image.bytesPerRow
            for column in 0..<image.width {
                values.insert(bytes[rowStart + (column * 4) + 3])
            }
        }
        return values
    }

    private func alphaValue(in image: CGImage, x: Int, y: Int) -> UInt8 {
        guard let provider = image.dataProvider,
              let data = provider.data,
              let bytes = CFDataGetBytePtr(data) else {
            return 0
        }

        let pixelStart = (y * image.bytesPerRow) + (x * 4)
        return bytes[pixelStart + 3]
    }

    private func rgbValue(in image: CGImage, x: Int, y: Int) -> RGBTriplet {
        guard let provider = image.dataProvider,
              let data = provider.data,
              let bytes = CFDataGetBytePtr(data) else {
            return .init(red: 0, green: 0, blue: 0)
        }

        let pixelStart = (y * image.bytesPerRow) + (x * 4)
        return RGBTriplet(
            red: bytes[pixelStart],
            green: bytes[pixelStart + 1],
            blue: bytes[pixelStart + 2]
        )
    }

    private func visibleRGBValues(in image: CGImage) -> Set<RGBTriplet> {
        guard let provider = image.dataProvider,
              let data = provider.data,
              let bytes = CFDataGetBytePtr(data) else {
            return []
        }

        var values: Set<RGBTriplet> = []
        for row in 0..<image.height {
            let rowStart = row * image.bytesPerRow
            for column in 0..<image.width {
                let pixelStart = rowStart + (column * 4)
                guard bytes[pixelStart + 3] > 0 else { continue }
                values.insert(
                    RGBTriplet(
                        red: bytes[pixelStart],
                        green: bytes[pixelStart + 1],
                        blue: bytes[pixelStart + 2]
                    )
                )
            }
        }
        return values
    }

    private func makeTestTileImage(topHalf: UInt8, bottomHalf: UInt8) throws -> CGImage {
        let width = 8
        let height = 8
        let bytesPerRow = width
        let topRows = Array(repeating: topHalf, count: width * 4)
        let bottomRows = Array(repeating: bottomHalf, count: width * 4)
        let data = Data(topRows + bottomRows) as CFData
        guard let provider = CGDataProvider(data: data),
              let image = CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 8,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceGray(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
              ) else {
            throw XCTSkip("Unable to create synthetic tile image")
        }
        return image
    }

    private func cropTopLeftTile(from image: CGImage, tileSize: Int, index: Int) throws -> CGImage {
        let columns = max(1, image.width / tileSize)
        let x = (index % columns) * tileSize
        let y = (index / columns) * tileSize
        guard let tile = image.cropping(to: CGRect(x: x, y: y, width: tileSize, height: tileSize)) else {
            throw XCTSkip("Unable to crop tile \(index)")
        }
        return tile
    }

    private func makeSyntheticFieldFixture(tileValue: UInt8, spriteBodyValue: UInt8) throws -> URL {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let tilesetPixels = Array(repeating: tileValue, count: 8 * 8)
        try writeGrayscalePNG(
            width: 8,
            height: 8,
            pixels: tilesetPixels,
            to: root.appendingPathComponent("tileset.png")
        )

        var spritePixels = Array(repeating: UInt8(255), count: 16 * 16)
        for y in 4..<12 {
            for x in 4..<12 {
                spritePixels[(y * 16) + x] = spriteBodyValue
            }
        }
        try writeGrayscalePNG(
            width: 16,
            height: 16,
            pixels: spritePixels,
            to: root.appendingPathComponent("sprite.png")
        )

        try Data(Array(repeating: UInt8(0), count: 16)).write(to: root.appendingPathComponent("test.bst"))
        return root
    }

    private func makeSyntheticPaletteFixture(tileValues: [UInt8]) throws -> URL {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        var tilesetPixels: [UInt8] = []
        for value in tileValues {
            tilesetPixels.append(contentsOf: Array(repeating: value, count: 8 * 8))
        }

        try writeGrayscalePNG(
            width: tileValues.count * 8,
            height: 8,
            pixels: tilesetPixels,
            to: root.appendingPathComponent("tileset.png")
        )

        var blocksetBytes: [UInt8] = []
        for tileIndex in tileValues.indices {
            blocksetBytes.append(contentsOf: Array(repeating: UInt8(tileIndex), count: 16))
        }
        try Data(blocksetBytes).write(to: root.appendingPathComponent("test.bst"))
        return root
    }

    private func makePaletteMap(blockWidth: Int, blockHeight: Int) -> MapManifest {
        MapManifest(
            id: "PALETTE_MAP",
            displayName: "Palette Map",
            defaultMusicID: "MUSIC_PALLET_TOWN",
            borderBlockID: 0,
            blockWidth: blockWidth,
            blockHeight: blockHeight,
            stepWidth: blockWidth * 2,
            stepHeight: blockHeight * 2,
            tileset: "TEST",
            blockIDs: Array(0..<(blockWidth * blockHeight)),
            stepCollisionTileIDs: Array(repeating: 0x00, count: blockWidth * blockHeight * 4),
            warps: [],
            backgroundEvents: [],
            objects: []
        )
    }

    private func dmgPaletteValues() -> Set<RGBTriplet> {
        Set([
            RGBTriplet(red: 15, green: 56, blue: 15),
            RGBTriplet(red: 48, green: 98, blue: 48),
            RGBTriplet(red: 139, green: 172, blue: 15),
            RGBTriplet(red: 155, green: 188, blue: 15),
        ])
    }

    private func writeGrayscalePNG(width: Int, height: Int, pixels: [UInt8], to url: URL) throws {
        let bytesPerRow = width
        let data = Data(pixels) as CFData
        guard let provider = CGDataProvider(data: data),
              let image = CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 8,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceGray(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
              ),
              let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            throw XCTSkip("Unable to write grayscale PNG fixture")
        }

        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw XCTSkip("Unable to finalize PNG fixture at \(url.path)")
        }
    }

    private func makeRGBAImage(width: Int, height: Int, pixels: [UInt8]) throws -> CGImage {
        let bytesPerRow = width * 4
        let data = Data(pixels) as CFData
        guard let provider = CGDataProvider(data: data),
              let image = CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
              ) else {
            throw XCTSkip("Unable to create RGBA fixture image")
        }

        return image
    }

    private func renderRGBAImage(_ image: CGImage, background: RGBTriplet? = nil) throws -> CGImage {
        let width = image.width
        let height = image.height
        let bytesPerRow = width * 4
        var bytes = [UInt8](repeating: 0, count: height * bytesPerRow)

        guard let context = CGContext(
            data: &bytes,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw XCTSkip("Unable to create RGBA render context")
        }

        context.interpolationQuality = .none
        context.setShouldAntialias(false)

        if let background {
            context.setFillColor(
                CGColor(
                    red: CGFloat(background.red) / 255,
                    green: CGFloat(background.green) / 255,
                    blue: CGFloat(background.blue) / 255,
                    alpha: 1
                )
            )
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }

        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let renderedImage = context.makeImage() else {
            throw XCTSkip("Unable to create composited RGBA image")
        }

        return renderedImage
    }

    private func repoRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}

private struct RGBTriplet: Hashable {
    let red: UInt8
    let green: UInt8
    let blue: UInt8
}
