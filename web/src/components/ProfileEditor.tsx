"use client";

import { useState } from "react";
import { Camera, Plus, Trash2, X } from "lucide-react";
import type { CustomProfileField, GiftEntry, PersonProfile } from "@/lib/db";
import { isValidBirthday } from "@/lib/birthday";
import { compressPhoto } from "@/lib/photos";
import { Avatar, categories } from "./Common";

const offsets = [0, 1, 3, 7, 14, 30];
const months = Array.from({ length: 12 }, (_, index) => new Intl.DateTimeFormat(undefined, { month: "long" }).format(new Date(2000, index, 1)));

function dateInputValue(iso: string | null): string {
  if (!iso) return "";
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return "";
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}`;
}
function inputDateToISO(value: string): string | null { return value ? new Date(`${value}T12:00:00`).toISOString() : null; }

export default function ProfileEditor({ initial, isNew, onClose, onSave }: {
  initial: PersonProfile; isNew: boolean; onClose: () => void; onSave: (person: PersonProfile) => Promise<void>;
}) {
  const [draft, setDraft] = useState<PersonProfile>(() => ({ ...initial, gifts: initial.gifts.map((gift) => ({ ...gift })), customFields: initial.customFields.map((field) => ({ ...field })) }));
  const [saving, setSaving] = useState(false);
  const [photoBusy, setPhotoBusy] = useState(false);
  const [error, setError] = useState("");
  const set = <K extends keyof PersonProfile>(key: K, value: PersonProfile[K]) => setDraft((previous) => ({ ...previous, [key]: value }));
  const updateGift = (id: string, field: keyof GiftEntry, value: string | null) => setDraft((previous) => ({ ...previous,
    gifts: previous.gifts.map((gift) => gift.id === id ? { ...gift, [field]: value } : gift) }));
  const updateCustom = (id: string, field: keyof CustomProfileField, value: string) => setDraft((previous) => ({ ...previous,
    customFields: previous.customFields.map((item) => item.id === id ? { ...item, [field]: value } : item) }));
  const fields = (items: { key: keyof PersonProfile; label: string; placeholder?: string; multiline?: boolean; type?: string }[]) => items.map(({ key, label, placeholder, multiline, type }) =>
    <label key={key}><span className="field-label">{label}</span>{multiline ?
      <textarea className="input min-h-24 resize-y" value={draft[key] as string} placeholder={placeholder} onChange={(event) => set(key, event.target.value)} /> :
      <input className="input" type={type ?? "text"} value={draft[key] as string} placeholder={placeholder} onChange={(event) => set(key, event.target.value)} />}</label>);
  const selectedOffsets = new Set(draft.reminderOffsets.split(",").filter(Boolean).map(Number));
  const hasCustomSchedule = !!draft.reminderOffsets;

  async function save() {
    if (saving) return;
    const name = draft.fullName.trim();
    const birthYear = draft.birthYear;
    if (!name) { setError("Enter a full name."); return; }
    if (!isValidBirthday(draft.birthdayMonth, draft.birthdayDay, birthYear)) { setError("Choose a valid birthday."); return; }
    if (birthYear !== null && birthYear > new Date().getFullYear()) { setError("Birth year cannot be in the future."); return; }
    if (draft.gifts.some((gift) => !gift.title.trim())) { setError("Give each gift a title or remove the empty gift."); return; }
    if (draft.customFields.some((field) => !field.title.trim())) { setError("Give each custom field a title or remove it."); return; }
    if (hasCustomSchedule && selectedOffsets.size === 0) { setError("Select at least one reminder offset, or use the global schedule."); return; }
    setSaving(true); setError("");
    try { await onSave({ ...draft, fullName: name, updatedAt: new Date().toISOString() }); }
    catch (reason) { setError(reason instanceof Error ? reason.message : "Could not save this person."); setSaving(false); }
  }

  return <div className="modal-backdrop" role="presentation" onClick={onClose}>
    <section className="modal-panel" role="dialog" aria-modal="true" aria-labelledby="editor-title" onClick={(event) => event.stopPropagation()}>
      <div className="sheet-handle" aria-hidden="true" />
      <header className="flex items-center justify-between gap-3 mb-5"><button className="icon-button" onClick={onClose} aria-label="Cancel"><X size={23} /></button>
        <h2 id="editor-title" className="text-lg font-bold">{isNew ? "Add Person" : "Edit Person"}</h2>
        <button className="accent text-sm font-semibold min-h-11" onClick={save} disabled={saving || photoBusy}>{saving ? "Saving…" : "Save"}</button></header>
      {error && <p className="mb-4 rounded-xl p-3 text-sm text-red-700 bg-red-50" role="alert">{error}</p>}
      <div className="space-y-5">
        <section className="card card-pad field-stack">
          <div className="flex flex-col items-center gap-2">
            <Avatar person={draft} size={76} />
            <label className="accent inline-flex items-center gap-2 text-sm font-semibold min-h-11 cursor-pointer"><Camera size={17} /> {photoBusy ? "Preparing photo…" : draft.photoData ? "Change Photo" : "Add Photo"}
              <input type="file" accept="image/*" className="sr-only" aria-label="Choose profile photo" onChange={async (event) => {
                const file = event.target.files?.[0]; if (!file) return;
                setPhotoBusy(true); setError("");
                try { set("photoData", await compressPhoto(file)); }
                catch (reason) { setError(reason instanceof Error ? reason.message : "Could not process this photo."); }
                finally { setPhotoBusy(false); event.target.value = ""; }
              }} />
            </label>
            {draft.photoData && <button className="text-xs muted min-h-8" onClick={() => set("photoData", null)}>Remove photo</button>}
          </div>
          {fields([{ key: "fullName", label: "Full name", placeholder: "Sarah Chen" }, { key: "nickname", label: "Nickname", placeholder: "Optional" }])}
          <div className="grid grid-cols-2 gap-3">
            <label><span className="field-label">Birthday month</span><select className="input" value={draft.birthdayMonth} onChange={(event) => set("birthdayMonth", Number(event.target.value))}>
              {months.map((name, index) => <option key={name} value={index + 1}>{name}</option>)}</select></label>
            <label><span className="field-label">Day</span><select className="input" value={draft.birthdayDay} onChange={(event) => set("birthdayDay", Number(event.target.value))}>
              {Array.from({ length: 31 }, (_, index) => <option key={index} value={index + 1}>{index + 1}</option>)}</select></label>
          </div>
          <label><span className="field-label">Birth year (optional)</span><input className="input" type="number" min="1800" max={new Date().getFullYear()} inputMode="numeric" placeholder="Only if known"
            value={draft.birthYear ?? ""} onChange={(event) => set("birthYear", event.target.value ? Number(event.target.value) : null)} /></label>
          <label><span className="field-label">Relationship</span><select className="input" value={draft.relationship} onChange={(event) => set("relationship", event.target.value as PersonProfile["relationship"])}>
            {categories.map((category) => <option key={category}>{category}</option>)}</select></label>
        </section>

        <section className="card card-pad field-stack"><h3 className="section-title">About</h3>
          {fields([{ key: "location", label: "Location" }, { key: "howWeMet", label: "How we met", multiline: true }])}
          <label><span className="field-label">Date we met</span><input className="input" type="date" value={dateInputValue(draft.dateWeMet)} onChange={(event) => set("dateWeMet", inputDateToISO(event.target.value))} /></label>
        </section>

        <section className="card card-pad field-stack"><h3 className="section-title">The little things</h3>
          {fields([
            { key: "favoriteFoods", label: "Favorite foods" }, { key: "favoriteRestaurants", label: "Favorite restaurants" },
            { key: "favoriteColors", label: "Favorite colors" }, { key: "favoriteMusic", label: "Favorite music" },
            { key: "favoriteMovies", label: "Favorite movies" }, { key: "interests", label: "Interests and hobbies", multiline: true },
            { key: "thingsTheyLike", label: "Things they like", multiline: true }, { key: "thingsTheyDislike", label: "Things they dislike", multiline: true },
            { key: "importantDetails", label: "Important details", multiline: true }, { key: "personalNotes", label: "Notes", multiline: true },
          ])}
        </section>

        <section className="card card-pad field-stack"><h3 className="section-title">Reach out</h3>
          {fields([
            { key: "phoneNumber", label: "Phone number", type: "tel" }, { key: "emailAddress", label: "Email", type: "email" },
            { key: "linkedIn", label: "LinkedIn profile or username" }, { key: "instagram", label: "Instagram profile or username" },
            { key: "whatsApp", label: "WhatsApp number", type: "tel" }, { key: "website", label: "Website", type: "url" },
          ])}
        </section>

        <section className="card card-pad field-stack"><h3 className="section-title">Gifts</h3>
          {fields([{ key: "budgetPreference", label: "Budget preference" }])}
          {draft.gifts.map((gift) => <div key={gift.id} className="rounded-xl p-3 field-stack" style={{ border: "1px solid var(--line)" }}>
            <div className="flex justify-between items-center"><span className="font-semibold text-sm">Gift</span><button className="icon-button" aria-label={`Remove ${gift.title || "gift"}`} onClick={() => set("gifts", draft.gifts.filter((item) => item.id !== gift.id))}><Trash2 size={17} /></button></div>
            <label><span className="field-label">Title</span><input className="input" value={gift.title} onChange={(event) => updateGift(gift.id, "title", event.target.value)} /></label>
            <div className="grid grid-cols-2 gap-3"><label><span className="field-label">Type</span><select className="input" value={gift.kind} onChange={(event) => updateGift(gift.id, "kind", event.target.value)}>
              <option>Idea</option><option>Wishlist</option><option>Given</option></select></label>
              <label><span className="field-label">Cost</span><input className="input" value={gift.cost} onChange={(event) => updateGift(gift.id, "cost", event.target.value)} /></label></div>
            <label><span className="field-label">Product link</span><input className="input" type="url" value={gift.productURL} onChange={(event) => updateGift(gift.id, "productURL", event.target.value)} /></label>
            <label><span className="field-label">Notes</span><textarea className="input min-h-20" value={gift.notes} onChange={(event) => updateGift(gift.id, "notes", event.target.value)} /></label>
            {gift.kind === "Given" && <label><span className="field-label">Date given</span><input className="input" type="date" value={dateInputValue(gift.dateGiven)} onChange={(event) => updateGift(gift.id, "dateGiven", inputDateToISO(event.target.value))} /></label>}
          </div>)}
          <button className="secondary-button flex items-center justify-center gap-2" onClick={() => set("gifts", [...draft.gifts, { id: crypto.randomUUID(), title: "", kind: "Idea", productURL: "", cost: "", notes: "", dateGiven: null }])}><Plus size={18} /> Add gift</button>
        </section>

        <section className="card card-pad field-stack"><h3 className="section-title">More to remember</h3>
          {draft.customFields.map((field) => <div key={field.id} className="grid grid-cols-[1fr_1fr_44px] gap-2 items-end">
            <label><span className="field-label">Label</span><input className="input" value={field.title} onChange={(event) => updateCustom(field.id, "title", event.target.value)} /></label>
            <label><span className="field-label">Value or URL</span><input className="input" value={field.value} onChange={(event) => updateCustom(field.id, "value", event.target.value)} /></label>
            <button className="icon-button" aria-label={`Remove ${field.title || "field"}`} onClick={() => set("customFields", draft.customFields.filter((item) => item.id !== field.id))}><Trash2 size={17} /></button>
          </div>)}
          <button className="secondary-button flex items-center justify-center gap-2" onClick={() => set("customFields", [...draft.customFields, { id: crypto.randomUUID(), title: "", value: "" }])}><Plus size={18} /> Add custom field</button>
        </section>

        <section className="card card-pad field-stack"><h3 className="section-title">Birthday reminders</h3>
          <label className="flex items-center gap-3 min-h-11 text-sm"><input type="checkbox" checked={draft.remindersDisabled} onChange={(event) => set("remindersDisabled", event.target.checked)} /> Silence reminders for this person</label>
          {!draft.remindersDisabled && <>
            <label><span className="field-label">Schedule</span><select className="input" value={hasCustomSchedule ? "custom" : "global"} onChange={(event) => set("reminderOffsets", event.target.value === "global" ? "" : "0,7")}>
              <option value="global">Use global schedule</option><option value="custom">Custom schedule</option></select></label>
            {hasCustomSchedule && <div className="grid grid-cols-2 gap-2">{offsets.map((offset) => <label key={offset} className="flex items-center gap-2 text-sm min-h-11">
              <input type="checkbox" checked={selectedOffsets.has(offset)} onChange={(event) => {
                const next = new Set(selectedOffsets); if (event.target.checked) next.add(offset); else next.delete(offset);
                if (next.size === 0) { setError("Choose at least one offset, or silence reminders for this person."); return; }
                setError("");
                set("reminderOffsets", [...next].sort((a, b) => a - b).join(","));
              }} /> {offset === 0 ? "On birthday" : `${offset} ${offset === 1 ? "day" : "days"} before`}</label>)}</div>}
          </>}
        </section>
        <button className="primary-button w-full" onClick={save} disabled={saving || photoBusy}>{saving ? "Saving…" : isNew ? "Add Person" : "Save Changes"}</button>
      </div>
    </section>
  </div>;
}
