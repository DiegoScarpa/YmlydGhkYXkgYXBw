# Remember for the web

Remember is an installable, local-first birthday and relationship manager. This `web/` directory is a Next.js, TypeScript, Tailwind CSS, and Dexie PWA. It does not need Xcode signing, TestFlight, the App Store, or an Apple Developer subscription. The original SwiftUI app remains in the repository's `Remember/` directory and can still be built with Xcode. See [MIGRATION.md](MIGRATION.md) for the native feature inventory and the migration plan.

## What works

- Home, Calendar, People, and Settings tabs with an iPhone-sized layout, safe-area spacing, light and dark appearances, and a prominent Add Person action.
- Yearly recurring birthdays, including the native app's February 29 → February 28 rule in non-leap years; month and year calendar views, date selection, and birthday countdowns.
- Profiles with photos, personal details, notes, gifts, custom fields, per-person reminder choices, and tappable phone, message, email, LinkedIn, Instagram, WhatsApp, and website links.
- Search, relationship filtering, five sorts, edit and delete, and persistent local IndexedDB records.
- In-app birthday reminders with global offsets and time settings, JSON backup and restore, an installable manifest, and an offline service worker.

No account, database server, or paid service is needed to use the app. Profile data and photos are stored in the current browser or installed web app, not in Vercel's database.

## Run locally

[Next.js 16 requires Node.js 20.9 or newer](https://nextjs.org/docs/app/getting-started/installation). From the repository root:

```bash
cd web
npm ci
npm run dev
```

Open <http://localhost:3000> on the same computer; 3000 is the default port. If it is already in use, run `npm run dev -- -p 4177` and open <http://localhost:4177> instead. The service worker registers only in a **production** build, so use the production commands below to check offline behavior. Local HTTP on a different device is not the intended iPhone installation path; deploy over HTTPS first.

## Build and verify

From `web/`:

```bash
npm run typecheck
npm run lint
npm test
npm run build
npm run start
```

`npm run start` serves the built app at <http://localhost:3000> by default. If that port is busy, use `npm run start -- -p 4177` and open <http://localhost:4177>. The production build includes `public/manifest.webmanifest`, app icons, `public/sw.js`, and an offline fallback. On a first visit, allow the app to finish loading while online before relying on offline access. The service worker caches the public app shell and visited pages/assets; external communication links still need a network connection or their destination app.

## Deploy free on Vercel

[Vercel Hobby](https://vercel.com/docs/plans/hobby) is free for eligible personal, non-commercial projects and has usage limits. It supplies HTTPS, which the installed PWA needs. No paid add-on or environment variable is required by this app.

1. Push this repository, including `web/`, to GitHub.
2. Sign in to [Vercel](https://vercel.com/) with a Hobby account. Select **Add New → Project** and import `DiegoScarpa/YmlydGhkYXkgYXBw`.
3. In the import settings, choose **Next.js** as the framework and set **Root Directory** to `web`. Vercel's [monorepo guide](https://vercel.com/docs/monorepos) describes this directory setting. Leave the detected npm install, build, and output settings at their defaults.
4. Select **Deploy**. When it succeeds, open the generated `https://…vercel.app` URL. The native Xcode project is not deployed.

To publish an update later, commit changes under `web/` and push them to the connected GitHub branch. Vercel will create a new deployment. Open or reload the installed app while online to fetch it. If its service worker detects an update, tap the **Update** prompt. Export a JSON backup before a major update as a normal precaution for locally stored data.

## Install on iPhone

1. Open the deployed HTTPS URL in **Safari** on the iPhone.
2. Open the page menu and **Share** (or tap Share directly, depending on Safari's tab layout).
3. Choose **Add to Home Screen**. If it is absent, scroll to **Edit Actions** and enable it.
4. If shown, keep **Open as Web App** on, then tap **Add**.
5. Open **Remember** from the Home Screen. Its manifest requests standalone display, so it opens without the normal Safari toolbar.

These are Apple's current [Add to Home Screen instructions](https://support.apple.com/guide/iphone/open-as-web-app-iphea86e5236/27/ios/27). If you plan to import existing data, open the **installed** Remember icon and import there. [WebKit states that Home Screen web app website data is isolated from Safari's website data](https://webkit.org/tracking-prevention/#home-screen-web-application-domain-exempt-from-itp); a profile entered in Safari may therefore not appear in the installed copy.

## Move data from the native iPhone app

SwiftData does **not** transfer into IndexedDB automatically.

1. In the SwiftUI app, open **Settings → Export All Data** and save the JSON file somewhere you can reach from Files on the iPhone.
2. Install and open the PWA from its Home Screen icon.
3. In the PWA, open **Settings → Your data → Import JSON backup**, select the native export, then tap **Import**.
4. Check several people, birthdays, photos, notes, and gifts in the PWA before changing or removing the native app.

The PWA accepts the native `formatVersion: 1` export and its own `formatVersion: 2` backup. It validates the complete file before writing any profiles. Import **merges by profile ID**: matching IDs are updated, other existing people remain, and repeat imports do not create duplicate IDs. Native global reminder settings and appearance are not in the native export, so set them again in the PWA. The native and web apps do not sync after import.

To save a PWA backup, use **Settings → Export JSON backup** and keep the downloaded file in a safe place outside the app. The web backup includes profiles, photos, gifts, custom fields, and PWA settings. Restoring a web backup also restores its settings. Importing a backup is a merge, not a replacement or reset; it will not delete profiles that are absent from the file. Backup files are unencrypted JSON containing private information, so store and share them carefully.

IndexedDB persistence lasts across ordinary closes and reopens, but it is not cloud backup. Clearing website data, removing the Home Screen app, changing devices, or device storage pressure can remove local data. Keep a recent JSON backup, especially before reinstalling or changing phones. The installed web app and Safari may each have their own local copy.

## Birthday reminders and permissions

The app calculates countdowns and displays reminders **when Remember is open**. Settings offers offsets of 0, 1, 3, 7, 14, and 30 days before a birthday and a preferred time. A person's profile can use its own offsets or silence its reminders. The PWA does not ask for notification permission because there is no push backend.

It does **not** send reliable birthday alerts while closed. A service worker cannot independently schedule future yearly notifications. Closed-app alerts would need user-granted [Web Push permission for an installed Home Screen web app](https://webkit.org/blog/13878/), a push subscription, and a server that schedules and sends each alert. Those parts are not configured here. The native SwiftUI app can use iOS local notifications and still offers a different reminder experience.

## Differences from the SwiftUI app

| Native feature | PWA behavior |
| --- | --- |
| SwiftData | Dexie/IndexedDB in the current browser or installed web app; migrate with JSON export/import |
| `UNUserNotificationCenter` local notifications | In-app reminders and countdowns while open; no closed-app alerts |
| Apple Contacts picker | Manual profile entry or native JSON import; no direct iPhone Contacts birthday picker |
| Photos picker | Web file picker and local image compression |
| iCloud sync, widgets, Siri, AI suggestions | Not implemented in either current app phase |

Phone, messaging, email, and social links hand off through browser-supported URLs. Their exact destination depends on installed apps and iOS link handling. Offline access applies to the app interface and local profiles; external sites and communication actions remain subject to network and device support.

## Verification status

At the time of migration, `npm run build`, `npm run typecheck`, and `npm run lint` passed; `npm test` passed 15 tests across four files. Desktop Chromium checks covered adding, editing, and deleting a profile; IndexedDB persistence after reload; month/year calendar navigation and date selection; search and relationship filtering; phone, message, email, and LinkedIn link targets; JSON backup export; and a 390 × 844 layout without horizontal overflow. A separate production-browser check confirmed the manifest, icons, controlling service worker, and an offline reload into the app. Browser-driven JSON import and photo upload remain unverified because Chrome CUA's file chooser timed out; unit tests cover backup import/export and native photo data. These are automated or desktop-browser checks, **not** a physical iPhone installation test. iPhone Safari Add to Home Screen, iPhone offline behavior, and real-device link handoff still need a device check. The commands above let you rerun the automated checks after changes.

## Code map

| Path | Purpose |
| --- | --- |
| `src/components/` | Four screens, profile editor/detail, shared UI, service worker registration |
| `src/lib/db.ts` | Dexie schema, validated profile and settings records |
| `src/lib/birthday.ts` | Recurrence, countdown, leap-day policy |
| `src/lib/reminders.ts` | In-app reminder planning |
| `src/lib/backup.ts` | Native/PWA JSON import and export |
| `src/lib/links.ts`, `photos.ts` | Communication URLs and profile photo compression |
| `public/` | Manifest, service worker, offline page, and icons |
| `src/lib/*.test.ts` | Calculation, persistence, link, reminder, and backup tests |
