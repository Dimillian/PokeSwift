import XCTest
import PokeDataModel

final class ParserTests: XCTestCase {
    func testCharmapParserFindsEntries() throws {
        let file = try PokeExtractCLITestSupport.temporaryFile(contents: """
        ; section
        charmap "A", $80
        charmap "B", $81
        """)

        let manifest = try RedContentExtractor.parseCharmap(at: file)
        XCTAssertEqual(manifest.entries.count, 2)
        XCTAssertEqual(manifest.entries.first?.token, "A")
    }

    func testTitleBounceParserExtractsSteps() throws {
        let contents = """
        .TitleScreenPokemonLogoYScrolls:
        db -4,16
        db 3,4
        db 0
        .ScrollTitleScreenPokemonLogo:
        """

        let steps = try RedContentExtractor.parseLogoBounceSteps(from: contents)
        XCTAssertEqual(steps, [.init(yDelta: -4, frames: 16), .init(yDelta: 3, frames: 4)])
    }

    func testTitleScrollParserExtractsSpeedAndFramePairs() throws {
        let contents = """
        TitleScroll_In:
        db $a2, $94, $11, 0
        """

        let steps = try RedContentExtractor.parseTitleScrollInSteps(from: contents)
        XCTAssertEqual(steps, [.init(speed: 10, frames: 2), .init(speed: 9, frames: 4), .init(speed: 1, frames: 1)])
    }

    func testTitleMonPoolParserResolvesStarterAliases() throws {
        let contents = """
        TitleMons:
        IF DEF(_RED)
        db STARTER1
        db WEEDLE
        ENDC
        IF DEF(_BLUE)
        db STARTER2
        ENDC
        """

        let pool = try RedContentExtractor.parseTitleMonPool(
            from: contents,
            starterAliases: ["STARTER1": "CHARMANDER"],
            variant: .red
        )
        XCTAssertEqual(pool, ["CHARMANDER", "WEEDLE"])
    }
}
