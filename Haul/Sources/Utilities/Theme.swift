import SwiftUI
import UIKit

struct HaulTheme {
    // Backgrounds
    static let background = Color(hex: "f5f3ef")
    static let backgroundDark = Color(hex: "1a1814")

    // Surfaces
    static let surfaceLight = Color.white
    static let surfaceDark = Color(hex: "242118")

    // Accent
    static let accent = Color(hex: "c4956a")
    static let accentDark = Color(hex: "8b6914")

    // States
    static let checkedGreen = Color(hex: "5d8c5d")
    static let unchecked = Color(hex: "d4cfc6")

    // Text
    static let textPrimary = Color(hex: "1a1814")
    static let textSecondary = Color(hex: "7a746a")
}

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


