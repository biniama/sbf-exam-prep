import UserNotifications
import Foundation

/// Local daily study reminder. Nothing leaves the device.
@MainActor
final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    private let identifier = "sbf-daily"

    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        case .authorized, .provisional, .ephemeral:
            return true
        default:
            return false
        }
    }

    func scheduleDailyReminder(hour: Int = 18, minute: Int = 0) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Time to study! ⛵", comment: "Daily reminder title")
        content.body = String(localized: "Keep your streak going – a short SBF quiz takes just 5 minutes.",
                              comment: "Daily reminder body")
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }

    func cancelReminders() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
