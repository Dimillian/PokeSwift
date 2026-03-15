import AppKit
import PokeCore
import PokeDataModel

@MainActor
final class RuntimeKeyInputBridge {
    private var keyMonitor: Any?
    private var pressedDirectionalButtons: [UInt16: RuntimeButton] = [:]

    func install(runtimeProvider: @escaping @MainActor () -> GameRuntime?) {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
            guard let self else { return event }
            if self.shouldAllowTextInput(for: event) {
                self.releaseAllDirectionalButtons(runtimeProvider: runtimeProvider)
                return event
            }
            guard let runtime = runtimeProvider() else { return event }

            switch event.type {
            case .keyDown:
                if !event.isARepeat, let typeChar = runtime.namingCharacterHandler {
                    if event.keyCode == 36 {
                        runtime.handle(button: .start)
                        return nil
                    }
                    if let chars = event.charactersIgnoringModifiers,
                       chars.count == 1,
                       let char = chars.first,
                       char.isLetter || char == " " {
                        typeChar(char)
                        return nil
                    }
                }

                guard let button = RuntimeButton(keyEvent: event, scene: runtime.scene) else {
                    return event
                }

                if runtime.scene == .field, button.isDirectional {
                    if event.isARepeat {
                        return nil
                    }
                    pressedDirectionalButtons[event.keyCode] = button
                    runtime.setDirectionalButton(button, isPressed: true)
                    return nil
                }

                runtime.handle(button: button)
                return nil
            case .keyUp:
                if let button = pressedDirectionalButtons.removeValue(forKey: event.keyCode) {
                    runtime.setDirectionalButton(button, isPressed: false)
                    return nil
                }
                return event
            default:
                return event
            }
        }
    }

    func remove() {
        pressedDirectionalButtons.removeAll()
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
    }

    private func shouldAllowTextInput(for event: NSEvent) -> Bool {
        guard let responder = (event.window ?? NSApp.keyWindow)?.firstResponder as? NSTextView else {
            return false
        }

        return responder.isEditable
    }

    private func releaseAllDirectionalButtons(runtimeProvider: @escaping @MainActor () -> GameRuntime?) {
        guard pressedDirectionalButtons.isEmpty == false else { return }
        guard let runtime = runtimeProvider() else {
            pressedDirectionalButtons.removeAll()
            return
        }

        for button in pressedDirectionalButtons.values {
            runtime.setDirectionalButton(button, isPressed: false)
        }
        pressedDirectionalButtons.removeAll()
    }
}

private extension RuntimeButton {
    init?(keyEvent: NSEvent, scene: RuntimeScene) {
        switch keyEvent.keyCode {
        case 126: self = .up
        case 125: self = .down
        case 123: self = .left
        case 124: self = .right
        case 36:
            self = scene == .titleAttract ? .start : .confirm
        case 49:
            self = .start
        case 53, 51:
            self = .cancel
        default:
            guard let first = keyEvent.charactersIgnoringModifiers?.lowercased().first else {
                return nil
            }
            switch first {
            case "z": self = .confirm
            case "x": self = .cancel
            case "s": self = .start
            case "d": return nil
            default: return nil
            }
        }
    }

    var isDirectional: Bool {
        switch self {
        case .up, .down, .left, .right:
            return true
        case .confirm, .cancel, .start:
            return false
        }
    }
}
