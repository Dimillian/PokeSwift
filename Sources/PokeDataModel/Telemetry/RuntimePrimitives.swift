import Foundation

public enum RuntimeScene: String, Codable, Sendable {
    case launch
    case splash
    case titleAttract
    case titleMenu
    case field
    case dialogue
    case scriptedSequence
    case starterChoice
    case battle
    case evolution
    case naming
    case oakIntro
    case titleOptions
    case placeholder
}

public enum RuntimeButton: String, Codable, Sendable, CaseIterable {
    case up
    case down
    case left
    case right
    case confirm
    case cancel
    case start
}

public struct InputEventTelemetry: Codable, Equatable, Sendable {
    public let button: RuntimeButton
    public let timestamp: String

    public init(button: RuntimeButton, timestamp: String) {
        self.button = button
        self.timestamp = timestamp
    }
}

public struct WindowTelemetry: Codable, Equatable, Sendable {
    public let scale: Int
    public let renderWidth: Int
    public let renderHeight: Int

    public init(scale: Int, renderWidth: Int, renderHeight: Int) {
        self.scale = scale
        self.renderWidth = renderWidth
        self.renderHeight = renderHeight
    }
}
