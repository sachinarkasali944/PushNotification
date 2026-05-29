//
//  NotificationManager.swift
//  PushNotification
//
//  Created for learning purposes.
//
//  PURPOSE:
//  This is the single source of truth for all notification-related work.
//  It wraps UNUserNotificationCenter and exposes a clean @Published API
//  that SwiftUI views can observe.
//
//  WHAT THIS COVERS:
//  • Requesting notification permission
//  • Scheduling: immediate, time-interval, calendar, and actionable notifications
//  • Cancelling pending notifications
//  • Fetching lists of pending & delivered notifications
//  • Handling foreground presentation and user interaction via the delegate
//  • Registering custom action categories (for actionable notifications)

import Combine
import UserNotifications
import UIKit

// MARK: - NotificationManager

/// A singleton ObservableObject that manages the full notification lifecycle.
final class NotificationManager: NSObject, ObservableObject {

    // MARK: Shared Instance
    static let shared = NotificationManager()

    // MARK: Published State (SwiftUI observes these)
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var pendingNotifications: [UNNotificationRequest] = []
    @Published var deliveredNotifications: [UNNotification] = []

    // MARK: Private
    private let center = UNUserNotificationCenter.current()

    private override init() {
        super.init()
        // Set self as delegate so we receive foreground/interaction callbacks
        center.delegate = self
        refreshAuthorizationStatus()
    }

    // MARK: ─── Permission ─────────────────────────────────────────────────────

    /// Requests authorization for alerts, sounds, and badge updates.
    /// Returns `true` if the user granted permission.
    ///
    /// iOS will only show the system permission dialog once. After that,
    /// repeated calls simply return the current status without a dialog.
    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run { refreshAuthorizationStatus() }
            return granted
        } catch {
            print("❌ Permission request error: \(error)")
            return false
        }
    }

    /// Reads the current authorization status and publishes the result.
    func refreshAuthorizationStatus() {
        center.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.authorizationStatus = settings.authorizationStatus
            }
        }
    }

    // MARK: ─── Schedule: Immediate ────────────────────────────────────────────

    /// Fires a notification after 1 second.
    ///
    /// Why 1 second and not 0?
    /// UNTimeIntervalNotificationTrigger requires timeInterval > 0.
    func scheduleImmediateNotification(title: String, body: String, badge: Int? = nil) {
        let content = makeContent(title: title, body: body, badge: badge)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        schedule(content: content, trigger: trigger)
    }

    // MARK: ─── Schedule: Time Interval ────────────────────────────────────────

    /// Fires a notification after `seconds` seconds have elapsed.
    ///
    /// Typical use: reminders like "remind me in 10 minutes".
    func scheduleTimeIntervalNotification(title: String, body: String, after seconds: TimeInterval) {
        let content = makeContent(title: title, body: body)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        schedule(content: content, trigger: trigger)
    }

    // MARK: ─── Schedule: Calendar ─────────────────────────────────────────────

    /// Fires a notification at a specific `date`.
    ///
    /// Converts the Date into DateComponents and creates a
    /// UNCalendarNotificationTrigger. Useful for alarm-clock-style reminders.
    func scheduleCalendarNotification(title: String, body: String, date: Date) {
        let content = makeContent(title: title, body: body)
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        schedule(content: content, trigger: trigger)
    }

    // MARK: ─── Schedule: Actionable ───────────────────────────────────────────

    /// Fires a notification that has custom actions (Reply / Dismiss).
    ///
    /// The `categoryIdentifier` must match a registered UNNotificationCategory.
    /// See `registerCategories()` below.
    func scheduleActionableNotification(title: String, body: String, categoryIdentifier: String) {
        let content = makeContent(title: title, body: body)
        content.categoryIdentifier = categoryIdentifier
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        schedule(content: content, trigger: trigger)
    }

    // MARK: ─── Cancel ─────────────────────────────────────────────────────────

    /// Removes all pending & delivered notifications and refreshes the lists.
    func cancelAll() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
        refreshLists()
    }

    /// Cancels a single pending notification by its identifier.
    func cancelPending(identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        refreshLists()
    }

    // MARK: ─── Fetch Lists ─────────────────────────────────────────────────────

    /// Refreshes both `pendingNotifications` and `deliveredNotifications`.
    func refreshLists() {
        center.getPendingNotificationRequests { [weak self] requests in
            DispatchQueue.main.async { self?.pendingNotifications = requests }
        }
        center.getDeliveredNotifications { [weak self] notifications in
            DispatchQueue.main.async { self?.deliveredNotifications = notifications }
        }
    }

    // MARK: ─── Custom Categories (Actionable Notifications) ───────────────────

    /// Registers the custom notification categories (action sets) with the system.
    ///
    /// Must be called once at app launch (in AppDelegate.didFinishLaunching)
    /// BEFORE any actionable notifications are displayed.
    func registerCategories() {
        // Text input action: user can type a reply directly from the banner
        let replyAction = UNTextInputNotificationAction(
            identifier: NotificationActionID.reply,
            title: "Reply",
            options: [],
            textInputButtonTitle: "Send",
            textInputPlaceholder: "Type your reply…"
        )

        // Destructive action: shown in red on the notification banner
        let dismissAction = UNNotificationAction(
            identifier: NotificationActionID.dismiss,
            title: "Dismiss",
            options: [.destructive]
        )

        // Category ties multiple actions to a `categoryIdentifier` string
        let messageCategory = UNNotificationCategory(
            identifier: NotificationCategoryID.message,
            actions: [replyAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([messageCategory])
    }

    // MARK: ─── Private Helpers ────────────────────────────────────────────────

    private func makeContent(
        title: String,
        body: String,
        badge: Int? = nil
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        if let badge {
            content.badge = NSNumber(value: badge)
        }
        return content
    }

    private func schedule(
        content: UNMutableNotificationContent,
        trigger: UNNotificationTrigger,
        identifier: String = UUID().uuidString
    ) {
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        center.add(request) { [weak self] error in
            if let error {
                print("❌ Schedule error: \(error)")
            }
            self?.refreshLists()
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {

    /// Called when a notification arrives while the app is in the foreground.
    ///
    /// Without this, iOS suppresses the banner when the app is open.
    /// Returning `.banner` makes the notification visible in-app too.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
        refreshLists()
    }

    /// Called when the user taps the notification or selects an action.
    ///
    /// `response.actionIdentifier` tells you what the user did:
    ///  • UNNotificationDefaultActionIdentifier  → user tapped the banner
    ///  • UNNotificationDismissActionIdentifier  → user swiped/dismissed
    ///  • custom ID                              → user tapped your custom action
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionID = response.actionIdentifier
        let notifID  = response.notification.request.identifier

        switch actionID {
        case UNNotificationDefaultActionIdentifier:
            print("ℹ️ User opened app from notification: \(notifID)")

        case UNNotificationDismissActionIdentifier:
            print("ℹ️ User dismissed notification: \(notifID)")

        case NotificationActionID.reply:
            if let textResponse = response as? UNTextInputNotificationResponse {
                print("💬 User replied: \(textResponse.userText)")
            }

        case NotificationActionID.dismiss:
            print("🗑️ User chose destructive dismiss")

        default:
            break
        }

        refreshLists()
        completionHandler()
    }
}

// MARK: - Constants

/// String identifiers for notification action buttons.
enum NotificationActionID {
    static let reply   = "REPLY_ACTION"
    static let dismiss = "DISMISS_ACTION"
}

/// String identifiers for notification categories (groups of actions).
enum NotificationCategoryID {
    static let message = "MESSAGE_CATEGORY"
}
