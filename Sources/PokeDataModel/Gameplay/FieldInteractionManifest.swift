import Foundation

public enum FieldInteractionKind: String, Codable, Equatable, Sendable {
    case pokemonCenterHealing
    case paidAdmission
    case dialogueChoice
}

public enum FieldPromptKind: String, Codable, Equatable, Sendable {
    case yesNo
}

public struct FieldPromptManifest: Codable, Equatable, Sendable {
    public let kind: FieldPromptKind
    public let dialogueID: String

    public init(kind: FieldPromptKind, dialogueID: String) {
        self.kind = kind
        self.dialogueID = dialogueID
    }
}

public struct FieldHealingSequenceManifest: Codable, Equatable, Sendable {
    public let nurseObjectID: String?
    public let machineSoundEffectID: String
    public let healedAudioCueID: String
    public let blackoutCheckpoint: BlackoutCheckpointManifest?

    public init(
        nurseObjectID: String? = nil,
        machineSoundEffectID: String,
        healedAudioCueID: String,
        blackoutCheckpoint: BlackoutCheckpointManifest? = nil
    ) {
        self.nurseObjectID = nurseObjectID
        self.machineSoundEffectID = machineSoundEffectID
        self.healedAudioCueID = healedAudioCueID
        self.blackoutCheckpoint = blackoutCheckpoint
    }
}

public struct FieldPaidAdmissionManifest: Codable, Equatable, Sendable {
    public let price: Int
    public let successFlagID: String
    public let insufficientFundsDialogueID: String
    public let purchaseSoundEffectID: String?
    public let deniedExitPath: [FacingDirection]

    public init(
        price: Int,
        successFlagID: String,
        insufficientFundsDialogueID: String,
        purchaseSoundEffectID: String? = nil,
        deniedExitPath: [FacingDirection] = []
    ) {
        self.price = price
        self.successFlagID = successFlagID
        self.insufficientFundsDialogueID = insufficientFundsDialogueID
        self.purchaseSoundEffectID = purchaseSoundEffectID
        self.deniedExitPath = deniedExitPath
    }
}

public struct FieldInteractionManifest: Codable, Equatable, Sendable {
    public let id: String
    public let kind: FieldInteractionKind
    public let introDialogueID: String
    public let prompt: FieldPromptManifest
    public let acceptedDialogueID: String
    public let successDialogueID: String
    public let declinedDialogueID: String?
    public let farewellDialogueID: String
    public let healingSequence: FieldHealingSequenceManifest?
    public let paidAdmission: FieldPaidAdmissionManifest?

    public init(
        id: String,
        kind: FieldInteractionKind,
        introDialogueID: String,
        prompt: FieldPromptManifest,
        acceptedDialogueID: String,
        successDialogueID: String,
        declinedDialogueID: String? = nil,
        farewellDialogueID: String,
        healingSequence: FieldHealingSequenceManifest? = nil,
        paidAdmission: FieldPaidAdmissionManifest? = nil
    ) {
        self.id = id
        self.kind = kind
        self.introDialogueID = introDialogueID
        self.prompt = prompt
        self.acceptedDialogueID = acceptedDialogueID
        self.successDialogueID = successDialogueID
        self.declinedDialogueID = declinedDialogueID
        self.farewellDialogueID = farewellDialogueID
        self.healingSequence = healingSequence
        self.paidAdmission = paidAdmission
    }
}
