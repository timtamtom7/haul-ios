import SwiftUI
import PhotosUI

struct WardrobeView: View {
    @EnvironmentObject var tripStore: TripStore
    @Environment(\.dismiss) var dismiss
    let tripId: Int64

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var wardrobeImage: UIImage?
    @State private var suggestedItems: [WardrobeSuggestedItem] = []
    @State private var selectedItems: Set<String> = []
    @State private var isLoading = false
    @State private var showingAddedConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "f5f3ef")
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Wardrobe photo
                        VStack(spacing: 12) {
                            if let image = wardrobeImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 240)
                                    .clipped()
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color(hex: "c4956a").opacity(0.3), lineWidth: 1)
                                    )
                            } else {
                                VStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: "c4956a").opacity(0.08))
                                            .frame(width: 80, height: 80)
                                        Image(systemName: "tshirt.fill")
                                            .font(.system(size: 32))
                                            .foregroundColor(Color(hex: "c4956a"))
                                    }

                                    Text("Add your wardrobe photo")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color(hex: "1a1814"))

                                    Text("Take a photo of your closet to get smart item suggestions and avoid packing duplicates")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color(hex: "7a746a"))
                                        .multilineTextAlignment(.center)
                                        .lineSpacing(3)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 32)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color(hex: "d4cfc6"), style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                                )
                            }

                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                HStack(spacing: 8) {
                                    Image(systemName: wardrobeImage == nil ? "camera.fill" : "arrow.triangle.2.circlepath")
                                    Text(wardrobeImage == nil ? "Choose Photo" : "Change Photo")
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color(hex: "c4956a"))
                                .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal, 20)

                        // Wardrobe tips when no photo
                        if wardrobeImage == nil {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("How it works")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color(hex: "7a746a"))
                                    .tracking(1)
                                    .textCase(.uppercase)

                                ForEach(wardrobeTips, id: \.self) { tip in
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Color(hex: "5d8c5d"))
                                            .font(.system(size: 14))
                                        Text(tip)
                                            .font(.system(size: 13))
                                            .foregroundColor(Color(hex: "1a1814"))
                                    }
                                }
                            }
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(16)
                            .padding(.horizontal, 20)
                        }

                        // Suggestions
                        if !suggestedItems.isEmpty {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    Text("Suggested Items")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(Color(hex: "7a746a"))
                                        .tracking(1)
                                        .textCase(.uppercase)

                                    Spacer()

                                    Text("\(selectedItems.count) selected")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(hex: "c4956a"))
                                }

                                Text("Based on your wardrobe — tap to add to your packing list")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "7a746a"))

                                ForEach(suggestedItems) { item in
                                    WardrobeItemRow(
                                        item: item,
                                        isSelected: selectedItems.contains(item.name),
                                        onToggle: {
                                            if selectedItems.contains(item.name) {
                                                selectedItems.remove(item.name)
                                            } else {
                                                selectedItems.insert(item.name)
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(16)
                            .padding(.horizontal, 20)
                        }

                        // Loading
                        if isLoading {
                            HStack(spacing: 12) {
                                ProgressView()
                                Text("Analyzing your wardrobe...")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "7a746a"))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                        }

                        // Add to trip button
                        if !selectedItems.isEmpty {
                            Button {
                                addSelectedItemsToTrip()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add \(selectedItems.count) items to trip")
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(hex: "c4956a"))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 20)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Wardrobe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "c4956a"))
                }
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    await loadPhoto(newValue)
                }
            }
            .alert("Items added!", isPresented: $showingAddedConfirmation) {
                Button("OK") {}
            } message: {
                Text("\(selectedItems.count) items have been added to your packing list.")
            }
        }
    }

    private var wardrobeTips: [String] {
        [
            "Photo your open closet or drawer to identify what you own",
            "We suggest items not already in your packing list",
            "Avoid packing duplicates from your everyday wardrobe",
            "Helps remind you of items you might forget"
        ]
    }

    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }
        isLoading = true

        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            wardrobeImage = image
            // Generate suggestions after loading
            generateSuggestions()
        }
        isLoading = false
    }

    private func generateSuggestions() {
        // Simulated wardrobe suggestions — in a real app this would use Vision/ML
        // We suggest common items that might not be in the packing list
        let wardrobeSuggestions: [WardrobeSuggestedItem] = [
            WardrobeSuggestedItem(name: "Watch", category: "MISC", reason: "Everyday essential you might forget"),
            WardrobeSuggestedItem(name: "Watch", category: "MISC", reason: "Everyday essential you might forget"),
            WardrobeSuggestedItem(name: "Sunglasses", category: "MISC", reason: "Everyday essential you might forget"),
            WardrobeSuggestedItem(name: "Belt", category: "CLOTHES", reason: "Common item often left behind"),
            WardrobeSuggestedItem(name: "Scarf", category: "CLOTHES", reason: "Versatile piece for any trip"),
            WardrobeSuggestedItem(name: "Umbrella", category: "MISC", reason: "Compact umbrella — always useful"),
            WardrobeSuggestedItem(name: "Phone charger", category: "ELECTRONICS", reason: "Don't forget this one!"),
            WardrobeSuggestedItem(name: "Hair ties", category: "TOILETRIES", reason: "Small but essential"),
            WardrobeSuggestedItem(name: "Lip balm", category: "TOILETRIES", reason: "Easy to forget"),
            WardrobeSuggestedItem(name: "Wallet", category: "MISC", reason: "Don't leave home without it"),
            WardrobeSuggestedItem(name: "Jewelry", category: "MISC", reason: "Pack carefully to avoid losing"),
            WardrobeSuggestedItem(name: "Sneakers", category: "CLOTHES", reason: "Good for walking tours"),
        ]

        // Filter out items already in the trip
        let existingNames = Set(tripStore.getAllItems(for: tripId).map { $0.name.lowercased() })
        suggestedItems = wardrobeSuggestions.filter { !existingNames.contains($0.name.lowercased()) }
    }

    private func addSelectedItemsToTrip() {
        for itemName in selectedItems {
            if let suggested = suggestedItems.first(where: { $0.name == itemName }) {
                tripStore.addItem(to: tripId, name: suggested.name, category: suggested.category)
            } else {
                tripStore.addItem(to: tripId, name: itemName, category: "MISC")
            }
        }
        showingAddedConfirmation = true
        selectedItems.removeAll()
    }
}

struct WardrobeSuggestedItem: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let reason: String
}

struct WardrobeItemRow: View {
    let item: WardrobeSuggestedItem
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // Checkbox
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color(hex: "c4956a") : Color(hex: "d4cfc6"), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(Color(hex: "c4956a"))
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(hex: "1a1814"))

                    Text(item.reason)
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "7a746a"))
                }

                Spacer()

                Text(item.category)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(hex: "7a746a"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: "d4cfc6").opacity(0.4))
                    .cornerRadius(4)
            }
            .padding(12)
            .background(isSelected ? Color(hex: "c4956a").opacity(0.06) : Color(hex: "f5f3ef"))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}
