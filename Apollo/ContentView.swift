//
//  ContentView.swift
//  Apollo
//
//  Created by Joe Gasiorek on 9/15/25.
//

import SwiftUI
import SwiftData
import FamilyControls

struct ContentView: View {
    @EnvironmentObject var logStore: LogStore
    @Environment(\.scenePhase) private var scenePhase

    @State private var isRequestingAuth = false
    @State private var authStatus: AuthorizationStatus = AuthorizationCenter.shared.authorizationStatus

    var body: some View {
        NavigationSplitView {
            List(logStore.items.sorted(by: { $0.timestamp > $1.timestamp })) { item in
                NavigationLink {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Event: \(item.event)")
                            .font(.headline)
                        Text("Activity: \(item.activity)")
                            .font(.subheadline)
                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding()
                } label: {
                    VStack(alignment: .leading) {
                        Text(item.event)
                            .font(.headline)
                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .task {
                logStore.startAutoRefresh()
            }
            .onChange(of: scenePhase) { _, newPhase in
                switch newPhase {
                case .active:
                    logStore.startAutoRefresh()
                default:
                    logStore.stopAutoRefresh()
                }
            }
            .refreshable {
                logStore.load()
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isRequestingAuth = true
                        Task {
                            do {
                                try await ScreenTimeAuthorization.requestAuthorization()
                            } catch {
                                // You may want to present an error to the user.
                                print("Authorization failed: \(error)")
                            }
                            authStatus = ScreenTimeAuthorization.authorizationStatus
                            isRequestingAuth = false
                        }
                    } label: {
                        if isRequestingAuth {
                            ProgressView()
                        } else {
                            switch authStatus {
                            case .notDetermined:
                                Label("Authorize", systemImage: "hand.raised")
                            case .approved:
                                Label("Authorized", systemImage: "checkmark.seal")
                            case .denied:
                                Label("Authorization Denied", systemImage: "xmark.seal")
                            @unknown default:
                                Label("Authorize", systemImage: "hand.raised")
                            }
                        }
                    }
                    .help("Request Screen Time authorization")
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        do {
                            try DeviceActivityScheduler.startFullDayMonitoring()
                            print("Started 24-hour monitoring")
                        } catch {
                            print("Failed to start monitoring: \(error)")
                        }
                    } label: {
                        Label("Start Monitoring", systemImage: "clock.arrow.circlepath")
                    }
                    .help("Start a daily 24-hour device activity monitor")
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        logStore.clear()
                        logStore.load()
                    } label: {
                        Label("Clear Logs", systemImage: "trash")
                    }
                    .help("Clear all device activity logs")
                }
            }
        } detail: {
            Text("Select an item")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(LogStore())
}
