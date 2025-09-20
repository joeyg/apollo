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
    private let consolidatedLogsKey = "ConsolidatedDeviceActivityEventLogs"

    private static let iso = ISO8601DateFormatter()

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

        // Read incoming logs from eventLogsKey supporting both string array and dictionary array
        var incomingItems: [LogItem] = []
        if let incomingLines = defaults.array(forKey: eventLogsKey) as? [String] {
            incomingItems = parseLines(incomingLines)
        } else if let incomingDicts = defaults.array(forKey: eventLogsKey) as? [[String: Any]] {
            incomingItems = parseDicts(incomingDicts)
        }

        // Read existing consolidated logs from consolidatedLogsKey supporting both string array and dictionary array
        var existingItems: [LogItem] = []
        if let existingLines = defaults.array(forKey: consolidatedLogsKey) as? [String] {
            existingItems = parseLines(existingLines)
        } else if let existingDicts = defaults.array(forKey: consolidatedLogsKey) as? [[String: Any]] {
            existingItems = parseDicts(existingDicts)
        }

        // Merge existing + incoming
        let mergedItems = existingItems + incomingItems

        // Persist mergedItems as compact string array and clear incoming key
        let compactStrings = mergedItems.map { item in
            "\(Self.iso.string(from: item.timestamp))|\(item.event)|\(item.activity)"
        }
        defaults.set(compactStrings, forKey: consolidatedLogsKey)
        if !incomingItems.isEmpty {
            defaults.removeObject(forKey: eventLogsKey)
        }

        // Sort newest first
        self.items = mergedItems.sorted(by: { $0.timestamp > $1.timestamp })
    }

    private func parseLines(_ lines: [String]) -> [LogItem] {
        lines.compactMap { line in
            let parts = line.split(separator: "|", maxSplits: 2, omittingEmptySubsequences: false)
            guard parts.count == 3,
                  let date = Self.iso.date(from: String(parts[0])) else {
                return nil
            }
            let event = String(parts[1])
            let activity = String(parts[2])
            return LogItem(timestamp: date, event: event, activity: activity)
        }
    }

    private func parseDicts(_ dicts: [[String: Any]]) -> [LogItem] {
        dicts.compactMap { dict in
            guard let ts = dict["timestamp"] as? String,
                  let date = Self.iso.date(from: ts),
                  let event = dict["event"] as? String,
                  let activity = dict["activity"] as? String else {
                return nil
            }
            return LogItem(timestamp: date, event: event, activity: activity)
        }
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
    
    public func clear() {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else {
            self.items = []
            return
        }
        
        defaults.removeObject(forKey: eventLogsKey)
        defaults.removeObject(forKey: consolidatedLogsKey)
        
        DispatchQueue.main.async {
            self.items = []
        }
    }
}
