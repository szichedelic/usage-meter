import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @AppStorage("pollInterval") private var pollInterval: Double = 600
    @AppStorage("amberThreshold") private var amberThreshold: Double = 80
    @AppStorage("redThreshold") private var redThreshold: Double = 95
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = false

    var body: some View {
        Form {
            Section("Polling") {
                HStack {
                    Text("Poll interval")
                    Spacer()
                    Picker("", selection: $pollInterval) {
                        Text("5 min").tag(300.0)
                        Text("10 min").tag(600.0)
                        Text("15 min").tag(900.0)
                        Text("30 min").tag(1800.0)
                    }
                    .frame(width: 120)
                }
            }

            Section("Notifications") {
                HStack {
                    Text("Warning at")
                    Spacer()
                    TextField("", value: $amberThreshold, format: .number)
                        .frame(width: 50)
                    Text("%")
                }
                HStack {
                    Text("Critical at")
                    Spacer()
                    TextField("", value: $redThreshold, format: .number)
                        .frame(width: 50)
                    Text("%")
                }
            }

            Section("General") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            launchAtLogin = !newValue
                        }
                    }
            }

            Section("Accounts") {
                Button("Re-login Claude") { ScraperBridge.login(service: "claude") }
                Button("Re-login Codex") { ScraperBridge.login(service: "codex") }
                Button("Re-login All") { ScraperBridge.login() }
            }
        }
        .formStyle(.grouped)
        .frame(width: 320, height: 340)
        .padding()
    }
}
