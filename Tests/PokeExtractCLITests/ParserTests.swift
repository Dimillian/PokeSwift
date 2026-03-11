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
}
