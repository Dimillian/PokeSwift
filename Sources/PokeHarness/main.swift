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
    let legacyHarnessSaveRoot: URL
    let validationSaveRoot: URL
    let defaultSaveRoot: URL
    let port: Int

    init() {
        repoRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
        derivedData = repoRoot.appendingPathComponent(".build/DerivedData", isDirectory: true)
        traceDirectory = repoRoot.appendingPathComponent(".runtime-traces/pokemac", isDirectory: true)
        legacyHarnessSaveRoot = traceDirectory.appendingPathComponent("saves", isDirectory: true)
        validationSaveRoot = traceDirectory.appendingPathComponent("validation-saves", isDirectory: true)
        defaultSaveRoot = Self.resolveDefaultSaveRoot(traceDirectory: traceDirectory)
        port = Int(ProcessInfo.processInfo.environment["POKESWIFT_TELEMETRY_PORT"] ?? "9777") ?? 9777
    }

    func run() throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        guard let command = arguments.first else {
            throw HarnessError.invalidArguments("usage: PokeHarness <build|launch|latest|input|save|load|quit|validate|validate-m3>")
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
        case "save":
            try post(path: "/save", body: [:])
        case "load":
            try post(path: "/load", body: [:])
        case "quit":
            try post(path: "/quit", body: [:])
        case "validate":
            try validateMilestone()
        case "validate-m3":
            try validateM3()
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

    private func launchApp(validationMode: Bool = false, saveRootOverride: URL? = nil) throws {
        let appBinary = derivedData
            .appendingPathComponent("Build/Products/Debug/PokeMac.app/Contents/MacOS/PokeMac")

        guard FileManager.default.fileExists(atPath: appBinary.path) else {
            throw HarnessError.requestFailed("PokeMac binary not found. Run build first.")
        }

        try FileManager.default.createDirectory(at: traceDirectory, withIntermediateDirectories: true, attributes: nil)
        try Data().write(to: traceDirectory.appendingPathComponent("telemetry.jsonl"), options: .atomic)
        try Data().write(to: traceDirectory.appendingPathComponent("session_events.jsonl"), options: .atomic)

        let process = Process()
        process.currentDirectoryURL = repoRoot
        process.executableURL = appBinary
        var environment = ProcessInfo.processInfo.environment
        if saveRootOverride == nil {
            try migrateLegacyHarnessSaveIfNeeded()
        }
        environment["POKESWIFT_CONTENT_ROOT"] = repoRoot.appendingPathComponent("Content/Red", isDirectory: true).path
        environment["POKESWIFT_TRACE_DIR"] = traceDirectory.path
        environment["POKESWIFT_TELEMETRY_PORT"] = String(port)
        if let saveRootOverride {
            environment["POKESWIFT_SAVE_ROOT"] = saveRootOverride.path
        } else {
            environment.removeValue(forKey: "POKESWIFT_SAVE_ROOT")
        }
        if validationMode {
            environment["POKESWIFT_VALIDATION_MODE"] = "1"
        }
        process.environment = environment

        let outputURL = traceDirectory.appendingPathComponent("app.log")
        try Data().write(to: outputURL, options: .atomic)
        let handle = try FileHandle(forWritingTo: outputURL)
        try handle.seekToEnd()
        process.standardOutput = handle
        process.standardError = handle
        try process.run()
        try Data("\(process.processIdentifier)".utf8).write(to: traceDirectory.appendingPathComponent("app.pid"))
        print("launched PokeMac pid \(process.processIdentifier)")
    }

    private func validateMilestone() throws {
        try validateM3()
        print("intro smoke validation passed")
    }

    private func validateM3() throws {
        try resetValidationState()
        _ = try runNewGameToPostRivalBattle()
        print("milestone M3 intro smoke passed")
    }

    private func resetValidationState() throws {
        try? post(path: "/quit", body: [:])
        Thread.sleep(forTimeInterval: 0.5)
        try? FileManager.default.removeItem(at: validationSaveRoot)
        try launchApp(validationMode: true, saveRootOverride: validationSaveRoot)
    }

    private func migrateLegacyHarnessSaveIfNeeded() throws {
        let legacySaveURL = legacyHarnessSaveRoot
            .appendingPathComponent("red-main", isDirectory: false)
            .appendingPathExtension("json")
        let defaultSaveURL = defaultSaveRoot
            .appendingPathComponent("red-main", isDirectory: false)
            .appendingPathExtension("json")

        guard FileManager.default.fileExists(atPath: legacySaveURL.path) else { return }
        guard FileManager.default.fileExists(atPath: defaultSaveURL.path) == false else { return }

        try FileManager.default.createDirectory(at: defaultSaveRoot, withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: legacySaveURL, to: defaultSaveURL)
    }

    private static func resolveDefaultSaveRoot(traceDirectory: URL) -> URL {
        if let applicationSupport = try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) {
            return applicationSupport
                .appendingPathComponent("PokeSwift", isDirectory: true)
                .appendingPathComponent("Saves", isDirectory: true)
        }

        return traceDirectory.appendingPathComponent("saves", isDirectory: true)
    }

    private func runNewGameToPostRivalBattle() throws -> RuntimeTelemetrySnapshot {
        _ = try poll(until: { $0.scene == .titleAttract }, timeout: 6)
        print("validate: title ready")

        try postInput("start")
        let titleMenu = try poll(until: { $0.scene == .titleMenu }, timeout: 4)
        try assertAudio(titleMenu, trackID: "MUSIC_TITLE_SCREEN", reason: "title")

        guard let menu = titleMenu.titleMenu, menu.entries.count == 3 else {
            throw HarnessError.validationFailed("title menu did not expose the expected entries")
        }
        guard menu.entries[1].isEnabled == false else {
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
        print("validate: new game started")

        snapshot = try walk(to: TilePoint(x: 6, y: 1), on: "REDS_HOUSE_2F", startingFrom: snapshot)
        try postInput("right")
        snapshot = try waitForSettledField(on: "REDS_HOUSE_1F", timeout: 4)
        try assertRealFieldRendering(snapshot, expectedMapID: "REDS_HOUSE_1F")
        try assertAudio(snapshot, trackID: "MUSIC_PALLET_TOWN", reason: "mapDefault")
        snapshot = try walk(to: TilePoint(x: 4, y: 1), on: "REDS_HOUSE_1F", startingFrom: snapshot)
        snapshot = try walk(to: TilePoint(x: 4, y: 2), on: "REDS_HOUSE_1F", startingFrom: snapshot, yFirst: true)
        snapshot = try walk(to: TilePoint(x: 2, y: 2), on: "REDS_HOUSE_1F", startingFrom: snapshot)
        snapshot = try walk(to: TilePoint(x: 2, y: 6), on: "REDS_HOUSE_1F", startingFrom: snapshot, yFirst: true)
        try postInput("down")
        snapshot = try waitForSettledField(on: "PALLET_TOWN", timeout: 4)
        try assertRealFieldRendering(snapshot, expectedMapID: "PALLET_TOWN")
        try assertAudio(snapshot, trackID: "MUSIC_PALLET_TOWN", reason: "mapDefault")
        print("validate: pallet reached")
        snapshot = try walk(to: TilePoint(x: 10, y: 2), on: "PALLET_TOWN", startingFrom: snapshot)
        try postInput("up")

        snapshot = try poll(until: { $0.scene == .dialogue && ($0.dialogue?.dialogueID.contains("oak") ?? false) }, timeout: 4)
        try assertAudio(snapshot, trackID: "MUSIC_MEET_PROF_OAK", reason: "scriptOverride")
        snapshot = try drainDialogues(startingFrom: snapshot, maxInteractions: 16)
        snapshot = try advanceNarrative(
            startingFrom: snapshot,
            maxInteractions: 24,
            until: {
                $0.scene == .field &&
                $0.field?.mapID == "OAKS_LAB" &&
                ($0.eventFlags?.activeFlags.contains("EVENT_OAK_ASKED_TO_CHOOSE_MON") ?? false)
            }
        )
        try assertRealFieldRendering(snapshot, expectedMapID: "OAKS_LAB")
        try assertAudio(snapshot, trackID: "MUSIC_OAKS_LAB", reason: "mapDefault")
        print("validate: oak lab intro complete")
        try assertNoPlayerObjectOverlap(snapshot)
        guard snapshot.field?.objects.contains(where: { $0.id == "oaks_lab_oak_1" }) == true else {
            throw HarnessError.validationFailed("expected Oak to remain visible after escorting the player into the lab")
        }
        guard snapshot.field?.objects.contains(where: { $0.id == "oaks_lab_oak_2" }) == false else {
            throw HarnessError.validationFailed("temporary Oak escort object should be hidden after the lab entry movement finishes")
        }

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
        snapshot = try advanceNarrative(
            startingFrom: snapshot,
            maxInteractions: 24,
            until: {
                $0.scene == .field &&
                $0.field?.mapID == "OAKS_LAB" &&
                ($0.eventFlags?.activeFlags.contains("EVENT_GOT_STARTER") ?? false)
            }
        )
        try assertRealFieldRendering(snapshot, expectedMapID: "OAKS_LAB")
        try assertAudio(snapshot, trackID: "MUSIC_OAKS_LAB", reason: "mapDefault")
        print("validate: starter acquired")
        try assertNoPlayerObjectOverlap(snapshot)

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
        try assertNoPlayerObjectOverlap(snapshot)
        guard snapshot.field?.objects.contains(where: { $0.id == "oaks_lab_rival" }) == false else {
            throw HarnessError.validationFailed("rival should have left Oak's Lab after the post-battle exit sequence")
        }

        guard snapshot.party?.pokemon.count == 1 else {
            throw HarnessError.validationFailed("expected one starter in party after rival battle")
        }
        guard snapshot.assetLoadingFailures.isEmpty else {
            throw HarnessError.validationFailed("expected zero asset-loading failures, got: \(snapshot.assetLoadingFailures.joined(separator: ", "))")
        }
        print("validate: m3 baseline complete")
        return snapshot
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

    private func assertNoPlayerObjectOverlap(_ snapshot: RuntimeTelemetrySnapshot) throws {
        guard let field = snapshot.field else {
            throw HarnessError.validationFailed("expected field telemetry while checking object overlap")
        }
        guard field.objects.contains(where: { $0.position == field.playerPosition }) == false else {
            throw HarnessError.validationFailed("player overlapped a visible field object on \(field.mapID)")
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

    private func followPath(_ buttons: [String], startingFrom initialSnapshot: RuntimeTelemetrySnapshot) throws -> RuntimeTelemetrySnapshot {
        var snapshot = initialSnapshot
        for button in buttons {
            snapshot = try stepField(button, startingFrom: snapshot)
        }
        return snapshot
    }

    private func stepField(_ button: String, startingFrom initialSnapshot: RuntimeTelemetrySnapshot) throws -> RuntimeTelemetrySnapshot {
        guard initialSnapshot.scene == .field, let field = initialSnapshot.field else {
            throw HarnessError.validationFailed("cannot step field input '\(button)' while scene is \(initialSnapshot.scene.rawValue)")
        }

        try postInput(button)
        return try poll(until: { snapshot in
            guard snapshot.scene == .field, let nextField = snapshot.field else {
                return true
            }
            return nextField.mapID != field.mapID ||
                nextField.playerPosition != field.playerPosition ||
                nextField.facing != field.facing ||
                nextField.transition != field.transition ||
                nextField.activeMapScriptTriggerID != field.activeMapScriptTriggerID ||
                nextField.activeScriptID != field.activeScriptID ||
                nextField.activeScriptStep != field.activeScriptStep
        }, timeout: 3)
    }

    private func face(
        _ direction: FacingDirection,
        on mapID: String,
        startingFrom initialSnapshot: RuntimeTelemetrySnapshot
    ) throws -> RuntimeTelemetrySnapshot {
        guard let field = initialSnapshot.field, field.mapID == mapID else {
            throw HarnessError.validationFailed("cannot face \(direction.rawValue) outside \(mapID)")
        }
        if field.facing == direction {
            return initialSnapshot
        }
        return try stepField(direction.rawValue, startingFrom: initialSnapshot)
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
            throw HarnessError.validationFailed("no telemetry snapshot available\(appLogContext())")
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
            throw HarnessError.validationFailed("timed out waiting for expected telemetry state; last snapshot scene=\(latestSeen.scene.rawValue) substate=\(latestSeen.substate) focus=\(focus)\(appLogContext())")
        }
        throw HarnessError.validationFailed("timed out waiting for expected telemetry state; no snapshot available\(appLogContext())")
    }

    private func waitForSettledField(on mapID: String, timeout: TimeInterval) throws -> RuntimeTelemetrySnapshot {
        try poll(until: {
            $0.scene == .field &&
            $0.field?.mapID == mapID &&
            $0.field?.transition == nil
        }, timeout: timeout)
    }

    private func postInput(_ button: String) throws {
        let data = try request(path: "/input", method: "POST", payload: ["button": button])
        if let response = try? JSONDecoder().decode(BooleanResponse.self, from: data), response.accepted {
            return
        }
        throw HarnessError.requestFailed("input '\(button)' was not accepted")
    }

    private func post(path: String, body: [String: String]) throws {
        _ = try request(path: path, method: "POST", payload: body)
    }

    private func request<T: Encodable>(path: String, method: String, payload: T) throws -> Data {
        try request(path: path, method: method, bodyData: try JSONEncoder().encode(payload))
    }

    private func request(path: String, method: String) throws -> Data {
        try request(path: path, method: method, bodyData: nil)
    }

    private func request(path: String, method: String, bodyData: Data?) throws -> Data {
        guard let url = URL(string: "http://127.0.0.1:\(port)\(path)") else {
            throw HarnessError.requestFailed("invalid url")
        }
        let retryDeadline = Date().addingTimeInterval(2.5)
        var lastError: Error?

        while true {
            var request = URLRequest(url: url)
            request.httpMethod = method
            if let bodyData {
                request.httpBody = bodyData
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
                    throw HarnessError.requestFailed("\(error)\(appLogContext())")
                }
                Thread.sleep(forTimeInterval: 0.1)
            case .none:
                lastError = HarnessError.requestFailed("empty request result")
                guard Date() < retryDeadline else {
                    throw HarnessError.requestFailed("empty request result\(appLogContext())")
                }
                Thread.sleep(forTimeInterval: 0.1)
            }
        }

        throw HarnessError.requestFailed(String(describing: lastError ?? HarnessError.requestFailed("unknown request failure")))
    }

    private func appLogContext() -> String {
        guard let tail = appLogTail(), tail.isEmpty == false else {
            return ""
        }
        return "\napp.log tail:\n\(tail)"
    }

    private func appLogTail(maxLines: Int = 20) -> String? {
        let logURL = traceDirectory.appendingPathComponent("app.log")
        guard let data = try? Data(contentsOf: logURL) else {
            return nil
        }
        let lines = String(decoding: data, as: UTF8.self)
            .split(separator: "\n", omittingEmptySubsequences: false)
        guard lines.isEmpty == false else {
            return nil
        }
        return lines.suffix(maxLines).joined(separator: "\n")
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
                guard snapshot.scene == .field else {
                    return snapshot
                }
                return try poll(until: {
                    $0.scene == .field &&
                    $0.field?.mapID == mapID &&
                    $0.field?.playerPosition == target &&
                    $0.field?.transition == nil
                }, timeout: 3)
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
                guard $0.scene == .field, let nextField = $0.field else {
                    return true
                }
                if nextField.mapID != mapID {
                    return true
                }
                return nextField.playerPosition != previousPosition && nextField.transition == nil
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
            snapshot = try confirmDialogueAdvance(startingFrom: snapshot, timeout: 1.5)
            interactions += 1
        }
        return snapshot
    }

    private func advanceNarrative(
        startingFrom initialSnapshot: RuntimeTelemetrySnapshot,
        maxInteractions: Int,
        until predicate: @escaping (RuntimeTelemetrySnapshot) -> Bool
    ) throws -> RuntimeTelemetrySnapshot {
        var snapshot = initialSnapshot
        var interactions = 0

        while true {
            if predicate(snapshot) {
                return snapshot
            }

            switch snapshot.scene {
            case .dialogue:
                guard interactions < maxInteractions else {
                    throw HarnessError.validationFailed("narrative did not reach expected state within \(maxInteractions) confirms")
                }
                snapshot = try confirmDialogueAdvance(startingFrom: snapshot, timeout: 1.5, until: predicate)
                interactions += 1

            case .scriptedSequence:
                let previousStep = snapshot.field?.activeScriptStep
                let previousPosition = snapshot.field?.playerPosition
                let previousDialogueID = snapshot.dialogue?.dialogueID
                let previousSubstate = snapshot.substate
                snapshot = try poll(until: {
                    predicate($0) ||
                    $0.scene != .scriptedSequence ||
                    $0.field?.activeScriptStep != previousStep ||
                    $0.field?.playerPosition != previousPosition ||
                    $0.dialogue?.dialogueID != previousDialogueID ||
                    $0.substate != previousSubstate
                }, timeout: 3)

            case .field:
                let activeScriptID = snapshot.field?.activeScriptID
                let activeTriggerID = snapshot.field?.activeMapScriptTriggerID
                let previousStep = snapshot.field?.activeScriptStep
                let previousPosition = snapshot.field?.playerPosition
                guard activeScriptID != nil || activeTriggerID != nil else {
                    throw HarnessError.validationFailed("narrative stalled before reaching expected state; scene=\(snapshot.scene.rawValue) substate=\(snapshot.substate)")
                }
                snapshot = try poll(until: {
                    predicate($0) ||
                    $0.scene != .field ||
                    $0.field?.activeScriptID != activeScriptID ||
                    $0.field?.activeMapScriptTriggerID != activeTriggerID ||
                    $0.field?.activeScriptStep != previousStep ||
                    $0.field?.playerPosition != previousPosition
                }, timeout: 3)

            default:
                throw HarnessError.validationFailed("narrative stalled before reaching expected state; scene=\(snapshot.scene.rawValue) substate=\(snapshot.substate)")
            }
        }
    }

    private func confirmDialogueAdvance(
        startingFrom snapshot: RuntimeTelemetrySnapshot,
        timeout: TimeInterval,
        until predicate: ((RuntimeTelemetrySnapshot) -> Bool)? = nil
    ) throws -> RuntimeTelemetrySnapshot {
        let currentDialogueID = snapshot.dialogue?.dialogueID
        let currentPageIndex = snapshot.dialogue?.pageIndex

        for _ in 0..<3 {
            try postInput("confirm")
            if let advanced = try? poll(until: {
                (predicate?($0) ?? false) ||
                $0.scene != .dialogue ||
                $0.dialogue?.pageIndex != currentPageIndex ||
                $0.dialogue?.dialogueID != currentDialogueID
            }, timeout: timeout) {
                return advanced
            }
        }

        throw HarnessError.validationFailed(
            "dialogue did not advance from \(currentDialogueID ?? "unknown") page \(currentPageIndex.map(String.init) ?? "unknown")"
        )
    }
}

do {
    try HarnessCLI().run()
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
