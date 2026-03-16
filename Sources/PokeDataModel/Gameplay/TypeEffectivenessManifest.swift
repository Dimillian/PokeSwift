import Foundation

public struct TypeEffectivenessManifest: Codable, Equatable, Sendable {
    public let attackingType: String
    public let defendingType: String
    public let multiplier: Int

    public init(attackingType: String, defendingType: String, multiplier: Int) {
        self.attackingType = attackingType
        self.defendingType = defendingType
        self.multiplier = multiplier
    }
}
