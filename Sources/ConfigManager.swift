import Foundation
import Combine

final class ConfigManager: ObservableObject {
    @Published private(set) var config: AppConfig?
    @Published private(set) var error: String?
    @Published private(set) var warnings: [String] = []

    private let configDir: String
    private let configPath: String
    private var fileWatcher: FileWatcher?

    init(configDir: String? = nil) {
        let dir = configDir ?? "\(NSHomeDirectory())/.awesome-windows"
        self.configDir = dir
        self.configPath = "\(dir)/config.yaml"
    }

    func load() {
        if !FileManager.default.fileExists(atPath: configPath) {
            createDefaultConfig()
        }
        reload()
        startWatching()
    }

    private func startWatching() {
        fileWatcher = FileWatcher(path: configPath) { [weak self] in
            print("[AwesomeWindows] Config file changed, reloading...")
            self?.reload()
        }
        fileWatcher?.start()
    }

    func reload() {
        do {
            let newConfig = try ConfigParser.parse(fileAt: configPath)
            config = newConfig
            error = nil
            print("[AwesomeWindows] Config loaded: \(newConfig.sets.count) sets")
        } catch let parseError as AppConfig.ParseError {
            if config == nil {
                self.error = parseError.description
            } else {
                self.error = "Config error (keeping previous): \(parseError.description)"
            }
            print("[AwesomeWindows] Config error: \(parseError.description)")
        } catch {
            if config == nil {
                self.error = "Failed to read config: \(error.localizedDescription)"
            } else {
                self.error = "Config error (keeping previous): \(error.localizedDescription)"
            }
            print("[AwesomeWindows] Config error: \(error.localizedDescription)")
        }
    }

    private func createDefaultConfig() {
        let fm = FileManager.default
        do {
            try fm.createDirectory(atPath: configDir, withIntermediateDirectories: true)
            try ConfigParser.defaultConfigYAML.write(
                toFile: configPath,
                atomically: true,
                encoding: .utf8
            )
            print("[AwesomeWindows] Created default config at \(configPath)")
        } catch {
            self.error = "Failed to create default config: \(error.localizedDescription)"
            print("[AwesomeWindows] Failed to create default config: \(error)")
        }
    }
}
