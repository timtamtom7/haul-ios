import SwiftUI

struct BagsListView: View {
    @EnvironmentObject var tripStore: TripStore
    @Environment(\.dismiss) var dismiss
    let trip: Trip

    @State private var showingAddBag = false
    @State private var showingBagError = false
    @State private var selectedBag: Bag?
    @State private var showingEditBag = false

    var body: some View {
        NavigationStack {
            ZStack {
                HaulTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Default "All" bag
                        AllItemsBagCard(
                            trip: trip,
                            packedCount: tripStore.packedCount(for: trip.id ?? 0),
                            totalCount: tripStore.totalCount(for: trip.id ?? 0)
                        )

                        // Individual bags
                        ForEach(tripStore.currentTripBags) { bag in
                            BagCardView(
                                bag: bag,
                                packedCount: tripStore.bagPackedCount(for: bag.id ?? 0),
                                totalCount: tripStore.bagItemCount(for: bag.id ?? 0),
                                onTap: {
                                    selectedBag = bag
                                    showingEditBag = true
                                },
                                onDelete: {
                                    tripStore.deleteBag(bag)
                                }
                            )
                        }

                        // Add bag button
                        Button {
                            showingAddBag = true
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .stroke(HaulTheme.accent, style: StrokeStyle(lineWidth: 2, dash: [6]))
                                        .frame(width: 44, height: 44)

                                    Image(systemName: "plus")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(HaulTheme.accent)
                                }

                                Text("Add another bag")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(HaulTheme.accent)

                                Spacer()
                            }
                            .padding(14)
                            .background(HaulTheme.surfaceLight.opacity(0.5))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(HaulTheme.accent.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [8]))
                            )
                        }
                        .buttonStyle(.plain)

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Bags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(HaulTheme.accent)
                }
            }
            .sheet(isPresented: $showingAddBag) {
                AddBagSheet(tripId: trip.id ?? 0)
                    .environmentObject(tripStore)
            }
            .sheet(isPresented: $showingEditBag) {
                if let bag = selectedBag {
                    BagDetailSheet(bag: bag, trip: trip)
                        .environmentObject(tripStore)
                }
            }
            .alert("Couldn't create bag", isPresented: $showingBagError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Something went wrong. Please try again.")
            }
            .onAppear {
                tripStore.fetchBags(for: trip.id ?? 0)
            }
        }
    }
}

struct AllItemsBagCard: View {
    let trip: Trip
    let packedCount: Int
    let totalCount: Int

    private var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(packedCount) / Double(totalCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(HaulTheme.accent.opacity(0.12))
                        .frame(width: 48, height: 48)

                    Image(systemName: "suitcase.fill")
                        .font(.system(size: 20))
                        .foregroundColor(HaulTheme.accent)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("All Items")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(HaulTheme.textPrimary)

                    Text("\(totalCount) total items")
                        .font(.system(size: 13))
                        .foregroundColor(HaulTheme.textSecondary)
                }

                Spacer()

                if totalCount > 0 {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 15, design: .monospaced))
                        .fontWeight(.semibold)
                        .foregroundColor(progress == 1.0 ? HaulTheme.checkedGreen : HaulTheme.accent)
                }
            }

            if totalCount > 0 {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(HaulTheme.unchecked.opacity(0.3))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(progress == 1.0 ? HaulTheme.checkedGreen : HaulTheme.accent)
                            .frame(width: geometry.size.width * progress, height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(16)
        .background(VisualEffectBlur(blurStyle: .systemMaterial))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(HaulTheme.accent.opacity(0.2), lineWidth: 1)
        )
    }
}

struct BagCardView: View {
    let bag: Bag
    let packedCount: Int
    let totalCount: Int
    let onTap: () -> Void
    let onDelete: () -> Void

    @State private var isExpanded = false

    private var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(packedCount) / Double(totalCount)
    }

    private var bagColor: Color {
        Color(hex: bag.colorHex)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                onTap()
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(bagColor.opacity(0.15))
                            .frame(width: 48, height: 48)

                        Image(systemName: bag.bagType.icon)
                            .font(.system(size: 20))
                            .foregroundColor(bagColor)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(bag.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(HaulTheme.textPrimary)

                        HStack(spacing: 6) {
                            Text(bag.bagType.rawValue)
                            Text("·")
                                .foregroundColor(HaulTheme.textSecondary)
                            Text("\(totalCount) items")
                        }
                        .font(.system(size: 13))
                        .foregroundColor(HaulTheme.textSecondary)
                    }

                    Spacer()

                    if totalCount > 0 {
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 15, design: .monospaced))
                            .fontWeight(.semibold)
                            .foregroundColor(progress == 1.0 ? HaulTheme.checkedGreen : bagColor)
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(HaulTheme.textSecondary)
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            if totalCount > 0 {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(HaulTheme.unchecked.opacity(0.3))
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(progress == 1.0 ? HaulTheme.checkedGreen : bagColor)
                            .frame(width: geometry.size.width * progress, height: 4)
                    }
                }
                .frame(height: 4)
            }
        }
        .background(VisualEffectBlur(blurStyle: .systemMaterial))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(bagColor.opacity(0.2), lineWidth: 1)
        )
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Bag", systemImage: "trash")
            }
        }
    }
}

struct AddBagSheet: View {
    @EnvironmentObject var tripStore: TripStore
    @Environment(\.dismiss) var dismiss
    let tripId: Int64

    @State private var bagName = ""
    @State private var selectedType: BagType = .carryOn
    @State private var selectedColor: String = "5d8c5d"
    @State private var showingError = false

    private let colorOptions = [
        "5d8c5d", "4a7ba7", "8B7355", "7a6b8a",
        "c4956a", "6b8e9f", "9b6b6b", "7a746a"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                HaulTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bag Name")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(HaulTheme.textSecondary)
                            .tracking(1)
                            .textCase(.uppercase)

                        TextField("e.g. Checked Luggage", text: $bagName)
                            .font(.system(size: 17))
                            .padding(16)
                            .background(HaulTheme.surfaceLight)
                            .cornerRadius(12)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bag Type")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(HaulTheme.textSecondary)
                            .tracking(1)
                            .textCase(.uppercase)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(BagType.allCases, id: \.self) { type in
                                Button {
                                    selectedType = type
                                    bagName = bagName.isEmpty ? type.rawValue : bagName
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: type.icon)
                                            .font(.system(size: 16))
                                        Text(type.rawValue)
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(selectedType == type ? .white : HaulTheme.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(selectedType == type ? Color(hex: selectedColor) : HaulTheme.surfaceLight)
                                    .cornerRadius(10)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Color")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(HaulTheme.textSecondary)
                            .tracking(1)
                            .textCase(.uppercase)

                        HStack(spacing: 12) {
                            ForEach(colorOptions, id: \.self) { color in
                                Button {
                                    selectedColor = color
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: color))
                                            .frame(width: 36, height: 36)

                                        if selectedColor == color {
                                            Circle()
                                                .stroke(Color(hex: color).opacity(0.3), lineWidth: 3)
                                                .frame(width: 44, height: 44)

                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Preview
                    HStack {
                        ZStack {
                            Circle()
                                .fill(Color(hex: selectedColor).opacity(0.15))
                                .frame(width: 56, height: 56)

                            Image(systemName: selectedType.icon)
                                .font(.system(size: 24))
                                .foregroundColor(Color(hex: selectedColor))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(bagName.isEmpty ? selectedType.rawValue : bagName)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(HaulTheme.textPrimary)

                            Text(selectedType.rawValue)
                                .font(.system(size: 13))
                                .foregroundColor(HaulTheme.textSecondary)
                        }

                        Spacer()
                    }
                    .padding(16)
                    .background(VisualEffectBlur(blurStyle: .systemMaterial))
                    .cornerRadius(14)

                    Spacer()

                    Button {
                        createBag()
                    } label: {
                        Text("Add Bag")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(HaulTheme.checkedGreen)
                            .cornerRadius(12)
                    }
                }
                .padding(20)
            }
            .navigationTitle("New Bag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(HaulTheme.textSecondary)
                }
            }
            .alert("Couldn't create bag", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Something went wrong. Please try again.")
            }
        }
    }

    private func createBag() {
        let name = bagName.isEmpty ? selectedType.rawValue : bagName
        if tripStore.createBag(tripIdValue: tripId, name: name, bagType: selectedType, colorHex: selectedColor) != nil {
            dismiss()
        } else {
            showingError = true
        }
    }
}

struct BagDetailSheet: View {
    @EnvironmentObject var tripStore: TripStore
    @Environment(\.dismiss) var dismiss
    let bag: Bag
    let trip: Trip

    @State private var bagItems: [PackingItem] = []
    @State private var showingAddItem = false
    @State private var bagName: String = ""
    @State private var showingDeleteConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                HaulTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Bag header
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: bag.colorHex).opacity(0.15))
                                    .frame(width: 56, height: 56)

                                Image(systemName: bag.bagType.icon)
                                    .font(.system(size: 24))
                                    .foregroundColor(Color(hex: bag.colorHex))
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(bag.name)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(HaulTheme.textPrimary)

                                Text(bag.bagType.rawValue)
                                    .font(.system(size: 14))
                                    .foregroundColor(HaulTheme.textSecondary)
                            }

                            Spacer()

                            // Progress
                            let packed = bagPackedCount
                            let total = bagItems.count
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("\(packed)/\(total)")
                                    .font(.system(size: 16, design: .monospaced))
                                    .fontWeight(.semibold)
                                    .foregroundColor(HaulTheme.textPrimary)

                                Text("packed")
                                    .font(.system(size: 12))
                                    .foregroundColor(HaulTheme.textSecondary)
                            }
                        }
                        .padding(16)
                        .background(VisualEffectBlur(blurStyle: .systemMaterial))
                        .cornerRadius(16)

                        // Items grouped by category
                        let groupedItems = Dictionary(grouping: bagItems, by: { $0.category })
                        ForEach(DefaultCategories.all.filter { groupedItems[$0.name] != nil }, id: \.name) { category in
                            if let items = groupedItems[category.name] {
                                CategorySectionView(
                                    category: category.name,
                                    items: items,
                                    onToggle: { item in
                                        tripStore.toggleItem(item)
                                        loadItems()
                                    },
                                    onDelete: { item in
                                        tripStore.deleteItem(item)
                                        loadItems()
                                    }
                                )
                            }
                        }

                        // Add item button
                        Button {
                            showingAddItem = true
                        } label: {
                            HStack {
                                Image(systemName: "plus")
                                Text("Add Item to Bag")
                            }
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(hex: bag.colorHex))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: bag.colorHex).opacity(0.1))
                            .cornerRadius(12)
                        }

                        // Delete bag
                        Button {
                            showingDeleteConfirm = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Bag")
                            }
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.red.opacity(0.08))
                            .cornerRadius(12)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationTitle(bag.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(HaulTheme.accent)
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddItemToBagSheet(tripId: trip.id ?? 0, bagId: bag.id ?? 0)
                    .environmentObject(tripStore)
            }
            .alert("Delete this bag?", isPresented: $showingDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    tripStore.deleteBag(bag)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Items in this bag will be moved to Unassigned.")
            }
            .onAppear {
                loadItems()
            }
        }
    }

    private func loadItems() {
        bagItems = tripStore.fetchItems(forBag: bag.id ?? 0)
    }

    private var bagPackedCount: Int {
        bagItems.filter { $0.isPacked }.count
    }
}

struct AddItemToBagSheet: View {
    @EnvironmentObject var tripStore: TripStore
    @Environment(\.dismiss) var dismiss
    let tripId: Int64
    let bagId: Int64

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
                        if !itemName.isEmpty {
                            tripStore.addItem(to: tripId, name: itemName, category: selectedCategory, bagId: bagId)
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
