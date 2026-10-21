import Foundation
import SwiftUI

@MainActor
class UsageStore: ObservableObject {
    @Published var services: [ServiceUsage] = [
        ServiceUsage(name: "Claude Max", metrics: [], lastUpdated: nil, status: .unavailable),
        ServiceUsage(name: "Codex", metrics: [], lastUpdated: nil, status: .unavailable)
    ]

    /// Highest usage across services with fresh data, or nil when none have any.
    var highestUsage: Double? {
        services
            .filter { $0.status == .ok && !$0.metrics.isEmpty }
            .map(\.worstUsage)
            .max()
    }

    func updateService(index: Int, metrics: [UsageMetric], status: ServiceStatus) {
        guard index >= 0 && index < services.count else { return }
        services[index] = ServiceUsage(
            name: services[index].name,
            metrics: metrics,
            lastUpdated: Date(),
            status: status
        )
    }

    func applyScraperOutput(_ output: ScraperOutput) {
        if let error = output.error {
            updateService(index: 0, metrics: [], status: .error(error))
            updateService(index: 1, metrics: [], status: .error(error))
            return
        }
        applyServiceResult(output.claude, index: 0)
        applyServiceResult(output.codex, index: 1)
    }

    private func applyServiceResult(_ result: ServiceResult?, index: Int) {
        guard let result else {
            updateService(index: index, metrics: [], status: .error("No data"))
            return
        }
        if result.status == "auth_expired" {
            updateService(index: index, metrics: [], status: .authExpired)
        } else if let metrics = result.metrics, !metrics.isEmpty {
            updateService(index: index, metrics: metrics, status: .ok)
        } else if let message = result.message {
            updateService(index: index, metrics: [], status: .error(message))
        } else {
            updateService(index: index, metrics: [], status: .error("No metrics returned"))
        }
    }
}
