import Foundation
import PokeDataModel

enum PokeContentTestSupport {
    static func makeFixtureRoot() throws -> URL {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true, attributes: nil)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        try encoder.encode(
            GameManifest(
                contentVersion: "test",
                variant: .red,
                sourceCommit: "abc",
                extractorVersion: "1",
                sourceFiles: []
            )
        ).write(to: root.appendingPathComponent("game_manifest.json"))
        try encoder.encode(
            ConstantsManifest(
                variant: .red,
                sourceFiles: [],
                watchedKeys: ["PAD_A"],
                musicTrack: "MUSIC_TITLE_SCREEN",
                titleMonSelectionConstant: "STARTER1"
            )
        ).write(to: root.appendingPathComponent("constants.json"))
        try encoder.encode(
            CharmapManifest(
                variant: .red,
                entries: [.init(token: "A", value: 0x80, sourceSection: "test")]
            )
        ).write(to: root.appendingPathComponent("charmap.json"))
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
                timings: .init(
                    launchFadeSeconds: 0.4,
                    splashDurationSeconds: 1.2,
                    attractPromptDelaySeconds: 0.8
                )
            )
        ).write(to: root.appendingPathComponent("title_manifest.json"))
        try encoder.encode(testGameplayManifest()).write(to: root.appendingPathComponent("gameplay_manifest.json"))
        try encoder.encode(
            AudioManifest(
                variant: .red,
                titleTrackID: "MUSIC_TITLE_SCREEN",
                mapRoutes: [.init(mapID: "REDS_HOUSE_2F", musicID: "MUSIC_PALLET_TOWN")],
                cues: [
                    .init(id: "title_default", assetID: "MUSIC_TITLE_SCREEN"),
                    .init(
                        id: "mom_heal",
                        assetID: "MUSIC_PKMN_HEALED",
                        waitForCompletion: true,
                        resumeMusicAfterCompletion: true
                    ),
                ],
                tracks: [
                    .init(
                        id: "MUSIC_TITLE_SCREEN",
                        sourceLabel: "Music_TitleScreen",
                        sourceFile: "audio/music/titlescreen.asm",
                        entries: [.init(id: "default", sourceLabel: "Music_TitleScreen_Ch1", playbackMode: .looping, channels: [])]
                    ),
                    .init(
                        id: "MUSIC_PALLET_TOWN",
                        sourceLabel: "Music_PalletTown",
                        sourceFile: "audio/music/pallettown.asm",
                        entries: [.init(id: "default", sourceLabel: "Music_PalletTown_Ch1", playbackMode: .looping, channels: [])]
                    ),
                    .init(
                        id: "MUSIC_PKMN_HEALED",
                        sourceLabel: "Music_PkmnHealed",
                        sourceFile: "audio/music/pkmnhealed.asm",
                        entries: [.init(id: "default", sourceLabel: "Music_PkmnHealed_Ch1", playbackMode: .oneShot, channels: [])]
                    ),
                ],
                soundEffects: []
            )
        ).write(to: root.appendingPathComponent("audio_manifest.json"))

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
        FileManager.default.createFile(
            atPath: fieldBlocksetRoot.appendingPathComponent("reds_house.bst").path,
            contents: Data(repeating: 0, count: 16)
        )
        FileManager.default.createFile(atPath: fieldSpriteRoot.appendingPathComponent("red.png").path, contents: Data())
        FileManager.default.createFile(atPath: battleFrontRoot.appendingPathComponent("squirtle.png").path, contents: Data())
        FileManager.default.createFile(atPath: battleBackRoot.appendingPathComponent("squirtle.png").path, contents: Data())

        return root
    }

    static func testGameplayManifest() -> GameplayManifest {
        GameplayManifest(
            maps: [
                .init(
                    id: "REDS_HOUSE_2F",
                    displayName: "Red's House 2F",
                    defaultMusicID: "MUSIC_PALLET_TOWN",
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
                    baseExp: 66,
                    growthRate: .mediumSlow,
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
            playerStart: .init(
                mapID: "REDS_HOUSE_2F",
                position: .init(x: 2, y: 2),
                facing: .down,
                playerName: "RED",
                rivalName: "BLUE",
                initialFlags: []
            )
        )
    }

    static func repoRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
