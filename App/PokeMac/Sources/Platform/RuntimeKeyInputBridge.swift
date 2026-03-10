import AppKit
import PokeCore
import PokeDataModel

@MainActor
final class RuntimeKeyInputBridge {
    private var keyMonitor: Any?

    func install(runtimeProvider: @escaping @MainActor () -> GameRuntime?) {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard let runtime = runtimeProvider() else { return event }
            guard let button = RuntimeButton(keyEvent: event, scene: runtime.scene) else {
                return event
            }
            runtime.handle(button: button)
            return nil
        }
    }

    func remove() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
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
}
