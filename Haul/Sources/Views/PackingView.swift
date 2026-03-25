import SwiftUI
import UIKit

struct PackingView: View {
    @EnvironmentObject var tripStore: TripStore
    let trip: Trip
    @State private var showingSuitcasePhoto = false
    @State private var showingAddItem = false
    @State private var showingPassportReminder = false
    @State private var showingWeather = false
    @State private var showingBags = false
    @State private var showingTemplates = false
    @State private var showingFeedback = false
    @State private var showingShare = false

    private var groupedItems: [String: [PackingItem]] {
        Dictionary(grouping: tripStore.currentTripItems, by: { $0.category })
    }

    private var sortedCategories: [String] {
        let order = ["CLOTHES", "TOILETRIES", "ELECTRONICS", "DOCUMENTS", "MISC"]
        return groupedItems.keys.sorted { a, b in
            let indexA = order.firstIndex(of: a) ?? Int.max
            let indexB = order.firstIndex(of: b) ?? Int.max
            return indexA < indexB
        }
    }

    private var shareText: String {
        var text = "📦 \(trip.name) — Packing List\n"
        text += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"

        let packed = tripStore.packedCount(for: trip.id ?? 0)
        let total = tripStore.totalCount(for: trip.id ?? 0)
        text += "Progress: \(packed)/\(total) packed\n\n"

        for category in sortedCategories {
            if let items = groupedItems[category] {
                let catPacked = items.filter { $0.isPacked }.count
                text += "【\(category)】 (\(catPacked)/\(items.count))\n"
                for item in items {
                    let check = item.isPacked ? "☑" : "☐"
                    text += "  \(check) \(item.name)\n"
                }
                text += "\n"
            }
        }

        text += "Sent via Haul ✦"
        return text
    }

    var body: some View {
        ZStack {
            HaulTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Suitcase Photo
                    if let photoPath = trip.suitcasePhotoPath,
                       let image = PhotoStorageService.shared.loadPhoto(at: photoPath) {
                        Button {
                            showingSuitcasePhoto = true
                        } label: {
                            ZStack(alignment: .bottomLeading) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 220)
                                    .clipped()
                                    .cornerRadius(16)

                                LinearGradient(
                                    colors: [.black.opacity(0.4), .clear],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                                .cornerRadius(16)

                                Text("Tap items to pack")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(12)
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // Quick actions bar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            QuickActionButton(icon: "cloud.sun.fill", label: "Weather") {
                                showingWeather = true
                            }
                            QuickActionButton(icon: "suitcase.2.fill", label: "Bags") {
                                showingBags = true
                            }
                            QuickActionButton(icon: "doc.on.doc.fill", label: "Templates") {
                                showingTemplates = true
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // Weather Widget (for upcoming/ongoing trips)
                    if !trip.isPast {
                        WeatherWidgetView(trip: trip)
                            .padding(.horizontal, 20)
                    }

                    // Post-Trip Feedback Banner
                    if trip.isPast {
                        PostTripBannerView(trip: trip) {
                            showingFeedback = true
                        }
                        .padding(.horizontal, 20)
                    }

                    // Passport Reminder
                    if showingPassportReminder && !trip.isPast {
                        PassportReminderCard {
                            markPassportPacked()
                        }
                        .padding(.horizontal, 20)
                    }

                    // Progress summary
                    let packed = tripStore.packedCount(for: trip.id ?? 0)
                    let total = tripStore.totalCount(for: trip.id ?? 0)
                    if total > 0 {
                        PackingProgressView(packed: packed, total: total)
                            .padding(.horizontal, 20)
                    }

                    // Empty packing list state
                    if sortedCategories.isEmpty {
                        EmptyPackingListView {
                            showingAddItem = true
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                        }
                        .padding(.horizontal, 20)
                    }

                    // Items grouped by category
                    ForEach(sortedCategories, id: \.self) { category in
                        if let items = groupedItems[category] {
                            CategorySectionView(
                                category: category,
                                items: items,
                                onToggle: { item in
                                    tripStore.toggleItem(item)
                                },
                                onDelete: { item in
                                    tripStore.deleteItem(item)
                                }
                            )
                        }
                    }

                    // Add item button
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        showingAddItem = true
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                            Text("Add Item")
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(HaulTheme.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(HaulTheme.surfaceLight.opacity(0.8))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    Spacer(minLength: 40)
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle(trip.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingTemplates = true
                    } label: {
                        Label("Templates", systemImage: "doc.on.doc")
                    }

                    Button {
                        showingBags = true
                    } label: {
                        Label("Bags", systemImage: "suitcase.2")
                    }

                    Button {
                        showingShare = true
                    } label: {
                        Label("Share List", systemImage: "square.and.arrow.up")
                    }

                    if trip.isPast {
                        Button {
                            showingFeedback = true
                        } label: {
                            Label("Give Feedback", systemImage: "star")
                        }
                    }

                    Divider()

                    Button(role: .destructive) {
                        tripStore.deleteTrip(trip)
                    } label: {
                        Label("Delete Trip", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(HaulTheme.textSecondary)
                }
            }
        }
        .onAppear {
            if let tripId = trip.id {
                tripStore.fetchItems(for: tripId)
            }
            checkPassportReminder()
        }
        .fullScreenCover(isPresented: $showingSuitcasePhoto) {
            if let photoPath = trip.suitcasePhotoPath,
               let image = PhotoStorageService.shared.loadPhoto(at: photoPath) {
                SuitcasePhotoView(image: image)
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddItemSheet(tripId: trip.id ?? 0)
                .environmentObject(tripStore)
        }
        .sheet(isPresented: $showingBags) {
            BagsListView(trip: trip)
                .environmentObject(tripStore)
        }
        .sheet(isPresented: $showingTemplates) {
            TemplatesListView(tripId: trip.id) { template in
                if let tripId = trip.id {
                    tripStore.applyTemplate(template, to: tripId)
                    tripStore.fetchItems(for: tripId)
                }
            }
            .environmentObject(tripStore)
        }
        .sheet(isPresented: $showingWeather) {
            WeatherDestinationSheet(
                destination: .constant(""),
                onConfirm: { _ in
                    showingWeather = false
                }
            )
        }
        .sheet(isPresented: $showingFeedback) {
            PostTripFeedbackView(trip: trip)
                .environmentObject(tripStore)
        }
        .sheet(isPresented: $showingShare) {
            ShareSheet(activityItems: [shareText])
        }
    }

    private func checkPassportReminder() {
        let calendar = Calendar.current
        if let start = calendar.dateComponents([.year, .month, .day], from: trip.startDate).date,
           let today = calendar.dateComponents([.year, .month, .day], from: Date()).date {
            let daysDiff = calendar.dateComponents([.day], from: today, to: start).day ?? 0
            showingPassportReminder = (daysDiff >= 0 && daysDiff <= 1)

            if showingPassportReminder {
                let hasPassport = tripStore.currentTripItems.contains { $0.name.lowercased().contains("passport") && $0.isPacked }
                showingPassportReminder = !hasPassport
            }
        }
    }

    private func markPassportPacked() {
        if let passport = tripStore.currentTripItems.first(where: { $0.name.lowercased().contains("passport") }) {
            tripStore.toggleItem(passport)
        }
        showingPassportReminder = false
    }
}

struct QuickActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(label)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(HaulTheme.accent)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(HaulTheme.accent.opacity(0.1))
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

struct EmptyPackingListView: View {
    let onAddItem: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(HaulTheme.accent.opacity(0.08))
                    .frame(width: 80, height: 80)

                Image(systemName: "checklist")
                    .font(.system(size: 32))
                    .foregroundColor(HaulTheme.accent)
            }

            VStack(spacing: 6) {
                Text("Your packing list is empty")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(HaulTheme.textPrimary)

                Text("Add items to start packing, or apply a template to get started quickly.")
                    .font(.system(size: 14))
                    .foregroundColor(HaulTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            Button {
                onAddItem()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add First Item")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(HaulTheme.accent)
                .cornerRadius(10)
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(
            VisualEffectBlur(blurStyle: .systemMaterial)
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(HaulTheme.unchecked.opacity(0.3), lineWidth: 1)
        )
    }
}

struct CategorySectionView: View {
    let category: String
    let items: [PackingItem]
    let onToggle: (PackingItem) -> Void
    let onDelete: (PackingItem) -> Void

    @State private var isExpanded = true

    private var packedCount: Int {
        items.filter { $0.isPacked }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    if packedCount == items.count && items.count > 0 {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(HaulTheme.checkedGreen)
                    }

                    Text(category)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(HaulTheme.textSecondary)
                        .tracking(1.5)
                        .textCase(.uppercase)

                    Spacer()

                    Text("\(packedCount)/\(items.count)")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(HaulTheme.textSecondary)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(HaulTheme.textSecondary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }

            if isExpanded {
                VStack(spacing: 1) {
                    ForEach(items) { item in
                        PackingItemRow(item: item, onToggle: { onToggle(item) }, onDelete: { onDelete(item) })
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

struct PackingItemRow: View {
    let item: PackingItem
    let onToggle: () -> Void
    let onDelete: () -> Void

    @State private var showDelete = false

    var body: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            onToggle()
        } label: {
            HStack(spacing: 12) {
                // Checkbox
                ZStack {
                    Circle()
                        .stroke(item.isPacked ? HaulTheme.checkedGreen : HaulTheme.unchecked, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if item.isPacked {
                        Circle()
                            .fill(HaulTheme.checkedGreen)
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                Text(item.name)
                    .font(.system(size: 15))
                    .foregroundColor(item.isPacked ? HaulTheme.textSecondary : HaulTheme.textPrimary)
                    .strikethrough(item.isPacked, color: HaulTheme.textSecondary)
                    .opacity(item.isPacked ? 0.6 : 1)

                Spacer()

                if item.isPacked {
                    Text("Packed")
                        .font(.system(size: 11))
                        .foregroundColor(HaulTheme.checkedGreen)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .background(
                HStack(spacing: 0) {
                    if item.isPacked {
                        Rectangle()
                            .fill(HaulTheme.checkedGreen)
                            .frame(width: 3)
                    }
                    Color.white.opacity(0.5)
                }
            )
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct PackingProgressView: View {
    let packed: Int
    let total: Int

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(packed) / Double(total)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Packing Progress")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(HaulTheme.textSecondary)
                    .tracking(1)
                    .textCase(.uppercase)

                Spacer()

                Text("\(Int(progress * 100))%")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(progress == 1.0 ? HaulTheme.checkedGreen : HaulTheme.textPrimary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(HaulTheme.unchecked.opacity(0.3))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(progress == 1.0 ? HaulTheme.checkedGreen : HaulTheme.accent)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 8)
        }
        .padding(16)
        .background(VisualEffectBlur(blurStyle: .systemMaterial))
        .cornerRadius(12)
    }
}

struct PassportReminderCard: View {
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "rectangle.portrait.and.arrow.right")
                .font(.system(size: 24))
                .foregroundColor(HaulTheme.accent)

            VStack(alignment: .leading, spacing: 4) {
                Text("Passport")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(HaulTheme.textPrimary)
                Text("Have you packed it?")
                    .font(.system(size: 13))
                    .foregroundColor(HaulTheme.textSecondary)
            }

            Spacer()

            Button {
                onDismiss()
            } label: {
                Text("Yes!")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(HaulTheme.checkedGreen)
                    .cornerRadius(8)
            }
        }
        .padding(16)
        .background(
            ZStack {
                VisualEffectBlur(blurStyle: .systemMaterial)
                RoundedRectangle(cornerRadius: 16)
                    .stroke(HaulTheme.accent.opacity(0.3), lineWidth: 1)
            }
        )
        .cornerRadius(16)
    }
}

struct AddItemSheet: View {
    @EnvironmentObject var tripStore: TripStore
    @Environment(\.dismiss) var dismiss
    let tripId: Int64

    @State private var itemName = ""
    @State private var selectedCategory = "CLOTHES"

    private let categories = DefaultCategories.all.map { $0.name }

    var body: some View {
        NavigationStack {
            ZStack {
                HaulTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Item Name")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(HaulTheme.textSecondary)
                            .tracking(1)
                            .textCase(.uppercase)

                        TextField("e.g. 3x T-shirts", text: $itemName)
                            .font(.system(size: 17))
                            .padding(16)
                            .background(HaulTheme.surfaceLight)
                            .cornerRadius(12)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(HaulTheme.textSecondary)
                            .tracking(1)
                            .textCase(.uppercase)

                        Picker("", selection: $selectedCategory) {
                            ForEach(categories, id: \.self) { cat in
                                Text(cat).tag(cat)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Spacer()

                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        if !itemName.isEmpty {
                            tripStore.addItem(to: tripId, name: itemName, category: selectedCategory)
                            dismiss()
                        }
                    } label: {
                        Text("Add Item")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(itemName.isEmpty ? HaulTheme.unchecked : HaulTheme.accent)
                            .cornerRadius(12)
                    }
                    .disabled(itemName.isEmpty)
                }
                .padding(20)
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(HaulTheme.textSecondary)
                }
            }
        }
    }
}
