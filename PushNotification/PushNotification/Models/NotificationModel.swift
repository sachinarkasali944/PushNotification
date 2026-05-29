//
//  NotificationModel.swift
//  PushNotification
//
//  Created for learning purposes.
//
//  PURPOSE:
//  Lightweight data models used by the demo app's UI.
//  Separating models from views keeps the code clean and testable.

import Foundation

// MARK: - TriggerType

/// Represents the four kinds of notification triggers demonstrated in this app.
///
/// Each case maps to a specific UNNotificationTrigger subclass:
/// ┌─────────────────┬────────────────────────────────────────────┐
/// │ .immediate      │ UNTimeIntervalNotificationTrigger (1 s)    │
/// │ .timeInterval   │ UNTimeIntervalNotificationTrigger (N s)    │
/// │ .calendar       │ UNCalendarNotificationTrigger              │
/// │ .actionable     │ UNTimeIntervalNotificationTrigger + category│
/// └─────────────────┴────────────────────────────────────────────┘
enum TriggerType: String, CaseIterable, Identifiable {
    case immediate   = "Immediate"
    case timeInterval = "Time Interval"
    case calendar    = "Calendar / Date"
    case actionable  = "Actionable"

    var id: String { rawValue }

    /// Human-readable explanation shown in the Home concept cards.
    var description: String {
        switch self {
        case .immediate:
            return "Fires after ~1 second using UNTimeIntervalNotificationTrigger(timeInterval: 1)."
        case .timeInterval:
            return "Fires after N seconds. Great for countdowns and delayed reminders."
        case .calendar:
            return "Fires at a specific date & time using UNCalendarNotificationTrigger."
        case .actionable:
            return "Includes custom Reply / Dismiss actions via UNNotificationCategory."
        }
    }

    var systemImage: String {
        switch self {
        case .immediate:    return "bell.fill"
        case .timeInterval: return "clock.fill"
        case .calendar:     return "calendar"
        case .actionable:   return "arrow.uturn.left.circle.fill"
        }
    }

    var accentColor: String {
        switch self {
        case .immediate:    return "blue"
        case .timeInterval: return "orange"
        case .calendar:     return "purple"
        case .actionable:   return "green"
        }
    }
}

// MARK: - Concept

/// A key concept shown on the Home screen to help learners understand the APIs.
struct NotificationConcept: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let systemImage: String
}

extension NotificationConcept {
    /// The list of concepts shown on HomeView.
    static let all: [NotificationConcept] = [
        NotificationConcept(
            title: "UNUserNotificationCenter",
            detail: "The central object for managing all notification-related activities. Always use the .current() singleton.",
            systemImage: "server.rack"
        ),
        NotificationConcept(
            title: "UNNotificationRequest",
            detail: "Combines content + trigger into a request. Each request needs a unique string identifier.",
            systemImage: "tray.and.arrow.up.fill"
        ),
        NotificationConcept(
            title: "UNMutableNotificationContent",
            detail: "The payload — title, body, sound, badge, userInfo dictionary, and optional attachment.",
            systemImage: "text.bubble.fill"
        ),
        NotificationConcept(
            title: "Triggers",
            detail: "UNTimeIntervalNotificationTrigger, UNCalendarNotificationTrigger, UNLocationNotificationTrigger.",
            systemImage: "bolt.fill"
        ),
        NotificationConcept(
            title: "UNNotificationCategory",
            detail: "Groups actions (UNNotificationAction / UNTextInputNotificationAction) into a reusable set.",
            systemImage: "list.bullet.rectangle.fill"
        ),
        NotificationConcept(
            title: "AppDelegate (APNs)",
            detail: "Needed for remote notifications: register, receive device token, and handle the remote payload.",
            systemImage: "network"
        )
    ]
}
