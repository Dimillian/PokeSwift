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

private final class RequestResultBox: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: Result<Data, Error>?

    func store(_ result: Result<Data, Error>) {
        lock.lock()
        storage = result
        lock.unlock()
    }

    func load() -> Result<Data, Error>? {
        lock.lock()
        let result = storage
        lock.unlock()
        return result
    }
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
        try run(["tuist", "generate", "--no-open"])
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

    private func launchApp(validationMode: Bool = false) throws {
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
        if validationMode {
            environment["POKESWIFT_VALIDATION_MODE"] = "1"
        }
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
        try launchApp(validationMode: true)
        _ = try poll(until: { $0.scene == .titleAttract }, timeout: 6)

        try postInput("start")
        let titleMenu = try poll(until: { $0.scene == .titleMenu }, timeout: 4)
        try assertAudio(titleMenu, trackID: "MUSIC_TITLE_SCREEN", reason: "title")

        guard let menu = titleMenu.titleMenu, menu.entries.count == 3 else {
            throw HarnessError.validationFailed("title menu did not expose the expected entries")
        }
        guard menu.entries[1].enabledByDefault == false else {
            throw HarnessError.validationFailed("continue should be disabled")
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

        try postInput("up")
        _ = try poll(until: { $0.scene == .titleMenu && $0.titleMenu?.focusedIndex == 0 }, timeout: 4)
        try postInput("confirm")
        var snapshot = try poll(until: { $0.scene == .field && $0.field?.mapID == "REDS_HOUSE_2F" }, timeout: 4)
        try assertRealFieldRendering(snapshot, expectedMapID: "REDS_HOUSE_2F")
        try assertAudio(snapshot, trackID: "MUSIC_PALLET_TOWN", reason: "mapDefault")

        snapshot = try walk(to: TilePoint(x: 6, y: 1), on: "REDS_HOUSE_2F", startingFrom: snapshot)
        try postInput("right")
        snapshot = try poll(until: { $0.scene == .field && $0.field?.mapID == "REDS_HOUSE_1F" }, timeout: 4)
        try assertRealFieldRendering(snapshot, expectedMapID: "REDS_HOUSE_1F")
        try assertAudio(snapshot, trackID: "MUSIC_PALLET_TOWN", reason: "mapDefault")
        snapshot = try walk(to: TilePoint(x: 3, y: 6), on: "REDS_HOUSE_1F", startingFrom: snapshot, yFirst: true)
        try postInput("down")
        snapshot = try poll(until: { $0.scene == .field && $0.field?.mapID == "PALLET_TOWN" }, timeout: 4)
        try assertRealFieldRendering(snapshot, expectedMapID: "PALLET_TOWN")
        try assertAudio(snapshot, trackID: "MUSIC_PALLET_TOWN", reason: "mapDefault")
        snapshot = try walk(to: TilePoint(x: 10, y: 2), on: "PALLET_TOWN", startingFrom: snapshot)
        try postInput("up")

        snapshot = try poll(until: { $0.scene == .dialogue && ($0.dialogue?.dialogueID.contains("oak") ?? false) }, timeout: 4)
        try assertAudio(snapshot, trackID: "MUSIC_MEET_PROF_OAK", reason: "scriptOverride")
        snapshot = try drainDialogues(startingFrom: snapshot, maxInteractions: 16)
        snapshot = try poll(until: { $0.field?.mapID == "OAKS_LAB" && ($0.eventFlags?.activeFlags.contains("EVENT_OAK_ASKED_TO_CHOOSE_MON") ?? false) }, timeout: 6)
        try assertRealFieldRendering(snapshot, expectedMapID: "OAKS_LAB")
        try assertAudio(snapshot, trackID: "MUSIC_OAKS_LAB", reason: "mapDefault")

        snapshot = try walk(to: TilePoint(x: 7, y: 4), on: "OAKS_LAB", startingFrom: snapshot, yFirst: true)
        try postInput("up")
        snapshot = try poll(until: {
            $0.scene == .field &&
            $0.field?.mapID == "OAKS_LAB" &&
            $0.field?.playerPosition == TilePoint(x: 7, y: 4) &&
            $0.field?.facing == .up
        }, timeout: 3)
        try postInput("confirm")
        snapshot = try poll(until: { $0.scene == .dialogue && $0.dialogue?.dialogueID == "oaks_lab_you_want_squirtle" }, timeout: 4)
        snapshot = try drainDialogues(startingFrom: snapshot, maxInteractions: 4)
        snapshot = try poll(until: { $0.scene == .starterChoice }, timeout: 4)
        while snapshot.starterChoice?.focusedIndex != 1 {
            try postInput("right")
            snapshot = try poll(until: { $0.scene == .starterChoice }, timeout: 2)
        }
        try postInput("confirm")
        snapshot = try poll(until: { $0.scene == .dialogue }, timeout: 4)
        snapshot = try drainDialogues(startingFrom: snapshot, maxInteractions: 16)
        snapshot = try poll(until: { $0.scene == .field && ($0.eventFlags?.activeFlags.contains("EVENT_GOT_STARTER") ?? false) }, timeout: 4)
        try assertRealFieldRendering(snapshot, expectedMapID: "OAKS_LAB")
        try assertAudio(snapshot, trackID: "MUSIC_OAKS_LAB", reason: "mapDefault")

        snapshot = try walk(to: TilePoint(x: 4, y: 6), on: "OAKS_LAB", startingFrom: snapshot)
        if snapshot.scene != .dialogue || snapshot.dialogue?.dialogueID != "oaks_lab_rival_ill_take_you_on" {
            snapshot = try poll(until: {
                $0.scene == .dialogue &&
                $0.dialogue?.dialogueID == "oaks_lab_rival_ill_take_you_on"
            }, timeout: 4)
        }
        try assertAudio(snapshot, trackID: "MUSIC_MEET_RIVAL", reason: "scriptOverride")
        snapshot = try drainDialogues(startingFrom: snapshot, maxInteractions: 6)
        snapshot = try poll(until: { $0.scene == .battle }, timeout: 4)
        try assertAudio(snapshot, trackID: "MUSIC_TRAINER_BATTLE", reason: "battle")

        var battleTurns = 0
        while snapshot.scene == .battle {
            guard let battle = snapshot.battle else {
                throw HarnessError.validationFailed("battle scene is active without battle telemetry")
            }
            if battle.phase == "moveSelection" && battle.moveSlots.isEmpty {
                throw HarnessError.validationFailed("battle move selection is missing move slot telemetry")
            }
            if (battle.phase == "introText" || battle.phase == "turnText") && battle.textLines.isEmpty {
                throw HarnessError.validationFailed("battle text phase is missing queued text telemetry")
            }

            let previousPhase = battle.phase
            let previousText = battle.textLines
            let previousEnemyIndex = battle.enemyActiveIndex
            try postInput("confirm")
            snapshot = try poll(until: { next in
                next.scene != .battle ||
                next.battle?.phase != previousPhase ||
                next.battle?.textLines != previousText ||
                next.battle?.enemyActiveIndex != previousEnemyIndex
            }, timeout: 4)
            if battle.phase == "moveSelection" {
                battleTurns += 1
                if battleTurns > 12 {
                    throw HarnessError.validationFailed("battle did not resolve within 12 turns")
                }
            }
        }

        snapshot = try poll(until: {
            $0.scene == .dialogue &&
            (
                $0.dialogue?.dialogueID == "oaks_lab_rival_i_picked_the_wrong_pokemon" ||
                $0.dialogue?.dialogueID == "oaks_lab_rival_am_i_great_or_what"
            )
        }, timeout: 4)
        let resultDialogueID = snapshot.dialogue?.dialogueID
        try postInput("confirm")
        snapshot = try poll(until: {
            $0.scene == .dialogue &&
            $0.dialogue?.dialogueID == "oaks_lab_rival_smell_you_later" &&
            $0.dialogue?.dialogueID != resultDialogueID
        }, timeout: 4)
        try assertAudio(snapshot, trackID: "MUSIC_MEET_RIVAL", reason: "scriptOverride", entryID: "alternateStart")

        snapshot = try drainDialogues(startingFrom: snapshot, maxInteractions: 12)
        snapshot = try poll(until: {
            $0.scene == .field &&
            $0.field?.mapID == "OAKS_LAB" &&
            ($0.eventFlags?.activeFlags.contains("EVENT_BATTLED_RIVAL_IN_OAKS_LAB") ?? false)
        }, timeout: 4)
        try assertRealFieldRendering(snapshot, expectedMapID: "OAKS_LAB")
        try assertAudio(snapshot, trackID: "MUSIC_OAKS_LAB", reason: "mapDefault")

        guard snapshot.party?.pokemon.count == 1 else {
            throw HarnessError.validationFailed("expected one starter in party after rival battle")
        }
        guard snapshot.assetLoadingFailures.isEmpty else {
            throw HarnessError.validationFailed("expected zero asset-loading failures, got: \(snapshot.assetLoadingFailures.joined(separator: ", "))")
        }

        try post(path: "/quit", body: [:])
        print("milestone validation passed")
    }

    private func assertRealFieldRendering(_ snapshot: RuntimeTelemetrySnapshot, expectedMapID: String) throws {
        guard snapshot.field?.mapID == expectedMapID else {
            throw HarnessError.validationFailed("expected field telemetry for \(expectedMapID), got \(snapshot.field?.mapID ?? "none")")
        }
        guard snapshot.field?.renderMode == "realAssets" else {
            throw HarnessError.validationFailed("expected renderMode=realAssets on \(expectedMapID), got \(snapshot.field?.renderMode ?? "none")")
        }
        guard snapshot.assetLoadingFailures.isEmpty else {
            throw HarnessError.validationFailed("asset-loading failures present on \(expectedMapID): \(snapshot.assetLoadingFailures.joined(separator: ", "))")
        }
    }

    private func assertAudio(
        _ snapshot: RuntimeTelemetrySnapshot,
        trackID: String,
        reason: String,
        entryID: String? = nil
    ) throws {
        guard let audio = snapshot.audio else {
            throw HarnessError.validationFailed("expected audio telemetry for \(trackID), but snapshot had none")
        }
        guard audio.trackID == trackID else {
            throw HarnessError.validationFailed("expected audio track \(trackID), got \(audio.trackID)")
        }
        guard audio.reason == reason else {
            throw HarnessError.validationFailed("expected audio reason \(reason) for \(trackID), got \(audio.reason)")
        }
        if let entryID, audio.entryID != entryID {
            throw HarnessError.validationFailed("expected audio entry \(entryID) for \(trackID), got \(audio.entryID)")
        }
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
        let retryDeadline = Date().addingTimeInterval(2.5)
        var lastError: Error?

        while true {
            var request = URLRequest(url: url)
            request.httpMethod = method
            if method == "POST" {
                request.httpBody = try JSONEncoder().encode(body)
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }

            let semaphore = DispatchSemaphore(value: 0)
            let resultBox = RequestResultBox()
            URLSession.shared.dataTask(with: request) { data, _, error in
                if let error {
                    resultBox.store(.failure(error))
                } else {
                    resultBox.store(.success(data ?? Data()))
                }
                semaphore.signal()
            }.resume()
            semaphore.wait()

            switch resultBox.load() {
            case let .success(data):
                return data
            case let .failure(error):
                lastError = error
                guard Date() < retryDeadline else {
                    throw HarnessError.requestFailed(String(describing: error))
                }
                Thread.sleep(forTimeInterval: 0.1)
            case .none:
                lastError = HarnessError.requestFailed("empty request result")
                guard Date() < retryDeadline else {
                    throw HarnessError.requestFailed("empty request result")
                }
                Thread.sleep(forTimeInterval: 0.1)
            }
        }

        throw HarnessError.requestFailed(String(describing: lastError ?? HarnessError.requestFailed("unknown request failure")))
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

    private func walk(
        to target: TilePoint,
        on mapID: String,
        startingFrom initialSnapshot: RuntimeTelemetrySnapshot,
        yFirst: Bool = false
    ) throws -> RuntimeTelemetrySnapshot {
        var snapshot = initialSnapshot
        var steps = 0
        while steps < 64 {
            guard let field = snapshot.field, field.mapID == mapID else {
                return snapshot
            }
            if field.playerPosition == target {
                return snapshot
            }

            let nextButton: String
            if yFirst {
                if field.playerPosition.y < target.y {
                    nextButton = "down"
                } else if field.playerPosition.y > target.y {
                    nextButton = "up"
                } else if field.playerPosition.x < target.x {
                    nextButton = "right"
                } else {
                    nextButton = "left"
                }
            } else {
                if field.playerPosition.x < target.x {
                    nextButton = "right"
                } else if field.playerPosition.x > target.x {
                    nextButton = "left"
                } else if field.playerPosition.y < target.y {
                    nextButton = "down"
                } else {
                    nextButton = "up"
                }
            }

            try postInput(nextButton)
            let previousPosition = field.playerPosition
            snapshot = try poll(until: {
                $0.scene != .field ||
                $0.field?.mapID != mapID ||
                $0.field?.playerPosition != previousPosition
            }, timeout: 3)
            steps += 1
        }
        throw HarnessError.validationFailed("failed to reach \(target.x),\(target.y) on \(mapID)")
    }

    private func drainDialogues(startingFrom initialSnapshot: RuntimeTelemetrySnapshot, maxInteractions: Int) throws -> RuntimeTelemetrySnapshot {
        var snapshot = initialSnapshot
        var interactions = 0
        while snapshot.scene == .dialogue {
            guard interactions < maxInteractions else {
                throw HarnessError.validationFailed("dialogue did not drain within \(maxInteractions) confirms")
            }
            let currentDialogueID = snapshot.dialogue?.dialogueID
            let currentPageIndex = snapshot.dialogue?.pageIndex
            try postInput("confirm")
            snapshot = try poll(until: {
                $0.scene != .dialogue ||
                $0.dialogue?.pageIndex != currentPageIndex ||
                $0.dialogue?.dialogueID != currentDialogueID
            }, timeout: 3)
            interactions += 1
        }
        return snapshot
    }
}

do {
    try HarnessCLI().run()
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
