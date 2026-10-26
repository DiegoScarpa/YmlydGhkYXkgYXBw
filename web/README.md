# Remember PWA

This is a separate, local-first browser implementation of Remember. The original SwiftUI project remains unchanged.

## Run

From the repository root run `python3 -m http.server 8080 --directory web` and open http://localhost:8080. IndexedDB requires a secure context for some features; localhost works for development.

## Free iPhone installation

Deploy the `web/` directory to a static HTTPS host (for example Cloudflare Pages or Netlify's free tier). In iPhone Safari, visit the URL, tap Share, then Add to Home Screen.

## Privacy and limitations

Profiles are stored only in this browser's IndexedDB. Back up with Settings > Export JSON. Clearing site data or deleting the installed app can erase them. Native SwiftData data is not transferred automatically; this PWA imports its own JSON format. Native Contacts picker and scheduled background birthday notifications are not available in this local-only version; upcoming reminders appear inside the app. iOS Web Push requires a separately implemented push service. No account, backend, or tracking is used.

## Manual smoke test

Add a person with a birthday, refresh, verify persistence, edit, search, check calendar marker, export, delete, import backup, and test offline after first successful load. Validate on a physical iPhone before production use.
