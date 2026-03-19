import XCTest
import PokeDataModel

@testable import PokeMac

@MainActor
final class TitleSceneViewTests: XCTestCase {
    func testTitleAttractViewCanBeConstructed() {
        let view = TitleAttractView(presentation: .fixture)
        XCTAssertNotNil(view)
    }

    func testTitleMenuSceneCanBeConstructedWithContinueData() {
        let view = TitleMenuScene(
            props: .init(
                presentation: .fixture,
                entries: [
                    .init(id: "continue", label: "Continue", isEnabled: true),
                    .init(id: "newGame", label: "New Game", isEnabled: true),
                    .init(id: "options", label: "Options", isEnabled: true),
                ],
                saveMetadata: .init(
                    schemaVersion: 10,
                    variant: .red,
                    playthroughID: "fixture",
                    playerName: "RED",
                    locationName: "PALLET TOWN",
                    badgeCount: 1,
                    playTimeSeconds: 3723,
                    savedAt: "2026-03-19T12:00:00Z"
                ),
                focusedIndex: 0
            )
        )

        XCTAssertNotNil(view)
    }
}

private extension TitlePresentationProps {
    static let fixture = TitlePresentationProps(
        logoURL: URL(fileURLWithPath: "/tmp/pokemon_logo.png"),
        playerURL: URL(fileURLWithPath: "/tmp/player.png"),
        wordmarkURL: URL(fileURLWithPath: "/tmp/gamefreak_inc.png"),
        pokemonSpriteURL: URL(fileURLWithPath: "/tmp/charmander.png"),
        pokemonDisplayName: "Charmander",
        logoYOffset: 0,
        pokemonOffsetX: 0
    )
}
