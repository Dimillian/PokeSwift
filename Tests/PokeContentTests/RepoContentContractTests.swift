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
}
