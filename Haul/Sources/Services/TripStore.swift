import Foundation
import SQLite

@MainActor
class TripStore: ObservableObject {
    private var db: Connection?

    // Trips table
    private let trips = Table("trips")
    private let tripId = Expression<Int64>("id")
    private let tripName = Expression<String>("name")
    private let tripStartDate = Expression<Date>("start_date")
    private let tripEndDate = Expression<Date>("end_date")
    private let tripSuitcasePhotoPath = Expression<String?>("suitcase_photo_path")
    private let tripCreatedAt = Expression<Date>("created_at")

    // Items table
    private let items = Table("items")
    private let itemId = Expression<Int64>("id")
    private let itemTripId = Expression<Int64>("trip_id")
    private let itemName = Expression<String>("name")
    private let itemCategory = Expression<String>("category")
    private let itemIsPacked = Expression<Bool>("is_packed")
    private let itemBagId = Expression<Int64?>("bag_id")

    // Bags table
    private let bags = Table("bags")
    private let bagId = Expression<Int64>("id")
    private let bagTripId = Expression<Int64>("trip_id")
    private let bagName = Expression<String>("name")
    private let bagType = Expression<String>("bag_type")
    private let bagColorHex = Expression<String>("color_hex")
    private let bagCreatedAt = Expression<Date>("created_at")

    // Templates table
    private let templates = Table("templates")
    private let templateId = Expression<Int64>("id")
    private let templateName = Expression<String>("name")
    private let templateDescription = Expression<String>("description")
    private let templateCategoriesJson = Expression<String>("categories_json")
    private let templateIsBuiltIn = Expression<Bool>("is_built_in")
    private let templateCreatedAt = Expression<Date>("created_at")

    // Trip feedback table
    private let feedbacks = Table("trip_feedbacks")
    private let feedbackId = Expression<Int64>("id")
    private let feedbackTripId = Expression<Int64>("trip_id")
    private let feedbackRating = Expression<Int>("rating")
    private let feedbackForgotItemsJson = Expression<String>("forgot_items_json")
    private let feedbackUnusedItemsJson = Expression<String>("unused_items_json")
    private let feedbackNotes = Expression<String>("notes")
    private let feedbackCreatedAt = Expression<Date>("created_at")

    @Published var allTrips: [Trip] = []
    @Published var currentTripItems: [PackingItem] = []
    @Published var currentTripBags: [Bag] = []
    @Published var currentTripFeedback: TripFeedback?

    init() {
        setupDatabase()
        fetchAllTrips()
    }

    private func setupDatabase() {
        do {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let dbPath = documentsPath.appendingPathComponent("haul.sqlite3")
            db = try Connection(dbPath.path)

            // Trips table
            try db?.run(trips.create(ifNotExists: true) { t in
                t.column(tripId, primaryKey: .autoincrement)
                t.column(tripName)
                t.column(tripStartDate)
                t.column(tripEndDate)
                t.column(tripSuitcasePhotoPath)
                t.column(tripCreatedAt)
            })

            // Items table (updated with bag_id)
            try db?.run(items.create(ifNotExists: true) { t in
                t.column(itemId, primaryKey: .autoincrement)
                t.column(itemTripId)
                t.column(itemName)
                t.column(itemCategory)
                t.column(itemIsPacked, defaultValue: false)
                t.column(itemBagId)
            })

            // Bags table
            try db?.run(bags.create(ifNotExists: true) { t in
                t.column(bagId, primaryKey: .autoincrement)
                t.column(bagTripId)
                t.column(bagName)
                t.column(bagType)
                t.column(bagColorHex)
                t.column(bagCreatedAt)
            })

            // Templates table
            try db?.run(templates.create(ifNotExists: true) { t in
                t.column(templateId, primaryKey: .autoincrement)
                t.column(templateName)
                t.column(templateDescription)
                t.column(templateCategoriesJson)
                t.column(templateIsBuiltIn)
                t.column(templateCreatedAt)
            })

            // Trip feedback table
            try db?.run(feedbacks.create(ifNotExists: true) { t in
                t.column(feedbackId, primaryKey: .autoincrement)
                t.column(feedbackTripId, unique: true)
                t.column(feedbackRating)
                t.column(feedbackForgotItemsJson)
                t.column(feedbackUnusedItemsJson)
                t.column(feedbackNotes)
                t.column(feedbackCreatedAt)
            })
        } catch {
            print("Database setup error: \(error)")
        }
    }

    // MARK: - Trips

    func fetchAllTrips() {
        guard let db = db else { return }
        do {
            let query = trips.order(tripStartDate.desc)
            allTrips = try db.prepare(query).map { row in
                Trip(
                    id: row[tripId],
                    name: row[tripName],
                    startDate: row[tripStartDate],
                    endDate: row[tripEndDate],
                    suitcasePhotoPath: row[tripSuitcasePhotoPath],
                    createdAt: row[tripCreatedAt]
                )
            }
        } catch {
            print("Fetch trips error: \(error)")
        }
    }

    func createTrip(name: String, startDate: Date, endDate: Date, suitcasePhotoPath: String?) -> Int64? {
        guard let db = db else { return nil }
        do {
            let insert = trips.insert(
                tripName <- name,
                tripStartDate <- startDate,
                tripEndDate <- endDate,
                tripSuitcasePhotoPath <- suitcasePhotoPath,
                tripCreatedAt <- Date()
            )
            let rowId = try db.run(insert)
            fetchAllTrips()
            return rowId
        } catch {
            print("Create trip error: \(error)")
            return nil
        }
    }

    func deleteTrip(_ trip: Trip) {
        guard let db = db, let id = trip.id else { return }
        do {
            // Delete associated bags first
            let tripBags = bags.filter(bagTripId == id)
            try db.run(tripBags.delete())

            // Delete associated items
            let tripItems = items.filter(itemTripId == id)
            try db.run(tripItems.delete())

            // Delete associated feedback
            let tripFeedback = feedbacks.filter(feedbackTripId == id)
            try db.run(tripFeedback.delete())

            // Delete trip
            let query = trips.filter(tripId == id)
            try db.run(query.delete())
            fetchAllTrips()
        } catch {
            print("Delete trip error: \(error)")
        }
    }

    // MARK: - Items

    func fetchItems(for tripIdValue: Int64) {
        guard let db = db else { return }
        do {
            let query = items.filter(itemTripId == tripIdValue).order(itemCategory, itemName)
            currentTripItems = try db.prepare(query).map { row in
                PackingItem(
                    id: row[itemId],
                    tripId: row[itemTripId],
                    name: row[itemName],
                    category: row[itemCategory],
                    isPacked: row[itemIsPacked]
                )
            }
        } catch {
            print("Fetch items error: \(error)")
        }
    }

    func fetchItems(forBag bagIdValue: Int64) -> [PackingItem] {
        guard let db = db else { return [] }
        do {
            let query = items.filter(itemBagId == bagIdValue).order(itemCategory, itemName)
            return try db.prepare(query).map { row in
                PackingItem(
                    id: row[itemId],
                    tripId: row[itemTripId],
                    name: row[itemName],
                    category: row[itemCategory],
                    isPacked: row[itemIsPacked]
                )
            }
        } catch {
            print("Fetch items for bag error: \(error)")
            return []
        }
    }

    func addItem(to tripIdValue: Int64, name: String, category: String, bagId: Int64? = nil) {
        guard let db = db else { return }
        do {
            let insert = items.insert(
                itemTripId <- tripIdValue,
                itemName <- name,
                itemCategory <- category,
                itemIsPacked <- false,
                itemBagId <- bagId
            )
            try db.run(insert)
            fetchItems(for: tripIdValue)
        } catch {
            print("Add item error: \(error)")
        }
    }

    func addItems(to tripIdValue: Int64, itemNames: [String], category: String, bagId: Int64? = nil) {
        for name in itemNames {
            addItem(to: tripIdValue, name: name, category: category, bagId: bagId)
        }
    }

    func toggleItem(_ item: PackingItem) {
        guard let db = db, let id = item.id else { return }
        do {
            let query = items.filter(itemId == id)
            try db.run(query.update(itemIsPacked <- !item.isPacked))
            fetchItems(for: item.tripId)
        } catch {
            print("Toggle item error: \(error)")
        }
    }

    func deleteItem(_ item: PackingItem) {
        guard let db = db, let id = item.id else { return }
        do {
            let query = items.filter(itemId == id)
            try db.run(query.delete())
            fetchItems(for: item.tripId)
        } catch {
            print("Delete item error: \(error)")
        }
    }

    func packedCount(for tripIdValue: Int64) -> Int {
        guard let db = db else { return 0 }
        do {
            let query = items.filter(itemTripId == tripIdValue && itemIsPacked == true)
            return try db.scalar(query.count)
        } catch {
            return 0
        }
    }

    func totalCount(for tripIdValue: Int64) -> Int {
        guard let db = db else { return 0 }
        do {
            let query = items.filter(itemTripId == tripIdValue)
            return try db.scalar(query.count)
        } catch {
            return 0
        }
    }

    // MARK: - Bags

    func fetchBags(for tripIdValue: Int64) {
        guard let db = db else { return }
        do {
            let query = bags.filter(bagTripId == tripIdValue).order(bagCreatedAt)
            currentTripBags = try db.prepare(query).map { row in
                Bag(
                    id: row[bagId],
                    tripId: row[bagTripId],
                    name: row[bagName],
                    bagType: BagType(rawValue: row[bagType]) ?? .other,
                    colorHex: row[bagColorHex],
                    createdAt: row[bagCreatedAt]
                )
            }
        } catch {
            print("Fetch bags error: \(error)")
        }
    }

    func createBag(tripIdValue: Int64, name: String, bagType bagTypeArg: BagType, colorHex: String) -> Int64? {
        guard let db = db else { return nil }
        do {
            let insert = bags.insert(
                bagTripId <- tripIdValue,
                bagName <- name,
                bagType <- bagTypeArg.rawValue,
                bagColorHex <- colorHex,
                bagCreatedAt <- Date()
            )
            let rowId = try db.run(insert)
            fetchBags(for: tripIdValue)
            return rowId
        } catch {
            print("Create bag error: \(error)")
            return nil
        }
    }

    func updateBag(_ bag: Bag) {
        guard let db = db, let id = bag.id else { return }
        do {
            let query = bags.filter(bagId == id)
            try db.run(query.update(
                bagName <- bag.name,
                bagType <- bag.bagType.rawValue,
                bagColorHex <- bag.colorHex
            ))
            fetchBags(for: bag.tripId)
        } catch {
            print("Update bag error: \(error)")
        }
    }

    func deleteBag(_ bag: Bag) {
        guard let db = db, let id = bag.id else { return }
        do {
            // Unassign items from this bag (set bag_id to nil)
            let bagItems = items.filter(itemBagId == id)
            try db.run(bagItems.update(itemBagId <- nil as Int64?))

            // Delete the bag
            let query = bags.filter(bagId == id)
            try db.run(query.delete())
            fetchBags(for: bag.tripId)
        } catch {
            print("Delete bag error: \(error)")
        }
    }

    func bagItemCount(for bagIdValue: Int64) -> Int {
        guard let db = db else { return 0 }
        do {
            let query = items.filter(itemBagId == bagIdValue)
            return try db.scalar(query.count)
        } catch {
            return 0
        }
    }

    func bagPackedCount(for bagIdValue: Int64) -> Int {
        guard let db = db else { return 0 }
        do {
            let query = items.filter(itemBagId == bagIdValue && itemIsPacked == true)
            return try db.scalar(query.count)
        } catch {
            return 0
        }
    }

    // MARK: - Templates

    func fetchAllTemplates() -> [PackingTemplate] {
        guard let db = db else { return PackingTemplate.builtInTemplates }
        do {
            let query = templates.order(templateName)
            var result = try db.prepare(query).map { row -> PackingTemplate in
                let categories = decodeTemplateCategories(row[templateCategoriesJson])
                return PackingTemplate(
                    id: row[templateId],
                    name: row[templateName],
                    description: row[templateDescription],
                    categories: categories,
                    isBuiltIn: row[templateIsBuiltIn],
                    createdAt: row[templateCreatedAt]
                )
            }
            // Merge built-in templates
            result.append(contentsOf: PackingTemplate.builtInTemplates)
            return result
        } catch {
            print("Fetch templates error: \(error)")
            return PackingTemplate.builtInTemplates
        }
    }

    func saveTemplate(name: String, description: String, categories: [TemplateCategory]) -> Bool {
        guard let db = db else { return false }
        do {
            let categoriesJson = encodeTemplateCategories(categories)
            let insert = templates.insert(
                templateName <- name,
                templateDescription <- description,
                templateCategoriesJson <- categoriesJson,
                templateIsBuiltIn <- false,
                templateCreatedAt <- Date()
            )
            try db.run(insert)
            return true
        } catch {
            print("Save template error: \(error)")
            return false
        }
    }

    func deleteTemplate(_ template: PackingTemplate) -> Bool {
        guard let db = db, let id = template.id, !template.isBuiltIn else { return false }
        do {
            let query = templates.filter(templateId == id)
            try db.run(query.delete())
            return true
        } catch {
            print("Delete template error: \(error)")
            return false
        }
    }

    func applyTemplate(_ template: PackingTemplate, to tripIdValue: Int64) {
        for category in template.categories {
            addItems(to: tripIdValue, itemNames: category.items, category: category.name)
        }
    }

    private func encodeTemplateCategories(_ categories: [TemplateCategory]) -> String {
        let data = categories.map { cat -> [String: Any] in
            ["name": cat.name, "items": cat.items]
        }
        guard let jsonData = try? JSONSerialization.data(withJSONObject: data),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return "[]"
        }
        return jsonString
    }

    private func decodeTemplateCategories(_ json: String) -> [TemplateCategory] {
        guard let data = json.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }
        return array.compactMap { dict -> TemplateCategory? in
            guard let name = dict["name"] as? String,
                  let items = dict["items"] as? [String] else { return nil }
            return TemplateCategory(name: name, items: items)
        }
    }

    // MARK: - Trip Feedback

    func fetchFeedback(for tripIdValue: Int64) {
        guard let db = db else { return }
        do {
            let query = feedbacks.filter(feedbackTripId == tripIdValue)
            if let row = try db.pluck(query) {
                let forgotItems = decodeFeedbackItems(row[feedbackForgotItemsJson])
                let unusedItems = decodeFeedbackItems(row[feedbackUnusedItemsJson])
                currentTripFeedback = TripFeedback(
                    id: row[feedbackId],
                    tripId: row[feedbackTripId],
                    rating: row[feedbackRating],
                    forgotItems: forgotItems,
                    unusedItems: unusedItems,
                    notes: row[feedbackNotes],
                    createdAt: row[feedbackCreatedAt]
                )
            } else {
                currentTripFeedback = nil
            }
        } catch {
            print("Fetch feedback error: \(error)")
        }
    }

    func saveFeedback(_ feedback: TripFeedback) -> Bool {
        guard let db = db else { return false }
        do {
            let forgotJson = encodeFeedbackItems(feedback.forgotItems)
            let unusedJson = encodeFeedbackItems(feedback.unusedItems)

            // Check if feedback already exists
            let existingQuery = feedbacks.filter(feedbackTripId == feedback.tripId)
            if try db.pluck(existingQuery) != nil {
                // Update
                try db.run(existingQuery.update(
                    feedbackRating <- feedback.rating,
                    feedbackForgotItemsJson <- forgotJson,
                    feedbackUnusedItemsJson <- unusedJson,
                    feedbackNotes <- feedback.notes
                ))
            } else {
                // Insert
                let insert = feedbacks.insert(
                    feedbackTripId <- feedback.tripId,
                    feedbackRating <- feedback.rating,
                    feedbackForgotItemsJson <- forgotJson,
                    feedbackUnusedItemsJson <- unusedJson,
                    feedbackNotes <- feedback.notes,
                    feedbackCreatedAt <- Date()
                )
                try db.run(insert)
            }
            currentTripFeedback = feedback
            return true
        } catch {
            print("Save feedback error: \(error)")
            return false
        }
    }

    private func encodeFeedbackItems(_ items: [String]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: items),
              let jsonString = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return jsonString
    }

    private func decodeFeedbackItems(_ json: String) -> [String] {
        guard let data = json.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [String] else {
            return []
        }
        return array
    }

    // MARK: - Computed Properties

    var upcomingTrips: [Trip] {
        allTrips.filter { $0.isUpcoming || $0.isOngoing }
    }

    var pastTrips: [Trip] {
        allTrips.filter { $0.isPast }
    }

    func getTrip(by id: Int64) -> Trip? {
        allTrips.first { $0.id == id }
    }

    func getAllItems(for tripIdValue: Int64) -> [PackingItem] {
        guard let db = db else { return [] }
        do {
            let query = items.filter(itemTripId == tripIdValue).order(itemCategory, itemName)
            return try db.prepare(query).map { row in
                PackingItem(
                    id: row[itemId],
                    tripId: row[itemTripId],
                    name: row[itemName],
                    category: row[itemCategory],
                    isPacked: row[itemIsPacked]
                )
            }
        } catch {
            return []
        }
    }
}
