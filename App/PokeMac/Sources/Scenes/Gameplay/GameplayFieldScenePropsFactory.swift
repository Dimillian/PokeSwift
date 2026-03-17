import Foundation
import PokeCore
import PokeDataModel
import PokeRender
import PokeUI

@MainActor
enum GameplayScenePropsFactory {
    private static var sidebarManifestIndexCache: [String: GameplaySidebarManifestIndex] = [:]

    static func make(
        runtime: GameRuntime,
        appearanceMode: AppAppearanceMode,
        gameBoyShellStyle: GameBoyShellStyle,
        gameplayHDREnabled: Bool
    ) -> GameplaySceneProps? {
        let manifestIndex = cachedManifestIndex(for: runtime)
        let saveSidebar = makeSaveSidebar(runtime: runtime)

        let nicknameConfirmation = makeNicknameConfirmationProps(runtime: runtime)

        switch GameplaySidebarKind.forScene(runtime.scene) {
        case .fieldLike:
            let fieldState = runtime.currentFieldSceneState()
            let evolutionState = runtime.currentEvolutionSceneState()
            let enabledFieldInventoryItemIDs = Set(
                (fieldState.inventory?.items ?? []).compactMap { item in
                    runtime.content.item(id: item.itemID)?.medicine == nil ? nil : item.itemID
                }
            )
            let sidebarInventory = makeInventorySidebar(
                from: fieldState.inventory?.items ?? [],
                manifestIndex: manifestIndex,
                focusedItemID: runtime.fieldItemUseItemID,
                enabledItemIDs: enabledFieldInventoryItemIDs
            )

            let pokedexSidebar = GameplaySidebarPropsBuilder.makePokedex(
                allSpecies: manifestIndex.pokedexSpeciesList,
                ownedSpeciesIDs: runtime.ownedSpeciesIDs,
                seenSpeciesIDs: runtime.seenSpeciesIDs,
                speciesEncounterCounts: runtime.encounterCountsBySpeciesID,
                selectedEntryID: runtime.captureAftermathPokedexSelectionID
            )

            let sidebarMode = GameplaySidebarMode.fieldLike(
                GameplayFieldSidebarProps(
                    profile: makeTrainerProfile(runtime: runtime),
                    pokedex: pokedexSidebar,
                    party: makeFieldPartySidebar(runtime: runtime, party: fieldState.party, manifestIndex: manifestIndex),
                    inventory: sidebarInventory,
                    save: saveSidebar,
                    options: GameplaySidebarPropsBuilder.makeOptionsSection(
                        isMusicEnabled: runtime.isMusicEnabled,
                        appearanceMode: appearanceMode,
                        gameBoyShellStyle: gameBoyShellStyle,
                        gameplayHDREnabled: gameplayHDREnabled,
                        textSpeed: runtime.optionsTextSpeed,
                        battleAnimation: runtime.optionsBattleAnimation,
                        battleStyle: runtime.optionsBattleStyle
                    ),
                    preferredExpandedSection: runtime.scene == .evolution ? .party : (
                        runtime.fieldItemUseItemID != nil
                            ? .party
                            : (runtime.captureAftermathPokedexSelectionID == nil ? nil : .pokedex)
                    )
                )
            )

            if let evolutionState {
                return GameplaySceneProps(
                    viewport: .evolution(makeEvolutionViewportProps(runtime: runtime, evolutionState: evolutionState)),
                    sidebarMode: sidebarMode,
                    onSidebarAction: { actionID in
                        switch actionID {
                        case "save":
                            _ = runtime.saveCurrentGame()
                        case "load":
                            _ = runtime.loadSavedGameFromSidebar()
                        default:
                            break
                        }
                    },
                    onPartyRowSelected: { index in
                        runtime.handlePartySidebarSelection(index)
                    },
                    onInventoryItemSelected: { itemID in
                        runtime.handleInventorySidebarSelection(itemID)
                    },
                    initialFieldDisplayStyle: .defaultGameplayStyle
                )
            }

            return GameplaySceneProps(
                viewport: .field(
                    GameplayFieldViewportProps(
                        map: runtime.currentMapManifest,
                        playerPosition: runtime.playerPosition,
                        playerFacing: runtime.playerFacing,
                        playerStepDuration: runtime.fieldAnimationStepDuration,
                        objects: runtime.currentFieldObjects,
                        playerSpriteID: runtime.playerSpriteID,
                        renderAssets: makeFieldRenderAssets(runtime: runtime),
                        fieldTransition: fieldState.transition,
                        fieldAlert: fieldState.fieldAlert,
                        dialogueLines: runtime.currentDialoguePage?.lines,
                        dialogueInstantReveal: runtime.dialogueTextFullyRevealed,
                        onDialogueRevealed: { [weak runtime] in runtime?.dialogueTextFullyRevealed = true },
                        fieldPrompt: fieldState.fieldPrompt,
                        fieldHealing: fieldState.fieldHealing,
                        shop: fieldState.shop,
                        starterChoiceOptions: runtime.scene == .starterChoice ? runtime.starterChoiceOptions : [],
                        starterChoiceFocusedIndex: runtime.starterChoiceFocusedIndex,
                        namingProps: makeNamingProps(runtime: runtime),
                        nicknameConfirmation: nicknameConfirmation
                    )
                ),
                sidebarMode: sidebarMode,
                onSidebarAction: { actionID in
                    switch actionID {
                    case "save":
                        _ = runtime.saveCurrentGame()
                    case "load":
                        _ = runtime.loadSavedGameFromSidebar()
                    default:
                        break
                    }
                },
                onPartyRowSelected: { index in
                    runtime.handlePartySidebarSelection(index)
                },
                onInventoryItemSelected: { itemID in
                    runtime.handleInventorySidebarSelection(itemID)
                },
                initialFieldDisplayStyle: .defaultGameplayStyle
            )
        case .battle:
            let battleState = runtime.currentBattleSceneState()
            guard let battle = battleState.battle else { return nil }
            let isEnemySpeciesOwned = runtime.ownedSpeciesIDs.contains(battle.enemyPokemon.speciesID)

            let playerSpriteURL = runtime.content.species(id: battle.playerPokemon.speciesID)?
                .battleSprite
                .map { runtime.content.rootURL.appendingPathComponent($0.backImagePath) }
            let enemySpriteURL = runtime.content.species(id: battle.enemyPokemon.speciesID)?
                .battleSprite
                .map { runtime.content.rootURL.appendingPathComponent($0.frontImagePath) }
            let trainerSpriteURL = battle.trainerSpritePath.map {
                runtime.content.rootURL.appendingPathComponent($0)
            }
            let playerTrainerFrontSpriteURL = runtime.content.rootURL.appendingPathComponent("Assets/battle/trainers/red.png")
            let playerTrainerBackSpriteURL = runtime.content.rootURL.appendingPathComponent("Assets/battle/trainers/redb.png")
            let sendOutPoofSpriteURL = runtime.content.rootURL.appendingPathComponent("Assets/battle/effects/send_out_poof.png")
            let battleAnimationTilesetURLs = Dictionary(
                uniqueKeysWithValues: runtime.content.battleAnimationManifest.tilesets.map {
                    ($0.id, runtime.content.rootURL.appendingPathComponent($0.imagePath))
                }
            )
            let promptText = GameplayBattlePrompts.promptText(
                textLines: battle.textLines,
                battleMessage: battle.battleMessage,
                phase: battle.phase
            )
            let sidebarProps = BattleSidebarProps(
                trainerName: battle.trainerName,
                kind: battle.kind,
                phase: battle.phase,
                promptText: promptText,
                playerPokemon: battle.playerPokemon,
                enemyPokemon: battle.enemyPokemon,
                learnMovePrompt: battle.learnMovePrompt,
                moveSlots: battle.moveSlots,
                focusedMoveIndex: battle.focusedMoveIndex,
                canRun: battle.canRun,
                canUseBag: battle.canUseBag,
                canSwitch: battle.canSwitch,
                bagItemCount: battle.bagItems.count,
                moveDetailsByID: manifestIndex.moveDetailsByID,
                party: makeBattlePartySidebar(
                    runtime: runtime,
                    party: battleState.party,
                    manifestIndex: manifestIndex,
                    battle: battle
                ),
                capture: battle.capture,
                presentation: battle.presentation
            )

            return GameplaySceneProps(
                viewport: .battle(
                    BattleViewportProps(
                        trainerName: battle.trainerName,
                        kind: battle.kind,
                        phase: battle.phase,
                        showsBagOverlay: sidebarProps.showsBagOverlay,
                        textLines: battle.textLines,
                        playerPokemon: battle.playerPokemon,
                        enemyPokemon: battle.enemyPokemon,
                        enemyParty: battle.enemyParty,
                        enemyPartyCount: battle.enemyPartyCount,
                        isEnemySpeciesOwned: isEnemySpeciesOwned,
                        trainerSpriteURL: trainerSpriteURL,
                        playerTrainerFrontSpriteURL: playerTrainerFrontSpriteURL,
                        playerTrainerBackSpriteURL: playerTrainerBackSpriteURL,
                        sendOutPoofSpriteURL: sendOutPoofSpriteURL,
                        battleAnimationManifest: runtime.content.battleAnimationManifest,
                        battleAnimationTilesetURLs: battleAnimationTilesetURLs,
                        playerSpriteURL: playerSpriteURL,
                        enemySpriteURL: enemySpriteURL,
                        bag: makeInventorySidebar(
                            from: battle.bagItems,
                            manifestIndex: manifestIndex,
                            focusedItemID: battle.bagItems.indices.contains(battle.focusedBagItemIndex)
                                ? battle.bagItems[battle.focusedBagItemIndex].itemID
                                : nil
                        ),
                        onBagItemSelected: { itemID in
                            runtime.handleInventorySidebarSelection(itemID)
                        },
                        presentation: battle.presentation,
                        nicknameConfirmation: nicknameConfirmation
                    )
                ),
                sidebarMode: .battle(sidebarProps),
                onSidebarAction: nil,
                onPartyRowSelected: { index in
                    runtime.handlePartySidebarSelection(index)
                },
                onInventoryItemSelected: nil,
                initialFieldDisplayStyle: .defaultGameplayStyle
            )
        }
    }

    private static func cachedManifestIndex(for runtime: GameRuntime) -> GameplaySidebarManifestIndex {
        let cacheKey = "\(runtime.content.rootURL.path)::\(runtime.content.gameManifest.contentVersion)"
        if let cached = sidebarManifestIndexCache[cacheKey] {
            return cached
        }

        let manifestIndex = GameplaySidebarManifestIndex(runtime: runtime)
        sidebarManifestIndexCache[cacheKey] = manifestIndex
        return manifestIndex
    }

    private static func makeTrainerProfile(runtime: GameRuntime) -> TrainerProfileProps {
        GameplaySidebarPropsBuilder.makeProfile(
            trainerName: runtime.playerName,
            locationName: runtime.currentMapManifest?.displayName ?? "Unknown Location",
            scene: runtime.scene,
            playerPosition: runtime.playerPosition,
            facing: runtime.playerPosition == nil ? nil : runtime.playerFacing,
            portrait: makeTrainerPortrait(runtime: runtime),
            money: runtime.playerMoney,
            ownedBadgeIDs: runtime.earnedBadgeIDs,
            totalStepCount: runtime.totalStepCount,
            wildEncounterCount: runtime.wildEncounterCount,
            trainerBattleCount: runtime.trainerBattleCount
        )
    }

    private static func makeTrainerPortrait(runtime: GameRuntime) -> TrainerPortraitProps {
        guard let sprite = runtime.content.overworldSprite(id: runtime.playerSpriteID) else {
            return TrainerPortraitProps(label: runtime.playerName, spriteURL: nil, spriteFrame: nil)
        }

        let spriteFrame: PixelRect?
        switch runtime.playerFacing {
        case .down:
            spriteFrame = sprite.facingFrames.down
        case .up:
            spriteFrame = sprite.facingFrames.up
        case .left:
            spriteFrame = sprite.facingFrames.left
        case .right:
            spriteFrame = sprite.facingFrames.right
        }

        return TrainerPortraitProps(
            label: runtime.playerName,
            spriteURL: runtime.content.rootURL.appendingPathComponent(sprite.imagePath),
            spriteFrame: spriteFrame
        )
    }

    private static func makeNamingProps(runtime: GameRuntime) -> NamingOverlayProps? {
        guard let state = runtime.namingState else { return nil }
        return NamingOverlayProps(
            speciesDisplayName: state.defaultName,
            enteredText: state.enteredText,
            maxLength: RuntimeNamingState.maxLength
        )
    }

    private static func makeNicknameConfirmationProps(runtime: GameRuntime) -> NicknameConfirmationViewProps? {
        guard let confirmation = runtime.nicknameConfirmation else { return nil }
        return NicknameConfirmationViewProps(
            speciesDisplayName: confirmation.defaultName,
            focusedIndex: confirmation.focusedIndex
        )
    }

    private static func makeEvolutionViewportProps(
        runtime: GameRuntime,
        evolutionState: GameplayEvolutionSceneState
    ) -> EvolutionViewportProps {
        let originalSpriteURL = runtime.content.species(id: evolutionState.originalSpeciesID)?
            .battleSprite
            .map { runtime.content.rootURL.appendingPathComponent($0.frontImagePath) }
        let evolvedSpriteURL = runtime.content.species(id: evolutionState.evolvedSpeciesID)?
            .battleSprite
            .map { runtime.content.rootURL.appendingPathComponent($0.frontImagePath) }

        return EvolutionViewportProps(
            phase: evolutionState.phase,
            animationStep: evolutionState.animationStep,
            showsEvolvedSprite: evolutionState.showsEvolvedSprite,
            textLines: evolutionState.textLines,
            originalDisplayName: evolutionState.originalDisplayName,
            evolvedDisplayName: evolutionState.evolvedDisplayName,
            originalSpriteURL: originalSpriteURL,
            evolvedSpriteURL: evolvedSpriteURL
        )
    }

    private static func makeSaveSidebar(runtime: GameRuntime) -> SaveSidebarProps {
        let metadata = runtime.currentSaveMetadata
        let summary = metadata == nil ? "No Save" : "1 File"
        let saveDetail: String
        if let result = runtime.currentLastSaveResult, result.operation == .save {
            saveDetail = result.succeeded ? "Saved" : "Failed"
        } else {
            saveDetail = runtime.canSaveGame ? "Ready" : "Busy"
        }

        let loadDetail: String
        if let metadata {
            loadDetail = metadata.locationName
        } else if let errorMessage = runtime.currentSaveErrorMessage {
            loadDetail = errorMessage
        } else {
            loadDetail = "No Save"
        }

        return GameplaySidebarPropsBuilder.makeSaveSection(
            summary: summary,
            actions: [
                .init(id: "save", title: "Save Game", detail: saveDetail, isEnabled: runtime.canSaveGame),
                .init(id: "load", title: "Load Save", detail: loadDetail, isEnabled: runtime.canLoadGame),
            ]
        )
    }

    private static func makeInventorySidebar(
        from items: [InventoryItemTelemetry],
        manifestIndex: GameplaySidebarManifestIndex,
        focusedItemID: String? = nil,
        enabledItemIDs: Set<String>? = nil
    ) -> InventorySidebarProps {
        var itemsBySection: [ItemManifest.BagSection: [InventorySidebarItemProps]] = [:]

        for item in items {
            guard let catalogItem = manifestIndex.itemDetailsByID[item.itemID] else {
                continue
            }

            itemsBySection[catalogItem.bagSection, default: []].append(
                InventorySidebarItemProps(
                    id: item.itemID,
                    name: catalogItem.displayName,
                    quantityText: "x\(item.quantity)",
                    iconURL: catalogItem.iconURL,
                    descriptionText: catalogItem.descriptionText,
                    tmhm: catalogItem.tmhm,
                    isEnabled: enabledItemIDs?.contains(item.itemID) ?? true,
                    isFocused: item.itemID == focusedItemID
                )
            )
        }

        let sections = ItemManifest.BagSection.allCases.compactMap { section -> InventorySidebarSectionProps? in
            guard let sectionItems = itemsBySection[section], sectionItems.isEmpty == false else {
                return nil
            }
            return InventorySidebarSectionProps(
                id: section.rawValue,
                title: section.sidebarTitle,
                items: sectionItems
            )
        }

        return GameplaySidebarPropsBuilder.makeInventory(sections: sections)
    }
}

@MainActor
struct GameplaySidebarManifestIndex {
    let speciesDetailsByID: [String: PartySidebarSpeciesDetails]
    let itemDetailsByID: [String: InventoryCatalogItemData]
    let moveDetailsByID: [String: PartySidebarMoveDetails]
    let pokedexSpeciesList: [GameplaySidebarPropsBuilder.PokedexSpeciesData]

    init(runtime: GameRuntime) {
        let speciesByID = Dictionary(
            uniqueKeysWithValues: runtime.content.gameplayManifest.species.map { ($0.id, $0) }
        )
        let itemNamesByID = Dictionary(
            uniqueKeysWithValues: runtime.content.gameplayManifest.items.map { ($0.id, $0.displayName) }
        )

        speciesDetailsByID = Dictionary(
            uniqueKeysWithValues: runtime.content.gameplayManifest.species.map { species in
                (
                    species.id,
                    PartySidebarSpeciesDetails(
                        spriteURL: species.battleSprite.map { runtime.content.rootURL.appendingPathComponent($0.frontImagePath) },
                        primaryType: species.primaryType,
                        secondaryType: species.secondaryType
                    )
                )
            }
        )

        let moveDetailsByID = Dictionary(
            uniqueKeysWithValues: runtime.content.gameplayManifest.moves.map { move in
                (
                    move.id,
                    PartySidebarMoveDetails(
                        displayName: move.displayName,
                        typeLabel: move.type,
                        maxPP: move.maxPP,
                        power: move.power > 0 ? move.power : nil,
                        accuracy: move.accuracy > 0 ? move.accuracy : nil
                    )
                )
            }
        )
        self.moveDetailsByID = moveDetailsByID

        itemDetailsByID = Dictionary(
            uniqueKeysWithValues: runtime.content.gameplayManifest.items.map { item in
                let tmhm = item.tmhmMoveID
                    .flatMap { moveID in moveDetailsByID[moveID].map { (moveID, $0) } }
                    .map { _, moveDetails in
                        InventorySidebarTMHMProps(
                            moveName: moveDetails.displayName,
                            typeLabel: moveDetails.typeLabel ?? "UNKNOWN",
                            maxPPText: "PP \(moveDetails.maxPP ?? 0)"
                        )
                    }

                return (
                    item.id,
                    InventoryCatalogItemData(
                        displayName: item.displayName,
                        bagSection: item.bagSection,
                        iconURL: item.iconAssetPath.map { runtime.content.rootURL.appendingPathComponent($0) },
                        descriptionText: item.shortDescription ?? "A useful item for battle, healing, or travel.",
                        tmhm: tmhm
                    )
                )
            }
        )

        let preEvolutionBySpeciesID = runtime.content.gameplayManifest.species.reduce(
            into: [String: PokedexSidebarEvolutionProps]()
        ) { result, species in
            for evolution in species.evolutions {
                result[evolution.targetSpeciesID] = PokedexSidebarEvolutionProps(
                    id: species.id,
                    displayName: species.displayName,
                    triggerText: Self.evolutionTriggerText(for: evolution.trigger, itemNamesByID: itemNamesByID)
                )
            }
        }

        pokedexSpeciesList = runtime.content.gameplayManifest.species.compactMap { species -> GameplaySidebarPropsBuilder.PokedexSpeciesData? in
            guard let dexNumber = species.dexNumber else { return nil }
            let heightText: String?
            if let ft = species.heightFeet, let inches = species.heightInches {
                heightText = "\(ft)'\(String(format: "%02d", inches))\""
            } else {
                heightText = nil
            }
            let weightText: String?
            if let wt = species.weightTenths {
                weightText = String(format: "%.1f lbs", Double(wt) / 10.0)
            } else {
                weightText = nil
            }
            let evolutions = species.evolutions.map { evolution in
                PokedexSidebarEvolutionProps(
                    id: evolution.targetSpeciesID,
                    displayName: speciesByID[evolution.targetSpeciesID]?.displayName
                        ?? Self.fallbackDisplayName(for: evolution.targetSpeciesID),
                    triggerText: Self.evolutionTriggerText(for: evolution.trigger, itemNamesByID: itemNamesByID)
                )
            }
            let learnedMoves = species.levelUpLearnset
                .sorted {
                    if $0.level == $1.level {
                        return $0.moveID.localizedCompare($1.moveID) == .orderedAscending
                    }
                    return $0.level < $1.level
                }
                .map { move in
                    PokedexSidebarLearnedMoveProps(
                        id: "\(species.id)-\(move.moveID)-\(move.level)",
                        levelText: "Lv \(move.level)",
                        displayName: moveDetailsByID[move.moveID]?.displayName
                            ?? Self.fallbackDisplayName(for: move.moveID)
                    )
                }
            return GameplaySidebarPropsBuilder.PokedexSpeciesData(
                id: species.id,
                dexNumber: dexNumber,
                displayName: species.displayName,
                primaryType: species.primaryType,
                secondaryType: species.secondaryType,
                spriteURL: species.battleSprite.map { runtime.content.rootURL.appendingPathComponent($0.frontImagePath) },
                speciesCategory: species.speciesCategory,
                heightText: heightText,
                weightText: weightText,
                descriptionText: species.pokedexEntryText,
                preEvolution: preEvolutionBySpeciesID[species.id],
                evolutions: evolutions,
                learnedMoves: learnedMoves,
                baseHP: species.baseHP,
                baseAttack: species.baseAttack,
                baseDefense: species.baseDefense,
                baseSpeed: species.baseSpeed,
                baseSpecial: species.baseSpecial
            )
        }.sorted { $0.dexNumber < $1.dexNumber }
    }

    private static func evolutionTriggerText(
        for trigger: EvolutionTriggerManifest,
        itemNamesByID: [String: String]
    ) -> String {
        switch trigger.kind {
        case .level:
            if let level = trigger.level ?? trigger.minimumLevel {
                return "Lv \(level)"
            }
            return "Level Up"
        case .item:
            let itemName = trigger.itemID
                .flatMap { itemNamesByID[$0] }
                ?? trigger.itemID.map(fallbackDisplayName(for:))
                ?? "Item"
            if let minimumLevel = trigger.minimumLevel {
                return "\(itemName) (Lv \(minimumLevel)+)"
            }
            return itemName
        case .trade:
            if let minimumLevel = trigger.minimumLevel {
                return "Trade (Lv \(minimumLevel)+)"
            }
            return "Trade"
        }
    }

    private static func fallbackDisplayName(for identifier: String) -> String {
        identifier
            .lowercased()
            .split(separator: "_")
            .map { $0.capitalized }
            .joined(separator: " ")
    }
}

struct InventoryCatalogItemData {
    let displayName: String
    let bagSection: ItemManifest.BagSection
    let iconURL: URL?
    let descriptionText: String
    let tmhm: InventorySidebarTMHMProps?
}

private extension ItemManifest.BagSection {
    var sidebarTitle: String {
        switch self {
        case .items:
            return "Items"
        case .balls:
            return "Balls"
        case .keyItems:
            return "Key Items"
        case .tmhm:
            return "TM/HM"
        }
    }
}
