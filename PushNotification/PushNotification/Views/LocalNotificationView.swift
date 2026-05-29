//
//  LocalNotificationView.swift
//  PushNotification
//
//  Created for learning purposes.
//
//  PURPOSE:
//  Demonstrates the simplest notification — fire immediately (after 1 s)
//  and actionable notifications with Reply / Dismiss buttons.
//
//  KEY LEARNING POINTS:
//  1. UNMutableNotificationContent  — building the payload
//  2. UNTimeIntervalNotificationTrigger(timeInterval: 1) — the trigger
//  3. UNNotificationRequest          — combining content + trigger
//  4. UNNotificationCategory         — enabling action buttons on banners
//  5. UNTextInputNotificationAction  — inline text reply from the banner

import SwiftUI

struct LocalNotificationView: View {

    @EnvironmentObject private var notificationManager: NotificationManager

    @State private var titleText = "Hello 👋"
    @State private var bodyText  = "This is your first local notification!"
    @State private var showAlert  = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationStack {
            Form {

                // ── Compose ────────────────────────────────────────────────
                Section {
                    TextField("Title", text: $titleText)
                    TextField("Body", text: $bodyText)
                } header: {
                    Text("Compose Notification")
                } footer: {
                    Text("These values fill UNMutableNotificationContent.title and .body")
                }

                // ── Actions ────────────────────────────────────────────────
                Section("Send") {
                    Button {
                        sendImmediate()
                    } label: {
                        Label("Send Immediate (~1 s)", systemImage: "bell.fill")
                    }
                    .disabled(!isAuthorized)

                    Button {
                        sendActionable()
                    } label: {
                        Label("Send with Reply & Dismiss Actions", systemImage: "arrow.uturn.left.circle.fill")
                    }
                    .disabled(!isAuthorized)
                }

                // ── Warning ────────────────────────────────────────────────
                if !isAuthorized {
                    Section {
                        Label(
                            "Notifications are not authorized. Go to the Home tab to request permission.",
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .foregroundStyle(.orange)
                        .font(.caption)
                    }
                }

                // ── Tip ────────────────────────────────────────────────────
                Section {
                    InfoBox(text: "Background the app after tapping Send. The notification banner appears after ~1 second.")
                }

                // ── Code Walkthrough ───────────────────────────────────────
                Section("Code Walkthrough") {
                    CodeSnippetView(code: immediateCode, title: "Immediate Notification")
                    CodeSnippetView(code: actionableCode, title: "Actionable Notification")
                }
            }
            .navigationTitle("Local Notification")
            .alert("Scheduled ✅", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    // MARK: ─── Actions ────────────────────────────────────────────────────────

    private func sendImmediate() {
        let t = titleText.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        notificationManager.scheduleImmediateNotification(title: t, body: bodyText)
        alertMessage = "'\(t)' fires in ~1 second.\n\nBackground the app to see the banner."
        showAlert = true
    }

    private func sendActionable() {
        notificationManager.scheduleActionableNotification(
            title: "You have a message 📩",
            body: "Long-press the banner to Reply or Dismiss.",
            categoryIdentifier: NotificationCategoryID.message
        )
        alertMessage = "Actionable notification fires in 3 seconds.\n\nBackground the app, then long-press the banner to see the Reply/Dismiss actions."
        showAlert = true
    }

    // MARK: ─── Helpers ────────────────────────────────────────────────────────

    private var isAuthorized: Bool {
        notificationManager.authorizationStatus == .authorized ||
        notificationManager.authorizationStatus == .provisional
    }

    // MARK: ─── Code Samples ───────────────────────────────────────────────────

    private let immediateCode = """
// 1. Build the payload
let content = UNMutableNotificationContent()
content.title = "Hello 👋"
content.body  = "This is a local notification!"
content.sound = .default

// 2. Create the trigger (must be > 0 seconds)
let trigger = UNTimeIntervalNotificationTrigger(
    timeInterval: 1,
    repeats: false
)

// 3. Wrap into a request
let request = UNNotificationRequest(
    identifier: UUID().uuidString,
    content: content,
    trigger: trigger
)

// 4. Schedule it
UNUserNotificationCenter.current().add(request)
"""

    private let actionableCode = """
// Register the category once at app launch (AppDelegate)
let replyAction = UNTextInputNotificationAction(
    identifier: "REPLY_ACTION",
    title: "Reply",
    options: [],
    textInputButtonTitle: "Send",
    textInputPlaceholder: "Type here…"
)
let dismissAction = UNNotificationAction(
    identifier: "DISMISS_ACTION",
    title: "Dismiss",
    options: [.destructive]
)
let category = UNNotificationCategory(
    identifier: "MESSAGE_CATEGORY",
    actions: [replyAction, dismissAction],
    intentIdentifiers: []
)
UNUserNotificationCenter.current()
    .setNotificationCategories([category])

// Then attach the category to content
content.categoryIdentifier = "MESSAGE_CATEGORY"
"""
}

// MARK: - InfoBox

struct InfoBox: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(.yellow)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - CodeSnippetView

struct CodeSnippetView: View {
    let code: String
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(.caption, design: .monospaced))
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

// MARK: - Preview

#Preview {
    LocalNotificationView()
        .environmentObject(NotificationManager.shared)
}
