import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct ProfileExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    private var data: Data

    init(people: [Person], extras: [ProfileExtras]) throws {
        let extrasByPerson = Dictionary(extras.map { ($0.personID, $0) }, uniquingKeysWith: { first, _ in first })
        let archive = ExportArchive(
            formatVersion: 1,
            exportedAt: .now,
            people: people.map { ExportPerson(person: $0, extras: extrasByPerson[$0.id]) }
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        data = try encoder.encode(archive)
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

private struct ExportArchive: Codable {
    let formatVersion: Int
    let exportedAt: Date
    let people: [ExportPerson]
}

private struct ExportPerson: Codable {
    let id: UUID
    let fullName: String
    let nickname: String
    let birthdayMonth: Int
    let birthdayDay: Int
    let birthYear: Int?
    let relationship: String
    let location: String
    let howWeMet: String
    let dateWeMet: Date?
    let favoriteFoods: String
    let interests: String
    let personalNotes: String
    let phoneNumber: String
    let emailAddress: String
    let linkedIn: String
    let instagram: String
    let whatsApp: String
    let website: String
    let createdAt: Date
    let updatedAt: Date
    let favoriteRestaurants: String
    let favoriteColors: String
    let favoriteMusic: String
    let favoriteMovies: String
    let thingsTheyLike: String
    let thingsTheyDislike: String
    let importantDetails: String
    let budgetPreference: String
    let gifts: [GiftEntry]
    let customFields: [CustomProfileField]
    let photoData: Data?
    let reminderOffsets: String
    let remindersDisabled: Bool

    init(person: Person, extras: ProfileExtras?) {
        id = person.id
        fullName = person.fullName
        nickname = person.nickname
        birthdayMonth = person.birthdayMonth
        birthdayDay = person.birthdayDay
        birthYear = person.birthYear
        relationship = person.categoryRaw
        location = person.location
        howWeMet = person.howWeMet
        dateWeMet = person.dateWeMet
        favoriteFoods = person.favoriteFoods
        interests = person.interests
        personalNotes = person.personalNotes
        phoneNumber = person.phoneNumber
        emailAddress = person.emailAddress
        linkedIn = person.linkedIn
        instagram = person.instagram
        whatsApp = person.whatsApp
        website = person.website
        createdAt = person.createdAt
        updatedAt = person.updatedAt
        favoriteRestaurants = extras?.favoriteRestaurants ?? ""
        favoriteColors = extras?.favoriteColors ?? ""
        favoriteMusic = extras?.favoriteMusic ?? ""
        favoriteMovies = extras?.favoriteMovies ?? ""
        thingsTheyLike = extras?.thingsTheyLike ?? ""
        thingsTheyDislike = extras?.thingsTheyDislike ?? ""
        importantDetails = extras?.importantDetails ?? ""
        budgetPreference = extras?.budgetPreference ?? ""
        gifts = extras?.giftItems ?? []
        customFields = extras?.customFields ?? []
        photoData = extras?.photoData
        reminderOffsets = extras?.reminderOffsetsRaw ?? ""
        remindersDisabled = extras?.remindersDisabled ?? false
    }
}
