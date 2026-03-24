import Foundation

struct Trip: Identifiable, Equatable {
    var id: Int64?
    var name: String
    var startDate: Date
    var endDate: Date
    var suitcasePhotoPath: String?
    var createdAt: Date

    var isUpcoming: Bool {
        startDate > Date()
    }

    var isPast: Bool {
        endDate < Date()
    }

    var isOngoing: Bool {
        let now = Date()
        return startDate <= now && endDate >= now
    }

    var displayDateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = formatter.string(from: startDate)
        let end = formatter.string(from: endDate)
        return "\(start)–\(end)"
    }
}
