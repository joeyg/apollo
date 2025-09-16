import Foundation
import DeviceActivity
import ManagedSettings

enum ApolloActivityNames {
    static let fullDay = DeviceActivityName("apollo.fullDay")
}

enum DeviceActivityScheduler {
    static func startFullDayMonitoring() throws {
        setOneToTenMinuteThresholds()
//        // 24-hour schedule, repeating every day (00:00 -> 23:59)
//        let schedule = DeviceActivitySchedule(
//            intervalStart: DateComponents(hour: 0, minute: 0),
//            intervalEnd: DateComponents(hour: 23, minute: 59),
//            repeats: true
//        )
//        try DeviceActivityCenter().startMonitoring(ApolloActivityNames.fullDay, during: schedule)
    }

    static func stopFullDayMonitoring() {
        // Updated: pass an array of names
        DeviceActivityCenter().stopMonitoring([ApolloActivityNames.fullDay])
    }

    static func setOneToTenMinuteThresholds() {
        let center = DeviceActivityCenter()

        // 1. Define a single, unique name for this monitoring activity.
        let activityName = DeviceActivityName("tenMinuteThresholds")

        // 2. Define a schedule that repeats indefinitely.
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(minute: 0, second: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
            repeats: true
        )

        // 3. Create a dictionary to hold all our named events.
        var eventsToMonitor: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]

        // 4. Loop from 1 to 10 to create each unique event.
        for minute in 1...10 {
            // Each event within the dictionary needs its own unique name.
            let eventName = DeviceActivityEvent.Name("minute\(minute)Threshold")

            // Define the event with the specific minute threshold.
            let event = DeviceActivityEvent(threshold: DateComponents(minute: minute))

            // Add the event to our dictionary.
            eventsToMonitor[eventName] = event
        }

        do {
            // 5. Start monitoring for the single activity, with all events in the dictionary.
            try center.startMonitoring(activityName, during: schedule, events: eventsToMonitor)
            print("Successfully started monitoring for minute thresholds 1 through 10.")
        } catch {
            print("Error starting Device Activity monitoring: \(error)")
        }
    }
}
