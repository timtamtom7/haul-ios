import SwiftUI

// MARK: - Pricing View
struct PricingView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedTier: SubscriptionTier = .free
    @State private var showConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                HaulTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Choose your plan")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(HaulTheme.textPrimary)

                            Text("Start free. Upgrade when you're ready.")
                                .font(.system(size: 15))
                                .foregroundColor(HaulTheme.textSecondary)
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 4)

                        // Tier cards
                        ForEach(SubscriptionTier.allCases, id: \.self) { tier in
                            PricingTierCard(
                                tier: tier,
                                isSelected: selectedTier == tier,
                                onSelect: {
                                    if tier == .free {
                                        confirmSelection(tier)
                                    } else {
                                        selectedTier = tier
                                    }
                                }
                            )
                        }

                        // Current plan info
                        VStack(spacing: 6) {
                            Text("You're on the **Free** plan")
                                .font(.system(size: 14))
                                .foregroundColor(HaulTheme.textSecondary)

                            Text("2 trips · 20 items per trip")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(HaulTheme.textSecondary.opacity(0.7))
                        }
                        .padding(.top, 4)

                        // Selected tier action
                        if selectedTier != .free {
                            VStack(spacing: 12) {
                                Button {
                                    showConfirmation = true
                                } label: {
                                    Text("Continue with \(selectedTier.name)")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 15)
                                        .background(selectedTier.accentColor)
                                        .cornerRadius(12)
                                }

                                Text("Cancel anytime. Billed monthly.")
                                    .font(.system(size: 12))
                                    .foregroundColor(HaulTheme.textSecondary)
                            }
                            .padding(.top, 8)
                        }

                        // Restore purchases
                        Button {
                            // Restore logic would go here
                        } label: {
                            Text("Restore Purchases")
                                .font(.system(size: 13))
                                .foregroundColor(HaulTheme.textSecondary)
                        }
                        .padding(.top, 4)

                        // Legal footnotes
                        VStack(spacing: 4) {
                            Text("Subscriptions auto-renew unless cancelled 24h before the period ends. Manage subscriptions in Settings.")
                                .font(.system(size: 11))
                                .foregroundColor(HaulTheme.textSecondary.opacity(0.6))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Haul Plus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(HaulTheme.textSecondary)
                            .font(.system(size: 22))
                    }
                }
            }
            .alert("Switch to \(selectedTier.name)?", isPresented: $showConfirmation) {
                Button("Continue", role: .none) {
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                if selectedTier == .pack {
                    Text("Pack gives you unlimited trips, unlimited items, and photo storage. You'll be billed $2.99/month.")
                } else {
                    Text("Travel gives you everything in Pack, plus multiple suitcases, packing templates, and weather at your destination. You'll be billed $5.99/month.")
                }
            }
        }
    }

    private func confirmSelection(_ tier: SubscriptionTier) {
        dismiss()
    }
}

// MARK: - Pricing Tier Card
struct PricingTierCard: View {
    let tier: SubscriptionTier
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 0) {
                // Top section: icon + name + price
                HStack(alignment: .top) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(tier.accentColor.opacity(0.12))
                            .frame(width: 44, height: 44)

                        Image(systemName: tier.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(tier.accentColor)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(tier.name)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(HaulTheme.textPrimary)

                            if tier == .travel {
                                Text("BEST")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(HaulTheme.checkedGreen)
                                    .cornerRadius(4)
                            }

                            if tier == .pack {
                                Text("POPULAR")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(HaulTheme.accent)
                                    .cornerRadius(4)
                            }
                        }

                        Text(tier.tagline)
                            .font(.system(size: 13))
                            .foregroundColor(HaulTheme.textSecondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(tier.price)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(tier.accentColor)

                        if tier == .free {
                            Text("Forever")
                                .font(.system(size: 11))
                                .foregroundColor(HaulTheme.textSecondary)
                        }
                    }
                }
                .padding(18)

                Divider()
                    .background(HaulTheme.unchecked.opacity(0.5))

                // Features
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(tier.features, id: \.self) { feature in
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(tier.accentColor)
                                .frame(width: 16)

                            Text(feature)
                                .font(.system(size: 13))
                                .foregroundColor(HaulTheme.textPrimary)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(HaulTheme.surfaceLight)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? tier.accentColor : HaulTheme.unchecked.opacity(0.3),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(
                color: isSelected ? tier.accentColor.opacity(0.12) : .black.opacity(0.04),
                radius: isSelected ? 12 : 6,
                x: 0,
                y: isSelected ? 6 : 3
            )
            .scaleEffect(isSelected ? 1.01 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}
