import Foundation
import UIKit
import Combine

struct LogItem: Identifiable, Equatable {
    let id = UUID()
    let timestamp: Date
    let event: String
    let activity: String
}

final class LogStore: ObservableObject {
    // Update to your real App Group identifier
    private let appGroupIdentifier = "group.com.github.joeyg.apollo"
    private let eventLogsKey = "DeviceActivityEventLogs"

    @Published private(set) var items: [LogItem] = []

    private var refreshTask: Task<Void, Never>? = nil

    init() {
        load()
        // Observe app entering foreground to refresh, if available on main app side
        NotificationCenter.default.addObserver(self, selector: #selector(loadOnForeground), name: UIScene.willEnterForegroundNotification, object: nil)
    }

    @objc private func loadOnForeground() {
        load()
    }

    func load() {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else {
            self.items = []
            return
        }
        let raw = defaults.array(forKey: eventLogsKey) as? [[String: Any]] ?? []
        let iso = ISO8601DateFormatter()
        let mapped: [LogItem] = raw.compactMap { dict in
            guard let ts = dict["timestamp"] as? String,
                  let date = iso.date(from: ts) ?? ISO8601DateFormatter().date(from: ts),
                  let event = dict["event"] as? String,
                  let activity = dict["activity"] as? String else {
                return nil
            }
            return LogItem(timestamp: date, event: event, activity: activity)
        }
        // Sort newest first
        self.items = mapped.sorted(by: { $0.timestamp > $1.timestamp })
    }
    
    func startAutoRefresh(every seconds: UInt64 = 60) {
        stopAutoRefresh()
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                await MainActor.run { self?.load() }
                do {
                    try await Task.sleep(nanoseconds: seconds * 1_000_000_000)
                } catch {
                    break
                }
            }
        }
    }

    func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }
}
