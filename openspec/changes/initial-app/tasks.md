# Tasks

## 1. Project Scaffold

- [x] 1.1 Create a SwiftPM package with an executable target for the macOS app. Add Yams as a dependency. Verify `swift build` succeeds with an empty main entry point.
- [x] 1.2 Configure Info.plist with `LSUIElement = true` and the app bundle identifier `com.artcraft.awesome-windows`. Verify the built app does not appear in the Dock when launched.

## 2. Configuration Loading

- [x] 2.1 Define the `WindowSet` and `AppConfig` model types (set name, hotkey string, list of bundle IDs). Implement YAML parsing from a file path using Yams, including validation (missing fields, duplicate hotkeys). Verify by writing a unit test that parses a valid config string and rejects an invalid one.
- [x] 2.2 Implement the `ConfigManager` that reads from `~/.awesome-windows/config.yaml`, creates the directory and a default config if missing, and exposes the parsed sets. Verify by launching the app with no config file and confirming the default file is created.
- [x] 2.3 Add file watching with `DispatchSource.makeFileSystemObjectSource` and 500ms debounce. Re-parse on change. Verify by editing the config file while the app is running and observing the reload in console logs.

## 3. Global Hotkey Registration

- [x] 3.1 Implement `HotkeyManager` that parses hotkey strings (e.g., `ctrl+cmd+1`) into Carbon modifier flags and key codes, and calls `RegisterEventHotKey` / `UnregisterEventHotKey`. Verify by registering a test hotkey and confirming the Carbon callback fires when the key combination is pressed.
- [x] 3.2 Wire `HotkeyManager` to `ConfigManager` so hotkeys are re-registered on every config reload. Verify by changing a hotkey in the config file and confirming the old one stops working and the new one fires.

## 4. Window Activation

- [x] 4.1 Implement `WindowManager.activateSet(_:)` that filters `NSWorkspace.shared.runningApplications` by bundle ID and calls `activate(options: .activateIgnoringOtherApps)` in reverse order. Verify by defining a set with Terminal and Safari, triggering it, and confirming both apps come to the foreground with the first-listed app on top.
- [x] 4.2 Add Accessibility permission checking with `AXIsProcessTrusted()`. Expose the permission status as a published property for the UI. Verify by running the app without Accessibility permission and confirming the status reports untrusted.

## 5. Menu Bar UI

- [x] 5.1 Create the SwiftUI `MenuBarExtra` with a system image icon. Display the active set name (or "No active set"), config errors, and Accessibility status. Verify the menu bar icon appears and the dropdown shows the correct state.
- [x] 5.2 Add "Reload Config" and "Quit" menu items. Wire "Reload Config" to `ConfigManager.reload()` and "Quit" to `NSApp.terminate`. Verify both actions work from the dropdown.

## 6. Integration

- [x] 6.1 Wire everything together in `App.swift`: `ConfigManager` → `HotkeyManager` → `WindowManager`, with the `MenuBarExtra` observing state. Verify the full flow: launch app, press a configured hotkey, confirm the correct apps are raised, edit the config, confirm the new hotkey works.
