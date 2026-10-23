import SwiftUI

private enum PeopleSort: String, CaseIterable, Identifiable {
    case upcoming = "Upcoming birthday"
    case name = "Name"
    case relationship = "Relationship"
    case recent = "Recently added"
    case month = "Birthday month"
    var id: String { rawValue }
}

struct PeopleView: View {
    let people: [Person]
    let onAdd: () -> Void
    @State private var searchText = ""
    @State private var sort: PeopleSort = .upcoming
    @State private var category = "All"

    var body: some View {
        NavigationStack {
            List {
                if filteredPeople.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(filteredPeople) { person in
                        NavigationLink {
                            PersonDetailView(person: person)
                        } label: {
                            BirthdayRow(person: person, referenceDate: .now)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("People")
            .searchable(text: $searchText, prompt: "Names, interests, notes")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Sort", selection: $sort) {
                            ForEach(PeopleSort.allCases) { option in Text(option.rawValue).tag(option) }
                        }
                        Picker("Relationship", selection: $category) {
                            Text("All relationships").tag("All")
                            ForEach(RelationshipCategory.allCases) { option in
                                Text(option.rawValue).tag(option.rawValue)
                            }
                        }
                    } label: {
                        Label("Filter and sort", systemImage: "line.3.horizontal.decrease")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: onAdd) { Label("Add Person", systemImage: "plus") }
                        .accessibilityLabel("Add person")
                }
            }
        }
    }

    private var filteredPeople: [Person] {
        let filtered = people.filter {
            (category == "All" || $0.categoryRaw == category) &&
            (searchText.isEmpty || $0.searchText.localizedStandardContains(searchText))
        }
        return filtered.sorted { first, second in
            switch sort {
            case .upcoming:
                let a = BirthdayCalculator.daysUntil(month: first.birthdayMonth, day: first.birthdayDay, from: .now) ?? 999
                let b = BirthdayCalculator.daysUntil(month: second.birthdayMonth, day: second.birthdayDay, from: .now) ?? 999
                return a == b ? first.fullName < second.fullName : a < b
            case .name:
                return first.fullName.localizedStandardCompare(second.fullName) == .orderedAscending
            case .relationship:
                return first.categoryRaw == second.categoryRaw ? first.fullName < second.fullName : first.categoryRaw < second.categoryRaw
            case .recent:
                return first.createdAt > second.createdAt
            case .month:
                return first.birthdayMonth == second.birthdayMonth ? first.birthdayDay < second.birthdayDay : first.birthdayMonth < second.birthdayMonth
            }
        }
    }
}
