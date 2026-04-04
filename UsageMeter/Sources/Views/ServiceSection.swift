import SwiftUI

struct ServiceSection: View {
    let service: ServiceUsage
    let labelColor: Color
    var onRelogin: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(service.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(labelColor)
                Spacer()
                if let lastUpdated = service.lastUpdated {
                    Text(timeAgo(lastUpdated))
                        .font(.system(size: 10))
                        .foregroundStyle(ThemeColors.secondaryText)
                }
            }

            switch service.status {
            case .ok:
                ForEach(service.metrics) { metric in
                    MetricRow(metric: metric)
                }
            case .unavailable:
                Text("Not connected")
                    .font(.system(size: 11))
                    .foregroundStyle(ThemeColors.secondaryText)
            case .authExpired:
                HStack {
                    Text("Session expired")
                        .font(.system(size: 11))
                        .foregroundStyle(ThemeColors.dustyRose)
                    Spacer()
                    if let onRelogin {
                        Button("Re-login", action: onRelogin)
                            .font(.system(size: 10))
                            .buttonStyle(.plain)
                            .foregroundStyle(ThemeColors.warmAmber)
                    }
                }
            case .error(let message):
                Text(message)
                    .font(.system(size: 11))
                    .foregroundStyle(ThemeColors.dustyRose)
                    .lineLimit(2)
            }
        }
        .padding(12)
    }

    private func timeAgo(_ date: Date) -> String {
        let seconds = Int(-date.timeIntervalSinceNow)
        if seconds < 60 { return "just now" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m ago" }
        return "\(minutes / 60)h ago"
    }
}
