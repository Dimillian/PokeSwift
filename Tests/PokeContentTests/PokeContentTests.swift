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
        try encoder.encode(AudioManifest(variant: .red, tracks: [.init(id: "title", sourceFile: "audio/music/titlescreen.asm")])).write(to: root.appendingPathComponent("audio_manifest.json"))

        let assetRoot = root.appendingPathComponent("Assets", isDirectory: true)
        try FileManager.default.createDirectory(at: assetRoot, withIntermediateDirectories: true, attributes: nil)
        FileManager.default.createFile(atPath: assetRoot.appendingPathComponent("logo.png").path, contents: Data())
        return root
    }
}
