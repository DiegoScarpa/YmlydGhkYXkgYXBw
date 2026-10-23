import Foundation

struct BirthdayDate: Equatable {
    let month: Int
    let day: Int
    let year: Int?

    var isValid: Bool {
        guard (1...12).contains(month), (1...31).contains(day) else { return false }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let referenceYear = year ?? 2000 // A leap year keeps February 29 available without a birth year.
        guard (1800...9999).contains(referenceYear),
              let date = calendar.date(from: DateComponents(year: referenceYear, month: month, day: day))
        else { return false }
        return calendar.component(.month, from: date) == month && calendar.component(.day, from: date) == day
    }
}

enum BirthdayCalculator {
    /// February 29 birthdays are observed on February 28 in non-leap years.
    static func birthday(in year: Int, month: Int, day: Int, calendar: Calendar = .current) -> Date? {
        guard BirthdayDate(month: month, day: day, year: nil).isValid else { return nil }
        let observedDay = month == 2 && day == 29 && !isLeapYear(year) ? 28 : day
        guard let date = calendar.date(from: DateComponents(year: year, month: month, day: observedDay)),
              calendar.component(.month, from: date) == month,
              calendar.component(.day, from: date) == observedDay
        else { return nil }
        return calendar.startOfDay(for: date)
    }

    static func nextBirthday(month: Int, day: Int, after date: Date, calendar: Calendar = .current) -> Date? {
        let today = calendar.startOfDay(for: date)
        let year = calendar.component(.year, from: today)
        for candidateYear in year...(year + 1) {
            if let candidate = birthday(in: candidateYear, month: month, day: day, calendar: calendar),
               candidate >= today {
                return candidate
            }
        }
        return nil
    }

    static func daysUntil(month: Int, day: Int, from date: Date, calendar: Calendar = .current) -> Int? {
        guard let next = nextBirthday(month: month, day: day, after: date, calendar: calendar) else { return nil }
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: next).day
    }

    static func age(birthYear: Int?, on birthday: Date, calendar: Calendar = .current) -> Int? {
        guard let birthYear else { return nil }
        return calendar.component(.year, from: birthday) - birthYear
    }

    private static func isLeapYear(_ year: Int) -> Bool {
        year.isMultiple(of: 400) || (year.isMultiple(of: 4) && !year.isMultiple(of: 100))
    }
}
