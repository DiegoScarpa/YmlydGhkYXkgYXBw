import Foundation
import SwiftData

enum GiftKind: String, Codable, CaseIterable, Identifiable {
    case idea = "Idea"
    case wishlist = "Wishlist"
    case given = "Given"
    var id: String { rawValue }
}

struct GiftEntry: Codable, Identifiable, Hashable {
    var id = UUID()
    var title: String
    var kind: GiftKind
    var productURL = ""
    var cost = ""
    var notes = ""
    var dateGiven: Date?
}

struct CustomProfileField: Codable, Identifiable, Hashable {
    var id = UUID()
    var title: String
    var value: String
}

@Model
final class ProfileExtras {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var personID: UUID
    @Attribute(.externalStorage) var photoData: Data?
    var sourceContactIdentifier: String
    var favoriteRestaurants: String
    var favoriteColors: String
    var favoriteMusic: String
    var favoriteMovies: String
    var thingsTheyLike: String
    var thingsTheyDislike: String
    var importantDetails: String
    var budgetPreference: String
    var giftItemsData: Data
    var customFieldsData: Data
    var reminderOffsetsRaw: String
    var remindersDisabled: Bool

    init(personID: UUID) {
        id = UUID()
        self.personID = personID
        photoData = nil
        sourceContactIdentifier = ""
        favoriteRestaurants = ""
        favoriteColors = ""
        favoriteMusic = ""
        favoriteMovies = ""
        thingsTheyLike = ""
        thingsTheyDislike = ""
        importantDetails = ""
        budgetPreference = ""
        giftItemsData = Data()
        customFieldsData = Data()
        reminderOffsetsRaw = "" // Empty means use the global offsets.
        remindersDisabled = false
    }

    var giftItems: [GiftEntry] {
        get { (try? JSONDecoder().decode([GiftEntry].self, from: giftItemsData)) ?? [] }
        set { giftItemsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    var customFields: [CustomProfileField] {
        get { (try? JSONDecoder().decode([CustomProfileField].self, from: customFieldsData)) ?? [] }
        set { customFieldsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }
}
