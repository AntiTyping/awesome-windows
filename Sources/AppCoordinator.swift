import Combine
import Foundation

final class AppCoordinator: ObservableObject {
    let configManager: ConfigManager
    let hotkeyManager: HotkeyManager
    let windowManager: WindowManager
    let toast = ToastWindow()

    @Published var activeSetName: String?
    @Published var trackedWindows: [String: [TrackedWindow]] = [:]

    var activeTrackedWindows: [TrackedWindow] {
        guard let name = activeSetName else { return [] }
        return trackedWindows[name] ?? []
    }

    private var cancellables = Set<AnyCancellable>()

    init() {
        self.configManager = ConfigManager()
        self.hotkeyManager = HotkeyManager()
        self.windowManager = WindowManager()

        configManager.$config
            .compactMap { $0 }
            .sink { [weak self] config in
                self?.registerHotkeys(for: config)
            }
            .store(in: &cancellables)
    }

    func start() {
        configManager.load()
    }

    private func registerHotkeys(for config: AppConfig) {
        hotkeyManager.registerSets(config.sets) { [weak self] set in
            self?.activateSet(set)
        }

        if let addHotkey = config.addHotkey {
            hotkeyManager.registerHotkey(addHotkey) { [weak self] in
                self?.toggleFrontmostWindowInActiveSet()
            }
        }
    }

    private func activateSet(_ set: WindowSet) {
        let tracked = trackedWindows[set.name] ?? []
        windowManager.activateSet(set, trackedWindows: tracked)
        activeSetName = set.name
        print("[AwesomeWindows] Activated set: \(set.name)")
    }

    private func toggleFrontmostWindowInActiveSet() {
        guard let setName = activeSetName else {
            toast.show("No active set")
            return
        }

        guard let window = windowManager.getFrontmostTrackedWindow() else {
            toast.show("Could not detect window")
            return
        }

        var windows = trackedWindows[setName] ?? []

        if let idx = windows.firstIndex(where: { $0.windowID == window.windowID }) {
            windows.remove(at: idx)
            trackedWindows[setName] = windows
            toast.show("Removed \(window.displayName) from \(setName)")
        } else {
            windows.append(window)
            trackedWindows[setName] = windows
            toast.show("Added \(window.displayName) to \(setName)")
        }
    }
}
