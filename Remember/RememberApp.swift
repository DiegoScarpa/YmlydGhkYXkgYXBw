import SwiftData
import SwiftUI

@main
struct RememberApp: App {
    private let container: ModelContainer?
    private let storageError: String?

    init() {
        do {
            container = try ModelContainer(for: Person.self, migrationPlan: RememberMigrationPlan.self)
            storageError = nil
        } catch {
            container = nil
            storageError = error.localizedDescription
        }
    }

    var body: some Scene {
        WindowGroup {
            if let container {
                RootView()
                    .modelContainer(container)
                    .tint(Color(red: 0.36, green: 0.33, blue: 0.75))
            } else {
                ContentUnavailableView(
                    "Unable to Open Remember",
                    systemImage: "externaldrive.badge.exclamationmark",
                    description: Text(storageError ?? "The local database could not be opened.")
                )
            }
        }
    }
}
