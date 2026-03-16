import Foundation
import PokeDataModel

public struct InventorySidebarTMHMProps: Equatable, Sendable {
    public let moveName: String
    public let typeLabel: String
    public let maxPPText: String

    public init(moveName: String, typeLabel: String, maxPPText: String) {
        self.moveName = moveName
        self.typeLabel = typeLabel
        self.maxPPText = maxPPText
    }
}

public struct InventorySidebarItemProps: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let quantityText: String
    public let iconURL: URL?
    public let descriptionText: String
    public let tmhm: InventorySidebarTMHMProps?
    public let isFocused: Bool

    public init(
        id: String,
        name: String,
        quantityText: String,
        iconURL: URL? = nil,
        descriptionText: String = "",
        tmhm: InventorySidebarTMHMProps? = nil,
        isFocused: Bool = false
    ) {
        self.id = id
        self.name = name
        self.quantityText = quantityText
        self.iconURL = iconURL
        self.descriptionText = descriptionText
        self.tmhm = tmhm
        self.isFocused = isFocused
    }
}

public struct InventorySidebarSectionProps: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let items: [InventorySidebarItemProps]

    public init(id: String, title: String, items: [InventorySidebarItemProps]) {
        self.id = id
        self.title = title
        self.items = items
    }
}

public struct InventorySidebarProps: Equatable, Sendable {
    public let title: String
    public let sections: [InventorySidebarSectionProps]
    public let emptyStateTitle: String
    public let emptyStateDetail: String

    public init(
        title: String,
        sections: [InventorySidebarSectionProps],
        emptyStateTitle: String,
        emptyStateDetail: String
    ) {
        self.title = title
        self.sections = sections
        self.emptyStateTitle = emptyStateTitle
        self.emptyStateDetail = emptyStateDetail
    }
}

public struct SidebarActionRowProps: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let detail: String?
    public let isEnabled: Bool

    public init(id: String, title: String, detail: String? = nil, isEnabled: Bool) {
        self.id = id
        self.title = title
        self.detail = detail
        self.isEnabled = isEnabled
    }
}

public struct SaveSidebarProps: Equatable, Sendable {
    public let title: String
    public let summary: String
    public let actions: [SidebarActionRowProps]

    public init(title: String, summary: String, actions: [SidebarActionRowProps]) {
        self.title = title
        self.summary = summary
        self.actions = actions
    }
}

public struct GameBoyShellStyleOptionProps: Identifiable, Equatable, Sendable {
    public let id: String
    public let shellStyle: GameBoyShellStyle
    public let title: String
    public let isSelected: Bool

    public init(
        id: String,
        shellStyle: GameBoyShellStyle,
        title: String,
        isSelected: Bool
    ) {
        self.id = id
        self.shellStyle = shellStyle
        self.title = title
        self.isSelected = isSelected
    }
}

public struct OptionsSidebarProps: Equatable, Sendable {
    public let title: String
    public let shellPickerTitle: String
    public let shellOptions: [GameBoyShellStyleOptionProps]
    public let rows: [SidebarActionRowProps]

    public init(
        title: String,
        shellPickerTitle: String,
        shellOptions: [GameBoyShellStyleOptionProps],
        rows: [SidebarActionRowProps]
    ) {
        self.title = title
        self.shellPickerTitle = shellPickerTitle
        self.shellOptions = shellOptions
        self.rows = rows
    }
}
