import Foundation
import os.log

/// R10: Export service — JSON/CSV backup of trip data
struct ExportService {
    static let shared = ExportService()
    private init() {}

    private let logger = Logger(subsystem: "com.haulapp.ios", category: "ExportService")

    // MARK: - JSON Export

    /// Exports a single trip to a JSON file URL (for sharing)
    func exportTripToJSON(trip: Trip, items: [PackingItem], bags: [Bag]) -> URL? {
        let data = TripExportData(
            version: 1,
            exportDate: ISO8601DateFormatter().string(from: Date()),
            trip: TripExport(
                name: trip.name,
                startDate: ISO8601DateFormatter().string(from: trip.startDate),
                endDate: ISO8601DateFormatter().string(from: trip.endDate),
                createdAt: ISO8601DateFormatter().string(from: trip.createdAt)
            ),
            items: items.map { item in
                ItemExport(
                    name: item.name,
                    category: item.category,
                    isPacked: item.isPacked,
                    bagName: bags.first { $0.id == item.bagId }.map { $0.name }
                )
            },
            bags: bags.map { bag in
                BagExport(
                    name: bag.name,
                    type: bag.bagType.rawValue,
                    colorHex: bag.colorHex
                )
            }
        )

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let jsonData = try encoder.encode(data)
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("Haul_\(sanitizeFilename(trip.name))_\(Date().timeIntervalSince1970).json")
            try jsonData.write(to: tempURL)
            logger.info("Exported trip '\(trip.name)' to JSON: \(tempURL.lastPathComponent)")
            return tempURL
        } catch {
            logger.error("JSON export failed: \(error.localizedDescription)")
            return nil
        }
    }

    /// Exports all trips to a single JSON file
    func exportAllTripsToJSON(trips: [Trip], getItems: (Int64) -> [PackingItem], getBags: (Int64) -> [Bag]) -> URL? {
        let tripExports = trips.compactMap { trip -> TripExportFull? in
            guard let id = trip.id else { return nil }
            return TripExportFull(
                name: trip.name,
                startDate: ISO8601DateFormatter().string(from: trip.startDate),
                endDate: ISO8601DateFormatter().string(from: trip.endDate),
                items: getItems(id).map { item in
                    let bags = getBags(id)
                    return ItemExport(
                        name: item.name,
                        category: item.category,
                        isPacked: item.isPacked,
                        bagName: bags.first { $0.id == item.bagId }.map { $0.name }
                    )
                },
                bags: getBags(id).map { bag in
                    BagExport(name: bag.name, type: bag.bagType.rawValue, colorHex: bag.colorHex)
                }
            )
        }

        let data = AllTripsExport(
            version: 1,
            exportDate: ISO8601DateFormatter().string(from: Date()),
            tripCount: tripExports.count,
            trips: tripExports
        )

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let jsonData = try encoder.encode(data)
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("Haul_Backup_\(Date().timeIntervalSince1970).json")
            try jsonData.write(to: tempURL)
            logger.info("Exported all \(tripExports.count) trips to JSON")
            return tempURL
        } catch {
            logger.error("All-trips JSON export failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - CSV Export

    /// Exports a trip's items to CSV format
    func exportTripToCSV(trip: Trip, items: [PackingItem], bags: [Bag]) -> URL? {
        var csv = "Category,Item,Packed,Bag\n"
        for item in items {
            let bagName = bags.first { $0.id == item.bagId }.map { "\"\($0.name)\"" } ?? ""
            csv += "\"\(item.category)\",\"\(escapeCSV(item.name))\",\"\(item.isPacked ? "Yes" : "No")\",\(bagName)\n"
        }

        do {
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("Haul_\(sanitizeFilename(trip.name))_items_\(Int(Date().timeIntervalSince1970)).csv")
            try csv.write(to: tempURL, atomically: true, encoding: .utf8)
            logger.info("Exported trip '\(trip.name)' to CSV")
            return tempURL
        } catch {
            logger.error("CSV export failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Helpers

    private func sanitizeFilename(_ name: String) -> String {
        let illegal = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        return name.components(separatedBy: illegal).joined(separator: "_")
    }

    private func escapeCSV(_ string: String) -> String {
        string.replacingOccurrences(of: "\"", with: "\"\"")
    }
}

// MARK: - Export Data Models

private struct TripExportData: Codable {
    let version: Int
    let exportDate: String
    let trip: TripExport
    let items: [ItemExport]
    let bags: [BagExport]
}

private struct AllTripsExport: Codable {
    let version: Int
    let exportDate: String
    let tripCount: Int
    let trips: [TripExportFull]
}

private struct TripExport: Codable {
    let name: String
    let startDate: String
    let endDate: String
    let createdAt: String
}

private struct TripExportFull: Codable {
    let name: String
    let startDate: String
    let endDate: String
    let items: [ItemExport]
    let bags: [BagExport]
}

private struct ItemExport: Codable {
    let name: String
    let category: String
    let isPacked: Bool
    let bagName: String?
}

private struct BagExport: Codable {
    let name: String
    let type: String
    let colorHex: String
}
