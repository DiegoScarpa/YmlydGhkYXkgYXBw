import SwiftData
import SwiftUI

enum AppTab: Hashable {
    case home, calendar, people, settings
}

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Person.fullName) private var people: [Person]
    @AppStorage("appearance") private var appearance = "system"
    @State private var selection: AppTab = .home
    @State private var showingAddPerson = false

    var body: some View {
        TabView(selection: $selection) {
            HomeView(people: people, selection: $selection, onAdd: { showingAddPerson = true })
                .tabItem { Label("Home", systemImage: "house") }
                .tag(AppTab.home)
            BirthdayCalendarView(people: people)
                .tabItem { Label("Calendar", systemImage: "calendar") }
                .tag(AppTab.calendar)
            PeopleView(people: people, onAdd: { showingAddPerson = true })
                .tabItem { Label("People", systemImage: "person.2") }
                .tag(AppTab.people)
            SettingsView(people: people)
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(AppTab.settings)
        }
        .sheet(isPresented: $showingAddPerson) {
            NavigationStack { PersonEditorView() }
        }
        .task {
            try? await NotificationCoordinator.shared.refresh(people: people)
        }
        .preferredColorScheme(appearance == "dark" ? .dark : appearance == "light" ? .light : nil)
    }
}
