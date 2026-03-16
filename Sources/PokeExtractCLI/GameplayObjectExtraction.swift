import Foundation
import PokeDataModel

func facingDirection(from raw: String) -> FacingDirection {
    switch raw {
    case "UP", "PLAYER_DIR_UP", "SPRITE_FACING_UP": return .up
    case "DOWN", "PLAYER_DIR_DOWN", "SPRITE_FACING_DOWN": return .down
    case "LEFT", "SPRITE_FACING_LEFT": return .left
    case "RIGHT", "SPRITE_FACING_RIGHT": return .right
    default: return .down
    }
}

func parseRawWarps(contents: String) -> [RawWarpEntry] {
    let regex = try! NSRegularExpression(pattern: #"warp_event\s+(\d+),\s+(\d+),\s+([A-Z0-9_]+),\s+(\d+)"#)
    let nsrange = NSRange(contents.startIndex..<contents.endIndex, in: contents)
    return regex.matches(in: contents, range: nsrange).compactMap { match in
        guard
            let xRange = Range(match.range(at: 1), in: contents),
            let yRange = Range(match.range(at: 2), in: contents),
            let targetRange = Range(match.range(at: 3), in: contents),
            let targetWarpRange = Range(match.range(at: 4), in: contents),
            let x = Int(contents[xRange]),
            let y = Int(contents[yRange]),
            let targetWarp = Int(contents[targetWarpRange])
        else {
            return nil
        }

        return RawWarpEntry(
            origin: .init(x: x, y: y),
            rawTargetMapID: String(contents[targetRange]),
            targetWarp: targetWarp
        )
    }
}

func parseBackgroundEvents(
    mapID: String,
    contents: String,
    mapScriptMetadata: MapScriptMetadata?
) -> [BackgroundEventManifest] {
    let regex = try! NSRegularExpression(pattern: #"bg_event\s+(\d+),\s+(\d+),\s+([A-Z0-9_]+)"#)
    let nsrange = NSRange(contents.startIndex..<contents.endIndex, in: contents)
    return regex.matches(in: contents, range: nsrange).enumerated().compactMap { index, match in
        guard
            let xRange = Range(match.range(at: 1), in: contents),
            let yRange = Range(match.range(at: 2), in: contents),
            let textRange = Range(match.range(at: 3), in: contents),
            let x = Int(contents[xRange]),
            let y = Int(contents[yRange])
        else {
            return nil
        }
        let textID = String(contents[textRange])
        return BackgroundEventManifest(
            id: "\(mapID.lowercased())_bg_\(index)",
            position: .init(x: x, y: y),
            dialogueID: dialogueID(for: mapID, textID: textID, mapScriptMetadata: mapScriptMetadata)
        )
    }
}

func parseObjects(
    mapID: String,
    contents: String,
    mapScriptMetadata: MapScriptMetadata?,
    objectVisibilityByConstant: [String: Bool],
    martStockLabels: Set<String>
) -> [MapObjectManifest] {
    let objectConstantNames = parseObjectConstantNames(contents: contents)
    let regex = try! NSRegularExpression(
        pattern: #"(?m)^\s*object_event\s+(\d+),\s+(\d+),\s+([A-Z0-9_]+),\s+([A-Z_]+),\s+([A-Z_]+),\s+([A-Z0-9_]+)(.*)$"#,
        options: [.anchorsMatchLines]
    )
    let nsrange = NSRange(contents.startIndex..<contents.endIndex, in: contents)
    return regex.matches(in: contents, range: nsrange).enumerated().compactMap { index, match in
        guard
            let xRange = Range(match.range(at: 1), in: contents),
            let yRange = Range(match.range(at: 2), in: contents),
            let spriteRange = Range(match.range(at: 3), in: contents),
            let movementRange = Range(match.range(at: 4), in: contents),
            let facingRange = Range(match.range(at: 5), in: contents),
            let textRange = Range(match.range(at: 6), in: contents),
            let x = Int(contents[xRange]),
            let y = Int(contents[yRange])
        else {
            return nil
        }

        let sprite = String(contents[spriteRange])
        let movement = String(contents[movementRange])
        let facing = facingDirection(from: String(contents[facingRange]))
        let textID = String(contents[textRange])
        let extraTokens = Range(match.range(at: 7), in: contents)
            .map { parseObjectExtraTokens(from: String(contents[$0])) } ?? []
        let trainerClass = extraTokens.count >= 2 ? extraTokens[0] : nil
        let trainerNumber = extraTokens.count >= 2 ? Int(extraTokens[1]) : nil
        let trainerBattleID = trainerBattleIDFor(trainerClass: trainerClass, trainerNumber: trainerNumber)
        let textLabel = mapScriptMetadata?.textLabelByTextID[textID]
        let trainerHeader = textLabel
            .flatMap { mapScriptMetadata?.trainerHeaderLabelByTextLabel[$0] }
            .flatMap { mapScriptMetadata?.trainerHeadersByLabel[$0] }
        let pickupItemID =
            sprite == "SPRITE_POKE_BALL" &&
            (mapScriptMetadata?.pickupTextIDs.contains(textID) ?? false) &&
            extraTokens.isEmpty == false
                ? extraTokens[0]
                : nil
        let position = TilePoint(x: x, y: y)
        let objectID = objectIDFor(
            mapID: mapID,
            index: index,
            textID: textID,
            pickupItemID: pickupItemID,
            mapScriptMetadata: mapScriptMetadata
        )
        let objectConstant = objectConstantNames.indices.contains(index) ? objectConstantNames[index] : nil
        let usesScriptedBattle = usesScriptedTrainerBattle(objectID: objectID)

        return MapObjectManifest(
            id: objectID,
            displayName: displayNameForObject(objectID: objectID, textID: textID, sprite: sprite, pickupItemID: pickupItemID),
            sprite: sprite,
            position: position,
            facing: facing,
            interactionReach: interactionReach(for: objectID, sprite: sprite),
            interactionTriggers: interactionTriggers(
                for: objectID,
                mapID: mapID,
                sprite: sprite,
                textLabel: textLabel,
                martStockLabels: martStockLabels
            ),
            interactionDialogueID: dialogueID(for: mapID, textID: textID, mapScriptMetadata: mapScriptMetadata),
            interactionScriptID: interactionScriptID(for: objectID, mapID: mapID, sprite: sprite),
            movementBehavior: movementBehavior(
                movementToken: movement,
                facingToken: String(contents[facingRange]),
                home: position
            ),
            trainerBattleID: usesScriptedBattle ? nil : trainerBattleID,
            trainerClass: usesScriptedBattle ? nil : trainerClass,
            trainerNumber: usesScriptedBattle ? nil : trainerNumber,
            trainerEngageDistance: usesScriptedBattle ? nil : trainerHeader?.engageDistance,
            trainerIntroDialogueID: usesScriptedBattle ? nil : trainerHeader.map { dialogueID(forScriptLabel: $0.battleTextLabel, mapScriptMetadata: mapScriptMetadata) },
            trainerEndBattleDialogueID: usesScriptedBattle ? nil : trainerHeader.map { dialogueID(forScriptLabel: $0.endBattleTextLabel, mapScriptMetadata: mapScriptMetadata) },
            trainerAfterBattleDialogueID: usesScriptedBattle ? nil : trainerHeader.map { dialogueID(forScriptLabel: $0.afterBattleTextLabel, mapScriptMetadata: mapScriptMetadata) },
            pickupItemID: pickupItemID,
            visibleByDefault: objectConstant.flatMap { objectVisibilityByConstant[$0] } ?? defaultVisibility(for: objectID)
        )
    }
}

private func parseObjectConstantNames(contents: String) -> [String] {
    contents
        .split(separator: "\n", omittingEmptySubsequences: false)
        .compactMap { rawLine -> String? in
            let line = rawLine
                .split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false)
                .first?
                .trimmingCharacters(in: .whitespaces) ?? ""
            if line.hasPrefix("def_object_events") {
                return nil
            }
            guard let match = line.firstMatch(of: /const_export\s+([A-Z0-9_]+)/) else {
                return nil
            }
            return String(match.output.1)
        }
}

func parseObjectExtraTokens(from suffix: String) -> [String] {
    let trimmed = suffix
        .split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false)
        .first?
        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    guard trimmed.isEmpty == false else {
        return []
    }
    return trimmed
        .split(separator: ",")
        .map { $0.trimmingCharacters(in: .whitespaces) }
        .filter { $0.isEmpty == false }
}

func dialogueID(forScriptLabel label: String, mapScriptMetadata: MapScriptMetadata?) -> String {
    let resolvedLabel = mapScriptMetadata?.farTextLabelByLocalLabel[label] ?? label
    return normalizedDialogueID(from: resolvedLabel)
}

func normalizedDialogueID(from label: String) -> String {
    let trimmed = label
        .trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        .replacingOccurrences(of: ".", with: "_")
    let withoutTextSuffix =
        trimmed.hasSuffix("Text")
            ? String(trimmed.dropLast(4))
            : trimmed

    return withoutTextSuffix
        .unicodeScalars
        .reduce(into: "") { partialResult, scalar in
            let character = Character(scalar)
            if CharacterSet.uppercaseLetters.contains(scalar), partialResult.isEmpty == false, partialResult.last != "_" {
                partialResult.append("_")
            }
            if CharacterSet.alphanumerics.contains(scalar) {
                partialResult.append(String(character).lowercased())
            } else if partialResult.last != "_" {
                partialResult.append("_")
            }
        }
        .trimmingCharacters(in: CharacterSet(charactersIn: "_"))
}

private func movementBehavior(
    movementToken: String,
    facingToken: String,
    home: TilePoint
) -> ObjectMovementBehavior {
    switch movementToken {
    case "WALK":
        let axis: ObjectMovementAxis
        switch facingToken {
        case "ANY_DIR":
            axis = .any
        case "UP_DOWN":
            axis = .upDown
        case "LEFT_RIGHT":
            axis = .leftRight
        default:
            axis = .any
        }
        return .init(idleMode: .walk, axis: axis, home: home)
    default:
        return .init(idleMode: .stay, axis: .none, home: home, maxDistanceFromHome: 0)
    }
}

func objectIDFor(
    mapID: String,
    index: Int,
    textID: String,
    pickupItemID: String?,
    mapScriptMetadata: MapScriptMetadata?
) -> String {
    switch (mapID, textID) {
    case ("PALLET_TOWN", "TEXT_PALLETTOWN_OAK"): return "pallet_town_oak"
    case ("PALLET_TOWN", "TEXT_PALLETTOWN_GIRL"): return "pallet_town_girl"
    case ("PALLET_TOWN", "TEXT_PALLETTOWN_FISHER"): return "pallet_town_fisher"
    case ("REDS_HOUSE_1F", "TEXT_REDSHOUSE1F_MOM"): return "reds_house_1f_mom"
    case ("ROUTE_1", "TEXT_ROUTE1_YOUNGSTER1"): return "route_1_youngster_1"
    case ("ROUTE_1", "TEXT_ROUTE1_YOUNGSTER2"): return "route_1_youngster_2"
    case ("ROUTE_22", "TEXT_ROUTE22_RIVAL1"): return "route_22_rival_1"
    case ("ROUTE_22", "TEXT_ROUTE22_RIVAL2"): return "route_22_rival_2"
    case ("ROUTE_22_GATE", "TEXT_ROUTE22GATE_GUARD"): return "route_22_gate_guard"
    case ("ROUTE_2", "TEXT_ROUTE2_MOON_STONE"): return "route_2_moon_stone"
    case ("ROUTE_2", "TEXT_ROUTE2_HP_UP"): return "route_2_hp_up"
    case ("VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_OLD_MAN_SLEEPY"): return "viridian_city_old_man_sleepy"
    case ("VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_OLD_MAN"): return "viridian_city_old_man_awake"
    case ("VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_GIRL"): return "viridian_city_girl"
    case ("VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_YOUNGSTER1"): return "viridian_city_youngster_1"
    case ("VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_YOUNGSTER2"): return "viridian_city_youngster_2"
    case ("VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_GAMBLER1"): return "viridian_city_gambler"
    case ("VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_FISHER"): return "viridian_city_fisher"
    case ("VIRIDIAN_SCHOOL_HOUSE", "TEXT_VIRIDIANSCHOOLHOUSE_BRUNETTE_GIRL"): return "viridian_school_house_brunette_girl"
    case ("VIRIDIAN_SCHOOL_HOUSE", "TEXT_VIRIDIANSCHOOLHOUSE_COOLTRAINER_F"): return "viridian_school_house_cooltrainer_f"
    case ("VIRIDIAN_NICKNAME_HOUSE", "TEXT_VIRIDIANNICKNAMEHOUSE_BALDING_GUY"): return "viridian_nickname_house_balding_guy"
    case ("VIRIDIAN_NICKNAME_HOUSE", "TEXT_VIRIDIANNICKNAMEHOUSE_LITTLE_GIRL"): return "viridian_nickname_house_little_girl"
    case ("VIRIDIAN_NICKNAME_HOUSE", "TEXT_VIRIDIANNICKNAMEHOUSE_SPEAROW"): return "viridian_nickname_house_spearow"
    case ("VIRIDIAN_NICKNAME_HOUSE", "TEXT_VIRIDIANNICKNAMEHOUSE_SPEARY_SIGN"): return "viridian_nickname_house_speary_sign"
    case ("VIRIDIAN_MART", "TEXT_VIRIDIANMART_CLERK"): return "viridian_mart_clerk"
    case ("VIRIDIAN_MART", "TEXT_VIRIDIANMART_YOUNGSTER"): return "viridian_mart_youngster"
    case ("VIRIDIAN_MART", "TEXT_VIRIDIANMART_COOLTRAINER_M"): return "viridian_mart_cooltrainer"
    case ("VIRIDIAN_FOREST_SOUTH_GATE", "TEXT_VIRIDIANFORESTSOUTHGATE_GIRL"): return "viridian_forest_south_gate_girl"
    case ("VIRIDIAN_FOREST_SOUTH_GATE", "TEXT_VIRIDIANFORESTSOUTHGATE_LITTLE_GIRL"): return "viridian_forest_south_gate_little_girl"
    case ("VIRIDIAN_FOREST", "TEXT_VIRIDIANFOREST_YOUNGSTER1"): return "viridian_forest_youngster_1"
    case ("VIRIDIAN_FOREST", "TEXT_VIRIDIANFOREST_YOUNGSTER2"): return "viridian_forest_bug_catcher_1"
    case ("VIRIDIAN_FOREST", "TEXT_VIRIDIANFOREST_YOUNGSTER3"): return "viridian_forest_bug_catcher_2"
    case ("VIRIDIAN_FOREST", "TEXT_VIRIDIANFOREST_YOUNGSTER4"): return "viridian_forest_bug_catcher_3"
    case ("VIRIDIAN_FOREST", "TEXT_VIRIDIANFOREST_ANTIDOTE"): return "viridian_forest_antidote"
    case ("VIRIDIAN_FOREST", "TEXT_VIRIDIANFOREST_POTION"): return "viridian_forest_potion"
    case ("VIRIDIAN_FOREST", "TEXT_VIRIDIANFOREST_POKE_BALL"): return "viridian_forest_poke_ball"
    case ("VIRIDIAN_FOREST", "TEXT_VIRIDIANFOREST_YOUNGSTER5"): return "viridian_forest_youngster_5"
    case ("VIRIDIAN_FOREST_NORTH_GATE", "TEXT_VIRIDIANFORESTNORTHGATE_SUPER_NERD"): return "viridian_forest_north_gate_super_nerd"
    case ("VIRIDIAN_FOREST_NORTH_GATE", "TEXT_VIRIDIANFORESTNORTHGATE_GRAMPS"): return "viridian_forest_north_gate_gramps"
    case ("PEWTER_CITY", "TEXT_PEWTERCITY_COOLTRAINER_F"): return "pewter_city_cooltrainer_f"
    case ("PEWTER_CITY", "TEXT_PEWTERCITY_COOLTRAINER_M"): return "pewter_city_cooltrainer_m"
    case ("PEWTER_CITY", "TEXT_PEWTERCITY_SUPER_NERD1"): return "pewter_city_super_nerd_1"
    case ("PEWTER_CITY", "TEXT_PEWTERCITY_SUPER_NERD2"): return "pewter_city_super_nerd_2"
    case ("PEWTER_CITY", "TEXT_PEWTERCITY_YOUNGSTER"): return "pewter_city_youngster"
    case ("PEWTER_GYM", "TEXT_PEWTERGYM_BROCK"): return "pewter_gym_brock"
    case ("PEWTER_GYM", "TEXT_PEWTERGYM_COOLTRAINER_M"): return "pewter_gym_cooltrainer_m"
    case ("PEWTER_GYM", "TEXT_PEWTERGYM_GYM_GUIDE"): return "pewter_gym_gym_guide"
    case ("CERULEAN_GYM", "TEXT_CERULEANGYM_MISTY"): return "cerulean_gym_misty"
    case ("CERULEAN_GYM", "TEXT_CERULEANGYM_COOLTRAINER_F"): return "cerulean_gym_cooltrainer_f"
    case ("CERULEAN_GYM", "TEXT_CERULEANGYM_SWIMMER"): return "cerulean_gym_swimmer"
    case ("CERULEAN_GYM", "TEXT_CERULEANGYM_GYM_GUIDE"): return "cerulean_gym_gym_guide"
    case ("CERULEAN_CITY", "TEXT_CERULEANCITY_RIVAL"): return "cerulean_city_rival"
    case ("CERULEAN_CITY", "TEXT_CERULEANCITY_ROCKET"): return "cerulean_city_rocket"
    case ("CERULEAN_CITY", "TEXT_CERULEANCITY_COOLTRAINER_M"): return "cerulean_city_cooltrainer_m"
    case ("CERULEAN_CITY", "TEXT_CERULEANCITY_SUPER_NERD1"): return "cerulean_city_super_nerd_1"
    case ("CERULEAN_CITY", "TEXT_CERULEANCITY_SUPER_NERD2"): return "cerulean_city_super_nerd_2"
    case ("CERULEAN_CITY", "TEXT_CERULEANCITY_GUARD1"): return "cerulean_city_guard_1"
    case ("CERULEAN_CITY", "TEXT_CERULEANCITY_COOLTRAINER_F1"): return "cerulean_city_cooltrainer_f_1"
    case ("CERULEAN_CITY", "TEXT_CERULEANCITY_SLOWBRO"): return "cerulean_city_slowbro"
    case ("CERULEAN_CITY", "TEXT_CERULEANCITY_COOLTRAINER_F2"): return "cerulean_city_cooltrainer_f_2"
    case ("CERULEAN_CITY", "TEXT_CERULEANCITY_SUPER_NERD3"): return "cerulean_city_super_nerd_3"
    case ("CERULEAN_CITY", "TEXT_CERULEANCITY_GUARD2"): return "cerulean_city_guard_2"
    case ("CERULEAN_POKECENTER", "TEXT_CERULEANPOKECENTER_NURSE"): return "cerulean_pokecenter_nurse"
    case ("CERULEAN_POKECENTER", "TEXT_CERULEANPOKECENTER_SUPER_NERD"): return "cerulean_pokecenter_super_nerd"
    case ("CERULEAN_POKECENTER", "TEXT_CERULEANPOKECENTER_GENTLEMAN"): return "cerulean_pokecenter_gentleman"
    case ("CERULEAN_POKECENTER", "TEXT_CERULEANPOKECENTER_LINK_RECEPTIONIST"): return "cerulean_pokecenter_link_receptionist"
    case ("CERULEAN_MART", "TEXT_CERULEANMART_CLERK"): return "cerulean_mart_clerk"
    case ("CERULEAN_MART", "TEXT_CERULEANMART_COOLTRAINER_M"): return "cerulean_mart_cooltrainer_m"
    case ("CERULEAN_MART", "TEXT_CERULEANMART_COOLTRAINER_F"): return "cerulean_mart_cooltrainer_f"
    case ("BIKE_SHOP", "TEXT_BIKESHOP_CLERK"): return "bike_shop_clerk"
    case ("BIKE_SHOP", "TEXT_BIKESHOP_MIDDLE_AGED_WOMAN"): return "bike_shop_middle_aged_woman"
    case ("BIKE_SHOP", "TEXT_BIKESHOP_YOUNGSTER"): return "bike_shop_youngster"
    case ("CERULEAN_TRADE_HOUSE", "TEXT_CERULEANTRADEHOUSE_GRANNY"): return "cerulean_trade_house_granny"
    case ("CERULEAN_TRADE_HOUSE", "TEXT_CERULEANTRADEHOUSE_GAMBLER"): return "cerulean_trade_house_gambler"
    case ("CERULEAN_BADGE_HOUSE", "TEXT_CERULEANBADGEHOUSE_MIDDLE_AGED_MAN"): return "cerulean_badge_house_middle_aged_man"
    case ("CERULEAN_TRASHED_HOUSE", "TEXT_CERULEANTRASHEDHOUSE_FISHING_GURU"): return "cerulean_trashed_house_fishing_guru"
    case ("CERULEAN_TRASHED_HOUSE", "TEXT_CERULEANTRASHEDHOUSE_GIRL"): return "cerulean_trashed_house_girl"
    case ("ROUTE_24", "TEXT_ROUTE24_COOLTRAINER_M1"): return "route24_nugget_bridge_guy"
    case ("ROUTE_24", "TEXT_ROUTE24_COOLTRAINER_M2"): return "route24_cooltrainer_m_2"
    case ("ROUTE_24", "TEXT_ROUTE24_COOLTRAINER_M3"): return "route24_cooltrainer_m_3"
    case ("ROUTE_24", "TEXT_ROUTE24_COOLTRAINER_F1"): return "route24_cooltrainer_f_1"
    case ("ROUTE_24", "TEXT_ROUTE24_YOUNGSTER1"): return "route24_youngster_1"
    case ("ROUTE_24", "TEXT_ROUTE24_COOLTRAINER_F2"): return "route24_cooltrainer_f_2"
    case ("ROUTE_24", "TEXT_ROUTE24_YOUNGSTER2"): return "route24_youngster_2"
    case ("ROUTE_24", "TEXT_ROUTE24_TM_THUNDER_WAVE"): return "route_24_tm_thunder_wave"
    case ("ROUTE_25", "TEXT_ROUTE25_YOUNGSTER1"): return "route25_youngster_1"
    case ("ROUTE_25", "TEXT_ROUTE25_YOUNGSTER2"): return "route25_youngster_2"
    case ("ROUTE_25", "TEXT_ROUTE25_COOLTRAINER_M"): return "route25_cooltrainer_m"
    case ("ROUTE_25", "TEXT_ROUTE25_COOLTRAINER_F1"): return "route25_cooltrainer_f_1"
    case ("ROUTE_25", "TEXT_ROUTE25_YOUNGSTER3"): return "route25_youngster_3"
    case ("ROUTE_25", "TEXT_ROUTE25_COOLTRAINER_F2"): return "route25_cooltrainer_f_2"
    case ("ROUTE_25", "TEXT_ROUTE25_HIKER1"): return "route25_hiker_1"
    case ("ROUTE_25", "TEXT_ROUTE25_HIKER2"): return "route25_hiker_2"
    case ("ROUTE_25", "TEXT_ROUTE25_HIKER3"): return "route25_hiker_3"
    case ("ROUTE_25", "TEXT_ROUTE25_TM_SEISMIC_TOSS"): return "route_25_tm_seismic_toss"
    case ("BILLS_HOUSE", "TEXT_BILLSHOUSE_BILL_POKEMON"): return "bills_house_bill_pokemon"
    case ("BILLS_HOUSE", "TEXT_BILLSHOUSE_BILL_SS_TICKET"): return "bills_house_bill_1"
    case ("BILLS_HOUSE", "TEXT_BILLSHOUSE_BILL_CHECK_OUT_MY_RARE_POKEMON"): return "bills_house_bill_2"
    case ("MT_MOON_1F", "TEXT_MTMOON1F_POTION1"): return "mt_moon_1f_potion_1"
    case ("MT_MOON_1F", "TEXT_MTMOON1F_POTION2"): return "mt_moon_1f_potion_2"
    case ("MT_MOON_B2F", "TEXT_MTMOONB2F_SUPER_NERD"): return "mt_moon_b2f_super_nerd"
    case ("MT_MOON_B2F", "TEXT_MTMOONB2F_ROCKET1"): return "mt_moon_b2f_rocket_1"
    case ("MT_MOON_B2F", "TEXT_MTMOONB2F_ROCKET2"): return "mt_moon_b2f_rocket_2"
    case ("MT_MOON_B2F", "TEXT_MTMOONB2F_ROCKET3"): return "mt_moon_b2f_rocket_3"
    case ("MT_MOON_B2F", "TEXT_MTMOONB2F_ROCKET4"): return "mt_moon_b2f_rocket_4"
    case ("MT_MOON_B2F", "TEXT_MTMOONB2F_DOME_FOSSIL"): return "mt_moon_b2f_dome_fossil"
    case ("MT_MOON_B2F", "TEXT_MTMOONB2F_HELIX_FOSSIL"): return "mt_moon_b2f_helix_fossil"
    case ("VIRIDIAN_POKECENTER", "TEXT_VIRIDIANPOKECENTER_NURSE"): return "viridian_pokecenter_nurse"
    case ("VIRIDIAN_POKECENTER", "TEXT_VIRIDIANPOKECENTER_GENTLEMAN"): return "viridian_pokecenter_gentleman"
    case ("VIRIDIAN_POKECENTER", "TEXT_VIRIDIANPOKECENTER_COOLTRAINER_M"): return "viridian_pokecenter_cooltrainer"
    case ("VIRIDIAN_POKECENTER", "TEXT_VIRIDIANPOKECENTER_LINK_RECEPTIONIST"): return "viridian_pokecenter_link_receptionist"
    case ("OAKS_LAB", "TEXT_OAKSLAB_RIVAL"): return "oaks_lab_rival"
    case ("OAKS_LAB", "TEXT_OAKSLAB_CHARMANDER_POKE_BALL"): return "oaks_lab_poke_ball_charmander"
    case ("OAKS_LAB", "TEXT_OAKSLAB_SQUIRTLE_POKE_BALL"): return "oaks_lab_poke_ball_squirtle"
    case ("OAKS_LAB", "TEXT_OAKSLAB_BULBASAUR_POKE_BALL"): return "oaks_lab_poke_ball_bulbasaur"
    case ("OAKS_LAB", "TEXT_OAKSLAB_OAK1"): return "oaks_lab_oak_1"
    case ("OAKS_LAB", "TEXT_OAKSLAB_OAK2"): return "oaks_lab_oak_2"
    case ("OAKS_LAB", "TEXT_OAKSLAB_POKEDEX1"): return "oaks_lab_pokedex_1"
    case ("OAKS_LAB", "TEXT_OAKSLAB_POKEDEX2"): return "oaks_lab_pokedex_2"
    default:
        if let pickupItemID {
            return "\(mapID.lowercased())_\(pickupItemID.lowercased())"
        }
        if let fallbackObjectID = fallbackObjectID(for: textID, mapScriptMetadata: mapScriptMetadata) {
            return fallbackObjectID
        }
        return "\(mapID.lowercased())_object_\(index)"
    }
}

private func fallbackObjectID(for textID: String, mapScriptMetadata: MapScriptMetadata?) -> String? {
    guard
        let mapScriptMetadata,
        let baseID = fallbackObjectIDBase(for: textID, mapScriptMetadata: mapScriptMetadata)
    else {
        return nil
    }

    let matchingTextIDs = mapScriptMetadata.textLabelByTextID.keys
        .filter { fallbackObjectIDBase(for: $0, mapScriptMetadata: mapScriptMetadata) == baseID }
        .sorted()

    guard matchingTextIDs.count > 1, let matchingIndex = matchingTextIDs.firstIndex(of: textID) else {
        return baseID
    }

    return "\(baseID)_\(matchingIndex + 1)"
}

private func fallbackObjectIDBase(for textID: String, mapScriptMetadata: MapScriptMetadata) -> String? {
    guard let localLabel = mapScriptMetadata.textLabelByTextID[textID] else {
        return nil
    }

    return dialogueID(forScriptLabel: localLabel, mapScriptMetadata: mapScriptMetadata)
}

private func interactionReach(for objectID: String, sprite: String) -> ObjectInteractionReach {
    switch objectID {
    case "viridian_mart_clerk", "viridian_pokecenter_nurse", "museum1_f_scientist1_come_again", "bike_shop_clerk":
        return .overCounter
    default:
        switch sprite {
        case "SPRITE_CLERK", "SPRITE_NURSE":
            return .overCounter
        default:
            return .adjacent
        }
    }
}

private func interactionScriptID(for objectID: String, mapID: String, sprite: String) -> String? {
    switch objectID {
    case "viridian_pokecenter_nurse":
        return "viridian_pokecenter_nurse_heal"
    case "bills_house_bill_pokemon":
        return "bills_house_bill_pokemon_interaction"
    case "mt_moon_b2f_super_nerd":
        return "mt_moon_b2f_super_nerd_battle"
    case "mt_moon_b2f_dome_fossil":
        return "mt_moon_b2f_take_dome_fossil"
    case "mt_moon_b2f_helix_fossil":
        return "mt_moon_b2f_take_helix_fossil"
    default:
        if sprite == "SPRITE_NURSE" {
            return pokemonCenterHealScriptID(for: mapID)
        }
        return nil
    }
}

private func interactionTriggers(
    for objectID: String,
    mapID: String,
    sprite: String,
    textLabel: String?,
    martStockLabels: Set<String>
) -> [ObjectInteractionTriggerManifest] {
    switch objectID {
    case "reds_house_1f_mom":
        return [
            .init(
                conditions: [.init(kind: "flagSet", flagID: "EVENT_GOT_STARTER")],
                scriptID: "reds_house_1f_mom_heal"
            ),
        ]
    case "oaks_lab_rival":
        return [
            .init(
                conditions: [.init(kind: "flagSet", flagID: "EVENT_GOT_STARTER")],
                dialogueID: "oaks_lab_rival_my_pokemon_looks_stronger"
            ),
            .init(dialogueID: "oaks_lab_rival_gramps_isnt_around"),
        ]
    case "oaks_lab_oak_1":
        return [
            .init(
                conditions: [.init(kind: "flagSet", flagID: "EVENT_GOT_POKEDEX")],
                dialogueID: "oaks_lab_oak_how_is_your_pokedex_coming"
            ),
            .init(
                conditions: [
                    .init(kind: "flagSet", flagID: "EVENT_BATTLED_RIVAL_IN_OAKS_LAB"),
                    .init(kind: "flagSet", flagID: "EVENT_GOT_OAKS_PARCEL"),
                    .init(kind: "flagUnset", flagID: "EVENT_OAK_GOT_PARCEL"),
                ],
                scriptID: "oaks_lab_parcel_handoff"
            ),
            .init(
                conditions: [.init(kind: "flagSet", flagID: "EVENT_BATTLED_RIVAL_IN_OAKS_LAB")],
                dialogueID: "oaks_lab_oak_raise_your_young_pokemon"
            ),
            .init(
                conditions: [.init(kind: "flagSet", flagID: "EVENT_GOT_STARTER")],
                dialogueID: "oaks_lab_oak_raise_your_young_pokemon"
            ),
            .init(
                conditions: [.init(kind: "flagSet", flagID: "EVENT_OAK_ASKED_TO_CHOOSE_MON")],
                dialogueID: "oaks_lab_oak_which_pokemon_do_you_want"
            ),
            .init(dialogueID: "oaks_lab_oak_choose_mon"),
        ]
    case "mt_moon_b2f_super_nerd":
        return [
            .init(
                conditions: [.init(kind: "flagSet", flagID: "EVENT_GOT_DOME_FOSSIL")],
                dialogueID: "mt_moon_b2f_super_nerd_theres_a_pokemon_lab"
            ),
            .init(
                conditions: [.init(kind: "flagSet", flagID: "EVENT_GOT_HELIX_FOSSIL")],
                dialogueID: "mt_moon_b2f_super_nerd_theres_a_pokemon_lab"
            ),
            .init(
                conditions: [.init(kind: "flagSet", flagID: "EVENT_BEAT_MT_MOON_EXIT_SUPER_NERD")],
                dialogueID: "mt_moon_b2f_super_nerd_each_take_one"
            ),
        ]
    case "cerulean_city_rocket":
        return [
            .init(
                conditions: [.init(kind: "flagSet", flagID: "EVENT_BEAT_CERULEAN_ROCKET_THIEF")],
                scriptID: "cerulean_city_rocket_reward"
            ),
        ]
    case "route24_nugget_bridge_guy":
        return [
            .init(
                conditions: [.init(kind: "flagSet", flagID: "EVENT_GOT_NUGGET")],
                dialogueID: "route24_cooltrainer_m1_you_could_become_a_top_leader"
            ),
            .init(scriptID: "route24_nugget_bridge_reward"),
        ]
    case "bills_house_bill_1":
        return [
            .init(
                conditions: [.init(kind: "flagSet", flagID: "EVENT_GOT_SS_TICKET")],
                dialogueID: "bills_house_bill_why_dont_you_go_instead_of_me"
            ),
            .init(scriptID: "bills_house_bill_ss_ticket"),
        ]
    case "bills_house_bill_2":
        return [.init(dialogueID: "bills_house_bill_check_out_my_rare_pokemon")]
    case "route_1_youngster_1":
        return [
            .init(
                conditions: [.init(kind: "flagSet", flagID: "EVENT_GOT_POTION_SAMPLE")],
                dialogueID: "route_1_youngster_1_after_sample"
            ),
            .init(scriptID: "route_1_potion_sample"),
        ]
    case "viridian_city_girl":
        return [
            .init(
                conditions: [.init(kind: "flagSet", flagID: "EVENT_GOT_POKEDEX")],
                dialogueID: "viridian_city_girl_after_pokedex"
            ),
        ]
    case "route_22_rival_1":
        return [
            .init(
                conditions: [.init(kind: "flagSet", flagID: "EVENT_BEAT_ROUTE22_RIVAL_1ST_BATTLE")],
                dialogueID: "route_22_rival_after_battle_1"
            ),
        ]
    case "route_22_rival_2":
        return [
            .init(
                conditions: [.init(kind: "flagSet", flagID: "EVENT_BEAT_ROUTE22_RIVAL_2ND_BATTLE")],
                dialogueID: "route_22_rival_after_battle_2"
            ),
        ]
    case "route_22_gate_guard":
        return [
            .init(
                conditions: [.init(kind: "flagSet", flagID: "EVENT_BEAT_BROCK")],
                dialogueID: "route_22_gate_guard_go_right_ahead"
            ),
        ]
    case "viridian_mart_clerk":
        return [
            .init(
                conditions: [.init(kind: "flagUnset", flagID: "EVENT_GOT_OAKS_PARCEL")],
                scriptID: "viridian_mart_oaks_parcel"
            ),
            .init(
                conditions: [
                    .init(kind: "flagSet", flagID: "EVENT_GOT_OAKS_PARCEL"),
                    .init(kind: "flagUnset", flagID: "EVENT_OAK_GOT_PARCEL"),
                ],
                dialogueID: "viridian_mart_clerk_after_parcel"
            ),
            .init(
                conditions: [.init(kind: "flagSet", flagID: "EVENT_OAK_GOT_PARCEL")],
                martID: "viridian_mart"
            ),
        ]
    case "bike_shop_clerk":
        return [
            .init(
                conditions: [.init(kind: "flagSet", flagID: "EVENT_GOT_BICYCLE")],
                dialogueID: "bike_shop_clerk_how_do_you_like_your_bicycle"
            ),
            .init(
                conditions: [
                    .init(kind: "flagUnset", flagID: "EVENT_GOT_BICYCLE"),
                    .init(kind: "itemPresent", stringValue: "BIKE_VOUCHER"),
                ],
                scriptID: "bike_shop_exchange_voucher"
            ),
            .init(scriptID: "bike_shop_offer_purchase"),
        ]
    case "bike_shop_youngster":
        return [
            .init(
                conditions: [.init(kind: "flagSet", flagID: "EVENT_GOT_BICYCLE")],
                dialogueID: "bike_shop_youngster_cool_bike"
            ),
            .init(dialogueID: "bike_shop_youngster_these_bikes_are_expensive"),
        ]
    case "cerulean_trashed_house_fishing_guru":
        return [
            .init(
                conditions: [.init(kind: "itemPresent", stringValue: "TM_DIG")],
                dialogueID: "cerulean_trashed_house_fishing_guru_whats_lost_is_lost"
            ),
            .init(dialogueID: "cerulean_trashed_house_fishing_guru_they_stole_a_t_m"),
        ]
    case "museum1_f_scientist1_come_again":
        return [
            .init(
                conditions: [
                    .init(kind: "flagUnset", flagID: "EVENT_BOUGHT_MUSEUM_TICKET"),
                    .init(kind: "playerYEquals", intValue: 4),
                    .init(kind: "playerXEquals", intValue: 10),
                ],
                scriptID: "museum_1f_scientist1_interaction"
            ),
            .init(
                conditions: [
                    .init(kind: "flagUnset", flagID: "EVENT_BOUGHT_MUSEUM_TICKET"),
                    .init(kind: "playerYEquals", intValue: 4),
                    .init(kind: "playerXEquals", intValue: 11),
                ],
                scriptID: "museum_1f_scientist1_interaction"
            ),
            .init(
                conditions: [.init(kind: "flagSet", flagID: "EVENT_BOUGHT_MUSEUM_TICKET")],
                dialogueID: "museum1_f_scientist1_take_plenty_of_time"
            ),
            .init(
                conditions: [.init(kind: "flagUnset", flagID: "EVENT_BOUGHT_MUSEUM_TICKET")],
                dialogueID: "museum1_f_scientist1_go_to_other_side"
            ),
        ]
    case "oaks_lab_poke_ball_charmander":
        return starterBallInteractionTriggers(speciesID: "CHARMANDER", scriptID: "oaks_lab_choose_charmander")
    case "oaks_lab_poke_ball_squirtle":
        return starterBallInteractionTriggers(speciesID: "SQUIRTLE", scriptID: "oaks_lab_choose_squirtle")
    case "oaks_lab_poke_ball_bulbasaur":
        return starterBallInteractionTriggers(speciesID: "BULBASAUR", scriptID: "oaks_lab_choose_bulbasaur")
    case "pewter_gym_brock":
        return [
            .init(
                conditions: [
                    .init(kind: "flagSet", flagID: "EVENT_BEAT_BROCK"),
                    .init(kind: "flagSet", flagID: "EVENT_GOT_TM34"),
                ],
                dialogueID: "pewter_gym_brock_post_battle_advice"
            ),
            .init(
                conditions: [
                    .init(kind: "flagSet", flagID: "EVENT_BEAT_BROCK"),
                    .init(kind: "flagUnset", flagID: "EVENT_GOT_TM34"),
                ],
                scriptID: "pewter_gym_brock_reward"
            ),
            .init(scriptID: "pewter_gym_brock_battle"),
        ]
    case "pewter_gym_gym_guide":
        return [
            .init(
                conditions: [.init(kind: "flagSet", flagID: "EVENT_BEAT_BROCK")],
                dialogueID: "pewter_gym_guide_post_battle"
            ),
            .init(dialogueID: "pewter_gym_guide_pre_advice"),
        ]
    case "cerulean_gym_misty":
        return [
            .init(
                conditions: [
                    .init(kind: "flagSet", flagID: "EVENT_BEAT_MISTY"),
                    .init(kind: "flagSet", flagID: "EVENT_GOT_TM11"),
                ],
                dialogueID: "cerulean_gym_misty_tm11_explanation"
            ),
            .init(
                conditions: [
                    .init(kind: "flagSet", flagID: "EVENT_BEAT_MISTY"),
                    .init(kind: "flagUnset", flagID: "EVENT_GOT_TM11"),
                ],
                scriptID: "cerulean_gym_misty_reward"
            ),
            .init(scriptID: "cerulean_gym_misty_battle"),
        ]
    case "cerulean_gym_gym_guide":
        return [
            .init(
                conditions: [.init(kind: "flagSet", flagID: "EVENT_BEAT_MISTY")],
                dialogueID: "cerulean_gym_gym_guide_beat_misty"
            ),
            .init(dialogueID: "cerulean_gym_gym_guide_champ_in_making"),
        ]
    default:
        if sprite == "SPRITE_CLERK", let textLabel, martStockLabels.contains(textLabel) {
            return [.init(martID: martID(for: mapID))]
        }
        return []
    }
}

private func starterBallInteractionTriggers(speciesID _: String, scriptID: String) -> [ObjectInteractionTriggerManifest] {
    return [
        .init(
            conditions: [.init(kind: "flagUnset", flagID: "EVENT_OAK_ASKED_TO_CHOOSE_MON")],
            dialogueID: "oaks_lab_those_are_pokeballs"
        ),
        .init(
            conditions: [.init(kind: "flagSet", flagID: "EVENT_GOT_STARTER")],
            dialogueID: "oaks_lab_last_mon"
        ),
        .init(scriptID: scriptID),
    ]
}

private func displayNameForObject(
    objectID: String,
    textID: String,
    sprite: String,
    pickupItemID: String?
) -> String {
    switch objectID {
    case "pallet_town_oak": return "Oak"
    case "pallet_town_girl": return "Girl"
    case "pallet_town_fisher": return "Fisher"
    case "reds_house_1f_mom": return "Mom"
    case "route_1_youngster_1", "route_1_youngster_2": return "Youngster"
    case "route_2_moon_stone": return "Moon Stone"
    case "route_2_hp_up": return "HP Up"
    case "viridian_city_old_man_sleepy", "viridian_city_old_man_awake": return "Old Man"
    case "viridian_city_girl": return "Girl"
    case "viridian_city_youngster_1", "viridian_city_youngster_2": return "Youngster"
    case "viridian_city_gambler": return "Gambler"
    case "viridian_city_fisher": return "Fisher"
    case "viridian_school_house_brunette_girl": return "Brunette Girl"
    case "viridian_school_house_cooltrainer_f": return "Cooltrainer"
    case "viridian_nickname_house_balding_guy": return "Balding Guy"
    case "viridian_nickname_house_little_girl": return "Little Girl"
    case "viridian_nickname_house_spearow": return "Spearow"
    case "viridian_nickname_house_speary_sign": return "Speary Sign"
    case "viridian_mart_clerk": return "Clerk"
    case "viridian_mart_youngster": return "Youngster"
    case "viridian_mart_cooltrainer": return "Cooltrainer"
    case "viridian_forest_south_gate_girl": return "Girl"
    case "viridian_forest_south_gate_little_girl": return "Little Girl"
    case "viridian_forest_youngster_1", "viridian_forest_youngster_5": return "Youngster"
    case "viridian_forest_bug_catcher_1", "viridian_forest_bug_catcher_2", "viridian_forest_bug_catcher_3":
        return "Bug Catcher"
    case "viridian_forest_antidote": return "Antidote"
    case "viridian_forest_potion": return "Potion"
    case "viridian_forest_poke_ball": return "Poke Ball"
    case "viridian_forest_north_gate_super_nerd": return "Super Nerd"
    case "viridian_forest_north_gate_gramps": return "Gramps"
    case "viridian_pokecenter_nurse": return "Nurse"
    case "viridian_pokecenter_gentleman": return "Gentleman"
    case "viridian_pokecenter_cooltrainer": return "Cooltrainer"
    case "viridian_pokecenter_link_receptionist": return "Receptionist"
    case "oaks_lab_rival": return "Blue"
    case "oaks_lab_poke_ball_charmander": return "Charmander"
    case "oaks_lab_poke_ball_squirtle": return "Squirtle"
    case "oaks_lab_poke_ball_bulbasaur": return "Bulbasaur"
    case "oaks_lab_oak_1", "oaks_lab_oak_2": return "Oak"
    case "oaks_lab_pokedex_1", "oaks_lab_pokedex_2": return "Pokedex"
    case "route_22_rival_1", "route_22_rival_2": return "Blue"
    case "cerulean_city_rival": return "Blue"
    case "cerulean_city_rocket", "route24_nugget_bridge_guy": return "Rocket"
    case "bills_house_bill_pokemon", "bills_house_bill_1", "bills_house_bill_2": return "Bill"
    case "pewter_city_cooltrainer_f", "pewter_city_cooltrainer_m": return "Cooltrainer"
    case "pewter_city_super_nerd_1", "pewter_city_super_nerd_2": return "Super Nerd"
    case "pewter_city_youngster": return "Youngster"
    case "pewter_gym_brock": return "Brock"
    case "pewter_gym_cooltrainer_m": return "Cooltrainer"
    case "pewter_gym_gym_guide": return "Gym Guide"
    case "cerulean_gym_misty": return "Misty"
    case "cerulean_gym_cooltrainer_f": return "Cooltrainer"
    case "cerulean_gym_swimmer": return "Swimmer"
    case "cerulean_gym_gym_guide": return "Gym Guide"
    default:
        if let pickupItemID {
            return humanizedIdentifier(pickupItemID)
        }
        if let spriteDisplayName = displayName(forSprite: sprite) {
            return spriteDisplayName
        }
        return humanizedIdentifier(objectID.isEmpty ? textID : objectID)
    }
}

func trainerBattleIDFor(trainerClass: String?, trainerNumber: Int?) -> String? {
    guard let trainerClass, let trainerNumber else { return nil }
    return "\(trainerClass.lowercased())_\(trainerNumber)"
}

private func usesScriptedTrainerBattle(objectID: String) -> Bool {
    switch objectID {
    case
        "route_22_rival_1",
        "route_22_rival_2",
        "pewter_gym_brock",
        "cerulean_gym_misty",
        "mt_moon_b2f_super_nerd",
        "cerulean_city_rival",
        "cerulean_city_rocket",
        "route24_nugget_bridge_guy":
        return true
    default:
        return false
    }
}

private func defaultVisibility(for objectID: String) -> Bool {
    switch objectID {
    case "pallet_town_oak", "oaks_lab_oak_2", "viridian_city_old_man_awake":
        return false
    default:
        return true
    }
}

func dialogueID(for mapID: String, textID: String, mapScriptMetadata: MapScriptMetadata?) -> String {
    switch (mapID, textID) {
    case ("PALLET_TOWN", "TEXT_PALLETTOWN_OAK"): return "pallet_town_oak_its_unsafe"
    case ("PALLET_TOWN", "TEXT_PALLETTOWN_GIRL"): return "pallet_town_girl"
    case ("PALLET_TOWN", "TEXT_PALLETTOWN_FISHER"): return "pallet_town_fisher"
    case ("PALLET_TOWN", "TEXT_PALLETTOWN_OAKSLAB_SIGN"): return "pallet_town_oaks_lab_sign"
    case ("PALLET_TOWN", "TEXT_PALLETTOWN_SIGN"): return "pallet_town_sign"
    case ("PALLET_TOWN", "TEXT_PALLETTOWN_PLAYERSHOUSE_SIGN"): return "pallet_town_players_house_sign"
    case ("PALLET_TOWN", "TEXT_PALLETTOWN_RIVALSHOUSE_SIGN"): return "pallet_town_rivals_house_sign"
    case ("REDS_HOUSE_1F", "TEXT_REDSHOUSE1F_MOM"): return "reds_house_1f_mom_wakeup"
    case ("REDS_HOUSE_1F", "TEXT_REDSHOUSE1F_TV"): return "reds_house_1f_tv"
    case ("ROUTE_1", "TEXT_ROUTE1_YOUNGSTER1"): return "route_1_youngster_1_after_sample"
    case ("ROUTE_1", "TEXT_ROUTE1_YOUNGSTER2"): return "route_1_youngster_2"
    case ("ROUTE_1", "TEXT_ROUTE1_SIGN"): return "route_1_sign"
    case ("ROUTE_22", "TEXT_ROUTE22_POKEMON_LEAGUE_SIGN"): return "route_22_pokemon_league_sign"
    case ("ROUTE_22", "TEXT_ROUTE22_RIVAL1"): return "route_22_rival_before_battle_1"
    case ("ROUTE_22", "TEXT_ROUTE22_RIVAL2"): return "route_22_rival_before_battle_2"
    case ("ROUTE_22_GATE", "TEXT_ROUTE22GATE_GUARD"): return "route_22_gate_guard_no_boulder_badge"
    case ("ROUTE_2", "TEXT_ROUTE2_SIGN"): return "route_2_sign"
    case ("ROUTE_2", "TEXT_ROUTE2_DIGLETTS_CAVE_SIGN"): return "route_2_digletts_cave_sign"
    case ("VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_YOUNGSTER1"): return "viridian_city_youngster_1"
    case ("VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_GAMBLER1"): return "viridian_city_gambler"
    case ("VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_YOUNGSTER2"): return "viridian_city_youngster_2_prompt"
    case ("VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_GIRL"): return "viridian_city_girl_before_pokedex"
    case ("VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_OLD_MAN_SLEEPY"): return "viridian_city_old_man_private_property"
    case ("VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_FISHER"): return "viridian_city_fisher"
    case ("VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_OLD_MAN"): return "viridian_city_old_man_had_coffee"
    case ("VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_SIGN"): return "viridian_city_sign"
    case ("VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_TRAINER_TIPS1"): return "viridian_city_trainer_tips_1"
    case ("VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_TRAINER_TIPS2"): return "viridian_city_trainer_tips_2"
    case ("VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_MART_SIGN"): return "viridian_city_mart_sign"
    case ("VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_POKECENTER_SIGN"): return "viridian_city_pokecenter_sign"
    case ("VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_GYM_SIGN"): return "viridian_city_gym_sign"
    case ("VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_GYM_LOCKED"): return "viridian_city_gym_locked"
    case ("VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_OLD_MAN_YOU_NEED_TO_WEAKEN_THE_TARGET"): return "viridian_city_old_man_weaken_target"
    case ("VIRIDIAN_SCHOOL_HOUSE", "TEXT_VIRIDIANSCHOOLHOUSE_BRUNETTE_GIRL"): return "viridian_school_house_brunette_girl"
    case ("VIRIDIAN_SCHOOL_HOUSE", "TEXT_VIRIDIANSCHOOLHOUSE_COOLTRAINER_F"): return "viridian_school_house_cooltrainer_f"
    case ("VIRIDIAN_NICKNAME_HOUSE", "TEXT_VIRIDIANNICKNAMEHOUSE_BALDING_GUY"): return "viridian_nickname_house_balding_guy"
    case ("VIRIDIAN_NICKNAME_HOUSE", "TEXT_VIRIDIANNICKNAMEHOUSE_LITTLE_GIRL"): return "viridian_nickname_house_little_girl"
    case ("VIRIDIAN_NICKNAME_HOUSE", "TEXT_VIRIDIANNICKNAMEHOUSE_SPEAROW"): return "viridian_nickname_house_spearow"
    case ("VIRIDIAN_NICKNAME_HOUSE", "TEXT_VIRIDIANNICKNAMEHOUSE_SPEARY_SIGN"): return "viridian_nickname_house_speary_sign"
    case ("VIRIDIAN_MART", "TEXT_VIRIDIANMART_CLERK"): return "viridian_mart_clerk_after_parcel"
    case ("VIRIDIAN_MART", "TEXT_VIRIDIANMART_YOUNGSTER"): return "viridian_mart_youngster"
    case ("VIRIDIAN_MART", "TEXT_VIRIDIANMART_COOLTRAINER_M"): return "viridian_mart_cooltrainer"
    case ("VIRIDIAN_FOREST_SOUTH_GATE", "TEXT_VIRIDIANFORESTSOUTHGATE_GIRL"): return "viridian_forest_south_gate_girl"
    case ("VIRIDIAN_FOREST_SOUTH_GATE", "TEXT_VIRIDIANFORESTSOUTHGATE_LITTLE_GIRL"): return "viridian_forest_south_gate_little_girl"
    case ("VIRIDIAN_FOREST", "TEXT_VIRIDIANFOREST_YOUNGSTER1"): return "viridian_forest_youngster_1"
    case ("VIRIDIAN_FOREST", "TEXT_VIRIDIANFOREST_YOUNGSTER5"): return "viridian_forest_youngster_5"
    case ("VIRIDIAN_FOREST", "TEXT_VIRIDIANFOREST_TRAINER_TIPS1"): return "viridian_forest_trainer_tips_1"
    case ("VIRIDIAN_FOREST", "TEXT_VIRIDIANFOREST_USE_ANTIDOTE_SIGN"): return "viridian_forest_use_antidote_sign"
    case ("VIRIDIAN_FOREST", "TEXT_VIRIDIANFOREST_TRAINER_TIPS2"): return "viridian_forest_trainer_tips_2"
    case ("VIRIDIAN_FOREST", "TEXT_VIRIDIANFOREST_TRAINER_TIPS3"): return "viridian_forest_trainer_tips_3"
    case ("VIRIDIAN_FOREST", "TEXT_VIRIDIANFOREST_TRAINER_TIPS4"): return "viridian_forest_trainer_tips_4"
    case ("VIRIDIAN_FOREST", "TEXT_VIRIDIANFOREST_LEAVING_SIGN"): return "viridian_forest_leaving_sign"
    case ("VIRIDIAN_FOREST_NORTH_GATE", "TEXT_VIRIDIANFORESTNORTHGATE_SUPER_NERD"): return "viridian_forest_north_gate_super_nerd"
    case ("VIRIDIAN_FOREST_NORTH_GATE", "TEXT_VIRIDIANFORESTNORTHGATE_GRAMPS"): return "viridian_forest_north_gate_gramps"
    case ("PEWTER_CITY", "TEXT_PEWTERCITY_COOLTRAINER_F"): return "pewter_city_cooltrainer_f"
    case ("PEWTER_CITY", "TEXT_PEWTERCITY_COOLTRAINER_M"): return "pewter_city_cooltrainer_m"
    case ("PEWTER_CITY", "TEXT_PEWTERCITY_SUPER_NERD1"): return "pewter_city_super_nerd_1"
    case ("PEWTER_CITY", "TEXT_PEWTERCITY_SUPER_NERD2"): return "pewter_city_super_nerd_2"
    case ("PEWTER_CITY", "TEXT_PEWTERCITY_YOUNGSTER"): return "pewter_city_youngster_follow_me"
    case ("PEWTER_CITY", "TEXT_PEWTERCITY_TRAINER_TIPS"): return "pewter_city_trainer_tips"
    case ("PEWTER_CITY", "TEXT_PEWTERCITY_POLICE_NOTICE_SIGN"): return "pewter_city_police_notice_sign"
    case ("PEWTER_CITY", "TEXT_PEWTERCITY_MART_SIGN"): return "pewter_city_mart_sign"
    case ("PEWTER_CITY", "TEXT_PEWTERCITY_POKECENTER_SIGN"): return "pewter_city_pokecenter_sign"
    case ("PEWTER_CITY", "TEXT_PEWTERCITY_MUSEUM_SIGN"): return "pewter_city_museum_sign"
    case ("PEWTER_CITY", "TEXT_PEWTERCITY_GYM_SIGN"): return "pewter_city_gym_sign"
    case ("PEWTER_CITY", "TEXT_PEWTERCITY_SIGN"): return "pewter_city_sign"
    case ("CERULEAN_CITY", "TEXT_CERULEANCITY_RIVAL"): return "cerulean_city_rival_pre_battle"
    case ("CERULEAN_CITY", "TEXT_CERULEANCITY_ROCKET"): return "cerulean_city_rocket_text"
    case ("CERULEAN_CITY", "TEXT_CERULEANCITY_GUARD1"),
         ("CERULEAN_CITY", "TEXT_CERULEANCITY_GUARD2"): return "cerulean_city_guard"
    case ("CERULEAN_CITY", "TEXT_CERULEANCITY_SIGN"): return "cerulean_city_sign"
    case ("CERULEAN_CITY", "TEXT_CERULEANCITY_TRAINER_TIPS"): return "cerulean_city_trainer_tips"
    case ("CERULEAN_CITY", "TEXT_CERULEANCITY_MART_SIGN"): return "cerulean_city_mart_sign"
    case ("CERULEAN_CITY", "TEXT_CERULEANCITY_POKECENTER_SIGN"): return "cerulean_city_pokecenter_sign"
    case ("CERULEAN_CITY", "TEXT_CERULEANCITY_BIKESHOP_SIGN"): return "cerulean_city_bike_shop_sign"
    case ("CERULEAN_CITY", "TEXT_CERULEANCITY_GYM_SIGN"): return "cerulean_city_gym_sign"
    case ("ROUTE_24", "TEXT_ROUTE24_COOLTRAINER_M1"): return "route24_cooltrainer_m1_you_could_become_a_top_leader"
    case ("ROUTE_25", "TEXT_ROUTE25_BILL_SIGN"): return "route25_bill_sign"
    case ("BILLS_HOUSE", "TEXT_BILLSHOUSE_BILL_POKEMON"): return "bills_house_bill_im_not_a_pokemon"
    case ("BILLS_HOUSE", "TEXT_BILLSHOUSE_BILL_SS_TICKET"): return "bills_house_bill_thank_you"
    case ("BILLS_HOUSE", "TEXT_BILLSHOUSE_BILL_CHECK_OUT_MY_RARE_POKEMON"): return "bills_house_bill_check_out_my_rare_pokemon"
    case ("PEWTER_GYM", "TEXT_PEWTERGYM_BROCK"): return "pewter_gym_brock_pre_battle"
    case ("PEWTER_GYM", "TEXT_PEWTERGYM_GYM_GUIDE"): return "pewter_gym_guide_pre_advice"
    case ("CERULEAN_GYM", "TEXT_CERULEANGYM_MISTY"): return "cerulean_gym_misty_pre_battle"
    case ("CERULEAN_GYM", "TEXT_CERULEANGYM_GYM_GUIDE"): return "cerulean_gym_gym_guide_champ_in_making"
    case ("VIRIDIAN_POKECENTER", "TEXT_VIRIDIANPOKECENTER_GENTLEMAN"): return "viridian_pokecenter_gentleman"
    case ("VIRIDIAN_POKECENTER", "TEXT_VIRIDIANPOKECENTER_COOLTRAINER_M"): return "viridian_pokecenter_cooltrainer"
    case ("VIRIDIAN_POKECENTER", "TEXT_VIRIDIANPOKECENTER_LINK_RECEPTIONIST"): return "viridian_pokecenter_link_receptionist"
    case ("OAKS_LAB", "TEXT_OAKSLAB_RIVAL"): return "oaks_lab_rival_gramps_isnt_around"
    case ("OAKS_LAB", "TEXT_OAKSLAB_RIVAL_GRAMPS"): return "oaks_lab_rival_gramps"
    case ("OAKS_LAB", "TEXT_OAKSLAB_CHARMANDER_POKE_BALL"),
         ("OAKS_LAB", "TEXT_OAKSLAB_SQUIRTLE_POKE_BALL"),
         ("OAKS_LAB", "TEXT_OAKSLAB_BULBASAUR_POKE_BALL"):
        return "oaks_lab_those_are_pokeballs"
    case ("OAKS_LAB", "TEXT_OAKSLAB_OAK1"): return "oaks_lab_oak_which_pokemon_do_you_want"
    case ("OAKS_LAB", "TEXT_OAKSLAB_POKEDEX1"), ("OAKS_LAB", "TEXT_OAKSLAB_POKEDEX2"):
        return "oaks_lab_pokedex"
    case ("OAKS_LAB", "TEXT_OAKSLAB_OAK2"): return "oaks_lab_oak_choose_mon"
    case ("OAKS_LAB", "TEXT_OAKSLAB_GIRL"): return "oaks_lab_girl"
    case ("OAKS_LAB", "TEXT_OAKSLAB_SCIENTIST1"), ("OAKS_LAB", "TEXT_OAKSLAB_SCIENTIST2"):
        return "oaks_lab_girl"
    default:
        if let localLabel = mapScriptMetadata?.textLabelByTextID[textID] {
            switch localLabel {
            case "MartSignText":
                return "\(mapID.lowercased())_mart_sign"
            case "PokeCenterSignText":
                return "\(mapID.lowercased())_pokecenter_sign"
            default:
                break
            }
            return dialogueID(forScriptLabel: localLabel, mapScriptMetadata: mapScriptMetadata)
        }
        return "\(mapID.lowercased())_\(textID.lowercased())"
    }
}

private func humanizedIdentifier(_ identifier: String) -> String {
    identifier
        .lowercased()
        .split(separator: "_")
        .map { $0.capitalized }
        .joined(separator: " ")
}

private func displayName(forSprite sprite: String) -> String? {
    switch sprite {
    case "SPRITE_CLERK": return "Clerk"
    case "SPRITE_NURSE": return "Nurse"
    case "SPRITE_GENTLEMAN": return "Gentleman"
    case "SPRITE_LINK_RECEPTIONIST": return "Receptionist"
    case "SPRITE_YOUNGSTER": return "Youngster"
    case "SPRITE_SUPER_NERD": return "Super Nerd"
    case "SPRITE_COOLTRAINER_F": return "Cooltrainer"
    case "SPRITE_COOLTRAINER_M": return "Cooltrainer"
    case "SPRITE_BIKE_SHOP_CLERK": return "Clerk"
    case "SPRITE_GAMBLER": return "Gambler"
    case "SPRITE_GIRL": return "Girl"
    case "SPRITE_GUARD": return "Guard"
    case "SPRITE_GRANNY": return "Granny"
    case "SPRITE_FISHING_GURU": return "Fishing Guru"
    case "SPRITE_LITTLE_BOY": return "Little Boy"
    case "SPRITE_LITTLE_GIRL": return "Little Girl"
    case "SPRITE_MIDDLE_AGED_MAN": return "Middle Aged Man"
    case "SPRITE_MIDDLE_AGED_WOMAN": return "Middle Aged Woman"
    case "SPRITE_MONSTER": return "Monster"
    case "SPRITE_FAIRY": return "Jigglypuff"
    case "SPRITE_SCIENTIST": return "Scientist"
    case "SPRITE_OLD_AMBER": return "Old Amber"
    case "SPRITE_HIKER": return "Hiker"
    case "SPRITE_GRAMPS": return "Gramps"
    case "SPRITE_GYM_GUIDE": return "Gym Guide"
    default:
        return nil
    }
}
