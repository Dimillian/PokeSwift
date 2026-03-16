import Foundation

public enum MajorStatusCondition: String, Codable, Equatable, Sendable {
    case none
    case sleep
    case poison
    case burn
    case freeze
    case paralysis

    public var captureBonus: Int {
        switch self {
        case .none:
            return 0
        case .poison, .burn, .paralysis:
            return 12
        case .sleep, .freeze:
            return 25
        }
    }
}
