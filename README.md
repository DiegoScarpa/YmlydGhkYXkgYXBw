# Remember

Remember is a local-first iPhone app for birthdays and the details that help you stay close to people. The project uses SwiftUI, SwiftData, and UserNotifications, and targets iOS 17 or later.

The installable Progressive Web App is in [`web/`](web/README.md). It runs without Xcode signing or an Apple Developer subscription. This README documents the original native app, which remains available alongside the PWA.

## Architecture

| Folder | Responsibility |
| --- | --- |
| `Remember/Models` | Versioned SwiftData `Person` and `ProfileExtras` records |
| `Remember/Services` | Birthday recurrence, reminder planning, local notifications, Contacts import, data export, communication URLs |
| `Remember/Components` | Reusable avatars, birthday rows, and calendar grid |
| `Remember/Views` | Four tabs, profile details, and the profile editor |
| `RememberTests` | Unit tests for birthdays and reminder planning |
| `RememberUITests` | iPhone interface test for adding Sarah, relaunching, and finding her on the calendar |

The dashboard, calendar, and reminder scheduler use the same `BirthdayCalculator`. A February 29 birthday is observed on February 28 in years without February 29. The app has one local SwiftData store and no server or account dependency.

## Build and run

1. Open `Remember.xcodeproj` in a current Xcode release with an iOS 17 or later simulator or iPhone runtime.
2. Choose the **Remember** scheme and an iPhone destination.
3. Build and run. Automatic signing may require selecting your Apple development team for a physical iPhone.
4. Add a person on Home or People. Enter a name and birthday; the other details are optional.
5. In Settings, enable birthday reminders and grant notification permission. Select offsets and a delivery time.
6. Optionally choose contacts in **Import from Contacts** or save a JSON copy with **Export All Data**.

For the core unit tests, run `swift test` on a Mac with Xcode installed. The shared Xcode scheme runs the interface test on an iPhone simulator. CI builds the app, runs both test suites, checks that a SwiftData profile survives migration and reopening, and captures a launch screenshot. `scripts/verify-core.swift` is a lightweight assertion harness for environments with Swift but no XCTest.

## Phase 1 behavior

- Native Home, Calendar, People, and Settings tabs.
- Local creation, editing, deletion, and persistence of profiles.
- Month and year calendar views, birthday indicators, date selection, and adding a person for a selected date.
- Upcoming birthdays, search, relationship filtering, and five sort orders.
- Phone, Messages, email, LinkedIn, Instagram, WhatsApp, and website links. Universal web links provide a browser fallback for social apps.
- Optional local notifications at 0, 1, 3, 7, 14, or 30 days before a birthday, at a chosen time. Permission is requested only when reminders are enabled.
- System, light, and dark appearance. VoiceOver labels are included for birthday dates and primary actions.

## Phase 2 behavior

- Optional profile photos through the system Photos picker. Photos are resized before local storage.
- More personal details, including restaurants, music, movies, likes, dislikes, and important details.
- Gift ideas, wishlist items, gift history, product links, budgets, and custom fields.
- Personal reminder schedules and an option to silence reminders for one person.
- Selected-contact import through Apple's Contacts picker. This does not request full address-book access. Contacts without birthdays are skipped, and repeat imports of the same contact are skipped.
- User-initiated JSON export of profiles, notes, gifts, custom fields, and photos.

## Current limits and next phase

iCloud sync, widgets, Siri integration, AI suggestions, and relationship follow-ups remain future work.

Reminder requests are regenerated on launch and after relevant edits. The planner keeps the nearest 60 pending requests to stay below iOS's pending notification limit. With many people or offsets, later reminders require opening the app again to replenish the queue. Notifications depend on iOS authorization and delivery behavior. The app stores data in its iOS sandbox; SwiftData does not itself provide end-to-end encryption or cross-device sync. The app does not request Contacts access or transmit profile data.

The SwiftData store has explicit V1 and V2 schemas and a lightweight V1-to-V2 migration. A future model change should add another schema version and migration stage when needed.
