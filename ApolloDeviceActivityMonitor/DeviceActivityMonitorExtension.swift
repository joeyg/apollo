//
//  DeviceActivityMonitorExtension.swift
//  ApolloDeviceActivityMonitor
//
//  Created by Joe Gasiorek on 9/15/25.
//

import DeviceActivity
import Foundation

// Optionally override any of the functions below.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    private static let isoFormatter = ISO8601DateFormatter()

    // MARK: - Shared defaults logging
    /// Update this to your App Group identifier so the extension and app can share data.
    private let appGroupIdentifier = "group.com.github.joeyg.apollo"
    private let eventLogsKey = "DeviceActivityEventLogs"

    /// Appends a compact log line to shared UserDefaults under `eventLogsKey`.
    /// Keeps only the most recent 100 entries to avoid unbounded growth.
    private func appendEventLogLine(_ line: String) {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else {
            return
        }
        var logs = defaults.stringArray(forKey: eventLogsKey) ?? []
        logs.append(line)
        if logs.count > 100 { // cap to latest 100
            logs = Array(logs.suffix(100))
        }
        defaults.set(logs, forKey: eventLogsKey)
    }

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        // Handle the start of the interval.
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        // Handle the end of the interval.
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)

        let timestamp = Self.isoFormatter.string(from: Date())
        // Compact, single-line log to reduce memory and bridging overhead
        let line = "\(timestamp)|\(event.rawValue)|\(activity.rawValue)"
        appendEventLogLine(line)
    }

    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
        // Handle the warning before the interval starts.
    }

    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
        // Handle the warning before the interval ends.
    }

    override func eventWillReachThresholdWarning(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventWillReachThresholdWarning(event, activity: activity)
        // Handle the warning before the event reaches its threshold.
    }
}
