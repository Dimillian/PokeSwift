import Foundation
import PokeDataModel

private let pokespriteAssetRoot = "Assets/items"
private let pokespriteSourceRoot = "ThirdParty/PokeSprite/items"

struct SupplementalItemMetadata {
    let bagSection: ItemManifest.BagSection
    let shortDescription: String
    let iconAssetPath: String?
    let tmhmMoveID: String?
}

func buildSupplementalItemMetadata(
    itemID: String,
    displayName: String,
    isKeyItem: Bool,
    battleUse: ItemManifest.BattleUseKind,
    tmhmMoveID: String?,
    tmhmMoveDisplayName: String?,
    tmhmMoveType: String?
) -> SupplementalItemMetadata {
    let bagSection = derivedBagSection(for: itemID, isKeyItem: isKeyItem, battleUse: battleUse)
    return SupplementalItemMetadata(
        bagSection: bagSection,
        shortDescription: shortDescription(
            for: itemID,
            displayName: displayName,
            bagSection: bagSection,
            tmhmMoveDisplayName: tmhmMoveDisplayName
        ),
        iconAssetPath: iconAssetPath(
            for: itemID,
            bagSection: bagSection,
            tmhmMoveType: tmhmMoveType
        ),
        tmhmMoveID: tmhmMoveID
    )
}

func pokespriteItemAssetMap(from items: [ItemManifest]) -> [(source: String, destination: String)] {
    let uniqueDestinations = Set<String>(
        items.compactMap { item -> String? in
            guard let iconAssetPath = item.iconAssetPath, iconAssetPath.hasPrefix("\(pokespriteAssetRoot)/") else {
                return nil
            }
            return iconAssetPath
        }
    )

    return uniqueDestinations
        .sorted()
        .map { destination in
            let relativePath = String(destination.dropFirst(pokespriteAssetRoot.count + 1))
            return (
                source: "\(pokespriteSourceRoot)/\(relativePath)",
                destination: destination
            )
        }
}

private func derivedBagSection(
    for itemID: String,
    isKeyItem: Bool,
    battleUse: ItemManifest.BattleUseKind
) -> ItemManifest.BagSection {
    if itemID.hasPrefix("TM_") || itemID.hasPrefix("HM_") {
        return .tmhm
    }
    if battleUse == .ball {
        return .balls
    }
    if isKeyItem {
        return .keyItems
    }
    return .items
}

private func shortDescription(
    for itemID: String,
    displayName: String,
    bagSection: ItemManifest.BagSection,
    tmhmMoveDisplayName: String?
) -> String {
    if let tmhmMoveDisplayName {
        let machineKind = itemID.hasPrefix("HM_") ? "hidden machine" : "technical machine"
        return "A \(machineKind) that teaches \(tmhmMoveDisplayName.replacingOccurrences(of: "_", with: " "))."
    }

    if let explicit = explicitDescriptionByItemID[itemID] {
        return explicit
    }

    if itemID.hasPrefix("FLOOR_") {
        return "An elevator floor card marked \(displayName)."
    }

    switch bagSection {
    case .items:
        return "A useful item for battle, healing, or travel."
    case .balls:
        return "A Ball for catching wild Pokemon."
    case .keyItems:
        return "A special item that helps advance the adventure."
    case .tmhm:
        return "A machine that teaches a move to a compatible Pokemon."
    }
}

private func iconAssetPath(
    for itemID: String,
    bagSection: ItemManifest.BagSection,
    tmhmMoveType: String?
) -> String? {
    if itemID == "POKEDEX" {
        return "Assets/field/sprites/pokedex.png"
    }

    if itemID.hasPrefix("TM_") || itemID.hasPrefix("HM_") {
        let group = itemID.hasPrefix("HM_") ? "hm" : "tm"
        let moveTypeSlug = tmhmMoveType.map(pokespriteMoveTypeSlug(for:)) ?? "normal"
        return "\(pokespriteAssetRoot)/\(group)/\(moveTypeSlug).png"
    }

    if let explicitRelativePath = explicitRelativeIconPathByItemID[itemID] {
        return "\(pokespriteAssetRoot)/\(explicitRelativePath)"
    }

    guard let fallbackRelativePath = fallbackRelativeIconPathByBagSection[bagSection] else {
        return nil
    }
    return "\(pokespriteAssetRoot)/\(fallbackRelativePath)"
}

private func pokespriteMoveTypeSlug(for moveType: String) -> String {
    switch moveType.uppercased() {
    case "NORMAL":
        return "normal"
    case "FIGHTING":
        return "fighting"
    case "FLYING":
        return "flying"
    case "POISON":
        return "poison"
    case "GROUND":
        return "ground"
    case "ROCK":
        return "rock"
    case "BUG":
        return "bug"
    case "GHOST":
        return "ghost"
    case "FIRE":
        return "fire"
    case "WATER":
        return "water"
    case "GRASS":
        return "grass"
    case "ELECTRIC":
        return "electric"
    case "PSYCHIC":
        return "psychic"
    case "ICE":
        return "ice"
    case "DRAGON":
        return "dragon"
    case "DARK":
        return "dark"
    case "STEEL":
        return "steel"
    case "FAIRY":
        return "fairy"
    default:
        return "normal"
    }
}

private let fallbackRelativeIconPathByBagSection: [ItemManifest.BagSection: String] = [
    .items: "other-item/repel.png",
    .balls: "ball/poke.png",
    .keyItems: "key-item/parcel.png",
    .tmhm: "tm/normal.png",
]

private let explicitRelativeIconPathByItemID: [String: String] = [
    "MASTER_BALL": "ball/master.png",
    "ULTRA_BALL": "ball/ultra.png",
    "GREAT_BALL": "ball/great.png",
    "POKE_BALL": "ball/poke.png",
    "TOWN_MAP": "key-item/town-map.png",
    "BICYCLE": "key-item/bicycle.png",
    "SURFBOARD": "key-item/aqua-suit.png",
    "SAFARI_BALL": "ball/safari.png",
    "MOON_STONE": "evo-item/moon-stone.png",
    "ANTIDOTE": "medicine/antidote.png",
    "BURN_HEAL": "medicine/burn-heal.png",
    "ICE_HEAL": "medicine/ice-heal.png",
    "AWAKENING": "medicine/awakening.png",
    "PARLYZ_HEAL": "medicine/paralyze-heal.png",
    "FULL_RESTORE": "medicine/full-restore.png",
    "MAX_POTION": "medicine/max-potion.png",
    "HYPER_POTION": "medicine/hyper-potion.png",
    "SUPER_POTION": "medicine/super-potion.png",
    "POTION": "medicine/potion.png",
    "BOULDERBADGE": "key-item/surge-badge.png",
    "CASCADEBADGE": "key-item/surge-badge.png",
    "THUNDERBADGE": "key-item/surge-badge.png",
    "RAINBOWBADGE": "key-item/surge-badge.png",
    "SOULBADGE": "key-item/surge-badge.png",
    "MARSHBADGE": "key-item/surge-badge.png",
    "VOLCANOBADGE": "key-item/surge-badge.png",
    "EARTHBADGE": "key-item/surge-badge.png",
    "ESCAPE_ROPE": "other-item/escape-rope.png",
    "REPEL": "other-item/repel.png",
    "OLD_AMBER": "fossil/old-amber.png",
    "FIRE_STONE": "evo-item/fire-stone.png",
    "THUNDER_STONE": "evo-item/thunder-stone.png",
    "WATER_STONE": "evo-item/water-stone.png",
    "HP_UP": "medicine/hp-up.png",
    "PROTEIN": "medicine/protein.png",
    "IRON": "medicine/iron.png",
    "CARBOS": "medicine/carbos.png",
    "CALCIUM": "medicine/calcium.png",
    "RARE_CANDY": "medicine/rare-candy.png",
    "DOME_FOSSIL": "fossil/dome.png",
    "HELIX_FOSSIL": "fossil/helix.png",
    "SECRET_KEY": "key-item/storage-key.png",
    "ITEM_2C": "key-item/data-card.png",
    "BIKE_VOUCHER": "key-item/bike-voucher.png",
    "X_ACCURACY": "battle-item/x-accuracy.png",
    "LEAF_STONE": "evo-item/leaf-stone.png",
    "CARD_KEY": "key-item/card-key.png",
    "NUGGET": "valuable-item/nugget.png",
    "ITEM_32": "medicine/pp-up.png",
    "POKE_DOLL": "other-item/poke-doll.png",
    "FULL_HEAL": "medicine/full-heal.png",
    "REVIVE": "medicine/revive.png",
    "MAX_REVIVE": "medicine/max-revive.png",
    "GUARD_SPEC": "battle-item/guard-spec.png",
    "SUPER_REPEL": "other-item/super-repel.png",
    "MAX_REPEL": "other-item/max-repel.png",
    "DIRE_HIT": "battle-item/dire-hit.png",
    "COIN": "other-item/bottle-cap.png",
    "FRESH_WATER": "medicine/fresh-water.png",
    "SODA_POP": "medicine/soda-pop.png",
    "LEMONADE": "medicine/lemonade.png",
    "S_S_TICKET": "key-item/ss-ticket.png",
    "GOLD_TEETH": "key-item/gold-teeth.png",
    "X_ATTACK": "battle-item/x-attack.png",
    "X_DEFEND": "battle-item/x-defense.png",
    "X_SPEED": "battle-item/x-speed.png",
    "X_SPECIAL": "battle-item/x-sp-atk.png",
    "COIN_CASE": "key-item/coin-case.png",
    "OAKS_PARCEL": "key-item/parcel.png",
    "ITEMFINDER": "key-item/dowsing-machine.png",
    "SILPH_SCOPE": "key-item/silph-scope.png",
    "POKE_FLUTE": "key-item/poke-flute.png",
    "LIFT_KEY": "key-item/lift-key.png",
    "EXP_ALL": "key-item/exp-share.png",
    "OLD_ROD": "key-item/old-rod.png",
    "GOOD_ROD": "key-item/good-rod.png",
    "SUPER_ROD": "key-item/super-rod.png",
    "PP_UP": "medicine/pp-up.png",
    "ETHER": "medicine/ether.png",
    "MAX_ETHER": "medicine/max-ether.png",
    "ELIXER": "medicine/elixir.png",
    "MAX_ELIXER": "medicine/max-elixir.png",
    "FLOOR_B2F": "key-item/elevator-key.png",
    "FLOOR_B1F": "key-item/elevator-key.png",
    "FLOOR_1F": "key-item/elevator-key.png",
    "FLOOR_2F": "key-item/elevator-key.png",
    "FLOOR_3F": "key-item/elevator-key.png",
    "FLOOR_4F": "key-item/elevator-key.png",
    "FLOOR_5F": "key-item/elevator-key.png",
    "FLOOR_6F": "key-item/elevator-key.png",
    "FLOOR_7F": "key-item/elevator-key.png",
    "FLOOR_8F": "key-item/elevator-key.png",
    "FLOOR_9F": "key-item/elevator-key.png",
    "FLOOR_10F": "key-item/elevator-key.png",
    "FLOOR_11F": "key-item/elevator-key.png",
    "FLOOR_B4F": "key-item/elevator-key.png",
]

private let explicitDescriptionByItemID: [String: String] = [
    "MASTER_BALL": "The best Ball. It catches a wild Pokemon without fail.",
    "ULTRA_BALL": "A high-performance Ball with a very good catch rate.",
    "GREAT_BALL": "A good Ball with a better catch rate than a Poke Ball.",
    "POKE_BALL": "A standard Ball used to catch wild Pokemon.",
    "TOWN_MAP": "A convenient map of the Kanto region.",
    "BICYCLE": "A folding bike that lets you move much faster than walking.",
    "SURFBOARD": "An unused surfboard entry left behind in Red's item table.",
    "SAFARI_BALL": "A special Ball supplied for use in the Safari Zone.",
    "POKEDEX": "A hi-tech encyclopedia for recording Pokemon data.",
    "MOON_STONE": "A peculiar stone that can trigger certain evolutions.",
    "ANTIDOTE": "A spray medicine that cures poisoning.",
    "BURN_HEAL": "A spray medicine that heals a burn.",
    "ICE_HEAL": "A spray medicine that thaws a frozen Pokemon.",
    "AWAKENING": "A medicine that wakes a sleeping Pokemon.",
    "PARLYZ_HEAL": "A medicine that cures paralysis.",
    "FULL_RESTORE": "Fully restores HP and cures all major status problems.",
    "MAX_POTION": "Fully restores a Pokemon's HP.",
    "HYPER_POTION": "Restores a large amount of HP.",
    "SUPER_POTION": "Restores a healthy amount of HP.",
    "POTION": "Restores a little HP.",
    "BOULDERBADGE": "Proof of victory over Brock in Pewter Gym.",
    "CASCADEBADGE": "Proof of victory over Misty in Cerulean Gym.",
    "THUNDERBADGE": "Proof of victory over Lt. Surge in Vermilion Gym.",
    "RAINBOWBADGE": "Proof of victory over Erika in Celadon Gym.",
    "SOULBADGE": "Proof of victory over Koga in Fuchsia Gym.",
    "MARSHBADGE": "Proof of victory over Sabrina in Saffron Gym.",
    "VOLCANOBADGE": "Proof of victory over Blaine in Cinnabar Gym.",
    "EARTHBADGE": "Proof of victory over Giovanni in Viridian Gym.",
    "ESCAPE_ROPE": "A sturdy rope that helps you quickly escape a cave or dungeon.",
    "REPEL": "Keeps weak wild Pokemon away for a while.",
    "OLD_AMBER": "A piece of ancient amber that may contain extinct Pokemon DNA.",
    "FIRE_STONE": "A stone that can trigger certain Fire-type evolutions.",
    "THUNDER_STONE": "A stone that can trigger certain Electric-type evolutions.",
    "WATER_STONE": "A stone that can trigger certain Water-type evolutions.",
    "HP_UP": "Raises a Pokemon's maximum HP.",
    "PROTEIN": "Raises a Pokemon's Attack stat.",
    "IRON": "Raises a Pokemon's Defense stat.",
    "CARBOS": "Raises a Pokemon's Speed stat.",
    "CALCIUM": "Raises a Pokemon's Special stat.",
    "RARE_CANDY": "Raises a Pokemon's level by one.",
    "DOME_FOSSIL": "A fossil that can be revived into an ancient Pokemon.",
    "HELIX_FOSSIL": "A fossil that can be revived into an ancient Pokemon.",
    "SECRET_KEY": "Opens the locked door in the Pokemon Mansion.",
    "ITEM_2C": "An unused item entry left in Red's item table.",
    "BIKE_VOUCHER": "Exchange this voucher for a Bicycle.",
    "X_ACCURACY": "Sharply boosts accuracy for one battle.",
    "LEAF_STONE": "A stone that can trigger certain Grass-type evolutions.",
    "CARD_KEY": "Unlocks electronic doors inside Silph Co.",
    "NUGGET": "A nugget of pure gold that sells for a high price.",
    "ITEM_32": "Raises the PP of one move.",
    "POKE_DOLL": "A cute doll that can distract wild Pokemon and help you flee.",
    "FULL_HEAL": "Cures any major status problem.",
    "REVIVE": "Revives a fainted Pokemon with some HP.",
    "MAX_REVIVE": "Fully revives a fainted Pokemon.",
    "GUARD_SPEC": "Raises protection against stat drops for one battle.",
    "SUPER_REPEL": "Keeps weak wild Pokemon away longer than a Repel.",
    "MAX_REPEL": "Keeps weak wild Pokemon away for a very long time.",
    "DIRE_HIT": "Raises the critical-hit rate for one battle.",
    "COIN": "A single Game Corner coin.",
    "FRESH_WATER": "A drink that restores a little HP.",
    "SODA_POP": "A fizzy drink that restores some HP.",
    "LEMONADE": "A sweet drink that restores more HP.",
    "S_S_TICKET": "A boarding pass for the S.S. Anne.",
    "GOLD_TEETH": "The Warden's lost teeth from the Safari Zone.",
    "X_ATTACK": "Boosts Attack for one battle.",
    "X_DEFEND": "Boosts Defense for one battle.",
    "X_SPEED": "Boosts Speed for one battle.",
    "X_SPECIAL": "Boosts Special for one battle.",
    "COIN_CASE": "Holds the Game Corner coins you collect.",
    "OAKS_PARCEL": "A parcel that needs to be delivered to Professor Oak.",
    "ITEMFINDER": "Searches for hidden items nearby.",
    "SILPH_SCOPE": "A scope that reveals the true form of ghosts.",
    "POKE_FLUTE": "A flute with a sound that wakes sleeping Pokemon.",
    "LIFT_KEY": "Starts the elevator in Team Rocket's hideout.",
    "EXP_ALL": "Shares battle experience with the whole party.",
    "OLD_ROD": "A simple fishing rod for catching basic Pokemon.",
    "GOOD_ROD": "A better fishing rod for stronger bites.",
    "SUPER_ROD": "The best fishing rod for the biggest catches.",
    "PP_UP": "Raises the PP of one move.",
    "ETHER": "Restores PP to one move.",
    "MAX_ETHER": "Fully restores PP to one move.",
    "ELIXER": "Restores PP to all learned moves.",
    "MAX_ELIXER": "Fully restores PP to all learned moves.",
]
