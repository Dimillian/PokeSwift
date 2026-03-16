import AppKit
import Observation
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
                    mapProvider: { [weak self] in
                        await MainActor.run {
                            guard let runtime = self?.runtime,
                                  let map = runtime.currentMapManifest,
                                  let tileset = runtime.content.tileset(id: map.tileset) else {
                                return nil
                            }
                            let passable = Set(tileset.collision.passableTileIDs)
                            let walkable = map.stepCollisionTileIDs.map { passable.contains($0) }
                            return MapStateTelemetry(
                                mapID: map.id,
                                displayName: map.displayName,
                                stepWidth: map.stepWidth,
                                stepHeight: map.stepHeight,
                                walkable: walkable,
                                warps: map.warps.map {
                                    MapWarpTelemetry(id: $0.id, origin: $0.origin, targetMapID: $0.targetMapID, targetPosition: $0.targetPosition, targetFacing: $0.targetFacing)
                                },
                                connections: map.connections.map {
                                    MapConnectionTelemetry(direction: $0.direction, targetMapID: $0.targetMapID)
                                },
                                signs: map.backgroundEvents.map {
                                    MapSignTelemetry(position: $0.position, dialogueID: $0.dialogueID)
                                }
                            )
                        }
                    },
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
