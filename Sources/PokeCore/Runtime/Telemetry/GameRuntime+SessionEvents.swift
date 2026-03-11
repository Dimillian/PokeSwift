import Foundation
import PokeDataModel

extension GameRuntime {
    func traceEvent(
        _ kind: RuntimeSessionEventKind,
        _ message: String,
        mapID: String? = nil,
        scriptID: String? = nil,
        dialogueID: String? = nil,
        battleID: String? = nil,
        battleKind: BattleKind? = nil,
        details: [String: String] = [:]
    ) {
        guard let telemetryPublisher else { return }
        let event = RuntimeSessionEvent(
            timestamp: Self.timestampFormatter.string(from: Date()),
            kind: kind,
            message: message,
            scene: scene,
            mapID: mapID ?? gameplayState?.mapID,
            scriptID: scriptID ?? gameplayState?.activeScriptID,
            dialogueID: dialogueID ?? dialogueState?.dialogueID,
            battleID: battleID ?? gameplayState?.battle?.battleID,
            battleKind: battleKind ?? gameplayState?.battle?.kind,
            details: details
        )
        Task {
            await telemetryPublisher.publish(event: event)
        }
    }
}
