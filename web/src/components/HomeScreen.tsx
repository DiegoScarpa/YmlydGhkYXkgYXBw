"use client";

import { useState } from "react";
import { ArrowRight, Gift, Heart, Plus, Sparkles, Sun } from "lucide-react";
import type { AppSettings, PersonProfile } from "@/lib/db";
import { daysUntil } from "@/lib/birthday";
import { upcomingReminders } from "@/lib/reminders";
import { BirthdayRow, EmptyCard, MonthGrid } from "./Common";

export default function HomeScreen({ people, settings, now, onAdd, onPerson, onPeople, onCalendar }: {
  people: PersonProfile[]; settings: AppSettings; now: Date;
  onAdd: () => void; onPerson: (id: string) => void; onPeople: () => void; onCalendar: () => void;
}) {
  const [selected, setSelected] = useState(now);
  const upcoming = people.map((person) => ({ person, days: daysUntil(person.birthdayMonth, person.birthdayDay, now) ?? 999 }))
    .sort((a, b) => a.days - b.days || a.person.fullName.localeCompare(b.person.fullName));
  const groups = [
    { label: "Today", icon: Sparkles, people: upcoming.filter((entry) => entry.days === 0) },
    { label: "Next 7 Days", icon: Sun, people: upcoming.filter((entry) => entry.days >= 1 && entry.days <= 7) },
    { label: "Coming Up", icon: Gift, people: upcoming.filter((entry) => entry.days >= 8 && entry.days <= 30) },
  ];
  const reminders = upcomingReminders(people, settings, now);
  const due = reminders.filter((reminder) => reminder.fireDate <= now);
  const nextReminder = reminders.find((reminder) => reminder.fireDate > now);

  return <main className="app-shell">
    <header className="mb-9">
      <div className="flex items-start justify-between gap-4 mb-11">
        <h1 className="screen-title">Remember</h1>
        <button className="icon-button" aria-label="Add person" onClick={onAdd}><Plus size={26} /></button>
      </div>
      <p className="muted text-sm font-medium mb-3">{new Intl.DateTimeFormat(undefined, { weekday: "long", month: "long", day: "numeric" }).format(now)}</p>
      <p className="hero-title max-w-[17ch]">Keep close to what matters.</p>
    </header>

    {people.length === 0 ? <EmptyCard onAdd={onAdd} /> : <div className="space-y-7">
      {groups.filter((group) => group.people.length).map(({ label, icon: Icon, people: entries }) =>
        <section key={label}>
          <h2 className="section-title flex items-center gap-2 mb-3"><Icon size={20} className="accent" />{label}</h2>
          <div className="card px-4 py-1">{entries.map(({ person }) => <BirthdayRow key={person.id} person={person} referenceDate={now} onClick={() => onPerson(person.id)} />)}</div>
        </section>)}
      {groups.every((group) => group.people.length === 0) &&
        <div className="card card-pad"><Heart className="accent mb-2" size={24} /><p className="font-semibold">Nothing in the next 30 days</p><p className="muted text-sm mt-1">Your people are still saved and easy to find.</p></div>}
      <button className="secondary-button w-full flex items-center justify-between" onClick={onPeople}><span>See all people</span><ArrowRight size={18} /></button>
    </div>}

    {settings.remindersEnabled && people.length > 0 && <section className="card card-pad mt-7" aria-label="In-app reminders">
      <h2 className="section-title mb-1">In-app reminders</h2>
      {due.length ? <div className="mt-3 space-y-3">{due.map((reminder) => <button key={reminder.id} className="block text-left w-full" onClick={() => onPerson(reminder.personID)}>
        <span className="font-semibold accent text-sm">{reminder.title}</span><span className="block text-sm muted mt-1">{reminder.body}</span>
      </button>)}</div> : nextReminder ? <p className="text-sm muted mt-2">Next: {nextReminder.name}, {new Intl.DateTimeFormat(undefined, { month: "short", day: "numeric" }).format(nextReminder.fireDate)} at {new Intl.DateTimeFormat(undefined, { hour: "numeric", minute: "2-digit" }).format(nextReminder.fireDate)}.</p> :
        <p className="text-sm muted mt-2">No reminders scheduled in the next 30 days.</p>}
      <p className="text-xs muted mt-3">Reminders appear here when you open the app. Alerts while closed require a push service.</p>
    </section>}

    <section className="mt-8">
      <div className="flex items-center justify-between gap-3 mb-3">
        <h2 className="section-title">This Month</h2>
        <button className="accent text-sm font-semibold min-h-11" onClick={onCalendar}>Full calendar</button>
      </div>
      <div className="card p-4"><MonthGrid month={now} selected={selected} people={people} onSelect={setSelected} /></div>
    </section>
  </main>;
}
