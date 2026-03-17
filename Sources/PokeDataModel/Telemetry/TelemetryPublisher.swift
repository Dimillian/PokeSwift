import Foundation

public protocol TelemetryPublisher: Sendable {
    func publish(snapshot: RuntimeTelemetrySnapshot) async
    func publish(event: RuntimeSessionEvent) async
}

public extension TelemetryPublisher {
    func publish(event: RuntimeSessionEvent) async {}
}
