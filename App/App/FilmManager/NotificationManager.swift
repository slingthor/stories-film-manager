import Foundation
import UserNotifications

// MARK: - NotificationManager - Handles macOS system notifications

class NotificationManager {

    private let notificationCenter = UNUserNotificationCenter.current()

    // MARK: - Request Permissions
    func requestPermissions() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Notification permissions granted")
            } else if let error = error {
                print("⚠️ Notification permission error: \(error.localizedDescription)")
            } else {
                print("⚠️ Notification permissions denied by user")
            }
        }
    }

    // MARK: - Send Notification
    func sendNotification(title: String, body: String, isError: Bool) async {
        print("[Sora] 📬 Attempting to send notification: '\(title)'")

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = isError ? .defaultCritical : .default

        // Add identifier for grouping
        content.threadIdentifier = "veo-import"

        // Create request
        let identifier = UUID().uuidString
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil  // nil = deliver immediately
        )

        do {
            try await notificationCenter.add(request)
            print("[Sora] ✅ Notification delivered successfully: '\(title)'")
        } catch {
            print("[Sora] ❌ Failed to send notification: \(error.localizedDescription)")
        }
    }

    // MARK: - Clear All Notifications
    func clearAllNotifications() {
        notificationCenter.removeAllDeliveredNotifications()
        print("🗑 Cleared all notifications")
    }

    // MARK: - Clear Veo Import Notifications
    func clearVeoImportNotifications() {
        notificationCenter.getDeliveredNotifications { notifications in
            let veoNotificationIds = notifications
                .filter { $0.request.content.threadIdentifier == "veo-import" }
                .map { $0.request.identifier }

            self.notificationCenter.removeDeliveredNotifications(withIdentifiers: veoNotificationIds)
            print("🗑 Cleared \(veoNotificationIds.count) Veo import notifications")
        }
    }
}
