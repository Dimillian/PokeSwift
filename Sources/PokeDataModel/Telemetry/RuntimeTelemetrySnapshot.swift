import Foundation

public struct RuntimeTelemetrySnapshot: Codable, Equatable, Sendable {
    public let appVersion: String
    public let contentVersion: String
    public let scene: RuntimeScene
    public let substate: String
    public let titleMenu: TitleMenuTelemetry?
    public let field: FieldTelemetry?
    public let dialogue: DialogueTelemetry?
    public let fieldPrompt: FieldPromptTelemetry?
    public let fieldHealing: FieldHealingTelemetry?
    public let starterChoice: StarterChoiceTelemetry?
    public let party: PartyTelemetry?
    public let inventory: InventoryTelemetry?
    public let battle: BattleTelemetry?
    public let shop: ShopTelemetry?
    public let eventFlags: EventFlagTelemetry?
    public let audio: AudioTelemetry?
    public let soundEffects: [SoundEffectTelemetry]
    public let save: SaveTelemetry?
    public let recentInputEvents: [InputEventTelemetry]
    public let assetLoadingFailures: [String]
    public let window: WindowTelemetry

    public init(
        appVersion: String,
        contentVersion: String,
        scene: RuntimeScene,
        substate: String,
        titleMenu: TitleMenuTelemetry?,
        field: FieldTelemetry?,
        dialogue: DialogueTelemetry?,
        fieldPrompt: FieldPromptTelemetry? = nil,
        fieldHealing: FieldHealingTelemetry? = nil,
        starterChoice: StarterChoiceTelemetry?,
        party: PartyTelemetry?,
        inventory: InventoryTelemetry?,
        battle: BattleTelemetry?,
        shop: ShopTelemetry?,
        eventFlags: EventFlagTelemetry?,
        audio: AudioTelemetry?,
        soundEffects: [SoundEffectTelemetry] = [],
        save: SaveTelemetry?,
        recentInputEvents: [InputEventTelemetry],
        assetLoadingFailures: [String],
        window: WindowTelemetry
    ) {
        self.appVersion = appVersion
        self.contentVersion = contentVersion
        self.scene = scene
        self.substate = substate
        self.titleMenu = titleMenu
        self.field = field
        self.dialogue = dialogue
        self.fieldPrompt = fieldPrompt
        self.fieldHealing = fieldHealing
        self.starterChoice = starterChoice
        self.party = party
        self.inventory = inventory
        self.battle = battle
        self.shop = shop
        self.eventFlags = eventFlags
        self.audio = audio
        self.soundEffects = soundEffects
        self.save = save
        self.recentInputEvents = recentInputEvents
        self.assetLoadingFailures = assetLoadingFailures
        self.window = window
    }
}
