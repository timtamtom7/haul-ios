import SwiftUI

struct PostTripFeedbackView: View {
    @EnvironmentObject var tripStore: TripStore
    @Environment(\.dismiss) var dismiss
    let trip: Trip

    @State private var rating: Int = 0
    @State private var forgotItems: [String] = []
    @State private var unusedItems: [String] = []
    @State private var notes: String = ""
    @State private var newForgotItem: String = ""
    @State private var newUnusedItem: String = ""
    @State private var hasSubmitted = false
    @State private var showingError = false
    @State private var loadedItems: [PackingItem] = []

    var body: some View {
        NavigationStack {
            ZStack {
                HaulTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        // Header
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(HaulTheme.accent.opacity(0.1))
                                    .frame(width: 80, height: 80)

                                Image(systemName: "star.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(HaulTheme.accent)
                            }

                            Text("How was \(trip.name)?")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(HaulTheme.textPrimary)

                            Text("Your feedback helps improve future trips")
                                .font(.system(size: 14))
                                .foregroundColor(HaulTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)

                        // Star rating
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Trip Rating")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(HaulTheme.textSecondary)
                                .tracking(1)
                                .textCase(.uppercase)

                            HStack(spacing: 12) {
                                ForEach(1...5, id: \.self) { star in
                                    Button {
                                        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                            rating = star
                                        }
                                    } label: {
                                        Image(systemName: star <= rating ? "star.fill" : "star")
                                            .font(.system(size: 32))
                                            .foregroundColor(star <= rating ? .yellow : HaulTheme.unchecked)
                                            .scaleEffect(star <= rating ? 1.1 : 1.0)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(16)
                        .background(VisualEffectBlur(blurStyle: .systemMaterial))
                        .cornerRadius(16)

                        // Forgot items
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 18))

                                Text("Forgot to pack")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(HaulTheme.textSecondary)
                                    .tracking(1)
                                    .textCase(.uppercase)
                            }

                            Text("What did you wish you had?")
                                .font(.system(size: 13))
                                .foregroundColor(HaulTheme.textSecondary)

                            // Suggested items from trip
                            if !loadedItems.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(suggestedForgotItems, id: \.self) { item in
                                            Button {
                                                if !forgotItems.contains(item) {
                                                    forgotItems.append(item)
                                                }
                                            } label: {
                                                Text(item)
                                                    .font(.system(size: 13))
                                                    .foregroundColor(forgotItems.contains(item) ? .white : HaulTheme.textPrimary)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 7)
                                                    .background(forgotItems.contains(item) ? Color.red : HaulTheme.unchecked.opacity(0.3))
                                                    .cornerRadius(16)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }

                            // Add custom item
                            HStack {
                                TextField("Add item...", text: $newForgotItem)
                                    .font(.system(size: 15))
                                    .padding(12)
                                    .background(HaulTheme.surfaceLight)
                                    .cornerRadius(10)

                                Button {
                                    if !newForgotItem.isEmpty {
                                        forgotItems.append(newForgotItem)
                                        newForgotItem = ""
                                    }
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 26))
                                        .foregroundColor(HaulTheme.accent)
                                }
                            }

                            // Added items
                            FlowLayout(spacing: 8) {
                                ForEach(forgotItems, id: \.self) { item in
                                    AddedItemChip(text: item, color: .red) {
                                        forgotItems.removeAll { $0 == item }
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(VisualEffectBlur(blurStyle: .systemMaterial))
                        .cornerRadius(16)

                        // Unused items
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(HaulTheme.textSecondary)
                                    .font(.system(size: 18))

                                Text("Didn't wear/use")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(HaulTheme.textSecondary)
                                    .tracking(1)
                                    .textCase(.uppercase)
                            }

                            Text("What did you pack but never use?")
                                .font(.system(size: 13))
                                .foregroundColor(HaulTheme.textSecondary)

                            // Suggested items
                            if !loadedItems.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(suggestedUnusedItems, id: \.self) { item in
                                            Button {
                                                if !unusedItems.contains(item) {
                                                    unusedItems.append(item)
                                                }
                                            } label: {
                                                Text(item)
                                                    .font(.system(size: 13))
                                                    .foregroundColor(unusedItems.contains(item) ? .white : HaulTheme.textPrimary)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 7)
                                                    .background(unusedItems.contains(item) ? HaulTheme.textSecondary : HaulTheme.unchecked.opacity(0.3))
                                                    .cornerRadius(16)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }

                            HStack {
                                TextField("Add item...", text: $newUnusedItem)
                                    .font(.system(size: 15))
                                    .padding(12)
                                    .background(HaulTheme.surfaceLight)
                                    .cornerRadius(10)

                                Button {
                                    if !newUnusedItem.isEmpty {
                                        unusedItems.append(newUnusedItem)
                                        newUnusedItem = ""
                                    }
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 26))
                                        .foregroundColor(HaulTheme.accent)
                                }
                            }

                            FlowLayout(spacing: 8) {
                                ForEach(unusedItems, id: \.self) { item in
                                    AddedItemChip(text: item, color: HaulTheme.textSecondary) {
                                        unusedItems.removeAll { $0 == item }
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(VisualEffectBlur(blurStyle: .systemMaterial))
                        .cornerRadius(16)

                        // Notes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(HaulTheme.textSecondary)
                                .tracking(1)
                                .textCase(.uppercase)

                            TextEditor(text: $notes)
                                .font(.system(size: 15))
                                .frame(minHeight: 100)
                                .padding(12)
                                .background(HaulTheme.surfaceLight)
                                .cornerRadius(12)
                                .scrollContentBackground(.hidden)
                        }
                        .padding(16)
                        .background(VisualEffectBlur(blurStyle: .systemMaterial))
                        .cornerRadius(16)

                        // Submit
                        Button {
                            submitFeedback()
                        } label: {
                            Text("Save Feedback")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(rating == 0 ? HaulTheme.unchecked : HaulTheme.checkedGreen)
                                .cornerRadius(12)
                        }
                        .disabled(rating == 0)

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Trip Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(HaulTheme.accent)
                }
            }
            .alert("Couldn't save feedback", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Something went wrong. Please try again.")
            }
            .onAppear {
                loadTripData()
            }
        }
    }

    private var loadedItemNames: [String] {
        loadedItems.map { $0.name }
    }

    private var suggestedForgotItems: [String] {
        loadedItemNames.filter { !forgotItems.contains($0) && !unusedItems.contains($0) }
    }

    private var suggestedUnusedItems: [String] {
        loadedItemNames.filter { !unusedItems.contains($0) && !forgotItems.contains($0) }
    }

    private func loadTripData() {
        if let tripId = trip.id {
            tripStore.fetchFeedback(for: tripId)
            loadedItems = tripStore.getAllItems(for: tripId)

            // Load existing feedback if available
            if let existing = tripStore.currentTripFeedback {
                rating = existing.rating
                forgotItems = existing.forgotItems
                unusedItems = existing.unusedItems
                notes = existing.notes
            }
        }
    }

    private func submitFeedback() {
        guard let tripId = trip.id else { return }

        let feedback = TripFeedback(
            id: tripStore.currentTripFeedback?.id,
            tripId: tripId,
            rating: rating,
            forgotItems: forgotItems,
            unusedItems: unusedItems,
            notes: notes
        )

        if tripStore.saveFeedback(feedback) {
            dismiss()
        } else {
            showingError = true
        }
    }
}

struct AddedItemChip: View {
    let text: String
    let color: Color
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(text)
                .font(.system(size: 13))

            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(color.opacity(0.6))
            }
        }
        .foregroundColor(HaulTheme.textPrimary)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(color.opacity(0.12))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct TripFeedbackSummaryCard: View {
    let feedback: TripFeedback
    let trip: Trip

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Trip Rating")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(HaulTheme.textSecondary)
                    .tracking(1)
                    .textCase(.uppercase)

                Spacer()

                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= feedback.rating ? "star.fill" : "star")
                            .font(.system(size: 12))
                            .foregroundColor(star <= feedback.rating ? .yellow : HaulTheme.unchecked)
                    }
                }
            }

            if !feedback.forgotItems.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.red)
                        Text("Forgot")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(HaulTheme.textSecondary)
                    }

                    FlowLayout(spacing: 6) {
                        ForEach(feedback.forgotItems, id: \.self) { item in
                            Text(item)
                                .font(.system(size: 12))
                                .foregroundColor(HaulTheme.textPrimary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(6)
                        }
                    }
                }
            }

            if !feedback.unusedItems.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(HaulTheme.textSecondary)
                        Text("Skipped")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(HaulTheme.textSecondary)
                    }

                    FlowLayout(spacing: 6) {
                        ForEach(feedback.unusedItems, id: \.self) { item in
                            Text(item)
                                .font(.system(size: 12))
                                .foregroundColor(HaulTheme.textPrimary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(HaulTheme.unchecked.opacity(0.2))
                                .cornerRadius(6)
                        }
                    }
                }
            }

            if !feedback.notes.isEmpty {
                Text(feedback.notes)
                    .font(.system(size: 13))
                    .foregroundColor(HaulTheme.textSecondary)
                    .lineSpacing(3)
            }
        }
        .padding(16)
        .background(VisualEffectBlur(blurStyle: .systemMaterial))
        .cornerRadius(16)
    }
}

struct PostTripBannerView: View {
    let trip: Trip
    let onGiveFeedback: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(HaulTheme.accent.opacity(0.12))
                        .frame(width: 48, height: 48)

                    Image(systemName: "star.fill")
                        .font(.system(size: 20))
                        .foregroundColor(HaulTheme.accent)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("How was \(trip.name)?")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(HaulTheme.textPrimary)

                    Text("Share your feedback to improve future trips")
                        .font(.system(size: 13))
                        .foregroundColor(HaulTheme.textSecondary)
                }

                Spacer()
            }

            Button {
                onGiveFeedback()
            } label: {
                HStack {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 14))
                    Text("Give Feedback")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(HaulTheme.accent)
                .cornerRadius(10)
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
