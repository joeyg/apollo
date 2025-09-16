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
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

    @State private var isRequestingAuth = false
    @State private var authStatus: AuthorizationStatus = AuthorizationCenter.shared.authorizationStatus

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                    } label: {
                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
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
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
