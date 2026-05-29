//
//  ContentView.swift
//  PushNotification
//
//  Root container: a TabView that hosts the four demo screens.
//  Each tab focuses on a different aspect of notifications.

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            // Tab 1 — Concepts & permission status
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            // Tab 2 — Immediate & actionable local notifications
            LocalNotificationView()
                .tabItem {
                    Label("Local", systemImage: "bell.fill")
                }

            // Tab 3 — Time-interval & calendar-based scheduling
            ScheduledNotificationView()
                .tabItem {
                    Label("Scheduled", systemImage: "clock.fill")
                }

            // Tab 4 — View and cancel pending / delivered notifications
            NotificationHistoryView()
                .tabItem {
                    Label("History", systemImage: "list.bullet")
                }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(NotificationManager.shared)
}
