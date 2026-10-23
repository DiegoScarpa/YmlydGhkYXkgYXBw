import Foundation

struct ReminderPerson {
    let id: UUID
    let name: String
    let birthday: BirthdayDate
    let customOffsets: Set<Int>?
    let giftIdeaCount: Int

    init(id: UUID, name: String, birthday: BirthdayDate, customOffsets: Set<Int>? = nil, giftIdeaCount: Int = 0) {
        self.id = id
        self.name = name
        self.birthday = birthday
        self.customOffsets = customOffsets
        self.giftIdeaCount = giftIdeaCount
    }
}

struct PlannedReminder: Identifiable {
    let id: String
    let personID: UUID
    let name: String
    let birthday: Date
    let fireDate: Date
    let daysBefore: Int
    let giftIdeaCount: Int

    var title: String {
        daysBefore == 0 ? "🎂 It's \(name)'s birthday!" : "🎂 \(name)'s birthday is coming up"
    }

    var body: String {
        switch daysBefore {
        case 0: return "Wish \(name) a happy birthday today."
        case 1: return "Tomorrow is \(name)'s birthday! Don't forget to reach out."
        default:
            let gifts = giftIdeaCount > 0 ? " You saved \(giftIdeaCount) gift \(giftIdeaCount == 1 ? "idea" : "ideas")." : ""
            return "\(name)'s birthday is in \(daysBefore) days.\(gifts)"
        }
    }
}

enum ReminderPlanner {
    static let allowedOffsets = [0, 1, 3, 7, 14, 30]

    static func plan(
        people: [ReminderPerson],
        offsets: Set<Int>,
        hour: Int,
        minute: Int,
        after now: Date,
        calendar: Calendar = .current,
        maximum: Int = 60
    ) -> [PlannedReminder] {
        guard (0...23).contains(hour), (0...59).contains(minute), maximum > 0 else { return [] }
        let year = calendar.component(.year, from: now)
        var reminders: [PlannedReminder] = []

        for person in people where person.birthday.isValid {
            for targetYear in year...(year + 3) {
                guard let birthday = BirthdayCalculator.birthday(
                    in: targetYear,
                    month: person.birthday.month,
                    day: person.birthday.day,
                    calendar: calendar
                ), let birthdayAtTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: birthday)
                else { continue }

                for offset in (person.customOffsets ?? offsets) where allowedOffsets.contains(offset) {
                    guard let fireDate = calendar.date(byAdding: .day, value: -offset, to: birthdayAtTime),
                          fireDate > now
                    else { continue }
                    reminders.append(PlannedReminder(
                        id: "remember.\(person.id.uuidString).\(targetYear).\(offset)",
                        personID: person.id,
                        name: person.name,
                        birthday: birthday,
                        fireDate: fireDate,
                        daysBefore: offset,
                        giftIdeaCount: person.giftIdeaCount
                    ))
                }
            }
        }

        return Array(reminders.sorted {
            if $0.fireDate != $1.fireDate { return $0.fireDate < $1.fireDate }
            return $0.id < $1.id
        }.prefix(maximum))
    }
}
