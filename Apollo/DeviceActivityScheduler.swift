import Foundation
import DeviceActivity
import ManagedSettings

enum ApolloActivityNames {
    static let fullDay = DeviceActivityName("apollo.fullDay")
}

enum DeviceActivityScheduler {
    static func startFullDayMonitoring() throws {
        setTwelveTwoHourSchedulesWithTwoMinuteEvents()
        //setDailyMinuteThresholds()
        //setOneToTenMinuteThresholds()
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
        for minute in 10...20 {
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
    
    static func setDailyMinuteThresholds() {
        let center = DeviceActivityCenter()

        // A unique name for this activity
        let activityName = DeviceActivityName("dailyMinuteThresholds")

        // Full-day schedule that repeats every day
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0, second: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
            repeats: true
        )

        // Build events for every minute of the day (0 through 1439 minutes)
        var eventsToMonitor: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]

        // We create thresholds from 0 minutes up to 23h59m, inclusive
        for totalMinutes in 0..<(24 * 60) {
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60

            // Unique, stable event name per minute
            let eventName = DeviceActivityEvent.Name(String(format: "minute_%02d_%02d", hours, minutes))

            // Threshold for this exact minute offset from interval start
            let event = DeviceActivityEvent(threshold: DateComponents(hour: hours, minute: minutes))
            eventsToMonitor[eventName] = event
        }

        do {
            try center.startMonitoring(activityName, during: schedule, events: eventsToMonitor)
            print("Successfully started monitoring for every minute of the day (1440 thresholds).")
        } catch {
            print("Error starting daily minute thresholds monitoring: \(error)")
        }
    }
    
    static func setTwelveTwoHourSchedulesWithTwoMinuteEvents() {
        let center = DeviceActivityCenter()

        // Create 12 two-hour segments to cover the full day.
        for segment in 0..<12 {
            let startHour = segment * 2
            let activityName = DeviceActivityName(String(format: "twoHourSegment_%02d_%02d", startHour, startHour + 2))

            // Two-hour schedule window, inclusive of 1:59:59 (or equivalent)
            let schedule = DeviceActivitySchedule(
                intervalStart: DateComponents(hour: startHour, minute: 0, second: 0),
                intervalEnd: DateComponents(hour: startHour + 1, minute: 59, second: 59),
                repeats: false
            )

            // 60 events, one every 2 minutes within the 2-hour window (0, 2, 4, ..., 118)
            var eventsToMonitor: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
            for i in 0..<60 {
                let offsetMinutes = i * 2
                let eventName = DeviceActivityEvent.Name(String(format: "twoMinute_%02d", offsetMinutes))
                let event = DeviceActivityEvent(threshold: DateComponents(minute: offsetMinutes))
                eventsToMonitor[eventName] = event
            }

            do {
                try center.startMonitoring(activityName, during: schedule, events: eventsToMonitor)
                print("Started monitoring segment \((String(format: "%02d", startHour)))–\((String(format: "%02d", startHour + 2))) with 60 two-minute events.")
            } catch {
                print("Error starting monitoring for segment \((String(format: "%02d", startHour)))–\((String(format: "%02d", startHour + 2))): \(error)")
            }
        }
    }
}
