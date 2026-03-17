import Foundation

public struct FieldPaletteColorManifest: Codable, Equatable, Sendable {
    public let red: Int
    public let green: Int
    public let blue: Int

    public init(red: Int, green: Int, blue: Int) {
        self.red = red
        self.green = green
        self.blue = blue
    }
}

public struct FieldPaletteManifest: Codable, Equatable, Sendable {
    public let id: String
    public let colors: [FieldPaletteColorManifest]

    public init(id: String, colors: [FieldPaletteColorManifest]) {
        self.id = id
        self.colors = colors
    }
}
