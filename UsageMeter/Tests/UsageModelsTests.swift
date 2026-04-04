import XCTest
@testable import UsageMeter

final class UsageModelsTests: XCTestCase {
    func testDecodesScraperOutput() throws {
        let json = """
        {
          "claude": {
            "metrics": [
              {"label": "Session", "percent_used": 4, "reset_time": "Resets in 2h 5m"},
              {"label": "Weekly", "percent_used": 28, "reset_time": "Resets in 12h 5m"}
            ]
          },
          "codex": {
            "metrics": [
              {"label": "General 5h", "percent_used": 3, "reset_time": "Resets 10:31 PM"}
            ]
          }
        }
        """.data(using: .utf8)!

        let output = try JSONDecoder().decode(ScraperOutput.self, from: json)
        let claudeMetrics = try XCTUnwrap(output.claude?.metrics)
        XCTAssertEqual(claudeMetrics.count, 2)
        XCTAssertEqual(claudeMetrics[0].label, "Session")
        XCTAssertEqual(claudeMetrics[0].percentUsed, 0.04, accuracy: 0.001)
        let codexMetrics = try XCTUnwrap(output.codex?.metrics)
        XCTAssertEqual(codexMetrics.count, 1)
        XCTAssertEqual(codexMetrics[0].percentUsed, 0.03, accuracy: 0.001)
    }

    func testDecodesAuthExpired() throws {
        let json = """
        {
          "claude": {"status": "auth_expired"},
          "codex": {"metrics": []}
        }
        """.data(using: .utf8)!

        let output = try JSONDecoder().decode(ScraperOutput.self, from: json)
        XCTAssertEqual(output.claude?.status, "auth_expired")
        XCTAssertNil(output.claude?.metrics)
    }

    func testDecodesErrorResponse() throws {
        let json = """
        {"error": "No saved profile. Run with --login first."}
        """.data(using: .utf8)!

        let output = try JSONDecoder().decode(ScraperOutput.self, from: json)
        XCTAssertEqual(output.error, "No saved profile. Run with --login first.")
    }

    func testWorstUsage() {
        let service = ServiceUsage(
            name: "Test",
            metrics: [
                UsageMetric(label: "A", percentUsed: 0.3, resetTime: ""),
                UsageMetric(label: "B", percentUsed: 0.8, resetTime: "")
            ],
            lastUpdated: nil,
            status: .ok
        )
        XCTAssertEqual(service.worstUsage, 0.8, accuracy: 0.001)
    }
}
