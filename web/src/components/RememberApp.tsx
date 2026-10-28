"use client";

import { useEffect, useState } from "react";
import { useLiveQuery } from "dexie-react-hooks";
import { db, blankProfile, deleteProfile, saveSettings, upsertProfile, DEFAULT_SETTINGS, type AppSettings, type PersonProfile } from "@/lib/db";
import { BottomTabs, type Tab } from "./Common";
import HomeScreen from "./HomeScreen";
import CalendarScreen from "./CalendarScreen";
import PeopleScreen from "./PeopleScreen";
import SettingsScreen from "./SettingsScreen";
import ProfileDetail from "./ProfileDetail";
import ProfileEditor from "./ProfileEditor";

type Editor = { person: PersonProfile; isNew: boolean };

export default function RememberApp() {
  const people = useLiveQuery(() => db.people.toArray(), [], undefined);
  const storedSettings = useLiveQuery(() => db.settings.get("main"), [], undefined);
  const settings = storedSettings ?? DEFAULT_SETTINGS;
  const [tab, setTab] = useState<Tab>("home");
  const [selectedID, setSelectedID] = useState<string | null>(null);
  const [editor, setEditor] = useState<Editor | null>(null);
  const [now, setNow] = useState(() => new Date());
  const selected = people?.find((person) => person.id === selectedID) ?? null;

  useEffect(() => {
    if (settings.appearance === "system") document.documentElement.removeAttribute("data-theme");
    else document.documentElement.dataset.theme = settings.appearance;
  }, [settings.appearance]);
  useEffect(() => {
    const refresh = () => setNow(new Date());
    const timer = window.setInterval(refresh, 60_000);
    document.addEventListener("visibilitychange", refresh);
    return () => { window.clearInterval(timer); document.removeEventListener("visibilitychange", refresh); };
  }, []);

  function addPerson(date?: Date) { setEditor({ person: blankProfile(date), isNew: true }); }
  function showPerson(id: string) { setSelectedID(id); window.scrollTo({ top: 0, behavior: "smooth" }); }
  function changeTab(next: Tab) { setTab(next); setSelectedID(null); window.scrollTo({ top: 0, behavior: "smooth" }); }

  async function savePerson(person: PersonProfile) {
    const saved = await upsertProfile(person);
    setEditor(null);
    setSelectedID(saved.id);
  }

  async function removePerson() {
    if (!selectedID) return;
    await deleteProfile(selectedID);
    setSelectedID(null);
  }

  async function updateSettings(change: Partial<AppSettings>) { await saveSettings(change); }

  return <>
    {people === undefined ? <main className="app-shell"><h1 className="screen-title">Remember</h1><p className="muted mt-4">Opening your people…</p></main> : selected ?
      <ProfileDetail person={selected} onBack={() => setSelectedID(null)} onEdit={() => setEditor({ person: selected, isNew: false })} onDelete={removePerson} /> :
      tab === "home" ? <HomeScreen people={people} settings={settings} now={now} onAdd={() => addPerson()} onPerson={showPerson} onPeople={() => changeTab("people")} onCalendar={() => changeTab("calendar")} /> :
      tab === "calendar" ? <CalendarScreen people={people} now={now} onAdd={addPerson} onPerson={showPerson} /> :
      tab === "people" ? <PeopleScreen people={people} now={now} onAdd={() => addPerson()} onPerson={showPerson} /> :
      <SettingsScreen settings={settings} onSettingsSaved={updateSettings} />}
    <BottomTabs active={tab} onChange={changeTab} />
    {editor && <ProfileEditor key={editor.person.id} initial={editor.person} isNew={editor.isNew} onClose={() => setEditor(null)} onSave={savePerson} />}
  </>;
}
