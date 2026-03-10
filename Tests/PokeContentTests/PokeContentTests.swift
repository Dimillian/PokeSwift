import Foundation
import XCTest
@testable import PokeContent
import PokeDataModel

final class PokeContentTests: XCTestCase {
    func testLoaderReadsGeneratedContentShape() throws {
        let root = try makeFixtureRoot()
        let loaded = try FileSystemContentLoader(rootURL: root).load()
        XCTAssertEqual(loaded.gameManifest.variant, .red)
        XCTAssertEqual(loaded.titleManifest.menuEntries.count, 3)
        XCTAssertEqual(loaded.gameplayManifest.maps.count, 1)
        XCTAssertEqual(loaded.gameplayManifest.dialogues.count, 1)
        XCTAssertEqual(loaded.gameplayManifest.playerStart.mapID, "REDS_HOUSE_2F")
        XCTAssertEqual(loaded.map(id: "REDS_HOUSE_2F")?.displayName, "Red's House 2F")
        XCTAssertEqual(loaded.dialogue(id: "hello")?.pages.first?.lines, ["Hi"])
        XCTAssertEqual(loaded.script(id: "oak_intro")?.steps.map(\.action), ["showDialogue"])
        XCTAssertEqual(loaded.mapScript(for: "REDS_HOUSE_2F")?.triggers.first?.scriptID, "oak_intro")
        XCTAssertEqual(loaded.species(id: "SQUIRTLE")?.startingMoves, ["TACKLE", "TAIL_WHIP"])
        XCTAssertEqual(loaded.species(id: "SQUIRTLE")?.primaryType, "WATER")
        XCTAssertEqual(
            loaded.species(id: "SQUIRTLE")?.battleSprite,
            .init(
                frontImagePath: "Assets/battle/pokemon/front/squirtle.png",
                backImagePath: "Assets/battle/pokemon/back/squirtle.png"
            )
        )
        XCTAssertEqual(loaded.move(id: "TACKLE")?.power, 35)
        XCTAssertEqual(loaded.typeEffectiveness(attackingType: "WATER", defendingType: "FIRE")?.multiplier, 20)
        XCTAssertEqual(loaded.trainerBattle(id: "opp_rival1_2")?.party.first?.speciesID, "BULBASAUR")
        XCTAssertEqual(loaded.tileset(id: "REDS_HOUSE_2")?.imagePath, "Assets/field/tilesets/reds_house.png")
        XCTAssertEqual(loaded.tileset(id: "REDS_HOUSE_2")?.collision.passableTileIDs, [0x01, 0x02])
        XCTAssertEqual(loaded.overworldSprite(id: "SPRITE_RED")?.frameHeight, 16)
    }

    func testLoaderResolvesRepoGeneratedFieldAssets() throws {
        let root = repoRoot().appendingPathComponent("Content/Red", isDirectory: true)
        let loaded = try FileSystemContentLoader(rootURL: root).load()

        let tileset = try XCTUnwrap(loaded.tileset(id: "OVERWORLD"))
        let sprite = try XCTUnwrap(loaded.overworldSprite(id: "SPRITE_RED"))
        let oaksLab = try XCTUnwrap(loaded.map(id: "OAKS_LAB"))

        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent(tileset.imagePath).path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent(tileset.blocksetPath).path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent(sprite.imagePath).path))
        XCTAssertTrue(
            loaded.fieldRenderIssues(
                map: oaksLab,
                spriteIDs: ["SPRITE_RED", "SPRITE_OAK", "SPRITE_BLUE", "SPRITE_SCIENTIST", "SPRITE_POKE_BALL", "SPRITE_POKEDEX"]
            ).isEmpty
        )
    }

    private func makeFixtureRoot() throws -> URL {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true, attributes: nil)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(GameManifest(contentVersion: "test", variant: .red, sourceCommit: "abc", extractorVersion: "1", sourceFiles: [])).write(to: root.appendingPathComponent("game_manifest.json"))
        try encoder.encode(ConstantsManifest(variant: .red, sourceFiles: [], watchedKeys: ["PAD_A"], musicTrack: "MUSIC_TITLE_SCREEN", titleMonSelectionConstant: "STARTER1")).write(to: root.appendingPathComponent("constants.json"))
        try encoder.encode(CharmapManifest(variant: .red, entries: [.init(token: "A", value: 0x80, sourceSection: "test")])).write(to: root.appendingPathComponent("charmap.json"))
        try encoder.encode(
            TitleSceneManifest(
                variant: .red,
                sourceFiles: [],
                titleMonSpecies: "STARTER1",
                menuEntries: [
                    .init(id: "newGame", label: "New Game", enabledByDefault: true),
                    .init(id: "continue", label: "Continue", enabledByDefault: false),
                    .init(id: "options", label: "Options", enabledByDefault: true),
                ],
                logoBounceSequence: [.init(yDelta: -4, frames: 16)],
                assets: [.init(id: "logo", relativePath: "Assets/logo.png", kind: "titleLogo")],
                timings: .init(launchFadeSeconds: 0.4, splashDurationSeconds: 1.2, attractPromptDelaySeconds: 0.8)
            )
        ).write(to: root.appendingPathComponent("title_manifest.json"))
        try encoder.encode(testGameplayManifest()).write(to: root.appendingPathComponent("gameplay_manifest.json"))
        try encoder.encode(AudioManifest(variant: .red, tracks: [.init(id: "title", sourceFile: "audio/music/titlescreen.asm")])).write(to: root.appendingPathComponent("audio_manifest.json"))

        let assetRoot = root.appendingPathComponent("Assets", isDirectory: true)
        try FileManager.default.createDirectory(at: assetRoot, withIntermediateDirectories: true, attributes: nil)
        FileManager.default.createFile(atPath: assetRoot.appendingPathComponent("logo.png").path, contents: Data())
        let fieldTilesetRoot = assetRoot.appendingPathComponent("field/tilesets", isDirectory: true)
        let fieldBlocksetRoot = assetRoot.appendingPathComponent("field/blocksets", isDirectory: true)
        let fieldSpriteRoot = assetRoot.appendingPathComponent("field/sprites", isDirectory: true)
        let battleFrontRoot = assetRoot.appendingPathComponent("battle/pokemon/front", isDirectory: true)
        let battleBackRoot = assetRoot.appendingPathComponent("battle/pokemon/back", isDirectory: true)
        try FileManager.default.createDirectory(at: fieldTilesetRoot, withIntermediateDirectories: true, attributes: nil)
        try FileManager.default.createDirectory(at: fieldBlocksetRoot, withIntermediateDirectories: true, attributes: nil)
        try FileManager.default.createDirectory(at: fieldSpriteRoot, withIntermediateDirectories: true, attributes: nil)
        try FileManager.default.createDirectory(at: battleFrontRoot, withIntermediateDirectories: true, attributes: nil)
        try FileManager.default.createDirectory(at: battleBackRoot, withIntermediateDirectories: true, attributes: nil)
        FileManager.default.createFile(atPath: fieldTilesetRoot.appendingPathComponent("reds_house.png").path, contents: Data())
        FileManager.default.createFile(atPath: fieldBlocksetRoot.appendingPathComponent("reds_house.bst").path, contents: Data(repeating: 0, count: 16))
        FileManager.default.createFile(atPath: fieldSpriteRoot.appendingPathComponent("red.png").path, contents: Data())
        FileManager.default.createFile(atPath: battleFrontRoot.appendingPathComponent("squirtle.png").path, contents: Data())
        FileManager.default.createFile(atPath: battleBackRoot.appendingPathComponent("squirtle.png").path, contents: Data())
        return root
    }

    private func testGameplayManifest() -> GameplayManifest {
        GameplayManifest(
            maps: [
                .init(
                    id: "REDS_HOUSE_2F",
                    displayName: "Red's House 2F",
                    borderBlockID: 0x0A,
                    blockWidth: 4,
                    blockHeight: 4,
                    stepWidth: 8,
                    stepHeight: 8,
                    tileset: "REDS_HOUSE_2",
                    blockIDs: Array(repeating: 0x05, count: 16),
                    stepCollisionTileIDs: Array(repeating: 0x01, count: 64),
                    warps: [],
                    backgroundEvents: [],
                    objects: []
                ),
            ],
            tilesets: [
                .init(
                    id: "REDS_HOUSE_2",
                    imagePath: "Assets/field/tilesets/reds_house.png",
                    blocksetPath: "Assets/field/blocksets/reds_house.bst",
                    sourceTileSize: 8,
                    blockTileWidth: 4,
                    blockTileHeight: 4,
                    collision: .init(
                        passableTileIDs: [0x01, 0x02],
                        warpTileIDs: [0x1A],
                        doorTileIDs: [0x1A],
                        tilePairCollisions: [],
                        ledges: []
                    )
                ),
            ],
            overworldSprites: [
                .init(
                    id: "SPRITE_RED",
                    imagePath: "Assets/field/sprites/red.png",
                    frameWidth: 16,
                    frameHeight: 16,
                    facingFrames: .init(
                        down: .init(x: 0, y: 0, width: 16, height: 16),
                        up: .init(x: 0, y: 16, width: 16, height: 16),
                        left: .init(x: 0, y: 32, width: 16, height: 16),
                        right: .init(x: 0, y: 32, width: 16, height: 16, flippedHorizontally: true)
                    )
                ),
            ],
            dialogues: [.init(id: "hello", pages: [.init(lines: ["Hi"], waitsForPrompt: true)])],
            eventFlags: .init(flags: [.init(id: "EVENT_GOT_STARTER", sourceConstant: "EVENT_GOT_STARTER")]),
            mapScripts: [.init(mapID: "REDS_HOUSE_2F", triggers: [.init(id: "intro", scriptID: "oak_intro", conditions: [])])],
            scripts: [.init(id: "oak_intro", steps: [.init(action: "showDialogue", dialogueID: "hello")])],
            species: [
                .init(
                    id: "SQUIRTLE",
                    displayName: "Squirtle",
                    primaryType: "WATER",
                    battleSprite: .init(
                        frontImagePath: "Assets/battle/pokemon/front/squirtle.png",
                        backImagePath: "Assets/battle/pokemon/back/squirtle.png"
                    ),
                    baseHP: 44,
                    baseAttack: 48,
                    baseDefense: 65,
                    baseSpeed: 43,
                    baseSpecial: 50,
                    startingMoves: ["TACKLE", "TAIL_WHIP"]
                ),
            ],
            moves: [
                .init(
                    id: "TACKLE",
                    displayName: "TACKLE",
                    power: 35,
                    accuracy: 95,
                    maxPP: 35,
                    effect: "NO_ADDITIONAL_EFFECT",
                    type: "NORMAL"
                ),
            ],
            typeEffectiveness: [
                .init(attackingType: "WATER", defendingType: "FIRE", multiplier: 20),
                .init(attackingType: "NORMAL", defendingType: "GHOST", multiplier: 0),
            ],
            trainerBattles: [
                .init(
                    id: "opp_rival1_2",
                    trainerClass: "OPP_RIVAL1",
                    trainerNumber: 2,
                    displayName: "BLUE",
                    party: [.init(speciesID: "BULBASAUR", level: 5)],
                    winDialogueID: "hello",
                    loseDialogueID: "hello",
                    healsPartyAfterBattle: true,
                    preventsBlackoutOnLoss: true,
                    completionFlagID: "EVENT_GOT_STARTER"
                ),
            ],
            playerStart: .init(mapID: "REDS_HOUSE_2F", position: .init(x: 2, y: 2), facing: .down, playerName: "RED", rivalName: "BLUE", initialFlags: [])
        )
    }

    private func repoRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
