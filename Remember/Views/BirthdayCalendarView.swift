import SwiftUI

struct BirthdayCalendarView: View {
    let people: [Person]
    @State private var displayedMonth = Date.now
    @State private var selectedDate = Date.now
    @State private var showingYear = false
    @State private var showingAddPerson = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Picker("Calendar view", selection: $showingYear) {
                        Text("Month").tag(false)
                        Text("Year").tag(true)
                    }
                    .pickerStyle(.segmented)

                    if showingYear {
                        yearContent
                    } else {
                        monthContent
                    }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAddPerson = true } label: {
                        Label("Add Person", systemImage: "plus")
                    }
                    .accessibilityLabel("Add person on selected date")
                }
            }
            .sheet(isPresented: $showingAddPerson) {
                NavigationStack { PersonEditorView(preselectedBirthday: selectedDate) }
            }
        }
    }

    private var monthContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Button { moveMonth(-1) } label: { Image(systemName: "chevron.left") }
                    .accessibilityLabel("Previous month")
                Spacer()
                Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                    .font(.title2.bold())
                Spacer()
                Button { moveMonth(1) } label: { Image(systemName: "chevron.right") }
                    .accessibilityLabel("Next month")
            }
            .buttonStyle(.borderless)

            MonthGrid(month: displayedMonth, selectedDate: $selectedDate, people: people)
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
                .gesture(
                    DragGesture(minimumDistance: 60).onEnded { value in
                        if value.translation.width < -60 { moveMonth(1) }
                        if value.translation.width > 60 { moveMonth(-1) }
                    }
                )

            HStack {
                Text(selectedDate.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(.title3.bold())
                Spacer()
                Button { showingAddPerson = true } label: { Label("Add", systemImage: "plus") }
                    .font(.subheadline.weight(.semibold))
            }

            if selectedBirthdays.isEmpty {
                Text("No birthdays on this date.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
            } else {
                VStack(spacing: 0) {
                    ForEach(selectedBirthdays) { person in
                        NavigationLink {
                            PersonDetailView(person: person)
                        } label: {
                            BirthdayRow(person: person, referenceDate: selectedDate)
                        }
                        .buttonStyle(.plain)
                        if person.id != selectedBirthdays.last?.id { Divider().padding(.leading, 66) }
                    }
                }
                .padding(.horizontal, 14)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private var yearContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button { moveYear(-1) } label: { Image(systemName: "chevron.left") }
                    .accessibilityLabel("Previous year")
                Spacer()
                Text(String(Calendar.current.component(.year, from: displayedMonth)))
                    .font(.title2.bold())
                Spacer()
                Button { moveYear(1) } label: { Image(systemName: "chevron.right") }
                    .accessibilityLabel("Next year")
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(1...12, id: \.self) { month in
                    Button {
                        let year = Calendar.current.component(.year, from: displayedMonth)
                        displayedMonth = Calendar.current.date(from: DateComponents(year: year, month: month, day: 1)) ?? displayedMonth
                        selectedDate = displayedMonth
                        showingYear = false
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(DateFormatter().monthSymbols[month - 1])
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text("\(birthdayCount(in: month)) birthdays")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var selectedBirthdays: [Person] {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: selectedDate)
        return people.filter { person in
            guard let birthday = BirthdayCalculator.birthday(in: year, month: person.birthdayMonth, day: person.birthdayDay) else { return false }
            return calendar.isDate(birthday, inSameDayAs: selectedDate)
        }.sorted { $0.fullName.localizedStandardCompare($1.fullName) == .orderedAscending }
    }

    private func birthdayCount(in month: Int) -> Int {
        let year = Calendar.current.component(.year, from: displayedMonth)
        return people.filter {
            guard let date = BirthdayCalculator.birthday(in: year, month: $0.birthdayMonth, day: $0.birthdayDay) else { return false }
            return Calendar.current.component(.month, from: date) == month
        }.count
    }

    private func moveMonth(_ amount: Int) {
        guard let next = Calendar.current.date(byAdding: .month, value: amount, to: displayedMonth) else { return }
        displayedMonth = next
        selectedDate = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: next)) ?? next
    }

    private func moveYear(_ amount: Int) {
        guard let next = Calendar.current.date(byAdding: .year, value: amount, to: displayedMonth) else { return }
        displayedMonth = next
    }
}
