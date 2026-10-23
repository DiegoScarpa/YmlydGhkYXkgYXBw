import Foundation

@main
struct VerifyCore {
    static func main() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12) -> Date {
            calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
        }
        precondition(BirthdayCalculator.daysUntil(month: 1, day: 1, from: date(2026, 12, 31), calendar: calendar) == 1)
        precondition(BirthdayCalculator.birthday(in: 2027, month: 2, day: 29, calendar: calendar) == date(2027, 2, 28, 0))
        precondition(BirthdayCalculator.birthday(in: 2028, month: 2, day: 29, calendar: calendar) == date(2028, 2, 29, 0))
        precondition(!BirthdayDate(month: 4, day: 31, year: nil).isValid)
        let sarah = ReminderPerson(id: UUID(), name: "Sarah", birthday: BirthdayDate(month: 11, day: 1, year: nil))
        let plans = ReminderPlanner.plan(people: [sarah], offsets: [0, 1, 7], hour: 9, minute: 30, after: date(2026, 10, 23), calendar: calendar, maximum: 3)
        precondition(plans.map(\.daysBefore) == [7, 1, 0])
        precondition(Set(plans.map(\.id)).count == 3)
        precondition(plans[0].body.contains("7 days"))
        print("Core verification passed: recurrence, leap day, invalid dates, scheduling, deduplication")
    }
}
