# Design

## Context

Greenfield macOS application. No existing code. See proposal.md for motivation.

macOS provides several APIs for window management, each with different capabilities and trade-offs. The key constraints are:
- Global hotkeys require either the deprecated-but-stable Carbon `RegisterEventHotKey` API or a `CGEvent` tap (which needs Accessibility permission)
- Raising app windows requires `NSRunningApplication.activate()` or AXUIElement calls
- Menu bar-only apps use `LSUIElement` (Info.plist) or `NSApp.setActivationPolicy(.accessory)`
- YAML parsing has no built-in support; requires a third-party library

## Goals / Non-Goals

**Goals:**
- Ship a single-binary menu bar app that activates window sets via global hotkeys
- Config-file-driven with auto-reload — no GUI for editing sets
- Work reliably on macOS 14+ (Sonoma and later)

**Non-Goals:**
- Window tiling, resizing, or layout management
- Launching apps that aren't running
- Per-window (as opposed to per-app) grouping
- GUI for defining or editing window sets
- Supporting macOS versions before 14

## Decisions

### Project structure: Swift Package Manager
Use a SwiftPM package (not an Xcode project file). The app target produces a macOS `.app` bundle. SwiftPM is simpler to version-control and avoids Xcode project merge conflicts.

**Alternative considered:** Xcode project — more GUI tooling support, but heavier to manage in git and unnecessary for a small app.

### YAML parsing: Yams
Use the [Yams](https://github.com/jpsim/Yams) Swift package for YAML parsing. It's the de facto standard Swift YAML library, well-maintained, and has no transitive dependencies.

**Alternative considered:** JSON config — no dependency needed, but YAML is more readable for the kind of configuration this app uses (nested keys, lists).

### Global hotkeys: Carbon RegisterEventHotKey
Use `RegisterEventHotKey` / `UnregisterEventHotKey` from the Carbon framework. Despite being legacy API, it is the most reliable way to register global shortcuts on macOS. It does not require Accessibility permission (unlike `CGEvent` taps), which simplifies the permission model — Accessibility is needed only for window queries, not hotkey capture.

**Alternative considered:** `CGEvent` tap — more modern, but requires Accessibility permission just to listen for keys, and failure modes are harder to diagnose. `NSEvent.addGlobalMonitorForEvents` — cannot intercept or consume the event, so the shortcut would also fire in the frontmost app.

### Window activation: NSRunningApplication.activate
Use `NSWorkspace.shared.runningApplications` to find apps by bundle ID, then call `activate(options: .activateIgnoringOtherApps)` on each match. Activate in reverse order so the first app in the set's list ends up frontmost.

**Alternative considered:** AXUIElement `AXRaise` per-window — gives per-window control but adds complexity and requires Accessibility permission for the raise itself. `NSRunningApplication.activate()` is sufficient for the "raise all windows of this app" behavior and only needs Accessibility for the initial window enumeration check.

### Config file watching: DispatchSource.makeFileSystemObjectSource
Use GCD's file-system source to watch `~/.awesome-windows/config.yaml` for writes. Falls back to polling if the file descriptor cannot be opened (e.g., file deleted). Debounce reloads by 500ms to avoid parsing mid-save.

**Alternative considered:** FSEvents — more powerful (directory-level watching), but heavier API for watching a single file. Polling — simpler but introduces latency.

### App lifecycle: LSUIElement
Set `LSUIElement = true` in Info.plist to suppress the Dock icon. Use SwiftUI `MenuBarExtra` (macOS 13+) for the menu bar interface.

## Risks / Trade-offs

- **Carbon API deprecation** → `RegisterEventHotKey` has been "deprecated" since macOS 10.14 but still works on macOS 15. If Apple removes it, the fallback is `CGEvent` tap, which would require Accessibility permission for hotkey listening too. Monitor WWDC announcements.
- **Accessibility permission UX** → macOS requires the user to manually toggle Accessibility in System Settings. The app cannot grant it programmatically. First-launch experience will include a prompt. Mitigation: clear instructions in the menu bar dropdown and an "Open System Settings" action.
- **Bundle ID discovery** → Users need to know bundle IDs for their apps, which aren't obvious. Mitigation: document how to find them (`osascript -e 'id of app "AppName"'` or `mdls -name kMDItemCFBundleIdentifier /path/to/App.app`). A future improvement could add a "copy bundle ID of frontmost app" menu bar action.
