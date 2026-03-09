import XCTest
@testable import PokeCore
import PokeContent
import PokeDataModel

@MainActor
final class PokeCoreTests: XCTestCase {
    func testTitleFlowTransitionsFromAttractToMenuAndPlaceholder() async {
        let runtime = GameRuntime(content: fixtureContent(), telemetryPublisher: nil)
        runtime.start()
        try? await Task.sleep(for: .milliseconds(1700))
        XCTAssertEqual(runtime.scene, .titleAttract)
        runtime.handle(button: .start)
        XCTAssertEqual(runtime.scene, .titleMenu)

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
            audioManifest: .init(variant: .red, tracks: [])
        )
    }
}
