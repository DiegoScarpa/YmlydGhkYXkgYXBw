import Foundation
import XCTest
@testable import RememberCore

final class BirthdayCalculatorTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    func testTodayAndYearRollover() {
        XCTAssertEqual(BirthdayCalculator.daysUntil(month: 12, day: 31, from: date(2026, 12, 31), calendar: calendar), 0)
        XCTAssertEqual(BirthdayCalculator.daysUntil(month: 1, day: 1, from: date(2026, 12, 31), calendar: calendar), 1)
        XCTAssertEqual(BirthdayCalculator.nextBirthday(month: 1, day: 1, after: date(2026, 12, 31), calendar: calendar), date(2027, 1, 1, hour: 0))
    }

    func testLeapDayObservation() {
        XCTAssertEqual(BirthdayCalculator.birthday(in: 2028, month: 2, day: 29, calendar: calendar), date(2028, 2, 29, hour: 0))
        XCTAssertEqual(BirthdayCalculator.birthday(in: 2027, month: 2, day: 29, calendar: calendar), date(2027, 2, 28, hour: 0))
        XCTAssertEqual(BirthdayCalculator.daysUntil(month: 2, day: 29, from: date(2027, 2, 27), calendar: calendar), 1)
    }

    func testInvalidBirthdayAndAge() {
        XCTAssertFalse(BirthdayDate(month: 4, day: 31, year: nil).isValid)
        XCTAssertFalse(BirthdayDate(month: 2, day: 29, year: 2001).isValid)
        XCTAssertTrue(BirthdayDate(month: 2, day: 29, year: nil).isValid)
        XCTAssertEqual(BirthdayCalculator.age(birthYear: 2000, on: date(2028, 2, 29), calendar: calendar), 28)
        XCTAssertNil(BirthdayCalculator.age(birthYear: nil, on: date(2028, 2, 29), calendar: calendar))
    }

    func testReminderOffsetsAndStableIDs() {
        let id = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let person = ReminderPerson(id: id, name: "Sarah", birthday: BirthdayDate(month: 11, day: 1, year: nil))
        let plans = ReminderPlanner.plan(
            people: [person], offsets: [0, 1, 7], hour: 9, minute: 30,
            after: date(2026, 10, 23), calendar: calendar, maximum: 3
        )
        XCTAssertEqual(plans.map(\.daysBefore), [7, 1, 0])
        XCTAssertEqual(plans.first?.fireDate, date(2026, 10, 25, hour: 9).addingTimeInterval(30 * 60))
        XCTAssertEqual(Set(plans.map(\.id)).count, plans.count)
        XCTAssertEqual(plans.map(\.id), ReminderPlanner.plan(
            people: [person], offsets: [0, 1, 7], hour: 9, minute: 30,
            after: date(2026, 10, 23), calendar: calendar, maximum: 3
        ).map(\.id))
    }

    func testPlannerSkipsPastTimesAndCapsPendingRequests() {
        let person = ReminderPerson(id: UUID(), name: "Alex", birthday: BirthdayDate(month: 10, day: 23, year: nil))
        let plans = ReminderPlanner.plan(
            people: [person], offsets: [0, 1], hour: 9, minute: 0,
            after: date(2026, 10, 23, hour: 12), calendar: calendar, maximum: 2
        )
        XCTAssertEqual(plans.count, 2)
        XCTAssertTrue(plans.allSatisfy { $0.fireDate > date(2026, 10, 23) })
        XCTAssertTrue(plans.allSatisfy { $0.id.contains("2027") })
    }

    func testPersonalOffsetsOverrideGlobalAndGiftIdeasAppearInBody() {
        let person = ReminderPerson(
            id: UUID(), name: "Michael", birthday: BirthdayDate(month: 11, day: 1, year: nil),
            customOffsets: [7], giftIdeaCount: 3
        )
        let plans = ReminderPlanner.plan(
            people: [person], offsets: [0, 1], hour: 9, minute: 0,
            after: date(2026, 10, 23), calendar: calendar, maximum: 1
        )
        XCTAssertEqual(plans.map(\.daysBefore), [7])
        XCTAssertTrue(plans[0].body.contains("3 gift ideas"))
    }
}
