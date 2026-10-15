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

    func addAppToSet(setName: String, bundleID: String, windowTitle: String?) {
        guard FileManager.default.fileExists(atPath: configPath) else { return }

        do {
            var contents = try String(contentsOfFile: configPath, encoding: .utf8)
            var lines = contents.components(separatedBy: "\n")

            guard let setLineIndex = lines.firstIndex(where: {
                $0.trimmingCharacters(in: .whitespaces).hasPrefix("\(setName):")
            }) else {
                print("[AwesomeWindows] Set '\(setName)' not found in config file")
                return
            }

            var appsLineIndex: Int? = nil
            for i in (setLineIndex + 1)..<lines.count {
                let trimmed = lines[i].trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("apps:") {
                    appsLineIndex = i
                    break
                }
                if !trimmed.isEmpty && !trimmed.hasPrefix("-") && !trimmed.hasPrefix("hotkey:") {
                    break
                }
            }

            guard let appsIdx = appsLineIndex else {
                print("[AwesomeWindows] Could not find 'apps:' under set '\(setName)'")
                return
            }

            let appsLine = lines[appsIdx]
            let appsIndent = String(appsLine.prefix(while: { $0 == " " }))
            let entryIndent = appsIndent + "  "

            if appsLine.trimmingCharacters(in: .whitespaces) == "apps: []" {
                lines[appsIdx] = "\(appsIndent)apps:"
            }

            var insertAfter = appsIdx
            for i in (appsIdx + 1)..<lines.count {
                let line = lines[i]
                if line.trimmingCharacters(in: .whitespaces).isEmpty {
                    continue
                }
                let lineIndent = line.prefix(while: { $0 == " " }).count
                if lineIndent >= entryIndent.count {
                    insertAfter = i
                } else {
                    break
                }
            }

            var newLines: [String] = []
            if let title = windowTitle, !title.isEmpty {
                newLines.append("\(entryIndent)- id: \(bundleID)")
                newLines.append("\(entryIndent)  title: \"\(title)\"")
            } else {
                newLines.append("\(entryIndent)- \(bundleID)")
            }

            lines.insert(contentsOf: newLines, at: insertAfter + 1)
            contents = lines.joined(separator: "\n")
            try contents.write(toFile: configPath, atomically: true, encoding: .utf8)
            print("[AwesomeWindows] Added \(bundleID) to set '\(setName)'")
        } catch {
            print("[AwesomeWindows] Failed to update config: \(error)")
        }
    }

    func removeAppFromSet(setName: String, bundleID: String, windowTitle: String?) {
        guard FileManager.default.fileExists(atPath: configPath) else { return }

        do {
            var contents = try String(contentsOfFile: configPath, encoding: .utf8)
            var lines = contents.components(separatedBy: "\n")

            guard let setLineIndex = lines.firstIndex(where: {
                $0.trimmingCharacters(in: .whitespaces).hasPrefix("\(setName):")
            }) else {
                print("[AwesomeWindows] Set '\(setName)' not found in config file")
                return
            }

            var appsLineIndex: Int? = nil
            for i in (setLineIndex + 1)..<lines.count {
                let trimmed = lines[i].trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("apps:") {
                    appsLineIndex = i
                    break
                }
                if !trimmed.isEmpty && !trimmed.hasPrefix("-") && !trimmed.hasPrefix("hotkey:") {
                    break
                }
            }

            guard let appsIdx = appsLineIndex else { return }

            let appsLine = lines[appsIdx]
            let appsIndent = String(appsLine.prefix(while: { $0 == " " }))
            let entryIndent = appsIndent + "  "

            var i = appsIdx + 1
            while i < lines.count {
                let line = lines[i]
                if line.trimmingCharacters(in: .whitespaces).isEmpty {
                    i += 1
                    continue
                }
                let lineIndent = line.prefix(while: { $0 == " " }).count
                if lineIndent < entryIndent.count { break }

                let trimmed = line.trimmingCharacters(in: .whitespaces)

                if trimmed == "- \(bundleID)" && windowTitle == nil {
                    lines.remove(at: i)
                    collapseIfEmpty(&lines, appsIdx: appsIdx, entryIndent: entryIndent)
                    contents = lines.joined(separator: "\n")
                    try contents.write(toFile: configPath, atomically: true, encoding: .utf8)
                    print("[AwesomeWindows] Removed \(bundleID) from set '\(setName)'")
                    return
                }

                if trimmed == "- id: \(bundleID)", let title = windowTitle {
                    if i + 1 < lines.count {
                        let nextTrimmed = lines[i + 1].trimmingCharacters(in: .whitespaces)
                        if nextTrimmed == "title: \"\(title)\"" {
                            lines.removeSubrange(i...(i + 1))
                            collapseIfEmpty(&lines, appsIdx: appsIdx, entryIndent: entryIndent)
                            contents = lines.joined(separator: "\n")
                            try contents.write(toFile: configPath, atomically: true, encoding: .utf8)
                            print("[AwesomeWindows] Removed \(bundleID) (\(title)) from set '\(setName)'")
                            return
                        }
                    }
                }

                i += 1
            }

            print("[AwesomeWindows] Entry not found for removal")
        } catch {
            print("[AwesomeWindows] Failed to update config: \(error)")
        }
    }

    private func collapseIfEmpty(_ lines: inout [String], appsIdx: Int, entryIndent: String) {
        let hasEntries = (appsIdx + 1 < lines.count) && lines[(appsIdx + 1)...].contains {
            let line = $0
            if line.trimmingCharacters(in: .whitespaces).isEmpty { return false }
            return line.prefix(while: { $0 == " " }).count >= entryIndent.count
        }
        if !hasEntries {
            let indent = String(lines[appsIdx].prefix(while: { $0 == " " }))
            lines[appsIdx] = "\(indent)apps: []"
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
