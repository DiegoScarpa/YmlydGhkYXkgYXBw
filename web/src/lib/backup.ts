import { z } from "zod";
import { db, loadSettings, profileSchema, settingsSchema, type PersonProfile } from "./db";

const archiveSchema = z.object({
  formatVersion: z.union([z.literal(1), z.literal(2)]),
  exportedAt: z.string().refine((value) => !Number.isNaN(Date.parse(value))),
  people: z.array(z.unknown()),
  settings: z.unknown().optional(),
});

const objectSchema = z.record(z.string(), z.unknown());

function imageMimeType(bytes: Uint8Array): string {
  if (bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff) return "image/jpeg";
  if ([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a].every((byte, index) => bytes[index] === byte)) return "image/png";
  const ascii = (start: number, end: number) => String.fromCharCode(...bytes.subarray(start, end));
  if (ascii(0, 3) === "GIF") return "image/gif";
  if (ascii(0, 4) === "RIFF" && ascii(8, 12) === "WEBP") return "image/webp";
  if (ascii(4, 8) === "ftyp") {
    const brand = ascii(8, 12);
    if (["heic", "heix", "hevc", "hevx", "mif1", "msf1"].includes(brand)) return "image/heic";
    if (brand === "avif" || brand === "avis") return "image/avif";
  }
  return "image/jpeg";
}

function decodeBase64(value: unknown): Blob | null {
  if (value == null) return null;
  if (typeof value !== "string" || value.length % 4 !== 0 || !/^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$/.test(value)) {
    throw new Error("Invalid photo data in backup");
  }
  const binary = atob(value);
  const bytes = new Uint8Array(binary.length);
  for (let index = 0; index < binary.length; index++) bytes[index] = binary.charCodeAt(index);
  return new Blob([bytes], { type: imageMimeType(bytes) });
}

async function encodeBase64(blob: Blob | null): Promise<string | null> {
  if (!blob) return null;
  const bytes = new Uint8Array(await blob.arrayBuffer());
  let binary = "";
  for (let index = 0; index < bytes.length; index += 32_768) {
    binary += String.fromCharCode(...bytes.subarray(index, index + 32_768));
  }
  return btoa(binary);
}

function parseBackupPerson(raw: unknown): PersonProfile {
  const value = objectSchema.parse(raw);
  const gifts = z.array(objectSchema).parse(value.gifts).map((gift) => ({ ...gift, dateGiven: gift.dateGiven ?? null }));
  return profileSchema.parse({
    ...value,
    birthYear: value.birthYear ?? null,
    dateWeMet: value.dateWeMet ?? null,
    gifts,
    photoData: decodeBase64(value.photoData),
  });
}

/** A version 2 backup contains all local settings and base64 photos. */
export async function exportBackup(): Promise<string> {
  const people = await db.people.toArray();
  const settings = await loadSettings();
  const serializedPeople = await Promise.all(people.map(async (person) => ({
    ...person,
    photoData: await encodeBase64(person.photoData),
  })));
  return JSON.stringify({
    formatVersion: 2,
    exportedAt: new Date().toISOString(),
    people: serializedPeople,
    settings,
  }, null, 2);
}

/** Accepts native formatVersion 1 and web formatVersion 2; validates before any write. */
export async function importBackup(input: string | File): Promise<number> {
  const text = typeof input === "string" ? input : await input.text();
  let json: unknown;
  try {
    json = JSON.parse(text);
  } catch {
    throw new Error("The selected file is not valid JSON");
  }
  const archive = archiveSchema.parse(json);
  const people = archive.people.map(parseBackupPerson);
  const ids = new Set(people.map((person) => person.id));
  if (ids.size !== people.length) throw new Error("Backup contains duplicate profile IDs");
  const settings = archive.formatVersion === 2 ? settingsSchema.parse(archive.settings) : null;

  await db.transaction("rw", db.people, db.settings, async () => {
    await db.people.bulkPut(people);
    if (settings) await db.settings.put(settings);
  });
  return people.length;
}
