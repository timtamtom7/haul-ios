import SwiftUI

struct TripsListView: View {
    @EnvironmentObject var tripStore: TripStore
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingNewTrip = false
    @State private var showingPricing = false
    @State private var showingTripLimitAlert = false
    @State private var tripLimitError = false

    private var canCreateTrip: Bool {
        subscriptionManager.canCreateTrip(tripCount: tripStore.allTrips.count)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HaulTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if !tripStore.upcomingTrips.isEmpty {
                            Section {
                                ForEach(tripStore.upcomingTrips) { trip in
                                    NavigationLink(destination: PackingView(trip: trip)) {
                                        TripCardView(
                                            trip: trip,
                                            packedCount: tripStore.packedCount(for: trip.id ?? 0),
                                            totalCount: tripStore.totalCount(for: trip.id ?? 0)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            } header: {
                                SectionHeaderView(title: "Upcoming")
                            }
                        }

                        if !tripStore.pastTrips.isEmpty {
                            Section {
                                ForEach(tripStore.pastTrips) { trip in
                                    NavigationLink(destination: PackingView(trip: trip)) {
                                        TripCardView(
                                            trip: trip,
                                            packedCount: tripStore.packedCount(for: trip.id ?? 0),
                                            totalCount: tripStore.totalCount(for: trip.id ?? 0)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            } header: {
                                SectionHeaderView(title: "Past")
                            }
                        }

                        if tripStore.allTrips.isEmpty {
                            EmptyTripsView {
                                handleNewTripTap()
                            }
                        }

                        // Upgrade nudge (for free users with 1 trip)
                        if subscriptionManager.currentTier == .free,
                           tripStore.allTrips.count == 1 {
                            UpgradeNudgeCard {
                                showingPricing = true
                            }
                            .padding(.top, 8)
                        }

                        Button {
                            handleNewTripTap()
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("New Trip")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(HaulTheme.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(HaulTheme.surfaceLight.opacity(0.8))
                            .cornerRadius(12)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Haul")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingPricing = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 11))
                            Text(subscriptionManager.currentTier == .free ? "Upgrade" : subscriptionManager.currentTier.name)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(subscriptionManager.currentTier == .free ? HaulTheme.accent : HaulTheme.checkedGreen)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            (subscriptionManager.currentTier == .free ? HaulTheme.accent : HaulTheme.checkedGreen).opacity(0.1)
                        )
                        .cornerRadius(20)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                            .foregroundColor(HaulTheme.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $showingNewTrip) {
                NewTripSheet()
                    .environmentObject(tripStore)
            }
            .sheet(isPresented: $showingPricing) {
                PricingView()
            }
            .alert("Trip limit reached", isPresented: $showingTripLimitAlert) {
                Button("See Plans") {
                    showingPricing = true
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                if let maxTrips = subscriptionManager.currentTier.maxTrips {
                    Text("Your Free plan includes \(maxTrips) trips. Upgrade to Pack or Travel for unlimited trips.")
                }
            }
            .overlay {
                if tripLimitError {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture {
                                tripLimitError = false
                            }

                        TripLimitReachedView(
                            isPresented: $tripLimitError,
                            limit: subscriptionManager.currentTier.maxTrips ?? 2,
                            onShowPricing: {
                                tripLimitError = false
                                showingPricing = true
                            }
                        )
                    }
                }
            }
        }
    }

    private func handleNewTripTap() {
        if canCreateTrip {
            showingNewTrip = true
        } else {
            tripLimitError = true
        }
    }
}

// MARK: - Upgrade Nudge Card
struct UpgradeNudgeCard: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(HaulTheme.accent.opacity(0.12))
                        .frame(width: 40, height: 40)

                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(HaulTheme.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("You've got the travel bug")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(HaulTheme.textPrimary)

                    Text("Upgrade for unlimited trips & storage")
                        .font(.system(size: 12))
                        .foregroundColor(HaulTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(HaulTheme.accent)
            }
            .padding(14)
            .background(
                VisualEffectBlur(blurStyle: .systemMaterial)
            )
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(HaulTheme.accent.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct SectionHeaderView: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold, design: .default))
            .foregroundColor(HaulTheme.textSecondary)
            .tracking(1.5)
            .textCase(.uppercase)
    }
}

struct TripCardView: View {
    let trip: Trip
    let packedCount: Int
    let totalCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "suitcase.fill")
                    .foregroundColor(HaulTheme.accent)
                Text(trip.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(HaulTheme.textPrimary)
                Spacer()

                if trip.isOngoing {
                    Text("NOW")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(HaulTheme.checkedGreen)
                        .cornerRadius(4)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(HaulTheme.textSecondary)
            }

            Text(trip.displayDateRange)
                .font(.system(size: 14))
                .foregroundColor(HaulTheme.textSecondary)

            if totalCount > 0 {
                HStack(spacing: 8) {
                    ProgressView(value: Double(packedCount), total: Double(totalCount))
                        .tint(HaulTheme.checkedGreen)

                    Text("\(packedCount)/\(totalCount) packed")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(HaulTheme.textSecondary)
                }
            } else {
                Text("No items yet")
                    .font(.system(size: 12))
                    .foregroundColor(HaulTheme.textSecondary)
            }
        }
        .padding(16)
        .background(
            VisualEffectBlur(blurStyle: .systemMaterial)
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct VisualEffectBlur: UIViewRepresentable {
    let blurStyle: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
