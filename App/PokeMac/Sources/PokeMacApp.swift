import AppKit
import Observation
import SwiftUI
import PokeContent
import PokeCore
import PokeDataModel
import PokeTelemetry
import PokeUI

@MainActor
@Observable
final class AppCoordinator {
    private(set) var runtime: GameRuntime?
    private(set) var bootError: String?
    var showDebugPanel = false

    private var telemetryCoordinator: TelemetryCoordinator?
    private var telemetryServer: TelemetryControlServer?
    private var keyMonitor: Any?

    func bootstrap() {
        guard runtime == nil, bootError == nil else { return }

        Task { @MainActor in
            do {
                let contentRoot = ContentLocator.defaultContentRoot()
                let content = try FileSystemContentLoader(rootURL: contentRoot).load()
                let traceRoot = AppPaths.traceDirectory
                let telemetry = try TelemetryCoordinator(traceDirectoryURL: traceRoot)

                let runtime = GameRuntime(content: content, telemetryPublisher: telemetry)
                self.runtime = runtime
                self.telemetryCoordinator = telemetry

                let server = try await telemetry.makeServer(
                    port: AppPaths.telemetryPort,
                    inputHandler: { [weak self] button in
                        await MainActor.run {
                            guard let runtime = self?.runtime else {
                                return false
                            }
                            runtime.handle(button: button)
                            return true
                        }
                    },
                    quitHandler: {
                        await MainActor.run {
                            NSApp.terminate(nil)
                        }
                    }
                )
                server.start()
                telemetryServer = server
                installKeyMonitor()
                runtime.start()
            } catch {
                bootError = error.localizedDescription
            }
        }
    }

    func shutdown() {
        telemetryServer?.stop()
        removeKeyMonitor()
    }

    func toggleDebugPanel() {
        showDebugPanel.toggle()
    }

    private func installKeyMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, let runtime = self.runtime else { return event }
            guard let button = RuntimeButton(keyEvent: event, scene: runtime.scene) else {
                return event
            }
            runtime.handle(button: button)
            return nil
        }
    }

    private func removeKeyMonitor() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
    }
}

private enum AppPaths {
    static let telemetryPort: UInt16 = {
        if let raw = ProcessInfo.processInfo.environment["POKESWIFT_TELEMETRY_PORT"],
           let port = UInt16(raw) {
            return port
        }
        return 9_777
    }()

    static let traceDirectory: URL = {
        if let override = ProcessInfo.processInfo.environment["POKESWIFT_TRACE_DIR"] {
            return URL(fileURLWithPath: override, isDirectory: true)
        }
        return URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
            .appendingPathComponent(".runtime-traces/pokemac", isDirectory: true)
    }()
}

private extension RuntimeButton {
    init?(keyEvent: NSEvent, scene: RuntimeScene) {
        switch keyEvent.keyCode {
        case 126: self = .up
        case 125: self = .down
        case 123: self = .left
        case 124: self = .right
        case 36:
            self = scene == .titleAttract ? .start : .confirm
        case 49:
            self = .start
        case 53, 51:
            self = .cancel
        default:
            guard let first = keyEvent.charactersIgnoringModifiers?.lowercased().first else {
                return nil
            }
            switch first {
            case "z": self = .confirm
            case "x": self = .cancel
            case "s": self = .start
            case "d": return nil
            default: return nil
            }
        }
    }
}

struct RootView: View {
    @Bindable var coordinator: AppCoordinator

    var body: some View {
        Group {
            if let bootError = coordinator.bootError {
                ContentUnavailableView("Boot Failed", systemImage: "exclamationmark.triangle", description: Text(bootError))
            } else if let runtime = coordinator.runtime {
                RuntimeView(runtime: runtime)
            } else {
                GameBoyScreen {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Bootstrapping PokeMac")
                            .font(.headline)
                    }
                    .foregroundStyle(.black)
                }
            }
        }
        .frame(minWidth: 960, minHeight: 640)
        .toolbar {
            ToolbarItem {
                Button("Debug") {
                    coordinator.toggleDebugPanel()
                }
            }
        }
        .sheet(isPresented: $coordinator.showDebugPanel) {
            if let runtime = coordinator.runtime {
                DebugPanel(snapshot: runtime.currentSnapshot())
                    .padding(24)
                    .frame(minWidth: 520, minHeight: 320)
            }
        }
        .task {
            coordinator.bootstrap()
        }
        .onDisappear {
            coordinator.shutdown()
        }
    }
}

private struct RuntimeView: View {
    @Bindable var runtime: GameRuntime

    var body: some View {
        switch runtime.scene {
        case .launch:
            GameBoyScreen {
                Text("PokeMac")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(.black)
            }
        case .splash:
            SplashView(rootURL: runtime.content.rootURL)
        case .titleAttract:
            TitleAttractView(rootURL: runtime.content.rootURL)
        case .titleMenu:
            TitleMenuScene(runtime: runtime)
        case .placeholder:
            PlaceholderScene(runtime: runtime)
        }
    }
}

private struct SplashView: View {
    let rootURL: URL

    var body: some View {
        GameBoyScreen {
            VStack(spacing: 20) {
                PixelAssetView(url: assetURL("Assets/splash/falling_star.png"), label: "Falling Star")
                    .frame(width: 96, height: 96)
                PixelAssetView(url: assetURL("Assets/splash/gamefreak_logo.png"), label: "Game Freak")
                    .frame(width: 320, height: 160)
                PixelAssetView(url: assetURL("Assets/splash/gamefreak_presents.png"), label: "Game Freak Presents")
                    .frame(width: 320, height: 80)
                PixelAssetView(url: assetURL("Assets/splash/copyright.png"), label: "Copyright")
                    .frame(width: 360, height: 80)
            }
            .padding(40)
        }
    }

    private func assetURL(_ path: String) -> URL {
        rootURL.appendingPathComponent(path)
    }
}

private struct TitleAttractView: View {
    let rootURL: URL

    var body: some View {
        GameBoyScreen {
            TitleAttractContent(rootURL: rootURL)
        }
    }
}

private struct TitleAttractContent: View {
    let rootURL: URL

    var body: some View {
        VStack(spacing: 18) {
            PixelAssetView(url: assetURL("Assets/title/pokemon_logo.png"), label: "Pokemon Logo")
                .frame(width: 540, height: 220)
            HStack(spacing: 24) {
                PixelAssetView(url: assetURL("Assets/title/player.png"), label: "Red")
                    .frame(width: 200, height: 200)
                PlainWhitePanel {
                    VStack(spacing: 18) {
                        PixelAssetView(url: assetURL("Assets/title/red_version.png"), label: "Red Version")
                            .frame(width: 220, height: 90)
                        Text("Press Return or Space to Start")
                            .font(.system(.title3, design: .monospaced))
                            .foregroundStyle(.black)
                        Text("Z confirms, X cancels, arrows navigate")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.black.opacity(0.64))
                    }
                }
            }
            PixelAssetView(url: assetURL("Assets/title/gamefreak_inc.png"), label: "Game Freak Inc")
                .frame(width: 220, height: 80)
        }
        .padding(36)
    }

    private func assetURL(_ path: String) -> URL {
        rootURL.appendingPathComponent(path)
    }
}

private struct TitleMenuScene: View {
    @Bindable var runtime: GameRuntime

    var body: some View {
        GameBoyScreen {
            VStack(spacing: 26) {
                TitleAttractContent(rootURL: runtime.content.rootURL)
                    .frame(height: 420)
                TitleMenuPanel(entries: runtime.menuEntries, focusedIndex: runtime.focusedIndex)
                    .frame(width: 460)
            }
            .padding(30)
        }
    }
}

private struct PlaceholderScene: View {
    @Bindable var runtime: GameRuntime

    var body: some View {
        GameBoyScreen {
            GameBoyPanel {
                VStack(spacing: 16) {
                    Text(runtime.placeholderTitle ?? "Placeholder")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                    Text("This route is intentionally reserved for Milestone 3 and beyond.")
                        .foregroundStyle(.black.opacity(0.64))
                    Text("Press Escape or X to return to the title menu.")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.black.opacity(0.85))
                }
                .padding(22)
            }
            .frame(width: 580)
        }
    }
}

private struct DebugPanel: View {
    let snapshot: RuntimeTelemetrySnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Telemetry")
                .font(.title2.bold())
            Text("Scene: \(snapshot.scene.rawValue)")
            Text("Substate: \(snapshot.substate)")
            Text("Content: \(snapshot.contentVersion)")
            Text("Scale: \(snapshot.window.scale)x")
            if let titleMenu = snapshot.titleMenu {
                let safeIndex = max(0, min(titleMenu.focusedIndex, titleMenu.entries.count - 1))
                Text("Focused Entry: \(titleMenu.entries[safeIndex].label)")
            }
            Text("Recent Inputs")
                .font(.headline)
            ForEach(Array(snapshot.recentInputEvents.enumerated()), id: \.offset) { _, event in
                Text("\(event.timestamp)  \(event.button.rawValue)")
                    .font(.system(.body, design: .monospaced))
            }
            Spacer()
        }
    }
}

@main
struct PokeMacApp: App {
    @State private var coordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            RootView(coordinator: coordinator)
        }
        .commands {
            CommandMenu("PokeMac") {
                Button("Toggle Debug Panel") {
                    coordinator.toggleDebugPanel()
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])
            }
        }
    }
}
