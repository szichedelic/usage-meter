import Foundation
import UserNotifications

@MainActor
class NotificationManager {
    private var firedThresholds: [String: Set<Double>] = [:]

    init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func checkAndNotify(service: ServiceUsage) {
        guard service.status == .ok else { return }

        let amber = UserDefaults.standard.double(forKey: "amberThreshold")
        let red = UserDefaults.standard.double(forKey: "redThreshold")
        let amberThreshold = amber > 0 ? amber / 100.0 : 0.8
        let redThreshold = red > 0 ? red / 100.0 : 0.95

        for metric in service.metrics {
            let key = "\(service.name)-\(metric.label)"

            if metric.percentUsed >= redThreshold {
                fireIfNeeded(key: key, threshold: redThreshold,
                             title: "\(service.name) — \(metric.label)",
                             body: "\(Int(metric.percentUsed * 100))% used. \(metric.resetTime).")
            } else if metric.percentUsed >= amberThreshold {
                fireIfNeeded(key: key, threshold: amberThreshold,
                             title: "\(service.name) — \(metric.label)",
                             body: "\(Int(metric.percentUsed * 100))% used. \(metric.resetTime).")
            }

            if metric.percentUsed < amberThreshold {
                firedThresholds[key] = nil
            }
        }
    }

    private func fireIfNeeded(key: String, threshold: Double, title: String, body: String) {
        if firedThresholds[key]?.contains(threshold) == true { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "\(key)-\(threshold)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)

        if firedThresholds[key] == nil { firedThresholds[key] = [] }
        firedThresholds[key]?.insert(threshold)
    }
}
