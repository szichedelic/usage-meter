import SwiftUI

struct DropdownView: View {
    @ObservedObject var store: UsageStore
    let onRefresh: () -> Void
    let onQuit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ServiceSection(
                service: store.services[0],
                labelColor: ThemeColors.claudeLabel,
                onRelogin: { ScraperBridge.login(service: "claude") }
            )

            ThemeColors.divider.frame(height: 1)

            ServiceSection(
                service: store.services[1],
                labelColor: ThemeColors.codexLabel,
                onRelogin: { ScraperBridge.login(service: "codex") }
            )

            ThemeColors.divider.frame(height: 1)

            HStack {
                Button(action: onRefresh) {
                    Text("\u{21BB} Refresh")
                        .font(.system(size: 10))
                        .foregroundStyle(ThemeColors.footerText)
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }) {
                    Text("Settings")
                        .font(.system(size: 10))
                        .foregroundStyle(ThemeColors.footerText)
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: onQuit) {
                    Text("Quit")
                        .font(.system(size: 10))
                        .foregroundStyle(ThemeColors.footerText)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .frame(width: 280)
        .background(ThemeColors.background)
    }
}
