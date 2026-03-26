import SwiftUI

/// R10: Weather-based item suggestions sheet
struct WeatherSuggestionsSheet: View {
    @EnvironmentObject var tripStore: TripStore
    @Environment(\.dismiss) var dismiss
    let trip: Trip
    let suggestions: [WeatherSuggestion]
    let destination: String

    @State private var selectedItems: Set<String> = []
    @State private var isLoading = false
    @State private var showingAddedConfirmation = false

    private var uniqueItems: [(item: String, condition: WeatherCondition)] {
        var seen = Set<String>()
        var result: [(item: String, condition: WeatherCondition)] = []
        for suggestion in suggestions {
            for item in suggestion.items {
                if !seen.contains(item) {
                    seen.insert(item)
                    result.append((item: item, condition: suggestion.condition))
                }
            }
        }
        return result
    }

    private var groupedByCondition: [(condition: WeatherCondition, items: [String])] {
        var map: [WeatherCondition: [String]] = [:]
        for suggestion in suggestions {
            if map[suggestion.condition] == nil {
                map[suggestion.condition] = []
            }
            for item in suggestion.items {
                if !(map[suggestion.condition]?.contains(item) ?? false) {
                    map[suggestion.condition]?.append(item)
                }
            }
        }
        return map.map { ($0.key, $0.value) }.sorted { $0.0.rawValue < $1.0.rawValue }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HaulTheme.background
                    .ignoresSafeArea()

                if suggestions.isEmpty {
                    emptyState
                } else {
                    suggestionsList
                }
            }
            .navigationTitle("Smart Suggestions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(HaulTheme.textSecondary)
                }

                if !uniqueItems.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            addAllItems()
                        } label: {
                            Text("Add All")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(HaulTheme.checkedGreen)
                        }
                    }
                }
            }
            .alert("Items added!", isPresented: $showingAddedConfirmation) {
                Button("Done") {
                    dismiss()
                }
                Button("Keep Browsing", role: .cancel) {}
            } message: {
                Text("\(selectedItems.count) items have been added to your packing list.")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(HaulTheme.accent.opacity(0.08))
                    .frame(width: 80, height: 80)
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 32))
                    .foregroundColor(HaulTheme.accent)
            }

            VStack(spacing: 6) {
                Text("No suggestions for \(destination)")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(HaulTheme.textPrimary)

                Text("The weather looks pleasant — pack what feels right for your trip.")
                    .font(.system(size: 14))
                    .foregroundColor(HaulTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
        }
        .padding(40)
    }

    private var suggestionsList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Summary header
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(HaulTheme.accent.opacity(0.12))
                            .frame(width: 52, height: 52)
                        Image(systemName: "sparkles")
                            .font(.system(size: 22))
                            .foregroundColor(HaulTheme.accent)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Weather-based packing tips")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(HaulTheme.textPrimary)

                        Text("\(destination) · \(suggestions.count) days analyzed")
                            .font(.system(size: 13))
                            .foregroundColor(HaulTheme.textSecondary)
                    }

                    Spacer()
                }
                .padding(16)
                .background(VisualEffectBlur(blurStyle: .systemMaterial))
                .cornerRadius(16)

                // Items grouped by condition
                ForEach(groupedByCondition, id: \.condition) { group in
                    VStack(alignment: .leading, spacing: 12) {
                        // Condition header
                        HStack(spacing: 10) {
                            Image(systemName: group.condition.icon)
                                .font(.system(size: 16))
                                .foregroundColor(conditionColor(group.condition))

                            Text(group.condition.rawValue)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(HaulTheme.textSecondary)
                                .tracking(1)
                                .textCase(.uppercase)

                            Spacer()

                            Text("\(group.items.count) items")
                                .font(.system(size: 12))
                                .foregroundColor(HaulTheme.textSecondary)
                        }

                        FlowLayout(spacing: 8) {
                            ForEach(group.items, id: \.self) { item in
                                WeatherSuggestionChip(
                                    item: item,
                                    isSelected: selectedItems.contains(item),
                                    onToggle: {
                                        if selectedItems.contains(item) {
                                            selectedItems.remove(item)
                                        } else {
                                            selectedItems.insert(item)
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .padding(16)
                    .background(VisualEffectBlur(blurStyle: .systemMaterial))
                    .cornerRadius(16)
                }

                // Add selected button
                if !selectedItems.isEmpty {
                    Button {
                        addSelectedItems()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                            Text("Add \(selectedItems.count) items to trip")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(HaulTheme.checkedGreen)
                        .cornerRadius(12)
                    }
                }

                // Footer note
                Text("Suggestions are based on the weather forecast for your destination. Only items not already in your list are shown.")
                    .font(.system(size: 12))
                    .foregroundColor(HaulTheme.textSecondary)
                    .lineSpacing(3)
                    .padding(.top, 4)

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }

    private var existingItemNames: Set<String> {
        Set(tripStore.getAllItems(for: trip.id ?? 0).map { $0.name.lowercased() })
    }

    private func addSelectedItems() {
        for itemName in selectedItems {
            if !existingItemNames.contains(itemName.lowercased()) {
                // Assign to a sensible category
                let category = categoryForItem(itemName)
                tripStore.addItem(to: trip.id ?? 0, name: itemName, category: category)
            }
        }
        showingAddedConfirmation = true
    }

    private func addAllItems() {
        for (itemName, _) in uniqueItems {
            if !existingItemNames.contains(itemName.lowercased()) {
                let category = categoryForItem(itemName)
                tripStore.addItem(to: trip.id ?? 0, name: itemName, category: category)
            }
        }
        selectedItems = Set(uniqueItems.map { $0.item })
        showingAddedConfirmation = true
    }

    private func categoryForItem(_ item: String) -> String {
        let lower = item.lowercased()
        if lower.contains("umbrella") || lower.contains("rain") || lower.contains("jacket") || lower.contains("coat") || lower.contains("boot") {
            return "CLOTHES"
        }
        if lower.contains("sunscreen") || lower.contains("sunglasses") || lower.contains("hat") || lower.contains("lip balm") {
            return "TOILETRIES"
        }
        if lower.contains("gloves") || lower.contains("scarf") || lower.contains("thermal") || lower.contains("sock") {
            return "CLOTHES"
        }
        if lower.contains("charger") || lower.contains("adapter") || lower.contains("power bank") {
            return "ELECTRONICS"
        }
        return "MISC"
    }

    private func conditionColor(_ condition: WeatherCondition) -> Color {
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

struct WeatherSuggestionChip: View {
    let item: String
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 6) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "plus.circle")
                    .font(.system(size: 14))
                Text(item)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : HaulTheme.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(isSelected ? HaulTheme.checkedGreen : HaulTheme.surfaceLight)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? HaulTheme.checkedGreen : HaulTheme.unchecked, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(item), \(isSelected ? "selected" : "tap to add")")
    }
}
