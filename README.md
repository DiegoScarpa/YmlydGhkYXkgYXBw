# Remember

Remember is a local-first iPhone app for birthdays and the details that help you stay close to people. The project uses SwiftUI, SwiftData, and UserNotifications, and targets iOS 17 or later.

## Architecture

| Folder | Responsibility |
| --- | --- |
| `Remember/Models` | SwiftData `Person` and relationship categories |
| `Remember/Services` | Birthday recurrence, reminder planning, local notification scheduling, communication URLs |
| `Remember/Components` | Reusable avatars, birthday rows, and calendar grid |
| `Remember/Views` | Four tabs, profile details, and the profile editor |
| `RememberTests` | Unit tests for birthdays and reminder planning |

The dashboard, calendar, and reminder scheduler use the same `BirthdayCalculator`. A February 29 birthday is observed on February 28 in years without February 29. The app has one local SwiftData store and no server or account dependency.

## Build and run

1. Open `Remember.xcodeproj` in a current Xcode release with an iOS 17 or later simulator or iPhone runtime.
2. Choose the **Remember** scheme and an iPhone destination.
3. Build and run. Automatic signing may require selecting your Apple development team for a physical iPhone.
4. Add a person on Home or People. Enter a name and birthday; the other details are optional.
5. In Settings, enable birthday reminders and grant notification permission. Select offsets and a delivery time.

For the core unit tests, run `swift test` on a Mac with Xcode installed. The CI workflow builds the simulator app and runs those tests. `scripts/verify-core.swift` is a lightweight assertion harness for environments with Swift but no XCTest.

## Phase 1 behavior

- Native Home, Calendar, People, and Settings tabs.
- Local creation, editing, deletion, and persistence of profiles.
- Month and year calendar views, birthday indicators, date selection, and adding a person for a selected date.
- Upcoming birthdays, search, relationship filtering, and five sort orders.
- Phone, Messages, email, LinkedIn, Instagram, WhatsApp, and website links. Universal web links provide a browser fallback for social apps.
- Optional local notifications at 0, 1, 3, 7, 14, or 30 days before a birthday, at a chosen time. Permission is requested only when reminders are enabled.
- System, light, and dark appearance. VoiceOver labels are included for birthday dates and primary actions.

## Current limits and next phase

This is the Phase 1 scope. Profile photos, Contacts import, gift management, custom fields, and data export are not implemented yet. iCloud sync, widgets, Siri integration, AI suggestions, and relationship follow-ups remain future work.

Reminder requests are regenerated on launch and after relevant edits. The planner keeps the nearest 60 pending requests to stay below iOS's pending notification limit. With many people or offsets, later reminders require opening the app again to replenish the queue. Notifications depend on iOS authorization and delivery behavior. The app stores data in its iOS sandbox; SwiftData does not itself provide end-to-end encryption or cross-device sync. The app does not request Contacts access or transmit profile data.

The SwiftData store starts with `RememberSchemaV1` and an explicit migration plan. A future model change should add a new schema version and migration stage when needed.
