import Foundation
import SwiftData
import SwiftUI

enum RelationshipCategory: String, CaseIterable, Identifiable {
    case friend = "Friend"
    case family = "Family"
    case coworker = "Coworker"
    case professional = "Professional"
    case partner = "Partner"
    case other = "Other"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .friend: .blue
        case .family: .orange
        case .coworker: .teal
        case .professional: .indigo
        case .partner: .pink
        case .other: .gray
        }
    }
}

@Model
final class Person {
    @Attribute(.unique) var id: UUID
    var fullName: String
    var nickname: String
    var birthdayMonth: Int
    var birthdayDay: Int
    var birthYear: Int?
    var categoryRaw: String
    var location: String
    var howWeMet: String
    var dateWeMet: Date?
    var favoriteFoods: String
    var interests: String
    var personalNotes: String
    var phoneNumber: String
    var emailAddress: String
    var linkedIn: String
    var instagram: String
    var whatsApp: String
    var website: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        fullName: String,
        nickname: String = "",
        birthdayMonth: Int,
        birthdayDay: Int,
        birthYear: Int? = nil,
        category: RelationshipCategory = .friend,
        location: String = "",
        howWeMet: String = "",
        dateWeMet: Date? = nil,
        favoriteFoods: String = "",
        interests: String = "",
        personalNotes: String = "",
        phoneNumber: String = "",
        emailAddress: String = "",
        linkedIn: String = "",
        instagram: String = "",
        whatsApp: String = "",
        website: String = ""
    ) {
        self.id = id
        self.fullName = fullName
        self.nickname = nickname
        self.birthdayMonth = birthdayMonth
        self.birthdayDay = birthdayDay
        self.birthYear = birthYear
        self.categoryRaw = category.rawValue
        self.location = location
        self.howWeMet = howWeMet
        self.dateWeMet = dateWeMet
        self.favoriteFoods = favoriteFoods
        self.interests = interests
        self.personalNotes = personalNotes
        self.phoneNumber = phoneNumber
        self.emailAddress = emailAddress
        self.linkedIn = linkedIn
        self.instagram = instagram
        self.whatsApp = whatsApp
        self.website = website
        self.createdAt = .now
        self.updatedAt = .now
    }

    var category: RelationshipCategory {
        get { RelationshipCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var initials: String {
        let parts = fullName.split(separator: " ")
        return String(parts.prefix(2).compactMap(\.first)).uppercased()
    }

    var searchText: String {
        [fullName, nickname, categoryRaw, favoriteFoods, interests, personalNotes]
            .joined(separator: " ")
    }
}

enum RememberSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(1, 0, 0) }
    static var models: [any PersistentModel.Type] { [Person.self] }
}

enum RememberMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [RememberSchemaV1.self, RememberSchemaV2.self] }
    static var stages: [MigrationStage] {
        [.lightweight(fromVersion: RememberSchemaV1.self, toVersion: RememberSchemaV2.self)]
    }
}

enum RememberSchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(2, 0, 0) }
    static var models: [any PersistentModel.Type] { [Person.self, ProfileExtras.self] }
}
