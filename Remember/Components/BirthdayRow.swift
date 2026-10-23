import SwiftUI

struct BirthdayRow: View {
    let person: Person
    let referenceDate: Date
    var photoData: Data? = nil

    var body: some View {
        HStack(spacing: 14) {
            PersonAvatar(person: person, size: 52, photoData: photoData)
            VStack(alignment: .leading, spacing: 4) {
                Text(person.fullName).font(.headline)
                Text(dateLabel).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Text(countdownLabel)
                .font(.caption.weight(.semibold))
                .foregroundStyle(person.category.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(person.category.color.opacity(0.10), in: Capsule())
        }
        .padding(.vertical, 5)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(person.fullName), \(dateLabel), \(countdownLabel)")
    }

    private var dateLabel: String {
        guard let date = BirthdayCalculator.nextBirthday(
            month: person.birthdayMonth,
            day: person.birthdayDay,
            after: referenceDate
        ) else { return "Birthday unavailable" }
        return date.formatted(.dateTime.month(.wide).day())
    }

    private var countdownLabel: String {
        switch BirthdayCalculator.daysUntil(
            month: person.birthdayMonth,
            day: person.birthdayDay,
            from: referenceDate
        ) {
        case .some(0): "Today"
        case .some(1): "Tomorrow"
        case .some(let days): "\(days) days"
        case .none: "—"
        }
    }
}
