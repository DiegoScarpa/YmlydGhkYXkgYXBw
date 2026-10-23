import SwiftData
import SwiftUI
import PhotosUI
import UIKit

private struct ExtrasDraft {
    var photoData: Data?
    var favoriteRestaurants = ""
    var favoriteColors = ""
    var favoriteMusic = ""
    var favoriteMovies = ""
    var thingsTheyLike = ""
    var thingsTheyDislike = ""
    var importantDetails = ""
    var budgetPreference = ""
    var gifts: [GiftEntry] = []
    var customFields: [CustomProfileField] = []
    var reminderOffsetsRaw = ""
    var remindersDisabled = false

    init(extras: ProfileExtras?) {
        guard let extras else { return }
        photoData = extras.photoData
        favoriteRestaurants = extras.favoriteRestaurants
        favoriteColors = extras.favoriteColors
        favoriteMusic = extras.favoriteMusic
        favoriteMovies = extras.favoriteMovies
        thingsTheyLike = extras.thingsTheyLike
        thingsTheyDislike = extras.thingsTheyDislike
        importantDetails = extras.importantDetails
        budgetPreference = extras.budgetPreference
        gifts = extras.giftItems
        customFields = extras.customFields
        reminderOffsetsRaw = extras.reminderOffsetsRaw
        remindersDisabled = extras.remindersDisabled
    }

    func apply(to extras: ProfileExtras) {
        extras.photoData = photoData
        extras.favoriteRestaurants = favoriteRestaurants
        extras.favoriteColors = favoriteColors
        extras.favoriteMusic = favoriteMusic
        extras.favoriteMovies = favoriteMovies
        extras.thingsTheyLike = thingsTheyLike
        extras.thingsTheyDislike = thingsTheyDislike
        extras.importantDetails = importantDetails
        extras.budgetPreference = budgetPreference
        extras.giftItems = gifts
        extras.customFields = customFields
        extras.reminderOffsetsRaw = reminderOffsetsRaw
        extras.remindersDisabled = remindersDisabled
    }
}

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
    @State private var extrasDraft = ExtrasDraft(extras: nil)
    @State private var loadedExtras = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isLoadingPhoto = false
    @State private var editingGift: GiftEntry?
    @State private var editingField: CustomProfileField?
    @State private var errorMessage = ""
    @State private var showingError = false

    init(person: Person? = nil, preselectedBirthday: Date? = nil) {
        self.person = person
        _draft = State(initialValue: PersonDraft(person: person, preselectedBirthday: preselectedBirthday))
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        if let data = extrasDraft.photoData, let image = UIImage(data: data) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .frame(width: 100, height: 100)
                                .foregroundStyle(.secondary)
                        }
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Text(extrasDraft.photoData == nil ? "Choose Photo" : "Change Photo")
                        }
                        if extrasDraft.photoData != nil {
                            Button("Remove Photo", role: .destructive) { extrasDraft.photoData = nil }
                                .font(.caption)
                        }
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
            }

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
                TextField("Favorite restaurants", text: $extrasDraft.favoriteRestaurants, axis: .vertical)
                    .lineLimit(2...4)
                TextField("Favorite colors", text: $extrasDraft.favoriteColors)
                TextField("Favorite music", text: $extrasDraft.favoriteMusic, axis: .vertical)
                    .lineLimit(2...4)
                TextField("Favorite movies", text: $extrasDraft.favoriteMovies, axis: .vertical)
                    .lineLimit(2...4)
                TextField("Interests and hobbies", text: $draft.interests, axis: .vertical)
                    .lineLimit(2...4)
                TextField("Things they like", text: $extrasDraft.thingsTheyLike, axis: .vertical)
                    .lineLimit(2...4)
                TextField("Things they dislike", text: $extrasDraft.thingsTheyDislike, axis: .vertical)
                    .lineLimit(2...4)
                TextField("Important details", text: $extrasDraft.importantDetails, axis: .vertical)
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

            Section("Gifts") {
                TextField("Budget preference", text: $extrasDraft.budgetPreference)
                ForEach(extrasDraft.gifts) { gift in
                    Button {
                        editingGift = gift
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(gift.title).foregroundStyle(.primary)
                            Text(gift.kind.rawValue).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { extrasDraft.gifts.remove(atOffsets: $0) }
                Button { editingGift = GiftEntry(title: "", kind: .idea) } label: {
                    Label("Add Gift", systemImage: "plus")
                }
            }

            Section("Custom fields") {
                ForEach(extrasDraft.customFields) { field in
                    Button {
                        editingField = field
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(field.title).foregroundStyle(.primary)
                            Text(field.value).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { extrasDraft.customFields.remove(atOffsets: $0) }
                Button { editingField = CustomProfileField(title: "", value: "") } label: {
                    Label("Add Field", systemImage: "plus")
                }
            }

            Section("Personal reminders") {
                Toggle("Turn off for this person", isOn: $extrasDraft.remindersDisabled)
                if !extrasDraft.remindersDisabled {
                    Picker("Reminder schedule", selection: $extrasDraft.reminderOffsetsRaw) {
                        Text("Use global settings").tag("")
                        Text("On birthday only").tag("0")
                        Text("1 day and birthday").tag("0,1")
                        Text("7 days and birthday").tag("0,7")
                        Text("30, 7 and birthday").tag("0,7,30")
                    }
                }
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
                    .disabled(isLoadingPhoto)
            }
        }
        .onAppear(perform: loadExtras)
        .onChange(of: selectedPhoto) { _, item in
            guard let item else { return }
            Task { await loadPhoto(item) }
        }
        .sheet(item: $editingGift) { gift in
            NavigationStack {
                GiftEntryEditorView(gift: gift) { updated in
                    if let index = extrasDraft.gifts.firstIndex(where: { $0.id == updated.id }) {
                        extrasDraft.gifts[index] = updated
                    } else {
                        extrasDraft.gifts.append(updated)
                    }
                }
            }
        }
        .sheet(item: $editingField) { field in
            NavigationStack {
                CustomFieldEditorView(field: field) { updated in
                    if let index = extrasDraft.customFields.firstIndex(where: { $0.id == updated.id }) {
                        extrasDraft.customFields[index] = updated
                    } else {
                        extrasDraft.customFields.append(updated)
                    }
                }
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
            let existing = try modelContext.fetch(FetchDescriptor<ProfileExtras>()).first { $0.personID == target.id }
            let extras = existing ?? ProfileExtras(personID: target.id)
            extrasDraft.apply(to: extras)
            if existing == nil { modelContext.insert(extras) }
            try modelContext.save()
            if let allPeople = try? modelContext.fetch(FetchDescriptor<Person>()) {
                let allExtras = (try? modelContext.fetch(FetchDescriptor<ProfileExtras>())) ?? []
                Task { try? await NotificationCoordinator.shared.refresh(people: allPeople, extras: allExtras) }
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

    private func loadExtras() {
        guard !loadedExtras, let person else { return }
        let allExtras = (try? modelContext.fetch(FetchDescriptor<ProfileExtras>())) ?? []
        extrasDraft = ExtrasDraft(extras: allExtras.first { $0.personID == person.id })
        loadedExtras = true
    }

    private func loadPhoto(_ item: PhotosPickerItem) async {
        isLoadingPhoto = true
        defer { isLoadingPhoto = false }
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                showError("This photo could not be opened.")
                return
            }
            let scale = min(1, 512 / max(image.size.width, image.size.height))
            let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            let renderer = UIGraphicsImageRenderer(size: size)
            extrasDraft.photoData = renderer.jpegData(withCompressionQuality: 0.82) { _ in
                image.draw(in: CGRect(origin: .zero, size: size))
            }
        } catch {
            showError(error.localizedDescription)
        }
    }
}

private struct GiftEntryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var gift: GiftEntry
    @State private var hasDate: Bool
    @State private var errorMessage = ""
    @State private var showingError = false
    let onSave: (GiftEntry) -> Void

    init(gift: GiftEntry, onSave: @escaping (GiftEntry) -> Void) {
        _gift = State(initialValue: gift)
        _hasDate = State(initialValue: gift.dateGiven != nil)
        self.onSave = onSave
    }

    var body: some View {
        Form {
            TextField("Gift", text: $gift.title)
            Picker("Type", selection: $gift.kind) {
                ForEach(GiftKind.allCases) { kind in Text(kind.rawValue).tag(kind) }
            }
            TextField("Product link (optional)", text: $gift.productURL)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
            TextField("Cost or budget (optional)", text: $gift.cost)
            TextField("Notes", text: $gift.notes, axis: .vertical).lineLimit(2...4)
            if gift.kind == .given {
                Toggle("Add date given", isOn: $hasDate)
                if hasDate {
                    DatePicker("Date given", selection: Binding(
                        get: { gift.dateGiven ?? .now },
                        set: { gift.dateGiven = $0 }
                    ), displayedComponents: .date)
                }
            }
        }
        .navigationTitle("Gift")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
        }
        .alert("Check Gift", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: { Text(errorMessage) }
    }

    private func save() {
        gift.title = gift.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !gift.title.isEmpty else {
            errorMessage = "Enter a name for the gift."
            showingError = true
            return
        }
        if !gift.productURL.isEmpty && CommunicationLinks.website(gift.productURL) == nil {
            errorMessage = "Enter a valid product link."
            showingError = true
            return
        }
        if gift.kind != .given || !hasDate { gift.dateGiven = nil }
        onSave(gift)
        dismiss()
    }
}

private struct CustomFieldEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var field: CustomProfileField
    @State private var showingError = false
    let onSave: (CustomProfileField) -> Void

    init(field: CustomProfileField, onSave: @escaping (CustomProfileField) -> Void) {
        _field = State(initialValue: field)
        self.onSave = onSave
    }

    var body: some View {
        Form {
            TextField("Field name", text: $field.title)
            TextField("Value", text: $field.value, axis: .vertical).lineLimit(2...5)
        }
        .navigationTitle("Custom Field")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    field.title = field.title.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !field.title.isEmpty else { showingError = true; return }
                    onSave(field)
                    dismiss()
                }
            }
        }
        .alert("Enter a field name", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        }
    }
}
