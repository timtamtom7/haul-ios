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
            guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                return
            }
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

    /// Duplicates a trip with all its items and bags.
    /// Dates are shifted so the new trip starts today (if original is past/upcoming) or at the same relative offset.
    func duplicateTrip(_ trip: Trip) -> Int64? {
        guard let db = db, let originalId = trip.id else { return nil }

        // Calculate new dates: shift so the original start date aligns to today
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let originalStart = calendar.startOfDay(for: trip.startDate)
        let tripDuration = calendar.dateComponents([.day], from: trip.startDate, to: trip.endDate).day ?? 7

        let daysOffset = calendar.dateComponents([.day], from: originalStart, to: today).day ?? 0
        let newStartDate = calendar.date(byAdding: .day, value: daysOffset, to: trip.startDate) ?? trip.startDate
        let newEndDate = calendar.date(byAdding: .day, value: tripDuration, to: newStartDate) ?? trip.endDate

        // Create the new trip
        guard let newTripId = createTrip(
            name: "\(trip.name) (Copy)",
            startDate: newStartDate,
            endDate: newEndDate,
            suitcasePhotoPath: nil
        ) else { return nil }

        do {
            // Copy bags and build old→new ID mapping
            var bagIdMapping: [Int64: Int64] = [:]
            let originalBags = bags.filter(bagTripId == originalId)
            for bagRow in try db.prepare(originalBags) {
                let originalBagId = bagRow[bagId]
                let insert = bags.insert(
                    bagTripId <- newTripId,
                    bagName <- bagRow[bagName],
                    bagType <- bagRow[bagType],
                    bagColorHex <- bagRow[bagColorHex],
                    bagCreatedAt <- Date()
                )
                let newBagId = try db.run(insert)
                bagIdMapping[originalBagId] = newBagId
            }

            // Copy items with remapped bag IDs
            let originalItems = items.filter(itemTripId == originalId)
            for itemRow in try db.prepare(originalItems) {
                let originalBagId = itemRow[itemBagId]
                let newBagId: Int64? = originalBagId.flatMap { bagIdMapping[$0] }
                let insert = items.insert(
                    itemTripId <- newTripId,
                    itemName <- itemRow[itemName],
                    itemCategory <- itemRow[itemCategory],
                    itemIsPacked <- false,
                    itemBagId <- newBagId
                )
                try db.run(insert)
            }

            fetchAllTrips()
            return newTripId
        } catch {
            print("Duplicate trip error: \(error)")
            return nil
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
                    isPacked: row[itemIsPacked],
                    bagId: row[itemBagId]
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
                    isPacked: row[itemIsPacked],
                    bagId: row[itemBagId]
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
        // Get existing item names to avoid duplicates
        let existingNames = Set(currentTripItems.filter { $0.tripId == tripIdValue }.map { $0.name.lowercased() })
        for name in itemNames {
            if !existingNames.contains(name.lowercased()) {
                addItem(to: tripIdValue, name: name, category: category, bagId: bagId)
            }
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
            let dbTemplates = try db.prepare(query).map { row -> PackingTemplate in
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
            // Deduplicate by ID before merging
            var seenIds = Set<Int64>()
            var result: [PackingTemplate] = []
            for template in dbTemplates {
                if let tid = template.id, !seenIds.contains(tid) {
                    seenIds.insert(tid)
                    result.append(template)
                }
            }
            // Append built-ins that don't already exist in DB (built-ins have id=nil, safe to always append)
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
                    isPacked: row[itemIsPacked],
                    bagId: row[itemBagId]
                )
            }
        } catch {
            return []
        }
    }
}
