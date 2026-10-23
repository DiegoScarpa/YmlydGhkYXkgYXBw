import SwiftData
import SwiftUI

enum AppTab: Hashable {
    case home, calendar, people, settings
}

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Person.fullName) private var people: [Person]
    @Query private var extras: [ProfileExtras]
    @AppStorage("appearance") private var appearance = "system"
    @State private var selection: AppTab = .home
    @State private var showingAddPerson = false

    var body: some View {
        TabView(selection: $selection) {
            HomeView(people: people, extras: extras, selection: $selection, onAdd: { showingAddPerson = true })
                .tabItem { Label("Home", systemImage: "house") }
                .tag(AppTab.home)
            BirthdayCalendarView(people: people, extras: extras)
                .tabItem { Label("Calendar", systemImage: "calendar") }
                .tag(AppTab.calendar)
            PeopleView(people: people, extras: extras, onAdd: { showingAddPerson = true })
                .tabItem { Label("People", systemImage: "person.2") }
                .tag(AppTab.people)
            SettingsView(people: people, extras: extras)
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(AppTab.settings)
        }
        .sheet(isPresented: $showingAddPerson) {
            NavigationStack { PersonEditorView() }
        }
        .task {
            try? await NotificationCoordinator.shared.refresh(people: people, extras: extras)
        }
        .preferredColorScheme(appearance == "dark" ? .dark : appearance == "light" ? .light : nil)
    }
}
