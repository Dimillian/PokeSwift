import PokeDataModel

public struct InventorySidebarItemProps: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let quantityText: String

    public init(id: String, name: String, quantityText: String) {
        self.id = id
        self.name = name
        self.quantityText = quantityText
    }
}

public struct InventorySidebarProps: Equatable, Sendable {
    public let title: String
    public let items: [InventorySidebarItemProps]
    public let emptyStateTitle: String
    public let emptyStateDetail: String

    public init(
        title: String,
        items: [InventorySidebarItemProps],
        emptyStateTitle: String,
        emptyStateDetail: String
    ) {
        self.title = title
        self.items = items
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
