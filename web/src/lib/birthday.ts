import type { PersonProfile } from "./db";

/** Native Remember observes February 29 on February 28 in non-leap years. */
const isLeapYear = (year: number) => year % 400 === 0 || (year % 4 === 0 && year % 100 !== 0);

export function isValidBirthday(month: number, day: number, year?: number | null): boolean {
  if (!Number.isInteger(month) || !Number.isInteger(day) || month < 1 || month > 12) return false;
  if (year !== undefined && year !== null && (!Number.isInteger(year) || year < 1800 || year > 9999)) return false;
  const referenceYear = year ?? 2000;
  const daysInMonth = [31, isLeapYear(referenceYear) ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  return day >= 1 && day <= daysInMonth[month - 1];
}

export function observedBirthday(year: number, month: number, day: number): Date | null {
  if (!Number.isInteger(year) || year < 1800 || year > 9999 || !isValidBirthday(month, day)) return null;
  const observedDay = month === 2 && day === 29 && !isLeapYear(year) ? 28 : day;
  return new Date(year, month - 1, observedDay);
}

/** Includes today's birthday, matching BirthdayCalculator.nextBirthday in the iPhone app. */
export function nextBirthday(month: number, day: number, after = new Date()): Date | null {
  if (!isValidBirthday(month, day) || Number.isNaN(after.getTime())) return null;
  const today = new Date(after.getFullYear(), after.getMonth(), after.getDate());
  for (let year = today.getFullYear(); year <= today.getFullYear() + 1; year++) {
    const candidate = observedBirthday(year, month, day);
    if (candidate && candidate >= today) return candidate;
  }
  return null;
}

/** Compares calendar dates instead of milliseconds, so daylight saving changes do not add a day. */
export function daysUntil(month: number, day: number, from = new Date()): number | null {
  const birthday = nextBirthday(month, day, from);
  if (!birthday) return null;
  const utcDay = (date: Date) => Date.UTC(date.getFullYear(), date.getMonth(), date.getDate());
  return Math.round((utcDay(birthday) - utcDay(from)) / 86_400_000);
}

export function birthdayOnDate(person: Pick<PersonProfile, "birthdayMonth" | "birthdayDay">, date: Date): boolean;
export function birthdayOnDate(month: number, day: number, date: Date): boolean;
export function birthdayOnDate(
  personOrMonth: Pick<PersonProfile, "birthdayMonth" | "birthdayDay"> | number,
  dayOrDate: number | Date,
  maybeDate?: Date,
): boolean {
  const month = typeof personOrMonth === "number" ? personOrMonth : personOrMonth.birthdayMonth;
  const day = typeof personOrMonth === "number" ? dayOrDate as number : personOrMonth.birthdayDay;
  const date = typeof personOrMonth === "number" ? maybeDate : dayOrDate as Date;
  if (!(date instanceof Date) || Number.isNaN(date.getTime())) return false;
  const observed = observedBirthday(date.getFullYear(), month, day);
  return observed?.getMonth() === date.getMonth() && observed.getDate() === date.getDate();
}

export function turningAge(birthYear: number | null | undefined, birthday: Date): number | null {
  if (birthYear == null || !Number.isInteger(birthYear) || Number.isNaN(birthday.getTime())) return null;
  return birthday.getFullYear() - birthYear;
}
