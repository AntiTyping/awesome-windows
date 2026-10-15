# Spec Delta

## Purpose

Provides a minimal menu bar interface for status display and basic controls, with no dock icon.

## ADDED Requirements

### Requirement: Menu bar presence
The system SHALL run as a menu bar-only application with no Dock icon.

#### Scenario: App launched
- **WHEN** the application is running
- **THEN** a status icon appears in the macOS menu bar and no icon appears in the Dock

### Requirement: Active set display
The system SHALL display the name of the most recently activated window set in the menu bar dropdown.

#### Scenario: Set activated
- **WHEN** the user triggers a window set via hotkey
- **THEN** the menu bar dropdown shows the name of that set as the active set

#### Scenario: No set activated yet
- **WHEN** the application launches and no set has been triggered
- **THEN** the menu bar dropdown shows no active set

### Requirement: Menu bar actions
The system SHALL provide Reload Config and Quit actions in the menu bar dropdown.

#### Scenario: Reload config action
- **WHEN** the user selects "Reload Config" from the menu bar dropdown
- **THEN** the configuration file is re-read and applied

#### Scenario: Quit action
- **WHEN** the user selects "Quit" from the menu bar dropdown
- **THEN** the application unregisters all hotkeys and exits

### Requirement: Error and warning display
The system SHALL display configuration errors and accessibility permission status in the menu bar dropdown.

#### Scenario: Config error present
- **WHEN** the configuration file has a parse error or validation warning
- **THEN** the menu bar dropdown shows the error message

#### Scenario: Accessibility not granted
- **WHEN** the application does not have Accessibility permission
- **THEN** the menu bar dropdown shows a warning with a link to System Settings
