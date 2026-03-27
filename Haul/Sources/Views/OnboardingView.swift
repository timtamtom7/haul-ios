import SwiftUI
import UIKit

struct OnboardingContainerView: View {
    let onComplete: () -> Void
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            HaulTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    OnboardingPage1()
                        .tag(0)

                    OnboardingPage2()
                        .tag(1)

                    OnboardingPage3()
                        .tag(2)

                    OnboardingPage4(onComplete: onComplete)
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // Bottom controls
                VStack(spacing: 20) {
                    // Page dots
                    HStack(spacing: 8) {
                        ForEach(0..<4, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? HaulTheme.accent : HaulTheme.unchecked)
                                .frame(width: 8, height: 8)
                                .scaleEffect(index == currentPage ? 1.2 : 1.0)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }

                    // Navigation buttons
                    HStack(spacing: 16) {
                        if currentPage > 0 {
                            Button("Back") {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentPage -= 1
                                }
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(HaulTheme.textSecondary)
                        }

                        Spacer()

                        if currentPage < 3 {
                            Button {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentPage += 1
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Text(currentPage == 0 ? "Let's go" : "Next")
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 14)
                                .background(HaulTheme.accent)
                                .cornerRadius(12)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            HaulHaptics.shared.warm()
        }
    }
}

// MARK: - Screen 1: "Never forget"
struct OnboardingPage1: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Custom illustration: Suitcase with tag
            ZStack {
                // Background circle - warm linen
                Circle()
                    .fill(HaulTheme.accent.opacity(0.08))
                    .frame(width: 220, height: 220)

                // Suitcase body
                VStack(spacing: 0) {
                    // Handle
                    RoundedRectangle(cornerRadius: 6)
                        .fill(HaulTheme.accentDark)
                        .frame(width: 50, height: 12)
                        .offset(y: -2)

                    // Main body
                    RoundedRectangle(cornerRadius: 12)
                        .fill(HaulTheme.accent)
                        .frame(width: 120, height: 90)
                        .overlay(
                            VStack(spacing: 8) {
                                // Suitcase ridges
                                ForEach(0..<3, id: \.self) { _ in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(HaulTheme.accentDark.opacity(0.3))
                                        .frame(width: 80, height: 6)
                                }
                            }
                        )
                        .overlay(
                            // Tag
                            VStack(spacing: 2) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(HaulTheme.backgroundDark)
                                    .frame(width: 30, height: 22)
                                    .overlay(
                                        VStack(spacing: 1) {
                                            ForEach(0..<3, id: \.self) { _ in
                                                RoundedRectangle(cornerRadius: 1)
                                                    .fill(HaulTheme.accent)
                                                    .frame(width: 18, height: 2)
                                            }
                                        }
                                    )
                                    .offset(x: 45, y: -30)
                                    .rotationEffect(.degrees(12))

                                // Tag string
                                Rectangle()
                                    .fill(HaulTheme.accentDark)
                                    .frame(width: 2, height: 12)
                                    .offset(x: 45, y: -22)
                                    .rotationEffect(.degrees(12))
                            }
                        )
                }

                // Small plane icon
                Image(systemName: "airplane")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(HaulTheme.checkedGreen)
                    .offset(x: 50, y: -70)
                    .rotationEffect(.degrees(-30))
            }
            .padding(.bottom, 40)

            // Text content
            VStack(spacing: 16) {
                Text("Never forget")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(HaulTheme.textPrimary)

                Text("You know that moment. Standing at the gate, phone in hand, trying to remember if you packed the charger. Haul ends that anxiety — forever.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(HaulTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Screen 2: "Photo your bag"
struct OnboardingPage2: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Custom illustration: Camera over suitcase
            ZStack {
                // Background rectangle
                RoundedRectangle(cornerRadius: 24)
                    .fill(HaulTheme.accent.opacity(0.06))
                    .frame(width: 200, height: 200)

                // Suitcase
                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(HaulTheme.accentDark)
                        .frame(width: 36, height: 8)
                        .offset(y: -1)

                    RoundedRectangle(cornerRadius: 10)
                        .fill(HaulTheme.accent)
                        .frame(width: 90, height: 68)
                        .overlay(
                            // Suitcase stripes
                            VStack(spacing: 6) {
                                ForEach(0..<2, id: \.self) { _ in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(HaulTheme.accentDark.opacity(0.3))
                                        .frame(width: 60, height: 4)
                                }
                            }
                        )
                }
                .offset(y: 20)

                // Camera overlay
                ZStack {
                    // Camera body
                    RoundedRectangle(cornerRadius: 10)
                        .fill(HaulTheme.backgroundDark)
                        .frame(width: 100, height: 72)

                    // Lens
                    Circle()
                        .fill(HaulTheme.accent)
                        .frame(width: 36, height: 36)

                    Circle()
                        .stroke(HaulTheme.accentDark, lineWidth: 3)
                        .frame(width: 36, height: 36)

                    Circle()
                        .fill(HaulTheme.backgroundDark)
                        .frame(width: 24, height: 24)

                    // Viewfinder bump
                    RoundedRectangle(cornerRadius: 3)
                        .fill(HaulTheme.backgroundDark)
                        .frame(width: 20, height: 10)
                        .offset(x: 30, y: -30)
                }
                .offset(x: -10, y: -50)

                // "Click" burst lines
                ForEach(0..<4, id: \.self) { index in
                    Rectangle()
                        .fill(HaulTheme.accent.opacity(0.4))
                        .frame(width: 2, height: 12)
                        .offset(x: index < 2 ? (index == 0 ? -52 : 52) : 0,
                                y: index >= 2 ? (index == 2 ? -52 : 52) : 0)
                        .rotationEffect(.degrees(Double(index) * 90 + 45))
                }
            }
            .padding(.bottom, 40)

            VStack(spacing: 16) {
                Text("Photo your bag")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(HaulTheme.textPrimary)

                Text("Before you pack anything, snap a photo of your empty suitcase. It's your canvas. Now fill it.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(HaulTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Screen 3: "Tap to pack"
struct OnboardingPage3: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Custom illustration: Checklist with checkmarks
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 20)
                    .fill(HaulTheme.accent.opacity(0.06))
                    .frame(width: 220, height: 200)

                // Packing list card
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    HStack {
                        Image(systemName: "suitcase.fill")
                            .font(.system(size: 12))
                            .foregroundColor(HaulTheme.accent)
                        Text("PACKING LIST")
                            .font(.system(size: 11, weight: .bold, design: .default))
                            .foregroundColor(HaulTheme.textSecondary)
                            .tracking(2)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 10)

                    // Items
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach([
                            ("5x T-shirts", true),
                            ("Toothbrush", true),
                            ("Passport", false),
                            ("Laptop", false)
                        ], id: \.0) { item in
                            HStack(spacing: 10) {
                                // Checkbox
                                ZStack {
                                    Circle()
                                        .stroke(item.1 ? HaulTheme.checkedGreen : HaulTheme.unchecked, lineWidth: 2)
                                        .frame(width: 18, height: 18)

                                    if item.1 {
                                        Circle()
                                            .fill(HaulTheme.checkedGreen)
                                            .frame(width: 18, height: 18)

                                        Image(systemName: "checkmark")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }

                                Text(item.0)
                                    .font(.system(size: 13, weight: item.1 ? .regular : .medium))
                                    .foregroundColor(item.1 ? HaulTheme.textSecondary : HaulTheme.textPrimary)
                                    .strikethrough(item.1, color: HaulTheme.textSecondary)
                                    .opacity(item.1 ? 0.6 : 1)

                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .frame(width: 200)
                .background(
                    VisualEffectBlur(blurStyle: .systemMaterial)
                )
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)

                // Floating tap indicator
                VStack(spacing: 4) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 22))
                        .foregroundColor(HaulTheme.accent)

                    Text("tap")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(HaulTheme.accent)
                }
                .offset(x: 60, y: -60)
            }
            .padding(.bottom, 40)

            VStack(spacing: 16) {
                Text("Tap to pack")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(HaulTheme.textPrimary)

                Text("Add everything you need, then tap each item as you pack it. Green means done. Simple, satisfying, complete.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(HaulTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Screen 4: "Pack smart"
struct OnboardingPage4: View {
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Custom illustration: Smart packing scene
            ZStack {
                // Background
                Circle()
                    .fill(HaulTheme.checkedGreen.opacity(0.08))
                    .frame(width: 200, height: 200)

                // Main suitcase
                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(HaulTheme.accentDark)
                        .frame(width: 30, height: 8)
                        .offset(y: -1)

                    RoundedRectangle(cornerRadius: 10)
                        .fill(HaulTheme.accent)
                        .frame(width: 80, height: 60)
                        .overlay(
                            VStack(spacing: 4) {
                                ForEach(0..<2, id: \.self) { _ in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(HaulTheme.accentDark.opacity(0.3))
                                        .frame(width: 50, height: 4)
                                }
                            }
                        )
                }

                // Smart badges floating around
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        SmartBadge(icon: "checkmark.circle.fill", color: HaulTheme.checkedGreen, label: "Done")
                        SmartBadge(icon: "suitcase.2.fill", color: HaulTheme.accent, label: "Packed")
                    }

                    HStack(spacing: 6) {
                        SmartBadge(icon: "location.fill", color: Color.blue, label: "Weather")
                        SmartBadge(icon: "doc.fill", color: HaulTheme.accentDark, label: "Docs")
                    }
                }
                .offset(y: 70)
            }
            .padding(.bottom, 40)

            VStack(spacing: 16) {
                Text("Pack smart")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(HaulTheme.textPrimary)

                Text("Pre-trip reminders. Passport check. Weather at your destination. Haul keeps you sharp before you even leave the house.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(HaulTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)

            Spacer()

            // CTA Button
            Button {
                HaulHaptics.shared.success()
                onComplete()
            } label: {
                Text("Start your first trip")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(HaulTheme.checkedGreen)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
            .accessibilityLabel("Start your first trip")
            .accessibilityHint("Begins setting up your first packing trip")
        }
    }
}

// MARK: - Smart Badge Component
struct SmartBadge: View {
    let icon: String
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(color)
        .cornerRadius(20)
        .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

// MARK: - UserDefaults Extension
extension UserDefaults {
    private enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
    }

    var hasCompletedOnboarding: Bool {
        get { bool(forKey: Keys.hasCompletedOnboarding) }
        set { set(newValue, forKey: Keys.hasCompletedOnboarding) }
    }
}
