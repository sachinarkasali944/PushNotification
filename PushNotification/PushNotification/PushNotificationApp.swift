//
//  PushNotificationApp.swift
//  PushNotification
//
//  App entry point.
//  - Injects NotificationManager as an EnvironmentObject so every view can
//    observe notification state without passing it down manually.
//  - Uses @UIApplicationDelegateAdaptor to hook AppDelegate for remote
//    (APNs) notification registration callbacks.

import SwiftUI
import UIKit

@main
struct PushNotificationApp: App {

    /// Bridge to UIKit's AppDelegate lifecycle (required for APNs token handling).
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Make NotificationManager available to the entire view hierarchy
                .environmentObject(NotificationManager.shared)
        }
    }
}

// MARK: - AppDelegate

/// Handles UIKit application lifecycle events.
///
/// For LOCAL notifications only, AppDelegate is not strictly required.
/// It becomes essential for REMOTE (APNs) notifications because:
///   1. You must call application.registerForRemoteNotifications()
///   2. iOS delivers the device token here
///   3. Background remote notification payloads arrive here
class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Register custom notification categories (action buttons) once at launch
        NotificationManager.shared.registerCategories()

        // ─── Remote notifications (uncomment to enable) ───────────────────
        // Calling this prompts iOS to register with APNs.
        // On success, didRegisterForRemoteNotificationsWithDeviceToken is called.
        // application.registerForRemoteNotifications()
        // ─────────────────────────────────────────────────────────────────

        return true
    }

    // MARK: Remote Registration Callbacks

    /// APNs registration succeeded.
    ///
    /// The `deviceToken` uniquely identifies this device+app combination.
    /// Send it to YOUR backend server so it can push notifications to this device.
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Convert binary token to hex string
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("✅ APNs device token: \(token)")
        // TODO: POST this token to your server endpoint
    }

    /// APNs registration failed.
    ///
    /// Common reasons:
    ///  • Running on Simulator (simulators cannot register for remote notifications)
    ///  • No network connection
    ///  • Missing Push Notification capability in the Xcode project
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("❌ APNs registration failed: \(error)")
    }

    /// Called when a remote notification arrives while the app is in the BACKGROUND
    /// and the payload includes `content-available: 1`.
    ///
    /// You have up to ~30 seconds to fetch data, then MUST call completionHandler.
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        print("📩 Remote notification payload: \(userInfo)")
        // Process the payload, update local data, then call the handler
        completionHandler(.newData)
    }
}
