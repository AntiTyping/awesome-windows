import AppKit
import ApplicationServices
import Foundation

@_silgen_name("_AXUIElementGetWindow")
func _AXUIElementGetWindow(_ element: AXUIElement, _ windowID: inout CGWindowID) -> AXError

@_silgen_name("CGSMainConnectionID")
func CGSMainConnectionID() -> Int32

@_silgen_name("CGSOrderWindow")
func CGSOrderWindow(_ cid: Int32, _ wid: CGWindowID, _ mode: Int32, _ relativeToWID: CGWindowID) -> CGError

private let kCGSOrderAbove: Int32 = 1

func awlog(_ msg: String) {
    let ts = ISO8601DateFormatter().string(from: Date())
    let line = "[\(ts)] \(msg)\n"
    let path = NSHomeDirectory() + "/.awesome-windows/debug.log"
    if let fh = FileHandle(forWritingAtPath: path) {
        fh.seekToEndOfFile()
        fh.write(line.data(using: .utf8)!)
        fh.closeFile()
    } else {
        FileManager.default.createFile(atPath: path, contents: line.data(using: .utf8))
    }
}

final class WindowManager: ObservableObject {
    @Published private(set) var isAccessibilityGranted: Bool = false
    private let cgsConnection: Int32

    init() {
        cgsConnection = CGSMainConnectionID()
        checkAccessibility()
    }

    func activateSet(_ set: WindowSet, trackedWindows: [TrackedWindow]) {
        awlog("activateSet '\(set.name)' tracked=\(trackedWindows.map { "wid=\($0.windowID) \($0.displayName)" })")
        let runningApps = NSWorkspace.shared.runningApplications

        var appBundleIDs = Set<String>()
        for target in set.apps { appBundleIDs.insert(target.bundleID) }
        for tracked in trackedWindows { appBundleIDs.insert(tracked.bundleID) }

        for (i, bundleID) in appBundleIDs.enumerated() {
            guard let app = runningApps.first(where: { $0.bundleIdentifier == bundleID }) else {
                awlog("  app not running: \(bundleID)")
                continue
            }

            let configTargets = set.apps.filter { $0.bundleID == bundleID }
            let trackedForApp = trackedWindows.filter { $0.bundleID == bundleID }

            let delay = Double(i) * 0.05
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                app.unhide()
                app.activate()

                let axApp = AXUIElementCreateApplication(app.processIdentifier)
                var windowsRef: CFTypeRef?
                guard AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsRef) == .success,
                      let windows = windowsRef as? [AXUIElement] else {
                    awlog("  could not list AX windows for \(bundleID)")
                    return
                }

                awlog("  \(bundleID): \(windows.count) AX windows")
                var lastRaised: AXUIElement? = nil

                for window in windows {
                    var wid: CGWindowID = 0
                    _ = _AXUIElementGetWindow(window, &wid)

                    if trackedForApp.contains(where: { $0.windowID == wid }) {
                        let r = AXUIElementPerformAction(window, kAXRaiseAction as CFString)
                        awlog("  AXRaise wid=\(wid) result=\(r.rawValue)")
                        lastRaised = window
                    }
                }

                for target in configTargets {
                    guard let titleFilter = target.titleFilter else { continue }
                    for window in windows {
                        var titleRef: CFTypeRef?
                        guard AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef) == .success,
                              let title = titleRef as? String else { continue }
                        if title.localizedCaseInsensitiveContains(titleFilter) {
                            AXUIElementPerformAction(window, kAXRaiseAction as CFString)
                            lastRaised = window
                            break
                        }
                    }
                }

                if let window = lastRaised {
                    AXUIElementSetAttributeValue(axApp, kAXFocusedWindowAttribute as CFString, window)
                    AXUIElementSetAttributeValue(window, kAXMainAttribute as CFString, kCFBooleanTrue)
                    awlog("  set focused/main window for \(bundleID)")
                }
            }
        }
    }

    func getFrontmostTrackedWindow() -> TrackedWindow? {
        guard var frontApp = NSWorkspace.shared.frontmostApplication,
              var bundleID = frontApp.bundleIdentifier else {
            awlog("No frontmost app")
            return nil
        }

        if bundleID == "com.artcraft.awesome-windows" {
            awlog("Frontmost is ourselves, finding previous app")
            if let topWindow = topWindowFromWindowServer(excludingPID: frontApp.processIdentifier) {
                if let app = NSWorkspace.shared.runningApplications.first(where: { $0.processIdentifier == topWindow.pid }),
                   let bid = app.bundleIdentifier {
                    frontApp = app
                    bundleID = bid
                }
            }
        }

        let pid = frontApp.processIdentifier
        awlog("Frontmost app: \(bundleID) pid=\(pid)")

        var windowID: CGWindowID = 0
        var displayName = bundleID.split(separator: ".").last.map(String.init) ?? bundleID

        // Try AX first for focused window
        let axApp = AXUIElementCreateApplication(pid)
        var focusedWindowRef: CFTypeRef?
        let axResult = AXUIElementCopyAttributeValue(axApp, kAXFocusedWindowAttribute as CFString, &focusedWindowRef)

        if axResult == .success {
            let axWindow = focusedWindowRef as! AXUIElement
            var wid: CGWindowID = 0
            let widResult = _AXUIElementGetWindow(axWindow, &wid)
            if widResult == .success && wid != 0 {
                windowID = wid
                awlog("Got window ID from AX: \(windowID)")
            }

            var titleRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(axWindow, kAXTitleAttribute as CFString, &titleRef) == .success,
               let title = titleRef as? String,
               !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                displayName = title
            }
        } else {
            awlog("AX focused window failed: \(axResult.rawValue)")
            if axResult.rawValue == -25211 {
                ensureAccessibility()
            }
        }

        // Fall back to CGWindowList — returns windows in z-order, first match is frontmost
        if windowID == 0 {
            if let fallback = frontmostWindowFromWindowServer(pid: pid) {
                windowID = fallback.id
                if !fallback.name.isEmpty { displayName = fallback.name }
                awlog("Got window ID from CGWindowList fallback: \(windowID)")
            }
        }

        guard windowID != 0 else {
            awlog("Could not get window ID for \(bundleID)")
            return nil
        }

        // Try to get a better name from CGWindowList
        if let name = windowNameFromWindowServer(pid: pid, windowID: windowID) {
            displayName = name
        }

        // Append window ID to display name so user can distinguish same-name windows
        let finalName = "\(displayName) [\(windowID)]"
        awlog("Detected: \(bundleID) wid=\(windowID) name=\(finalName)")
        return TrackedWindow(windowID: windowID, bundleID: bundleID, displayName: finalName)
    }

    private func topWindowFromWindowServer(excludingPID: pid_t) -> (pid: pid_t, id: CGWindowID, name: String)? {
        guard let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }
        for info in windowList {
            guard let ownerPID = info[kCGWindowOwnerPID as String] as? pid_t,
                  ownerPID != excludingPID,
                  let layer = info[kCGWindowLayer as String] as? Int,
                  layer == 0,
                  let wid = info[kCGWindowNumber as String] as? CGWindowID else {
                continue
            }
            let name = info[kCGWindowName as String] as? String ?? ""
            return (pid: ownerPID, id: wid, name: name)
        }
        return nil
    }

    private func frontmostWindowFromWindowServer(pid: pid_t) -> (id: CGWindowID, name: String)? {
        guard let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }
        for info in windowList {
            guard let ownerPID = info[kCGWindowOwnerPID as String] as? pid_t,
                  ownerPID == pid,
                  let layer = info[kCGWindowLayer as String] as? Int,
                  layer == 0,
                  let wid = info[kCGWindowNumber as String] as? CGWindowID else {
                continue
            }
            let name = info[kCGWindowName as String] as? String ?? ""
            return (id: wid, name: name)
        }
        return nil
    }

    private func windowNameFromWindowServer(pid: pid_t, windowID: CGWindowID) -> String? {
        guard let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }
        for info in windowList {
            guard let wid = info[kCGWindowNumber as String] as? CGWindowID, wid == windowID,
                  let ownerPID = info[kCGWindowOwnerPID as String] as? pid_t, ownerPID == pid else {
                continue
            }
            if let name = info[kCGWindowName as String] as? String,
               !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return name
            }
        }
        return nil
    }

    func checkAccessibility() {
        isAccessibilityGranted = AXIsProcessTrusted()
        awlog("AXIsProcessTrusted: \(isAccessibilityGranted)")
    }

    func promptForAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
        checkAccessibility()
    }

    func ensureAccessibility() {
        let trusted = AXIsProcessTrusted()
        if !trusted {
            awlog("Accessibility NOT trusted, prompting")
            promptForAccessibility()
        }
    }
}
