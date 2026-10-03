import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    let store = UsageStore()
    var poller: UsagePoller?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }
        let poller = UsagePoller(store: store)
        self.poller = poller
        poller.start()
    }
}

@main
struct UsageMeterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("UM", systemImage: "gauge.with.dots.needle.50percent") {
            DropdownView(
                store: appDelegate.store,
                onRefresh: { appDelegate.poller?.poll() },
                onQuit: { NSApplication.shared.terminate(nil) }
            )
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
        }
    }
}
