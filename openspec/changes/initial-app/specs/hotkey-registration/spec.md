# Spec Delta

## Purpose

Registers and manages global keyboard shortcuts so each named window set can be activated from anywhere in macOS.

## ADDED Requirements

### Requirement: Global hotkey registration
The system SHALL register a global keyboard shortcut for each window set defined in the configuration.

#### Scenario: Hotkeys registered on launch
- **WHEN** the application launches with a valid configuration containing sets with hotkeys
- **THEN** each set's hotkey is registered as a system-wide shortcut

#### Scenario: Hotkey triggered
- **WHEN** the user presses a registered hotkey from any application
- **THEN** the system activates the corresponding window set

### Requirement: Hotkey format
The system SHALL accept hotkey strings in the format `modifier+modifier+key` where modifiers are `ctrl`, `cmd`, `option`, `shift` and key is an alphanumeric character or number.

#### Scenario: Multi-modifier hotkey
- **WHEN** the config specifies `hotkey: ctrl+cmd+1`
- **THEN** the system registers a shortcut requiring both Control and Command modifiers plus the 1 key

#### Scenario: Invalid hotkey string
- **WHEN** the config specifies a hotkey with an unrecognized modifier or key
- **THEN** the system skips that set, logs a warning, and continues registering other sets

### Requirement: Hotkey re-registration on config change
The system SHALL unregister all existing hotkeys and re-register them when the configuration is reloaded.

#### Scenario: Config reloaded with different hotkeys
- **WHEN** the user changes a set's hotkey in the config file and the file is reloaded
- **THEN** the old hotkey stops working and the new hotkey activates the set

#### Scenario: Set removed from config
- **WHEN** the user removes a set from the config file and the file is reloaded
- **THEN** the removed set's hotkey is unregistered

### Requirement: Duplicate hotkey detection
The system SHALL reject configurations where two sets share the same hotkey.

#### Scenario: Two sets with identical hotkeys
- **WHEN** the config defines two sets with the same hotkey string
- **THEN** the system logs an error naming both sets, skips both, and registers the remaining valid sets
