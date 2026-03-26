import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var tripStore: TripStore
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var notificationsEnabled = false
    @State private var showingPricing = false

    var body: some View {
        ZStack {
            HaulTheme.background
                .ignoresSafeArea()

            List {
                // Subscription section
                Section {
                    Button {
                        showingPricing = true
                    } label: {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(subscriptionManager.currentTier == .free ? HaulTheme.accent : HaulTheme.checkedGreen)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Haul \(subscriptionManager.currentTier.name)")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(HaulTheme.textPrimary)

                                if subscriptionManager.currentTier == .free {
                                    Text("Tap to upgrade")
                                        .font(.system(size: 12))
                                        .foregroundColor(HaulTheme.accent)
                                } else {
                                    Text("Your current plan")
                                        .font(.system(size: 12))
                                        .foregroundColor(HaulTheme.textSecondary)
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(HaulTheme.textSecondary)
                        }
                    }
                } header: {
                    Text("Subscription")
                }

                Section {
                    Toggle(isOn: $notificationsEnabled) {
                        HStack {
                            Image(systemName: "bell")
                                .foregroundColor(HaulTheme.accent)
                            Text("Departure Reminders")
                        }
                    }
                    .tint(HaulTheme.checkedGreen)
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Get reminded to check your bag before departure.")
                }

                Section {
                    HStack {
                        Image(systemName: "suitcase.2")
                            .foregroundColor(HaulTheme.accent)
                        VStack(alignment: .leading) {
                            Text("Total Trips")
                            Text("\(tripStore.allTrips.count)")
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(HaulTheme.textSecondary)
                        }
                    }

                    let totalItems = tripStore.allTrips.reduce(0) { $0 + tripStore.totalCount(for: $1.id ?? 0) }
                    HStack {
                        Image(systemName: "list.bullet.clipboard")
                            .foregroundColor(HaulTheme.accent)
                        VStack(alignment: .leading) {
                            Text("Total Items Tracked")
                            Text("\(totalItems)")
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(HaulTheme.textSecondary)
                        }
                    }

                    let packedItems = tripStore.allTrips.reduce(0) { $0 + tripStore.packedCount(for: $1.id ?? 0) }
                    HStack {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(HaulTheme.checkedGreen)
                        VStack(alignment: .leading) {
                            Text("Items Packed")
                            Text("\(packedItems)")
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(HaulTheme.textSecondary)
                        }
                    }
                } header: {
                    Text("Statistics")
                }

                Section {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(HaulTheme.accent)
                        Text("About Haul")
                        Spacer()
                        Text("v1.0")
                            .foregroundColor(HaulTheme.textSecondary)
                    }
                }

                Section {
                    Link(destination: URL(string: "https://www.haulapp.com/privacy")!) {
                        HStack {
                            Image(systemName: "hand.raised")
                                .foregroundColor(HaulTheme.accent)
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12))
                                .foregroundColor(HaulTheme.textSecondary)
                        }
                    }
                    .foregroundColor(HaulTheme.textPrimary)
                } header: {
                    Text("Legal")
                }

                // Reset onboarding (for testing)
                Section {
                    Button {
                        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                                .foregroundColor(.orange)
                            Text("Reset Onboarding")
                                .foregroundColor(.orange)
                        }
                    }
                } header: {
                    Text("Developer")
                } footer: {
                    Text("Resets onboarding flow on next app launch.")
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkNotificationStatus()
        }
        .sheet(isPresented: $showingPricing) {
            PricingView()
        }
    }

    private func checkNotificationStatus() {
        Task { @MainActor in
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            notificationsEnabled = settings.authorizationStatus == .authorized
        }
    }
}

import UserNotifications
