"use client";

import { useEffect, useState } from "react";
import Image from "next/image";
import { CalendarDays, Gift, House, Settings, Users } from "lucide-react";
import type { PersonProfile } from "@/lib/db";
import { birthdayOnDate, daysUntil, nextBirthday } from "@/lib/birthday";

export type Tab = "home" | "calendar" | "people" | "settings";

export const categories = ["Friend", "Family", "Coworker", "Professional", "Partner", "Other"] as const;
export const categoryColors: Record<string, string> = {
  Friend: "#4d8fe8", Family: "#ef9a45", Coworker: "#28a9aa",
  Professional: "#7164c9", Partner: "#e472a6", Other: "#94949d",
};

export function formatBirthday(date: Date | null): string {
  return date ? new Intl.DateTimeFormat(undefined, { month: "long", day: "numeric" }).format(date) : "Birthday unavailable";
}

export function formatFullDate(date: Date): string {
  return new Intl.DateTimeFormat(undefined, { weekday: "long", month: "long", day: "numeric" }).format(date);
}

export function Avatar({ person, size = 52 }: { person: PersonProfile; size?: number }) {
  const [image, setImage] = useState<{ blob: Blob; url: string } | null>(null);
  useEffect(() => {
    if (!person.photoData) return;
    const blob = person.photoData;
    const objectURL = URL.createObjectURL(blob);
    let active = true;
    queueMicrotask(() => { if (active) setImage({ blob, url: objectURL }); });
    return () => { active = false; URL.revokeObjectURL(objectURL); };
  }, [person.photoData]);
  const initials = person.fullName.trim().split(/\s+/).slice(0, 2).map((part) => part[0] || "").join("").toUpperCase() || "?";
  const color = categoryColors[person.relationship];
  return <div className="shrink-0 overflow-hidden rounded-full grid place-items-center font-semibold"
    style={{ width: size, height: size, color, background: `${color}20`, fontSize: size * .32 }}
    aria-label={`${person.fullName} profile picture`}>
    {image?.blob === person.photoData ? <Image src={image.url} alt="" width={size} height={size} unoptimized className="h-full w-full object-cover" /> : initials}
  </div>;
}

export function BirthdayRow({ person, referenceDate, onClick }: {
  person: PersonProfile; referenceDate: Date; onClick: () => void;
}) {
  const next = nextBirthday(person.birthdayMonth, person.birthdayDay, referenceDate);
  const days = daysUntil(person.birthdayMonth, person.birthdayDay, referenceDate);
  const countdown = days === 0 ? "Today" : days === 1 ? "Tomorrow" : days === null ? "—" : `${days} days`;
  const color = categoryColors[person.relationship];
  return <button onClick={onClick} className="row-divider w-full flex items-center gap-3 py-3 text-left min-h-[68px]"
    aria-label={`${person.fullName}, ${formatBirthday(next)}, ${countdown}`}>
    <Avatar person={person} />
    <span className="min-w-0 flex-1">
      <span className="block truncate font-semibold">{person.fullName}</span>
      <span className="block text-sm muted">{formatBirthday(next)}</span>
    </span>
    <span className="shrink-0 rounded-full px-2.5 py-1 text-xs font-semibold" style={{ color, background: `${color}1c` }}>{countdown}</span>
  </button>;
}

export function MonthGrid({ month, selected, people, onSelect }: {
  month: Date; selected: Date; people: PersonProfile[]; onSelect: (date: Date) => void;
}) {
  const year = month.getFullYear();
  const monthIndex = month.getMonth();
  const leading = new Date(year, monthIndex, 1).getDay();
  const total = new Date(year, monthIndex + 1, 0).getDate();
  const today = new Date();
  const weekdays = ["S", "M", "T", "W", "T", "F", "S"];
  return <div>
    <div className="calendar-grid mb-2">{weekdays.map((label, index) =>
      <span key={index} className="text-center text-xs font-semibold muted" aria-hidden="true">{label}</span>)}</div>
    <div className="calendar-grid">
      {Array.from({ length: leading }, (_, index) => <span key={`gap-${index}`} aria-hidden="true" />)}
      {Array.from({ length: total }, (_, index) => {
        const date = new Date(year, monthIndex, index + 1);
        const birthdays = people.filter((person) => birthdayOnDate(person, date));
        const isSelected = selected.toDateString() === date.toDateString();
        const isToday = today.toDateString() === date.toDateString();
        return <button key={index} className={`day-cell ${isToday ? "today" : ""}`} aria-pressed={isSelected}
          aria-label={`${formatFullDate(date)}${birthdays.length ? `, birthdays: ${birthdays.map((person) => person.fullName).join(", ")}` : ""}`}
          onClick={() => onSelect(date)}>
          <span className="day-number">{index + 1}</span>
          <span className="flex h-[6px] items-center justify-center gap-[2px]">
            {birthdays.slice(0, 3).map((person) => <span key={person.id} className="h-[5px] w-[5px] rounded-full" style={{ background: categoryColors[person.relationship] }} />)}
          </span>
        </button>;
      })}
    </div>
  </div>;
}

const tabs = [
  { id: "home" as Tab, label: "Home", icon: House },
  { id: "calendar" as Tab, label: "Calendar", icon: CalendarDays },
  { id: "people" as Tab, label: "People", icon: Users },
  { id: "settings" as Tab, label: "Settings", icon: Settings },
];

export function BottomTabs({ active, onChange }: { active: Tab; onChange: (tab: Tab) => void }) {
  return <nav className="tabbar" aria-label="Main navigation">
    {tabs.map(({ id, label, icon: Icon }) => <button key={id} aria-current={active === id ? "page" : undefined}
      onClick={() => onChange(id)}><Icon size={24} strokeWidth={active === id ? 2.5 : 2} aria-hidden="true" /><span>{label}</span></button>)}
  </nav>;
}

export function EmptyCard({ onAdd }: { onAdd: () => void }) {
  return <div className="card card-pad text-left">
    <Gift size={30} className="accent mb-3" aria-hidden="true" />
    <h2 className="section-title mb-2">Remember someone special</h2>
    <p className="muted text-sm leading-relaxed mb-4">Add a person to see birthdays and the details that matter to them.</p>
    <button className="primary-button" onClick={onAdd}>Add Person</button>
  </div>;
}
