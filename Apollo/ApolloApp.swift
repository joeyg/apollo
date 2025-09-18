//
//  ApolloApp.swift
//  Apollo
//
//  Created by Joe Gasiorek on 9/15/25.
//

import SwiftUI
import SwiftData
import UIKit
import BackgroundTasks
import UserNotifications

@main
struct ApolloApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var logStore = LogStore()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(logStore)
                .task {
                    BackgroundTaskManager.shared.scheduleAppRefresh()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
