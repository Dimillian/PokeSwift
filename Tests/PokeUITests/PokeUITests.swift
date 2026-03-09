import XCTest
@testable import PokeUI
import PokeDataModel

final class PokeUITests: XCTestCase {
    func testTitleMenuPanelCanBeConstructed() {
        let view = TitleMenuPanel(entries: [.init(id: "newGame", label: "New Game", enabledByDefault: true)], focusedIndex: 0)
        XCTAssertNotNil(view)
    }
}
