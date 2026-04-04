import Foundation

enum ServiceStatus: Equatable {
    case ok
    case unavailable
    case authExpired
    case error(String)
}

struct UsageMetric: Identifiable, Equatable, Decodable {
    let id: UUID
    let label: String
    let percentUsed: Double
    let resetTime: String

    init(label: String, percentUsed: Double, resetTime: String) {
        self.id = UUID()
        self.label = label
        self.percentUsed = percentUsed
        self.resetTime = resetTime
    }

    enum CodingKeys: String, CodingKey {
        case label
        case percentUsed = "percent_used"
        case resetTime = "reset_time"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.label = try c.decode(String.self, forKey: .label)
        let rawPercent = try c.decode(Double.self, forKey: .percentUsed)
        self.percentUsed = rawPercent / 100.0
        self.resetTime = try c.decode(String.self, forKey: .resetTime)
    }
}

struct ServiceUsage: Identifiable, Equatable {
    let id = UUID()
    let name: String
    var metrics: [UsageMetric]
    var lastUpdated: Date?
    var status: ServiceStatus

    static func == (lhs: ServiceUsage, rhs: ServiceUsage) -> Bool {
        lhs.name == rhs.name && lhs.metrics == rhs.metrics && lhs.status == rhs.status
    }

    var worstUsage: Double {
        metrics.map(\.percentUsed).max() ?? 0.0
    }
}

struct ScraperOutput: Decodable {
    let claude: ServiceResult?
    let codex: ServiceResult?
    let error: String?
}

struct ServiceResult: Decodable {
    let metrics: [UsageMetric]?
    let status: String?
    let message: String?
}
