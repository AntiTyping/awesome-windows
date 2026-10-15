import CoreGraphics
import Foundation

struct HotkeyBinding: Equatable {
    let modifiers: Set<String>
    let key: String

    init?(from string: String) {
        let parts = string.lowercased().split(separator: "+").map(String.init)
        guard parts.count >= 2 else { return nil }

        let validModifiers: Set<String> = ["ctrl", "cmd", "option", "shift"]
        let mods = Set(parts.dropLast())
        let keyPart = parts.last!

        guard mods.isSubset(of: validModifiers) else { return nil }
        guard keyPart.count == 1, keyPart.first!.isLetter || keyPart.first!.isNumber else { return nil }

        self.modifiers = mods
        self.key = keyPart
    }
}

struct AppTarget {
    let bundleID: String
    let titleFilter: String?
}

struct TrackedWindow: Equatable {
    let windowID: CGWindowID
    let bundleID: String
    let displayName: String
}

struct WindowSet {
    let name: String
    let hotkey: HotkeyBinding
    let apps: [AppTarget]
}

struct AppConfig {
    let sets: [WindowSet]
    let addHotkey: HotkeyBinding?

    struct ParseError: Error, CustomStringConvertible {
        let description: String
    }
}
