import Foundation
import Yams

enum ConfigParser {
    static func parse(yaml: String) throws -> AppConfig {
        guard let root = try Yams.load(yaml: yaml) as? [String: Any] else {
            throw AppConfig.ParseError(description: "Config must be a YAML mapping")
        }

        guard let setsDict = root["sets"] as? [String: Any] else {
            throw AppConfig.ParseError(description: "Config must contain a 'sets' key")
        }

        var hotkeySeen: [String: String] = [:]
        var duplicateHotkeys: Set<String> = []
        var sets: [WindowSet] = []
        var warnings: [String] = []

        for (name, value) in setsDict.sorted(by: { $0.key < $1.key }) {
            guard let entry = value as? [String: Any] else {
                warnings.append("Set '\(name)': expected a mapping, skipping")
                continue
            }

            guard let hotkeyStr = entry["hotkey"] as? String else {
                warnings.append("Set '\(name)': missing 'hotkey', skipping")
                continue
            }

            var appTargets: [AppTarget] = []
            if let rawApps = entry["apps"] as? [Any] {
                appTargets = parseAppTargets(rawApps, setName: name, warnings: &warnings)
            }

            guard let hotkey = HotkeyBinding(from: hotkeyStr) else {
                warnings.append("Set '\(name)': invalid hotkey '\(hotkeyStr)', skipping")
                continue
            }

            let normalizedHotkey = hotkeyStr.lowercased()
            if let existingName = hotkeySeen[normalizedHotkey] {
                duplicateHotkeys.insert(normalizedHotkey)
                warnings.append("Sets '\(existingName)' and '\(name)' share hotkey '\(hotkeyStr)', skipping both")
                continue
            }
            hotkeySeen[normalizedHotkey] = name

            sets.append(WindowSet(name: name, hotkey: hotkey, apps: appTargets))
        }

        let filteredSets = sets.filter { set in
            let originalNormalized = hotkeySeen.first(where: { $0.value == set.name })?.key ?? ""
            return !duplicateHotkeys.contains(originalNormalized)
        }

        for warning in warnings {
            print("[AwesomeWindows] Warning: \(warning)")
        }

        var addHotkey: HotkeyBinding? = nil
        if let addHotkeyStr = root["add_hotkey"] as? String {
            addHotkey = HotkeyBinding(from: addHotkeyStr)
            if addHotkey == nil {
                print("[AwesomeWindows] Warning: invalid add_hotkey '\(addHotkeyStr)', ignoring")
            }
        }

        return AppConfig(sets: filteredSets, addHotkey: addHotkey)
    }

    private static func parseAppTargets(_ rawApps: [Any], setName: String, warnings: inout [String]) -> [AppTarget] {
        var targets: [AppTarget] = []
        for item in rawApps {
            if let bundleID = item as? String {
                targets.append(AppTarget(bundleID: bundleID, titleFilter: nil))
            } else if let dict = item as? [String: Any], let bundleID = dict["id"] as? String {
                let title = dict["title"] as? String
                targets.append(AppTarget(bundleID: bundleID, titleFilter: title))
            } else {
                warnings.append("Set '\(setName)': invalid app entry, skipping")
            }
        }
        return targets
    }

    static func parse(fileAt path: String) throws -> AppConfig {
        let contents = try String(contentsOfFile: path, encoding: .utf8)
        return try parse(yaml: contents)
    }

    static var defaultConfigYAML: String {
        """
        add_hotkey: ctrl+cmd+a

        sets:
          1:
            hotkey: ctrl+cmd+1
            apps: []
          2:
            hotkey: ctrl+cmd+2
            apps: []
          3:
            hotkey: ctrl+cmd+3
            apps: []
          4:
            hotkey: ctrl+cmd+4
            apps: []
          5:
            hotkey: ctrl+cmd+5
            apps: []
          6:
            hotkey: ctrl+cmd+6
            apps: []
          7:
            hotkey: ctrl+cmd+7
            apps: []
          8:
            hotkey: ctrl+cmd+8
            apps: []
          9:
            hotkey: ctrl+cmd+9
            apps: []
        """
    }
}
