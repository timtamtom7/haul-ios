import SwiftUI
import AVFoundation

struct NewTripSheet: View {
    @EnvironmentObject var tripStore: TripStore
    @Environment(\.dismiss) var dismiss
    @StateObject private var cameraService = CameraService()

    @State private var tripName = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(86400 * 7)
    @State private var showingCamera = false
    @State private var capturedImage: UIImage?
    @State private var suitcasePhotoPath: String?
    @State private var newItemName = ""
    @State private var selectedCategory = "CLOTHES"
    @State private var addedItems: [(name: String, category: String)] = []
    @State private var currentStep = 0

    @State private var showingCameraPermissionError = false
    @State private var showingItemSaveError = false
    @State private var showingPhotoSaveError = false

    private let categories = DefaultCategories.all.map { $0.name }

    var body: some View {
        NavigationStack {
            ZStack {
                HaulTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Progress indicator
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { step in
                            Capsule()
                                .fill(step <= currentStep ? HaulTheme.accent : HaulTheme.unchecked)
                                .frame(height: 4)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    TabView(selection: $currentStep) {
                        // Step 1: Trip Details
                        tripDetailsStep
                            .tag(0)

                        // Step 2: Photo
                        photoStep
                            .tag(1)

                        // Step 3: Items
                        itemsStep
                            .tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentStep)

                    // Navigation buttons
                    HStack(spacing: 12) {
                        if currentStep > 0 {
                            Button("Back") {
                                withAnimation {
                                    currentStep -= 1
                                }
                            }
                            .foregroundColor(HaulTheme.textSecondary)
                        }

                        Spacer()

                        if currentStep < 2 {
                            Button {
                                withAnimation {
                                    currentStep += 1
                                }
                            } label: {
                                Text(currentStep == 0 ? "Next" : "Add Photo")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(tripName.isEmpty ? HaulTheme.unchecked : HaulTheme.accent)
                                    .cornerRadius(10)
                            }
                            .disabled(currentStep == 0 && tripName.isEmpty)
                        } else {
                            Button {
                                saveTrip()
                            } label: {
                                Text("Start Packing")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(HaulTheme.checkedGreen)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("New Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(HaulTheme.textSecondary)
                }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView { image in
                    capturedImage = image
                    if let path = PhotoStorageService.shared.savePhoto(image, for: Int64(Date().timeIntervalSince1970)) {
                        suitcasePhotoPath = path
                    } else {
                        showingPhotoSaveError = true
                    }
                }
            }
            .alert("Couldn't save photo", isPresented: $showingPhotoSaveError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("The photo couldn't be saved. Make sure you have enough storage space.")
            }
        }
    }

    private var tripDetailsStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Trip Name")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(HaulTheme.textSecondary)
                        .tracking(1)
                        .textCase(.uppercase)

                    TextField("e.g. Tokyo Trip", text: $tripName)
                        .font(.system(size: 17))
                        .padding(16)
                        .background(HaulTheme.surfaceLight)
                        .cornerRadius(12)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Start Date")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(HaulTheme.textSecondary)
                        .tracking(1)
                        .textCase(.uppercase)

                    DatePicker("", selection: $startDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .padding(12)
                        .background(HaulTheme.surfaceLight)
                        .cornerRadius(12)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("End Date")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(HaulTheme.textSecondary)
                        .tracking(1)
                        .textCase(.uppercase)

                    DatePicker("", selection: $endDate, in: startDate..., displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .padding(12)
                        .background(HaulTheme.surfaceLight)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
        }
    }

    private var photoStep: some View {
        VStack(spacing: 24) {
            Text("Photograph your empty suitcase")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(HaulTheme.textPrimary)

            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 300)
                    .clipped()
                    .cornerRadius(16)
                    .padding(.horizontal, 20)

                Button("Retake Photo") {
                    openCamera()
                }
                .foregroundColor(HaulTheme.accent)
            } else {
                Button {
                    openCamera()
                } label: {
                    VStack(spacing: 16) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 48))
                            .foregroundColor(HaulTheme.accent)

                        Text("Take Photo")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(HaulTheme.textPrimary)

                        Text("You can skip this step")
                            .font(.system(size: 12))
                            .foregroundColor(HaulTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .background(HaulTheme.surfaceLight)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 20)
            }

            // Skip photo button
            if capturedImage == nil {
                Button("Skip photo") {
                    withAnimation {
                        currentStep += 1
                    }
                }
                .font(.system(size: 14))
                .foregroundColor(HaulTheme.textSecondary)
            }

            Spacer()
        }
        .padding(.top, 24)
        .overlay {
            if showingCameraPermissionError {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showingCameraPermissionError = false
                        }

                    CameraPermissionView(
                        cameraService: cameraService,
                        onPhotoCaptured: { image in
                            capturedImage = image
                            showingCamera = false
                            showingCameraPermissionError = false
                        },
                        onDismiss: {
                            showingCameraPermissionError = false
                        }
                    )
                }
            }
        }
    }

    private func openCamera() {
        cameraService.checkAuthorization()
        if cameraService.isAuthorized {
            showingCamera = true
        } else {
            showingCameraPermissionError = true
        }
    }

    private var itemsStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Add items to pack")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(HaulTheme.textPrimary)

                // Add custom item
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add Item")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(HaulTheme.textSecondary)
                        .tracking(1)
                        .textCase(.uppercase)

                    HStack {
                        TextField("e.g. 3x T-shirts", text: $newItemName)
                            .font(.system(size: 15))

                        Picker("", selection: $selectedCategory) {
                            ForEach(categories, id: \.self) { cat in
                                Text(cat).tag(cat)
                            }
                        }
                        .pickerStyle(.menu)

                        Button {
                            if !newItemName.isEmpty {
                                addedItems.append((name: newItemName, category: selectedCategory))
                                newItemName = ""
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(HaulTheme.accent)
                                .font(.system(size: 24))
                        }
                    }
                    .padding(12)
                    .background(HaulTheme.surfaceLight)
                    .cornerRadius(12)
                }

                // Category suggestions
                ForEach(DefaultCategories.all) { category in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(category.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(HaulTheme.textSecondary)
                            .tracking(1)
                            .textCase(.uppercase)

                        FlowLayout(spacing: 8) {
                            ForEach(category.items, id: \.self) { item in
                                Button {
                                    addedItems.append((name: item, category: category.name))
                                } label: {
                                    Text(item)
                                        .font(.system(size: 13))
                                        .foregroundColor(HaulTheme.textPrimary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(HaulTheme.surfaceLight)
                                        .cornerRadius(20)
                                }
                            }
                        }
                    }
                }

                // Added items
                if !addedItems.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Added Items")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(HaulTheme.textSecondary)
                            .tracking(1)
                            .textCase(.uppercase)

                        ForEach(addedItems.indices, id: \.self) { index in
                            HStack {
                                Text(addedItems[index].name)
                                    .font(.system(size: 15))
                                Text("·")
                                    .foregroundColor(HaulTheme.textSecondary)
                                Text(addedItems[index].category)
                                    .font(.system(size: 12))
                                    .foregroundColor(HaulTheme.textSecondary)
                                Spacer()
                                Button {
                                    addedItems.remove(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(HaulTheme.textSecondary)
                                }
                            }
                            .padding(12)
                            .background(HaulTheme.surfaceLight.opacity(0.5))
                            .cornerRadius(8)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 100)
        }
    }

    private func saveTrip() {
        var photoPath = suitcasePhotoPath
        if let image = capturedImage, photoPath == nil {
            if let path = PhotoStorageService.shared.savePhoto(image, for: Int64(Date().timeIntervalSince1970)) {
                photoPath = path
            } else {
                showingPhotoSaveError = true
                return
            }
        }

        guard let tripId = tripStore.createTrip(name: tripName, startDate: startDate, endDate: endDate, suitcasePhotoPath: photoPath) else {
            showingItemSaveError = true
            return
        }

        // Add items
        for item in addedItems {
            tripStore.addItem(to: tripId, name: item.name, category: item.category)
        }

        // Schedule reminders
        let trip = Trip(id: tripId, name: tripName, startDate: startDate, endDate: endDate, suitcasePhotoPath: photoPath, createdAt: Date())
        ReminderService.shared.scheduleDepartureReminder(for: trip)
        ReminderService.shared.schedulePassportReminder(for: trip)

        dismiss()
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return CGSize(width: proposal.width ?? 0, height: result.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var positions: [CGPoint] = []
        var height: CGFloat = 0

        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > width, x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }
            height = y + rowHeight
        }
    }
}
