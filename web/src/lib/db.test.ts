import "fake-indexeddb/auto";
import { afterEach, describe, expect, it } from "vitest";
import { exportBackup, importBackup } from "./backup";
import { blankProfile, db, deleteProfile, loadSettings, saveSettings, setReminderOffset, upsertProfile } from "./db";

afterEach(async () => {
  await db.people.clear();
  await db.settings.clear();
});

describe("local persistence and backups", () => {
  it("adds, edits, persists after reopening, and deletes a profile", async () => {
    const sarah = { ...blankProfile(new Date(2028, 1, 29)), fullName: "Sarah", favoriteFoods: "Sushi" };
    await upsertProfile(sarah);
    expect((await db.people.get(sarah.id))?.favoriteFoods).toBe("Sushi");
    await upsertProfile({ ...sarah, favoriteFoods: "Pizza" });
    db.close();
    await db.open();
    expect((await db.people.get(sarah.id))?.favoriteFoods).toBe("Pizza");
    await deleteProfile(sarah.id);
    expect(await db.people.count()).toBe(0);
  });

  it("imports the native version 1 archive including a photo and merges by ID", async () => {
    const person: Record<string, unknown> = {
      ...blankProfile(new Date(2028, 1, 29)),
      fullName: "Sarah",
      favoriteFoods: "Sushi",
      gifts: [{ id: crypto.randomUUID(), title: "Book", kind: "Idea", productURL: "", cost: "", notes: "" }],
      photoData: "aGk=",
    };
    delete person.birthYear;
    delete person.dateWeMet;
    const archive = JSON.stringify({ formatVersion: 1, exportedAt: new Date().toISOString(), people: [person] });
    expect(await importBackup(archive)).toBe(1);
    expect(await importBackup(archive)).toBe(1);
    expect(await db.people.count()).toBe(1);
    const saved = await db.people.toCollection().first();
    expect(saved?.fullName).toBe("Sarah");
    expect(saved?.birthYear).toBeNull();
    expect(saved?.gifts[0].dateGiven).toBeNull();
    expect(await saved?.photoData?.text()).toBe("hi");
  });

  it("keeps a native PNG contact photo as PNG", async () => {
    const pngHeader = Uint8Array.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
    const photoData = btoa(String.fromCharCode(...pngHeader));
    const person = { ...blankProfile(), fullName: "Avery", photoData };
    const archive = JSON.stringify({ formatVersion: 1, exportedAt: new Date().toISOString(), people: [person] });
    await importBackup(archive);
    expect((await db.people.get(person.id))?.photoData?.type).toBe("image/png");
  });

  it("rejects a whole invalid archive before writing any profiles", async () => {
    const valid = { ...blankProfile(), fullName: "Valid" };
    const invalid = { ...blankProfile(), fullName: "Invalid", birthdayMonth: 2, birthdayDay: 30 };
    const archive = JSON.stringify({ formatVersion: 1, exportedAt: new Date().toISOString(), people: [valid, invalid] });
    await expect(importBackup(archive)).rejects.toThrow();
    expect(await db.people.count()).toBe(0);
  });

  it("round-trips web settings and photos", async () => {
    const profile = { ...blankProfile(), fullName: "Mia", photoData: new Blob(["photo"], { type: "image/jpeg" }) };
    await upsertProfile(profile);
    await saveSettings({ reminderOffsets: [1, 14], appearance: "dark" });
    const backup = await exportBackup();
    await db.people.clear();
    await db.settings.clear();
    expect(await importBackup(backup)).toBe(1);
    expect((await loadSettings()).appearance).toBe("dark");
    expect((await loadSettings()).reminderOffsets).toEqual([1, 14]);
    expect(await (await db.people.get(profile.id))?.photoData?.text()).toBe("photo");
  });

  it("preserves concurrent changes to different settings", async () => {
    await Promise.all([
      saveSettings({ reminderHour: 8, reminderMinute: 45 }),
      saveSettings({ appearance: "dark" }),
      saveSettings({ reminderOffsets: [0, 3, 7] }),
    ]);
    expect(await loadSettings()).toMatchObject({
      reminderHour: 8,
      reminderMinute: 45,
      appearance: "dark",
      reminderOffsets: [0, 3, 7],
    });
  });

  it("preserves rapid independent reminder offset toggles", async () => {
    await Promise.all([
      setReminderOffset(1, true),
      setReminderOffset(3, true),
      setReminderOffset(7, false),
    ]);
    expect((await loadSettings()).reminderOffsets).toEqual([0, 1, 3]);
  });
});
