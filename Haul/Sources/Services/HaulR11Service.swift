import Foundation

// R11: Weather sync, Template community, Post-trip learning for Haul
actor WeatherSyncService {
    static let shared = WeatherSyncService()

    private init() {}

    // MARK: - Weather-based packing suggestions

    struct WeatherSuggestion {
        let item: String
        let reason: String
        let priority: Priority

        enum Priority: Int {
            case essential = 0
            case recommended = 1
            case optional = 2
        }
    }

    func suggestItemsForWeather(weather: WeatherForecast, tripType: TripType) -> [WeatherSuggestion] {
        var suggestions: [WeatherSuggestion] = []

        let temp = (weather.highTemp + weather.lowTemp) / 2

        // Temperature-based
        if temp < 10 {
            suggestions.append(WeatherSuggestion(item: "Warm jacket", reason: "Cold weather (\(Int(temp))°C)", priority: .essential))
            suggestions.append(WeatherSuggestion(item: "Layers", reason: "Cold mornings", priority: .recommended))
        }

        if weather.rainProbability > 0.3 {
            suggestions.append(WeatherSuggestion(item: "Rain jacket", reason: "\(Int(weather.rainProbability * 100))% chance of rain", priority: .essential))
            suggestions.append(WeatherSuggestion(item: "Umbrella", reason: "Rain expected", priority: .recommended))
        }

        if weather.highTemp > 25 {
            suggestions.append(WeatherSuggestion(item: "Sunscreen", reason: "Hot weather (\(Int(temp))°C)", priority: .recommended))
            suggestions.append(WeatherSuggestion(item: "Hat", reason: "Sun protection", priority: .optional))
        }

        return suggestions
    }

    struct WeatherForecast {
        let highTemp: Double
        let lowTemp: Double
        let rainProbability: Double
        let condition: String // sunny, cloudy, rainy, etc.
    }

    enum TripType: String {
        case beach
        case business
        case hiking
        case city
        case winter
    }
}

// MARK: - Template Community

@MainActor
final class TemplateCommunityService: ObservableObject {
    static let shared = TemplateCommunityService()

    @Published var communityTemplates: [SharedTemplate] = []
    @Published var popularTemplates: [SharedTemplate] = []

    struct SharedTemplate: Identifiable {
        let id: UUID
        let name: String
        let author: String
        let category: String
        let itemCount: Int
        let rating: Double
        let downloadCount: Int
        let isFeatured: Bool
    }

    private init() {
        loadMockTemplates()
    }

    func loadMockTemplates() {
        communityTemplates = [
            SharedTemplate(id: UUID(), name: "Beach Week", author: "TravelPro", category: "Beach", itemCount: 24, rating: 4.8, downloadCount: 1205, isFeatured: true),
            SharedTemplate(id: UUID(), name: "Business Trip", author: "FrequentFlyer", category: "Business", itemCount: 18, rating: 4.5, downloadCount: 890, isFeatured: false),
            SharedTemplate(id: UUID(), name: "Winter Hiking", author: "MountainGoat", category: "Hiking", itemCount: 32, rating: 4.9, downloadCount: 567, isFeatured: true)
        ]
        popularTemplates = communityTemplates.sorted { $0.downloadCount > $1.downloadCount }
    }

    func importTemplate(_ template: SharedTemplate) {
        // Import template to user's list
    }
}

// MARK: - Post-Trip Learning

@MainActor
final class PostTripLearningService: ObservableObject {
    static let shared = PostTripLearningService()

    @Published var tripLessons: [TripLesson] = []

    struct TripLesson: Identifiable {
        let id: UUID
        let tripName: String
        let itemsForgotten: [String]
        let itemsNeverUsed: [String]
        let packingRating: Int // 1-5
        let suggestions: [String]
    }

    private init() {}

    func recordTripLesson(
        tripName: String,
        itemsForgotten: [String],
        itemsNeverUsed: [String],
        packingRating: Int
    ) {
        let suggestions = generateSuggestions(
            forgotten: itemsForgotten,
            neverUsed: itemsNeverUsed,
            rating: packingRating
        )

        let lesson = TripLesson(
            id: UUID(),
            tripName: tripName,
            itemsForgotten: itemsForgotten,
            itemsNeverUsed: itemsNeverUsed,
            packingRating: packingRating,
            suggestions: suggestions
        )

        tripLessons.insert(lesson, at: 0)
        saveLessons()
    }

    private func generateSuggestions(forgotten: [String], neverUsed: [String], rating: Int) -> [String] {
        var suggestions: [String] = []

        if !forgotten.isEmpty {
            suggestions.append("Add '\(forgotten.first!)' to your essentials list")
        }

        if neverUsed.count > 3 {
            suggestions.append("Consider packing lighter — you didn't use \(neverUsed.count) items")
        }

        if rating < 3 {
            suggestions.append("Try a more detailed packing list next time")
        }

        return suggestions
    }

    func getForgottenItemsSuggestions() -> [String] {
        // Return items that were forgotten across all trips
        return Array(Set(tripLessons.flatMap { $0.itemsForgotten }))
    }

    private func saveLessons() {
        // Save to UserDefaults
    }
}
