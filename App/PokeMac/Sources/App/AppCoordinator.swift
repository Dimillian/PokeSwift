import AppKit
import Observation
import PokeContent
import PokeCore
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
    private var audioService: PokeAudioService?
    private let keyInputBridge = RuntimeKeyInputBridge()
    private var hasRequestedForegroundActivation = false
    private let preferences: AppPreferences

    init(preferences: AppPreferences) {
        self.preferences = preferences
        bootstrap()
    }

    func bootstrap() {
        guard runtime == nil, bootError == nil else { return }

        Task { @MainActor in
            do {
                let contentRoot = ContentLocator.defaultContentRoot()
                let content = try FileSystemContentLoader(rootURL: contentRoot).load()
                let telemetry = try TelemetryCoordinator(traceDirectoryURL: AppPaths.traceDirectory)
                let audioService = PokeAudioService(manifest: content.audioManifest)
                let saveStore = FileSystemSaveStore(saveURL: AppPaths.primarySaveURL)
                let runtime = GameRuntime(
                    content: content,
                    telemetryPublisher: telemetry,
                    audioPlayer: audioService,
                    saveStore: saveStore
                )
                preferences.attachRuntime(runtime)
                self.runtime = runtime
                self.telemetryCoordinator = telemetry
                self.audioService = audioService

                let server = try await telemetry.makeServer(
                    port: AppPaths.telemetryPort,
                    inputHandler: { [weak self] button in
                        await MainActor.run {
                            guard let runtime = self?.runtime else { return false }
                            runtime.handle(button: button)
                            return true
                        }
                    },
                    saveHandler: { [weak self] in
                        await MainActor.run {
                            self?.runtime?.saveCurrentGame() ?? false
                        }
                    },
                    loadHandler: { [weak self] in
                        await MainActor.run {
                            self?.runtime?.loadSavedGameFromSidebar() ?? false
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
                keyInputBridge.install { [weak self] in
                    self?.runtime
                }
                runtime.start()
            } catch {
                fputs("boot error: \(error.localizedDescription)\n", stderr)
                bootError = error.localizedDescription
            }
        }
    }

    func shutdown() {
        telemetryServer?.stop()
        audioService?.stopAllMusic()
        keyInputBridge.remove()
        preferences.attachRuntime(nil)
    }

    func toggleDebugPanel() {
        showDebugPanel.toggle()
    }

    func requestForegroundActivationIfNeeded() {
        guard AppPaths.validationMode == false, hasRequestedForegroundActivation == false else { return }

        hasRequestedForegroundActivation = true
        _ = NSRunningApplication.current.activate(options: [.activateAllWindows])
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first(where: \.canBecomeKey)?.makeKeyAndOrderFront(nil)
    }
}
