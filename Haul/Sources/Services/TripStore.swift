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

    @Published var allTrips: [Trip] = []
    @Published var currentTripItems: [PackingItem] = []

    init() {
        setupDatabase()
        fetchAllTrips()
    }

    private func setupDatabase() {
        do {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let dbPath = documentsPath.appendingPathComponent("haul.sqlite3")
            db = try Connection(dbPath.path)

            try db?.run(trips.create(ifNotExists: true) { t in
                t.column(tripId, primaryKey: .autoincrement)
                t.column(tripName)
                t.column(tripStartDate)
                t.column(tripEndDate)
                t.column(tripSuitcasePhotoPath)
                t.column(tripCreatedAt)
            })

            try db?.run(items.create(ifNotExists: true) { t in
                t.column(itemId, primaryKey: .autoincrement)
                t.column(itemTripId)
                t.column(itemName)
                t.column(itemCategory)
                t.column(itemIsPacked, defaultValue: false)
            })
        } catch {
            print("Database setup error: \(error)")
        }
    }

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
            let tripItems = items.filter(itemTripId == id)
            try db.run(tripItems.delete())
            let query = trips.filter(tripId == id)
            try db.run(query.delete())
            fetchAllTrips()
        } catch {
            print("Delete trip error: \(error)")
        }
    }

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

    func addItem(to tripIdValue: Int64, name: String, category: String) {
        guard let db = db else { return }
        do {
            let insert = items.insert(
                itemTripId <- tripIdValue,
                itemName <- name,
                itemCategory <- category,
                itemIsPacked <- false
            )
            try db.run(insert)
            fetchItems(for: tripIdValue)
        } catch {
            print("Add item error: \(error)")
        }
    }

    func addItems(to tripIdValue: Int64, itemNames: [String], category: String) {
        for name in itemNames {
            addItem(to: tripIdValue, name: name, category: category)
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

    var upcomingTrips: [Trip] {
        allTrips.filter { $0.isUpcoming || $0.isOngoing }
    }

    var pastTrips: [Trip] {
        allTrips.filter { $0.isPast }
    }

    func getTrip(by id: Int64) -> Trip? {
        allTrips.first { $0.id == id }
    }
}
