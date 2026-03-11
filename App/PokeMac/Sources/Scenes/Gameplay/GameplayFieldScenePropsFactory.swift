import PokeCore
import PokeDataModel
import PokeUI

@MainActor
enum GameplayScenePropsFactory {
    static func make(runtime: GameRuntime) -> GameplaySceneProps? {
        let snapshot = runtime.currentSnapshot()
        let manifestIndex = GameplaySidebarManifestIndex(runtime: runtime)
        let saveSidebar = makeSaveSidebar(runtime: runtime)
        let sidebarParty = GameplaySidebarPropsBuilder.makeParty(
            from: snapshot.party,
            speciesDetailsByID: manifestIndex.speciesDetailsByID,
            moveDisplayNamesByID: manifestIndex.moveDisplayNamesByID
        )
        let sidebarInventory = GameplaySidebarPropsBuilder.makeInventory(
            items: snapshot.inventory?.items.map {
                InventorySidebarItemProps(
                    id: $0.itemID,
                    name: $0.displayName,
                    quantityText: "x\($0.quantity)"
                )
            } ?? []
        )

        switch GameplaySidebarKind.forScene(runtime.scene) {
        case .fieldLike:
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
                        fieldTransition: snapshot.field?.transition,
                        dialogueLines: runtime.currentDialoguePage?.lines,
                        starterChoiceOptions: runtime.scene == .starterChoice ? runtime.starterChoiceOptions : [],
                        starterChoiceFocusedIndex: runtime.starterChoiceFocusedIndex
                    )
                ),
                sidebarMode: .fieldLike(
                    GameplayFieldSidebarProps(
                        profile: makeTrainerProfile(runtime: runtime),
                        party: sidebarParty,
                        inventory: sidebarInventory,
                        save: saveSidebar,
                        options: GameplaySidebarPropsBuilder.makeOptionsSection()
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
                initialFieldDisplayStyle: .defaultGameplayStyle
            )
        case .battle:
            guard let battle = snapshot.battle else { return nil }

            let playerSpriteURL = runtime.content.species(id: battle.playerPokemon.speciesID)?
                .battleSprite
                .map { runtime.content.rootURL.appendingPathComponent($0.backImagePath) }
            let enemySpriteURL = runtime.content.species(id: battle.enemyPokemon.speciesID)?
                .battleSprite
                .map { runtime.content.rootURL.appendingPathComponent($0.frontImagePath) }
            let promptText = battle.textLines.last ?? (battle.battleMessage.isEmpty ? "Pick the next move." : battle.battleMessage)

            return GameplaySceneProps(
                viewport: .battle(
                    BattleViewportProps(
                        trainerName: battle.trainerName,
                        textLines: battle.textLines,
                        playerPokemon: battle.playerPokemon,
                        enemyPokemon: battle.enemyPokemon,
                        playerSpriteURL: playerSpriteURL,
                        enemySpriteURL: enemySpriteURL
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
                        moveSlots: battle.moveSlots,
                        focusedMoveIndex: battle.focusedMoveIndex,
                        canRun: battle.canRun,
                        party: sidebarParty
                    )
                ),
                onSidebarAction: nil,
                initialFieldDisplayStyle: .defaultGameplayStyle
            )
        }
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
private struct GameplaySidebarManifestIndex {
    let speciesDetailsByID: [String: PartySidebarSpeciesDetails]
    let moveDisplayNamesByID: [String: String]

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
    }
}
