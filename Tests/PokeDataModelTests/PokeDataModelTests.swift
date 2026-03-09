import XCTest
@testable import PokeDataModel

final class PokeDataModelTests: XCTestCase {
    func testRuntimeButtonRawValuesRemainStable() {
        XCTAssertEqual(RuntimeButton.confirm.rawValue, "confirm")
        XCTAssertEqual(RuntimeButton.start.rawValue, "start")
    }
}
