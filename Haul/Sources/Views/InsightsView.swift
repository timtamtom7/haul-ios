import SwiftUI

/// R7: Insights view
struct HaulInsightsView: View {
    @StateObject private var insightsService = HaulInsightsService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()

                if insightsService.isAnalyzing {
                    ProgressView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(insightsService.insights) { insight in
                                insightCard(insight)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Insights")
            .task {
                if insightsService.insights.isEmpty {
                    await insightsService.analyzeAll()
                }
            }
        }
    }

    private func insightCard(_ insight: HaulInsightsService.Insight) -> some View {
        HStack {
            Image(systemName: insight.icon)
                .font(.title2)
                .foregroundColor(.blue)
            VStack(alignment: .leading) {
                Text(insight.title)
                    .font(.subheadline)
                Text(insight.value)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
