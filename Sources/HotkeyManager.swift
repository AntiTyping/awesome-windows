import Carbon
import Foundation

final class HotkeyManager {
    private var registeredHotkeys: [(id: UInt32, ref: EventHotKeyRef)] = []
    private var hotkeyActions: [UInt32: () -> Void] = [:]
    private var nextId: UInt32 = 1
    private var eventHandler: EventHandlerRef?

    init() {
        installEventHandler()
    }

    func registerSets(_ sets: [WindowSet], action: @escaping (WindowSet) -> Void) {
        unregisterAll()

        for set in sets {
            let id = nextId
            nextId += 1

            let hotKeyID = EventHotKeyID(signature: OSType(0x4157_494E), id: id) // "AWIN"
            let modifiers = carbonModifiers(from: set.hotkey.modifiers)
            let keyCode = carbonKeyCode(from: set.hotkey.key)

            guard keyCode != UInt32.max else {
                print("[AwesomeWindows] Unknown key '\(set.hotkey.key)' for set '\(set.name)', skipping")
                continue
            }

            var hotKeyRef: EventHotKeyRef?
            let status = RegisterEventHotKey(
                keyCode,
                modifiers,
                hotKeyID,
                GetApplicationEventTarget(),
                0,
                &hotKeyRef
            )

            if status == noErr, let ref = hotKeyRef {
                registeredHotkeys.append((id: id, ref: ref))
                hotkeyActions[id] = { action(set) }
                print("[AwesomeWindows] Registered hotkey for '\(set.name)'")
            } else {
                print("[AwesomeWindows] Failed to register hotkey for '\(set.name)': \(status)")
            }
        }
    }

    func registerHotkey(_ binding: HotkeyBinding, action: @escaping () -> Void) {
        let id = nextId
        nextId += 1

        let hotKeyID = EventHotKeyID(signature: OSType(0x4157_494E), id: id)
        let modifiers = carbonModifiers(from: binding.modifiers)
        let keyCode = carbonKeyCode(from: binding.key)

        guard keyCode != UInt32.max else {
            print("[AwesomeWindows] Unknown key '\(binding.key)' for extra hotkey, skipping")
            return
        }

        var hotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status == noErr, let ref = hotKeyRef {
            registeredHotkeys.append((id: id, ref: ref))
            hotkeyActions[id] = action
            print("[AwesomeWindows] Registered add-to-set hotkey")
        } else {
            print("[AwesomeWindows] Failed to register add-to-set hotkey: \(status)")
        }
    }

    func unregisterAll() {
        for entry in registeredHotkeys {
            UnregisterEventHotKey(entry.ref)
        }
        registeredHotkeys.removeAll()
        hotkeyActions.removeAll()
        print("[AwesomeWindows] Unregistered all hotkeys")
    }

    private func installEventHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let handler: EventHandlerUPP = { _, event, userData -> OSStatus in
            guard let event else { return OSStatus(eventNotHandledErr) }
            let manager = Unmanaged<HotkeyManager>.fromOpaque(userData!).takeUnretainedValue()

            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )

            guard status == noErr else { return status }

            if let action = manager.hotkeyActions[hotKeyID.id] {
                DispatchQueue.main.async { action() }
            }

            return noErr
        }

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            handler,
            1,
            &eventType,
            selfPtr,
            &eventHandler
        )
    }

    private func carbonModifiers(from modifiers: Set<String>) -> UInt32 {
        var result: UInt32 = 0
        for mod in modifiers {
            switch mod {
            case "cmd": result |= UInt32(cmdKey)
            case "ctrl": result |= UInt32(controlKey)
            case "option": result |= UInt32(optionKey)
            case "shift": result |= UInt32(shiftKey)
            default: break
            }
        }
        return result
    }

    private func carbonKeyCode(from key: String) -> UInt32 {
        let keyMap: [String: UInt32] = [
            "a": 0x00, "s": 0x01, "d": 0x02, "f": 0x03, "h": 0x04,
            "g": 0x05, "z": 0x06, "x": 0x07, "c": 0x08, "v": 0x09,
            "b": 0x0B, "q": 0x0C, "w": 0x0D, "e": 0x0E, "r": 0x0F,
            "y": 0x10, "t": 0x11, "u": 0x20, "i": 0x22, "p": 0x23,
            "l": 0x25, "j": 0x26, "k": 0x28, "n": 0x2D, "m": 0x2E,
            "o": 0x1F,
            "1": 0x12, "2": 0x13, "3": 0x14, "4": 0x15, "5": 0x17,
            "6": 0x16, "7": 0x1A, "8": 0x1C, "9": 0x19, "0": 0x1D,
        ]
        return keyMap[key.lowercased()] ?? UInt32.max
    }

    deinit {
        unregisterAll()
        if let handler = eventHandler {
            RemoveEventHandler(handler)
        }
    }
}
