# Remember: native-to-web migration plan

## Existing app inventory

The native `Remember/` project remains the source of truth for the original iPhone app. `RootView.swift` has Home, Calendar, People, and Settings tabs. Home shows today, three upcoming birthday groups, and a month preview. Calendar has month and year views, swipe and arrow navigation, birthday dots, selected-day details, and add-on-date. People has search, a relationship filter, and five sorts. Profile details and editing include contact links, personal facts, notes, photos, gifts, custom fields, and per-person reminder controls. Settings has global reminder offsets and time, appearance, selected Contacts import, and JSON export.

`Person` and `ProfileExtras` are versioned SwiftData records. The extra record stores a photo and JSON-encoded gifts/custom fields. Reminder preferences and appearance are in UserDefaults. `BirthdayCalculator` observes February 29 on February 28 in non-leap years. `NotificationCoordinator` schedules up to 60 local iOS notifications. Native export is `formatVersion: 1` JSON, with flat people, ISO dates, and base64 photos.

The UI uses a pale system grouped background, white rounded cards, a muted purple accent, system typography, colored relationship dots, a large Home title, and a four-item bottom tab bar.

## Web architecture

| Native | PWA replacement |
| --- | --- |
| SwiftUI views and navigation | Next.js App Router, React client views, Tailwind CSS, same four tabs and card hierarchy |
| SwiftData `Person` + `ProfileExtras` | One validated `PersonProfile` record per person in Dexie/IndexedDB; schema versioned for future upgrades |
| `BirthdayCalculator` | Pure local-date TypeScript calculations, with the same February 29 policy |
| UserDefaults settings | Dexie settings record, including appearance, global offsets, and reminder time |
| PhotosPicker | Browser image picker, resized JPEG stored locally in IndexedDB |
| Native JSON export | Web JSON backup; importer accepts native `formatVersion: 1` and web backup |
| `UNUserNotificationCenter` | Accurate in-app reminders and countdowns; no claim of closed-app alerts |
| `CNContactPickerViewController` | Manual entry and native JSON migration; direct iPhone Contacts birthday import is unavailable to this web app |

## Migration and limits

The native Settings → Export All Data file can be restored through the PWA Settings screen. Import validates every profile before any IndexedDB write and merges by stable UUID, avoiding duplicate people on repeated imports. Photos from the native file are decoded from base64. The two stores never synchronize automatically.

The PWA is installable from Safari on HTTPS and works offline after its first successful load. Safari/OS storage cleanup, removing the web app, or switching devices can remove local data; users should save a JSON backup. The PWA has no server or account. Reliable notifications when closed would require a user-granted Web Push subscription plus a server that schedules and delivers pushes. The offline PWA only displays reminders when opened.

## Verification plan

Run the production build and type check; test birthday recurrence, validation, import/export, and profile CRUD. Use browser automation to exercise add/edit/delete, reload persistence, calendar navigation, links, manifest, service worker, offline loading, and mobile layout where possible. State separately whether installation on a physical iPhone has been tested.
