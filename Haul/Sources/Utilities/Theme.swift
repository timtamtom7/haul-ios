import SwiftUI
import UIKit

// MARK: - iOS 26 Liquid Glass Design System
// Centralized tokens for consistent UI across the app

struct HaulTheme {
    // MARK: - Colors
    /// Background — warm off-white
    static let background = Color(hex: "f5f3ef")
    /// Background dark — deep warm black
    static let backgroundDark = Color(hex: "1a1814")

    /// Surface — pure white (light mode)
    static let surfaceLight = Color.white
    /// Surface — warm dark (dark mode)
    static let surfaceDark = Color(hex: "242118")

    /// Accent — warm camel gold
    static let accent = Color(hex: "c4956a")
    /// Accent dark — deeper gold
    static let accentDark = Color(hex: "8b6914")

    /// Checked / success green
    static let checkedGreen = Color(hex: "5d8c5d")
    /// Unchecked / neutral gray
    static let unchecked = Color(hex: "d4cfc6")

    /// Primary text — near black
    static let textPrimary = Color(hex: "1a1814")
    /// Secondary text — warm gray
    static let textSecondary = Color(hex: "7a746a")

    // MARK: - Corner Radius Tokens (Liquid Glass)
    /// Extra small — badges, tags, minimal rounding
    static let radiusXS: CGFloat = 4
    /// Small — inline elements, compact chips
    static let radiusSM: CGFloat = 8
    /// Medium — cards, input fields, secondary containers
    static let radiusMD: CGFloat = 12
    /// Large — main cards, sheets, prominent containers
    static let radiusLG: CGFloat = 16
    /// Extra large — hero cards, bottom sheets
    static let radiusXL: CGFloat = 20
    /// Full — pills, circular buttons
    static let radiusFull: CGFloat = 9999

    // MARK: - Font Tokens (min 11pt for iOS 26 accessibility)
    /// Caption / helper text
    static let fontCaption: Font = .system(size: 11, weight: .regular)
    /// Small label (uppercase category labels)
    static let fontLabelSM: Font = .system(size: 12, weight: .medium)
    /// Body text
    static let fontBody: Font = .system(size: 15, weight: .regular)
    /// Body bold
    static let fontBodyBold: Font = .system(size: 15, weight: .semibold)
    /// Subheadline
    static let fontSubhead: Font = .system(size: 14, weight: .medium)
    /// Headline
    static let fontHeadline: Font = .system(size: 17, weight: .semibold)
    /// Title
    static let fontTitle: Font = .system(size: 20, weight: .bold)
    /// Large title
    static let fontLargeTitle: Font = .system(size: 28, weight: .bold)
    /// Hero / display
    static let fontHero: Font = .system(size: 34, weight: .bold, design: .rounded)

    // MARK: - Shadow / Depth (Liquid Glass)
    /// Glass shadow color
    static let glassShadowColor = Color.black.opacity(0.08)
    /// Glass shadow blur radius
    static let glassShadowRadius: CGFloat = 12
    /// Glass shadow Y offset
    static let glassShadowY: CGFloat = 4

    // MARK: - Spacing
    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 12
    static let spacingLG: CGFloat = 16
    static let spacingXL: CGFloat = 20
    static let spacingXXL: CGFloat = 24
}

// MARK: - Haptic Feedback Manager
// Stored as top-level actors to avoid Sendable issues with @MainActor static properties

@MainActor
final class HaulHaptics {
    static let shared = HaulHaptics()

    let light = UIImpactFeedbackGenerator(style: .light)
    let medium = UIImpactFeedbackGenerator(style: .medium)
    let selection = UISelectionFeedbackGenerator()
    let notification = UINotificationFeedbackGenerator()

    private init() {}

    /// Pre-warm all haptic engines — call from view onAppear
    func warm() {
        light.prepare()
        medium.prepare()
        selection.prepare()
        notification.prepare()
    }

    func lightImpact() {
        light.impactOccurred()
    }

    func mediumImpact() {
        medium.impactOccurred()
    }

    func success() {
        notification.notificationOccurred(.success)
    }
}

// MARK: - Button Styles

/// Primary filled button — accent background, white text
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(HaulTheme.fontBodyBold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, HaulTheme.spacingLG)
            .background(isEnabled ? HaulTheme.accent : HaulTheme.unchecked)
            .cornerRadius(HaulTheme.radiusMD)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Secondary outline button
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(HaulTheme.fontBodyBold)
            .foregroundColor(HaulTheme.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, HaulTheme.spacingLG)
            .background(HaulTheme.accent.opacity(configuration.isPressed ? 0.1 : 0.05))
            .cornerRadius(HaulTheme.radiusMD)
            .overlay(
                RoundedRectangle(cornerRadius: HaulTheme.radiusMD)
                    .stroke(HaulTheme.accent.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Ghost / plain button with press animation
struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - View Extensions

extension View {
    /// Liquid Glass card — blur background + border
    func glassCard(cornerRadius: CGFloat = HaulTheme.radiusLG) -> some View {
        self
            .background(VisualEffectBlur(blurStyle: .systemMaterial))
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
            )
            .shadow(
                color: HaulTheme.glassShadowColor,
                radius: HaulTheme.glassShadowRadius,
                y: HaulTheme.glassShadowY
            )
    }

    /// Semantic accent border
    func accentBorder(color: Color = HaulTheme.accent, cornerRadius: CGFloat = HaulTheme.radiusMD) -> some View {
        self
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(color.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [6]))
            )
    }
}

// MARK: - Color Hex Initializer

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    var excludedActivityTypes: [UIActivity.ActivityType]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        controller.excludedActivityTypes = excludedActivityTypes
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
