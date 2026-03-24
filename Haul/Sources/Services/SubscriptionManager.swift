import SwiftUI
import Combine

// MARK: - Subscription Tier
enum SubscriptionTier: String, CaseIterable {
    case free = "free"
    case pack = "pack"
    case travel = "travel"

    var name: String {
        switch self {
        case .free: return "Free"
        case .pack: return "Pack"
        case .travel: return "Travel"
        }
    }

    var price: String {
        switch self {
        case .free: return "Free"
        case .pack: return "$2.99/mo"
        case .travel: return "$5.99/mo"
        }
    }

    var monthlyPrice: Double? {
        switch self {
        case .free: return 0
        case .pack: return 2.99
        case .travel: return 5.99
        }
    }

    var tagline: String {
        switch self {
        case .free: return "Get started"
        case .pack: return "Everything you need"
        case .travel: return "The ultimate packer"
        }
    }

    var features: [String] {
        switch self {
        case .free:
            return [
                "2 trips",
                "20 items per trip",
                "1 suitcase photo",
                "Basic packing list"
            ]
        case .pack:
            return [
                "Unlimited trips",
                "Unlimited items",
                "Unlimited photo storage",
                "Category organization",
                "Pre-departure reminders"
            ]
        case .travel:
            return [
                "Everything in Pack",
                "Multiple suitcases per trip",
                "Packing templates",
                "Weather at destination",
                "Trip statistics",
                "Priority support"
            ]
        }
    }

    var icon: String {
        switch self {
        case .free: return "suitcase"
        case .pack: return "suitcase.fill"
        case .travel: return "suitcase.2.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .free: return HaulTheme.textSecondary
        case .pack: return HaulTheme.accent
        case .travel: return HaulTheme.checkedGreen
        }
    }

    var maxTrips: Int? {
        switch self {
        case .free: return 2
        default: return nil
        }
    }

    var maxItemsPerTrip: Int? {
        switch self {
        case .free: return 20
        default: return nil
        }
    }
}

// MARK: - Subscription Manager
@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published var currentTier: SubscriptionTier = .free

    private let userDefaults = UserDefaults.standard
    private let tierKey = "subscriptionTier"

    private init() {
        loadTier()
    }

    func loadTier() {
        if let savedRaw = userDefaults.string(forKey: tierKey),
           let tier = SubscriptionTier(rawValue: savedRaw) {
            currentTier = tier
        } else {
            currentTier = .free
        }
    }

    func upgrade(to tier: SubscriptionTier) {
        currentTier = tier
        userDefaults.set(tier.rawValue, forKey: tierKey)
    }

    func canCreateTrip(tripCount: Int) -> Bool {
        if let max = currentTier.maxTrips {
            return tripCount < max
        }
        return true
    }

    func canAddItem(itemCount: Int) -> Bool {
        if let max = currentTier.maxItemsPerTrip {
            return itemCount < max
        }
        return true
    }

    func resetToFree() {
        currentTier = .free
        userDefaults.removeObject(forKey: tierKey)
    }
}
