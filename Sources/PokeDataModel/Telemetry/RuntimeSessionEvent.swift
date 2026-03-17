import Foundation

public enum RuntimeSessionEventKind: String, Codable, Equatable, Sendable {
    case sessionStarted
    case scriptStarted
    case scriptFinished
    case scriptFailed
    case dialogueStarted
    case warpCompleted
    case encounterTriggered
    case battleStarted
    case battleEnded
    case blackout
    case shopOpened
    case shopClosed
    case shopPurchase
    case inventoryChanged
    case partyHealed
    case saveResult
    case nicknameApplied
}

public struct RuntimeSessionEvent: Codable, Equatable, Sendable {
    public let timestamp: String
    public let kind: RuntimeSessionEventKind
    public let message: String
    public let scene: RuntimeScene
    public let mapID: String?
    public let scriptID: String?
    public let dialogueID: String?
    public let battleID: String?
    public let battleKind: BattleKind?
    public let details: [String: String]

    public init(
        timestamp: String,
        kind: RuntimeSessionEventKind,
        message: String,
        scene: RuntimeScene,
        mapID: String?,
        scriptID: String? = nil,
        dialogueID: String? = nil,
        battleID: String? = nil,
        battleKind: BattleKind? = nil,
        details: [String: String] = [:]
    ) {
        self.timestamp = timestamp
        self.kind = kind
        self.message = message
        self.scene = scene
        self.mapID = mapID
        self.scriptID = scriptID
        self.dialogueID = dialogueID
        self.battleID = battleID
        self.battleKind = battleKind
        self.details = details
    }
}
