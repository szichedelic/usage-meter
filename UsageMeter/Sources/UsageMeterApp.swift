import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var poller: UsagePoller?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Poller is started from the App struct after store is available
    }
}

@main
struct UsageMeterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var store = UsageStore()

    var body: some Scene {
        MenuBarExtra("UM", systemImage: "gauge.with.dots.needle.50percent") {
            DropdownView(
                store: store,
                onRefresh: { appDelegate.poller?.poll() },
                onQuit: { NSApplication.shared.terminate(nil) }
            )
            .onAppear {
                if appDelegate.poller == nil {
                    let p = UsagePoller(store: store)
                    p.start()
                    appDelegate.poller = p
                }
            }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
        }
    }
}
