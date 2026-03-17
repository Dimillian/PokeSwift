import PokeCore
import PokeDataModel
import PokeUI

extension GameplayScenePropsFactory {
    private struct FieldPartySidebarConfiguration {
        let mode: PartySidebarInteractionMode
        let selectedIndex: Int?
        let selectableIndices: Set<Int>
        let annotationByIndex: [Int: String]
        let promptText: String?
    }

    private struct BattlePartySidebarConfiguration {
        let mode: PartySidebarInteractionMode
        let focusedIndex: Int?
        let selectableIndices: Set<Int>
        let annotationByIndex: [Int: String]
        let promptText: String?
    }

    static func makeFieldPartySidebar(
        runtime: GameRuntime,
        party: PartyTelemetry?,
        manifestIndex: GameplaySidebarManifestIndex
    ) -> PartySidebarProps {
        let configuration = fieldPartySidebarConfiguration(runtime: runtime, party: party)

        return GameplaySidebarPropsBuilder.makeParty(
            from: party,
            speciesDetailsByID: manifestIndex.speciesDetailsByID,
            moveDetailsByID: manifestIndex.moveDetailsByID,
            mode: configuration.mode,
            focusedIndex: runtime.fieldPartyReorderSelectionIndex,
            selectedIndex: configuration.selectedIndex,
            selectableIndices: configuration.selectableIndices,
            annotationByIndex: configuration.annotationByIndex,
            promptText: configuration.promptText
        )
    }

    static func makeBattlePartySidebar(
        runtime: GameRuntime,
        party: PartyTelemetry?,
        manifestIndex: GameplaySidebarManifestIndex,
        battle: BattleTelemetry
    ) -> PartySidebarProps {
        let configuration = battlePartySidebarConfiguration(
            runtime: runtime,
            party: party,
            battle: battle
        )

        return GameplaySidebarPropsBuilder.makeParty(
            from: party,
            speciesDetailsByID: manifestIndex.speciesDetailsByID,
            moveDetailsByID: manifestIndex.moveDetailsByID,
            mode: configuration.mode,
            focusedIndex: configuration.focusedIndex,
            selectableIndices: configuration.selectableIndices,
            annotationByIndex: configuration.annotationByIndex,
            promptText: configuration.promptText
        )
    }

    private static func fieldPartySidebarConfiguration(
        runtime: GameRuntime,
        party: PartyTelemetry?
    ) -> FieldPartySidebarConfiguration {
        let partyPokemon = party?.pokemon ?? []
        if let itemID = runtime.fieldItemUseItemID {
            let selectableIndices = medicineSelectableIndices(
                runtime: runtime,
                itemID: itemID,
                partyPokemon: partyPokemon
            )
            return FieldPartySidebarConfiguration(
                mode: .itemUseTarget,
                selectedIndex: nil,
                selectableIndices: selectableIndices,
                annotationByIndex: medicineAnnotations(
                    runtime: runtime,
                    itemID: itemID,
                    partyPokemon: partyPokemon,
                    activeIndex: nil
                ),
                promptText: medicinePromptText(runtime: runtime, itemID: itemID)
            )
        }

        let reorderSelectionIndex = runtime.fieldPartyReorderSelectionIndex
        let selectableIndices = fieldPartySelectableIndices(runtime: runtime, party: party)

        if selectableIndices.isEmpty {
            return FieldPartySidebarConfiguration(
                mode: .passive,
                selectedIndex: nil,
                selectableIndices: [],
                annotationByIndex: [:],
                promptText: nil
            )
        }

        guard let reorderSelectionIndex else {
            return FieldPartySidebarConfiguration(
                mode: .fieldReorderSource,
                selectedIndex: nil,
                selectableIndices: selectableIndices,
                annotationByIndex: [:],
                promptText: fieldPartyPromptText(selectedIndex: nil)
            )
        }

        return FieldPartySidebarConfiguration(
            mode: .fieldReorderDestination,
            selectedIndex: reorderSelectionIndex,
            selectableIndices: selectableIndices,
            annotationByIndex: [reorderSelectionIndex: "MOVING"],
            promptText: fieldPartyPromptText(selectedIndex: reorderSelectionIndex)
        )
    }

    private static func battlePartySidebarConfiguration(
        runtime: GameRuntime,
        party: PartyTelemetry?,
        battle: BattleTelemetry
    ) -> BattlePartySidebarConfiguration {
        let partyPokemon = party?.pokemon ?? []
        let isSelecting = battle.phase == .partySelection
        let activeIndex = runtime.currentBattlePlayerActiveIndex ?? 0

        if isSelecting, let itemID = runtime.currentBattlePartySelectionItemID {
            return BattlePartySidebarConfiguration(
                mode: .itemUseTarget,
                focusedIndex: battle.focusedPartyIndex,
                selectableIndices: medicineSelectableIndices(
                    runtime: runtime,
                    itemID: itemID,
                    partyPokemon: partyPokemon
                ),
                annotationByIndex: medicineAnnotations(
                    runtime: runtime,
                    itemID: itemID,
                    partyPokemon: partyPokemon,
                    activeIndex: activeIndex
                ),
                promptText: medicinePromptText(runtime: runtime, itemID: itemID)
            )
        }

        return BattlePartySidebarConfiguration(
            mode: isSelecting ? .battleSwitch : .passive,
            focusedIndex: isSelecting ? battle.focusedPartyIndex : nil,
            selectableIndices: battlePartySelectableIndices(
                partyPokemon: partyPokemon,
                activeIndex: activeIndex
            ),
            annotationByIndex: battlePartyAnnotations(
                partyPokemon: partyPokemon,
                activeIndex: activeIndex
            ),
            promptText: isSelecting ? GameplayBattlePrompts.defaultPrompt(for: battle.phase) : nil
        )
    }

    private static func fieldPartySelectableIndices(
        runtime: GameRuntime,
        party: PartyTelemetry?
    ) -> Set<Int> {
        guard runtime.scene == .field, let partyPokemon = party?.pokemon, partyPokemon.count > 1 else {
            return []
        }
        return Set(partyPokemon.indices)
    }

    private static func fieldPartyPromptText(selectedIndex: Int?) -> String {
        selectedIndex == nil ? "Choose a #MON." : "Move #MON where?"
    }

    private static func battlePartySelectableIndices(
        partyPokemon: [PartyPokemonTelemetry],
        activeIndex: Int
    ) -> Set<Int> {
        Set(
            partyPokemon.indices.filter { index in
                index != activeIndex && partyPokemon[index].currentHP > 0
            }
        )
    }

    private static func battlePartyAnnotations(
        partyPokemon: [PartyPokemonTelemetry],
        activeIndex: Int
    ) -> [Int: String] {
        var annotationByIndex: [Int: String] = [activeIndex: "ACTIVE"]
        for index in partyPokemon.indices where partyPokemon[index].currentHP == 0 {
            annotationByIndex[index] = "FAINTED"
        }
        return annotationByIndex
    }

    private static func medicinePromptText(
        runtime: GameRuntime,
        itemID: String
    ) -> String {
        guard let item = runtime.content.item(id: itemID) else {
            return "Use on which #MON?"
        }
        return "Use \(item.displayName) on which #MON?"
    }

    private static func medicineSelectableIndices(
        runtime: GameRuntime,
        itemID: String,
        partyPokemon: [PartyPokemonTelemetry]
    ) -> Set<Int> {
        guard let medicine = runtime.content.item(id: itemID)?.medicine else {
            return []
        }

        return Set(
            partyPokemon.indices.filter { index in
                canApplyMedicine(medicine: medicine, to: partyPokemon[index])
            }
        )
    }

    private static func medicineAnnotations(
        runtime: GameRuntime,
        itemID: String,
        partyPokemon: [PartyPokemonTelemetry],
        activeIndex: Int?
    ) -> [Int: String] {
        guard let medicine = runtime.content.item(id: itemID)?.medicine else {
            return [:]
        }

        return Dictionary(
            uniqueKeysWithValues: partyPokemon.indices.compactMap { index in
                let annotation = medicineAnnotation(
                    medicine: medicine,
                    pokemon: partyPokemon[index],
                    isActive: activeIndex == index
                )
                return annotation.map { (index, $0) }
            }
        )
    }

    private static func canApplyMedicine(
        medicine: ItemManifest.MedicineAttributes,
        to pokemon: PartyPokemonTelemetry
    ) -> Bool {
        let canCureStatus = medicineCanCureStatus(medicine.statusMode, on: pokemon)
        var healedAmount = 0

        switch medicine.hpMode {
        case .none:
            break
        case .fixed:
            guard pokemon.currentHP > 0 else {
                return false
            }
            if pokemon.currentHP < pokemon.maxHP {
                let nextHP = min(pokemon.maxHP, pokemon.currentHP + max(0, medicine.hpAmount ?? 0))
                healedAmount = max(0, nextHP - pokemon.currentHP)
            } else if canCureStatus == false {
                return false
            }
        case .healToFull:
            guard pokemon.currentHP > 0 else {
                return false
            }
            if pokemon.currentHP < pokemon.maxHP {
                healedAmount = pokemon.maxHP - pokemon.currentHP
            } else if canCureStatus == false {
                return false
            }
        case .reviveHalfMax, .reviveFull:
            guard pokemon.currentHP == 0 else {
                return false
            }
            healedAmount = 1
        }

        return healedAmount > 0 || canCureStatus
    }

    private static func medicineCanCureStatus(
        _ statusMode: ItemManifest.MedicineAttributes.StatusMode,
        on pokemon: PartyPokemonTelemetry
    ) -> Bool {
        switch statusMode {
        case .none:
            return false
        case .all:
            return pokemon.majorStatus != .none
        case .poison:
            return pokemon.majorStatus == .poison
        case .burn:
            return pokemon.majorStatus == .burn
        case .freeze:
            return pokemon.majorStatus == .freeze
        case .sleep:
            return pokemon.majorStatus == .sleep
        case .paralysis:
            return pokemon.majorStatus == .paralysis
        }
    }

    private static func medicineAnnotation(
        medicine: ItemManifest.MedicineAttributes,
        pokemon: PartyPokemonTelemetry,
        isActive: Bool
    ) -> String? {
        if canApplyMedicine(medicine: medicine, to: pokemon) {
            return isActive ? "ACTIVE" : nil
        }

        switch medicine.hpMode {
        case .reviveHalfMax, .reviveFull:
            return pokemon.currentHP == 0 ? (isActive ? "ACTIVE" : nil) : "NOT FAINTED"
        case .fixed, .healToFull:
            if pokemon.currentHP == 0 {
                return "FAINTED"
            }
            if pokemon.currentHP >= pokemon.maxHP, medicine.statusMode == .none {
                return "FULL HP"
            }
        case .none:
            break
        }

        switch medicine.statusMode {
        case .none:
            return isActive ? "ACTIVE" : nil
        case .all:
            return pokemon.majorStatus == .none ? "NO STATUS" : "NO EFFECT"
        case .poison, .burn, .freeze, .sleep, .paralysis:
            return pokemon.majorStatus == .none ? "NO STATUS" : "NO EFFECT"
        }
    }
}
