import Foundation
import Network
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

public final class TelemetryControlServer: @unchecked Sendable {
    private let listener: NWListener
    private let snapshotProvider: @Sendable () async -> RuntimeTelemetrySnapshot?
    private let inputHandler: @Sendable (RuntimeButton) async -> Bool
    private let quitHandler: @Sendable () async -> Void
    private let queue = DispatchQueue(label: "com.dimillian.PokeSwift.telemetry")
    private let encoder = JSONEncoder()

    public init(
        port: UInt16,
        snapshotProvider: @escaping @Sendable () async -> RuntimeTelemetrySnapshot?,
        inputHandler: @escaping @Sendable (RuntimeButton) async -> Bool,
        quitHandler: @escaping @Sendable () async -> Void
    ) throws {
        guard let endpointPort = NWEndpoint.Port(rawValue: port) else {
            throw CocoaError(.coderInvalidValue)
        }

        self.listener = try NWListener(using: .tcp, on: endpointPort)
        self.snapshotProvider = snapshotProvider
        self.inputHandler = inputHandler
        self.quitHandler = quitHandler
        encoder.outputFormatting = [.sortedKeys]
    }

    public func start() {
        listener.newConnectionHandler = { [weak self] connection in
            self?.handle(connection: connection)
        }
        listener.start(queue: queue)
    }

    public func stop() {
        listener.cancel()
    }

    private func handle(connection: NWConnection) {
        connection.start(queue: queue)
        receiveRequest(on: connection, buffer: Data())
    }

    private func receiveRequest(on connection: NWConnection, buffer: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { [weak self] data, _, isComplete, error in
            guard let self else {
                connection.cancel()
                return
            }

            if error != nil {
                connection.cancel()
                return
            }

            var nextBuffer = buffer
            if let data {
                nextBuffer.append(data)
            }

            if HTTPRequest.isComplete(data: nextBuffer) {
                Task {
                    let response = await self.response(for: nextBuffer)
                    self.send(response: response, on: connection)
                }
                return
            }

            if isComplete {
                Task {
                    let response = await self.response(for: nextBuffer)
                    self.send(response: response, on: connection)
                }
                return
            }

            self.receiveRequest(on: connection, buffer: nextBuffer)
        }
    }

    private func response(for data: Data) async -> HTTPResponse {
        guard let request = HTTPRequest(data: data) else {
            return jsonResponse(status: "400 Bad Request", object: ["error": "invalid request"])
        }

        switch (request.method, request.path) {
        case ("GET", "/health"):
            return jsonResponse(object: ["status": "ok"])
        case ("GET", "/telemetry/latest"):
            guard let snapshot = await snapshotProvider(),
                  let payload = try? encoder.encode(snapshot) else {
                return jsonResponse(status: "404 Not Found", object: ["error": "no snapshot yet"])
            }
            return response(status: "200 OK", body: payload)
        case ("POST", "/input"):
            guard let command = try? JSONDecoder().decode(InputRequest.self, from: request.body),
                  let button = RuntimeButton(rawValue: command.button) else {
                return jsonResponse(status: "400 Bad Request", object: ["error": "invalid input payload"])
            }
            let accepted = await inputHandler(button)
            return jsonResponse(object: ["accepted": accepted, "button": button.rawValue])
        case ("POST", "/quit"):
            return jsonResponse(
                object: ["accepted": true],
                onSendCompleted: { [quitHandler] in
                    Task {
                        try? await Task.sleep(for: .milliseconds(150))
                        await quitHandler()
                    }
                }
            )
        default:
            return jsonResponse(status: "404 Not Found", object: ["error": "unknown route"])
        }
    }

    private func jsonResponse(
        status: String = "200 OK",
        object: [String: Any],
        onSendCompleted: (@Sendable () -> Void)? = nil
    ) -> HTTPResponse {
        let payload = (try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])) ?? Data("{}".utf8)
        return response(status: status, body: payload, onSendCompleted: onSendCompleted)
    }

    private func response(
        status: String,
        body: Data,
        onSendCompleted: (@Sendable () -> Void)? = nil
    ) -> HTTPResponse {
        var header = "HTTP/1.1 \(status)\r\n"
        header += "Content-Type: application/json\r\n"
        header += "Content-Length: \(body.count)\r\n"
        header += "Connection: close\r\n\r\n"
        return HTTPResponse(payload: Data(header.utf8) + body, onSendCompleted: onSendCompleted)
    }

    private func send(response: HTTPResponse, on connection: NWConnection) {
        connection.send(content: response.payload, contentContext: .defaultMessage, isComplete: true, completion: .contentProcessed { _ in
            response.onSendCompleted?()
            connection.cancel()
        })
    }
}

private struct InputRequest: Decodable {
    let button: String
}

private struct HTTPResponse {
    let payload: Data
    let onSendCompleted: (@Sendable () -> Void)?
}

private struct HTTPRequest {
    let method: String
    let path: String
    let body: Data

    init?(data: Data) {
        let separator = Data("\r\n\r\n".utf8)
        let segments = data.split(separator: separator)
        guard let headerData = segments.first,
              let header = String(data: headerData, encoding: .utf8),
              let requestLine = header.split(separator: "\r\n").first else {
            return nil
        }

        let requestParts = requestLine.split(separator: " ")
        guard requestParts.count >= 2 else {
            return nil
        }

        method = String(requestParts[0])
        path = String(requestParts[1])
        body = segments.count > 1 ? Data(segments[1]) : Data()
    }

    static func isComplete(data: Data) -> Bool {
        let separator = Data("\r\n\r\n".utf8)
        guard let headerRange = data.range(of: separator),
              let header = String(data: data[..<headerRange.lowerBound], encoding: .utf8) else {
            return false
        }

        let contentLength = header
            .split(separator: "\r\n")
            .dropFirst()
            .compactMap { line -> Int? in
                let parts = line.split(separator: ":", maxSplits: 1)
                guard parts.count == 2,
                      parts[0].trimmingCharacters(in: .whitespacesAndNewlines).caseInsensitiveCompare("Content-Length") == .orderedSame else {
                    return nil
                }
                return Int(parts[1].trimmingCharacters(in: .whitespacesAndNewlines))
            }
            .first ?? 0

        let bodyStart = headerRange.upperBound
        let bodyLength = data.distance(from: bodyStart, to: data.endIndex)
        return bodyLength >= contentLength
    }
}

private extension Data {
    func split(separator: Data) -> [Data] {
        guard separator.isEmpty == false else { return [self] }
        var chunks: [Data] = []
        var cursor = startIndex

        while let range = self.range(of: separator, options: [], in: cursor..<endIndex) {
            chunks.append(Data(self[cursor..<range.lowerBound]))
            cursor = range.upperBound
        }

        chunks.append(Data(self[cursor..<endIndex]))
        return chunks
    }
}
