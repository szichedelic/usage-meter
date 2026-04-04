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
        MenuBarExtra {
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
        } label: {
            MenuBarIcon(
                claudeUsage: store.services[0].worstUsage,
                codexUsage: store.services[1].worstUsage
            )
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
        }
    }
}
