import AppKit
import SwiftUI

@main
struct AwesomeWindowsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var coordinator: AppCoordinator = {
        let c = AppCoordinator()
        c.start()
        return c
    }()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(coordinator: coordinator)
        } label: {
            if let name = coordinator.activeSetName,
               let config = coordinator.configManager.config,
               let index = config.sets.firstIndex(where: { $0.name == name }) {
                Text("\(index + 1)")
            } else {
                Image(systemName: "rectangle.3.group")
            }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
