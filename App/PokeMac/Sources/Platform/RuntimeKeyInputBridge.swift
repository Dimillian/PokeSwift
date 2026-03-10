import AppKit
import PokeCore
import PokeDataModel

@MainActor
final class RuntimeKeyInputBridge {
    private var keyMonitor: Any?
    private var repeatingDirectionalTask: Task<Void, Never>?
    private var repeatingDirectionalKeyCode: UInt16?

    func install(runtimeProvider: @escaping @MainActor () -> GameRuntime?) {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
            guard let self else { return event }
            guard let runtime = runtimeProvider() else { return event }

            switch event.type {
            case .keyDown:
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
            while Task.isCancelled == false {
                guard let self else { return }
                let pollInterval = await MainActor.run { () -> TimeInterval in
                    guard self.repeatingDirectionalKeyCode == keyCode,
                          let runtime = runtimeProvider(),
                          runtime.scene == .field else {
                        self.stopDirectionalRepeat()
                        return 0
                    }

                    if runtime.canAcceptFieldDirectionalInput {
                        runtime.handle(button: button)
                    }
                    return max(1.0 / 240.0, runtime.fieldAnimationStepDuration / 8.0)
                }
                guard pollInterval > 0 else { return }
                try? await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
            }
        }
    }

    private func stopDirectionalRepeat() {
        repeatingDirectionalTask?.cancel()
        repeatingDirectionalTask = nil
        repeatingDirectionalKeyCode = nil
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
