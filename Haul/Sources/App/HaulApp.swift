import SwiftUI

@main
struct HaulApp: App {
    @StateObject private var tripStore = TripStore()
    @State private var hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                TripsListView()
                    .environmentObject(tripStore)
                    .preferredColorScheme(.light)
            } else {
                OnboardingContainerView {
                    hasCompletedOnboarding = true
                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                }
                .preferredColorScheme(.light)
            }
        }
    }
}
