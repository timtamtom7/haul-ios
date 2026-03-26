import Foundation
import UIKit

@MainActor
class PhotoStorageService {
    static let shared = PhotoStorageService()
    private let fileManager = FileManager.default

    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
    }

    private var photosDirectory: URL {
        let dir = documentsDirectory.appendingPathComponent("SuitcasePhotos", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    func savePhoto(_ image: UIImage, for tripId: Int64) -> String? {
        let filename = "suitcase_\(tripId)_\(Int(Date().timeIntervalSince1970)).jpg"
        let fileURL = photosDirectory.appendingPathComponent(filename)

        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }

        do {
            try data.write(to: fileURL)
            return fileURL.path
        } catch {
            print("Error saving photo: \(error)")
            return nil
        }
    }

    func loadPhoto(at path: String) -> UIImage? {
        return UIImage(contentsOfFile: path)
    }

    func deletePhoto(at path: String) {
        try? fileManager.removeItem(atPath: path)
    }
}
