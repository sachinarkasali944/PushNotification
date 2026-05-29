//
//  HomeView.swift
//  PushNotification
//
//  Created for learning purposes.
//
//  PURPOSE:
//  The landing screen. Shows:
//  • Current permission status (with Request / Open Settings buttons)
//  • Key API concepts as readable cards
//  • All four notification trigger types with descriptions

import SwiftUI
import UIKit

struct HomeView: View {

    @EnvironmentObject private var notificationManager: NotificationManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    permissionSection
                    conceptSection
                    triggerTypesSection
                }
                .padding()
            }
            .navigationTitle("Push Notifications")
            .navigationBarTitleDisplayMode(.large)
            .onAppear { notificationManager.refreshAuthorizationStatus() }
        }
    }

    // MARK: ─── Permission Status ──────────────────────────────────────────────

    private var permissionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Permission Status", icon: "shield.lefthalf.filled")

            HStack(spacing: 10) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)

                Text(statusText)
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                Spacer()

                permissionActionButton
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Extra tip for denied state
            if notificationManager.authorizationStatus == .denied {
                Label(
                    "iOS only shows the permission dialog once. Use Settings → Notifications to re-enable.",
                    systemImage: "info.circle.fill"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var permissionActionButton: some View {
        switch notificationManager.authorizationStatus {
        case .notDetermined:
            Button("Request Permission") {
                Task { await notificationManager.requestPermission() }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)

        case .denied:
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

        default:
            EmptyView()
        }
    }

    // MARK: ─── Key Concepts ───────────────────────────────────────────────────

    private var conceptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Key APIs", icon: "book.fill")

            ForEach(NotificationConcept.all) { concept in
                ConceptCard(concept: concept)
            }
        }
    }

    // MARK: ─── Trigger Types ──────────────────────────────────────────────────

    private var triggerTypesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Notification Trigger Types", icon: "bolt.fill")

            VStack(spacing: 0) {
                ForEach(Array(TriggerType.allCases.enumerated()), id: \.element.id) { index, type in
                    HStack(spacing: 14) {
                        Image(systemName: type.systemImage)
                            .foregroundStyle(.blue)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(type.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(type.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 10)

                    if index < TriggerType.allCases.count - 1 {
                        Divider()
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: ─── Helpers ────────────────────────────────────────────────────────

    private func sectionHeader(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.headline)
    }

    private var statusColor: Color {
        switch notificationManager.authorizationStatus {
        case .authorized, .provisional: return .green
        case .denied:                   return .red
        default:                        return .orange
        }
    }

    private var statusText: String {
        switch notificationManager.authorizationStatus {
        case .authorized:    return "Authorized — notifications enabled"
        case .denied:        return "Denied — enable in Settings"
        case .provisional:   return "Provisional — quiet delivery only"
        case .notDetermined: return "Not yet requested"
        default:             return "Unknown status"
        }
    }
}

// MARK: - ConceptCard

private struct ConceptCard: View {
    let concept: NotificationConcept

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: concept.systemImage)
                .foregroundStyle(.blue)
                .frame(width: 24)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(concept.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
                Text(concept.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .environmentObject(NotificationManager.shared)
}
