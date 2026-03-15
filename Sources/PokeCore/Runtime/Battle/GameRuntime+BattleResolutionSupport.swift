import PokeDataModel

struct ResolvedBattleMove {
    let messages: [String]
    let dealtDamage: Int
    let typeMultiplier: Int
    let pendingAction: RuntimeBattlePendingAction?
    let payDayMoneyGain: Int
}

struct ResolvedBattleAction {
    let side: BattlePresentationSide
    let moveID: String
    let attackerSpeciesID: String
    let didExecuteMove: Bool
    let updatedAttacker: RuntimePokemonState
    let updatedDefender: RuntimePokemonState
    let messages: [String]
    let dealtDamage: Int
    let typeMultiplier: Int
    let defenderHPBefore: Int
    let defenderHPAfter: Int
    let pendingAction: RuntimeBattlePendingAction?
    let payDayMoneyGain: Int
}

enum BattleStatKind {
    case attack
    case defense
    case speed
    case special
    case accuracy
    case evasion

    var displayName: String {
        switch self {
        case .attack:
            return "Attack"
        case .defense:
            return "Defense"
        case .speed:
            return "Speed"
        case .special:
            return "Special"
        case .accuracy:
            return "Accuracy"
        case .evasion:
            return "Evasion"
        }
    }
}

enum StatChangeTarget {
    case attacker
    case defender
}

struct StatStageEffectDescriptor {
    let target: StatChangeTarget
    let stat: BattleStatKind
    let stageDelta: Int
    let isSideEffect: Bool
}

struct BattleTurnPreparationResult {
    let messages: [String]
    let canAct: Bool
    let shouldSkipPP: Bool
    let shouldSkipAccuracy: Bool
    let shouldSkipEffect: Bool
    let forcedDamage: Int?
}

struct ResolvedMultiHitMove {
    let dealtDamage: Int
    let lastHitDamage: Int
    let hitSubstitute: Bool
    let messages: [String]
}

struct SubstituteDamageResult {
    let hitSubstitute: Bool
    let appliedDamage: Int
    let messages: [String]
}

extension GameRuntime {
    static let trainerAIStatusAilmentEffects: Set<String> = [
        "EFFECT_01",
        "SLEEP_EFFECT",
        "POISON_EFFECT",
        "PARALYZE_EFFECT",
    ]

    static let trainerAIModification2PreferredEffects: Set<String> = [
        "ATTACK_UP1_EFFECT",
        "DEFENSE_UP1_EFFECT",
        "SPEED_UP1_EFFECT",
        "SPECIAL_UP1_EFFECT",
        "ACCURACY_UP1_EFFECT",
        "EVASION_UP1_EFFECT",
        "PAY_DAY_EFFECT",
        "SWIFT_EFFECT",
        "ATTACK_DOWN1_EFFECT",
        "DEFENSE_DOWN1_EFFECT",
        "SPEED_DOWN1_EFFECT",
        "SPECIAL_DOWN1_EFFECT",
        "ACCURACY_DOWN1_EFFECT",
        "EVASION_DOWN1_EFFECT",
        "CONVERSION_EFFECT",
        "HAZE_EFFECT",
        "ATTACK_UP2_EFFECT",
        "DEFENSE_UP2_EFFECT",
        "SPEED_UP2_EFFECT",
        "SPECIAL_UP2_EFFECT",
        "ACCURACY_UP2_EFFECT",
        "EVASION_UP2_EFFECT",
        "HEAL_EFFECT",
        "TRANSFORM_EFFECT",
        "ATTACK_DOWN2_EFFECT",
        "DEFENSE_DOWN2_EFFECT",
        "SPEED_DOWN2_EFFECT",
        "SPECIAL_DOWN2_EFFECT",
        "ACCURACY_DOWN2_EFFECT",
        "EVASION_DOWN2_EFFECT",
        "LIGHT_SCREEN_EFFECT",
        "REFLECT_EFFECT",
    ]

    static let specialMoveTypes: Set<String> = [
        "FIRE",
        "WATER",
        "GRASS",
        "ELECTRIC",
        "ICE",
        "PSYCHIC_TYPE",
        "DRAGON",
    ]

    static let burnSideEffects: Set<String> = [
        "BURN_SIDE_EFFECT1",
        "BURN_SIDE_EFFECT2",
    ]

    static let freezeSideEffects: Set<String> = [
        "FREEZE_SIDE_EFFECT1",
        "FREEZE_SIDE_EFFECT2",
    ]

    static let paralysisSideEffects: Set<String> = [
        "PARALYZE_SIDE_EFFECT1",
        "PARALYZE_SIDE_EFFECT2",
    ]

    static let poisonSideEffects: Set<String> = [
        "POISON_SIDE_EFFECT1",
        "POISON_SIDE_EFFECT2",
        "TWINEEDLE_EFFECT",
    ]

    static let flinchSideEffects: Set<String> = [
        "FLINCH_SIDE_EFFECT1",
        "FLINCH_SIDE_EFFECT2",
    ]
}
