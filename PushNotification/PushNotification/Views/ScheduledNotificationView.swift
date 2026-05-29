//
//  ScheduledNotificationView.swift
//  PushNotification
//
//  Created for learning purposes.
//
//  PURPOSE:
//  Demonstrates the two time-based triggers:
//  • UNTimeIntervalNotificationTrigger — fires after N seconds
//  • UNCalendarNotificationTrigger    — fires at a specific date/time
//
//  KEY LEARNING POINTS:
//  1. The difference between interval-based vs calendar-based scheduling
//  2. How DateComponents are used to specify an exact fire date
//  3. How `repeats: true` would turn either trigger into a recurring reminder

import SwiftUI

struct ScheduledNotificationView: View {

    @EnvironmentObject private var notificationManager: NotificationManager

    // Time interval selection
    @State private var selectedInterval: TimeInterval = 5

    // Calendar date selection
    @State private var selectedDate = Date().addingTimeInterval(60)  // default: 1 min from now

    @State private var showAlert     = false
    @State private var alertMessage  = ""

    private let intervals: [(label: String, seconds: TimeInterval)] = [
        ("5 s",  5),
        ("10 s", 10),
        ("30 s", 30),
        ("1 min", 60)
    ]

    // MARK: ─── Body ───────────────────────────────────────────────────────────

    var body: some View {
        NavigationStack {
            Form {

                // ── Time Interval ──────────────────────────────────────────
                Section {
                    Picker("Fire after", selection: $selectedInterval) {
                        ForEach(intervals, id: \.seconds) { item in
                            Text(item.label).tag(item.seconds)
                        }
                    }
                    .pickerStyle(.segmented)

                    Button {
                        scheduleInterval()
                    } label: {
                        Label("Schedule Interval Notification", systemImage: "clock.fill")
                    }
                    .disabled(!isAuthorized)

                    CodeSnippetView(code: intervalCode, title: "UNTimeIntervalNotificationTrigger")
                } header: {
                    Text("Time Interval Trigger")
                } footer: {
                    Text("UNTimeIntervalNotificationTrigger fires after the specified number of seconds. Use repeats: true to build recurring reminders.")
                }

                // ── Calendar ───────────────────────────────────────────────
                Section {
                    DatePicker(
                        "Fire at",
                        selection: $selectedDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )

                    Button {
                        scheduleCalendar()
                    } label: {
                        Label("Schedule Calendar Notification", systemImage: "calendar")
                    }
                    .disabled(!isAuthorized)

                    CodeSnippetView(code: calendarCode, title: "UNCalendarNotificationTrigger")
                } header: {
                    Text("Calendar / Date Trigger")
                } footer: {
                    Text("UNCalendarNotificationTrigger converts a Date into DateComponents and fires when the clock matches. Ideal for alarms and event reminders.")
                }

                // ── Warning ────────────────────────────────────────────────
                if !isAuthorized {
                    Section {
                        Label(
                            "Notifications are not authorized. Go to the Home tab.",
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .foregroundStyle(.orange)
                        .font(.caption)
                    }
                }
            }
            .navigationTitle("Scheduled")
            .alert("Scheduled ✅", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    // MARK: ─── Actions ────────────────────────────────────────────────────────

    private func scheduleInterval() {
        let label = intervals.first(where: { $0.seconds == selectedInterval })?.label ?? "\(Int(selectedInterval))s"
        notificationManager.scheduleTimeIntervalNotification(
            title: "Time Interval Fired ⏰",
            body: "You scheduled this \(label) ago.",
            after: selectedInterval
        )
        alertMessage = "Notification scheduled in \(label).\n\nBackground the app to see the banner."
        showAlert = true
    }

    private func scheduleCalendar() {
        notificationManager.scheduleCalendarNotification(
            title: "Calendar Trigger Fired 📅",
            body: "You scheduled this for \(selectedDate.formatted(date: .abbreviated, time: .shortened)).",
            date: selectedDate
        )
        alertMessage = "Notification scheduled for:\n\(selectedDate.formatted(date: .long, time: .shortened))."
        showAlert = true
    }

    // MARK: ─── Helpers ────────────────────────────────────────────────────────

    private var isAuthorized: Bool {
        notificationManager.authorizationStatus == .authorized ||
        notificationManager.authorizationStatus == .provisional
    }

    // MARK: ─── Code Samples ───────────────────────────────────────────────────

    private let intervalCode = """
// Fires after 30 seconds
let trigger = UNTimeIntervalNotificationTrigger(
    timeInterval: 30,
    repeats: false        // set to true for recurring
)
"""

    private let calendarCode = """
// Pick which date components to match.
// Omitting a component means "any value" for that field.
var components = Calendar.current.dateComponents(
    [.year, .month, .day, .hour, .minute],
    from: selectedDate
)

let trigger = UNCalendarNotificationTrigger(
    dateMatching: components,
    repeats: false
)

// Tip: to fire every day at 9 AM, use:
// components = DateComponents(hour: 9, minute: 0)
// repeats: true
"""
}

// MARK: - Preview

#Preview {
    ScheduledNotificationView()
        .environmentObject(NotificationManager.shared)
}
