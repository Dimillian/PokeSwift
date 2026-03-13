import AppKit
import PokeCore
import PokeDataModel

@MainActor
final class RuntimeKeyInputBridge {
    private static let directionalRepeatAvailabilityPollInterval: TimeInterval = 1.0 / 240.0

    private var keyMonitor: Any?
    private var repeatingDirectionalTask: Task<Void, Never>?
    private var repeatingDirectionalKeyCode: UInt16?

    func install(runtimeProvider: @escaping @MainActor () -> GameRuntime?) {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
            guard let self else { return event }
            if self.shouldAllowTextInput(for: event) {
                self.stopDirectionalRepeat()
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
                    startDirectionalRepeat(
                        keyCode: event.keyCode,
                        button: button,
                        runtimeProvider: runtimeProvider
                    )
                    runtime.handle(button: button)
                    return nil
                }

                runtime.handle(button: button)
                return nil
            case .keyUp:
                if repeatingDirectionalKeyCode == event.keyCode {
                    stopDirectionalRepeat()
                    return nil
                }
                return event
            default:
                return event
            }
        }
    }

    func remove() {
        stopDirectionalRepeat()
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
    }

    private func startDirectionalRepeat(
        keyCode: UInt16,
        button: RuntimeButton,
        runtimeProvider: @escaping @MainActor () -> GameRuntime?
    ) {
        stopDirectionalRepeat()
        repeatingDirectionalKeyCode = keyCode
        repeatingDirectionalTask = Task { [weak self] in
            guard let self else { return }

            let initialDelay = await MainActor.run { () -> TimeInterval in
                guard self.repeatingDirectionalKeyCode == keyCode,
                      let runtime = runtimeProvider(),
                      runtime.scene == .field else {
                    self.stopDirectionalRepeat()
                    return 0
                }

                return runtime.fieldAnimationStepDuration
            }
            guard initialDelay > 0 else { return }
            try? await Task.sleep(nanoseconds: Self.sleepNanoseconds(for: initialDelay))

            while Task.isCancelled == false {
                let nextDelay = await MainActor.run { () -> TimeInterval in
                    guard self.repeatingDirectionalKeyCode == keyCode,
                          let runtime = runtimeProvider(),
                          runtime.scene == .field else {
                        self.stopDirectionalRepeat()
                        return 0
                    }

                    guard runtime.canAcceptFieldDirectionalInput else {
                        return Self.directionalRepeatAvailabilityPollInterval
                    }

                    runtime.handle(button: button)
                    return runtime.fieldAnimationStepDuration
                }
                guard nextDelay > 0 else { return }
                try? await Task.sleep(nanoseconds: Self.sleepNanoseconds(for: nextDelay))
            }
        }
    }

    private func stopDirectionalRepeat() {
        repeatingDirectionalTask?.cancel()
        repeatingDirectionalTask = nil
        repeatingDirectionalKeyCode = nil
    }

    private static func sleepNanoseconds(for duration: TimeInterval) -> UInt64 {
        UInt64(max(0, duration) * 1_000_000_000)
    }

    private func shouldAllowTextInput(for event: NSEvent) -> Bool {
        guard let responder = (event.window ?? NSApp.keyWindow)?.firstResponder as? NSTextView else {
            return false
        }

        return responder.isEditable
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
