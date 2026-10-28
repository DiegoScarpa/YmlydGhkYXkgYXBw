import { observedBirthday } from "./birthday";
import { ALLOWED_REMINDER_OFFSETS, type AppSettings, type PersonProfile } from "./db";

export interface InAppReminder {
  id: string;
  personID: string;
  name: string;
  daysBefore: number;
  fireDate: Date;
  birthdayDate: Date;
  title: string;
  body: string;
}

/** Local, visible reminders only. Browsers cannot reliably deliver these while the app is closed. */
export function upcomingReminders(people: PersonProfile[], settings: AppSettings, from = new Date()): InAppReminder[] {
  if (!settings.remindersEnabled || Number.isNaN(from.getTime())) return [];
  const start = new Date(from.getFullYear(), from.getMonth(), from.getDate());
  const end = new Date(start.getFullYear(), start.getMonth(), start.getDate() + 30, 23, 59, 59, 999);
  const allowedOffsets = new Set<number>(ALLOWED_REMINDER_OFFSETS);
  const reminders: InAppReminder[] = [];

  for (const person of people) {
    if (person.remindersDisabled) continue;
    const offsets = person.reminderOffsets
      ? person.reminderOffsets.split(",").map(Number)
      : settings.reminderOffsets;
    const giftIdeaCount = person.gifts.filter((gift) => gift.kind === "Idea").length;
    for (let year = start.getFullYear(); year <= start.getFullYear() + 1; year++) {
      const birthdayDate = observedBirthday(year, person.birthdayMonth, person.birthdayDay);
      if (!birthdayDate) continue;
      for (const offset of new Set(offsets)) {
        if (!allowedOffsets.has(offset)) continue;
        const fireDate = new Date(year, birthdayDate.getMonth(), birthdayDate.getDate() - offset, settings.reminderHour, settings.reminderMinute);
        if (fireDate < start || fireDate > end) continue;
        const title = offset === 0 ? `🎂 It's ${person.fullName}'s birthday!` : `🎂 ${person.fullName}'s birthday is coming up`;
        let body: string;
        if (offset === 0) body = `Wish ${person.fullName} a happy birthday today.`;
        else if (offset === 1) body = `Tomorrow is ${person.fullName}'s birthday! Don't forget to reach out.`;
        else body = `${person.fullName}'s birthday is in ${offset} days.${giftIdeaCount ? ` You saved ${giftIdeaCount} gift ${giftIdeaCount === 1 ? "idea" : "ideas"}.` : ""}`;
        reminders.push({
          id: `remember.${person.id}.${year}.${offset}`,
          personID: person.id,
          name: person.fullName,
          daysBefore: offset,
          fireDate,
          birthdayDate,
          title,
          body,
        });
      }
    }
  }
  return reminders.sort((left, right) => left.fireDate.getTime() - right.fireDate.getTime() || left.id.localeCompare(right.id));
}
