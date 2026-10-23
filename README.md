# iOS Notifications Lab

> Explore notification permissions, local scheduling, actions, and delivery.

A SwiftUI learning project organised around notification authorisation, immediate local notifications, scheduled notifications, and notification history.

## Highlights

- Request permission and inspect authorisation state.
- Compose and schedule local notifications.
- Explore notification actions and UNUserNotificationCenter APIs.
- Read the accompanying walkthrough of remote APNs integration.

## Open and run

1. Clone this repository and open `PushNotification/PushNotification.xcodeproj` in Xcode.
2. Select the app scheme and a simulator compatible with the deployment target in **Build Settings → iOS Deployment Target**. Use an Xcode version with SDK support for that target.
3. Build and run with **⌘R**. For a physical device, select your development team.

```bash
git clone https://github.com/sachinarkasali944/PushNotification.git
cd PushNotification
open "PushNotification/PushNotification.xcodeproj"
```

## Demo scope

Local notification scenarios can be explored independently. Remote push delivery requires your own APNs configuration, signing capabilities, and provider; a production push backend is not included.

## Explore the code

- [Xcode project](./PushNotification/PushNotification.xcodeproj)
- [Project files](./PushNotification)

## Further reading

[Read the detailed implementation guide](./PushNotification/README.md).
