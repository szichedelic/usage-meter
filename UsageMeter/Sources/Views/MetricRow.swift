import SwiftUI

struct MetricRow: View {
    let metric: UsageMetric

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 8) {
                Text(metric.label)
                    .foregroundStyle(ThemeColors.primaryText)
                    .frame(width: 90, alignment: .leading)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(ThemeColors.barBackground)
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(ThemeColors.barColor(for: metric.percentUsed))
                            .frame(width: geo.size.width * metric.percentUsed, height: 4)
                    }
                }
                .frame(height: 4)

                Text("\(Int(metric.percentUsed * 100))%")
                    .foregroundStyle(ThemeColors.primaryText)
                    .frame(width: 45, alignment: .trailing)
            }

            Text(metric.resetTime)
                .font(.system(size: 9))
                .foregroundStyle(ThemeColors.secondaryText)
                .padding(.leading, 98)
        }
        .font(.system(size: 11))
    }
}
