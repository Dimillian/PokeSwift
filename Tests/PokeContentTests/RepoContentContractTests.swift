import XCTest
@testable import PokeContent

final class RepoContentContractTests: XCTestCase {
    func testLoaderResolvesRepoGeneratedFieldAssets() throws {
        let root = PokeContentTestSupport.repoRoot().appendingPathComponent("Content/Red", isDirectory: true)
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

    func testLoaderReadsRepoGeneratedAudioContract() throws {
        let root = PokeContentTestSupport.repoRoot().appendingPathComponent("Content/Red", isDirectory: true)
        let loaded = try FileSystemContentLoader(rootURL: root).load()

        XCTAssertEqual(loaded.audioManifest.titleTrackID, "MUSIC_TITLE_SCREEN")
        XCTAssertEqual(loaded.map(id: "REDS_HOUSE_2F")?.defaultMusicID, "MUSIC_PALLET_TOWN")
        XCTAssertEqual(loaded.map(id: "OAKS_LAB")?.defaultMusicID, "MUSIC_OAKS_LAB")
        XCTAssertEqual(loaded.audioCue(id: "oak_intro")?.trackID, "MUSIC_MEET_PROF_OAK")
        XCTAssertEqual(loaded.audioCue(id: "rival_exit")?.entryID, "alternateStart")
        XCTAssertEqual(loaded.audioCue(id: "mom_heal")?.waitForCompletion, true)
        XCTAssertEqual(loaded.audioCue(id: "mom_heal")?.resumeMusicAfterCompletion, true)
        XCTAssertEqual(loaded.audioCue(id: "pokemon_center_healed")?.waitForCompletion, true)
        XCTAssertEqual(loaded.audioCue(id: "pokemon_center_healed")?.resumeMusicAfterCompletion, true)
        XCTAssertNotNil(loaded.audioTrack(id: "MUSIC_TITLE_SCREEN"))
        XCTAssertNotNil(loaded.audioEntry(trackID: "MUSIC_MEET_RIVAL", entryID: "alternateStart"))
        XCTAssertEqual(
            loaded.audioManifest.mapRoutes,
            [
                .init(mapID: "OAKS_LAB", musicID: "MUSIC_OAKS_LAB"),
                .init(mapID: "PALLET_TOWN", musicID: "MUSIC_PALLET_TOWN"),
                .init(mapID: "REDS_HOUSE_1F", musicID: "MUSIC_PALLET_TOWN"),
                .init(mapID: "REDS_HOUSE_2F", musicID: "MUSIC_PALLET_TOWN"),
                .init(mapID: "ROUTE_1", musicID: "MUSIC_ROUTES1"),
                .init(mapID: "VIRIDIAN_CITY", musicID: "MUSIC_CITIES1"),
                .init(mapID: "VIRIDIAN_MART", musicID: "MUSIC_POKECENTER"),
                .init(mapID: "VIRIDIAN_NICKNAME_HOUSE", musicID: "MUSIC_CITIES1"),
                .init(mapID: "VIRIDIAN_POKECENTER", musicID: "MUSIC_POKECENTER"),
                .init(mapID: "VIRIDIAN_SCHOOL_HOUSE", musicID: "MUSIC_CITIES1"),
            ]
        )
    }

    func testLoaderReadsRepoGeneratedMartAndCaptureContracts() throws {
        let root = PokeContentTestSupport.repoRoot().appendingPathComponent("Content/Red", isDirectory: true)
        let loaded = try FileSystemContentLoader(rootURL: root).load()

        let mart = try XCTUnwrap(loaded.mart(id: "viridian_mart"))
        let pokeBall = try XCTUnwrap(loaded.item(id: "POKE_BALL"))
        let pidgey = try XCTUnwrap(loaded.species(id: "PIDGEY"))
        let squirtle = try XCTUnwrap(loaded.species(id: "SQUIRTLE"))

        XCTAssertEqual(mart.mapID, "VIRIDIAN_MART")
        XCTAssertEqual(mart.clerkObjectID, "viridian_mart_clerk")
        XCTAssertEqual(mart.stockItemIDs, ["POKE_BALL", "ANTIDOTE", "PARLYZ_HEAL", "BURN_HEAL"])
        XCTAssertEqual(loaded.mart(mapID: "VIRIDIAN_MART", clerkObjectID: "viridian_mart_clerk")?.id, mart.id)
        XCTAssertEqual(pokeBall.price, 200)
        XCTAssertEqual(pokeBall.battleUse, .ball)
        XCTAssertEqual(pidgey.catchRate, 255)
        XCTAssertEqual(
            Array(squirtle.levelUpLearnset.prefix(2)),
            [.init(level: 8, moveID: "BUBBLE"), .init(level: 15, moveID: "WATER_GUN")]
        )
    }

    func testLoaderReadsRepoGeneratedPokemonCenterInteractionContract() throws {
        let root = PokeContentTestSupport.repoRoot().appendingPathComponent("Content/Red", isDirectory: true)
        let loaded = try FileSystemContentLoader(rootURL: root).load()

        let interaction = try XCTUnwrap(loaded.fieldInteraction(id: "pokemon_center_healing"))
        XCTAssertEqual(interaction.kind, .pokemonCenterHealing)
        XCTAssertEqual(interaction.introDialogueID, "pokemon_center_welcome")
        XCTAssertEqual(interaction.prompt.dialogueID, "pokemon_center_shall_we_heal")
        XCTAssertEqual(interaction.acceptedDialogueID, "pokemon_center_need_your_pokemon")
        XCTAssertEqual(interaction.successDialogueID, "pokemon_center_fighting_fit")
        XCTAssertEqual(interaction.farewellDialogueID, "pokemon_center_farewell")
        XCTAssertEqual(interaction.healingSequence?.machineSoundEffectID, "SFX_HEALING_MACHINE")
        XCTAssertEqual(interaction.healingSequence?.healedAudioCueID, "pokemon_center_healed")
    }
}
