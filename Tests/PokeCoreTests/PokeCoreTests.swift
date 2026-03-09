import XCTest
@testable import PokeCore
import PokeContent
import PokeDataModel

@MainActor
final class PokeCoreTests: XCTestCase {
    func testTitleFlowTransitionsFromAttractToMenuAndOptionsPlaceholder() async {
        let runtime = GameRuntime(content: fixtureContent(), telemetryPublisher: nil)
        runtime.start()
        try? await Task.sleep(for: .milliseconds(1700))
        XCTAssertEqual(runtime.scene, .titleAttract)
        runtime.handle(button: .start)
        XCTAssertEqual(runtime.scene, .titleMenu)

        runtime.handle(button: .down)
        runtime.handle(button: .down)
        runtime.handle(button: .confirm)
        runtime.updateWindowScale(5)
        XCTAssertEqual(runtime.currentSnapshot().window.scale, 5)
        XCTAssertEqual(runtime.scene, .placeholder)
    }

    func testMenuInteractionWithDisabledContinue() async {
        let runtime = GameRuntime(content: fixtureContent(), telemetryPublisher: nil)
        runtime.start()
        try? await Task.sleep(for: .milliseconds(1700))
        runtime.handle(button: .start)
        runtime.handle(button: .down)
        runtime.handle(button: .confirm)
        XCTAssertEqual(runtime.currentSnapshot().substate, "continue_disabled")
    }

    func testNewGameEntersFieldAndPublishesFieldTelemetry() async {
        let runtime = GameRuntime(content: fixtureContent(), telemetryPublisher: nil)
        runtime.start()
        try? await Task.sleep(for: .milliseconds(1700))
        runtime.handle(button: .start)
        runtime.handle(button: .confirm)

        let snapshot = runtime.currentSnapshot()
        XCTAssertEqual(snapshot.scene, .field)
        XCTAssertEqual(snapshot.field?.mapID, "REDS_HOUSE_2F")
        XCTAssertEqual(snapshot.field?.playerPosition, TilePoint(x: 4, y: 4))
        XCTAssertEqual(snapshot.field?.renderMode, "placeholder")
    }

    func testRepoGeneratedContentPublishesRealAssetFieldTelemetry() async throws {
        let contentRoot = repoRoot().appendingPathComponent("Content/Red", isDirectory: true)
        let content = try FileSystemContentLoader(rootURL: contentRoot).load()
        let runtime = GameRuntime(content: content, telemetryPublisher: nil)

        runtime.start()
        try? await Task.sleep(for: .milliseconds(1700))
        runtime.handle(button: .start)
        runtime.handle(button: .confirm)

        let snapshot = runtime.currentSnapshot()
        XCTAssertEqual(snapshot.scene, .field)
        XCTAssertEqual(snapshot.field?.mapID, "REDS_HOUSE_2F")
        XCTAssertEqual(snapshot.field?.renderMode, "realAssets")
        XCTAssertEqual(snapshot.assetLoadingFailures, [])
    }

    private func fixtureContent() -> LoadedContent {
        LoadedContent(
            rootURL: URL(fileURLWithPath: "/tmp", isDirectory: true),
            gameManifest: .init(contentVersion: "test", variant: .red, sourceCommit: "abc", extractorVersion: "1", sourceFiles: []),
            constantsManifest: .init(variant: .red, sourceFiles: [], watchedKeys: ["PAD_A", "PAD_B", "PAD_START"], musicTrack: "MUSIC_TITLE_SCREEN", titleMonSelectionConstant: "STARTER1"),
            charmapManifest: .init(variant: .red, entries: [.init(token: "A", value: 0x80, sourceSection: "test")]),
            titleManifest: .init(
                variant: .red,
                sourceFiles: [],
                titleMonSpecies: "STARTER1",
                menuEntries: [
                    .init(id: "newGame", label: "New Game", enabledByDefault: true),
                    .init(id: "continue", label: "Continue", enabledByDefault: false),
                    .init(id: "options", label: "Options", enabledByDefault: true),
                ],
                logoBounceSequence: [],
                assets: [],
                timings: .init(launchFadeSeconds: 0.4, splashDurationSeconds: 1.2, attractPromptDelaySeconds: 0.8)
            ),
            audioManifest: .init(variant: .red, tracks: []),
            gameplayManifest: .init(
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
                        collisionBlockIDs: [],
                        blockIDs: Array(repeating: 0x05, count: 16),
                        warps: [],
                        backgroundEvents: [],
                        objects: [],
                        triggerRegions: []
                    ),
                ],
                tilesets: [
                    .init(
                        id: "REDS_HOUSE_2",
                        imagePath: "Assets/field/tilesets/reds_house.png",
                        blocksetPath: "Assets/field/blocksets/reds_house.bst",
                        sourceTileSize: 8,
                        blockTileWidth: 4,
                        blockTileHeight: 4
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
                dialogues: [],
                eventFlags: .init(flags: []),
                scripts: [],
                species: [],
                moves: [],
                trainerBattles: [],
                playerStart: .init(mapID: "REDS_HOUSE_2F", position: .init(x: 4, y: 4), facing: .down, playerName: "RED", rivalName: "BLUE", initialFlags: [])
            )
        )
    }

    private func repoRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
