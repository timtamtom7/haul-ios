import SwiftUI

struct TemplatesListView: View {
    @EnvironmentObject var tripStore: TripStore
    @Environment(\.dismiss) var dismiss
    let tripId: Int64?
    let onApply: ((PackingTemplate) -> Void)?

    @State private var templates: [PackingTemplate] = []
    @State private var showingSaveTemplate = false
    @State private var showingSaveError = false
    @State private var selectedTemplate: PackingTemplate?

    init(tripId: Int64? = nil, onApply: ((PackingTemplate) -> Void)? = nil) {
        self.tripId = tripId
        self.onApply = onApply
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HaulTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Save current as template button
                        if tripId != nil {
                            Button {
                                showingSaveTemplate = true
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(HaulTheme.accent.opacity(0.12))
                                            .frame(width: 44, height: 44)

                                        Image(systemName: "square.and.arrow.down.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(HaulTheme.accent)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Save current list as template")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(HaulTheme.textPrimary)
                                        Text("Create a reusable packing template")
                                            .font(.system(size: 12))
                                            .foregroundColor(HaulTheme.textSecondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(HaulTheme.textSecondary)
                                }
                                .padding(14)
                                .background(VisualEffectBlur(blurStyle: .systemMaterial))
                                .cornerRadius(14)
                            }
                            .buttonStyle(.plain)
                        }

                        // Built-in templates
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Built-in Templates")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(HaulTheme.textSecondary)
                                .tracking(1.5)
                                .textCase(.uppercase)

                            ForEach(PackingTemplate.builtInTemplates) { template in
                                TemplateCardView(
                                    template: template,
                                    onApply: {
                                        applyTemplate(template)
                                    }
                                )
                            }
                        }

                        // Custom templates
                        if !customTemplates.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Your Templates")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(HaulTheme.textSecondary)
                                    .tracking(1.5)
                                    .textCase(.uppercase)

                                ForEach(customTemplates) { template in
                                    TemplateCardView(
                                        template: template,
                                        onApply: {
                                            applyTemplate(template)
                                        },
                                        onDelete: {
                                            deleteTemplate(template)
                                        }
                                    )
                                }
                            }
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(HaulTheme.accent)
                }
            }
            .sheet(isPresented: $showingSaveTemplate) {
                SaveTemplateSheet(tripId: tripId ?? 0)
                    .environmentObject(tripStore)
            }
            .alert("Couldn't save template", isPresented: $showingSaveError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Something went wrong saving your template. Please try again.")
            }
            .onAppear {
                templates = tripStore.fetchAllTemplates()
            }
        }
    }

    private var customTemplates: [PackingTemplate] {
        templates.filter { !$0.isBuiltIn }
    }

    private func applyTemplate(_ template: PackingTemplate) {
        if let tripId = tripId, let apply = onApply {
            apply(template)
            dismiss()
        }
    }

    private func deleteTemplate(_ template: PackingTemplate) {
        if tripStore.deleteTemplate(template) {
            templates = tripStore.fetchAllTemplates()
        }
    }
}

struct TemplateCardView: View {
    let template: PackingTemplate
    let onApply: () -> Void
    var onDelete: (() -> Void)? = nil

    @State private var isExpanded = false

    private var totalItems: Int {
        template.categories.reduce(0) { $0 + $1.items.count }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 14) {
                    // Template icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(HaulTheme.accent.opacity(0.12))
                            .frame(width: 44, height: 44)

                        Image(systemName: templateIcon)
                            .font(.system(size: 18))
                            .foregroundColor(HaulTheme.accent)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(template.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(HaulTheme.textPrimary)

                        HStack(spacing: 6) {
                            Text("\(template.categories.count) categories")
                            Text("·")
                                .foregroundColor(HaulTheme.textSecondary)
                            Text("\(totalItems) items")
                        }
                        .font(.system(size: 12))
                        .foregroundColor(HaulTheme.textSecondary)
                    }

                    Spacer()

                    if !template.isBuiltIn {
                        Text("Custom")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(HaulTheme.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(HaulTheme.accent.opacity(0.1))
                            .cornerRadius(4)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(HaulTheme.textSecondary)
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    if !template.description.isEmpty {
                        Text(template.description)
                            .font(.system(size: 13))
                            .foregroundColor(HaulTheme.textSecondary)
                            .padding(.horizontal, 14)
                    }

                    // Categories preview
                    ForEach(template.categories) { category in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(category.name)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(HaulTheme.textSecondary)
                                .tracking(1)
                                .textCase(.uppercase)

                            FlowLayout(spacing: 6) {
                                ForEach(category.items.prefix(5), id: \.self) { item in
                                    Text(item)
                                        .font(.system(size: 12))
                                        .foregroundColor(HaulTheme.textPrimary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(HaulTheme.unchecked.opacity(0.2))
                                        .cornerRadius(6)
                                }
                                if category.items.count > 5 {
                                    Text("+\(category.items.count - 5) more")
                                        .font(.system(size: 11))
                                        .foregroundColor(HaulTheme.textSecondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 5)
                                        .background(HaulTheme.unchecked.opacity(0.1))
                                        .cornerRadius(6)
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                    }

                    // Action buttons
                    HStack(spacing: 12) {
                        Button {
                            onApply()
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Apply Template")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(HaulTheme.accent)
                            .cornerRadius(8)
                        }

                        if let onDelete = onDelete {
                            Button {
                                onDelete()
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 14))
                                    .foregroundColor(.red)
                                    .padding(10)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 4)
                }
                .padding(.bottom, 14)
            }
        }
        .background(VisualEffectBlur(blurStyle: .systemMaterial))
        .cornerRadius(16)
    }

    private var templateIcon: String {
        switch template.name.lowercased() {
        case let n where n.contains("beach"):
            return "sun.max.fill"
        case let n where n.contains("business"):
            return "briefcase.fill"
        case let n where n.contains("camping") || n.contains("adventure"):
            return "figure.hiking"
        case let n where n.contains("city"):
            return "building.2.fill"
        default:
            return "suitcase.fill"
        }
    }
}

struct SaveTemplateSheet: View {
    @EnvironmentObject var tripStore: TripStore
    @Environment(\.dismiss) var dismiss
    let tripId: Int64

    @State private var templateName = ""
    @State private var templateDescription = ""
    @State private var categories: [TemplateCategory] = []
    @State private var showingError = false
    @State private var showingSuccess = false

    var body: some View {
        NavigationStack {
            ZStack {
                HaulTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Template Name")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(HaulTheme.textSecondary)
                            .tracking(1)
                            .textCase(.uppercase)

                        TextField("e.g. Beach Vacation", text: $templateName)
                            .font(.system(size: 17))
                            .padding(16)
                            .background(HaulTheme.surfaceLight)
                            .cornerRadius(12)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description (optional)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(HaulTheme.textSecondary)
                            .tracking(1)
                            .textCase(.uppercase)

                        TextField("e.g. Perfect for a week at the beach", text: $templateDescription)
                            .font(.system(size: 17))
                            .padding(16)
                            .background(HaulTheme.surfaceLight)
                            .cornerRadius(12)
                    }

                    // Items preview
                    if !categories.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Items to save (\(categories.reduce(0) { $0 + $1.items.count }))")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(HaulTheme.textSecondary)
                                .tracking(1)
                                .textCase(.uppercase)

                            ScrollView {
                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(categories) { cat in
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(cat.name)
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundColor(HaulTheme.textSecondary)
                                                .tracking(1)

                                            FlowLayout(spacing: 6) {
                                                ForEach(cat.items, id: \.self) { item in
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
                                }
                            }
                            .frame(maxHeight: 200)
                        }
                    }

                    Spacer()

                    Button {
                        saveTemplate()
                    } label: {
                        Text("Save Template")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(templateName.isEmpty ? HaulTheme.unchecked : HaulTheme.checkedGreen)
                            .cornerRadius(12)
                    }
                    .disabled(templateName.isEmpty)
                }
                .padding(20)
            }
            .navigationTitle("Save Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(HaulTheme.textSecondary)
                }
            }
            .alert("Couldn't save template", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Something went wrong. Please try again.")
            }
            .alert("Template saved!", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            }
            .onAppear {
                loadTripItems()
            }
        }
    }

    private func loadTripItems() {
        let items = tripStore.getAllItems(for: tripId)
        let grouped = Dictionary(grouping: items, by: { $0.category })
        categories = DefaultCategories.all.compactMap { cat in
            if let items = grouped[cat.name], !items.isEmpty {
                return TemplateCategory(name: cat.name, items: items.map { $0.name })
            }
            return nil
        }
    }

    private func saveTemplate() {
        if categories.isEmpty {
            showingError = true
            return
        }

        if tripStore.saveTemplate(name: templateName, description: templateDescription, categories: categories) {
            showingSuccess = true
        } else {
            showingError = true
        }
    }
}
