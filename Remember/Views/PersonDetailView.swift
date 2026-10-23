import SwiftData
import SwiftUI

struct PersonDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allExtras: [ProfileExtras]
    let person: Person
    @State private var showingEdit = false
    @State private var showingDelete = false
    @State private var errorMessage = ""
    @State private var showingError = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                profileHeader
                if hasCommunication { communicationCard }
                detailsCard
                if hasPersonalDetails {
                    personalCard
                }
                if let extras, !extras.giftItems.isEmpty || !extras.budgetPreference.isEmpty { giftsCard(extras) }
                if let extras, !extras.customFields.isEmpty { customFieldsCard(extras) }
                Button(role: .destructive) { showingDelete = true } label: {
                    Label("Delete Person", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.top, 8)
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(person.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit) {
            NavigationStack { PersonEditorView(person: person) }
        }
        .confirmationDialog("Delete \(person.fullName)?", isPresented: $showingDelete, titleVisibility: .visible) {
            Button("Delete Person", role: .destructive, action: delete)
        } message: {
            Text("Their birthday, notes, and links will be removed from this iPhone.")
        }
        .alert("Could Not Delete", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 13) {
            PersonAvatar(person: person, size: 88, photoData: extras?.photoData)
            VStack(spacing: 4) {
                Text(person.fullName).font(.title.bold())
                if !person.nickname.isEmpty {
                    Text("“\(person.nickname)”").foregroundStyle(.secondary)
                }
            }
            Text(person.category.rawValue)
                .font(.caption.weight(.semibold))
                .foregroundStyle(person.category.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(person.category.color.opacity(0.12), in: Capsule())
            if let nextBirthday = BirthdayCalculator.nextBirthday(
                month: person.birthdayMonth, day: person.birthdayDay, after: .now
            ) {
                HStack(spacing: 5) {
                    Image(systemName: "gift")
                    Text(nextBirthday.formatted(.dateTime.month(.wide).day()))
                    if let age = BirthdayCalculator.age(birthYear: person.birthYear, on: nextBirthday) {
                        Text("· Turning \(age)")
                    }
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
    }

    private var hasCommunication: Bool {
        ![person.phoneNumber, person.emailAddress, person.linkedIn, person.instagram, person.whatsApp, person.website]
            .allSatisfy(\.isEmpty)
    }

    private var extras: ProfileExtras? { allExtras.first { $0.personID == person.id } }

    private var hasPersonalDetails: Bool {
        !person.favoriteFoods.isEmpty || !person.interests.isEmpty || !person.personalNotes.isEmpty ||
        !(extras?.favoriteRestaurants ?? "").isEmpty || !(extras?.favoriteColors ?? "").isEmpty ||
        !(extras?.favoriteMusic ?? "").isEmpty || !(extras?.favoriteMovies ?? "").isEmpty ||
        !(extras?.thingsTheyLike ?? "").isEmpty || !(extras?.thingsTheyDislike ?? "").isEmpty ||
        !(extras?.importantDetails ?? "").isEmpty
    }

    private var communicationCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Reach out").font(.title3.bold()).padding(.bottom, 10)
            if let url = CommunicationLinks.phone(person.phoneNumber) {
                linkRow("Call", value: person.phoneNumber, icon: "phone", url: url)
            }
            if let url = CommunicationLinks.message(person.phoneNumber) {
                linkRow("Message", value: "iMessage or SMS", icon: "message", url: url)
            }
            if let url = CommunicationLinks.email(person.emailAddress) {
                linkRow("Email", value: person.emailAddress, icon: "envelope", url: url)
            }
            if let url = CommunicationLinks.linkedIn(person.linkedIn) {
                linkRow("LinkedIn", value: person.linkedIn, icon: "person.crop.square", url: url)
            }
            if let url = CommunicationLinks.instagram(person.instagram) {
                linkRow("Instagram", value: person.instagram, icon: "camera", url: url)
            }
            if let url = CommunicationLinks.whatsApp(person.whatsApp) {
                linkRow("WhatsApp", value: person.whatsApp, icon: "bubble.left", url: url)
            }
            if let url = CommunicationLinks.website(person.website) {
                linkRow("Website", value: person.website, icon: "globe", url: url)
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
    }

    private func linkRow(_ title: String, value: String, icon: String, url: URL) -> some View {
        Link(destination: url) {
            HStack(spacing: 12) {
                Image(systemName: icon).frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline.weight(.semibold))
                    Text(value).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer()
                Image(systemName: "arrow.up.right").font(.caption)
            }
            .padding(.vertical, 9)
            .contentShape(Rectangle())
        }
        .accessibilityLabel("\(title) \(person.fullName), \(value)")
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About").font(.title3.bold())
            if !person.location.isEmpty { detailRow("Location", value: person.location, icon: "mappin") }
            if !person.howWeMet.isEmpty { detailRow("How we met", value: person.howWeMet, icon: "person.2") }
            if let date = person.dateWeMet {
                detailRow("Date we met", value: date.formatted(date: .abbreviated, time: .omitted), icon: "calendar")
            }
            if person.location.isEmpty && person.howWeMet.isEmpty && person.dateWeMet == nil {
                Text("Add details about how you know \(person.fullName).")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
    }

    private func detailRow(_ title: String, value: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).frame(width: 24).foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.caption).foregroundStyle(.secondary)
                Text(value).font(.subheadline)
            }
        }
    }

    private var personalCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text("The little things").font(.title3.bold())
            if !person.favoriteFoods.isEmpty { detailRow("Favorite foods", value: person.favoriteFoods, icon: "fork.knife") }
            if let extras, !extras.favoriteRestaurants.isEmpty { detailRow("Favorite restaurants", value: extras.favoriteRestaurants, icon: "fork.knife.circle") }
            if let extras, !extras.favoriteColors.isEmpty { detailRow("Favorite colors", value: extras.favoriteColors, icon: "paintpalette") }
            if let extras, !extras.favoriteMusic.isEmpty { detailRow("Favorite music", value: extras.favoriteMusic, icon: "music.note") }
            if let extras, !extras.favoriteMovies.isEmpty { detailRow("Favorite movies", value: extras.favoriteMovies, icon: "film") }
            if !person.interests.isEmpty { detailRow("Interests", value: person.interests, icon: "sparkle") }
            if let extras, !extras.thingsTheyLike.isEmpty { detailRow("Likes", value: extras.thingsTheyLike, icon: "heart") }
            if let extras, !extras.thingsTheyDislike.isEmpty { detailRow("Dislikes", value: extras.thingsTheyDislike, icon: "hand.thumbsdown") }
            if let extras, !extras.importantDetails.isEmpty { detailRow("Important details", value: extras.importantDetails, icon: "star") }
            if !person.personalNotes.isEmpty { detailRow("Notes", value: person.personalNotes, icon: "text.alignleft") }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
    }

    private func giftsCard(_ extras: ProfileExtras) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            Text("Gifts").font(.title3.bold())
            if !extras.budgetPreference.isEmpty {
                detailRow("Budget preference", value: extras.budgetPreference, icon: "banknote")
            }
            ForEach(extras.giftItems) { gift in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(gift.title).font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(gift.kind.rawValue).font(.caption).foregroundStyle(.secondary)
                    }
                    if !gift.cost.isEmpty { Text(gift.cost).font(.caption).foregroundStyle(.secondary) }
                    if !gift.notes.isEmpty { Text(gift.notes).font(.subheadline) }
                    if let date = gift.dateGiven { Text("Given \(date.formatted(date: .abbreviated, time: .omitted))").font(.caption).foregroundStyle(.secondary) }
                    if let url = CommunicationLinks.website(gift.productURL) {
                        Link("View product", destination: url).font(.subheadline)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
    }

    private func customFieldsCard(_ extras: ProfileExtras) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            Text("More to remember").font(.title3.bold())
            ForEach(extras.customFields) { field in
                if let url = CommunicationLinks.website(field.value) {
                    Link(destination: url) {
                        detailRow(field.title, value: field.value, icon: "link")
                    }
                } else {
                    detailRow(field.title, value: field.value, icon: "square.text.square")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
    }

    private func delete() {
        do {
            if let extras { modelContext.delete(extras) }
            modelContext.delete(person)
            try modelContext.save()
            if let allPeople = try? modelContext.fetch(FetchDescriptor<Person>()) {
                let remainingExtras = (try? modelContext.fetch(FetchDescriptor<ProfileExtras>())) ?? []
                Task { try? await NotificationCoordinator.shared.refresh(people: allPeople, extras: remainingExtras) }
            }
            dismiss()
        } catch {
            modelContext.rollback()
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}
