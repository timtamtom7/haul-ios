import Foundation

/// R9: Community service
@MainActor
final class HaulCommunityService: ObservableObject {
    static let shared = HaulCommunityService()

    @Published private(set) var posts: [Post] = []
    @Published private(set) var isLoading = false

    struct Post: Identifiable {
        let id = UUID()
        let anonymousId: String
        let content: String
        let timestamp: Date
        let likes: Int
    }

    func loadFeed() async {
        isLoading = true
        try? await Task.sleep(nanoseconds: 500_000_000)
        posts = [
            Post(anonymousId: "shipper_x7k2", content: "Just shipped a package!", timestamp: Date().addingTimeInterval(-3600), likes: 24),
            Post(anonymousId: "hauler_m3p9", content: "First delivery complete", timestamp: Date().addingTimeInterval(-7200), likes: 42)
        ]
        isLoading = false
    }
}
