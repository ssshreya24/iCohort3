import UserNotifications

/// Fires local notifications when new tasks are assigned to the student's team.
/// Tracks already-seen task IDs in UserDefaults to avoid repeat notifications.
final class StudentNotificationManager {
    static let shared = StudentNotificationManager()
    private init() {}

    private let seenKey = "student_seen_task_ids"

    // MARK: - Permission

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error { print("❌ [Notification] Permission error:", error.localizedDescription) }
            print(granted ? "✅ [Notification] Permission granted" : "⚠️ [Notification] Permission denied")
        }
    }

    // MARK: - New Task Detection

    /// Compare fetched task IDs against previously-seen IDs and fire a notification for each new one.
    func notifyNewTasks(taskIds: [(id: String, title: String)], teamName: String) {
        let shouldNotify = UserDefaults.standard.bool(forKey: "profile_notifications_enabled")
        var seen = seenTaskIds()
        for task in taskIds where !seen.contains(task.id) {
            if shouldNotify {
                scheduleNotification(taskTitle: task.title, teamName: teamName)
            }
            seen.insert(task.id)
        }
        saveSeenTaskIds(seen)
    }

    // MARK: - Schedule

    private func scheduleNotification(taskTitle: String, teamName: String) {
        let content      = UNMutableNotificationContent()
        content.title    = "New Task Assigned 📋"
        content.body     = "\"\(taskTitle)\" has been assigned to \(teamName)"
        content.sound    = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        let id      = UUID().uuidString
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("❌ [Notification] Failed to schedule:", error.localizedDescription) }
        }
    }

    // MARK: - Persistence

    private func seenTaskIds() -> Set<String> {
        let arr = UserDefaults.standard.stringArray(forKey: seenKey) ?? []
        return Set(arr)
    }

    private func saveSeenTaskIds(_ ids: Set<String>) {
        UserDefaults.standard.set(Array(ids), forKey: seenKey)
    }
}
