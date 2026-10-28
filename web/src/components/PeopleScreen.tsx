"use client";

import { useMemo, useState } from "react";
import { Plus, Search, SlidersHorizontal } from "lucide-react";
import type { PersonProfile } from "@/lib/db";
import { daysUntil } from "@/lib/birthday";
import { BirthdayRow, categories } from "./Common";

type Sort = "upcoming" | "name" | "relationship" | "recent" | "month";

export default function PeopleScreen({ people, now, onAdd, onPerson }: {
  people: PersonProfile[]; now: Date; onAdd: () => void; onPerson: (id: string) => void;
}) {
  const [query, setQuery] = useState("");
  const [sort, setSort] = useState<Sort>("upcoming");
  const [category, setCategory] = useState("All");
  const [showFilters, setShowFilters] = useState(false);
  const filtered = useMemo(() => people.filter((person) => {
    const search = [person.fullName, person.nickname, person.relationship, person.favoriteFoods, person.interests,
      person.personalNotes, person.favoriteRestaurants, person.favoriteMusic, person.favoriteMovies,
      person.thingsTheyLike, person.importantDetails].join(" ").toLocaleLowerCase();
    return (category === "All" || person.relationship === category) && search.includes(query.trim().toLocaleLowerCase());
  }).sort((a, b) => {
    if (sort === "name") return a.fullName.localeCompare(b.fullName);
    if (sort === "relationship") return a.relationship.localeCompare(b.relationship) || a.fullName.localeCompare(b.fullName);
    if (sort === "recent") return b.createdAt.localeCompare(a.createdAt);
    if (sort === "month") return a.birthdayMonth - b.birthdayMonth || a.birthdayDay - b.birthdayDay || a.fullName.localeCompare(b.fullName);
    return (daysUntil(a.birthdayMonth, a.birthdayDay, now) ?? 999) - (daysUntil(b.birthdayMonth, b.birthdayDay, now) ?? 999) || a.fullName.localeCompare(b.fullName);
  }), [people, query, sort, category, now]);

  return <main className="app-shell">
    <header className="flex items-start justify-between mb-6"><h1 className="screen-title">People</h1>
      <button className="icon-button" onClick={onAdd} aria-label="Add person"><Plus size={26} /></button></header>
    <div className="relative mb-3"><Search className="absolute left-3 top-3.5 muted" size={18} aria-hidden="true" />
      <input className="input pl-10" type="search" placeholder="Names, interests, notes" aria-label="Search people" value={query} onChange={(event) => setQuery(event.target.value)} /></div>
    <button className="flex items-center gap-2 accent font-semibold text-sm min-h-11 mb-3" onClick={() => setShowFilters(!showFilters)} aria-expanded={showFilters}>
      <SlidersHorizontal size={18} /> Filter and sort</button>
    {showFilters && <div className="card card-pad grid grid-cols-2 gap-3 mb-4">
      <label><span className="field-label">Sort</span><select className="input" value={sort} onChange={(event) => setSort(event.target.value as Sort)}>
        <option value="upcoming">Upcoming birthday</option><option value="name">Name</option><option value="relationship">Relationship</option><option value="recent">Recently added</option><option value="month">Birthday month</option>
      </select></label>
      <label><span className="field-label">Relationship</span><select className="input" value={category} onChange={(event) => setCategory(event.target.value)}>
        <option value="All">All relationships</option>{categories.map((option) => <option key={option}>{option}</option>)}
      </select></label>
    </div>}
    <p className="text-xs font-semibold uppercase tracking-wider muted mb-2">{filtered.length} {filtered.length === 1 ? "person" : "people"}</p>
    {filtered.length ? <div className="card px-4 py-1">{filtered.map((person) => <BirthdayRow key={person.id} person={person} referenceDate={now} onClick={() => onPerson(person.id)} />)}</div> :
      <div className="card card-pad text-center"><p className="font-semibold">{people.length ? "No people found" : "No people yet"}</p><p className="text-sm muted mt-2">{people.length ? "Try a different search or relationship." : "Add someone you want to remember."}</p>{!people.length && <button className="primary-button mt-4" onClick={onAdd}>Add Person</button>}</div>}
  </main>;
}
