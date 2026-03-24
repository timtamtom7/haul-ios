import SwiftUI

struct WeatherWidgetView: View {
    @EnvironmentObject var tripStore: TripStore
    let trip: Trip

    @State private var weatherData: [WeatherData] = []
    @State private var suggestions: [WeatherSuggestion] = []
    @State private var isLoading = true
    @State private var error: WeatherError?
    @State private var showingDestinationInput = false
    @State private var destinationInput = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "cloud.sun.fill")
                    .font(.system(size: 16))
                    .foregroundColor(HaulTheme.accent)

                Text("Weather")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(HaulTheme.textSecondary)
                    .tracking(1)
                    .textCase(.uppercase)

                Spacer()

                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Button {
                        Task { await loadWeather() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(HaulTheme.textSecondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if isLoading {
                HStack {
                    Spacer()
                    VStack(spacing: 10) {
                        ProgressView()
                            .scaleEffect(0.9)
                        Text("Loading weather...")
                            .font(.system(size: 13))
                            .foregroundColor(HaulTheme.textSecondary)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            } else if let error = error {
                // Error state
                HStack(spacing: 12) {
                    Image(systemName: error.icon)
                        .font(.system(size: 20))
                        .foregroundColor(HaulTheme.textSecondary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Weather unavailable")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(HaulTheme.textPrimary)

                        Text("Tap to enter destination")
                            .font(.system(size: 12))
                            .foregroundColor(HaulTheme.textSecondary)
                    }

                    Spacer()

                    Button {
                        showingDestinationInput = true
                    } label: {
                        Text("Set")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(HaulTheme.accent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(HaulTheme.accent.opacity(0.1))
                            .cornerRadius(6)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            } else if !weatherData.isEmpty {
                // Weather forecast
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(weatherData.prefix(7)) { day in
                            WeatherDayCard(weather: day)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 12)

                // Suggestions
                if !suggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Suggested items")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(HaulTheme.textSecondary)
                            .tracking(1)
                            .textCase(.uppercase)
                            .padding(.horizontal, 16)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(uniqueSuggestions, id: \.self) { item in
                                    SuggestionChipView(item: item, condition: conditionForSuggestion(item))
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.bottom, 12)
                }
            } else {
                // No data yet
                VStack(spacing: 10) {
                    Image(systemName: "globe")
                        .font(.system(size: 24))
                        .foregroundColor(HaulTheme.textSecondary)

                    Text("Set your destination to see weather")
                        .font(.system(size: 13))
                        .foregroundColor(HaulTheme.textSecondary)

                    Button {
                        showingDestinationInput = true
                    } label: {
                        Text("Set Destination")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(HaulTheme.accent)
                            .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
        }
        .background(VisualEffectBlur(blurStyle: .systemMaterial))
        .cornerRadius(16)
        .sheet(isPresented: $showingDestinationInput) {
            WeatherDestinationSheet(
                destination: $destinationInput,
                onConfirm: { dest in
                    Task { await loadWeather(for: dest) }
                }
            )
        }
        .onAppear {
            Task { await loadWeather() }
        }
    }

    private var uniqueSuggestions: [String] {
        Array(Set(suggestions.flatMap { $0.items }))
    }

    private func conditionForSuggestion(_ item: String) -> WeatherCondition {
        for suggestion in suggestions {
            if suggestion.items.contains(item) {
                return suggestion.condition
            }
        }
        return .unknown
    }

    private func loadWeather(for destination: String? = nil) async {
        isLoading = true
        error = nil

        let dest = destination ?? extractDestination()
        guard !dest.isEmpty else {
            isLoading = false
            return
        }

        let result = await WeatherService.shared.fetchWeather(
            for: dest,
            startDate: trip.startDate,
            endDate: trip.endDate
        )

        switch result {
        case .success(let data):
            let generatedSuggestions = await WeatherService.shared.generateSuggestions(from: data)
            await MainActor.run {
                weatherData = data
                suggestions = generatedSuggestions
                error = nil
                isLoading = false
            }
        case .failure(let err):
            await MainActor.run {
                error = err
                weatherData = []
                suggestions = []
                isLoading = false
            }
        }
    }

    private func extractDestination() -> String {
        // Try to extract location from trip name (e.g., "Tokyo Trip" -> "Tokyo")
        let words = trip.name.components(separatedBy: " ")
        if words.count > 1 {
            let potential = words.dropLast().joined(separator: " ")
            if potential.count > 2 {
                return potential
            }
        }
        return ""
    }
}

struct WeatherDayCard: View {
    let weather: WeatherData

    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: weather.date)
    }

    private var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: weather.date)
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(dayName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(HaulTheme.textSecondary)

            Image(systemName: weather.conditionIcon)
                .font(.system(size: 22))
                .foregroundColor(conditionColor)

            Text(weather.temperatureDisplay)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(HaulTheme.textPrimary)

            Text(shortDate)
                .font(.system(size: 10))
                .foregroundColor(HaulTheme.textSecondary)
        }
        .frame(width: 70)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(conditionColor.opacity(0.08))
        .cornerRadius(12)
    }

    private var conditionColor: Color {
        switch weather.condition {
        case .sunny: return .orange
        case .rainy, .stormy: return .blue
        case .snowy: return .cyan
        case .cloudy: return .gray
        case .partlyCloudy: return .yellow
        case .foggy: return .gray
        case .windy: return .teal
        case .unknown: return HaulTheme.textSecondary
        }
    }
}

struct SuggestionChipView: View {
    let item: String
    let condition: WeatherCondition

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: condition.icon)
                .font(.system(size: 11))
                .foregroundColor(chipColor)

            Text(item)
                .font(.system(size: 13))
                .foregroundColor(HaulTheme.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(chipColor.opacity(0.1))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(chipColor.opacity(0.3), lineWidth: 1)
        )
    }

    private var chipColor: Color {
        switch condition {
        case .rainy, .stormy: return .blue
        case .snowy: return .cyan
        case .sunny: return .orange
        case .cloudy: return .gray
        case .partlyCloudy: return .yellow
        case .foggy: return .gray
        case .windy: return .teal
        case .unknown: return HaulTheme.textSecondary
        }
    }
}

struct WeatherDestinationSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var destination: String
    let onConfirm: (String) -> Void

    @State private var input: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                HaulTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Destination")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(HaulTheme.textSecondary)
                            .tracking(1)
                            .textCase(.uppercase)

                        TextField("e.g. Tokyo, Paris, New York", text: $input)
                            .font(.system(size: 17))
                            .padding(16)
                            .background(HaulTheme.surfaceLight)
                            .cornerRadius(12)
                    }

                    Text("Enter the city or region of your trip to get weather-based packing suggestions.")
                        .font(.system(size: 14))
                        .foregroundColor(HaulTheme.textSecondary)
                        .lineSpacing(3)

                    Spacer()

                    Button {
                        destination = input
                        onConfirm(input)
                        dismiss()
                    } label: {
                        Text("Get Weather")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(input.isEmpty ? HaulTheme.unchecked : HaulTheme.accent)
                            .cornerRadius(12)
                    }
                    .disabled(input.isEmpty)
                }
                .padding(20)
            }
            .navigationTitle("Weather Destination")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(HaulTheme.textSecondary)
                }
            }
            .onAppear {
                input = destination
            }
        }
    }
}

struct WeatherAlertCard: View {
    let suggestions: [WeatherSuggestion]
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(alertColor.opacity(0.12))
                        .frame(width: 44, height: 44)

                    Image(systemName: alertIcon)
                        .font(.system(size: 20))
                        .foregroundColor(alertColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Weather Alert")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(HaulTheme.textPrimary)

                    Text("\(uniqueItems.count) items suggested for your destination")
                        .font(.system(size: 13))
                        .foregroundColor(HaulTheme.textSecondary)
                }

                Spacer()
            }

            if !uniqueItems.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(uniqueItems.prefix(6), id: \.self) { item in
                        HStack(spacing: 4) {
                            Image(systemName: iconForItem(item))
                                .font(.system(size: 11))
                            Text(item)
                                .font(.system(size: 12))
                        }
                        .foregroundColor(HaulTheme.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(alertColor.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }

            Button {
                onDismiss()
            } label: {
                Text("Got it!")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(alertColor)
                    .cornerRadius(10)
            }
        }
        .padding(16)
        .background(VisualEffectBlur(blurStyle: .systemMaterial))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(alertColor.opacity(0.3), lineWidth: 1)
        )
    }

    private var uniqueItems: [String] {
        Array(Set(suggestions.flatMap { $0.items }))
    }

    private var alertColor: Color {
        guard let first = suggestions.first else { return .blue }
        switch first.condition {
        case .rainy, .stormy: return .blue
        case .snowy: return .cyan
        case .sunny: return .orange
        case .cloudy: return .gray
        case .partlyCloudy: return .yellow
        case .foggy: return .gray
        case .windy: return .teal
        case .unknown: return HaulTheme.accent
        }
    }

    private var alertIcon: String {
        suggestions.first?.condition.icon ?? "cloud.fill"
    }

    private func iconForItem(_ item: String) -> String {
        let lower = item.lowercased()
        if lower.contains("umbrella") { return "umbrella.fill" }
        if lower.contains("rain") || lower.contains("jacket") { return "cloud.rain.fill" }
        if lower.contains("sunscreen") || lower.contains("sunglasses") { return "sun.max.fill" }
        if lower.contains("gloves") || lower.contains("scarf") || lower.contains("boots") { return "snowflake" }
        if lower.contains("layer") || lower.contains("jacket") { return "thermometer.snowflake" }
        return "checklist"
    }
}
