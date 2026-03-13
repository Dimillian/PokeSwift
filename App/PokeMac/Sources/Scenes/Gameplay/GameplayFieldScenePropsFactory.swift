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
        gameplayHDREnabled: Bool
    ) -> GameplaySceneProps? {
        let manifestIndex = cachedManifestIndex(for: runtime)
        let saveSidebar = makeSaveSidebar(runtime: runtime)

        let nicknameConfirmation = makeNicknameConfirmationProps(runtime: runtime)

        switch GameplaySidebarKind.forScene(runtime.scene) {
        case .fieldLike:
            let fieldState = runtime.currentFieldSceneState()
            let sidebarInventory = GameplaySidebarPropsBuilder.makeInventory(
                items: fieldState.inventory?.items.map {
                    InventorySidebarItemProps(
                        id: $0.itemID,
                        name: $0.displayName,
                        quantityText: "x\($0.quantity)"
                    )
                } ?? []
            )

            let pokedexSidebar = GameplaySidebarPropsBuilder.makePokedex(
                allSpecies: manifestIndex.pokedexSpeciesList,
                ownedSpeciesIDs: runtime.ownedSpeciesIDs,
                seenSpeciesIDs: runtime.seenSpeciesIDs
            )

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
                        fieldPrompt: fieldState.fieldPrompt,
                        fieldHealing: fieldState.fieldHealing,
                        shop: fieldState.shop,
                        starterChoiceOptions: runtime.scene == .starterChoice ? runtime.starterChoiceOptions : [],
                        starterChoiceFocusedIndex: runtime.starterChoiceFocusedIndex,
                        namingProps: makeNamingProps(runtime: runtime),
                        nicknameConfirmation: nicknameConfirmation
                    )
                ),
                sidebarMode: .fieldLike(
                    GameplayFieldSidebarProps(
                        profile: makeTrainerProfile(runtime: runtime),
                        pokedex: pokedexSidebar,
                        party: makeFieldPartySidebar(runtime: runtime, party: fieldState.party, manifestIndex: manifestIndex),
                        inventory: sidebarInventory,
                        save: saveSidebar,
                        options: GameplaySidebarPropsBuilder.makeOptionsSection(
                            isMusicEnabled: runtime.isMusicEnabled,
                            appearanceMode: appearanceMode,
                            gameplayHDREnabled: gameplayHDREnabled
                        )
                    )
                ),
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
                initialFieldDisplayStyle: .defaultGameplayStyle
            )
        case .battle:
            let battleState = runtime.currentBattleSceneState()
            guard let battle = battleState.battle else { return nil }

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
            let promptText = GameplayBattlePrompts.promptText(
                textLines: battle.textLines,
                battleMessage: battle.battleMessage,
                phase: battle.phase
            )

            return GameplaySceneProps(
                viewport: .battle(
                    BattleViewportProps(
                        trainerName: battle.trainerName,
                        kind: battle.kind,
                        phase: battle.phase,
                        textLines: battle.textLines,
                        playerPokemon: battle.playerPokemon,
                        enemyPokemon: battle.enemyPokemon,
                        trainerSpriteURL: trainerSpriteURL,
                        playerTrainerFrontSpriteURL: playerTrainerFrontSpriteURL,
                        playerTrainerBackSpriteURL: playerTrainerBackSpriteURL,
                        playerSpriteURL: playerSpriteURL,
                        enemySpriteURL: enemySpriteURL,
                        bagItems: battle.bagItems,
                        focusedBagItemIndex: battle.focusedBagItemIndex,
                        presentation: battle.presentation,
                        nicknameConfirmation: nicknameConfirmation
                    )
                ),
                sidebarMode: .battle(
                    BattleSidebarProps(
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
                        party: makeBattlePartySidebar(party: battleState.party, manifestIndex: manifestIndex, battle: battle),
                        capture: battle.capture,
                        presentation: battle.presentation
                    )
                ),
                onSidebarAction: nil,
                onPartyRowSelected: { index in
                    runtime.handlePartySidebarSelection(index)
                },
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
            ownedBadgeIDs: runtime.earnedBadgeIDs
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

    private static func makeSaveSidebar(runtime: GameRuntime) -> SaveSidebarProps {
        let metadata = runtime.currentSaveMetadata
        let summary = metadata == nil ? "No Save" : "1 File"
        let saveDetail: String
        if let result = runtime.currentLastSaveResult, result.operation == "save" {
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
}

@MainActor
struct GameplaySidebarManifestIndex {
    let speciesDetailsByID: [String: PartySidebarSpeciesDetails]
    let moveDisplayNamesByID: [String: String]
    let pokedexSpeciesList: [GameplaySidebarPropsBuilder.PokedexSpeciesData]

    init(runtime: GameRuntime) {
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

        moveDisplayNamesByID = Dictionary(
            uniqueKeysWithValues: runtime.content.gameplayManifest.moves.map { move in
                (move.id, move.displayName)
            }
        )

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
                baseHP: species.baseHP,
                baseAttack: species.baseAttack,
                baseDefense: species.baseDefense,
                baseSpeed: species.baseSpeed,
                baseSpecial: species.baseSpecial
            )
        }.sorted { $0.dexNumber < $1.dexNumber }
    }
}
