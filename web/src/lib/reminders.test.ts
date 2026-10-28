import { describe, expect, it } from "vitest";
import { blankProfile, DEFAULT_SETTINGS } from "./db";
import { upcomingReminders } from "./reminders";

describe("in-app reminder planning", () => {
  it("uses the leap-day observation, custom offsets, and gift idea count", () => {
    const sarah = {
      ...blankProfile(),
      fullName: "Sarah",
      birthdayMonth: 2,
      birthdayDay: 29,
      reminderOffsets: "0,7",
      gifts: [{ id: crypto.randomUUID(), title: "Book", kind: "Idea" as const, productURL: "", cost: "", notes: "", dateGiven: null }],
    };
    const settings = { ...DEFAULT_SETTINGS, reminderOffsets: [30] };
    const reminders = upcomingReminders([sarah], settings, new Date(2025, 1, 20, 12));
    expect(reminders.map((item) => item.daysBefore)).toEqual([7, 0]);
    expect(reminders[0].birthdayDate.getDate()).toBe(28);
    expect(reminders[0].body).toContain("1 gift idea");
    expect(new Set(reminders.map((item) => item.id)).size).toBe(reminders.length);
  });

  it("respects global and per-person switches", () => {
    const person = { ...blankProfile(), fullName: "Mia", birthdayMonth: 10, birthdayDay: 25 };
    const from = new Date(2026, 9, 24);
    const enabled = { ...DEFAULT_SETTINGS, reminderOffsets: [0, 1] };
    expect(upcomingReminders([person], enabled, from)).toHaveLength(2);
    expect(upcomingReminders([{ ...person, remindersDisabled: true }], enabled, from)).toHaveLength(0);
    expect(upcomingReminders([person], { ...enabled, remindersEnabled: false }, from)).toHaveLength(0);
  });
});
