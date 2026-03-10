import AppKit
import Observation
import PokeContent
import PokeCore
import PokeTelemetry

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

    init() {
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
                let runtime = GameRuntime(content: content, telemetryPublisher: telemetry, audioPlayer: audioService)
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
                bootError = error.localizedDescription
            }
        }
    }

    func shutdown() {
        telemetryServer?.stop()
        audioService?.stopAllMusic()
        keyInputBridge.remove()
    }

    func toggleDebugPanel() {
        showDebugPanel.toggle()
    }
}
