import XCTest
@testable import UsageMeter

final class PeakHoursServiceTests: XCTestCase {
    private let pacific = TimeZone(identifier: "America/Los_Angeles")!

    private func date(year: Int = 2026, month: Int, day: Int, hour: Int, minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.timeZone = pacific
        return Calendar.current.date(from: components)!
    }

    // MARK: - isPeakHours

    func testPeakAtExactStart() {
        let d = date(month: 4, day: 13, hour: 5)
        XCTAssertTrue(PeakHoursService.isPeakHours(at: d))
    }

    func testNotPeakOneMinuteBeforeStart() {
        let d = date(month: 4, day: 13, hour: 4, minute: 59)
        XCTAssertFalse(PeakHoursService.isPeakHours(at: d))
    }

    func testPeakOneMinuteBeforeEnd() {
        let d = date(month: 4, day: 13, hour: 10, minute: 59)
        XCTAssertTrue(PeakHoursService.isPeakHours(at: d))
    }

    func testNotPeakAtExactEnd() {
        // Monday April 13 2026, 11:00 AM PT (half-open: 11:00 is NOT peak)
        let d = date(month: 4, day: 13, hour: 11)
        XCTAssertFalse(PeakHoursService.isPeakHours(at: d))
    }

    func testNotPeakOnSaturday() {
        let d = date(month: 4, day: 11, hour: 8)
        XCTAssertFalse(PeakHoursService.isPeakHours(at: d))
    }

    func testNotPeakOnSunday() {
        let d = date(month: 4, day: 12, hour: 9)
        XCTAssertFalse(PeakHoursService.isPeakHours(at: d))
    }

    func testPeakMidWindow() {
        let d = date(month: 4, day: 15, hour: 8)
        XCTAssertTrue(PeakHoursService.isPeakHours(at: d))
    }

    func testNotPeakEvening() {
        let d = date(month: 4, day: 14, hour: 18)
        XCTAssertFalse(PeakHoursService.isPeakHours(at: d))
    }

    // MARK: - DST transitions

    func testPeakDuringSpringForward() {
        // Sunday March 8 2026, 4:59 AM PT — not peak (Sunday), but DST springs forward at 2 AM
        let d = date(month: 3, day: 8, hour: 4, minute: 59)
        XCTAssertFalse(PeakHoursService.isPeakHours(at: d))
    }

    func testPeakMondayAfterSpringForward() {
        // Monday March 9 2026, 5:00 AM PT — first weekday peak after DST change
        let d = date(month: 3, day: 9, hour: 5)
        XCTAssertTrue(PeakHoursService.isPeakHours(at: d))
    }

    // MARK: - Friday boundary

    func testPeakFridayLastMinute() {
        let d = date(month: 4, day: 17, hour: 10, minute: 59)
        XCTAssertTrue(PeakHoursService.isPeakHours(at: d))
    }

    func testNotPeakFridayAtEnd() {
        // Friday April 17 2026, 11:00 AM PT — peak just ended, next is Monday
        let d = date(month: 4, day: 17, hour: 11)
        XCTAssertFalse(PeakHoursService.isPeakHours(at: d))
    }

    // MARK: - formattedStatus

    func testFormattedDuringPeak() {
        // Monday April 13 2026, 8:00 AM PT — peak ends at 11:00, so 3h remaining
        let d = date(month: 4, day: 13, hour: 8)
        let result = PeakHoursService.formattedStatus(at: d)
        XCTAssertTrue(result.isPeak)
        XCTAssertEqual(result.text, "ends in 3h 0m")
    }

    func testFormattedBeforePeakSameDay() {
        // Monday April 13 2026, 2:00 AM PT — peak starts at 5:00, so 3h away
        let d = date(month: 4, day: 13, hour: 2)
        let result = PeakHoursService.formattedStatus(at: d)
        XCTAssertFalse(result.isPeak)
        XCTAssertEqual(result.text, "starts in 3h 0m")
    }

    func testFormattedAfterPeakSameDay() {
        // Monday April 13 2026, 2:00 PM PT — next peak is Tuesday 5:00 AM
        let d = date(month: 4, day: 13, hour: 14)
        let result = PeakHoursService.formattedStatus(at: d)
        XCTAssertFalse(result.isPeak)
        XCTAssertEqual(result.text, "starts in 15h 0m")
    }

    func testFormattedFridayEvening() {
        // Friday April 17 2026, 6:00 PM PT — next peak is Monday 5:00 AM
        let d = date(month: 4, day: 17, hour: 18)
        let result = PeakHoursService.formattedStatus(at: d)
        XCTAssertFalse(result.isPeak)
        XCTAssertEqual(result.text, "Mon 5:00 AM PT")
    }

    func testFormattedSaturday() {
        // Saturday April 11 2026, 10:00 AM PT — next peak is Monday 5:00 AM
        let d = date(month: 4, day: 11, hour: 10)
        let result = PeakHoursService.formattedStatus(at: d)
        XCTAssertFalse(result.isPeak)
        XCTAssertEqual(result.text, "Mon 5:00 AM PT")
    }

    func testFormattedSundayEvening() {
        // Sunday April 12 2026, 8:00 PM PT — next peak is Monday 5:00 AM (9h away)
        let d = date(month: 4, day: 12, hour: 20)
        let result = PeakHoursService.formattedStatus(at: d)
        XCTAssertFalse(result.isPeak)
        XCTAssertEqual(result.text, "starts in 9h 0m")
    }

    func testFormattedFridayAtPeakEnd() {
        // Friday April 17 2026, 11:00 AM PT — peak just ended, next is Monday (>24h)
        let d = date(month: 4, day: 17, hour: 11)
        let result = PeakHoursService.formattedStatus(at: d)
        XCTAssertFalse(result.isPeak)
        XCTAssertEqual(result.text, "Mon 5:00 AM PT")
    }

    func testFormattedMondayAfterDST() {
        // Monday March 9 2026, 8:00 AM PT — peak, ends at 11:00 (3h)
        let d = date(month: 3, day: 9, hour: 8)
        let result = PeakHoursService.formattedStatus(at: d)
        XCTAssertTrue(result.isPeak)
        XCTAssertEqual(result.text, "ends in 3h 0m")
    }
}
