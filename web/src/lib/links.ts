function normalizedPhone(value: string): string | null {
  const trimmed = value.trim();
  const digits = trimmed.replace(/\D/g, "");
  return digits ? `${trimmed.startsWith("+") ? "+" : ""}${digits}` : null;
}

export function phoneLink(value: string): string | null {
  const phone = normalizedPhone(value);
  return phone ? `tel:${phone}` : null;
}

export function messageLink(value: string): string | null {
  const phone = normalizedPhone(value);
  return phone ? `sms:${phone}` : null;
}

export function emailLink(value: string): string | null {
  const email = value.trim();
  return /^[^\s@?&#:]+@[^\s@?&#:]+\.[^\s@?&#:]+$/.test(email) ? `mailto:${email}` : null;
}

export function websiteLink(value: string): string | null {
  const trimmed = value.trim();
  if (!trimmed || /\s/.test(trimmed)) return null;
  const candidate = /^[a-z][a-z\d+.-]*:/i.test(trimmed) ? trimmed : `https://${trimmed}`;
  try {
    const url = new URL(candidate);
    if (!["https:", "http:"].includes(url.protocol) || !url.hostname || url.username || url.password) return null;
    if (!url.hostname.includes(".") && url.hostname !== "localhost") return null;
    return url.href;
  } catch {
    return null;
  }
}

function socialLink(value: string, host: string, base: string): string | null {
  const trimmed = value.trim();
  if (!trimmed) return null;
  if (/^https?:\/\//i.test(trimmed)) return websiteLink(trimmed);
  if (trimmed.toLowerCase().startsWith(host) || trimmed.toLowerCase().startsWith(`www.${host}`)) {
    const href = websiteLink(trimmed);
    if (!href) return null;
    const url = new URL(href);
    return url.hostname === host || url.hostname === `www.${host}` ? href : null;
  }
  if (!/^[a-z\d._-]+$/i.test(trimmed)) return null;
  return `${base}${encodeURIComponent(trimmed)}`;
}

export function linkedInLink(value: string): string | null {
  return socialLink(value, "linkedin.com", "https://www.linkedin.com/in/");
}

export function instagramLink(value: string): string | null {
  return socialLink(value.trim().replace(/^@/, ""), "instagram.com", "https://www.instagram.com/");
}

export function whatsAppLink(value: string): string | null {
  const digits = value.replace(/\D/g, "");
  return digits ? `https://wa.me/${digits}` : null;
}
