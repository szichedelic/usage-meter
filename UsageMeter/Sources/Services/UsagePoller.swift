import Foundation

@MainActor
class UsagePoller {
    private let store: UsageStore
    private var timer: Timer?
    private var pollInterval: TimeInterval = 600
    private var intervalObserver: NSObjectProtocol?
    private let notificationManager = NotificationManager()

    init(store: UsageStore) {
        self.store = store
    }

    func start() {
        let stored = UserDefaults.standard.double(forKey: "pollInterval")
        pollInterval = stored > 0 ? stored : 600
        poll()
        scheduleTimer()

        intervalObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            let newInterval = UserDefaults.standard.double(forKey: "pollInterval")
            let interval = newInterval > 0 ? newInterval : 600
            if interval != self.pollInterval {
                self.pollInterval = interval
                self.scheduleTimer()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        if let observer = intervalObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func poll() {
        Task {
            if let output = await ScraperBridge.scrape() {
                store.applyScraperOutput(output)
                for service in store.services {
                    notificationManager.checkAndNotify(service: service)
                }
            } else {
                store.applyScraperOutput(ScraperOutput(
                    claude: nil,
                    codex: nil,
                    error: "Couldn't refresh usage. Close the login browser and try Refresh."
                ))
            }
        }
    }

    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.poll()
            }
        }
    }
}
