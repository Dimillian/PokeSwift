import Foundation
import Observation
import PokeContent
import PokeDataModel
import PokeTelemetry

@MainActor
@Observable
public final class GameRuntime {
    public let content: LoadedContent

    public private(set) var scene: RuntimeScene = .launch
    public private(set) var focusedIndex = 0
    public private(set) var placeholderTitle: String?

    private let telemetryPublisher: (any TelemetryPublisher)?
    private var substate = "launching"
    private var recentInputEvents: [InputEventTelemetry] = []
    private var assetLoadingFailures: [String]
    private var windowScale = 4
    private var transitionTask: Task<Void, Never>?
    private var hasStarted = false

    public init(content: LoadedContent, telemetryPublisher: (any TelemetryPublisher)?) {
        self.content = content
        self.telemetryPublisher = telemetryPublisher
        self.assetLoadingFailures = Self.missingAssets(in: content)
    }

    public var menuEntries: [TitleMenuEntry] {
        content.titleManifest.menuEntries
    }

    public func start() {
        guard hasStarted == false else { return }
        hasStarted = true
        focusedIndex = 0
        scene = .launch
        substate = "launching"
        publishSnapshot()
        scheduleTitleFlow()
    }

    public func handle(button: RuntimeButton) {
        record(button: button)

        switch scene {
        case .launch, .splash:
            break
        case .titleAttract:
            if button == .start || button == .confirm {
                scene = .titleMenu
                substate = "title_menu"
                focusedIndex = 0
                placeholderTitle = nil
            }
        case .titleMenu:
            handleTitleMenu(button: button)
        case .placeholder:
            if button == .cancel {
                scene = .titleMenu
                substate = "title_menu"
                placeholderTitle = nil
            }
        }

        publishSnapshot()
    }

    public func updateWindowScale(_ scale: Int) {
        windowScale = max(1, scale)
        publishSnapshot()
    }

    public func currentSnapshot() -> RuntimeTelemetrySnapshot {
        RuntimeTelemetrySnapshot(
            appVersion: "0.1.0",
            contentVersion: content.gameManifest.contentVersion,
            scene: scene,
            substate: substate,
            titleMenu: scene == .titleMenu ? TitleMenuTelemetry(entries: menuEntries, focusedIndex: focusedIndex) : nil,
            recentInputEvents: recentInputEvents,
            assetLoadingFailures: assetLoadingFailures,
            window: .init(scale: windowScale, renderWidth: 160, renderHeight: 144)
        )
    }

    private func handleTitleMenu(button: RuntimeButton) {
        switch button {
        case .up:
            focusedIndex = (focusedIndex - 1 + menuEntries.count) % menuEntries.count
            substate = "title_menu"
        case .down:
            focusedIndex = (focusedIndex + 1) % menuEntries.count
            substate = "title_menu"
        case .confirm, .start:
            let selected = menuEntries[focusedIndex]
            guard selected.enabled else {
                substate = "continue_disabled"
                return
            }
            placeholderTitle = selected.label
            substate = selected.id
            scene = .placeholder
        case .cancel:
            scene = .titleAttract
            substate = "attract"
        case .left, .right:
            break
        }
    }

    private func scheduleTitleFlow() {
        transitionTask?.cancel()
        let timings = content.titleManifest.timings
        transitionTask = Task { [weak self] in
            let launchDelay = UInt64(max(0.1, timings.launchFadeSeconds) * 1_000_000_000)
            let splashDelay = UInt64(max(0.1, timings.splashDurationSeconds) * 1_000_000_000)

            try? await Task.sleep(nanoseconds: launchDelay)
            guard Task.isCancelled == false else { return }
            await MainActor.run {
                guard let self else { return }
                self.scene = .splash
                self.substate = "splash"
                self.publishSnapshot()
            }

            try? await Task.sleep(nanoseconds: splashDelay)
            guard Task.isCancelled == false else { return }
            await MainActor.run {
                guard let self else { return }
                self.scene = .titleAttract
                self.substate = "attract"
                self.publishSnapshot()
            }
        }
    }

    private func record(button: RuntimeButton) {
        recentInputEvents.append(.init(button: button, timestamp: Self.timestamp()))
        if recentInputEvents.count > 12 {
            recentInputEvents.removeFirst(recentInputEvents.count - 12)
        }
    }

    private func publishSnapshot() {
        guard let telemetryPublisher else { return }
        let snapshot = currentSnapshot()
        Task {
            await telemetryPublisher.publish(snapshot: snapshot)
        }
    }

    private static func timestamp() -> String {
        ISO8601DateFormatter().string(from: Date())
    }

    private static func missingAssets(in content: LoadedContent) -> [String] {
        content.titleManifest.assets.compactMap { asset in
            let url = content.rootURL.appendingPathComponent(asset.relativePath)
            return FileManager.default.fileExists(atPath: url.path) ? nil : asset.relativePath
        }
    }
}
