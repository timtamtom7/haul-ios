import SwiftUI

struct CommunityTemplatesView: View {
    @EnvironmentObject var tripStore: TripStore
    @Environment(\.dismiss) var dismiss
    let tripId: Int64?
    let onApply: ((PackingTemplate) -> Void)?

    @State private var selectedCategory: String = "All"
    @State private var searchText = ""
    @State private var communityTemplates: [CommunityTemplate] = CommunityTemplate.samples
    @State private var importedTemplates: Set<Int64> = []
    @State private var showImported = false

    init(tripId: Int64? = nil, onApply: ((PackingTemplate) -> Void)? = nil) {
        self.tripId = tripId
        self.onApply = onApply
    }

    private let categories = ["All", "Beach", "City", "Business", "Adventure", "Camping", "Winter"]

    private var filteredTemplates: [CommunityTemplate] {
        communityTemplates.filter { t in
            (selectedCategory == "All" || t.category == selectedCategory) &&
            (searchText.isEmpty || t.name.localizedCaseInsensitiveContains(searchText) || t.tags.contains { $0.localizedCaseInsensitiveContains(searchText) })
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "f5f3ef")
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color(hex: "7a746a"))
                            .font(.system(size: 15))
                        TextField("Search templates...", text: $searchText)
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "1a1814"))
                    }
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Category filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories, id: \.self) { cat in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        selectedCategory = cat
                                    }
                                } label: {
                                    Text(cat)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(selectedCategory == cat ? .white : Color(hex: "7a746a"))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 7)
                                        .background(selectedCategory == cat ? Color(hex: "c4956a") : Color(hex: "d4cfc6").opacity(0.5))
                                        .cornerRadius(20)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 12)

                    ScrollView {
                        VStack(spacing: 16) {
                            // Popular this week
                            if selectedCategory == "All" && searchText.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "flame.fill")
                                            .foregroundColor(.orange)
                                            .font(.system(size: 14))
                                        Text("Popular this week")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(Color(hex: "7a746a"))
                                            .tracking(1)
                                            .textCase(.uppercase)
                                    }
                                    .padding(.horizontal, 20)

                                    ForEach(communityTemplates.filter { $0.isPopular }.prefix(3)) { template in
                                        CommunityTemplateCard(
                                            template: template,
                                            isImported: importedTemplates.contains(template.id),
                                            onImport: { importTemplate(template) },
                                            onApply: { applyTemplate(template) }
                                        )
                                        .padding(.horizontal, 20)
                                    }
                                }

                                Divider()
                                    .padding(.top, 8)
                                    .padding(.horizontal, 20)
                            }

                            // All templates
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(selectedCategory == "All" ? "All Templates" : selectedCategory)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(Color(hex: "7a746a"))
                                        .tracking(1)
                                        .textCase(.uppercase)

                                    Spacer()

                                    Text("\(filteredTemplates.count) templates")
                                        .font(.system(size: 11))
                                        .foregroundColor(Color(hex: "7a746a"))
                                }
                                .padding(.horizontal, 20)

                                ForEach(filteredTemplates) { template in
                                    CommunityTemplateCard(
                                        template: template,
                                        isImported: importedTemplates.contains(template.id),
                                        onImport: { importTemplate(template) },
                                        onApply: { applyTemplate(template) }
                                    )
                                    .padding(.horizontal, 20)
                                }
                            }

                            Spacer(minLength: 40)
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("Community Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(hex: "c4956a"))
                }
            }
        }
    }

    private func importTemplate(_ community: CommunityTemplate) {
        importedTemplates.insert(community.id)
        // Save to local templates
        let packingTemplate = PackingTemplate(
            id: nil,
            name: community.name,
            description: community.description,
            categories: community.categories,
            isBuiltIn: false
        )
        tripStore.saveTemplate(name: packingTemplate.name, description: packingTemplate.description, categories: packingTemplate.categories)
    }

    private func applyTemplate(_ community: CommunityTemplate) {
        if let tripId = tripId, let onApply = onApply {
            let packingTemplate = PackingTemplate(
                id: nil,
                name: community.name,
                description: community.description,
                categories: community.categories,
                isBuiltIn: false
            )
            onApply(packingTemplate)
            dismiss()
        }
    }
}

struct CommunityTemplate: Identifiable {
    let id: Int64
    let name: String
    let description: String
    let category: String
    let tags: [String]
    let categories: [TemplateCategory]
    let authorName: String
    let downloadCount: Int
    let rating: Double
    let isPopular: Bool

    static let samples: [CommunityTemplate] = [
        CommunityTemplate(
            id: 1001,
            name: "Ultimate Japan Trip",
            description: "2 weeks exploring Tokyo, Kyoto and Osaka — all seasons covered",
            category: "Adventure",
            tags: ["japan", "asia", "travel", "2 weeks"],
            categories: [
                TemplateCategory(name: "CLOTHES", items: ["6x T-shirts", "2x Long sleeve shirts", "3x Pairs of pants", "1x Rain jacket", "7x Underwear", "7x Socks", "1x Walking shoes", "1x Temple-appropriate clothing", "1x Warm layers for winter"]),
                TemplateCategory(name: "TOILETRIES", items: ["Sunscreen", "Toothbrush", "Toothpaste", "Deodorant", "Skincare routine", "Portable bidet", "Hand sanitizer"]),
                TemplateCategory(name: "ELECTRONICS", items: ["Phone charger", "Universal adapter", "Portable WiFi", "Camera", "Power bank", "Headphones"]),
                TemplateCategory(name: "DOCUMENTS", items: ["Passport", "JR Pass", "Hotel reservations", "Travel insurance", "Credit cards", "Cash (Yen)"]),
                TemplateCategory(name: "MISC", items: ["Day bag", "Reusable water bottle", "Pocket tissues", "Umbrella", "Map/guidebook", "Snacks"])
            ],
            authorName: "NomadSarah",
            downloadCount: 2841,
            rating: 4.9,
            isPopular: true
        ),
        CommunityTemplate(
            id: 1002,
            name: "European Summer",
            description: "3 weeks across Paris, Rome and Barcelona — warm weather packing",
            category: "City",
            tags: ["europe", "summer", "paris", "rome", "3 weeks"],
            categories: [
                TemplateCategory(name: "CLOTHES", items: ["8x T-shirts", "3x Dresses", "2x Shorts", "5x Underwear", "5x Socks", "1x Light jacket", "1x Swimsuit", "1x Sandals", "1x Walking shoes", "1x Dressy outfit"]),
                TemplateCategory(name: "TOILETRIES", items: ["Sunscreen SPF 50", "Toothbrush", "Toothpaste", "Deodorant", "Sunglasses", "After-sun lotion", "Compact skincare"]),
                TemplateCategory(name: "ELECTRONICS", items: ["Phone charger", "Universal adapter", "Camera", "Power bank", "Headphones", "E-reader"]),
                TemplateCategory(name: "DOCUMENTS", items: ["Passport", "Travel insurance", "Eurail pass", "Hotel confirmations", "Credit cards"]),
                TemplateCategory(name: "MISC", items: ["Day bag", "Reusable water bottle", "Guidebook", "Travel pillow", "Padlock", "Laundry bag"])
            ],
            authorName: "WanderlustEmma",
            downloadCount: 1956,
            rating: 4.8,
            isPopular: true
        ),
        CommunityTemplate(
            id: 1003,
            name: "Ski Trip Week",
            description: "5 days at the slopes — stay warm and pack light",
            category: "Winter",
            tags: ["skiing", "snow", "winter", "mountains"],
            categories: [
                TemplateCategory(name: "CLOTHES", items: ["4x Base layers", "2x Mid layers", "2x Ski pants", "1x Ski jacket", "5x Thermal underwear", "5x Warm socks", "Ski gloves", "Warm hat", "Neck gaiter", "Sunglasses"]),
                TemplateCategory(name: "TOILETRIES", items: ["Lip balm SPF", "Moisturizer", "Toothbrush", "Toothpaste", "Deodorant", "Sunscreen SPF 50"]),
                TemplateCategory(name: "ELECTRONICS", items: ["Phone charger", "Camera", "Headphones", "Power bank"]),
                TemplateCategory(name: "MISC", items: ["Day bag", "Water bottle", "Snacks", "Hand warmers", "First aid kit", "Ski lock"])
            ],
            authorName: "AlpineAlex",
            downloadCount: 1203,
            rating: 4.7,
            isPopular: true
        ),
        CommunityTemplate(
            id: 1004,
            name: "Safari Adventure",
            description: "10 days in Kenya/Tanzania — practical and lightweight",
            category: "Adventure",
            tags: ["safari", "africa", "kenya", "wildlife"],
            categories: [
                TemplateCategory(name: "CLOTHES", items: ["5x Neutral-color shirts", "3x Neutral-color pants", "1x Rain jacket", "1x Fleece", "7x Underwear", "7x Socks", "1x Wide-brim hat", "1x Sunglasses", "1x Swimsuit"]),
                TemplateCategory(name: "TOILETRIES", items: ["Strong sunscreen", "Insect repellent", "Toothbrush", "Toothpaste", "Deodorant", "Wet wipes", "First aid kit"]),
                TemplateCategory(name: "ELECTRONICS", items: ["Phone charger", "Camera + extra memory", "Power bank", "Headlamp", "Binoculars"]),
                TemplateCategory(name: "DOCUMENTS", items: ["Passport", "Visa", "Yellow fever certificate", "Travel insurance", "Flight tickets", "Credit cards"]),
                TemplateCategory(name: "MISC", items: ["Day bag", "Reusable water bottle", "Laundry bag", "Padlock", "Dry bag", "Travel pillow"])
            ],
            authorName: "WildlifeWill",
            downloadCount: 892,
            rating: 4.8,
            isPopular: false
        ),
        CommunityTemplate(
            id: 1005,
            name: "Minimalist Weekend",
            description: "2 days, carry-on only — pack light, travel right",
            category: "City",
            tags: ["weekend", "minimal", "carry-on", "light"],
            categories: [
                TemplateCategory(name: "CLOTHES", items: ["2x T-shirts", "1x Pants", "1x Jacket", "3x Underwear", "3x Socks", "1x Pajamas"]),
                TemplateCategory(name: "TOILETRIES", items: ["Toothbrush", "Toothpaste", "Deodorant", "Mini skincare"]),
                TemplateCategory(name: "ELECTRONICS", items: ["Phone charger", "Headphones"]),
                TemplateCategory(name: "MISC", items: ["Wallet", "Passport", "Keys"])
            ],
            authorName: "CarryOnCarl",
            downloadCount: 3102,
            rating: 4.6,
            isPopular: false
        ),
        CommunityTemplate(
            id: 1006,
            name: "Southeast Asia Backpacking",
            description: "4 weeks through Thailand, Vietnam and Cambodia on a budget",
            category: "Beach",
            tags: ["thailand", "vietnam", "backpacking", "budget", "asia"],
            categories: [
                TemplateCategory(name: "CLOTHES", items: ["6x Light T-shirts", "3x Shorts", "2x Light pants", "1x Rain jacket", "7x Underwear", "7x Socks", "1x Swimsuit", "1x Sandals", "1x Hiking shoes"]),
                TemplateCategory(name: "TOILETRIES", items: ["Sunscreen", "Insect repellent", "Toothbrush", "Toothpaste", "Deodorant", "Anti-malaria tablets", "Waterproof bag"]),
                TemplateCategory(name: "ELECTRONICS", items: ["Phone charger", "Power bank", "Camera", "Headphones", "Universal adapter"]),
                TemplateCategory(name: "DOCUMENTS", items: ["Passport", "Travel insurance", "Visa documents", "Hostel bookings", "Credit cards"]),
                TemplateCategory(name: "MISC", items: ["Backpack", "Day bag", "Padlock", "Water bottle", "Quick-dry towel", "Snacks"])
            ],
            authorName: "BackpackerBen",
            downloadCount: 2241,
            rating: 4.7,
            isPopular: false
        )
    ]
}

struct CommunityTemplateCard: View {
    let template: CommunityTemplate
    let isImported: Bool
    let onImport: () -> Void
    let onApply: () -> Void

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
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(categoryColor.opacity(0.12))
                            .frame(width: 44, height: 44)

                        Image(systemName: categoryIcon)
                            .font(.system(size: 18))
                            .foregroundColor(categoryColor)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(template.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(hex: "1a1814"))

                        HStack(spacing: 6) {
                            Text("by \(template.authorName)")
                            Text("·")
                                .foregroundColor(Color(hex: "7a746a"))
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", template.rating))
                            }
                            Text("·")
                                .foregroundColor(Color(hex: "7a746a"))
                            Text("\(template.downloadCount.formatted()) downloads")
                        }
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "7a746a"))
                    }

                    Spacer()

                    if template.isPopular {
                        Text("🔥")
                            .font(.system(size: 14))
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "7a746a"))
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    // Description
                    Text(template.description)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "7a746a"))
                        .padding(.horizontal, 14)

                    // Tags
                    FlowLayout(spacing: 6) {
                        ForEach(template.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.system(size: 11))
                                .foregroundColor(Color(hex: "c4956a"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color(hex: "c4956a").opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                    .padding(.horizontal, 14)

                    // Categories preview
                    ForEach(template.categories.prefix(3)) { cat in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(cat.name)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(Color(hex: "7a746a"))
                                .tracking(1)

                            Text(cat.items.prefix(4).joined(separator: ", ") + (cat.items.count > 4 ? "..." : ""))
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "1a1814"))
                        }
                        .padding(.horizontal, 14)
                    }

                    if template.categories.count > 3 {
                        Text("+\(template.categories.count - 3) more categories")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "7a746a"))
                            .padding(.horizontal, 14)
                    }

                    // Actions
                    HStack(spacing: 12) {
                        Button {
                            onImport()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: isImported ? "checkmark" : "square.and.arrow.down")
                                    .font(.system(size: 13))
                                Text(isImported ? "Imported" : "Import")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(isImported ? Color(hex: "5d8c5d") : Color(hex: "c4956a"))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .background(isImported ? Color(hex: "5d8c5d").opacity(0.1) : Color(hex: "c4956a").opacity(0.1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        .disabled(isImported)

                        Button {
                            onApply()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 13))
                                Text("Apply")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .background(Color(hex: "c4956a"))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 4)
                }
                .padding(.bottom, 14)
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "d4cfc6").opacity(0.5), lineWidth: 1)
        )
    }

    private var categoryColor: Color {
        switch template.category {
        case "Beach": return Color(hex: "4a90a4")
        case "City": return Color(hex: "7a6b8a")
        case "Business": return Color(hex: "4a7ba7")
        case "Adventure": return Color(hex: "5d8c5d")
        case "Camping": return Color(hex: "8B7355")
        case "Winter": return Color(hex: "5a7fa7")
        default: return Color(hex: "c4956a")
        }
    }

    private var categoryIcon: String {
        switch template.category {
        case "Beach": return "sun.max.fill"
        case "City": return "building.2.fill"
        case "Business": return "briefcase.fill"
        case "Adventure": return "figure.hiking"
        case "Camping": return "tent.fill"
        case "Winter": return "snowflake"
        default: return "suitcase.fill"
        }
    }
}
