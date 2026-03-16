import Foundation

public struct ScriptStep: Codable, Equatable, Sendable {
    public let action: String
    public let stringValue: String?
    public let secondaryStringValue: String?
    public let intValue: Int?
    public let badgeID: String?
    public let point: TilePoint?
    public let path: [FacingDirection]
    public let movement: ScriptMovementManifest?
    public let flagID: String?
    public let objectID: String?
    public let dialogueID: String?
    public let successDialogueID: String?
    public let failureDialogueID: String?
    public let successFlagID: String?
    public let fieldInteractionID: String?
    public let battleID: String?
    public let trainerClass: String?
    public let trainerNumber: Int?
    public let visible: Bool?
    public let continueOnFailure: Bool?

    public init(
        action: String,
        stringValue: String? = nil,
        secondaryStringValue: String? = nil,
        intValue: Int? = nil,
        badgeID: String? = nil,
        point: TilePoint? = nil,
        path: [FacingDirection] = [],
        movement: ScriptMovementManifest? = nil,
        flagID: String? = nil,
        objectID: String? = nil,
        dialogueID: String? = nil,
        successDialogueID: String? = nil,
        failureDialogueID: String? = nil,
        successFlagID: String? = nil,
        fieldInteractionID: String? = nil,
        battleID: String? = nil,
        trainerClass: String? = nil,
        trainerNumber: Int? = nil,
        visible: Bool? = nil,
        continueOnFailure: Bool? = nil
    ) {
        self.action = action
        self.stringValue = stringValue
        self.secondaryStringValue = secondaryStringValue
        self.intValue = intValue
        self.badgeID = badgeID
        self.point = point
        self.path = path
        self.movement = movement
        self.flagID = flagID
        self.objectID = objectID
        self.dialogueID = dialogueID
        self.successDialogueID = successDialogueID
        self.failureDialogueID = failureDialogueID
        self.successFlagID = successFlagID
        self.fieldInteractionID = fieldInteractionID
        self.battleID = battleID
        self.trainerClass = trainerClass
        self.trainerNumber = trainerNumber
        self.visible = visible
        self.continueOnFailure = continueOnFailure
    }
}
