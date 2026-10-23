import SwiftData
import SwiftUI

private struct PersonDraft {
    var fullName = ""
    var nickname = ""
    var month: Int
    var day: Int
    var hasBirthYear = false
    var birthYear = Calendar.current.component(.year, from: .now)
    var category: RelationshipCategory = .friend
    var location = ""
    var howWeMet = ""
    var hasDateWeMet = false
    var dateWeMet = Date.now
    var favoriteFoods = ""
    var interests = ""
    var personalNotes = ""
    var phoneNumber = ""
    var emailAddress = ""
    var linkedIn = ""
    var instagram = ""
    var whatsApp = ""
    var website = ""

    init(person: Person?, preselectedBirthday: Date?) {
        let date = preselectedBirthday ?? .now
        month = person?.birthdayMonth ?? Calendar.current.component(.month, from: date)
        day = person?.birthdayDay ?? Calendar.current.component(.day, from: date)
        guard let person else { return }
        fullName = person.fullName
        nickname = person.nickname
        hasBirthYear = person.birthYear != nil
        birthYear = person.birthYear ?? birthYear
        category = person.category
        location = person.location
        howWeMet = person.howWeMet
        hasDateWeMet = person.dateWeMet != nil
        dateWeMet = person.dateWeMet ?? .now
        favoriteFoods = person.favoriteFoods
        interests = person.interests
        personalNotes = person.personalNotes
        phoneNumber = person.phoneNumber
        emailAddress = person.emailAddress
        linkedIn = person.linkedIn
        instagram = person.instagram
        whatsApp = person.whatsApp
        website = person.website
    }

    func apply(to person: Person) {
        person.fullName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        person.nickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        person.birthdayMonth = month
        person.birthdayDay = day
        person.birthYear = hasBirthYear ? birthYear : nil
        person.category = category
        person.location = location
        person.howWeMet = howWeMet
        person.dateWeMet = hasDateWeMet ? dateWeMet : nil
        person.favoriteFoods = favoriteFoods
        person.interests = interests
        person.personalNotes = personalNotes
        person.phoneNumber = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        person.emailAddress = emailAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        person.linkedIn = linkedIn.trimmingCharacters(in: .whitespacesAndNewlines)
        person.instagram = instagram.trimmingCharacters(in: .whitespacesAndNewlines)
        person.whatsApp = whatsApp.trimmingCharacters(in: .whitespacesAndNewlines)
        person.website = website.trimmingCharacters(in: .whitespacesAndNewlines)
        person.updatedAt = .now
    }
}

struct PersonEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    private let person: Person?
    @State private var draft: PersonDraft
    @State private var errorMessage = ""
    @State private var showingError = false

    init(person: Person? = nil, preselectedBirthday: Date? = nil) {
        self.person = person
        _draft = State(initialValue: PersonDraft(person: person, preselectedBirthday: preselectedBirthday))
    }

    var body: some View {
        Form {
            Section("About") {
                TextField("Full name", text: $draft.fullName)
                    .textContentType(.name)
                    .accessibilityIdentifier("person.fullName")
                TextField("Nickname", text: $draft.nickname)
                Picker("Relationship", selection: $draft.category) {
                    ForEach(RelationshipCategory.allCases) { option in Text(option.rawValue).tag(option) }
                }
                TextField("Location", text: $draft.location)
                TextField("How we met", text: $draft.howWeMet)
                Toggle("Remember when we met", isOn: $draft.hasDateWeMet)
                if draft.hasDateWeMet {
                    DatePicker("Date we met", selection: $draft.dateWeMet, in: ...Date.now, displayedComponents: .date)
                }
            }

            Section {
                Picker("Month", selection: $draft.month) {
                    ForEach(1...12, id: \.self) { month in
                        Text(DateFormatter().monthSymbols[month - 1]).tag(month)
                    }
                }
                Picker("Day", selection: $draft.day) {
                    ForEach(1...31, id: \.self) { day in Text("\(day)").tag(day) }
                }
                Toggle("I know the birth year", isOn: $draft.hasBirthYear)
                if draft.hasBirthYear {
                    TextField("Birth year", value: $draft.birthYear, format: .number)
                        .keyboardType(.numberPad)
                }
            } header: {
                Text("Birthday")
            } footer: {
                Text("February 29 birthdays appear on February 28 in other years.")
            }

            Section("The little things") {
                TextField("Favorite foods", text: $draft.favoriteFoods, axis: .vertical)
                    .lineLimit(2...4)
                TextField("Interests and hobbies", text: $draft.interests, axis: .vertical)
                    .lineLimit(2...4)
                VStack(alignment: .leading) {
                    Text("Personal notes").font(.subheadline).foregroundStyle(.secondary)
                    TextEditor(text: $draft.personalNotes)
                        .frame(minHeight: 110)
                        .accessibilityIdentifier("person.notes")
                }
            }

            Section("Stay in touch") {
                TextField("Phone or iMessage", text: $draft.phoneNumber)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                TextField("Email", text: $draft.emailAddress)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                TextField("LinkedIn URL or username", text: $draft.linkedIn)
                    .textInputAutocapitalization(.never)
                TextField("Instagram URL or username", text: $draft.instagram)
                    .textInputAutocapitalization(.never)
                TextField("WhatsApp number", text: $draft.whatsApp)
                    .keyboardType(.phonePad)
                TextField("Website", text: $draft.website)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
            }
        }
        .navigationTitle(person == nil ? "Add Person" : "Edit Person")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save)
                    .fontWeight(.semibold)
                    .accessibilityIdentifier("person.save")
            }
        }
        .alert("Could Not Save", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private func save() {
        guard !draft.fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showError("Please enter a full name.")
            return
        }
        let birthday = BirthdayDate(
            month: draft.month,
            day: draft.day,
            year: draft.hasBirthYear ? draft.birthYear : nil
        )
        guard birthday.isValid, !draft.hasBirthYear || draft.birthYear <= Calendar.current.component(.year, from: .now) else {
            showError("Please enter a valid birthday and birth year.")
            return
        }
        do {
            let target = person ?? Person(fullName: draft.fullName, birthdayMonth: draft.month, birthdayDay: draft.day)
            draft.apply(to: target)
            if person == nil { modelContext.insert(target) }
            try modelContext.save()
            if let allPeople = try? modelContext.fetch(FetchDescriptor<Person>()) {
                Task { try? await NotificationCoordinator.shared.refresh(people: allPeople) }
            }
            dismiss()
        } catch {
            modelContext.rollback()
            showError(error.localizedDescription)
        }
    }

    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}
