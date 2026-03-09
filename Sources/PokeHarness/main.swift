import Foundation
import PokeDataModel

private enum HarnessError: Error, CustomStringConvertible {
    case invalidArguments(String)
    case requestFailed(String)
    case validationFailed(String)

    var description: String {
        switch self {
        case let .invalidArguments(message), let .requestFailed(message), let .validationFailed(message):
            return message
        }
    }
}

private struct BooleanResponse: Decodable {
    let accepted: Bool
}

private struct HarnessCLI {
    let repoRoot: URL
    let derivedData: URL
    let traceDirectory: URL
    let port: Int

    init() {
        repoRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
        derivedData = repoRoot.appendingPathComponent(".build/DerivedData", isDirectory: true)
        traceDirectory = repoRoot.appendingPathComponent(".runtime-traces/pokemac", isDirectory: true)
        port = Int(ProcessInfo.processInfo.environment["POKESWIFT_TELEMETRY_PORT"] ?? "9777") ?? 9777
    }

    func run() throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        guard let command = arguments.first else {
            throw HarnessError.invalidArguments("usage: PokeHarness <build|launch|latest|input|quit|validate>")
        }

        switch command {
        case "build":
            try runBuild()
        case "launch":
            try launchApp()
        case "latest":
            let snapshot = try latestSnapshot()
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(snapshot)
            FileHandle.standardOutput.write(data)
            FileHandle.standardOutput.write(Data("\n".utf8))
        case "input":
            guard let button = arguments.dropFirst().first else {
                throw HarnessError.invalidArguments("usage: PokeHarness input <up|down|confirm|cancel|start>")
            }
            try post(path: "/input", body: ["button": button])
        case "quit":
            try post(path: "/quit", body: [:])
        case "validate":
            try validate()
        default:
            throw HarnessError.invalidArguments("unknown command: \(command)")
        }
    }

    private func runBuild() throws {
        try run(["tuist", "generate"])
        try run([
            "xcodebuild",
            "-workspace", "PokeSwift.xcworkspace",
            "-scheme", "PokeMac",
            "-configuration", "Debug",
            "-derivedDataPath", derivedData.path,
            "build",
        ])
        try run([
            "xcodebuild",
            "-workspace", "PokeSwift.xcworkspace",
            "-scheme", "PokeExtractCLI",
            "-configuration", "Debug",
            "-derivedDataPath", derivedData.path,
            "build",
        ])
        try run([
            "xcodebuild",
            "-workspace", "PokeSwift.xcworkspace",
            "-scheme", "PokeHarness",
            "-configuration", "Debug",
            "-derivedDataPath", derivedData.path,
            "build",
        ])
    }

    private func launchApp() throws {
        let appBinary = derivedData
            .appendingPathComponent("Build/Products/Debug/PokeMac.app/Contents/MacOS/PokeMac")

        guard FileManager.default.fileExists(atPath: appBinary.path) else {
            throw HarnessError.requestFailed("PokeMac binary not found. Run build first.")
        }

        try FileManager.default.createDirectory(at: traceDirectory, withIntermediateDirectories: true, attributes: nil)
        try Data().write(to: traceDirectory.appendingPathComponent("telemetry.jsonl"), options: .atomic)

        let process = Process()
        process.currentDirectoryURL = repoRoot
        process.executableURL = appBinary
        var environment = ProcessInfo.processInfo.environment
        environment["POKESWIFT_CONTENT_ROOT"] = repoRoot.appendingPathComponent("Content/Red", isDirectory: true).path
        environment["POKESWIFT_TRACE_DIR"] = traceDirectory.path
        environment["POKESWIFT_TELEMETRY_PORT"] = String(port)
        process.environment = environment

        let outputURL = traceDirectory.appendingPathComponent("app.log")
        if FileManager.default.fileExists(atPath: outputURL.path) == false {
            FileManager.default.createFile(atPath: outputURL.path, contents: Data())
        }
        let handle = try FileHandle(forWritingTo: outputURL)
        try handle.seekToEnd()
        process.standardOutput = handle
        process.standardError = handle
        try process.run()
        try Data("\(process.processIdentifier)".utf8).write(to: traceDirectory.appendingPathComponent("app.pid"))
        print("launched PokeMac pid \(process.processIdentifier)")
    }

    private func validate() throws {
        try? post(path: "/quit", body: [:])
        Thread.sleep(forTimeInterval: 0.5)
        try launchApp()
        _ = try poll(until: { $0.scene == .titleAttract }, timeout: 6)

        try postInput("start")
        let titleMenu = try poll(until: { $0.scene == .titleMenu }, timeout: 4)

        guard let menu = titleMenu.titleMenu, menu.entries.count == 3 else {
            throw HarnessError.validationFailed("title menu did not expose the expected entries")
        }
        guard menu.entries[1].enabledByDefault == false else {
            throw HarnessError.validationFailed("continue should be disabled in milestone 2")
        }

        try postInput("down")
        let blockedSnapshot = try poll(until: { snapshot in
            snapshot.scene == .titleMenu && snapshot.titleMenu?.focusedIndex == 1
        }, timeout: 4)
        guard blockedSnapshot.titleMenu?.focusedIndex == 1 else {
            throw HarnessError.validationFailed("failed to move focus to Continue")
        }

        try postInput("confirm")
        let stillBlocked = try poll(until: { snapshot in
            snapshot.scene == .titleMenu && snapshot.substate.contains("continue")
        }, timeout: 4)
        guard stillBlocked.scene == .titleMenu else {
            throw HarnessError.validationFailed("disabled continue should not leave the title menu")
        }
        guard stillBlocked.substate.contains("continue") else {
            throw HarnessError.validationFailed("disabled continue did not surface a blocked substate")
        }

        try postInput("down")
        let optionsFocus = try poll(until: { snapshot in
            snapshot.scene == .titleMenu && snapshot.titleMenu?.focusedIndex == 2
        }, timeout: 4)
        guard optionsFocus.titleMenu?.focusedIndex == 2 else {
            throw HarnessError.validationFailed("failed to move focus to Options")
        }
        try postInput("confirm")
        let placeholder = try poll(until: { $0.scene == .placeholder && $0.substate == "options" }, timeout: 4)
        guard placeholder.scene == .placeholder, placeholder.substate == "options" else {
            throw HarnessError.validationFailed("options did not route to placeholder")
        }
        try postInput("cancel")
        let returned = try poll(until: { $0.scene == .titleMenu }, timeout: 4)
        guard returned.scene == .titleMenu else {
            throw HarnessError.validationFailed("cancel did not return to the title menu")
        }

        try post(path: "/quit", body: [:])
        print("milestone 2 validation passed")
    }

    private func latestSnapshot() throws -> RuntimeTelemetrySnapshot {
        let decoder = JSONDecoder()

        if let data = try? request(path: "/telemetry/latest", method: "GET"),
           let snapshot = try? decoder.decode(RuntimeTelemetrySnapshot.self, from: data) {
            return snapshot
        }

        let traceURL = traceDirectory.appendingPathComponent("telemetry.jsonl")
        let data = try Data(contentsOf: traceURL)
        let lines = String(decoding: data, as: UTF8.self)
            .split(separator: "\n")
        guard let latestLine = lines.last else {
            throw HarnessError.validationFailed("no telemetry snapshot available")
        }
        return try decoder.decode(RuntimeTelemetrySnapshot.self, from: Data(latestLine.utf8))
    }

    private func poll(until predicate: (RuntimeTelemetrySnapshot) -> Bool, timeout: TimeInterval) throws -> RuntimeTelemetrySnapshot {
        let deadline = Date().addingTimeInterval(timeout)
        var latestSeen: RuntimeTelemetrySnapshot?
        while Date() < deadline {
            if let snapshot = try? latestSnapshot() {
                latestSeen = snapshot
                if predicate(snapshot) {
                    return snapshot
                }
            }
            Thread.sleep(forTimeInterval: 0.15)
        }
        if let latestSeen {
            let focus = latestSeen.titleMenu.map { String($0.focusedIndex) } ?? "n/a"
            throw HarnessError.validationFailed("timed out waiting for expected telemetry state; last snapshot scene=\(latestSeen.scene.rawValue) substate=\(latestSeen.substate) focus=\(focus)")
        }
        throw HarnessError.validationFailed("timed out waiting for expected telemetry state; no snapshot available")
    }

    private func postInput(_ button: String) throws {
        let data = try request(path: "/input", method: "POST", body: ["button": button])
        if let response = try? JSONDecoder().decode(BooleanResponse.self, from: data), response.accepted {
            return
        }
        throw HarnessError.requestFailed("input '\(button)' was not accepted")
    }

    private func post(path: String, body: [String: String]) throws {
        _ = try request(path: path, method: "POST", body: body)
    }

    private func request(path: String, method: String, body: [String: String] = [:]) throws -> Data {
        guard let url = URL(string: "http://127.0.0.1:\(port)\(path)") else {
            throw HarnessError.requestFailed("invalid url")
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        if method == "POST" {
            request.httpBody = try JSONEncoder().encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let semaphore = DispatchSemaphore(value: 0)
        var result: Result<Data, Error>?
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error {
                result = .failure(error)
            } else {
                result = .success(data ?? Data())
            }
            semaphore.signal()
        }.resume()
        semaphore.wait()

        switch result {
        case let .success(data):
            return data
        case let .failure(error):
            throw HarnessError.requestFailed(String(describing: error))
        case .none:
            throw HarnessError.requestFailed("empty request result")
        }
    }

    private func run(_ arguments: [String]) throws {
        let process = Process()
        process.currentDirectoryURL = repoRoot
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = arguments
        process.standardOutput = FileHandle.standardOutput
        process.standardError = FileHandle.standardError
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus != 0 {
            throw HarnessError.requestFailed("command failed: \(arguments.joined(separator: " "))")
        }
    }
}

do {
    try HarnessCLI().run()
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
