import Foundation
import UserNotifications

enum ReminderPreferences {
    static let enabledKey = "remindersEnabled"
    static let offsetsKey = "reminderOffsets"
    static let hourKey = "reminderHour"
    static let minuteKey = "reminderMinute"

    static var enabled: Bool { UserDefaults.standard.bool(forKey: enabledKey) }

    static var offsets: Set<Int> {
        guard let raw = UserDefaults.standard.string(forKey: offsetsKey) else { return [0, 7] }
        return Set(raw.split(separator: ",").compactMap { Int($0) })
    }

    static var hour: Int { UserDefaults.standard.object(forKey: hourKey) as? Int ?? 9 }
    static var minute: Int { UserDefaults.standard.object(forKey: minuteKey) as? Int ?? 0 }
}

@MainActor
final class NotificationCoordinator {
    static let shared = NotificationCoordinator()
    private let center = UNUserNotificationCenter.current()
    private init() {}

    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .badge, .sound])
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    /// Replaces only Remember's pending requests. IDs are stable, so edits cannot leave duplicates.
    func refresh(people: [Person], extras: [ProfileExtras] = []) async throws {
        let existing = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix("remember.") }
        center.removePendingNotificationRequests(withIdentifiers: existing)

        guard ReminderPreferences.enabled else { return }
        let status = await authorizationStatus()
        guard status == .authorized || status == .provisional else { return }

        let extrasByPerson = Dictionary(extras.map { ($0.personID, $0) }, uniquingKeysWith: { first, _ in first })
        let records = people.filter { extrasByPerson[$0.id]?.remindersDisabled != true }.map { person in
            let extra = extrasByPerson[person.id]
            let customOffsets: Set<Int>?
            if let raw = extra?.reminderOffsetsRaw, !raw.isEmpty {
                customOffsets = Set(raw.split(separator: ",").compactMap { Int($0) })
            } else {
                customOffsets = nil
            }
            return ReminderPerson(
                id: person.id,
                name: person.fullName,
                birthday: BirthdayDate(month: person.birthdayMonth, day: person.birthdayDay, year: person.birthYear),
                customOffsets: customOffsets,
                giftIdeaCount: extra?.giftItems.filter { $0.kind == .idea }.count ?? 0
            )
        }
        let reminders = ReminderPlanner.plan(
            people: records,
            offsets: ReminderPreferences.offsets,
            hour: ReminderPreferences.hour,
            minute: ReminderPreferences.minute,
            after: .now
        )
        for reminder in reminders {
            let content = UNMutableNotificationContent()
            content.title = reminder.title
            content.body = reminder.body
            content.sound = .default
            content.userInfo = ["personID": reminder.personID.uuidString]
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: reminder.fireDate
            )
            let request = UNNotificationRequest(
                identifier: reminder.id,
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            )
            try await center.add(request)
        }
    }
}
