import Foundation
import PokeDataModel

public actor TelemetryCoordinator: TelemetryPublisher {
    private let traceFileURL: URL
    private let sessionEventFileURL: URL
    private let encoder = JSONEncoder()
    private var latest: RuntimeTelemetrySnapshot?

    public init(traceDirectoryURL: URL) throws {
        try FileManager.default.createDirectory(at: traceDirectoryURL, withIntermediateDirectories: true)
        self.traceFileURL = traceDirectoryURL.appendingPathComponent("telemetry.jsonl")
        self.sessionEventFileURL = traceDirectoryURL.appendingPathComponent("session_events.jsonl")
        encoder.outputFormatting = [.sortedKeys]
        Self.createTraceFileIfNeeded(at: traceFileURL)
        Self.createTraceFileIfNeeded(at: sessionEventFileURL)
    }

    public func publish(snapshot: RuntimeTelemetrySnapshot) async {
        latest = snapshot
        writeJSONLine(snapshot, to: traceFileURL)
    }

    public func publish(event: RuntimeSessionEvent) async {
        writeJSONLine(event, to: sessionEventFileURL)
    }

    public func latestSnapshot() -> RuntimeTelemetrySnapshot? {
        latest
    }

    public func makeServer(
        port: UInt16,
        inputHandler: @escaping @Sendable (RuntimeButton) async -> Bool,
        saveHandler: @escaping @Sendable () async -> Bool,
        loadHandler: @escaping @Sendable () async -> Bool,
        quitHandler: @escaping @Sendable () async -> Void
    ) throws -> TelemetryControlServer {
        try TelemetryControlServer(
            port: port,
            snapshotProvider: { [coordinator = self] in
                await coordinator.latestSnapshot()
            },
            inputHandler: inputHandler,
            saveHandler: saveHandler,
            loadHandler: loadHandler,
            quitHandler: quitHandler
        )
    }

    private nonisolated static func createTraceFileIfNeeded(at url: URL) {
        if FileManager.default.fileExists(atPath: url.path) == false {
            FileManager.default.createFile(atPath: url.path, contents: Data())
        }
    }

    private func writeJSONLine<T: Encodable>(_ value: T, to url: URL) {
        guard let data = try? encoder.encode(value) else { return }
        do {
            let handle = try FileHandle(forWritingTo: url)
            try handle.seekToEnd()
            try handle.write(contentsOf: data)
            try handle.write(contentsOf: Data("\n".utf8))
            try handle.close()
        } catch {
            // Keep runtime alive if trace writing fails.
        }
    }
}
