import Foundation
import PokeCore
import PokeDataModel

enum FileSystemSaveStoreError: LocalizedError {
    case schemaMismatch(Int)

    var errorDescription: String? {
        switch self {
        case let .schemaMismatch(version):
            return "Save schema \(version) is not supported."
        }
    }
}

final class FileSystemSaveStore: SaveStore {
    private static let minimumSupportedSchemaVersion = 3
    private static let supportedSchemaVersion = GameRuntime.saveSchemaVersion
    private let saveURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(saveURL: URL) {
        self.saveURL = saveURL
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    }

    func hasSaveFile() -> Bool {
        FileManager.default.fileExists(atPath: saveURL.path)
    }

    func loadMetadata() throws -> GameSaveMetadata? {
        guard let envelope = try loadSave() else { return nil }
        return envelope.metadata
    }

    func loadSave() throws -> GameSaveEnvelope? {
        guard hasSaveFile() else { return nil }
        let data = try Data(contentsOf: saveURL)
        let envelope = try decoder.decode(GameSaveEnvelope.self, from: data)
        guard (Self.minimumSupportedSchemaVersion...Self.supportedSchemaVersion).contains(envelope.metadata.schemaVersion) else {
            throw FileSystemSaveStoreError.schemaMismatch(envelope.metadata.schemaVersion)
        }
        return envelope
    }

    func save(_ envelope: GameSaveEnvelope) throws {
        let directory = saveURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let temporaryURL = directory.appendingPathComponent(UUID().uuidString).appendingPathExtension("tmp")
        let data = try encoder.encode(envelope) + Data("\n".utf8)
        try data.write(to: temporaryURL, options: .atomic)

        if FileManager.default.fileExists(atPath: saveURL.path) {
            _ = try FileManager.default.replaceItemAt(saveURL, withItemAt: temporaryURL)
        } else {
            try FileManager.default.moveItem(at: temporaryURL, to: saveURL)
        }
    }

    func deleteSave() throws {
        guard hasSaveFile() else { return }
        try FileManager.default.removeItem(at: saveURL)
    }
}
