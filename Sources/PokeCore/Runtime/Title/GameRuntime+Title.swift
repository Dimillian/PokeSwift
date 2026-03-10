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
            let selected = menuEntries[focusedIndex]
            guard selected.enabled else {
                substate = "continue_disabled"
                return
            }
            switch selected.id {
            case "newGame":
                beginNewGame()
            default:
                placeholderTitle = selected.label
                substate = selected.id
                scene = .placeholder
            }
        case .cancel:
            scene = .titleAttract
            substate = "attract"
        case .left, .right:
            break
        }
    }

    func beginNewGame() {
        deferredActions.removeAll()
        gameplayState = makeInitialGameplayState()
        dialogueState = nil
        placeholderTitle = nil
        starterChoiceFocusedIndex = 0
        scene = .field
        substate = "field"
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
                self.publishSnapshot()
            }
        }
    }
}
