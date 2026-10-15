import AppKit
import ApplicationServices
import Foundation

final class WindowManager: ObservableObject {
    @Published private(set) var isAccessibilityGranted: Bool = false

    init() {
        checkAccessibility()
    }

    func activateSet(_ set: WindowSet) {
        let runningApps = NSWorkspace.shared.runningApplications

        for (i, target) in set.apps.reversed().enumerated() {
            guard let app = runningApps.first(where: { $0.bundleIdentifier == target.bundleID }) else {
                continue
            }

            let delay = Double(i) * 0.05
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                app.unhide()

                if let titleFilter = target.titleFilter {
                    self.raiseWindowByTitle(app: app, titleFilter: titleFilter)
                } else {
                    app.activate()
                }
            }
        }
    }

    private func raiseWindowByTitle(app: NSRunningApplication, titleFilter: String) {
        let axApp = AXUIElementCreateApplication(app.processIdentifier)

        var windowsRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsRef) == .success,
              let windows = windowsRef as? [AXUIElement] else {
            app.activate()
            return
        }

        var matched = false
        for window in windows {
            var titleRef: CFTypeRef?
            guard AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef) == .success,
                  let title = titleRef as? String else {
                continue
            }

            if title.localizedCaseInsensitiveContains(titleFilter) {
                AXUIElementPerformAction(window, kAXRaiseAction as CFString)
                app.activate()
                matched = true
                break
            }
        }

        if !matched {
            print("[AwesomeWindows] No window matching '\(titleFilter)' in \(app.bundleIdentifier ?? "unknown")")
            app.activate()
        }
    }

    func checkAccessibility() {
        isAccessibilityGranted = AXIsProcessTrusted()
    }

    func promptForAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
        checkAccessibility()
    }
}
