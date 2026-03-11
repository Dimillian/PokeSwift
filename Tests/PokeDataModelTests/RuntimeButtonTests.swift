import XCTest
@testable import PokeDataModel

final class RuntimeButtonTests: XCTestCase {
    func testRuntimeButtonRawValuesRemainStable() {
        XCTAssertEqual(RuntimeButton.confirm.rawValue, "confirm")
        XCTAssertEqual(RuntimeButton.start.rawValue, "start")
    }
}
