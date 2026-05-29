//
//  NotificationHistoryView.swift
//  PushNotification
//
//  Created for learning purposes.
//
//  PURPOSE:
//  Shows all pending and delivered notifications in two sections.
//  Pending notifications can be individually swiped-to-delete or bulk cleared.
//
//  KEY LEARNING POINTS:
//  1. getPendingNotificationRequests  — all scheduled-but-not-yet-fired requests
//  2. getDeliveredNotifications       — notifications already shown to the user
//  3. removePendingNotificationRequests(withIdentifiers:) — cancel specific ones
//  4. removeAllDeliveredNotifications  — clear the Notification Center

import SwiftUI
import UserNotifications

struct NotificationHistoryView: View {

    @EnvironmentObject private var notificationManager: NotificationManager

    var body: some View {
        NavigationStack {
            List {
                pendingSection
                deliveredSection
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        notificationManager.refreshLists()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(role: .destructive) {
                        notificationManager.cancelAll()
                    } label: {
                        Label("Clear All", systemImage: "trash")
                    }
                    .disabled(
                        notificationManager.pendingNotifications.isEmpty &&
                        notificationManager.deliveredNotifications.isEmpty
                    )
                }
            }
            .onAppear { notificationManager.refreshLists() }
        }
    }

    // MARK: ─── Pending Section ────────────────────────────────────────────────

    private var pendingSection: some View {
        Section {
            if notificationManager.pendingNotifications.isEmpty {
                emptyRow(message: "No pending notifications")
            } else {
                ForEach(notificationManager.pendingNotifications, id: \.identifier) { request in
                    NotificationRow(
                        title: request.content.title,
                        message: request.content.body,
                        detail: triggerDetail(for: request.trigger),
                        statusColor: .blue,
                        statusLabel: "Pending"
                    )
                }
                .onDelete { indexSet in
                    indexSet.forEach { i in
                        let id = notificationManager.pendingNotifications[i].identifier
                        notificationManager.cancelPending(identifier: id)
                    }
                }
            }
        } header: {
            HStack {
                Text("Pending")
                Spacer()
                Text("\(notificationManager.pendingNotifications.count)")
                    .foregroundStyle(.secondary)
            }
        } footer: {
            Text("Swipe a row left to cancel a specific pending notification.")
        }
    }

    // MARK: ─── Delivered Section ──────────────────────────────────────────────

    private var deliveredSection: some View {
        Section {
            if notificationManager.deliveredNotifications.isEmpty {
                emptyRow(message: "No delivered notifications")
            } else {
                ForEach(notificationManager.deliveredNotifications, id: \.request.identifier) { notification in
                    NotificationRow(
                        title: notification.request.content.title,
                        message: notification.request.content.body,
                        detail: notification.date.formatted(date: .abbreviated, time: .shortened),
                        statusColor: .green,
                        statusLabel: "Delivered"
                    )
                }
            }
        } header: {
            HStack {
                Text("Delivered")
                Spacer()
                Text("\(notificationManager.deliveredNotifications.count)")
                    .foregroundStyle(.secondary)
            }
        } footer: {
            Text("Delivered notifications remain in Notification Center until the user or app clears them.")
        }
    }

    // MARK: ─── Helpers ────────────────────────────────────────────────────────

    private func emptyRow(message: String) -> some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    /// Returns a readable description of the trigger type and fire time.
    private func triggerDetail(for trigger: UNNotificationTrigger?) -> String {
        switch trigger {
        case let t as UNTimeIntervalNotificationTrigger:
            if let next = t.nextTriggerDate() {
                return "Fires at \(next.formatted(date: .omitted, time: .shortened))"
            }
            return "In \(Int(t.timeInterval))s"

        case let t as UNCalendarNotificationTrigger:
            if let next = t.nextTriggerDate() {
                return "At \(next.formatted(date: .abbreviated, time: .shortened))"
            }
            return "Calendar trigger"

        default:
            return "Unknown trigger"
        }
    }
}

// MARK: - NotificationRow

private struct NotificationRow: View {
    let title: String
    let message: String
    let detail: String
    let statusColor: Color
    let statusLabel: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Status dot
            Circle()
                .fill(statusColor.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "bell.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(statusColor)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Text(statusLabel)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(statusColor)
                    Text("·")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(detail)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    NotificationHistoryView()
        .environmentObject(NotificationManager.shared)
}
