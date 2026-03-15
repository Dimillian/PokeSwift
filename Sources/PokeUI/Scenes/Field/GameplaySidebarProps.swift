import PokeDataModel

public enum GameplaySidebarExpandedSection: String, Equatable, Sendable, CaseIterable {
    case trainer
    case pokedex
    case battleCombat
    case party
    case bag
    case save
    case options
}

public struct GameplaySidebarExpansionState: Equatable, Sendable {
    public private(set) var expandedSection: GameplaySidebarExpandedSection

    public init(expandedSection: GameplaySidebarExpandedSection = .trainer) {
        self.expandedSection = expandedSection
    }

    public mutating func activate(_ section: GameplaySidebarExpandedSection) {
        expandedSection = section
    }
}

public enum GameplaySidebarKind: String, Equatable, Sendable {
    case fieldLike
    case battle

    public static func forScene(_ scene: RuntimeScene) -> GameplaySidebarKind {
        switch scene {
        case .battle:
            return .battle
        default:
            return .fieldLike
        }
    }
}

public enum GameplaySidebarMode: Equatable, Sendable {
    case fieldLike(GameplayFieldSidebarProps)
    case battle(BattleSidebarProps)

    public var kind: GameplaySidebarKind {
        switch self {
        case .fieldLike:
            return .fieldLike
        case .battle:
            return .battle
        }
    }

    public var defaultExpandedSection: GameplaySidebarExpandedSection {
        switch self {
        case let .fieldLike(props):
            return props.preferredExpandedSection ?? .trainer
        case .battle:
            return .battleCombat
        }
    }

    public var requiredExpandedSection: GameplaySidebarExpandedSection? {
        switch self {
        case .fieldLike:
            return nil
        case let .battle(props):
            return props.attentionSection
        }
    }

    public func supports(_ section: GameplaySidebarExpandedSection) -> Bool {
        switch self {
        case .fieldLike:
            switch section {
            case .trainer, .pokedex, .party, .bag, .save, .options:
                return true
            case .battleCombat:
                return false
            }
        case .battle:
            switch section {
            case .battleCombat, .party:
                return true
            case .trainer, .pokedex, .bag, .save, .options:
                return false
            }
        }
    }

    public func resolvedExpandedSection(afterRequesting section: GameplaySidebarExpandedSection) -> GameplaySidebarExpandedSection {
        if let requiredExpandedSection {
            return requiredExpandedSection
        }
        return supports(section) ? section : defaultExpandedSection
    }
}
