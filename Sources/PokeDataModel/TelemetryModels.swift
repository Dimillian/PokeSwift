import Foundation

public enum RuntimeScene: String, Codable, Sendable {
    case launch
    case splash
    case titleAttract
    case titleMenu
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

public struct TitleMenuTelemetry: Codable, Equatable, Sendable {
    public let entries: [TitleMenuEntry]
    public let focusedIndex: Int

    public init(entries: [TitleMenuEntry], focusedIndex: Int) {
        self.entries = entries
        self.focusedIndex = focusedIndex
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

public struct RuntimeTelemetrySnapshot: Codable, Equatable, Sendable {
    public let appVersion: String
    public let contentVersion: String
    public let scene: RuntimeScene
    public let substate: String
    public let titleMenu: TitleMenuTelemetry?
    public let recentInputEvents: [InputEventTelemetry]
    public let assetLoadingFailures: [String]
    public let window: WindowTelemetry

    public init(
        appVersion: String,
        contentVersion: String,
        scene: RuntimeScene,
        substate: String,
        titleMenu: TitleMenuTelemetry?,
        recentInputEvents: [InputEventTelemetry],
        assetLoadingFailures: [String],
        window: WindowTelemetry
    ) {
        self.appVersion = appVersion
        self.contentVersion = contentVersion
        self.scene = scene
        self.substate = substate
        self.titleMenu = titleMenu
        self.recentInputEvents = recentInputEvents
        self.assetLoadingFailures = assetLoadingFailures
        self.window = window
    }
}

public protocol TelemetryPublisher: Sendable {
    func publish(snapshot: RuntimeTelemetrySnapshot) async
}
