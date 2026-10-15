import SwiftUI

struct MenuBarView: View {
    @ObservedObject var coordinator: AppCoordinator

    var body: some View {
        if let name = coordinator.activeSetName {
            Text("Active: \(name)")
                .font(.headline)
        } else {
            Text("No active set")
                .foregroundStyle(.secondary)
        }

        Divider()

        if let error = coordinator.configManager.error {
            Label(error, systemImage: "exclamationmark.triangle")
                .foregroundStyle(.red)
            Divider()
        }

        if !coordinator.windowManager.isAccessibilityGranted {
            Button("Grant Accessibility Access...") {
                coordinator.windowManager.promptForAccessibility()
            }
            Label("Accessibility required", systemImage: "lock.shield")
                .foregroundStyle(.orange)
            Divider()
        }

        if let config = coordinator.configManager.config {
            Section("Sets") {
                ForEach(config.sets, id: \.name) { set in
                    Button("\(set.name) (\(hotkeyLabel(set.hotkey)))") {
                        coordinator.windowManager.activateSet(set)
                        coordinator.activeSetName = set.name
                    }
                }
            }
            Divider()
        }

        Button("Reload Config") {
            coordinator.configManager.reload()
        }
        .keyboardShortcut("r")

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    private func hotkeyLabel(_ binding: HotkeyBinding) -> String {
        let mods = binding.modifiers.sorted().map { mod in
            switch mod {
            case "cmd": return "⌘"
            case "ctrl": return "⌃"
            case "option": return "⌥"
            case "shift": return "⇧"
            default: return mod
            }
        }.joined()
        return "\(mods)\(binding.key.uppercased())"
    }
}
