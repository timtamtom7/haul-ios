import Foundation

struct Bag: Identifiable, Equatable {
    var id: Int64?
    var tripId: Int64
    var name: String
    var bagType: BagType
    var colorHex: String
    var createdAt: Date

    init(id: Int64? = nil, tripId: Int64, name: String, bagType: BagType, colorHex: String, createdAt: Date = Date()) {
        self.id = id
        self.tripId = tripId
        self.name = name
        self.bagType = bagType
        self.colorHex = colorHex
        self.createdAt = createdAt
    }
}

enum BagType: String, CaseIterable {
    case checked = "Checked"
    case carryOn = "Carry-on"
    case personalItem = "Personal Item"
    case backpack = "Backpack"
    case other = "Other"

    var icon: String {
        switch self {
        case .checked: return "suitcase.fill"
        case .carryOn: return "bag.fill"
        case .personalItem: return "backpack.fill"
        case .backpack: return "figure.walk"
        case .other: return "shippingbox.fill"
        }
    }

    var defaultColor: String {
        switch self {
        case .checked: return "8B7355"
        case .carryOn: return "5d8c5d"
        case .personalItem: return "4a7ba7"
        case .backpack: return "7a6b8a"
        case .other: return "7a746a"
        }
    }
}

import Foundation

struct PackingTemplate: Identifiable, Equatable {
    var id: Int64?
    var name: String
    var description: String
    var categories: [TemplateCategory]
    var isBuiltIn: Bool
    var createdAt: Date

    init(id: Int64? = nil, name: String, description: String = "", categories: [TemplateCategory], isBuiltIn: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.description = description
        self.categories = categories
        self.isBuiltIn = isBuiltIn
        self.createdAt = createdAt
    }
}

struct TemplateCategory: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var items: [String]
}

import Foundation

struct TripFeedback: Identifiable, Equatable {
    var id: Int64?
    var tripId: Int64
    var rating: Int // 1-5 stars
    var forgotItems: [String]
    var unusedItems: [String]
    var notes: String
    var createdAt: Date

    init(id: Int64? = nil, tripId: Int64, rating: Int = 0, forgotItems: [String] = [], unusedItems: [String] = [], notes: String = "", createdAt: Date = Date()) {
        self.id = id
        self.tripId = tripId
        self.rating = rating
        self.forgotItems = forgotItems
        self.unusedItems = unusedItems
        self.notes = notes
        self.createdAt = createdAt
    }
}

import Foundation

struct WeatherData: Identifiable, Equatable {
    let id = UUID()
    var location: String
    var date: Date
    var condition: WeatherCondition
    var temperatureCelsius: Double
    var temperatureFahrenheit: Double {
        temperatureCelsius * 9 / 5 + 32
    }
    var humidity: Int
    var suggestions: [String]

    var conditionIcon: String {
        condition.icon
    }

    var temperatureDisplay: String {
        "\(Int(temperatureCelsius))°C"
    }
}

enum WeatherCondition: String {
    case sunny = "Sunny"
    case cloudy = "Cloudy"
    case rainy = "Rainy"
    case stormy = "Stormy"
    case snowy = "Snowy"
    case partlyCloudy = "Partly Cloudy"
    case foggy = "Foggy"
    case windy = "Windy"
    case unknown = "Unknown"

    var icon: String {
        switch self {
        case .sunny: return "sun.max.fill"
        case .cloudy: return "cloud.fill"
        case .rainy: return "cloud.rain.fill"
        case .stormy: return "cloud.bolt.rain.fill"
        case .snowy: return "cloud.snow.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        case .foggy: return "cloud.fog.fill"
        case .windy: return "wind"
        case .unknown: return "questionmark.circle.fill"
        }
    }

    var suggestedItems: [String] {
        switch self {
        case .rainy, .stormy:
            return ["Umbrella", "Rain jacket", "Waterproof shoes", "Plastic bag for electronics"]
        case .snowy:
            return ["Warm gloves", "Scarf", "Beanie", "Thermal socks", "Snow boots"]
        case .sunny:
            return ["Sunscreen", "Sunglasses", "Hat", "Lip balm with SPF"]
        case .partlyCloudy, .cloudy:
            return ["Light jacket", "Sunglasses"]
        case .foggy:
            return ["Light jacket", "Closed-toe shoes"]
        case .windy:
            return ["Windbreaker", "Hair ties", "Secure hat"]
        case .unknown:
            return []
        }
    }
}

// Built-in templates
extension PackingTemplate {
    static let builtInTemplates: [PackingTemplate] = [
        PackingTemplate(
            name: "Beach Vacation",
            description: "1 week of sun, sand, and sea",
            categories: [
                TemplateCategory(name: "CLOTHES", items: [
                    "8x T-shirts", "3x Shorts", "2x Swimsuits",
                    "7x Underwear", "7x Socks", "1x Sarong",
                    "2x Dresses", "1x Sandals", "1x Flip-flops"
                ]),
                TemplateCategory(name: "TOILETRIES", items: [
                    "Sunscreen SPF 50", "After-sun lotion", "Sunglasses",
                    "Toothbrush", "Toothpaste", "Deodorant",
                    "Shampoo", " conditioner", "Razor", "Skincare"
                ]),
                TemplateCategory(name: "ELECTRONICS", items: [
                    "Phone charger", "Portable speaker", "Camera",
                    "Power bank", "E-reader"
                ]),
                TemplateCategory(name: "DOCUMENTS", items: [
                    "Passport", "Travel insurance", "Hotel confirmation",
                    "Credit cards", "Cash (local currency)"
                ]),
                TemplateCategory(name: "MISC", items: [
                    "Beach towel", "Reusable water bottle", "Snacks",
                    "Book", "Day bag", "Dry bag"
                ])
            ],
            isBuiltIn: true
        ),
        PackingTemplate(
            name: "Business Trip",
            description: "3-5 days of professional travel",
            categories: [
                TemplateCategory(name: "CLOTHES", items: [
                    "4x Dress shirts", "2x Pairs of pants", "1x Suit",
                    "7x Underwear", "7x Socks", "1x Belt",
                    "1x Ties", "1x Dress shoes", "1x Casual shoes",
                    "1x Pajamas", "1x Watch"
                ]),
                TemplateCategory(name: "TOILETRIES", items: [
                    "Toiletry kit", "Deodorant", " Razor",
                    "Cologne", "Skincare routine", "Hair product"
                ]),
                TemplateCategory(name: "ELECTRONICS", items: [
                    "Laptop + charger", "Phone charger", "Headphones",
                    "Business cards", "USB drive", "Universal adapter"
                ]),
                TemplateCategory(name: "DOCUMENTS", items: [
                    "Passport", "ID Card", "Hotel confirmation",
                    "Flight tickets", "Credit cards", "Cash"
                ]),
                TemplateCategory(name: "MISC", items: [
                    "Work bag", "Notebook", "Pen", "Gym clothes",
                    "Medications", "Mints/gum"
                ])
            ],
            isBuiltIn: true
        ),
        PackingTemplate(
            name: "Camping Adventure",
            description: "1-2 weeks in the great outdoors",
            categories: [
                TemplateCategory(name: "CLOTHES", items: [
                    "5x Hiking shirts", "3x Hiking pants", "2x Shorts",
                    "7x Underwear", "7x Socks", "1x Rain jacket",
                    "1x Fleece", "1x Hat", "1x Hiking boots"
                ]),
                TemplateCategory(name: "TOILETRIES", items: [
                    "Sunscreen", "Insect repellent", "Toothbrush",
                    "Toothpaste", "Biodegradable soap", "First aid kit"
                ]),
                TemplateCategory(name: "ELECTRONICS", items: [
                    "Phone charger", "Power bank", "Headlamp",
                    "Camera", "Portable charger"
                ]),
                TemplateCategory(name: "GEAR", items: [
                    "Tent", "Sleeping bag", "Sleeping pad",
                    "Camp stove", "Cooler", "Water filter",
                    "Multi-tool", "Rope", "Fire starter"
                ]),
                TemplateCategory(name: "MISC", items: [
                    "Backpack", "Day bag", "Reusable water bottle",
                    "First aid kit", "Map/GPS", "Snacks",
                    "Bear spray", "Headlamp", "Earplugs"
                ])
            ],
            isBuiltIn: true
        ),
        PackingTemplate(
            name: "City Break",
            description: "2-3 days exploring a new city",
            categories: [
                TemplateCategory(name: "CLOTHES", items: [
                    "3x T-shirts", "2x Pairs of pants", "1x Jacket",
                    "5x Underwear", "5x Socks", "1x Pajamas",
                    "1x Comfortable walking shoes", "1x Casual shoes"
                ]),
                TemplateCategory(name: "TOILETRIES", items: [
                    "Toothbrush", "Toothpaste", "Deodorant",
                    "Skincare", "Mini perfume/cologne", "Hairbrush"
                ]),
                TemplateCategory(name: "ELECTRONICS", items: [
                    "Phone charger", "Headphones", "Camera",
                    "Power bank", "Universal adapter"
                ]),
                TemplateCategory(name: "DOCUMENTS", items: [
                    "Passport", "Travel insurance", "Hotel confirmation",
                    "Credit cards", "Cash"
                ]),
                TemplateCategory(name: "MISC", items: [
                    "Day bag", "Umbrella", "Guidebook/maps",
                    "Snacks", "Book", "Portable charger"
                ])
            ],
            isBuiltIn: true
        )
    ]
}
