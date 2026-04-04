import Foundation

enum ScraperBridge {
    private static var scraperPath: String {
        let bundlePath = Bundle.main.bundlePath
        let appDir = (bundlePath as NSString).deletingLastPathComponent
        let candidates = [
            "\(appDir)/scraper/scraper.py",
            "\(appDir)/../scraper/scraper.py",
            "\(FileManager.default.currentDirectoryPath)/scraper/scraper.py"
        ]
        return candidates.first { FileManager.default.fileExists(atPath: $0) } ?? "scraper/scraper.py"
    }

    private static var pythonPath: String {
        let venvPython = "\(NSHomeDirectory())/.usage-meter/venv/bin/python"
        if FileManager.default.fileExists(atPath: venvPython) {
            return venvPython
        }
        return "/usr/bin/python3"
    }

    static func scrape() async -> ScraperOutput? {
        let process = Process()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: pythonPath)
        process.arguments = [scraperPath, "--headless"]
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        do {
            try process.run()
        } catch {
            return nil
        }

        var stdoutData = Data()
        var stderrData = Data()
        let group = DispatchGroup()

        group.enter()
        DispatchQueue.global().async {
            stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            group.leave()
        }
        group.enter()
        DispatchQueue.global().async {
            stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            group.leave()
        }

        let timeoutTask = Task {
            try await Task.sleep(for: .seconds(60))
            if process.isRunning { process.terminate() }
        }

        process.waitUntilExit()
        timeoutTask.cancel()
        group.wait()

        guard process.terminationStatus == 0 else { return nil }

        return try? JSONDecoder().decode(ScraperOutput.self, from: stdoutData)
    }

    static func login(service: String? = nil) {
        let python = pythonPath
        let scraper = scraperPath

        var args = [scraper]
        if let service {
            args.append("--login-\(service)")
        } else {
            args.append("--login")
        }

        let script = """
        tell application "Terminal"
            activate
            do script "\(python) \(args.joined(separator: " "))"
        end tell
        """
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
    }
}
