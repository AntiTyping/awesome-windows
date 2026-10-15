import Testing
@testable import AwesomeWindows

@Suite("ConfigParser")
struct ConfigParserTests {
    @Test("parses valid config with string app entries")
    func parseValidConfig() throws {
        let yaml = """
        sets:
          coding:
            hotkey: ctrl+cmd+1
            apps:
              - com.apple.Terminal
              - com.microsoft.VSCode
          comms:
            hotkey: ctrl+cmd+2
            apps:
              - com.tinyspeck.slackmacgap
        """

        let config = try ConfigParser.parse(yaml: yaml)
        #expect(config.sets.count == 2)

        let coding = config.sets.first(where: { $0.name == "coding" })!
        #expect(coding.apps.count == 2)
        #expect(coding.apps[0].bundleID == "com.apple.Terminal")
        #expect(coding.apps[0].titleFilter == nil)
        #expect(coding.apps[1].bundleID == "com.microsoft.VSCode")
        #expect(coding.hotkey.modifiers == ["ctrl", "cmd"])
        #expect(coding.hotkey.key == "1")
    }

    @Test("parses dict app entries with title filter")
    func parseDictAppEntries() throws {
        let yaml = """
        sets:
          coding:
            hotkey: ctrl+cmd+1
            apps:
              - com.googlecode.iterm2
              - id: com.google.Chrome.canary
                title: "GitHub"
        """

        let config = try ConfigParser.parse(yaml: yaml)
        #expect(config.sets.count == 1)

        let set = config.sets[0]
        #expect(set.apps.count == 2)
        #expect(set.apps[0].bundleID == "com.googlecode.iterm2")
        #expect(set.apps[0].titleFilter == nil)
        #expect(set.apps[1].bundleID == "com.google.Chrome.canary")
        #expect(set.apps[1].titleFilter == "GitHub")
    }

    @Test("rejects config with no sets key")
    func rejectNoSetsKey() throws {
        let yaml = "foo: bar"
        #expect(throws: AppConfig.ParseError.self) {
            try ConfigParser.parse(yaml: yaml)
        }
    }

    @Test("rejects malformed YAML")
    func rejectMalformedYAML() throws {
        let yaml = "sets:\n  - [invalid"
        #expect(throws: (any Error).self) {
            try ConfigParser.parse(yaml: yaml)
        }
    }

    @Test("skips set with missing hotkey")
    func skipMissingHotkey() throws {
        let yaml = """
        sets:
          nohotkey:
            apps:
              - com.apple.Terminal
          valid:
            hotkey: ctrl+cmd+1
            apps:
              - com.apple.Safari
        """

        let config = try ConfigParser.parse(yaml: yaml)
        #expect(config.sets.count == 1)
        #expect(config.sets[0].name == "valid")
    }

    @Test("allows set with no apps key (empty workspace)")
    func allowEmptyApps() throws {
        let yaml = """
        sets:
          empty:
            hotkey: ctrl+cmd+1
          withapps:
            hotkey: ctrl+cmd+2
            apps:
              - com.apple.Safari
        """

        let config = try ConfigParser.parse(yaml: yaml)
        #expect(config.sets.count == 2)
        let empty = config.sets.first(where: { $0.name == "empty" })!
        #expect(empty.apps.isEmpty)
    }

    @Test("allows set with empty apps array")
    func allowEmptyAppsArray() throws {
        let yaml = """
        sets:
          workspace:
            hotkey: ctrl+cmd+1
            apps: []
        """

        let config = try ConfigParser.parse(yaml: yaml)
        #expect(config.sets.count == 1)
        #expect(config.sets[0].apps.isEmpty)
    }

    @Test("skips sets with duplicate hotkeys")
    func skipDuplicateHotkeys() throws {
        let yaml = """
        sets:
          first:
            hotkey: ctrl+cmd+1
            apps:
              - com.apple.Terminal
          second:
            hotkey: ctrl+cmd+1
            apps:
              - com.apple.Safari
          third:
            hotkey: ctrl+cmd+2
            apps:
              - com.apple.mail
        """

        let config = try ConfigParser.parse(yaml: yaml)
        #expect(config.sets.count == 1)
        #expect(config.sets[0].name == "third")
    }

    @Test("skips set with invalid hotkey string")
    func skipInvalidHotkey() throws {
        let yaml = """
        sets:
          bad:
            hotkey: superkey+1
            apps:
              - com.apple.Terminal
          good:
            hotkey: ctrl+cmd+2
            apps:
              - com.apple.Safari
        """

        let config = try ConfigParser.parse(yaml: yaml)
        #expect(config.sets.count == 1)
        #expect(config.sets[0].name == "good")
    }
}

@Suite("HotkeyBinding")
struct HotkeyBindingTests {
    @Test("parses ctrl+cmd+1")
    func parseCtrlCmd1() {
        let binding = HotkeyBinding(from: "ctrl+cmd+1")
        #expect(binding != nil)
        #expect(binding!.modifiers == ["ctrl", "cmd"])
        #expect(binding!.key == "1")
    }

    @Test("parses single modifier")
    func parseSingleModifier() {
        let binding = HotkeyBinding(from: "cmd+a")
        #expect(binding != nil)
        #expect(binding!.modifiers == ["cmd"])
        #expect(binding!.key == "a")
    }

    @Test("rejects key-only string")
    func rejectKeyOnly() {
        let binding = HotkeyBinding(from: "a")
        #expect(binding == nil)
    }

    @Test("rejects unknown modifier")
    func rejectUnknownModifier() {
        let binding = HotkeyBinding(from: "super+1")
        #expect(binding == nil)
    }

    @Test("is case insensitive")
    func caseInsensitive() {
        let binding = HotkeyBinding(from: "Ctrl+CMD+A")
        #expect(binding != nil)
        #expect(binding!.modifiers == ["ctrl", "cmd"])
        #expect(binding!.key == "a")
    }
}
