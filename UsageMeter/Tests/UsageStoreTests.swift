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
    func testHighestUsageIsNilWithoutData() {
        let store = UsageStore()
        XCTAssertNil(store.highestUsage)
    }

    @MainActor
    func testHighestUsageAcrossServices() {
        let store = UsageStore()
        store.updateService(index: 0, metrics: [
            UsageMetric(label: "Weekly", percentUsed: 0.59, resetTime: ""),
            UsageMetric(label: "Fable", percentUsed: 0.60, resetTime: "")
        ], status: .ok)
        store.updateService(index: 1, metrics: [
            UsageMetric(label: "General Wk", percentUsed: 0.01, resetTime: "")
        ], status: .ok)
        XCTAssertEqual(store.highestUsage, 0.60)
    }

    @MainActor
    func testHighestUsageIgnoresFailedServices() {
        let store = UsageStore()
        store.updateService(index: 0, metrics: [], status: .authExpired)
        store.updateService(index: 1, metrics: [
            UsageMetric(label: "General Wk", percentUsed: 0.01, resetTime: "")
        ], status: .ok)
        XCTAssertEqual(store.highestUsage, 0.01)
    }

    @MainActor
    func testAuthExpiredStatus() {
        let store = UsageStore()
        store.updateService(index: 0, metrics: [], status: .authExpired)
        XCTAssertEqual(store.services[0].status, .authExpired)
    }
}
