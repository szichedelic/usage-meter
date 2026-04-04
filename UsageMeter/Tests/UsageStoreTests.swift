import XCTest
@testable import UsageMeter

final class UsageStoreTests: XCTestCase {
    @MainActor
    func testInitialStateHasTwoServices() {
        let store = UsageStore()
        XCTAssertEqual(store.services.count, 2)
        XCTAssertEqual(store.services[0].name, "Claude Max")
        XCTAssertEqual(store.services[1].name, "Codex")
    }

    @MainActor
    func testInitialStatusIsUnavailable() {
        let store = UsageStore()
        XCTAssertEqual(store.services[0].status, .unavailable)
        XCTAssertEqual(store.services[1].status, .unavailable)
    }

    @MainActor
    func testApplyScraperOutput() {
        let store = UsageStore()
        let metrics = [UsageMetric(label: "Session", percentUsed: 0.04, resetTime: "Resets in 2h 5m")]
        store.updateService(index: 0, metrics: metrics, status: .ok)
        XCTAssertEqual(store.services[0].status, .ok)
        XCTAssertEqual(store.services[0].metrics.count, 1)
        XCTAssertNotNil(store.services[0].lastUpdated)
    }

    @MainActor
    func testAuthExpiredStatus() {
        let store = UsageStore()
        store.updateService(index: 0, metrics: [], status: .authExpired)
        XCTAssertEqual(store.services[0].status, .authExpired)
    }
}
