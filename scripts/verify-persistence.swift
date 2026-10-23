import Foundation
import SwiftData

enum V1OnlyMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [RememberSchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}

@MainActor
@main
struct VerifyPersistence {
    static func main() throws {
        let url = URL(fileURLWithPath: CommandLine.arguments[1])
        let configuration = ModelConfiguration(url: url)
        let first = try ModelContainer(for: Person.self, migrationPlan: V1OnlyMigrationPlan.self, configurations: configuration)
        let firstContext = ModelContext(first)
        firstContext.insert(Person(fullName: "Sarah", birthdayMonth: 11, birthdayDay: 1, favoriteFoods: "Pasta", interests: "Hiking", personalNotes: "Call on Sundays", phoneNumber: "+15551234567", emailAddress: "sarah@example.com", linkedIn: "sarah"))
        try firstContext.save()

        let second = try ModelContainer(for: Person.self, ProfileExtras.self, migrationPlan: RememberMigrationPlan.self, configurations: configuration)
        let secondContext = ModelContext(second)
        let people = try secondContext.fetch(FetchDescriptor<Person>())
        precondition(people.count == 1)
        precondition(people[0].fullName == "Sarah")
        precondition(people[0].favoriteFoods == "Pasta")
        precondition(people[0].interests == "Hiking")
        precondition(people[0].personalNotes == "Call on Sundays")
        precondition(people[0].emailAddress == "sarah@example.com")
        let extras = ProfileExtras(personID: people[0].id)
        extras.favoriteColors = "Blue"
        secondContext.insert(extras)
        try secondContext.save()
        let third = try ModelContainer(for: Person.self, ProfileExtras.self, migrationPlan: RememberMigrationPlan.self, configurations: configuration)
        let thirdContext = ModelContext(third)
        let reopenedExtras = try thirdContext.fetch(FetchDescriptor<ProfileExtras>())
        precondition(reopenedExtras.first?.favoriteColors == "Blue")
        print("Persistence and V1-to-V2 migration verification passed")
    }
}
