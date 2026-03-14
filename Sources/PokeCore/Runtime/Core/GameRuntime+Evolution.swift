import Foundation
import PokeDataModel

extension GameRuntime {
    private static let evolutionSwapDurations: [Duration] = [
        .milliseconds(820),
        .milliseconds(720),
        .milliseconds(640),
        .milliseconds(560),
        .milliseconds(490),
        .milliseconds(430),
        .milliseconds(370),
        .milliseconds(320),
        .milliseconds(270),
        .milliseconds(225),
        .milliseconds(185),
        .milliseconds(150),
        .milliseconds(120),
        .milliseconds(95),
        .milliseconds(75),
        .milliseconds(55),
    ]

    func beginPendingEvolutionIfNeeded(
        from battle: RuntimeBattleState,
        finalizedParty: [RuntimePokemonState],
        continuation: RuntimeEvolutionContinuation
    ) -> Bool {
        guard let pendingEvolution = battle.pendingEvolution,
              finalizedParty.indices.contains(pendingEvolution.partyIndex) else {
            return false
        }

        let originalPokemon = finalizedParty[pendingEvolution.partyIndex]
        guard originalPokemon.speciesID == pendingEvolution.originalSpeciesID,
              let evolvedPokemon = makeEvolvedPokemon(
                  from: originalPokemon,
                  targetSpeciesID: pendingEvolution.targetSpeciesID
              ) else {
            return false
        }

        evolutionTask?.cancel()
        evolutionTask = nil
        evolutionState = RuntimeEvolutionState(
            partyIndex: pendingEvolution.partyIndex,
            originalPokemon: originalPokemon,
            evolvedPokemon: evolvedPokemon,
            phase: .intro,
            continuation: continuation,
            resumeAudioState: currentAudioState
        )
        scene = .evolution
        substate = "evolution_intro"
        startEvolutionIntroAudio(for: originalPokemon)
        publishSnapshot()
        return true
    }

    func handleEvolution(button: RuntimeButton) {
        guard button == .confirm || button == .start || button == .cancel,
              var evolutionState else {
            return
        }

        switch evolutionState.phase {
        case .intro:
            playUIConfirmSound()
            evolutionState.phase = .animating
            evolutionState.animationStep = 0
            evolutionState.showsEvolvedSprite = false
            self.evolutionState = evolutionState
            substate = "evolution_animating"
            startEvolutionAnimation()
            publishSnapshot()
        case .animating:
            return
        case .evolved:
            playUIConfirmSound()
            evolutionState.phase = .into
            self.evolutionState = evolutionState
            substate = "evolution_into"
            playEvolutionDialogueEventsIfNeeded(for: evolutionState)
            publishSnapshot()
        case .into:
            playUIConfirmSound()
            finishEvolutionSequence(evolutionState)
        }
    }

    func currentEvolutionDialogueID() -> String? {
        guard let evolutionState else { return nil }
        return evolutionDialogueID(for: evolutionState.phase)
    }

    func currentEvolutionDialogueLines() -> [String] {
        guard let evolutionState,
              let dialogueID = evolutionDialogueID(for: evolutionState.phase),
              let page = content.dialogue(id: dialogueID)?.pages.first else {
            return []
        }
        return resolvedDialogueLines(page.lines, replacements: evolutionDialogueReplacements(for: evolutionState))
    }

    private func startEvolutionAnimation() {
        evolutionTask?.cancel()
        evolutionTask = Task { [weak self] in
            guard let self, Task.isCancelled == false else { return }
            for (index, duration) in Self.evolutionSwapDurations.enumerated() {
                try? await Task.sleep(for: duration)
                guard Task.isCancelled == false else { return }
                self.advanceEvolutionAnimation(step: index + 1)
            }
            self.completeEvolutionAnimation()
        }
    }

    private func advanceEvolutionAnimation(step: Int) {
        guard var evolutionState, evolutionState.phase == .animating else {
            return
        }

        evolutionState.animationStep = step
        evolutionState.showsEvolvedSprite.toggle()
        self.evolutionState = evolutionState
        publishSnapshot()
    }

    private func completeEvolutionAnimation() {
        evolutionTask = nil
        guard var evolutionState,
              evolutionState.phase == .animating,
              var gameplayState,
              gameplayState.playerParty.indices.contains(evolutionState.partyIndex) else {
            return
        }

        gameplayState.playerParty[evolutionState.partyIndex] = evolutionState.evolvedPokemon
        recordOwnedSpecies(evolutionState.evolvedPokemon.speciesID, in: &gameplayState)
        self.gameplayState = gameplayState

        evolutionState.phase = .evolved
        evolutionState.animationStep = Self.evolutionSwapDurations.count
        evolutionState.showsEvolvedSprite = true
        self.evolutionState = evolutionState
        substate = "evolution_evolved"

        playEvolutionCompletionAudio(for: evolutionState)
        publishSnapshot()
    }

    private func finishEvolutionSequence(_ evolutionState: RuntimeEvolutionState) {
        evolutionTask?.cancel()
        evolutionTask = nil
        self.evolutionState = nil

        switch evolutionState.continuation {
        case let .trainerBattle(battle, won):
            completeFinishedTrainerBattle(battle: battle, won: won)
        case let .wildBattle(battle, won):
            completeFinishedWildBattle(battle: battle, won: won)
        }
    }

    private func makeEvolvedPokemon(
        from pokemon: RuntimePokemonState,
        targetSpeciesID: String
    ) -> RuntimePokemonState? {
        guard let targetSpecies = content.species(id: targetSpeciesID) else {
            return nil
        }

        let resolvedNickname = evolvedNickname(from: pokemon, targetSpecies: targetSpecies)

        var evolvedPokemon = makeConfiguredPokemon(
            speciesID: targetSpeciesID,
            nickname: resolvedNickname,
            level: pokemon.level,
            experience: pokemon.experience,
            dvs: pokemon.dvs,
            statExp: pokemon.statExp,
            currentHP: nil,
            attackStage: pokemon.attackStage,
            defenseStage: pokemon.defenseStage,
            speedStage: pokemon.speedStage,
            specialStage: pokemon.specialStage,
            accuracyStage: pokemon.accuracyStage,
            evasionStage: pokemon.evasionStage,
            majorStatus: pokemon.majorStatus,
            statusCounter: pokemon.statusCounter,
            isBadlyPoisoned: pokemon.isBadlyPoisoned,
            moves: pokemon.moves
        )
        let gainedMaxHP = evolvedPokemon.maxHP - pokemon.maxHP
        evolvedPokemon.currentHP = min(
            evolvedPokemon.maxHP,
            max(0, pokemon.currentHP + gainedMaxHP)
        )
        evolvedPokemon.battleEffects = pokemon.battleEffects
        return evolvedPokemon
    }

    private func evolvedNickname(
        from pokemon: RuntimePokemonState,
        targetSpecies: SpeciesManifest
    ) -> String {
        guard let originalSpecies = content.species(id: pokemon.speciesID) else {
            return pokemon.nickname
        }

        let defaultNames = Set([
            originalSpecies.displayName,
            pokemon.speciesID.capitalized,
            pokemon.speciesID,
        ].map { $0.lowercased() })

        return defaultNames.contains(pokemon.nickname.lowercased())
            ? targetSpecies.displayName
            : pokemon.nickname
    }

    private func startEvolutionIntroAudio(for pokemon: RuntimePokemonState) {
        guard let request = speciesCrySoundEffectRequest(speciesID: pokemon.speciesID) else {
            requestAudioCue(id: "evolution", reason: "evolution")
            return
        }

        _ = playSoundEffect(request, reason: "evolution.originalCry") { [weak self] in
            guard let self else { return }
            self.requestAudioCue(id: "evolution", reason: "evolution")
            self.publishSnapshot()
        }
    }

    private func playEvolutionCompletionAudio(for evolutionState: RuntimeEvolutionState) {
        let restoreMusic: () -> Void = { [weak self] in
            guard let self, let resumeAudioState = evolutionState.resumeAudioState else { return }
            self.restoreAudioState(resumeAudioState, reason: "evolution.resume")
            self.publishSnapshot()
        }

        guard let cryRequest = speciesCrySoundEffectRequest(speciesID: evolutionState.evolvedPokemon.speciesID) else {
            restoreMusic()
            return
        }

        _ = playSoundEffect(cryRequest, reason: "evolution.evolvedCry", completion: restoreMusic)
    }

    private func evolutionDialogueID(for phase: RuntimeEvolutionPhase) -> String? {
        switch phase {
        case .intro:
            return "evolution_is_evolving"
        case .animating:
            return nil
        case .evolved:
            return "evolution_evolved"
        case .into:
            return "evolution_into"
        }
    }

    private func evolutionDialogueReplacements(for evolutionState: RuntimeEvolutionState) -> [String: String] {
        [
            "pokemon": evolutionState.originalPokemon.nickname,
            "evolvedPokemon": content.species(id: evolutionState.evolvedPokemon.speciesID)?.displayName
                ?? evolutionState.evolvedPokemon.speciesID.capitalized,
        ]
    }

    private func playEvolutionDialogueEventsIfNeeded(for evolutionState: RuntimeEvolutionState) {
        guard let dialogueID = evolutionDialogueID(for: evolutionState.phase),
              let page = content.dialogue(id: dialogueID)?.pages.first else {
            return
        }

        for event in page.events {
            switch event.kind {
            case .soundEffect:
                if let soundEffectID = event.soundEffectID {
                    _ = playSoundEffect(id: soundEffectID, reason: "evolution.dialogue")
                }
            case .cry:
                if let speciesID = event.speciesID,
                   let request = speciesCrySoundEffectRequest(speciesID: speciesID) {
                    _ = playSoundEffect(request, reason: "evolution.dialogue")
                }
            }
        }
    }
}
