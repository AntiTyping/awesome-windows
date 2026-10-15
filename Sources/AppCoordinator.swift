import Combine
import Foundation

final class AppCoordinator: ObservableObject {
    let configManager: ConfigManager
    let hotkeyManager: HotkeyManager
    let windowManager: WindowManager

    @Published var activeSetName: String?

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
    }

    private func activateSet(_ set: WindowSet) {
        windowManager.activateSet(set)
        activeSetName = set.name
        print("[AwesomeWindows] Activated set: \(set.name)")
    }
}
