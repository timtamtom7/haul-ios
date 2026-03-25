import Foundation

/// R8: Sync service
@MainActor
final class HaulSyncService: ObservableObject {
    static let shared = HaulSyncService()

    @Published private(set) var isSyncing = false
    @Published private(set) var lastSyncDate: Date?

    func syncAll() async throws {
        guard !isSyncing else { return }
        isSyncing = true
        try await Task.sleep(nanoseconds: 500_000_000)
        lastSyncDate = Date()
        isSyncing = false
    }

    var lastSyncText: String {
        guard let date = lastSyncDate else { return "Never synced" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Synced \(formatter.localizedString(for: date, relativeTo: Date()))"
    }
}
