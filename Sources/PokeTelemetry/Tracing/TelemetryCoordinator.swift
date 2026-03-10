import Foundation
import PokeDataModel

public actor TelemetryCoordinator: TelemetryPublisher {
    private let traceFileURL: URL
    private let encoder = JSONEncoder()
    private var latest: RuntimeTelemetrySnapshot?

    public init(traceDirectoryURL: URL) throws {
        try FileManager.default.createDirectory(at: traceDirectoryURL, withIntermediateDirectories: true)
        self.traceFileURL = traceDirectoryURL.appendingPathComponent("telemetry.jsonl")
        encoder.outputFormatting = [.sortedKeys]
        if FileManager.default.fileExists(atPath: traceFileURL.path) == false {
            FileManager.default.createFile(atPath: traceFileURL.path, contents: Data())
        }
    }

    public func publish(snapshot: RuntimeTelemetrySnapshot) async {
        latest = snapshot
        guard let data = try? encoder.encode(snapshot) else { return }
        do {
            let handle = try FileHandle(forWritingTo: traceFileURL)
            try handle.seekToEnd()
            try handle.write(contentsOf: data)
            try handle.write(contentsOf: Data("\n".utf8))
            try handle.close()
        } catch {
            // Keep runtime alive if trace writing fails.
        }
    }

    public func latestSnapshot() -> RuntimeTelemetrySnapshot? {
        latest
    }

    public func makeServer(
        port: UInt16,
        inputHandler: @escaping @Sendable (RuntimeButton) async -> Bool,
        quitHandler: @escaping @Sendable () async -> Void
    ) throws -> TelemetryControlServer {
        try TelemetryControlServer(
            port: port,
            snapshotProvider: { [coordinator = self] in
                await coordinator.latestSnapshot()
            },
            inputHandler: inputHandler,
            quitHandler: quitHandler
        )
    }
}
