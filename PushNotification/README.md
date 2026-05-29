# iOS Push Notifications — Learning Demo

> A structured, well-commented SwiftUI project that walks you through **every layer** of iOS push notifications — from requesting permission to handling APNs remote payloads.

---

## Table of Contents

1. [What Are Push Notifications?](#1-what-are-push-notifications)
2. [Local vs Remote Notifications](#2-local-vs-remote-notifications)
3. [Key APIs](#3-key-apis)
4. [Project Structure](#4-project-structure)
5. [App Walkthrough](#5-app-walkthrough)
6. [How to Run](#6-how-to-run)
7. [Going Further — Remote (APNs) Notifications](#7-going-further--remote-apns-notifications)
8. [Common Pitfalls](#8-common-pitfalls)
9. [Quick Reference](#9-quick-reference)

---

## 1. What Are Push Notifications?

A **push notification** is a message that an app can deliver to the user even when the app is not in the foreground. iOS uses them for:

- Alerts, banners, and lock-screen messages
- Badge count updates on the app icon
- Sounds and haptics
- Background content-available payloads (silent push)

There are **two categories**:

| Category | Delivered by | Requires server? | Works on Simulator? |
|---|---|---|---|
| **Local** | The app itself | ✗ No | ✓ Yes |
| **Remote** | Apple Push Notification service (APNs) | ✓ Yes | ✗ No* |

> *Remote notifications need a physical device with a valid APNs token.

---

## 2. Local vs Remote Notifications

### Local Notifications

Scheduled entirely on-device. The app uses `UNUserNotificationCenter` to schedule a notification with a trigger (time, calendar, or location). iOS fires it at the right moment — even after the app is killed.

```
App → UNUserNotificationCenter → iOS → Notification Banner
```

### Remote Notifications

Sent from your server through Apple's APNs infrastructure. The device must be registered and online to receive them.

```
Your Server → APNs → iPhone → Notification Banner / Silent Background Fetch
```

The **payload** is a JSON object (max 4 KB):

```json
{
  "aps": {
    "alert": {
      "title": "New message",
      "body": "Hey, check this out!"
    },
    "sound": "default",
    "badge": 1,
    "content-available": 1
  },
  "custom_key": "custom_value"
}
```

---

## 3. Key APIs

### `UNUserNotificationCenter`

The single entry point for all notification operations.

```swift
let center = UNUserNotificationCenter.current()
```

| Method | Purpose |
|---|---|
| `requestAuthorization(options:)` | Prompt user for permission |
| `add(_:withCompletionHandler:)` | Schedule a notification |
| `getPendingNotificationRequests` | List scheduled-but-unfired notifications |
| `getDeliveredNotifications` | List notifications in Notification Center |
| `removePendingNotificationRequests(withIdentifiers:)` | Cancel specific pending notifications |
| `removeAllDeliveredNotifications()` | Clear Notification Center |
| `setNotificationCategories(_:)` | Register action categories |

---

### `UNMutableNotificationContent`

The payload of a notification.

```swift
let content = UNMutableNotificationContent()
content.title    = "Meeting Reminder"
content.subtitle = "Team Standup"          // optional
content.body     = "Starting in 5 minutes"
content.sound    = .default
content.badge    = 1                       // app icon badge number
content.userInfo = ["meetingId": "abc123"] // custom data
content.categoryIdentifier = "MEETING"    // for actionable notifications
```

---

### Triggers

**`UNTimeIntervalNotificationTrigger`** — fires after N seconds:

```swift
// One-shot: fire after 10 seconds
let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)

// Recurring: fire every hour
let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: true)
```

**`UNCalendarNotificationTrigger`** — fires at a specific date/time:

```swift
// Fire at a specific moment
var components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

// Fire every day at 9 AM
let trigger = UNCalendarNotificationTrigger(
    dateMatching: DateComponents(hour: 9, minute: 0),
    repeats: true
)
```

**`UNLocationNotificationTrigger`** — fires when entering/leaving a region:

```swift
import CoreLocation
let region = CLCircularRegion(center: coordinate, radius: 100, identifier: "office")
region.notifyOnEntry = true
let trigger = UNLocationNotificationTrigger(region: region, repeats: false)
```

---

### `UNNotificationRequest`

Wraps content + trigger with a unique identifier.

```swift
let request = UNNotificationRequest(
    identifier: UUID().uuidString,  // must be unique; use a meaningful ID for cancellation
    content: content,
    trigger: trigger
)
UNUserNotificationCenter.current().add(request) { error in
    if let error { print("Error: \(error)") }
}
```

---

### Actionable Notifications

Attach buttons to the notification banner:

```swift
// 1. Define actions
let replyAction = UNTextInputNotificationAction(
    identifier: "REPLY", title: "Reply",
    options: [],
    textInputButtonTitle: "Send", textInputPlaceholder: "Type…"
)
let deleteAction = UNNotificationAction(
    identifier: "DELETE", title: "Delete", options: [.destructive]
)

// 2. Group into a category
let category = UNNotificationCategory(
    identifier: "MESSAGE",
    actions: [replyAction, deleteAction],
    intentIdentifiers: []
)

// 3. Register (do this ONCE at app launch)
UNUserNotificationCenter.current().setNotificationCategories([category])

// 4. Attach the category to content
content.categoryIdentifier = "MESSAGE"
```

---

### `UNUserNotificationCenterDelegate`

Two critical callbacks:

```swift
// Called when notification arrives IN THE FOREGROUND
// Without this, iOS silently drops the banner when the app is open
func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
) {
    completionHandler([.banner, .sound, .badge])
}

// Called when user taps or interacts with the notification
func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
) {
    switch response.actionIdentifier {
    case UNNotificationDefaultActionIdentifier:
        // User tapped the banner body
    case "REPLY":
        let text = (response as? UNTextInputNotificationResponse)?.userText
    default:
        break
    }
    completionHandler()
}
```

---

## 4. Project Structure

```
PushNotification/
├── PushNotificationApp.swift       ← @main entry, AppDelegate, EnvironmentObject injection
├── ContentView.swift               ← TabView that hosts all demo screens
│
├── Managers/
│   └── NotificationManager.swift  ← Singleton ObservableObject wrapping UNUserNotificationCenter
│
├── Models/
│   └── NotificationModel.swift    ← TriggerType enum, NotificationConcept model
│
└── Views/
    ├── HomeView.swift              ← Permission status, key API concepts, trigger types overview
    ├── LocalNotificationView.swift ← Immediate & actionable notification demos
    ├── ScheduledNotificationView.swift ← Time-interval & calendar trigger demos
    └── NotificationHistoryView.swift   ← Pending & delivered notification lists
```

### Design Decisions

| Decision | Reason |
|---|---|
| `NotificationManager` is a singleton `@ObservableObject` | Lets any view in the hierarchy observe notification state without prop drilling |
| `.environmentObject(NotificationManager.shared)` at root | SwiftUI best-practice for shared app-wide state |
| `AppDelegate` via `@UIApplicationDelegateAdaptor` | The only way to receive APNs device token and background remote payloads in SwiftUI |
| Code snippets embedded in views | Learners can see the API right next to the live demo |

---

## 5. App Walkthrough

### Tab 1 — Home

- Shows current notification permission status
- **Request Permission** button triggers `UNUserNotificationCenter.requestAuthorization`
- If denied, **Open Settings** button deep-links to the app's Settings page
- Lists all six key notification APIs as concept cards
- Summarises all four trigger types

### Tab 2 — Local

- Text fields let you customise the notification title and body
- **Send Immediate** — fires a `UNTimeIntervalNotificationTrigger(timeInterval: 1)` notification
- **Send with Actions** — fires an actionable notification; long-press the banner to see Reply/Dismiss buttons
- Inline code snippets show the exact Swift code behind each action

### Tab 3 — Scheduled

- Segmented picker → schedule a notification after 5 / 10 / 30 / 60 seconds
- Date picker → schedule a notification at an exact future date and time
- Inline code snippets compare the two trigger types

### Tab 4 — History

- **Pending** section — all scheduled-but-unfired notifications (swipe left to cancel one)
- **Delivered** section — notifications already shown to the user
- Toolbar **Refresh** and **Clear All** buttons

---

## 6. How to Run

### Prerequisites

- Xcode 15 or later
- iOS 17 Simulator or a physical device running iOS 16+

### Steps

1. Open `PushNotification.xcodeproj` in Xcode.
2. **Add new files to the target** — the source files created in this project live in the following new groups and must be added to the `PushNotification` target:
   - `Managers/NotificationManager.swift`
   - `Models/NotificationModel.swift`
   - `Views/HomeView.swift`
   - `Views/LocalNotificationView.swift`
   - `Views/ScheduledNotificationView.swift`
   - `Views/NotificationHistoryView.swift`

   **How to add:** In Xcode's Project Navigator, right-click the `PushNotification` group → **Add Files to "PushNotification"** → select the folders/files → ensure **"Add to target: PushNotification"** is checked.

3. Select a Simulator target (e.g. iPhone 16) and press **Run (⌘R)**.
4. On first launch, tap **Request Permission** on the Home tab.
5. Trigger a notification from the Local or Scheduled tab, then **background the app** (press Home / swipe up) to see the banner.

> **Note:** Local notifications work fine on the Simulator. Remote (APNs) notifications require a physical device and a server backend.

---

## 7. Going Further — Remote (APNs) Notifications

To add real remote notification support:

### Step 1 — Enable the capability

In Xcode: **Project → Target → Signing & Capabilities → + Capability → Push Notifications**.

### Step 2 — Register at launch

In `AppDelegate.didFinishLaunchingWithOptions`, uncomment:

```swift
application.registerForRemoteNotifications()
```

### Step 3 — Receive the device token

```swift
func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
) {
    let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    // Send token to your backend
    MyAPI.shared.registerDeviceToken(token)
}
```

### Step 4 — Send a push from your server

Use any APNs-compatible library (e.g. `apns2` in Node.js, `PyAPNs2` in Python, or Firebase Cloud Messaging) with the device token to send:

```json
{
  "aps": {
    "alert": { "title": "Hello", "body": "Remote push works!" },
    "sound": "default"
  }
}
```

### Step 5 — Handle the background payload

If your payload includes `"content-available": 1`, iOS wakes the app silently:

```swift
func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
) {
    // Fetch new data here
    completionHandler(.newData)
}
```

---

## 8. Common Pitfalls

| Pitfall | Fix |
|---|---|
| `timeInterval` must be > 0 | Use at least 1 second for immediate notifications |
| Permission dialog shown only once | After denial, guide user to **Settings → Notifications** |
| `willPresent` delegate not set | Without the delegate, banners are suppressed when the app is open |
| `registerCategories()` called after scheduling | Always register categories at app launch, before any notification fires |
| APNs token is `nil` on Simulator | Test remote notifications on a physical device only |
| Forgetting to call `completionHandler()` | iOS may terminate the app if the completion handler is never called |
| Identifier reuse | Using the same identifier for two requests silently replaces the first one |

---

## 9. Quick Reference

```swift
// ─── Permission ────────────────────────────────────────────────────────────
let granted = try await UNUserNotificationCenter.current()
    .requestAuthorization(options: [.alert, .sound, .badge])

// ─── Schedule ──────────────────────────────────────────────────────────────
let content   = UNMutableNotificationContent()
content.title = "Reminder"
content.body  = "Don't forget!"
content.sound = .default

let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
let request = UNNotificationRequest(identifier: UUID().uuidString,
                                    content: content, trigger: trigger)
try await UNUserNotificationCenter.current().add(request)

// ─── Cancel ────────────────────────────────────────────────────────────────
UNUserNotificationCenter.current()
    .removePendingNotificationRequests(withIdentifiers: ["myID"])

// ─── List pending ──────────────────────────────────────────────────────────
let pending = await UNUserNotificationCenter.current()
    .pendingNotificationRequests()
```

---

## License

MIT — free to use for learning and personal projects.
