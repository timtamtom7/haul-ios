import Foundation

actor WeatherService {
    static let shared = WeatherService()
    private init() {}

    private var cache: [String: (data: [WeatherData], timestamp: Date)] = [:]
    private let cacheExpiry: TimeInterval = 3600 // 1 hour

    func fetchWeather(for location: String, startDate: Date, endDate: Date) async -> Result<[WeatherData], WeatherError> {
        let cacheKey = "\(location)_\(startDate.timeIntervalSince1970)_\(endDate.timeIntervalSince1970)"

        // Check cache
        if let cached = cache[cacheKey], Date().timeIntervalSince(cached.timestamp) < cacheExpiry {
            return .success(cached.data)
        }

        // Use wttr.in - no API key needed
        let encodedLocation = location.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? location
        let urlString = "https://wttr.in/\(encodedLocation)?format=j1"

        guard let url = URL(string: urlString) else {
            return .failure(.invalidLocation)
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return .failure(.apiError)
            }

            let weatherData = try JSONDecoder().decode(wttrResponse.self, from: data)
            let processedData = processWeatherResponse(weatherData, location: location, startDate: startDate, endDate: endDate)

            // Cache result
            cache[cacheKey] = (processedData, Date())

            return .success(processedData)
        } catch is DecodingError {
            return .failure(.parseError)
        } catch {
            return .failure(.networkError)
        }
    }

    private func processWeatherResponse(_ response: wttrResponse, location: String, startDate: Date, endDate: Date) -> [WeatherData] {
        var results: [WeatherData] = []
        let calendar = Calendar.current
        let days = response.weather

        for (index, day) in days.enumerated() {
            guard let date = calendar.date(byAdding: .day, value: index, to: startDate) else { continue }

            let avgtempC = (Double(day.avgtempC) ?? 20)
            let condition = parseCondition(day.hourly.first?.weatherDesc.first?.value ?? "Unknown")
            let humidity = Int(day.hourly.first?.humidity ?? 50)

            var suggestions = condition.suggestedItems

            // Add temperature-based suggestions
            if avgtempC < 10 {
                suggestions.append("Warm layers")
                suggestions.append(" Jacket")
            } else if avgtempC > 30 {
                suggestions.append("Extra water")
                suggestions.append("Cooling towel")
            }

            let weather = WeatherData(
                location: location,
                date: date,
                condition: condition,
                temperatureCelsius: avgtempC,
                humidity: humidity,
                suggestions: suggestions
            )
            results.append(weather)
        }

        return results
    }

    private func parseCondition(_ code: String) -> WeatherCondition {
        let lowercased = code.lowercased()
        if lowercased.contains("rain") || lowercased.contains("drizzle") {
            return .rainy
        } else if lowercased.contains("thunder") || lowercased.contains("storm") {
            return .stormy
        } else if lowercased.contains("snow") || lowercased.contains("sleet") {
            return .snowy
        } else if lowercased.contains("fog") || lowercased.contains("mist") {
            return .foggy
        } else if lowercased.contains("cloud") || lowercased.contains("overcast") {
            return .cloudy
        } else if lowercased.contains("partly") || lowercased.contains("sunny") && lowercased.contains("cloud") {
            return .partlyCloudy
        } else if lowercased.contains("sun") || lowercased.contains("clear") {
            return .sunny
        } else if lowercased.contains("wind") {
            return .windy
        }
        return .unknown
    }

    // Generate suggestions based on weather conditions for a trip
    nonisolated func generateSuggestions(from weatherData: [WeatherData]) -> [WeatherSuggestion] {
        var suggestions: [WeatherSuggestion] = []

        for day in weatherData {
            if !day.condition.suggestedItems.isEmpty {
                let suggestion = WeatherSuggestion(
                    date: day.date,
                    condition: day.condition,
                    temperature: day.temperatureCelsius,
                    items: day.condition.suggestedItems,
                    reason: "\(day.condition.rawValue) (\(day.temperatureDisplay))"
                )
                suggestions.append(suggestion)
            }
        }

        return suggestions
    }
}

struct WeatherSuggestion: Identifiable {
    let id = UUID()
    let date: Date
    let condition: WeatherCondition
    let temperature: Double
    let items: [String]
    let reason: String

    var dateDisplay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }
}

enum WeatherError: Error, Equatable {
    case networkError
    case apiError
    case parseError
    case invalidLocation
    case unavailable

    var localizedDescription: String {
        switch self {
        case .networkError: return "No internet connection"
        case .apiError: return "Weather service unavailable"
        case .parseError: return "Couldn't read weather data"
        case .invalidLocation: return "Location not found"
        case .unavailable: return "Weather data unavailable"
        }
    }

    var icon: String {
        switch self {
        case .networkError: return "wifi.slash"
        case .apiError: return "cloud.fill"
        case .parseError: return "exclamationmark.triangle.fill"
        case .invalidLocation: return "mappin.slash"
        case .unavailable: return "cloud.fill"
        }
    }
}

// MARK: - wttr.in Response Models
private struct wttrResponse: Codable {
    let weather: [WeatherDay]
}

private struct WeatherDay: Codable {
    let avgtempC: String
    let hourly: [HourlyWeather]
}

private struct HourlyWeather: Codable {
    let weatherDesc: [WeatherDesc]
    let humidity: Int?
}

private struct WeatherDesc: Codable {
    let value: String
}
