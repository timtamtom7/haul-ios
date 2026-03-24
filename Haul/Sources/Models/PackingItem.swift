import Foundation

struct PackingItem: Identifiable, Equatable {
    var id: Int64?
    var tripId: Int64
    var name: String
    var category: String
    var isPacked: Bool

    init(id: Int64? = nil, tripId: Int64, name: String, category: String, isPacked: Bool = false) {
        self.id = id
        self.tripId = tripId
        self.name = name
        self.category = category
        self.isPacked = isPacked
    }
}

struct ItemCategory: Identifiable {
    let id = UUID()
    let name: String
    let items: [String]
}

enum DefaultCategories {
    static let all: [ItemCategory] = [
        ItemCategory(name: "CLOTHES", items: [
            "5x T-shirts",
            "3x Pairs of pants",
            "1x Jacket",
            "7x Underwear",
            "7x Socks",
            "1x Pajamas",
            "1x Swimsuit",
            "1x Sneakers",
            "1x Dress shoes",
            "2x Dress shirts",
            "1x Belt",
            "1x Hat",
            "1x Sunglasses"
        ]),
        ItemCategory(name: "TOILETRIES", items: [
            "Toothbrush",
            "Toothpaste",
            "Deodorant",
            "Shampoo",
            "Conditioner",
            "Body wash",
            "Razor",
            "Skincare routine",
            "Sunscreen",
            "Lip balm",
            "Contacts / Glasses",
            "Hairbrush / Comb"
        ]),
        ItemCategory(name: "ELECTRONICS", items: [
            "Phone charger",
            "Laptop + charger",
            "Headphones",
            "Power bank",
            "Universal adapter",
            "Camera",
            "E-reader / Kindle",
            "Portable speaker"
        ]),
        ItemCategory(name: "DOCUMENTS", items: [
            "Passport",
            "Travel insurance",
            "Flight tickets",
            "Hotel reservations",
            "ID Card",
            "Driver's license",
            "Credit cards",
            "Cash (local currency)"
        ]),
        ItemCategory(name: "MISC", items: [
            "Medications",
            "Snacks",
            "Book / Kindle",
            "Reusable water bottle",
            "Day bag",
            "Travel pillow",
            "Earplugs",
            "Laundry bag",
            "Padlock"
        ])
    ]

    // Real trip templates
    static let tripTemplates: [TripTemplate] = [
        TripTemplate(
            name: "Weekend city break",
            duration: "2-3 days",
            suggestedItems: [
                "3x T-shirts", "1x Jacket", "2x Pairs of pants",
                "5x Underwear", "5x Socks", "1x Pajamas",
                "Toothbrush", "Toothpaste", "Deodorant",
                "Phone charger", "Passport", "Credit cards"
            ]
        ),
        TripTemplate(
            name: "Beach vacation",
            duration: "1 week",
            suggestedItems: [
                "8x T-shirts", "2x Shorts", "1x Swimsuit",
                "7x Underwear", "7x Socks", "1x Sandals",
                "Sunscreen", "Sunglasses", "Hat", "Toothbrush",
                "Passport", "Phone charger", "Book"
            ]
        ),
        TripTemplate(
            name: "Business trip",
            duration: "3-5 days",
            suggestedItems: [
                "4x Dress shirts", "2x Pairs of pants", "1x Suit",
                "7x Underwear", "7x Socks", "1x Belt",
                "Laptop + charger", "Phone charger", "Business cards",
                "Passport", "Hotel reservations", "Toiletry kit"
            ]
        ),
        TripTemplate(
            name: "Adventure trip",
            duration: "1-2 weeks",
            suggestedItems: [
                "5x T-shirts", "3x Hiking pants", "1x Rain jacket",
                "7x Underwear", "7x Socks", "1x Hiking boots",
                "Sunscreen", "First aid kit", "Power bank",
                "Headlamp", "Passport", "Reusable water bottle"
            ]
        )
    ]
}

struct TripTemplate: Identifiable {
    let id = UUID()
    let name: String
    let duration: String
    let suggestedItems: [String]
}
