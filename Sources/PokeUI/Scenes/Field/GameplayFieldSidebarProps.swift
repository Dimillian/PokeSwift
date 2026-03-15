public struct GameplayFieldSidebarProps: Equatable, Sendable {
    public let profile: TrainerProfileProps
    public let pokedex: PokedexSidebarProps
    public let party: PartySidebarProps
    public let inventory: InventorySidebarProps
    public let save: SaveSidebarProps
    public let options: OptionsSidebarProps
    public let preferredExpandedSection: GameplaySidebarExpandedSection?

    public init(
        profile: TrainerProfileProps,
        pokedex: PokedexSidebarProps,
        party: PartySidebarProps,
        inventory: InventorySidebarProps,
        save: SaveSidebarProps,
        options: OptionsSidebarProps,
        preferredExpandedSection: GameplaySidebarExpandedSection? = nil
    ) {
        self.profile = profile
        self.pokedex = pokedex
        self.party = party
        self.inventory = inventory
        self.save = save
        self.options = options
        self.preferredExpandedSection = preferredExpandedSection
    }
}
