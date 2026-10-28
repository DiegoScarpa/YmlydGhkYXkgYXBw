"use client";

import { useState } from "react";
import { ArrowLeft, ArrowUpRight, CalendarDays, Camera, Gift, Globe, Heart, Mail, MapPin, MessageCircle, Phone, Trash2, Users } from "lucide-react";
import type { PersonProfile } from "@/lib/db";
import { nextBirthday, turningAge } from "@/lib/birthday";
import { emailLink, instagramLink, linkedInLink, messageLink, phoneLink, websiteLink, whatsAppLink } from "@/lib/links";
import { Avatar, categoryColors, formatBirthday } from "./Common";

function InfoRow({ label, value, icon: Icon }: { label: string; value: string; icon: typeof Gift }) {
  if (!value) return null;
  return <div className="flex items-start gap-3 py-1.5"><Icon size={20} className="muted shrink-0 mt-0.5" />
    <div className="min-w-0"><span className="block text-xs muted">{label}</span><span className="block text-sm whitespace-pre-wrap break-words">{value}</span></div></div>;
}

function LinkRow({ label, value, href, icon: Icon }: { label: string; value: string; href: string | null; icon: typeof Gift }) {
  if (!href) return null;
  const external = /^https?:\/\//i.test(href);
  return <a href={href} target={external ? "_blank" : undefined} rel={external ? "noopener noreferrer" : undefined}
    className="flex items-center gap-3 py-2.5 min-h-[52px]" aria-label={`${label}, ${value}`}>
    <Icon size={20} className="accent shrink-0" />
    <span className="min-w-0 flex-1"><span className="block text-sm font-semibold">{label}</span><span className="block text-xs muted truncate">{value}</span></span>
    <ArrowUpRight size={15} className="muted shrink-0" /></a>;
}

export default function ProfileDetail({ person, onBack, onEdit, onDelete }: {
  person: PersonProfile; onBack: () => void; onEdit: () => void; onDelete: () => Promise<void>;
}) {
  const [confirmDelete, setConfirmDelete] = useState(false);
  const [deleteError, setDeleteError] = useState("");
  const next = nextBirthday(person.birthdayMonth, person.birthdayDay);
  const age = next ? turningAge(person.birthYear, next) : null;
  const color = categoryColors[person.relationship];
  const links = [
    { label: "Call", value: person.phoneNumber, href: phoneLink(person.phoneNumber), icon: Phone },
    { label: "Message", value: "iMessage or SMS", href: messageLink(person.phoneNumber), icon: MessageCircle },
    { label: "Email", value: person.emailAddress, href: emailLink(person.emailAddress), icon: Mail },
    { label: "LinkedIn", value: person.linkedIn, href: linkedInLink(person.linkedIn), icon: Users },
    { label: "Instagram", value: person.instagram, href: instagramLink(person.instagram), icon: Camera },
    { label: "WhatsApp", value: person.whatsApp, href: whatsAppLink(person.whatsApp), icon: MessageCircle },
    { label: "Website", value: person.website, href: websiteLink(person.website), icon: Globe },
  ];
  const hasPersonal = [person.favoriteFoods, person.favoriteRestaurants, person.favoriteColors, person.favoriteMusic,
    person.favoriteMovies, person.interests, person.thingsTheyLike, person.thingsTheyDislike,
    person.importantDetails, person.personalNotes].some(Boolean);

  return <main className="app-shell">
    <header className="flex items-center justify-between mb-5">
      <button className="accent flex items-center gap-1 min-h-11 text-sm font-semibold" onClick={onBack}><ArrowLeft size={18} /> Back</button>
      <h1 className="text-sm font-semibold truncate max-w-[55%]">{person.fullName}</h1>
      <button className="accent min-h-11 text-sm font-semibold" onClick={onEdit}>Edit</button>
    </header>
    <div className="space-y-4">
      <section className="card p-6 flex flex-col items-center text-center">
        <Avatar person={person} size={88} />
        <h2 className="text-2xl font-bold mt-3 tracking-tight">{person.fullName}</h2>
        {person.nickname && <p className="muted mt-1">“{person.nickname}”</p>}
        <span className="text-xs font-semibold rounded-full px-3 py-1.5 mt-3" style={{ color, background: `${color}20` }}>{person.relationship}</span>
        <p className="text-sm muted mt-4 flex items-center gap-1.5"><Gift size={16} /> {formatBirthday(next)} {age !== null && `· Turning ${age}`}</p>
      </section>

      {links.some((link) => link.href) && <section className="card card-pad"><h2 className="section-title mb-2">Reach out</h2>
        <div className="divide-y" style={{ borderColor: "var(--line)" }}>{links.map((link) => <LinkRow key={link.label} {...link} />)}</div></section>}

      <section className="card card-pad"><h2 className="section-title mb-2">About</h2>
        <div className="space-y-1">
          <InfoRow label="Location" value={person.location} icon={MapPin} />
          <InfoRow label="How we met" value={person.howWeMet} icon={Users} />
          <InfoRow label="Date we met" value={person.dateWeMet ? new Intl.DateTimeFormat(undefined, { dateStyle: "medium" }).format(new Date(person.dateWeMet)) : ""} icon={CalendarDays} />
        </div>
        {!person.location && !person.howWeMet && !person.dateWeMet && <p className="text-sm muted">Add details about how you know {person.fullName}.</p>}
      </section>

      {hasPersonal && <section className="card card-pad"><h2 className="section-title mb-2">The little things</h2><div className="space-y-1">
        <InfoRow label="Favorite foods" value={person.favoriteFoods} icon={Heart} />
        <InfoRow label="Favorite restaurants" value={person.favoriteRestaurants} icon={Heart} />
        <InfoRow label="Favorite colors" value={person.favoriteColors} icon={Heart} />
        <InfoRow label="Favorite music" value={person.favoriteMusic} icon={Heart} />
        <InfoRow label="Favorite movies" value={person.favoriteMovies} icon={Heart} />
        <InfoRow label="Interests" value={person.interests} icon={Gift} />
        <InfoRow label="Likes" value={person.thingsTheyLike} icon={Heart} />
        <InfoRow label="Dislikes" value={person.thingsTheyDislike} icon={Heart} />
        <InfoRow label="Important details" value={person.importantDetails} icon={Gift} />
        <InfoRow label="Notes" value={person.personalNotes} icon={MessageCircle} />
      </div></section>}

      {(person.budgetPreference || person.gifts.length > 0) && <section className="card card-pad"><h2 className="section-title mb-2">Gifts</h2>
        <InfoRow label="Budget preference" value={person.budgetPreference} icon={Gift} />
        <div className="divide-y" style={{ borderColor: "var(--line)" }}>{person.gifts.map((gift) => <div key={gift.id} className="py-3">
          <div className="flex justify-between gap-3"><span className="text-sm font-semibold">{gift.title}</span><span className="text-xs muted">{gift.kind}</span></div>
          {gift.cost && <p className="text-xs muted mt-1">{gift.cost}</p>}
          {gift.notes && <p className="text-sm mt-1 whitespace-pre-wrap">{gift.notes}</p>}
          {gift.dateGiven && <p className="text-xs muted mt-1">Given {new Intl.DateTimeFormat(undefined, { dateStyle: "medium" }).format(new Date(gift.dateGiven))}</p>}
          {websiteLink(gift.productURL) && <a className="accent text-sm font-semibold inline-flex gap-1 mt-2" href={websiteLink(gift.productURL)!} target="_blank" rel="noopener noreferrer">View product <ArrowUpRight size={15} /></a>}
        </div>)}</div>
      </section>}

      {person.customFields.length > 0 && <section className="card card-pad"><h2 className="section-title mb-2">More to remember</h2>
        {person.customFields.map((field) => websiteLink(field.value) ? <LinkRow key={field.id} label={field.title} value={field.value} href={websiteLink(field.value)} icon={Globe} /> :
          <InfoRow key={field.id} label={field.title} value={field.value} icon={Gift} />)}
      </section>}
      <button className="danger-button w-full flex items-center justify-center gap-2" onClick={() => { setDeleteError(""); setConfirmDelete(true); }}><Trash2 size={18} /> Delete Person</button>
    </div>
    {confirmDelete && <div className="modal-backdrop" role="presentation" onClick={() => setConfirmDelete(false)}>
      <div className="modal-panel" role="dialog" aria-modal="true" aria-labelledby="delete-title" onClick={(event) => event.stopPropagation()}>
        <h2 id="delete-title" className="section-title">Delete {person.fullName}?</h2>
        <p className="text-sm muted my-3">Their birthday, notes, and links will be removed from this app.</p>
        {deleteError && <p className="text-sm text-red-600 mb-3" role="alert">{deleteError}</p>}
        <div className="flex gap-3"><button className="secondary-button flex-1" onClick={() => setConfirmDelete(false)}>Cancel</button>
          <button className="danger-button flex-1" onClick={async () => {
            try { await onDelete(); setConfirmDelete(false); }
            catch (reason) { setDeleteError(reason instanceof Error ? reason.message : "Could not delete this person."); }
          }}>Delete Person</button></div>
      </div>
    </div>}
  </main>;
}
