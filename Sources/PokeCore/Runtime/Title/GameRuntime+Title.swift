import Foundation
import PokeDataModel

extension GameRuntime {
    static let titleFrameDurationNanoseconds: UInt64 = 16_666_667
    static let titleIntroHoldFrameCount = 36
    static let titleLoopHoldFrameCount = 200

    func handleTitleMenu(button: RuntimeButton) {
        switch button {
        case .up:
            focusedIndex = (focusedIndex - 1 + menuEntries.count) % menuEntries.count
            substate = "title_menu"
        case .down:
            focusedIndex = (focusedIndex + 1) % menuEntries.count
            substate = "title_menu"
        case .confirm, .start:
            playUIConfirmSound()
            let selected = menuEntries[focusedIndex]
            guard selected.isEnabled else {
                substate = "continue_disabled"
                return
            }
            switch selected.id {
            case "newGame":
                beginNewGame()
            case "continue":
                if continueFromTitleMenu() == false {
                    substate = "continue_disabled"
                } else {
                    endTitlePresentation()
                }
            case "options":
                endTitlePresentation(resetState: false)
                optionsFocusedRow = 0
                scene = .titleOptions
                substate = "title_options"
            default:
                endTitlePresentation(resetState: false)
                placeholderTitle = selected.label
                substate = selected.id
                scene = .placeholder
            }
        case .cancel:
            playUIConfirmSound()
            scene = .titleAttract
            substate = "attract"
            requestTitleMusic()
            beginTitlePresentation(reset: false)
        case .left, .right:
            break
        }
    }

    func handleTitleOptions(button: RuntimeButton) {
        let rowCount = 4 // textSpeed, battleAnimation, battleStyle, cancel
        switch button {
        case .up:
            optionsFocusedRow = (optionsFocusedRow - 1 + rowCount) % rowCount
            substate = "title_options"
        case .down:
            optionsFocusedRow = (optionsFocusedRow + 1) % rowCount
            substate = "title_options"
        case .left:
            cycleOption(delta: -1)
        case .right:
            cycleOption(delta: 1)
        case .confirm:
            if optionsFocusedRow == 3 {
                playUIConfirmSound()
                scene = .titleMenu
                substate = "title_menu"
                beginTitlePresentation(reset: false)
            }
        case .cancel:
            playUIConfirmSound()
            scene = .titleMenu
            substate = "title_menu"
            beginTitlePresentation(reset: false)
        case .start:
            break
        }
    }

    private func cycleOption(delta: Int) {
        switch optionsFocusedRow {
        case 0:
            if let next = stepped(among: TextSpeed.allCases, from: optionsTextSpeed, by: delta) {
                optionsTextSpeed = next
            }
        case 1:
            optionsBattleAnimation = toggled(among: BattleAnimation.allCases, from: optionsBattleAnimation)
        case 2:
            optionsBattleStyle = toggled(among: BattleStyle.allCases, from: optionsBattleStyle)
        default:
            break
        }
    }

    private func stepped<T: Equatable>(among options: [T], from current: T, by delta: Int) -> T? {
        guard let idx = options.firstIndex(of: current) else { return nil }
        let next = idx + delta
        guard options.indices.contains(next) else { return nil }
        return options[next]
    }

    private func toggled<T: Equatable>(among options: [T], from current: T) -> T {
        guard let idx = options.firstIndex(of: current) else { return current }
        return options[(idx + 1) % options.count]
    }

    func beginNewGame() {
        endTitlePresentation()
        deferredActions.removeAll()
        battlePresentationTask?.cancel()
        battlePresentationTask = nil
        fieldInteractionTask?.cancel()
        fieldInteractionTask = nil
        fieldTransitionTask?.cancel()
        trainerEngagementTask?.cancel()
        trainerEngagementTask = nil
        scriptedMovementTask?.cancel()
        fieldTransitionState = nil
        fieldAlertState = nil
        gameplayState = makeInitialGameplayState()
        playthroughID = UUID().uuidString
        reseedRuntimeRNG()
        clearFieldObstacleOverrides()
        clearTransientInteractionState()
        fieldHealingState = nil
        placeholderTitle = nil
        starterChoiceFocusedIndex = 0
        beginOakIntro()
    }

    func scheduleTitleFlow() {
        transitionTask?.cancel()
        let timings = content.titleManifest.timings
        let launchSeconds = validationMode ? 0.05 : max(0.1, timings.launchFadeSeconds)
        let splashSeconds = validationMode ? 0.10 : max(0.1, timings.splashDurationSeconds)

        transitionTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(launchSeconds * 1_000_000_000))
            guard Task.isCancelled == false else { return }
            await MainActor.run {
                guard let self else { return }
                self.scene = .splash
                self.substate = "splash"
                self.publishSnapshot()
            }

            try? await Task.sleep(nanoseconds: UInt64(splashSeconds * 1_000_000_000))
            guard Task.isCancelled == false else { return }
            await MainActor.run {
                guard let self else { return }
                self.scene = .titleAttract
                self.substate = "attract"
                self.requestTitleMusic()
                self.beginTitlePresentation(reset: true)
                self.publishSnapshot()
            }
        }
    }

    func beginTitlePresentation(reset: Bool) {
        if reset || titlePresentationState == nil {
            titlePresentationState = makeInitialTitlePresentationState()
        }

        guard titlePresentationTask == nil else { return }
        titlePresentationTask = Task { [weak self] in
            while Task.isCancelled == false {
                try? await Task.sleep(nanoseconds: Self.titleFrameDurationNanoseconds)
                guard Task.isCancelled == false else { break }
                let shouldContinue = await MainActor.run { [weak self] in
                    guard let self else { return false }
                    self.advanceTitlePresentationFrame()
                    return true
                }
                guard shouldContinue else { break }
            }
        }
    }

    func endTitlePresentation(resetState: Bool = true) {
        titlePresentationTask?.cancel()
        titlePresentationTask = nil
        if resetState {
            titlePresentationState = nil
        }
    }

    func resetTitlePresentationState() {
        titlePresentationState = makeInitialTitlePresentationState()
    }

    func advanceTitlePresentationFrame() {
        guard scene == .titleAttract || scene == .titleMenu else {
            endTitlePresentation(resetState: false)
            return
        }
        guard var state = titlePresentationState else { return }
        let manifest = content.titleManifest

        switch state.phase {
        case .introLogoBounce:
            guard manifest.logoBounceSequence.isEmpty == false else {
                state.phase = .idle
                state.idleFramesRemaining = Self.titleIntroHoldFrameCount
                break
            }

            let step = manifest.logoBounceSequence[state.logoStepIndex]
            state.logoYOffset += step.yDelta
            state.logoFramesRemaining -= 1
            if state.logoFramesRemaining <= 0 {
                let nextIndex = state.logoStepIndex + 1
                if manifest.logoBounceSequence.indices.contains(nextIndex) {
                    state.logoStepIndex = nextIndex
                    state.logoFramesRemaining = manifest.logoBounceSequence[nextIndex].frames
                } else {
                    state.phase = .idle
                    state.idleFramesRemaining = Self.titleIntroHoldFrameCount
                }
            }
        case .idle:
            if state.idleFramesRemaining > 0 {
                state.idleFramesRemaining -= 1
                break
            }
            beginTitleMonScrollOut(using: &state)
        case .monScrollOut:
            advanceTitleScroll(sequence: manifest.titleMonScrollOutSequence, state: &state, direction: .out)
        case .monScrollIn:
            advanceTitleScroll(sequence: manifest.titleMonScrollInSequence, state: &state, direction: .in)
        }

        titlePresentationState = state
    }

    private func makeInitialTitlePresentationState() -> RuntimeTitlePresentationState {
        let manifest = content.titleManifest
        let initialPhase: RuntimeTitleAnimationPhase = manifest.logoBounceSequence.isEmpty ? .idle : .introLogoBounce
        let initialLogoFrames = manifest.logoBounceSequence.first?.frames ?? 0
        return RuntimeTitlePresentationState(
            currentSpeciesID: manifest.titleMonSpecies,
            previousSpeciesID: nil,
            phase: initialPhase,
            logoYOffset: 0,
            monOffsetX: 0,
            logoStepIndex: 0,
            logoFramesRemaining: initialLogoFrames,
            idleFramesRemaining: initialPhase == .idle ? Self.titleIntroHoldFrameCount : 0,
            scrollStepIndex: 0,
            scrollFramesRemaining: 0,
            pendingSpeciesID: nil
        )
    }

    private func beginTitleMonScrollOut(using state: inout RuntimeTitlePresentationState) {
        let sequence = content.titleManifest.titleMonScrollOutSequence
        guard sequence.isEmpty == false else {
            swapToNextTitleSpecies(using: &state)
            return
        }

        state.pendingSpeciesID = nextTitleSpecies(excluding: state.currentSpeciesID)
        state.phase = .monScrollOut
        state.scrollStepIndex = 0
        state.scrollFramesRemaining = sequence[0].frames
    }

    private func swapToNextTitleSpecies(using state: inout RuntimeTitlePresentationState) {
        let nextSpeciesID = state.pendingSpeciesID ?? nextTitleSpecies(excluding: state.currentSpeciesID)
        state.previousSpeciesID = state.currentSpeciesID
        state.currentSpeciesID = nextSpeciesID
        state.pendingSpeciesID = nil

        let sequence = content.titleManifest.titleMonScrollInSequence
        if sequence.isEmpty {
            state.phase = .idle
            state.idleFramesRemaining = Self.titleLoopHoldFrameCount
            state.monOffsetX = 0
            return
        }

        state.phase = .monScrollIn
        state.monOffsetX = titleScrollDistance(for: sequence)
        state.scrollStepIndex = 0
        state.scrollFramesRemaining = sequence[0].frames
    }

    private enum TitleScrollDirection {
        case `in`
        case out
    }

    private func advanceTitleScroll(
        sequence: [TitleScrollStep],
        state: inout RuntimeTitlePresentationState,
        direction: TitleScrollDirection
    ) {
        guard sequence.isEmpty == false else {
            if direction == .out {
                swapToNextTitleSpecies(using: &state)
            } else {
                state.phase = .idle
                state.idleFramesRemaining = Self.titleLoopHoldFrameCount
            }
            return
        }

        let step = sequence[state.scrollStepIndex]
        switch direction {
        case .in:
            state.monOffsetX = max(0, state.monOffsetX - step.speed)
        case .out:
            state.monOffsetX -= step.speed
        }

        state.scrollFramesRemaining -= 1
        if state.scrollFramesRemaining > 0 {
            return
        }

        let nextIndex = state.scrollStepIndex + 1
        if sequence.indices.contains(nextIndex) {
            state.scrollStepIndex = nextIndex
            state.scrollFramesRemaining = sequence[nextIndex].frames
            return
        }

        switch direction {
        case .out:
            swapToNextTitleSpecies(using: &state)
        case .in:
            state.monOffsetX = 0
            state.phase = .idle
            state.idleFramesRemaining = Self.titleLoopHoldFrameCount
        }
    }

    private func titleScrollDistance(for sequence: [TitleScrollStep]) -> Int {
        sequence.reduce(into: 0) { partial, step in
            partial += step.speed * step.frames
        }
    }

    private func nextTitleSpecies(excluding currentSpeciesID: String) -> String {
        let pool = content.titleManifest.titleMonSpeciesPool
        guard pool.isEmpty == false else { return currentSpeciesID }
        guard pool.count > 1 else { return pool[0] }

        var candidate = currentSpeciesID
        var attempts = 0
        while candidate == currentSpeciesID && attempts < 16 {
            candidate = pool[nextRuntimeRandomByte() % pool.count]
            attempts += 1
        }
        return candidate == currentSpeciesID ? pool.first { $0 != currentSpeciesID } ?? currentSpeciesID : candidate
    }
}
