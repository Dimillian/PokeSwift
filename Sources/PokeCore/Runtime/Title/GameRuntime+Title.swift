import Foundation
import PokeDataModel

extension GameRuntime {
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
                }
            case "options":
                optionsFocusedRow = 0
                scene = .titleOptions
                substate = "title_options"
            default:
                placeholderTitle = selected.label
                substate = selected.id
                scene = .placeholder
            }
        case .cancel:
            playUIConfirmSound()
            scene = .titleAttract
            substate = "attract"
            requestTitleMusic()
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
            cycleOptionLeft()
        case .right:
            cycleOptionRight()
        case .confirm:
            if optionsFocusedRow == 3 {
                playUIConfirmSound()
                scene = .titleMenu
                substate = "title_menu"
            }
        case .cancel:
            playUIConfirmSound()
            scene = .titleMenu
            substate = "title_menu"
        case .start:
            break
        }
    }

    private func cycleOptionLeft() {
        switch optionsFocusedRow {
        case 0:
            let options = TextSpeed.allOptions
            if let idx = options.firstIndex(of: optionsTextSpeed), idx > 0 {
                optionsTextSpeed = options[idx - 1]
            }
        case 1:
            let options = BattleAnimation.allOptions
            if let idx = options.firstIndex(of: optionsBattleAnimation), idx > 0 {
                optionsBattleAnimation = options[idx - 1]
            }
        case 2:
            let options = BattleStyle.allOptions
            if let idx = options.firstIndex(of: optionsBattleStyle), idx > 0 {
                optionsBattleStyle = options[idx - 1]
            }
        default:
            break
        }
    }

    private func cycleOptionRight() {
        switch optionsFocusedRow {
        case 0:
            let options = TextSpeed.allOptions
            if let idx = options.firstIndex(of: optionsTextSpeed), idx < options.count - 1 {
                optionsTextSpeed = options[idx + 1]
            }
        case 1:
            let options = BattleAnimation.allOptions
            if let idx = options.firstIndex(of: optionsBattleAnimation), idx < options.count - 1 {
                optionsBattleAnimation = options[idx + 1]
            }
        case 2:
            let options = BattleStyle.allOptions
            if let idx = options.firstIndex(of: optionsBattleStyle), idx < options.count - 1 {
                optionsBattleStyle = options[idx + 1]
            }
        default:
            break
        }
    }

    func beginNewGame() {
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
        dialogueState = nil
        fieldPromptState = nil
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
                self.publishSnapshot()
            }
        }
    }
}
