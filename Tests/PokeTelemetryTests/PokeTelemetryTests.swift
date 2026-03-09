import Foundation
import XCTest
@testable import PokeTelemetry
import PokeDataModel

final class PokeTelemetryTests: XCTestCase {
    func testCoordinatorKeepsLatestSnapshot() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let coordinator = try TelemetryCoordinator(traceDirectoryURL: root)
        let snapshot = RuntimeTelemetrySnapshot(
            appVersion: "0.1.0",
            contentVersion: "test",
            scene: .titleMenu,
            substate: "selection",
            titleMenu: .init(entries: [.init(id: "newGame", label: "New Game", enabledByDefault: true)], focusedIndex: 0),
            recentInputEvents: [],
            assetLoadingFailures: [],
            window: .init(scale: 4, renderWidth: 160, renderHeight: 144)
        )
        await coordinator.publish(snapshot: snapshot)
        let latest = await coordinator.latestSnapshot()
        XCTAssertEqual(latest?.scene, .titleMenu)
    }
}
