import SwiftUI
import UserNotifications

struct SettingsView: View {
    let people: [Person]
    @Environment(\.openURL) private var openURL
    @AppStorage(ReminderPreferences.enabledKey) private var remindersEnabled = false
    @AppStorage(ReminderPreferences.offsetsKey) private var offsetsRaw = "0,7"
    @AppStorage(ReminderPreferences.hourKey) private var reminderHour = 9
    @AppStorage(ReminderPreferences.minuteKey) private var reminderMinute = 0
    @AppStorage("appearance") private var appearance = "system"
    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var errorMessage = ""
    @State private var showingError = false

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

                Section("Privacy & Data") {
                    Label("Profiles stay on this iPhone", systemImage: "iphone.gen3")
                    Label("No account or tracking", systemImage: "hand.raised")
                    Text("Contacts import and data export are planned for Phase 2.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
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
            .alert("Notification Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
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
                    errorMessage = "Allow notifications in iPhone Settings to receive birthday reminders."
                    showingError = true
                    return
                }
            }
            try await NotificationCoordinator.shared.refresh(people: people)
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    private func refreshReminders() {
        Task {
            do { try await NotificationCoordinator.shared.refresh(people: people) }
            catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}
