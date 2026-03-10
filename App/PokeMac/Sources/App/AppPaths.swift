import Foundation

enum AppPaths {
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
