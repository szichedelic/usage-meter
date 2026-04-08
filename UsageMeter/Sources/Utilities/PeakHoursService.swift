import Foundation

struct PeakHoursService {
    static let peakStartHour = 5
    static let peakEndHour = 11
    static let peakWeekdays: Set<Int> = [2, 3, 4, 5, 6] // Mon–Fri in Calendar (1=Sun)
    static let pacificTimeZone = TimeZone(identifier: "America/Los_Angeles")!

    static func isPeakHours(at date: Date) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = pacificTimeZone
        let weekday = calendar.component(.weekday, from: date)
        let hour = calendar.component(.hour, from: date)
        return peakWeekdays.contains(weekday) && hour >= peakStartHour && hour < peakEndHour
    }

    struct Status {
        let isPeak: Bool
        let text: String
    }

    static func formattedStatus(at date: Date) -> Status {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = pacificTimeZone

        if isPeakHours(at: date) {
            let endToday = calendar.date(bySettingHour: peakEndHour, minute: 0, second: 0, of: date)!
            let remaining = endToday.timeIntervalSince(date)
            return Status(isPeak: true, text: "ends in \(formatDuration(remaining))")
        }

        let nextPeak = nextPeakStart(after: date, calendar: calendar)
        let remaining = nextPeak.timeIntervalSince(date)

        // If more than 24 hours away, show "Mon 5:00 AM PT".
        // This assumes the only >24h gap is the weekend — true for the
        // current Mon–Fri schedule. Update if the schedule changes.
        if remaining > 24 * 3600 {
            return Status(isPeak: false, text: "Mon 5:00 AM PT")
        }

        return Status(isPeak: false, text: "starts in \(formatDuration(remaining))")
    }

    private static func nextPeakStart(after date: Date, calendar: Calendar) -> Date {
        var candidate = date
        for _ in 0..<8 {
            let weekday = calendar.component(.weekday, from: candidate)
            let hour = calendar.component(.hour, from: candidate)

            if peakWeekdays.contains(weekday) && hour < peakStartHour {
                return calendar.date(bySettingHour: peakStartHour, minute: 0, second: 0, of: candidate)!
            }

            let nextDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: candidate))!
            candidate = nextDay
        }
        // Fallback (should not reach)
        return date
    }

    private static func formatDuration(_ interval: TimeInterval) -> String {
        let totalMinutes = Int(interval) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return "\(hours)h \(minutes)m"
    }
}
