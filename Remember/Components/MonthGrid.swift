import SwiftUI

struct MonthGrid: View {
    let month: Date
    @Binding var selectedDate: Date
    let people: [Person]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private var calendar: Calendar { .current }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                ForEach(weekdayNames, id: \.self) { day in
                    Text(day)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: columns, spacing: 5) {
                ForEach(0..<numberOfCells, id: \.self) { index in
                    if let date = date(at: index) {
                        Button {
                            selectedDate = date
                        } label: {
                            VStack(spacing: 4) {
                                Text("\(calendar.component(.day, from: date))")
                                    .font(.subheadline.weight(calendar.isDateInToday(date) ? .bold : .regular))
                                    .frame(width: 34, height: 34)
                                    .foregroundStyle(calendar.isDate(date, inSameDayAs: selectedDate) ? .white : .primary)
                                    .background(
                                        calendar.isDate(date, inSameDayAs: selectedDate) ? Color.accentColor : .clear,
                                        in: Circle()
                                    )
                                HStack(spacing: 2) {
                                    ForEach(Array(birthdays(on: date).prefix(3))) { person in
                                        Circle()
                                            .fill(person.category.color)
                                            .frame(width: 5, height: 5)
                                    }
                                }
                                .frame(height: 5)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(accessibilityLabel(for: date))
                        .accessibilityAddTraits(calendar.isDate(date, inSameDayAs: selectedDate) ? .isSelected : [])
                    } else {
                        Color.clear.frame(height: 48)
                    }
                }
            }
        }
    }

    private var weekdayNames: [String] {
        let names = calendar.veryShortStandaloneWeekdaySymbols
        return (0..<7).map { names[(calendar.firstWeekday - 1 + $0) % 7] }
    }

    private var firstDay: Date {
        let components = calendar.dateComponents([.year, .month], from: month)
        return calendar.date(from: components) ?? month
    }

    private var leadingSpaces: Int {
        (calendar.component(.weekday, from: firstDay) - calendar.firstWeekday + 7) % 7
    }

    private var daysInMonth: Int { calendar.range(of: .day, in: .month, for: firstDay)?.count ?? 30 }
    private var numberOfCells: Int { leadingSpaces + daysInMonth }

    private func date(at index: Int) -> Date? {
        let day = index - leadingSpaces + 1
        guard (1...daysInMonth).contains(day) else { return nil }
        return calendar.date(byAdding: .day, value: day - 1, to: firstDay)
    }

    private func birthdays(on date: Date) -> [Person] {
        let year = calendar.component(.year, from: date)
        return people.filter { person in
            guard let birthday = BirthdayCalculator.birthday(
                in: year,
                month: person.birthdayMonth,
                day: person.birthdayDay,
                calendar: calendar
            ) else { return false }
            return calendar.isDate(birthday, inSameDayAs: date)
        }
    }

    private func accessibilityLabel(for date: Date) -> String {
        let names = birthdays(on: date).map(\.fullName)
        let base = date.formatted(.dateTime.weekday(.wide).month(.wide).day())
        return names.isEmpty ? base : "\(base), birthdays: \(names.joined(separator: ", "))"
    }
}
