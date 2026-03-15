import Foundation
import PokeDataModel

func buildDialogues(
    repoRoot: URL,
    mapScriptMetadataByMapID: [String: MapScriptMetadata],
    itemNamesByID: [String: String]
) throws -> [DialogueManifest] {
    let scriptDialogueEvents = try buildScriptDialogueEvents(repoRoot: repoRoot)
    let textContentsByMapID = try buildTextContentsByMapID(repoRoot: repoRoot)
    let route22Text = textContentsByMapID["ROUTE_22"]
    let route22GateText = textContentsByMapID["ROUTE_22_GATE"]
    let pewterGymText = textContentsByMapID["PEWTER_GYM"]
    let pallet = try String(contentsOf: repoRoot.appendingPathComponent("text/PalletTown.asm"))
    let oaksLab = try String(contentsOf: repoRoot.appendingPathComponent("text/OaksLab.asm"))
    let redsHouse = try String(contentsOf: repoRoot.appendingPathComponent("text/RedsHouse1F.asm"))
    let route1 = try String(contentsOf: repoRoot.appendingPathComponent("text/Route1.asm"))
    let route2 = try String(contentsOf: repoRoot.appendingPathComponent("text/Route2.asm"))
    let viridianCity = try String(contentsOf: repoRoot.appendingPathComponent("text/ViridianCity.asm"))
    let viridianSchoolHouse = try String(contentsOf: repoRoot.appendingPathComponent("text/ViridianSchoolHouse.asm"))
    let viridianNicknameHouse = try String(contentsOf: repoRoot.appendingPathComponent("text/ViridianNicknameHouse.asm"))
    let viridianMart = try String(contentsOf: repoRoot.appendingPathComponent("text/ViridianMart.asm"))
    let viridianForestSouthGate = try String(contentsOf: repoRoot.appendingPathComponent("text/ViridianForestSouthGate.asm"))
    let viridianForest = try String(contentsOf: repoRoot.appendingPathComponent("text/ViridianForest.asm"))
    let viridianForestNorthGate = try String(contentsOf: repoRoot.appendingPathComponent("text/ViridianForestNorthGate.asm"))
    let viridianPokecenter = try String(contentsOf: repoRoot.appendingPathComponent("text/ViridianPokecenter.asm"))
    let mtMoonB2F = try String(contentsOf: repoRoot.appendingPathComponent("text/MtMoonB2F.asm"))
    let text1 = try String(contentsOf: repoRoot.appendingPathComponent("data/text/text_1.asm"))
    let text2 = try String(contentsOf: repoRoot.appendingPathComponent("data/text/text_2.asm"))
    let text3 = try String(contentsOf: repoRoot.appendingPathComponent("data/text/text_3.asm"))
    let text4 = try String(contentsOf: repoRoot.appendingPathComponent("data/text/text_4.asm"))
    let text6 = try String(contentsOf: repoRoot.appendingPathComponent("data/text/text_6.asm"))

    var dialogues: [DialogueManifest] = [
        try extractDialogue(id: "pallet_town_oak_hey_wait", label: "_PalletTownOakHeyWaitDontGoOutText", from: pallet, extraEvents: scriptDialogueEvents["_PalletTownOakHeyWaitDontGoOutText"] ?? []),
        try extractDialogue(id: "pallet_town_oak_its_unsafe", label: "_PalletTownOakItsUnsafeText", from: pallet, extraEvents: scriptDialogueEvents["_PalletTownOakItsUnsafeText"] ?? []),
        try extractDialogue(id: "pallet_town_girl", label: "_PalletTownGirlText", from: pallet, extraEvents: scriptDialogueEvents["_PalletTownGirlText"] ?? []),
        try extractDialogue(id: "pallet_town_fisher", label: "_PalletTownFisherText", from: pallet, extraEvents: scriptDialogueEvents["_PalletTownFisherText"] ?? []),
        try extractDialogue(id: "pallet_town_oaks_lab_sign", label: "_PalletTownOaksLabSignText", from: pallet, extraEvents: scriptDialogueEvents["_PalletTownOaksLabSignText"] ?? []),
        try extractDialogue(id: "pallet_town_sign", label: "_PalletTownSignText", from: pallet, extraEvents: scriptDialogueEvents["_PalletTownSignText"] ?? []),
        try extractDialogue(id: "pallet_town_players_house_sign", label: "_PalletTownPlayersHouseSignText", from: pallet, extraEvents: scriptDialogueEvents["_PalletTownPlayersHouseSignText"] ?? []),
        try extractDialogue(id: "pallet_town_rivals_house_sign", label: "_PalletTownRivalsHouseSignText", from: pallet, extraEvents: scriptDialogueEvents["_PalletTownRivalsHouseSignText"] ?? []),
        try extractDialogue(id: "reds_house_1f_mom_wakeup", label: "_RedsHouse1FMomWakeUpText", from: redsHouse, extraEvents: scriptDialogueEvents["_RedsHouse1FMomWakeUpText"] ?? []),
        try extractDialogue(id: "reds_house_1f_mom_rest", label: "_RedsHouse1FMomYouShouldRestText", from: redsHouse, extraEvents: scriptDialogueEvents["_RedsHouse1FMomYouShouldRestText"] ?? []),
        try extractDialogue(id: "reds_house_1f_mom_looking_great", label: "_RedsHouse1FMomLookingGreatText", from: redsHouse, extraEvents: scriptDialogueEvents["_RedsHouse1FMomLookingGreatText"] ?? []),
        try extractDialogue(id: "reds_house_1f_tv", label: "_RedsHouse1FTVStandByMeMovieText", from: redsHouse, extraEvents: scriptDialogueEvents["_RedsHouse1FTVStandByMeMovieText"] ?? []),
        try extractDialogue(id: "route_1_youngster_1_mart_sample", label: "_Route1Youngster1MartSampleText", from: route1, extraEvents: scriptDialogueEvents["_Route1Youngster1MartSampleText"] ?? []),
        try extractDialogue(id: "route_1_youngster_1_got_potion", label: "_Route1Youngster1GotPotionText", from: route1, extraEvents: scriptDialogueEvents["_Route1Youngster1GotPotionText"] ?? []),
        try extractDialogue(id: "route_1_youngster_1_after_sample", label: "_Route1Youngster1AlsoGotPokeballsText", from: route1, extraEvents: scriptDialogueEvents["_Route1Youngster1AlsoGotPokeballsText"] ?? []),
        try extractDialogue(id: "route_1_youngster_1_no_room", label: "_Route1Youngster1NoRoomText", from: route1, extraEvents: scriptDialogueEvents["_Route1Youngster1NoRoomText"] ?? []),
        try extractDialogue(id: "route_1_youngster_2", label: "_Route1Youngster2Text", from: route1, extraEvents: scriptDialogueEvents["_Route1Youngster2Text"] ?? []),
        try extractDialogue(id: "route_1_sign", label: "_Route1SignText", from: route1, extraEvents: scriptDialogueEvents["_Route1SignText"] ?? []),
        try extractDialogue(id: "route_2_sign", label: "_Route2SignText", from: route2),
        try extractDialogue(id: "route_2_digletts_cave_sign", label: "_Route2DiglettsCaveSignText", from: route2),
        try extractDialogue(id: "viridian_city_youngster_1", label: "_ViridianCityYoungster1Text", from: viridianCity, extraEvents: scriptDialogueEvents["_ViridianCityYoungster1Text"] ?? []),
        try extractDialogue(id: "viridian_city_gambler", label: "_ViridianCityGambler1GymAlwaysClosedText", from: viridianCity, extraEvents: scriptDialogueEvents["_ViridianCityGambler1GymAlwaysClosedText"] ?? []),
        try extractDialogue(id: "viridian_city_youngster_2_prompt", label: "_ViridianCityYoungster2YouWantToKnowAboutText", from: viridianCity, extraEvents: scriptDialogueEvents["_ViridianCityYoungster2YouWantToKnowAboutText"] ?? []),
        try extractDialogue(id: "viridian_city_youngster_2_ok_then", label: "ViridianCityYoungster2OkThenText", from: viridianCity, extraEvents: scriptDialogueEvents["ViridianCityYoungster2OkThenText"] ?? []),
        try extractDialogue(id: "viridian_city_youngster_2_description", label: "ViridianCityYoungster2CaterpieAndWeedleDescriptionText", from: viridianCity, extraEvents: scriptDialogueEvents["ViridianCityYoungster2CaterpieAndWeedleDescriptionText"] ?? []),
        try extractDialogue(id: "viridian_city_girl_before_pokedex", label: "_ViridianCityGirlHasntHadHisCoffeeYetText", from: viridianCity, extraEvents: scriptDialogueEvents["_ViridianCityGirlHasntHadHisCoffeeYetText"] ?? []),
        try extractDialogue(id: "viridian_city_girl_after_pokedex", label: "_ViridianCityGirlWhenIGoShopText", from: viridianCity, extraEvents: scriptDialogueEvents["_ViridianCityGirlWhenIGoShopText"] ?? []),
        try extractDialogue(id: "viridian_city_old_man_private_property", label: "_ViridianCityOldManSleepyPrivatePropertyText", from: viridianCity, extraEvents: scriptDialogueEvents["_ViridianCityOldManSleepyPrivatePropertyText"] ?? []),
        try extractDialogue(id: "viridian_city_fisher", label: "ViridianCityFisherYouCanHaveThisText", from: viridianCity, extraEvents: scriptDialogueEvents["ViridianCityFisherYouCanHaveThisText"] ?? []),
        try extractDialogue(id: "viridian_city_old_man_had_coffee", label: "_ViridianCityOldManHadMyCoffeeNowText", from: viridianCity, extraEvents: scriptDialogueEvents["_ViridianCityOldManHadMyCoffeeNowText"] ?? []),
        try extractDialogue(id: "viridian_city_old_man_weaken_target", label: "_ViridianCityOldManYouNeedToWeakenTheTargetText", from: viridianCity, extraEvents: scriptDialogueEvents["_ViridianCityOldManYouNeedToWeakenTheTargetText"] ?? []),
        try extractDialogue(id: "viridian_city_sign", label: "_ViridianCitySignText", from: viridianCity, extraEvents: scriptDialogueEvents["_ViridianCitySignText"] ?? []),
        try extractDialogue(id: "viridian_city_trainer_tips_1", label: "_ViridianCityTrainerTips1Text", from: viridianCity, extraEvents: scriptDialogueEvents["_ViridianCityTrainerTips1Text"] ?? []),
        try extractDialogue(id: "viridian_city_trainer_tips_2", label: "_ViridianCityTrainerTips2Text", from: viridianCity, extraEvents: scriptDialogueEvents["_ViridianCityTrainerTips2Text"] ?? []),
        try extractDialogue(id: "viridian_city_gym_sign", label: "_ViridianCityGymSignText", from: viridianCity, extraEvents: scriptDialogueEvents["_ViridianCityGymSignText"] ?? []),
        try extractDialogue(id: "viridian_city_gym_locked", label: "_ViridianCityGymLockedText", from: viridianCity, extraEvents: scriptDialogueEvents["_ViridianCityGymLockedText"] ?? []),
        DialogueManifest(id: "viridian_city_mart_sign", pages: [.init(lines: ["#MON MART"], waitsForPrompt: true)]),
        DialogueManifest(id: "viridian_city_pokecenter_sign", pages: [.init(lines: ["#MON CENTER"], waitsForPrompt: true)]),
        try extractDialogue(id: "viridian_school_house_brunette_girl", label: "_ViridianSchoolHouseBrunetteGirlText", from: viridianSchoolHouse),
        try extractDialogue(id: "viridian_school_house_cooltrainer_f", label: "_ViridianSchoolHouseCooltrainerFText", from: viridianSchoolHouse),
        try extractDialogue(id: "viridian_nickname_house_balding_guy", label: "_ViridianNicknameHouseBaldingGuyText", from: viridianNicknameHouse),
        try extractDialogue(id: "viridian_nickname_house_little_girl", label: "_ViridianNicknameHouseLittleGirlText", from: viridianNicknameHouse),
        try extractDialogue(id: "viridian_nickname_house_spearow", label: "_ViridianNicknameHouseSpearowText", from: viridianNicknameHouse),
        try extractDialogue(id: "viridian_nickname_house_speary_sign", label: "_ViridianNicknameHouseSpearySignText", from: viridianNicknameHouse),
        try extractDialogue(id: "viridian_mart_clerk_you_came_from_pallet_town", label: "_ViridianMartClerkYouCameFromPalletTownText", from: viridianMart, extraEvents: scriptDialogueEvents["_ViridianMartClerkYouCameFromPalletTownText"] ?? []),
        try extractDialogue(id: "viridian_mart_clerk_parcel_quest", label: "_ViridianMartClerkParcelQuestText", from: viridianMart, extraEvents: scriptDialogueEvents["_ViridianMartClerkParcelQuestText"] ?? []),
        try extractDialogue(id: "viridian_mart_clerk_after_parcel", label: "_ViridianMartClerkSayHiToOakText", from: viridianMart, extraEvents: scriptDialogueEvents["_ViridianMartClerkSayHiToOakText"] ?? []),
        try extractDialogue(id: "viridian_mart_youngster", label: "_ViridianMartYoungsterText", from: viridianMart, extraEvents: scriptDialogueEvents["_ViridianMartYoungsterText"] ?? []),
        try extractDialogue(id: "viridian_mart_cooltrainer", label: "_ViridianMartCooltrainerMText", from: viridianMart, extraEvents: scriptDialogueEvents["_ViridianMartCooltrainerMText"] ?? []),
        try extractDialogue(id: "viridian_forest_south_gate_girl", label: "_ViridianForestSouthGateGirlText", from: viridianForestSouthGate),
        try extractDialogue(id: "viridian_forest_south_gate_little_girl", label: "_ViridianForestSouthGateLittleGirlText", from: viridianForestSouthGate),
        try extractDialogue(id: "viridian_forest_youngster_1", label: "_ViridianForestYoungster1Text", from: viridianForest),
        try extractDialogue(id: "viridian_forest_youngster_5", label: "_ViridianForestYoungster5Text", from: viridianForest),
        try extractDialogue(id: "viridian_forest_trainer_tips_1", label: "_ViridianForestTrainerTips1Text", from: viridianForest),
        try extractDialogue(id: "viridian_forest_use_antidote_sign", label: "_ViridianForestUseAntidoteSignText", from: viridianForest),
        try extractDialogue(id: "viridian_forest_trainer_tips_2", label: "_ViridianForestTrainerTips2Text", from: viridianForest),
        try extractDialogue(id: "viridian_forest_trainer_tips_3", label: "_ViridianForestTrainerTips3Text", from: viridianForest),
        try extractDialogue(id: "viridian_forest_trainer_tips_4", label: "_ViridianForestTrainerTips4Text", from: viridianForest),
        try extractDialogue(id: "viridian_forest_leaving_sign", label: "_ViridianForestLeavingSignText", from: viridianForest),
        try extractDialogue(id: "viridian_forest_north_gate_super_nerd", label: "_ViridianForestNorthGateSuperNerdText", from: viridianForestNorthGate),
        try extractDialogue(id: "viridian_forest_north_gate_gramps", label: "_ViridianForestNorthGateGrampsText", from: viridianForestNorthGate),
        try extractDialogue(id: "mt_moon_b2f_dome_fossil_you_want", label: "_MtMoonB2FDomeFossilYouWantText", from: mtMoonB2F),
        try extractDialogue(id: "mt_moon_b2f_helix_fossil_you_want", label: "_MtMoonB2FHelixFossilYouWantText", from: mtMoonB2F),
        try extractDialogue(
            id: "mt_moon_b2f_received_fossil",
            label: "_MtMoonB2FReceivedFossilText",
            from: mtMoonB2F,
            placeholderMap: ["wStringBuffer": "wStringBuffer"],
            extraEvents: [.init(kind: .soundEffect, soundEffectID: "SFX_GET_KEY_ITEM")]
        ),
        try extractDialogue(id: "mt_moon_b2f_you_have_no_room", label: "_MtMoonB2FYouHaveNoRoomText", from: mtMoonB2F),
        try extractDialogue(id: "mt_moon_b2f_super_nerd_theyre_both_mine", label: "_MtMoonB2FSuperNerdTheyreBothMineText", from: mtMoonB2F),
        try extractDialogue(id: "mt_moon_b2f_super_nerd_ok_ill_share", label: "_MtMoonB2FSuperNerdOkIllShareText", from: mtMoonB2F),
        try extractDialogue(id: "mt_moon_b2f_super_nerd_each_take_one", label: "_MtMoonB2fSuperNerdEachTakeOneText", from: mtMoonB2F),
        try extractDialogue(id: "mt_moon_b2f_super_nerd_theres_a_pokemon_lab", label: "_MtMoonB2FSuperNerdTheresAPokemonLabText", from: mtMoonB2F),
        try extractDialogue(
            id: "mt_moon_b2f_super_nerd_then_this_is_mine",
            label: "_MtMoonB2FSuperNerdThenThisIsMineText",
            from: mtMoonB2F,
            extraEvents: [.init(kind: .soundEffect, soundEffectID: "SFX_GET_KEY_ITEM")]
        ),
        try extractDialogue(id: "pickup_no_room", label: "_NoMoreRoomForItemText", from: text1),
        try extractDialogue(
            id: "evolution_evolved",
            label: "_EvolvedText",
            from: text3,
            placeholderMap: ["wStringBuffer": "pokemon"]
        ),
        try extractDialogue(
            id: "evolution_into",
            label: "_IntoText",
            from: text3,
            placeholderMap: ["wNameBuffer": "evolvedPokemon"],
            extraEvents: [.init(kind: .soundEffect, soundEffectID: "SFX_GET_ITEM_2")]
        ),
        try extractDialogue(
            id: "evolution_stopped",
            label: "_StoppedEvolvingText",
            from: text3,
            placeholderMap: ["wStringBuffer": "pokemon"]
        ),
        try extractDialogue(
            id: "evolution_is_evolving",
            label: "_IsEvolvingText",
            from: text3,
            placeholderMap: ["wStringBuffer": "pokemon"]
        ),
        try extractDialogue(id: "pokemart_greeting", label: "_PokemartGreetingText", from: text4),
        try extractDialogue(id: "pokemart_buying_greeting", label: "_PokemartBuyingGreetingText", from: text4),
        try extractDialogue(id: "pokemart_bought_item", label: "_PokemartBoughtItemText", from: text4),
        try extractDialogue(id: "pokemart_not_enough_money", label: "_PokemartNotEnoughMoneyText", from: text4),
        try extractDialogue(id: "pokemart_item_bag_full", label: "_PokemartItemBagFullText", from: text4),
        try extractDialogue(id: "pokemart_selling_greeting", label: "_PokemonSellingGreetingText", from: text4),
        try extractDialogue(id: "pokemart_item_bag_empty", label: "_PokemartItemBagEmptyText", from: text4),
        try extractDialogue(id: "pokemart_unsellable_item", label: "_PokemartUnsellableItemText", from: text4),
        try extractDialogue(id: "pokemart_thank_you", label: "_PokemartThankYouText", from: text4),
        try extractDialogue(id: "pokemart_anything_else", label: "_PokemartAnythingElseText", from: text4),
        try extractDialogue(id: "pokemon_center_welcome", label: "_PokemonCenterWelcomeText", from: text4),
        try extractDialogue(id: "pokemon_center_shall_we_heal", label: "_ShallWeHealYourPokemonText", from: text4),
        try extractDialogue(id: "pokemon_center_need_your_pokemon", label: "_NeedYourPokemonText", from: text4),
        try extractDialogue(id: "pokemon_center_fighting_fit", label: "_PokemonFightingFitText", from: text4),
        try extractDialogue(id: "pokemon_center_farewell", label: "_PokemonCenterFarewellText", from: text4),
        try extractDialogue(id: "capture_uncatchable", label: "_ItemUseBallText00", from: text6),
        try extractDialogue(id: "capture_missed", label: "_ItemUseBallText01", from: text6),
        try extractDialogue(id: "capture_broke_free", label: "_ItemUseBallText02", from: text6),
        try extractDialogue(id: "capture_almost", label: "_ItemUseBallText03", from: text6),
        try extractDialogue(id: "capture_so_close", label: "_ItemUseBallText04", from: text6),
        try extractDialogue(
            id: "capture_caught",
            label: "_ItemUseBallText05",
            from: text6,
            placeholderMap: ["wEnemyMonNick": "capturedPokemon"],
            extraEvents: [.init(kind: .soundEffect, soundEffectID: "SFX_CAUGHT_MON")]
        ),
        try extractDialogue(
            id: "capture_dex_added",
            label: "_ItemUseBallText06",
            from: text6,
            placeholderMap: ["wEnemyMonNick": "capturedPokemon"],
            extraEvents: [.init(kind: .soundEffect, soundEffectID: "SFX_DEX_PAGE_ADDED")]
        ),
        try extractDialogue(
            id: "capture_transferred_bill_pc",
            label: "_ItemUseBallText07",
            from: text6,
            placeholderMap: ["wBoxMonNicks": "capturedPokemon"]
        ),
        try extractDialogue(
            id: "capture_transferred_someone_pc",
            label: "_ItemUseBallText08",
            from: text6,
            placeholderMap: ["wBoxMonNicks": "capturedPokemon"]
        ),
        try extractDialogue(id: "viridian_pokecenter_gentleman", label: "_ViridianPokecenterGentlemanText", from: viridianPokecenter, extraEvents: scriptDialogueEvents["_ViridianPokecenterGentlemanText"] ?? []),
        try extractDialogue(id: "viridian_pokecenter_cooltrainer", label: "_ViridianPokecenterCooltrainerMText", from: viridianPokecenter, extraEvents: scriptDialogueEvents["_ViridianPokecenterCooltrainerMText"] ?? []),
        try extractDialogue(id: "oaks_lab_rival_gramps_isnt_around", label: "_OaksLabRivalGrampsIsntAroundText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabRivalGrampsIsntAroundText"] ?? []),
        try extractDialogue(id: "oaks_lab_rival_go_ahead_and_choose", label: "_OaksLabRivalGoAheadAndChooseText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabRivalGoAheadAndChooseText"] ?? []),
        try extractDialogue(id: "oaks_lab_rival_my_pokemon_looks_stronger", label: "_OaksLabRivalMyPokemonLooksStrongerText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabRivalMyPokemonLooksStrongerText"] ?? []),
        try extractDialogue(id: "oaks_lab_those_are_pokeballs", label: "_OaksLabThoseArePokeBallsText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabThoseArePokeBallsText"] ?? []),
        try extractDialogue(id: "oaks_lab_you_want_charmander", label: "_OaksLabYouWantCharmanderText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabYouWantCharmanderText"] ?? []),
        try extractDialogue(id: "oaks_lab_you_want_squirtle", label: "_OaksLabYouWantSquirtleText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabYouWantSquirtleText"] ?? []),
        try extractDialogue(id: "oaks_lab_you_want_bulbasaur", label: "_OaksLabYouWantBulbasaurText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabYouWantBulbasaurText"] ?? []),
        try extractDialogue(id: "oaks_lab_mon_energetic", label: "_OaksLabMonEnergeticText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabMonEnergeticText"] ?? []),
        try extractDialogue(id: "oaks_lab_last_mon", label: "_OaksLabLastMonText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabLastMonText"] ?? []),
        try extractDialogue(id: "oaks_lab_oak_which_pokemon_do_you_want", label: "_OaksLabOak1WhichPokemonDoYouWantText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabOak1WhichPokemonDoYouWantText"] ?? []),
        try extractDialogue(id: "oaks_lab_oak_raise_your_young_pokemon", label: "_OaksLabOak1RaiseYourYoungPokemonText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabOak1RaiseYourYoungPokemonText"] ?? []),
        try extractDialogue(id: "oaks_lab_oak_deliver_parcel", label: "_OaksLabOak1DeliverParcelText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabOak1DeliverParcelText"] ?? []),
        try extractDialogue(id: "oaks_lab_oak_parcel_thanks", label: "_OaksLabOak1ParcelThanksText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabOak1ParcelThanksText"] ?? []),
        try extractDialogue(id: "oaks_lab_oak_pokemon_around_the_world", label: "_OaksLabOak1PokemonAroundTheWorldText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabOak1PokemonAroundTheWorldText"] ?? []),
        try extractDialogue(id: "oaks_lab_oak_come_see_me_sometimes", label: "_OaksLabOak1ComeSeeMeSometimesText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabOak1ComeSeeMeSometimesText"] ?? []),
        try extractDialogue(id: "oaks_lab_oak_how_is_your_pokedex_coming", label: "_OaksLabOak1HowIsYourPokedexComingText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabOak1HowIsYourPokedexComingText"] ?? []),
        try extractDialogue(id: "oaks_lab_pokedex", label: "_OaksLabPokedexText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabPokedexText"] ?? []),
        try extractDialogue(id: "oaks_lab_girl", label: "_OaksLabGirlText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabGirlText"] ?? []),
        try extractDialogue(id: "oaks_lab_rival_fed_up_with_waiting", label: "_OaksLabRivalFedUpWithWaitingText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabRivalFedUpWithWaitingText"] ?? []),
        try extractDialogue(id: "oaks_lab_oak_choose_mon", label: "_OaksLabOakChooseMonText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabOakChooseMonText"] ?? []),
        try extractDialogue(id: "oaks_lab_rival_what_about_me", label: "_OaksLabRivalWhatAboutMeText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabRivalWhatAboutMeText"] ?? []),
        try extractDialogue(id: "oaks_lab_oak_be_patient", label: "_OaksLabOakBePatientText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabOakBePatientText"] ?? []),
        try extractDialogue(id: "oaks_lab_oak_dont_go_away_yet", label: "_OaksLabOakDontGoAwayYetText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabOakDontGoAwayYetText"] ?? []),
        try extractDialogue(id: "oaks_lab_rival_ill_take_this_one", label: "_OaksLabRivalIllTakeThisOneText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabRivalIllTakeThisOneText"] ?? []),
        makeReceivedDialogue(id: "oaks_lab_received_mon_charmander", speciesName: "CHARMANDER", events: scriptDialogueEvents["_OaksLabReceivedMonText"] ?? []),
        makeReceivedDialogue(id: "oaks_lab_received_mon_squirtle", speciesName: "SQUIRTLE", events: scriptDialogueEvents["_OaksLabReceivedMonText"] ?? []),
        makeReceivedDialogue(id: "oaks_lab_received_mon_bulbasaur", speciesName: "BULBASAUR", events: scriptDialogueEvents["_OaksLabReceivedMonText"] ?? []),
        makeRivalReceivedDialogue(id: "oaks_lab_rival_received_mon_charmander", speciesName: "CHARMANDER", events: scriptDialogueEvents["_OaksLabRivalReceivedMonText"] ?? []),
        makeRivalReceivedDialogue(id: "oaks_lab_rival_received_mon_squirtle", speciesName: "SQUIRTLE", events: scriptDialogueEvents["_OaksLabRivalReceivedMonText"] ?? []),
        makeRivalReceivedDialogue(id: "oaks_lab_rival_received_mon_bulbasaur", speciesName: "BULBASAUR", events: scriptDialogueEvents["_OaksLabRivalReceivedMonText"] ?? []),
        try extractDialogue(id: "oaks_lab_rival_ill_take_you_on", label: "_OaksLabRivalIllTakeYouOnText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabRivalIllTakeYouOnText"] ?? []),
        try extractDialogue(id: "oaks_lab_rival_i_picked_the_wrong_pokemon", label: "_OaksLabRivalIPickedTheWrongPokemonText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabRivalIPickedTheWrongPokemonText"] ?? []),
        try extractDialogue(id: "oaks_lab_rival_am_i_great_or_what", label: "_OaksLabRivalAmIGreatOrWhatText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabRivalAmIGreatOrWhatText"] ?? []),
        try extractDialogue(id: "oaks_lab_rival_smell_you_later", label: "_OaksLabRivalSmellYouLaterText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabRivalSmellYouLaterText"] ?? []),
        try extractDialogue(id: "oaks_lab_rival_gramps", label: "_OaksLabRivalGrampsText", from: oaksLab),
        try extractDialogue(id: "oaks_lab_rival_what_did_you_call_me_for", label: "_OaksLabRivalWhatDidYouCallMeForText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabRivalWhatDidYouCallMeForText"] ?? []),
        try extractDialogue(id: "oaks_lab_oak_i_have_a_request", label: "_OaksLabOakIHaveARequestText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabOakIHaveARequestText"] ?? []),
        try extractDialogue(id: "oaks_lab_oak_my_invention_pokedex", label: "_OaksLabOakMyInventionPokedexText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabOakMyInventionPokedexText"] ?? []),
        try extractDialogue(id: "oaks_lab_oak_got_pokedex", label: "_OaksLabOakGotPokedexText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabOakGotPokedexText"] ?? []),
        try extractDialogue(id: "oaks_lab_oak_that_was_my_dream", label: "_OaksLabOakThatWasMyDreamText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabOakThatWasMyDreamText"] ?? []),
        try extractDialogue(id: "oaks_lab_rival_leave_it_all_to_me", label: "_OaksLabRivalLeaveItAllToMeText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabRivalLeaveItAllToMeText"] ?? []),
        try extractDialogue(id: "rival_1_win_text", label: "_Rival1WinText", from: text2, extraEvents: scriptDialogueEvents["_Rival1WinText"] ?? []),
    ]

    if let route22Text {
        if let beforeBattle1 = try extractDialogueIfPresent(
            id: "route_22_rival_before_battle_1",
            label: "_Route22RivalBeforeBattleText1",
            from: route22Text
        ) {
            dialogues.append(beforeBattle1)
        }
        if let afterBattle1 = try extractDialogueIfPresent(
            id: "route_22_rival_after_battle_1",
            label: "_Route22RivalAfterBattleText1",
            from: route22Text
        ) {
            dialogues.append(afterBattle1)
        }
        if let defeatedDialogue = try extractDialogueIfPresent(
            id: "route_22_rival_1_defeated",
            label: "_Route22Rival1DefeatedText",
            from: route22Text
        ) {
            dialogues.append(defeatedDialogue)
        }
        if let victoryDialogue = try extractDialogueIfPresent(
            id: "route_22_rival_1_victory",
            label: "_Route22Rival1VictoryText",
            from: route22Text
        ) {
            dialogues.append(victoryDialogue)
        }
        if let beforeBattle2 = try extractDialogueIfPresent(
            id: "route_22_rival_before_battle_2",
            label: "_Route22RivalBeforeBattleText2",
            from: route22Text
        ) {
            dialogues.append(beforeBattle2)
        }
        if let afterBattle2 = try extractDialogueIfPresent(
            id: "route_22_rival_after_battle_2",
            label: "_Route22RivalAfterBattleText2",
            from: route22Text
        ) {
            dialogues.append(afterBattle2)
        }
    }

    if let route22GateText {
        dialogues.append(
            try extractCombinedDialogue(
                id: "route_22_gate_guard_no_boulder_badge",
                segments: [
                    (label: "_Route22GateGuardNoBoulderbadgeText", contents: route22GateText),
                    (label: "_Route22GateGuardICantLetYouPassText", contents: route22GateText),
                ],
                trailingEventsBySegmentIndex: [0: [.init(kind: .soundEffect, soundEffectID: "SFX_DENIED")]]
            )
        )
        if let goRightAhead = try extractDialogueIfPresent(
            id: "route_22_gate_guard_go_right_ahead",
            label: "_Route22GateGuardGoRightAheadText",
            from: route22GateText
        ) {
            dialogues.append(goRightAhead)
        }
    }

    if let pewterGymText {
        dialogues.append(
            try extractCombinedDialogue(
                id: "pewter_gym_received_tm34",
                segments: [
                    (label: "_PewterGymReceivedTM34Text", contents: pewterGymText),
                    (label: "_TM34ExplanationText", contents: pewterGymText),
                ],
                trailingEventsBySegmentIndex: [0: [.init(kind: .soundEffect, soundEffectID: "SFX_GET_ITEM_1")]]
            )
        )
        dialogues.append(
            try extractDialogue(
                id: "pewter_gym_tm34_no_room",
                label: "_PewterGymTM34NoRoomText",
                from: pewterGymText
            )
        )
        dialogues.append(
            try extractCombinedDialogue(
                id: "pewter_gym_brock_received_boulder_badge",
                segments: [
                    (label: "_PewterGymBrockReceivedBoulderBadgeText", contents: pewterGymText),
                    (label: "_PewterGymBrockBoulderBadgeInfoText", contents: pewterGymText),
                ],
                trailingEventsBySegmentIndex: [0: [.init(kind: .soundEffect, soundEffectID: "SFX_GET_ITEM_1")]]
            )
        )
    }

    dialogues.append(contentsOf: try buildCoverageMapDialogues(
        textContentsByMapID: textContentsByMapID,
        mapScriptMetadataByMapID: mapScriptMetadataByMapID,
        scriptDialogueEvents: scriptDialogueEvents
    ))
    dialogues.append(contentsOf: try buildStandardTrainerDialogues(
        mapIDs: gameplayCoverageMaps.map(\.mapID),
        textContentsByMapID: textContentsByMapID,
        mapScriptMetadataByMapID: mapScriptMetadataByMapID
    ))
    dialogues.append(contentsOf: buildPickupFoundDialogues(
        itemIDs: referencedVisiblePickupItemIDs(repoRoot: repoRoot),
        itemNamesByID: itemNamesByID
    ))

    var dialogueByID: [String: DialogueManifest] = [:]
    for dialogue in dialogues where dialogueByID[dialogue.id] == nil {
        dialogueByID[dialogue.id] = dialogue
    }
    return dialogueByID.values.sorted { $0.id < $1.id }
}

// MARK: - Helpers (internal for parseItemNames in GameplayInventoryExtraction)

func extractQuotedString(from line: String) -> String {
    guard let firstQuote = line.firstIndex(of: "\""),
          let lastQuote = line.lastIndex(of: "\""),
          firstQuote < lastQuote
    else {
        return line
    }
    let raw = String(line[line.index(after: firstQuote)..<lastQuote])
    return raw
        .replacingOccurrences(of: "@", with: "")
        .replacingOccurrences(of: "#", with: "POKé")
        .trimmingCharacters(in: .whitespacesAndNewlines)
}

// MARK: - Private helpers

private func buildTextContentsByMapID(repoRoot: URL) throws -> [String: String] {
    let textDirectoryURL = repoRoot.appendingPathComponent("text", isDirectory: true)
    let textFiles = try FileManager.default.contentsOfDirectory(
        at: textDirectoryURL,
        includingPropertiesForKeys: nil
    )
    .filter { $0.pathExtension == "asm" }
    .sorted { $0.lastPathComponent < $1.lastPathComponent }

    return try gameplayCoverageMaps.reduce(into: [:]) { result, definition in
        let stem = mapFileStem(for: definition)
        let candidateURLs = textFiles
            .filter { url in
                url.deletingPathExtension().lastPathComponent == stem ||
                url.deletingPathExtension().lastPathComponent.hasPrefix("\(stem)_")
            }

        guard candidateURLs.isEmpty == false else {
            return
        }

        result[definition.mapID] = try candidateURLs
            .map { try String(contentsOf: $0) }
            .joined(separator: "\n")
    }
}

private func buildCoverageMapDialogues(
    textContentsByMapID: [String: String],
    mapScriptMetadataByMapID: [String: MapScriptMetadata],
    scriptDialogueEvents: [String: [DialogueEvent]]
) throws -> [DialogueManifest] {
    var dialogueByID: [String: DialogueManifest] = [:]

    for definition in gameplayCoverageMaps {
        guard
            let metadata = mapScriptMetadataByMapID[definition.mapID],
            let textContents = textContentsByMapID[definition.mapID]
        else {
            continue
        }

        for (textID, localLabel) in metadata.textLabelByTextID.sorted(by: { $0.key < $1.key }) {
            if let specialDialogue = specialCoverageDialogue(
                mapID: definition.mapID,
                textID: textID,
                localLabel: localLabel,
                mapScriptMetadata: metadata
            ) {
                dialogueByID[specialDialogue.id] = specialDialogue
                continue
            }

            let resolvedLabel = metadata.farTextLabelByLocalLabel[localLabel] ?? localLabel
            guard let dialogue = try extractDialogueIfPresent(
                id: dialogueID(for: definition.mapID, textID: textID, mapScriptMetadata: metadata),
                label: resolvedLabel,
                from: textContents,
                extraEvents: scriptDialogueEvents[resolvedLabel] ?? []
            ) else {
                continue
            }
            dialogueByID[dialogue.id] = dialogue
        }

        for farLabel in metadata.referencedFarTextLabels.sorted() {
            let dialogueID = normalizedDialogueID(from: farLabel)
            guard dialogueByID[dialogueID] == nil,
                  let dialogue = try extractDialogueIfPresent(
                      id: dialogueID,
                      label: farLabel,
                      from: textContents,
                      extraEvents: scriptDialogueEvents[farLabel] ?? []
                  ) else {
                continue
            }
            dialogueByID[dialogue.id] = dialogue
        }
    }

    return dialogueByID.values.sorted { $0.id < $1.id }
}

private func specialCoverageDialogue(
    mapID: String,
    textID: String,
    localLabel: String,
    mapScriptMetadata: MapScriptMetadata
) -> DialogueManifest? {
    let line: String
    switch localLabel {
    case "MartSignText":
        line = "#MON MART"
    case "PokeCenterSignText":
        line = "#MON CENTER"
    default:
        return nil
    }

    return DialogueManifest(
        id: dialogueID(for: mapID, textID: textID, mapScriptMetadata: mapScriptMetadata),
        pages: [.init(lines: [line], waitsForPrompt: true)]
    )
}

private func extractDialogueIfPresent(
    id: String,
    label: String,
    from contents: String,
    extraEvents: [DialogueEvent] = []
) throws -> DialogueManifest? {
    guard dialogueLabelExists(label, in: contents) else {
        return nil
    }
    return try extractDialogue(id: id, label: label, from: contents, extraEvents: extraEvents)
}

private func extractCombinedDialogue(
    id: String,
    segments: [(label: String, contents: String)],
    trailingEventsBySegmentIndex: [Int: [DialogueEvent]] = [:]
) throws -> DialogueManifest {
    var pages: [DialoguePage] = []

    for (index, segment) in segments.enumerated() {
        let extracted = try extractDialogue(
            id: "\(id)_segment_\(index)",
            label: segment.label,
            from: segment.contents
        )
        var extractedPages = extracted.pages
        if let trailingEvents = trailingEventsBySegmentIndex[index], extractedPages.isEmpty == false {
            let lastPageIndex = extractedPages.index(before: extractedPages.endIndex)
            let lastPage = extractedPages[lastPageIndex]
            extractedPages[lastPageIndex] = .init(
                lines: lastPage.lines,
                waitsForPrompt: lastPage.waitsForPrompt,
                events: lastPage.events + trailingEvents
            )
        }
        pages.append(contentsOf: extractedPages)
    }

    return DialogueManifest(id: id, pages: pages)
}

private func dialogueLabelExists(_ label: String, in contents: String) -> Bool {
    contents.range(of: "\(label)::") != nil || contents.range(of: "\(label):") != nil
}

private func buildScriptDialogueEvents(repoRoot: URL) throws -> [String: [DialogueEvent]] {
    let scriptPaths = gameplayCoverageMaps
        .map(scriptPathForMap)
        .filter { FileManager.default.fileExists(atPath: repoRoot.appendingPathComponent($0).path) }

    var eventsByTextLabel: [String: [DialogueEvent]] = [:]

    for path in scriptPaths {
        let contents = try String(contentsOf: repoRoot.appendingPathComponent(path))
        var currentTextLabel: String?

        for rawLine in contents.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)

            if line.hasSuffix(":") {
                currentTextLabel = nil
                continue
            }

            if let match = line.firstMatch(of: /text_far\s+([A-Za-z0-9_\.]+)/) {
                currentTextLabel = String(match.output.1)
                continue
            }

            if let event = dialogueEvent(for: line), let currentTextLabel {
                eventsByTextLabel[currentTextLabel, default: []].append(event)
                continue
            }

            if line == "text_end" || line == "text" {
                currentTextLabel = nil
            }
        }
    }

    return eventsByTextLabel
}

private func extractDialogue(
    id: String,
    label: String,
    from contents: String,
    placeholderMap: [String: String] = [:],
    extraEvents: [DialogueEvent] = []
) throws -> DialogueManifest {
    guard let range = contents.range(of: "\(label)::") ?? contents.range(of: "\(label):") else {
        throw ExtractorError.invalidArguments("missing dialogue label \(label)")
    }

    let tail = contents[range.upperBound...]
    var lines: [String] = []
    var currentLine = ""
    var events: [DialogueEvent] = []
    var pages: [DialoguePage] = []

    func appendSegment(_ segment: String) {
        guard segment.isEmpty == false else { return }
        if currentLine.isEmpty == false,
           let lastCharacter = currentLine.last,
           let firstCharacter = segment.first,
           (lastCharacter.isLetter || lastCharacter.isNumber || lastCharacter == "}" || lastCharacter == "!" || lastCharacter == "?") &&
            (firstCharacter.isLetter || firstCharacter.isNumber || firstCharacter == "{") {
            currentLine += " "
        }
        currentLine += segment
    }

    func flushLineIfNeeded(force: Bool = false) {
        guard force || currentLine.isEmpty == false else { return }
        lines.append(currentLine)
        currentLine = ""
        if lines.count == 4 {
            pages.append(.init(lines: lines, waitsForPrompt: true, events: events))
            lines = []
            events = []
        }
    }

    func flushPageIfNeeded() {
        flushLineIfNeeded()
        guard lines.isEmpty == false else { return }
        pages.append(.init(lines: lines, waitsForPrompt: true, events: events))
        lines = []
        events = []
    }

    for rawLine in tail.split(separator: "\n", omittingEmptySubsequences: false) {
        let line = rawLine.trimmingCharacters(in: .whitespaces)
        if let labelMatch = line.firstMatch(of: /^([A-Za-z0-9_\.]+)::?$/),
           String(labelMatch.output.1) != label {
            break
        }
        if line.hasPrefix("text \"") || line.hasPrefix("line \"") || line.hasPrefix("cont \"") || line.hasPrefix("para \"") {
            let value = extractQuotedString(from: line)
            if line.hasPrefix("para ") {
                flushPageIfNeeded()
            } else if line.hasPrefix("line ") || line.hasPrefix("cont ") {
                flushLineIfNeeded()
            }
            appendSegment(value)
        } else if line.hasPrefix("text_ram ") {
            let token = line
                .replacingOccurrences(of: "text_ram ", with: "")
                .trimmingCharacters(in: .whitespaces)
            let placeholder = placeholderMap[token] ?? "NAME"
            appendSegment("{\(placeholder)}")
        } else if let event = dialogueEvent(for: line) {
            events.append(event)
        } else if line == "done" || line == "prompt" || line == "text_end" {
            flushPageIfNeeded()
            if line == "text_end" || line == "done" || line == "prompt" {
                break
            }
        }
    }

    flushPageIfNeeded()

    if extraEvents.isEmpty == false, pages.isEmpty == false {
        let lastIndex = pages.index(before: pages.endIndex)
        let lastPage = pages[lastIndex]
        pages[lastIndex] = .init(
            lines: lastPage.lines,
            waitsForPrompt: lastPage.waitsForPrompt,
            events: lastPage.events + extraEvents
        )
    }
    return DialogueManifest(id: id, pages: pages)
}

private func makeReceivedDialogue(id: String, speciesName: String, events: [DialogueEvent] = []) -> DialogueManifest {
    DialogueManifest(id: id, pages: [.init(lines: ["<PLAYER> received", speciesName + "!"], waitsForPrompt: true, events: events)])
}

private func makeRivalReceivedDialogue(id: String, speciesName: String, events: [DialogueEvent] = []) -> DialogueManifest {
    DialogueManifest(id: id, pages: [.init(lines: ["<RIVAL> received", speciesName + "!"], waitsForPrompt: true, events: events)])
}

private func buildStandardTrainerDialogues(
    mapIDs: [String],
    textContentsByMapID: [String: String],
    mapScriptMetadataByMapID: [String: MapScriptMetadata]
) throws -> [DialogueManifest] {
    var dialogueByID: [String: DialogueManifest] = [:]

    for mapID in mapIDs {
        guard
            let metadata = mapScriptMetadataByMapID[mapID],
            metadata.usesStandardTrainerLoop,
            let textContents = textContentsByMapID[mapID]
        else {
            continue
        }

        for trainerHeader in metadata.trainerHeadersByLabel.values {
            for localLabel in [
                trainerHeader.battleTextLabel,
                trainerHeader.endBattleTextLabel,
                trainerHeader.afterBattleTextLabel,
            ] {
                let farLabel = metadata.farTextLabelByLocalLabel[localLabel] ?? localLabel
                let dialogueID = normalizedDialogueID(from: farLabel)
                if dialogueByID[dialogueID] != nil {
                    continue
                }
                dialogueByID[dialogueID] = try extractDialogue(id: dialogueID, label: farLabel, from: textContents)
            }
        }
    }

    return dialogueByID.values.sorted { $0.id < $1.id }
}

private func referencedVisiblePickupItemIDs(repoRoot: URL) -> [String] {
    var itemIDs: Set<String> = []

    for definition in gameplayCoverageMaps {
        let objectURL = repoRoot.appendingPathComponent(definition.objectFile)
        guard let contents = try? String(contentsOf: objectURL) else { continue }
        for rawLine in contents.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = rawLine.split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false).first?
                .trimmingCharacters(in: .whitespaces) ?? ""
            guard line.hasPrefix("object_event"), line.contains("SPRITE_POKE_BALL") else { continue }
            let tokens = line
                .replacingOccurrences(of: "object_event", with: "")
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
            guard tokens.count >= 7 else { continue }
            itemIDs.insert(tokens[6])
        }
    }

    return itemIDs.sorted()
}

private func buildPickupFoundDialogues(
    itemIDs: [String],
    itemNamesByID: [String: String]
) -> [DialogueManifest] {
    itemIDs.map { itemID in
        DialogueManifest(
            id: pickupFoundDialogueID(for: itemID),
            pages: [.init(
                lines: ["<PLAYER> found", "\(itemNamesByID[itemID] ?? itemID)!"],
                waitsForPrompt: true,
                events: [.init(kind: .soundEffect, soundEffectID: "SFX_GET_ITEM_1")]
            )]
        )
    }
}

private func pickupFoundDialogueID(for itemID: String) -> String {
    "pickup_found_\(itemID.lowercased())"
}

private func dialogueEvent(for line: String) -> DialogueEvent? {
    switch line {
    case "sound_get_item_1", "sound_level_up":
        return .init(kind: .soundEffect, soundEffectID: "SFX_GET_ITEM_1")
    case "sound_get_item_2":
        return .init(kind: .soundEffect, soundEffectID: "SFX_GET_ITEM_2")
    case "sound_get_key_item":
        return .init(kind: .soundEffect, soundEffectID: "SFX_GET_KEY_ITEM")
    case "sound_caught_mon":
        return .init(kind: .soundEffect, soundEffectID: "SFX_CAUGHT_MON")
    case "sound_dex_page_added":
        return .init(kind: .soundEffect, soundEffectID: "SFX_DEX_PAGE_ADDED")
    case "sound_cry_nidorina":
        return .init(kind: .cry, speciesID: "NIDORINA")
    case "sound_cry_pidgeot":
        return .init(kind: .cry, speciesID: "PIDGEOT")
    case "sound_cry_dewgong":
        return .init(kind: .cry, speciesID: "DEWGONG")
    default:
        return nil
    }
}
