import XCTest
@testable import UsageMeter

final class ColorsTests: XCTestCase {
    func testBarColorGreenForLowUsage() {
        XCTAssertEqual(ThemeColors.barColor(for: 0.0), ThemeColors.mutedGreen)
        XCTAssertEqual(ThemeColors.barColor(for: 0.59), ThemeColors.mutedGreen)
    }

    func testBarColorAmberForMediumUsage() {
        XCTAssertEqual(ThemeColors.barColor(for: 0.6), ThemeColors.warmAmber)
        XCTAssertEqual(ThemeColors.barColor(for: 0.79), ThemeColors.warmAmber)
    }

    func testBarColorRoseForHighUsage() {
        XCTAssertEqual(ThemeColors.barColor(for: 0.8), ThemeColors.dustyRose)
        XCTAssertEqual(ThemeColors.barColor(for: 1.0), ThemeColors.dustyRose)
    }
}
