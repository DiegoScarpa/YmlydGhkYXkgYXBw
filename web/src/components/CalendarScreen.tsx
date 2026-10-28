"use client";

import { useRef, useState } from "react";
import { ChevronLeft, ChevronRight, Plus } from "lucide-react";
import type { PersonProfile } from "@/lib/db";
import { birthdayOnDate, observedBirthday } from "@/lib/birthday";
import { BirthdayRow, formatFullDate, MonthGrid } from "./Common";

export default function CalendarScreen({ people, now, onAdd, onPerson }: {
  people: PersonProfile[]; now: Date; onAdd: (date: Date) => void; onPerson: (id: string) => void;
}) {
  const [displayed, setDisplayed] = useState(new Date(now.getFullYear(), now.getMonth(), 1));
  const [selected, setSelected] = useState(new Date(now.getFullYear(), now.getMonth(), now.getDate()));
  const [view, setView] = useState<"month" | "year">("month");
  const touchStart = useRef<number | null>(null);
  const moveMonth = (amount: number) => {
    const next = new Date(displayed.getFullYear(), displayed.getMonth() + amount, 1);
    setDisplayed(next); setSelected(next);
  };
  const moveYear = (amount: number) => setDisplayed(new Date(displayed.getFullYear() + amount, displayed.getMonth(), 1));
  const selectedPeople = people.filter((person) => birthdayOnDate(person, selected)).sort((a, b) => a.fullName.localeCompare(b.fullName));

  return <main className="app-shell">
    <header className="flex items-start justify-between mb-7"><h1 className="screen-title">Calendar</h1>
      <button className="icon-button" onClick={() => onAdd(selected)} aria-label="Add person on selected date"><Plus size={26} /></button></header>
    <div className="segmented mb-6" role="group" aria-label="Calendar view">
      <button aria-pressed={view === "month"} onClick={() => setView("month")}>Month</button>
      <button aria-pressed={view === "year"} onClick={() => setView("year")}>Year</button>
    </div>

    <div className="flex items-center justify-between mb-5">
      <button className="icon-button" aria-label={view === "month" ? "Previous month" : "Previous year"} onClick={() => view === "month" ? moveMonth(-1) : moveYear(-1)}><ChevronLeft /></button>
      <h2 className="text-xl font-bold">{view === "month" ? new Intl.DateTimeFormat(undefined, { month: "long", year: "numeric" }).format(displayed) : displayed.getFullYear()}</h2>
      <button className="icon-button" aria-label={view === "month" ? "Next month" : "Next year"} onClick={() => view === "month" ? moveMonth(1) : moveYear(1)}><ChevronRight /></button>
    </div>

    {view === "month" ? <>
      <div className="card p-4 mb-6" onTouchStart={(event) => { touchStart.current = event.touches[0]?.clientX ?? null; }}
        onTouchEnd={(event) => { if (touchStart.current === null) return; const movement = event.changedTouches[0]?.clientX - touchStart.current; if (movement < -60) moveMonth(1); if (movement > 60) moveMonth(-1); touchStart.current = null; }}>
        <MonthGrid month={displayed} selected={selected} people={people} onSelect={setSelected} />
      </div>
      <section>
        <div className="flex items-center justify-between gap-2 mb-3"><h3 className="section-title">{formatFullDate(selected)}</h3>
          <button onClick={() => onAdd(selected)} className="accent min-h-11 flex items-center gap-1 text-sm font-semibold"><Plus size={17} /> Add</button></div>
        {selectedPeople.length ? <div className="card px-4 py-1">{selectedPeople.map((person) => <BirthdayRow key={person.id} person={person} referenceDate={now} onClick={() => onPerson(person.id)} />)}</div> :
          <div className="card card-pad text-sm muted">No birthdays on this date.</div>}
      </section>
    </> : <div className="grid grid-cols-2 gap-3">
      {Array.from({ length: 12 }, (_, monthIndex) => {
        const date = new Date(displayed.getFullYear(), monthIndex, 1);
        const count = people.filter((person) => observedBirthday(displayed.getFullYear(), person.birthdayMonth, person.birthdayDay)?.getMonth() === monthIndex).length;
        return <button key={monthIndex} onClick={() => { setDisplayed(date); setSelected(date); setView("month"); }}
          className="card min-h-[96px] p-4 text-left"><span className="block font-semibold">{new Intl.DateTimeFormat(undefined, { month: "long" }).format(date)}</span><span className="block text-xs muted mt-2">{count} {count === 1 ? "birthday" : "birthdays"}</span></button>;
      })}
    </div>}
  </main>;
}
