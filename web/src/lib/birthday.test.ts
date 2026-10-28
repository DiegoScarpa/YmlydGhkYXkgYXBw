import { describe, expect, it } from "vitest";
import { birthdayOnDate, daysUntil, isValidBirthday, nextBirthday, observedBirthday, turningAge } from "./birthday";

describe("birthday calculations", () => {
  it("accepts February 29 without a birth year, but validates known years", () => {
    expect(isValidBirthday(2, 29)).toBe(true);
    expect(isValidBirthday(2, 29, 2000)).toBe(true);
    expect(isValidBirthday(2, 29, 1900)).toBe(false);
    expect(isValidBirthday(4, 31)).toBe(false);
    expect(isValidBirthday(13, 1)).toBe(false);
  });

  it("observes leap-day birthdays on February 28 in other years", () => {
    const regular = observedBirthday(2025, 2, 29);
    const leap = observedBirthday(2028, 2, 29);
    expect([regular?.getMonth(), regular?.getDate()]).toEqual([1, 28]);
    expect([leap?.getMonth(), leap?.getDate()]).toEqual([1, 29]);
    expect(birthdayOnDate(2, 29, new Date(2025, 1, 28))).toBe(true);
    expect(birthdayOnDate(2, 29, new Date(2025, 2, 1))).toBe(false);
  });

  it("includes today, rolls into the next year, and counts across DST", () => {
    expect(daysUntil(10, 23, new Date(2026, 9, 23, 18))).toBe(0);
    const next = nextBirthday(1, 2, new Date(2026, 11, 31));
    expect([next?.getFullYear(), next?.getMonth(), next?.getDate()]).toEqual([2027, 0, 2]);
    expect(daysUntil(3, 15, new Date(2026, 2, 7))).toBe(8);
  });

  it("shows an age only when the birth year is known", () => {
    expect(turningAge(1990, new Date(2027, 5, 2))).toBe(37);
    expect(turningAge(null, new Date(2027, 5, 2))).toBeNull();
  });
});
