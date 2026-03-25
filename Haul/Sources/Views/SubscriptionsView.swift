import SwiftUI

/// R10: Subscriptions view
struct HaulSubscriptionsView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.yellow)

                    Text("Unlock Premium")
                        .font(.title)
                        .fontWeight(.bold)

                    VStack(spacing: 12) {
                        planCard(title: "Premium", price: "$4.99", features: ["Unlimited shipments", "Cloud backup", "Priority support"])
                        planCard(title: "Pro", price: "$9.99", features: ["Everything in Premium", "Team sharing", "API access"])
                    }
                }
                .padding()
            }
            .navigationTitle("Subscribe")
        }
    }

    private func planCard(title: String, price: String, features: [String]) -> some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.headline)
            Text(price)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            ForEach(features, id: \.self) { feature in
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(feature)
                    Spacer()
                }
            }
            Button("Subscribe") {}
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
