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
        snapshot: RuntimeTelemetrySnapshot,
        manifestIndex: GameplaySidebarManifestIndex
    ) -> PartySidebarProps {
        let configuration = fieldPartySidebarConfiguration(runtime: runtime, snapshot: snapshot)

        return GameplaySidebarPropsBuilder.makeParty(
            from: snapshot.party,
            speciesDetailsByID: manifestIndex.speciesDetailsByID,
            moveDisplayNamesByID: manifestIndex.moveDisplayNamesByID,
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
        snapshot: RuntimeTelemetrySnapshot,
        manifestIndex: GameplaySidebarManifestIndex,
        battle: BattleTelemetry
    ) -> PartySidebarProps {
        let configuration = battlePartySidebarConfiguration(snapshot: snapshot, battle: battle)

        return GameplaySidebarPropsBuilder.makeParty(
            from: snapshot.party,
            speciesDetailsByID: manifestIndex.speciesDetailsByID,
            moveDisplayNamesByID: manifestIndex.moveDisplayNamesByID,
            mode: configuration.mode,
            focusedIndex: configuration.focusedIndex,
            selectableIndices: configuration.selectableIndices,
            annotationByIndex: configuration.annotationByIndex,
            promptText: configuration.promptText
        )
    }

    private static func fieldPartySidebarConfiguration(
        runtime: GameRuntime,
        snapshot: RuntimeTelemetrySnapshot
    ) -> FieldPartySidebarConfiguration {
        let hasInteractiveParty = runtime.scene == .field && (snapshot.party?.pokemon.count ?? 0) > 1
        let reorderSelectionIndex = runtime.fieldPartyReorderSelectionIndex

        if hasInteractiveParty == false {
            return FieldPartySidebarConfiguration(
                mode: .passive,
                selectedIndex: nil,
                selectableIndices: [],
                annotationByIndex: [:],
                promptText: nil
            )
        }

        let selectableIndices = Set(snapshot.party?.pokemon.indices.map { $0 } ?? [])
        guard let reorderSelectionIndex else {
            return FieldPartySidebarConfiguration(
                mode: .fieldReorderSource,
                selectedIndex: nil,
                selectableIndices: selectableIndices,
                annotationByIndex: [:],
                promptText: "Choose a #MON."
            )
        }

        return FieldPartySidebarConfiguration(
            mode: .fieldReorderDestination,
            selectedIndex: reorderSelectionIndex,
            selectableIndices: selectableIndices,
            annotationByIndex: [reorderSelectionIndex: "MOVING"],
            promptText: "Move #MON where?"
        )
    }

    private static func battlePartySidebarConfiguration(
        snapshot: RuntimeTelemetrySnapshot,
        battle: BattleTelemetry
    ) -> BattlePartySidebarConfiguration {
        let partyPokemon = snapshot.party?.pokemon ?? []
        var annotationByIndex: [Int: String] = [0: "ACTIVE"]
        for index in partyPokemon.indices where partyPokemon[index].currentHP == 0 {
            annotationByIndex[index] = "FAINTED"
        }

        let isSelecting = battle.phase == "partySelection"
        return BattlePartySidebarConfiguration(
            mode: isSelecting ? .battleSwitch : .passive,
            focusedIndex: isSelecting ? battle.focusedPartyIndex : nil,
            selectableIndices: Set(
                partyPokemon.indices.filter { index in
                    index != 0 && partyPokemon[index].currentHP > 0
                }
            ),
            annotationByIndex: annotationByIndex,
            promptText: isSelecting ? "Bring out which #MON?" : nil
        )
    }
}
