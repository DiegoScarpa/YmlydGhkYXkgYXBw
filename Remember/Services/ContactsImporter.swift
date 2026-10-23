import Contacts
import SwiftData

struct ContactsImportReport {
    var imported = 0
    var skippedWithoutBirthday = 0
    var skippedDuplicates = 0
}

@MainActor
enum ContactsImporter {
    static func importSelected(_ contacts: [CNContact], into context: ModelContext) throws -> ContactsImportReport {
        var report = ContactsImportReport()
        let existingExtras = try context.fetch(FetchDescriptor<ProfileExtras>())
        var importedIDs = Set(existingExtras.map(\.sourceContactIdentifier))

        for contact in contacts {
            if importedIDs.contains(contact.identifier) {
                report.skippedDuplicates += 1
                continue
            }
            guard contact.isKeyAvailable(CNContactBirthdayKey),
                  let components = contact.birthday,
                  let month = components.month,
                  let day = components.day,
                  BirthdayDate(month: month, day: day, year: components.year).isValid else {
                report.skippedWithoutBirthday += 1
                continue
            }
            let name = (CNContactFormatter.string(from: contact, style: .fullName) ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else {
                report.skippedWithoutBirthday += 1
                continue
            }
            let person = Person(
                fullName: name,
                nickname: contact.isKeyAvailable(CNContactNicknameKey) ? contact.nickname : "",
                birthdayMonth: month,
                birthdayDay: day,
                birthYear: components.year,
                phoneNumber: contact.isKeyAvailable(CNContactPhoneNumbersKey) ? contact.phoneNumbers.first?.value.stringValue ?? "" : "",
                emailAddress: contact.isKeyAvailable(CNContactEmailAddressesKey) ? contact.emailAddresses.first.map { String($0.value) } ?? "" : ""
            )
            let extras = ProfileExtras(personID: person.id)
            extras.sourceContactIdentifier = contact.identifier
            if contact.isKeyAvailable(CNContactThumbnailImageDataKey) {
                extras.photoData = contact.thumbnailImageData
            } else if contact.isKeyAvailable(CNContactImageDataKey) {
                extras.photoData = contact.imageData
            }
            context.insert(person)
            context.insert(extras)
            importedIDs.insert(contact.identifier)
            report.imported += 1
        }

        do { try context.save() }
        catch { context.rollback(); throw error }
        return report
    }
}
