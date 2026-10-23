import SwiftUI
import UserNotifications
import SwiftData
import UniformTypeIdentifiers
import Contacts

struct SettingsView: View {
    let people: [Person]
    let extras: [ProfileExtras]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @AppStorage(ReminderPreferences.enabledKey) private var remindersEnabled = false
    @AppStorage(ReminderPreferences.offsetsKey) private var offsetsRaw = "0,7"
    @AppStorage(ReminderPreferences.hourKey) private var reminderHour = 9
    @AppStorage(ReminderPreferences.minuteKey) private var reminderMinute = 0
    @AppStorage("appearance") private var appearance = "system"
    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingAlert = false
    @State private var showingContactsPicker = false
    @State private var exportDocument: ProfileExportDocument?
    @State private var showingExporter = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Birthday reminders", isOn: $remindersEnabled)
                        .onChange(of: remindersEnabled) { _, enabled in
                            Task { await updateReminders(enabled: enabled) }
                        }
                    if remindersEnabled {
                        ForEach(ReminderPlanner.allowedOffsets, id: \.self) { offset in
                            Toggle(offsetLabel(offset), isOn: offsetBinding(offset))
                        }
                        DatePicker("Reminder time", selection: reminderTime, displayedComponents: .hourAndMinute)
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    Text(notificationFooter)
                }

                Section("Appearance") {
                    Picker("Theme", selection: $appearance) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                }

                Section {
                    Label("Profiles stay on this iPhone", systemImage: "iphone.gen3")
                    Label("No account or tracking", systemImage: "hand.raised")
                    Button {
                        showingContactsPicker = true
                    } label: {
                        Label("Import from Contacts", systemImage: "person.crop.circle.badge.plus")
                    }
                    Button {
                        prepareExport()
                    } label: {
                        Label("Export All Data", systemImage: "square.and.arrow.up")
                    }
                    .disabled(people.isEmpty)
                } header: {
                    Text("Privacy & Data")
                } footer: {
                    Text("Choose which contacts to import. Contacts without birthdays are skipped. Export creates a JSON file that may contain sensitive notes and photos.")
                }

                if authorizationStatus == .denied {
                    Section {
                        Button("Open iPhone Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .task {
                authorizationStatus = await NotificationCoordinator.shared.authorizationStatus()
            }
            .onChange(of: offsetsRaw) { _, _ in refreshReminders() }
            .onChange(of: reminderHour) { _, _ in refreshReminders() }
            .onChange(of: reminderMinute) { _, _ in refreshReminders() }
            .sheet(isPresented: $showingContactsPicker) {
                ContactsPicker { selected in
                    showingContactsPicker = false
                    importContacts(selected)
                }
            }
            .fileExporter(
                isPresented: $showingExporter,
                document: exportDocument,
                contentType: .json,
                defaultFilename: "Remember Export"
            ) { result in
                if case .failure(let error) = result { showAlert("Export Failed", error.localizedDescription) }
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private var notificationFooter: String {
        switch authorizationStatus {
        case .denied:
            "Notifications are blocked in iPhone Settings. Open Settings to allow reminders."
        case .authorized, .provisional, .ephemeral:
            "Reminders are scheduled on this device and refresh when you open Remember. iOS limits pending notifications."
        default:
            "You will be asked for notification permission when you turn reminders on."
        }
    }

    private func offsetLabel(_ offset: Int) -> String {
        switch offset {
        case 0: "On the birthday"
        case 1: "1 day before"
        default: "\(offset) days before"
        }
    }

    private func offsetBinding(_ offset: Int) -> Binding<Bool> {
        Binding(
            get: { selectedOffsets.contains(offset) },
            set: { enabled in
                var selected = selectedOffsets
                if enabled { selected.insert(offset) } else { selected.remove(offset) }
                offsetsRaw = selected.sorted().map(String.init).joined(separator: ",")
            }
        )
    }

    private var selectedOffsets: Set<Int> {
        Set(offsetsRaw.split(separator: ",").compactMap { Int($0) })
    }

    private var reminderTime: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(bySettingHour: reminderHour, minute: reminderMinute, second: 0, of: .now) ?? .now
            },
            set: { newTime in
                reminderHour = Calendar.current.component(.hour, from: newTime)
                reminderMinute = Calendar.current.component(.minute, from: newTime)
            }
        )
    }

    private func updateReminders(enabled: Bool) async {
        do {
            if enabled {
                let allowed = try await NotificationCoordinator.shared.requestAuthorization()
                authorizationStatus = await NotificationCoordinator.shared.authorizationStatus()
                if !allowed {
                    remindersEnabled = false
                    showAlert("Notifications Off", "Allow notifications in iPhone Settings to receive birthday reminders.")
                    return
                }
            }
            try await NotificationCoordinator.shared.refresh(people: people, extras: extras)
        } catch {
            showAlert("Notification Error", error.localizedDescription)
        }
    }

    private func refreshReminders() {
        Task {
            do { try await NotificationCoordinator.shared.refresh(people: people, extras: extras) }
            catch {
                showAlert("Notification Error", error.localizedDescription)
            }
        }
    }

    private func importContacts(_ selected: [CNContact]) {
        do {
            let report = try ContactsImporter.importSelected(selected, into: modelContext)
            showAlert("Contacts Imported", "Imported \(report.imported). Skipped \(report.skippedWithoutBirthday) without birthdays and \(report.skippedDuplicates) duplicates.")
            let allPeople = try modelContext.fetch(FetchDescriptor<Person>())
            let allExtras = try modelContext.fetch(FetchDescriptor<ProfileExtras>())
            Task { try? await NotificationCoordinator.shared.refresh(people: allPeople, extras: allExtras) }
        } catch {
            showAlert("Import Failed", error.localizedDescription)
        }
    }

    private func prepareExport() {
        do {
            exportDocument = try ProfileExportDocument(people: people, extras: extras)
            showingExporter = true
        } catch {
            showAlert("Export Failed", error.localizedDescription)
        }
    }

    private func showAlert(_ title: String, _ message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}
