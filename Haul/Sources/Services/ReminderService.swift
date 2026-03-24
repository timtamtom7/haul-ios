import Foundation
import UserNotifications

@MainActor
class ReminderService {
    static let shared = ReminderService()

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }

    func schedulePassportReminder(for trip: Trip) {
        guard trip.isOngoing || (Date() >= trip.startDate.addingTimeInterval(-86400) && Date() <= trip.endDate) else { return }

        let content = UNMutableNotificationContent()
        content.title = "Heading to \(trip.name)?"
        content.body = "Don't forget your passport!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(
            identifier: "passport_\(trip.id ?? 0)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func scheduleDepartureReminder(for trip: Trip) {
        guard let tripId = trip.id else { return }

        // Schedule reminder for the morning of departure
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: trip.startDate)
        components.hour = 8
        components.minute = 0

        guard let triggerDate = calendar.date(from: components), triggerDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Haul"
        content.body = "Heading to \(trip.name)? Check your bag."
        content.sound = .default

        let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)

        let request = UNNotificationRequest(
            identifier: "departure_\(tripId)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func cancelReminders(for tripId: Int64) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            "passport_\(tripId)",
            "departure_\(tripId)"
        ])
    }
}
