import SwiftUI

@main
struct HaulApp: App {
    @StateObject private var tripStore = TripStore()
    @State private var hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

    var body: some Scene {
        WindowGroup {
            ZStack {
                if hasCompletedOnboarding {
                    TripsListView()
                        .environmentObject(tripStore)
                } else {
                    OnboardingContainerView {
                        hasCompletedOnboarding = true
                        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                    }
                }
            }
            .onAppear {
                ReminderService.shared.requestAuthorization()
            }
        }
    }
}
