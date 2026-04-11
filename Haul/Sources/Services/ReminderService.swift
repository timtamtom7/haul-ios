import Foundation
import UserNotifications

@MainActor
class ReminderService {
    static let shared = ReminderService()

    private var isAuthorized = false

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, _ in
            Task { @MainActor in
                self?.isAuthorized = granted
            }
        }
    }

    private func scheduleNotification(identifier: String, title: String, body: String, trigger: UNNotificationTrigger?) {
        guard isAuthorized else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func schedulePassportReminder(for trip: Trip) {
        guard trip.isOngoing || (Date() >= trip.startDate.addingTimeInterval(-86400) && Date() <= trip.endDate) else { return }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        scheduleNotification(
            identifier: "passport_\(trip.id ?? 0)",
            title: "Heading to \(trip.name)?",
            body: "Don't forget your passport!",
            trigger: trigger
        )
    }

    func scheduleDepartureReminder(for trip: Trip) {
        guard let tripId = trip.id else { return }

        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: trip.startDate)
        components.hour = 8
        components.minute = 0

        guard let triggerDate = calendar.date(from: components), triggerDate > Date() else { return }

        let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)

        scheduleNotification(
            identifier: "departure_\(tripId)",
            title: "Haul",
            body: "Heading to \(trip.name)? Check your bag.",
            trigger: trigger
        )
    }

    func cancelReminders(for tripId: Int64) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            "passport_\(tripId)",
            "departure_\(tripId)"
        ])
    }

    func cancelAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
