# Spec Delta

## Purpose

Finds running applications matching a window set's bundle IDs and raises their windows to the foreground.

## ADDED Requirements

### Requirement: Raise matching applications
The system SHALL activate (bring to foreground) every running application whose bundle ID appears in the triggered set's app list.

#### Scenario: All apps in set are running
- **WHEN** a set containing bundle IDs for Terminal and VS Code is triggered and both apps are running
- **THEN** both applications' windows are raised to the foreground

#### Scenario: Some apps in set are not running
- **WHEN** a set is triggered and some of its listed apps are not running
- **THEN** the running apps are raised and the non-running apps are silently ignored

#### Scenario: No apps in set are running
- **WHEN** a set is triggered and none of its listed apps are running
- **THEN** no action is taken and no error is displayed

### Requirement: Leave other windows untouched
The system SHALL NOT hide, minimize, or reorder windows belonging to applications outside the triggered set.

#### Scenario: Other apps remain visible
- **WHEN** a set is triggered while other apps have visible windows
- **THEN** those other windows remain in their current position and visibility state, behind the raised set

### Requirement: Accessibility permission
The system SHALL require macOS Accessibility permission to manipulate windows.

#### Scenario: Accessibility not granted
- **WHEN** the application launches without Accessibility permission
- **THEN** the system prompts the user to grant Accessibility access in System Settings and displays its status in the menu bar

#### Scenario: Accessibility granted
- **WHEN** the application has Accessibility permission
- **THEN** window activation works without further prompts
