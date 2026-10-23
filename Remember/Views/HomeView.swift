import SwiftUI

struct HomeView: View {
    let people: [Person]
    let extras: [ProfileExtras]
    @Binding var selection: AppTab
    let onAdd: () -> Void
    @State private var previewDate = Date.now

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    if people.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Image(systemName: "heart.text.square")
                                .font(.title)
                                .foregroundStyle(Color.accentColor)
                            Text("Remember someone special")
                                .font(.title3.bold())
                            Text("Add a person to see birthdays and the details that matter to them.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Button("Add Person", action: onAdd)
                                .buttonStyle(.borderedProminent)
                                .accessibilityIdentifier("home.addPerson")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
                    } else {
                        birthdaySection("Today", systemImage: "sparkles", people: inRange(0...0))
                        birthdaySection("Next 7 Days", systemImage: "sun.max", people: inRange(1...7))
                        birthdaySection("Coming Up", systemImage: "gift", people: inRange(8...30))
                        Button {
                            selection = .people
                        } label: {
                            Label("See all people", systemImage: "person.2")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.bordered)
                    }
                    calendarPreview
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Remember")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: onAdd) { Label("Add Person", systemImage: "plus") }
                        .accessibilityLabel("Add person")
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Text("Keep close to what matters.")
                .font(.largeTitle.bold())
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }

    private func inRange(_ range: ClosedRange<Int>) -> [Person] {
        people.filter {
            guard let days = BirthdayCalculator.daysUntil(month: $0.birthdayMonth, day: $0.birthdayDay, from: .now) else { return false }
            return range.contains(days)
        }.sorted {
            let first = BirthdayCalculator.daysUntil(month: $0.birthdayMonth, day: $0.birthdayDay, from: .now) ?? 999
            let second = BirthdayCalculator.daysUntil(month: $1.birthdayMonth, day: $1.birthdayDay, from: .now) ?? 999
            return first == second ? $0.fullName < $1.fullName : first < second
        }
    }

    @ViewBuilder
    private func birthdaySection(_ title: String, systemImage: String, people: [Person]) -> some View {
        if !people.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Label(title, systemImage: systemImage)
                    .font(.title3.bold())
                    .padding(.horizontal, 2)
                VStack(spacing: 0) {
                    ForEach(people) { person in
                        NavigationLink {
                            PersonDetailView(person: person)
                        } label: {
                            BirthdayRow(person: person, referenceDate: .now, photoData: extras.first { $0.personID == person.id }?.photoData)
                        }
                        .buttonStyle(.plain)
                        if person.id != people.last?.id { Divider().padding(.leading, 66) }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
            }
        }
    }

    private var calendarPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("This Month").font(.title3.bold())
                Spacer()
                Button("Full calendar") { selection = .calendar }
                    .font(.subheadline.weight(.semibold))
            }
            MonthGrid(month: .now, selectedDate: $previewDate, people: people)
                .padding(14)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
        }
    }
}
