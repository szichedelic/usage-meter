import SwiftUI

struct MenuBarIcon: View {
    let claudeUsage: Double
    let codexUsage: Double

    var body: some View {
        HStack(spacing: 2) {
            Circle()
                .fill(ThemeColors.barColor(for: claudeUsage))
                .frame(width: 8, height: 8)
            Text("C")
                .font(.system(size: 11))
            Circle()
                .fill(ThemeColors.barColor(for: codexUsage))
                .frame(width: 8, height: 8)
                .padding(.leading, 2)
            Text("X")
                .font(.system(size: 11))
        }
    }
}
