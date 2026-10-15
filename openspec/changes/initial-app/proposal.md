# Proposal

## Why

There is no lightweight macOS tool that lets you define named sets of applications and instantly raise all windows in a set to the foreground with a single keyboard shortcut. Existing window managers focus on tiling and layout; this tool focuses on context switching — moving between logical groups of apps (coding, communication, design) without manually cmd-tabbing through each one.

## What Changes

- Create a new macOS menu bar application (Swift/SwiftUI) with no dock icon
- Register global keyboard shortcuts that each activate a named window set
- When a set is activated, raise all windows belonging to the set's apps to the foreground; leave all other windows untouched
- Read window set definitions from a YAML config file at `~/.awesome-windows/config.yaml`
- Watch the config file for changes and reload automatically
- Prompt for Accessibility permission on first launch (required for window manipulation)

## Capabilities

### New Capabilities

- `config-loading`: Parse and validate a YAML configuration file defining named window sets, each with a hotkey and a list of app bundle IDs. Watch the file for changes and reload automatically.
- `hotkey-registration`: Register and unregister global keyboard shortcuts based on the loaded configuration. Handle modifier+key combinations (e.g., `ctrl+cmd+1`).
- `window-activation`: When a hotkey fires, find all running applications matching the set's bundle IDs and raise their windows to the foreground.
- `menu-bar-ui`: Minimal menu bar interface showing the currently active set, a reload-config action, and quit.

### Modified Capabilities

_(none — greenfield project)_

## Impact

- **New Xcode project**: Swift package or Xcode project targeting macOS 14+
- **System permissions**: Requires Accessibility access (AXUIElement API)
- **Dependencies**: A YAML parsing library (e.g., Yams) and Carbon framework for global hotkey registration
- **No server, no network, no user accounts** — purely local
