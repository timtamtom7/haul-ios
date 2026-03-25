import SwiftUI

/// R9: Community view
struct HaulCommunityView: View {
    @StateObject private var communityService = HaulCommunityService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()

                if communityService.isLoading {
                    ProgressView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(communityService.posts) { post in
                                postCard(post)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Community")
            .task {
                await communityService.loadFeed()
            }
        }
    }

    private func postCard(_ post: HaulCommunityService.Post) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(post.anonymousId)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(post.content)
            HStack {
                Spacer()
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("\(post.likes)")
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
