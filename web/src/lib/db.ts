import Dexie, { type Table } from "dexie";
import { z } from "zod";
import { isValidBirthday } from "./birthday";

export const RELATIONSHIPS = ["Friend", "Family", "Coworker", "Professional", "Partner", "Other"] as const;
export const GIFT_KINDS = ["Idea", "Wishlist", "Given"] as const;
export const ALLOWED_REMINDER_OFFSETS = [0, 1, 3, 7, 14, 30] as const;

const dateString = z.string().refine((value) => !Number.isNaN(Date.parse(value)), "Invalid date");
const optionalDateString = dateString.nullable();

export const giftSchema = z.object({
  id: z.uuid(),
  title: z.string().trim().min(1),
  kind: z.enum(GIFT_KINDS),
  productURL: z.string(),
  cost: z.string(),
  notes: z.string(),
  dateGiven: optionalDateString,
});
export type GiftEntry = z.infer<typeof giftSchema>;

export const customFieldSchema = z.object({
  id: z.uuid(),
  title: z.string().trim().min(1),
  value: z.string(),
});
export type CustomProfileField = z.infer<typeof customFieldSchema>;

export const profileSchema = z.object({
  id: z.uuid(),
  fullName: z.string().trim().min(1, "Enter a full name"),
  nickname: z.string(),
  birthdayMonth: z.number().int(),
  birthdayDay: z.number().int(),
  birthYear: z.number().int().min(1800).max(9999).nullable(),
  relationship: z.enum(RELATIONSHIPS),
  location: z.string(),
  howWeMet: z.string(),
  dateWeMet: optionalDateString,
  favoriteFoods: z.string(),
  interests: z.string(),
  personalNotes: z.string(),
  phoneNumber: z.string(),
  emailAddress: z.string(),
  linkedIn: z.string(),
  instagram: z.string(),
  whatsApp: z.string(),
  website: z.string(),
  createdAt: dateString,
  updatedAt: dateString,
  favoriteRestaurants: z.string(),
  favoriteColors: z.string(),
  favoriteMusic: z.string(),
  favoriteMovies: z.string(),
  thingsTheyLike: z.string(),
  thingsTheyDislike: z.string(),
  importantDetails: z.string(),
  budgetPreference: z.string(),
  gifts: z.array(giftSchema),
  customFields: z.array(customFieldSchema),
  photoData: z.instanceof(Blob).nullable(),
  reminderOffsets: z.string().refine((value) => value === "" || value.split(",").every((offset) =>
    ALLOWED_REMINDER_OFFSETS.includes(Number(offset) as typeof ALLOWED_REMINDER_OFFSETS[number]) && offset.trim() !== "",
  ), "Invalid reminder offsets"),
  remindersDisabled: z.boolean(),
}).superRefine((profile, ctx) => {
  if (!isValidBirthday(profile.birthdayMonth, profile.birthdayDay, profile.birthYear)) {
    ctx.addIssue({ code: "custom", path: ["birthdayDay"], message: "Invalid birthday" });
  }
  if (profile.birthYear !== null && profile.birthYear > new Date().getFullYear()) {
    ctx.addIssue({ code: "custom", path: ["birthYear"], message: "Birth year cannot be in the future" });
  }
});
export type PersonProfile = z.infer<typeof profileSchema>;

export const settingsSchema = z.object({
  id: z.literal("main"),
  remindersEnabled: z.boolean(),
  reminderOffsets: z.array(z.number().int().refine((value) => ALLOWED_REMINDER_OFFSETS.includes(value as typeof ALLOWED_REMINDER_OFFSETS[number]))),
  reminderHour: z.number().int().min(0).max(23),
  reminderMinute: z.number().int().min(0).max(59),
  appearance: z.enum(["system", "light", "dark"]),
});
export type AppSettings = z.infer<typeof settingsSchema>;

export const DEFAULT_SETTINGS: AppSettings = {
  id: "main",
  remindersEnabled: true,
  reminderOffsets: [0, 7],
  reminderHour: 9,
  reminderMinute: 0,
  appearance: "system",
};

class RememberDB extends Dexie {
  people!: Table<PersonProfile, string>;
  settings!: Table<AppSettings, "main">;

  constructor() {
    super("remember-pwa");
    this.version(1).stores({
      people: "id, fullName, relationship, birthdayMonth, createdAt, updatedAt",
      settings: "id",
    });
  }
}

export const db = new RememberDB();

export function blankProfile(preselectedDate = new Date()): PersonProfile {
  const now = new Date().toISOString();
  return {
    id: crypto.randomUUID(),
    fullName: "",
    nickname: "",
    birthdayMonth: preselectedDate.getMonth() + 1,
    birthdayDay: preselectedDate.getDate(),
    birthYear: null,
    relationship: "Friend",
    location: "",
    howWeMet: "",
    dateWeMet: null,
    favoriteFoods: "",
    interests: "",
    personalNotes: "",
    phoneNumber: "",
    emailAddress: "",
    linkedIn: "",
    instagram: "",
    whatsApp: "",
    website: "",
    createdAt: now,
    updatedAt: now,
    favoriteRestaurants: "",
    favoriteColors: "",
    favoriteMusic: "",
    favoriteMovies: "",
    thingsTheyLike: "",
    thingsTheyDislike: "",
    importantDetails: "",
    budgetPreference: "",
    gifts: [],
    customFields: [],
    photoData: null,
    reminderOffsets: "",
    remindersDisabled: false,
  };
}

export async function loadSettings(): Promise<AppSettings> {
  const stored = await db.settings.get("main");
  return stored ? settingsSchema.parse(stored) : { ...DEFAULT_SETTINGS, reminderOffsets: [...DEFAULT_SETTINGS.reminderOffsets] };
}

async function mutateSettings(change: (current: AppSettings) => Partial<AppSettings>): Promise<AppSettings> {
  return db.transaction("rw", db.settings, async () => {
    const stored = await db.settings.get("main");
    const current = stored ? settingsSchema.parse(stored) : DEFAULT_SETTINGS;
    const validated = settingsSchema.parse({ ...current, ...change(current), id: "main" });
    await db.settings.put(validated);
    return validated;
  });
}

export async function saveSettings(settings: Partial<AppSettings>): Promise<AppSettings> {
  return mutateSettings(() => settings);
}

/** Safely applies rapid checkbox changes without overwriting another offset. */
export async function setReminderOffset(offset: number, enabled: boolean): Promise<AppSettings> {
  if (!ALLOWED_REMINDER_OFFSETS.includes(offset as typeof ALLOWED_REMINDER_OFFSETS[number])) {
    throw new Error("Unsupported reminder offset");
  }
  return mutateSettings((current) => {
    const offsets = new Set(current.reminderOffsets);
    if (enabled) offsets.add(offset);
    else offsets.delete(offset);
    return { reminderOffsets: [...offsets].sort((a, b) => a - b) };
  });
}

export async function upsertProfile(profile: PersonProfile): Promise<PersonProfile> {
  const validated = profileSchema.parse({ ...profile, updatedAt: new Date().toISOString() });
  await db.people.put(validated);
  return validated;
}

export async function deleteProfile(id: string): Promise<void> {
  await db.people.delete(id);
}
