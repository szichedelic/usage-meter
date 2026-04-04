import SwiftUI

struct ThemeColors {
    static let background = Color(red: 0.11, green: 0.11, blue: 0.12)
    static let barBackground = Color.white.opacity(0.04)
    static let divider = Color.white.opacity(0.04)
    static let claudeLabel = Color(red: 0.77, green: 0.63, blue: 0.88)
    static let codexLabel = Color(red: 0.48, green: 0.68, blue: 0.88)
    static let primaryText = Color(red: 0.48, green: 0.48, blue: 0.49)
    static let secondaryText = Color(red: 0.29, green: 0.29, blue: 0.31)
    static let footerText = Color(red: 0.29, green: 0.29, blue: 0.31)

    static let mutedGreen = Color(red: 0.49, green: 0.72, blue: 0.63)
    static let warmAmber = Color(red: 0.83, green: 0.66, blue: 0.33)
    static let dustyRose = Color(red: 0.77, green: 0.48, blue: 0.48)

    static func barColor(for percentUsed: Double) -> Color {
        switch percentUsed {
        case 0..<0.6: return mutedGreen
        case 0.6..<0.8: return warmAmber
        default: return dustyRose
        }
    }
}
