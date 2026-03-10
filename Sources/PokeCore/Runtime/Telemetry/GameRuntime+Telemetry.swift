import Foundation
import PokeDataModel

extension GameRuntime {
    public func currentSnapshot() -> RuntimeTelemetrySnapshot {
        RuntimeTelemetrySnapshot(
            appVersion: "0.3.0",
            contentVersion: content.gameManifest.contentVersion,
            scene: scene,
            substate: substate,
            titleMenu: scene == .titleMenu ? TitleMenuTelemetry(entries: menuEntries, focusedIndex: focusedIndex) : nil,
            field: makeFieldTelemetry(),
            dialogue: makeDialogueTelemetry(),
            starterChoice: makeStarterChoiceTelemetry(),
            party: makePartyTelemetry(),
            battle: makeBattleTelemetry(),
            eventFlags: makeFlagTelemetry(),
            recentInputEvents: recentInputEvents,
            assetLoadingFailures: Array(Set(assetLoadingFailures + currentFieldRenderIssues)).sorted(),
            window: .init(scale: windowScale, renderWidth: 160, renderHeight: 144)
        )
    }

    func publishSnapshot() {
        advanceDeferredQueueIfNeeded()
        guard let telemetryPublisher else { return }
        let snapshot = currentSnapshot()
        Task {
            await telemetryPublisher.publish(snapshot: snapshot)
        }
    }

    func makeFieldTelemetry() -> FieldTelemetry? {
        guard let gameplayState, let map = content.map(id: gameplayState.mapID) else { return nil }
        return FieldTelemetry(
            mapID: map.id,
            mapName: map.displayName,
            playerPosition: gameplayState.playerPosition,
            facing: gameplayState.facing,
            activeScriptID: gameplayState.activeScriptID,
            activeScriptStep: gameplayState.activeScriptStep,
            renderMode: currentFieldRenderMode
        )
    }

    func makeDialogueTelemetry() -> DialogueTelemetry? {
        guard let dialogueState, let dialogue = content.dialogue(id: dialogueState.dialogueID) else { return nil }
        let page = dialogue.pages[dialogueState.pageIndex]
        return DialogueTelemetry(dialogueID: dialogue.id, pageIndex: dialogueState.pageIndex, pageCount: dialogue.pages.count, lines: page.lines)
    }

    func makeStarterChoiceTelemetry() -> StarterChoiceTelemetry? {
        guard scene == .starterChoice else { return nil }
        return StarterChoiceTelemetry(options: starterChoiceOptions.map(\.displayName), focusedIndex: starterChoiceFocusedIndex)
    }

    func makePartyTelemetry() -> PartyTelemetry? {
        guard let gameplayState else { return nil }
        return PartyTelemetry(pokemon: gameplayState.playerParty.map { makePartyPokemonTelemetry(from: $0) })
    }

    func makeBattleTelemetry() -> BattleTelemetry? {
        guard let battle = gameplayState?.battle else { return nil }
        return BattleTelemetry(
            battleID: battle.battleID,
            trainerName: battle.trainerName,
            playerPokemon: makePartyPokemonTelemetry(from: battle.playerPokemon),
            enemyPokemon: makePartyPokemonTelemetry(from: battle.enemyPokemon),
            focusedMoveIndex: battle.focusedMoveIndex,
            battleMessage: battle.message
        )
    }

    func makeFlagTelemetry() -> EventFlagTelemetry? {
        guard let gameplayState else { return nil }
        return EventFlagTelemetry(activeFlags: gameplayState.activeFlags.sorted())
    }

    func makePartyPokemonTelemetry(from pokemon: RuntimePokemonState) -> PartyPokemonTelemetry {
        PartyPokemonTelemetry(
            speciesID: pokemon.speciesID,
            displayName: pokemon.nickname,
            level: pokemon.level,
            currentHP: pokemon.currentHP,
            maxHP: pokemon.maxHP,
            moves: pokemon.moves.map(\.id)
        )
    }
}
