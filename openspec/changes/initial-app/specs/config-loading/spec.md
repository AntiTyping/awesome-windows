# Spec Delta

## Purpose

Loads and validates a YAML configuration file that defines named window sets, each mapping a keyboard shortcut to a list of application bundle IDs.

## ADDED Requirements

### Requirement: Config file location
The system SHALL read configuration from `~/.awesome-windows/config.yaml`.

#### Scenario: Config file exists
- **WHEN** the application launches and `~/.awesome-windows/config.yaml` exists
- **THEN** the system loads and parses the file

#### Scenario: Config file does not exist
- **WHEN** the application launches and `~/.awesome-windows/config.yaml` does not exist
- **THEN** the system creates the directory and a default config file with an example set

### Requirement: Config file structure
The system SHALL parse a YAML file with a top-level `sets` key containing named entries, each with a `hotkey` string and an `apps` list of bundle ID strings.

#### Scenario: Valid config
- **WHEN** the config file contains a valid `sets` mapping with at least one entry having `hotkey` and `apps` keys
- **THEN** the system loads all sets into memory

#### Scenario: Invalid YAML
- **WHEN** the config file contains malformed YAML
- **THEN** the system displays an error in the menu bar and retains the previous valid configuration if one was loaded

#### Scenario: Missing required fields
- **WHEN** a set entry is missing `hotkey` or `apps`
- **THEN** the system skips that entry and logs a warning

### Requirement: Config file watching
The system SHALL watch `~/.awesome-windows/config.yaml` for changes and reload automatically.

#### Scenario: Config file modified externally
- **WHEN** the config file is saved by an external editor while the app is running
- **THEN** the system reloads the configuration within 2 seconds without requiring a restart

#### Scenario: Config file deleted while running
- **WHEN** the config file is deleted while the app is running
- **THEN** the system retains the last valid configuration and displays a warning in the menu bar

### Requirement: Manual reload
The system SHALL provide a manual reload action accessible from the menu bar.

#### Scenario: User triggers reload
- **WHEN** the user selects "Reload Config" from the menu bar
- **THEN** the system re-reads and re-parses the config file immediately
