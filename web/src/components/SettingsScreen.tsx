"use client";

import { useRef, useState } from "react";
import { Bell, Download, HardDrive, Moon, Share2, ShieldCheck, Upload } from "lucide-react";
import type { AppSettings } from "@/lib/db";
import { ALLOWED_REMINDER_OFFSETS, setReminderOffset } from "@/lib/db";
import { exportBackup, importBackup } from "@/lib/backup";

const offsetLabel = (offset: number) => offset === 0 ? "On the birthday" : `${offset} ${offset === 1 ? "day" : "days"} before`;

export default function SettingsScreen({ settings, onSettingsSaved }: {
  settings: AppSettings;
  onSettingsSaved: (change: Partial<AppSettings>) => Promise<void>;
}) {
  const fileInput = useRef<HTMLInputElement>(null);
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");

  async function update(change: Partial<AppSettings>) {
    setError(""); setMessage("");
    try { await onSettingsSaved(change); }
    catch (reason) { setError(reason instanceof Error ? reason.message : "Could not save settings."); }
  }

  async function changeOffset(offset: number, enabled: boolean) {
    setError(""); setMessage("");
    try { await setReminderOffset(offset, enabled); }
    catch (reason) { setError(reason instanceof Error ? reason.message : "Could not save reminders."); }
  }

  async function downloadBackup() {
    if (busy) return;
    setBusy(true); setError(""); setMessage("");
    try {
      const contents = await exportBackup();
      const url = URL.createObjectURL(new Blob([contents], { type: "application/json" }));
      const anchor = document.createElement("a");
      anchor.href = url;
      anchor.download = `remember-backup-${new Date().toISOString().slice(0, 10)}.json`;
      document.body.append(anchor);
      anchor.click();
      anchor.remove();
      window.setTimeout(() => URL.revokeObjectURL(url), 60_000);
      setMessage("Backup created. Save the JSON file somewhere you can find it later.");
    } catch (reason) { setError(reason instanceof Error ? reason.message : "Could not create a backup."); }
    finally { setBusy(false); }
  }

  async function restoreBackup() {
    if (!selectedFile || busy) return;
    setBusy(true); setError(""); setMessage("");
    try {
      const count = await importBackup(selectedFile);
      setMessage(`Imported ${count} ${count === 1 ? "person" : "people"}. Matching profile IDs were updated; other people were kept.`);
      setSelectedFile(null);
      if (fileInput.current) fileInput.current.value = "";
    } catch (reason) { setError(reason instanceof Error ? reason.message : "Could not import this backup."); }
    finally { setBusy(false); }
  }

  return <main className="app-shell">
    <header className="mb-8"><h1 className="screen-title">Settings</h1><p className="muted text-sm mt-3">Make Remember work your way.</p></header>
    {(message || error) && <div className={`card card-pad mb-5 text-sm ${error ? "text-red-600" : "accent"}`} role={error ? "alert" : "status"}>{error || message}</div>}

    <section className="mb-7">
      <h2 className="section-title flex items-center gap-2 mb-3"><Bell size={20} className="accent" /> Birthday reminders</h2>
      <div className="card card-pad field-stack">
        <label className="flex items-center justify-between gap-4 min-h-11 text-sm font-semibold">
          Show reminders in app
          <input type="checkbox" checked={settings.remindersEnabled} onChange={(event) => update({ remindersEnabled: event.target.checked })} aria-label="Show reminders in app" />
        </label>
        {settings.remindersEnabled && <>
          <div><p className="field-label">When to remind me</p><div className="grid grid-cols-2 gap-1">
            {ALLOWED_REMINDER_OFFSETS.map((offset) => <label key={offset} className="flex items-center gap-2 min-h-11 text-sm">
              <input type="checkbox" checked={settings.reminderOffsets.includes(offset)} onChange={(event) => changeOffset(offset, event.target.checked)} /> {offsetLabel(offset)}
            </label>)}
          </div></div>
          <label><span className="field-label">Reminder time</span><input className="input" type="time" value={`${String(settings.reminderHour).padStart(2, "0")}:${String(settings.reminderMinute).padStart(2, "0")}`}
            onChange={(event) => { const [hour, minute] = event.target.value.split(":").map(Number); if (Number.isInteger(hour) && Number.isInteger(minute)) update({ reminderHour: hour, reminderMinute: minute }); }} /></label>
        </>}
        <p className="muted text-sm leading-relaxed">Reminders appear when you open Remember. This version does not ask for notification permission because it has no push server. Alerts while closed would require Web Push permission, a subscription, and scheduled server delivery.</p>
      </div>
    </section>

    <section className="mb-7"><h2 className="section-title flex items-center gap-2 mb-3"><Moon size={20} className="accent" /> Appearance</h2>
      <div className="card card-pad"><div className="grid grid-cols-3 gap-2" role="group" aria-label="Appearance">
        {(["system", "light", "dark"] as const).map((appearance) => <button key={appearance} className={settings.appearance === appearance ? "primary-button" : "secondary-button"}
          aria-pressed={settings.appearance === appearance} onClick={() => update({ appearance })}>{appearance[0].toUpperCase() + appearance.slice(1)}</button>)}
      </div></div>
    </section>

    <section className="mb-7"><h2 className="section-title flex items-center gap-2 mb-3"><HardDrive size={20} className="accent" /> Your data</h2>
      <div className="card card-pad field-stack">
        <p className="text-sm muted leading-relaxed">Your profiles and photos stay in this browser&apos;s local storage. There is no account or cloud sync.</p>
        <button className="secondary-button flex items-center justify-center gap-2" onClick={downloadBackup} disabled={busy}><Download size={18} /> Export JSON backup</button>
        <div className="border-t pt-4" style={{ borderColor: "var(--line)" }}>
          <label className="field-label" htmlFor="backup-file">Import JSON backup</label>
          <input ref={fileInput} id="backup-file" className="input text-sm" type="file" accept=".json,application/json" onChange={(event) => { setSelectedFile(event.target.files?.[0] ?? null); setError(""); setMessage(""); }} />
          {selectedFile && <><p className="text-xs muted mt-2">This will add people and update matching profile IDs. Existing people with other IDs stay saved.</p>
            <button className="primary-button w-full flex items-center justify-center gap-2 mt-3" onClick={restoreBackup} disabled={busy}><Upload size={18} /> Import {selectedFile.name}</button></>}
        </div>
        <p className="text-xs muted leading-relaxed">To move from the iPhone app, use its Settings → Export All Data, then select that JSON file here. SwiftData cannot transfer automatically.</p>
      </div>
    </section>

    <section className="mb-7"><h2 className="section-title flex items-center gap-2 mb-3"><Share2 size={20} className="accent" /> Add to Home Screen</h2>
      <div className="card card-pad text-sm leading-relaxed"><p>Open the deployed HTTPS link in Safari, tap Share, then choose Add to Home Screen. The installed app opens without the normal Safari toolbar.</p>
        <p className="muted mt-3">Safari and the installed Home Screen app can keep separate local data. If you entered people in Safari first, export a JSON backup there and import it after opening the installed app.</p>
        <p className="muted mt-3">The iPhone Contacts picker and scheduled local iOS notifications cannot be carried over directly to a local-only website. Create people manually or import the native app&apos;s JSON export.</p></div>
    </section>

    <section><h2 className="section-title flex items-center gap-2 mb-3"><ShieldCheck size={20} className="accent" /> Privacy</h2>
      <div className="card card-pad text-sm muted leading-relaxed">Your data stays on this device unless you choose to export a backup. Clearing Safari website data, removing this web app, or changing devices may erase it. Keep a recent backup in a safe place.</div>
    </section>
  </main>;
}
