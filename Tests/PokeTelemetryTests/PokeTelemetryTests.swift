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
            titleMenu: .init(entries: [.init(id: "newGame", label: "New Game", isEnabled: true)], focusedIndex: 0),
            field: nil,
            dialogue: nil,
            starterChoice: nil,
            party: nil,
            inventory: nil,
            battle: nil,
            eventFlags: nil,
            audio: nil,
            save: nil,
            recentInputEvents: [],
            assetLoadingFailures: [],
            window: .init(scale: 4, renderWidth: 160, renderHeight: 144)
        )
        await coordinator.publish(snapshot: snapshot)
        let latest = await coordinator.latestSnapshot()
        XCTAssertEqual(latest?.scene, .titleMenu)
    }

    func testCoordinatorWritesSessionEventsJSONL() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let coordinator = try TelemetryCoordinator(traceDirectoryURL: root)
        let event = RuntimeSessionEvent(
            timestamp: "2026-03-11T10:00:00Z",
            kind: .battleStarted,
            message: "Started wild battle.",
            scene: .battle,
            mapID: "ROUTE_1",
            battleID: "wild_route_1_pidgey_3",
            battleKind: .wild,
            details: ["enemySpecies": "PIDGEY"]
        )

        await coordinator.publish(event: event)

        let traceURL = root.appendingPathComponent("session_events.jsonl")
        let lines = try String(contentsOf: traceURL, encoding: .utf8)
            .split(separator: "\n")
        let payload = try XCTUnwrap(lines.last)
        let decoded = try JSONDecoder().decode(RuntimeSessionEvent.self, from: Data(payload.utf8))
        XCTAssertEqual(decoded, event)
    }
}
