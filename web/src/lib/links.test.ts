import { describe, expect, it } from "vitest";
import { emailLink, instagramLink, linkedInLink, messageLink, phoneLink, websiteLink, whatsAppLink } from "./links";

describe("contact links", () => {
  it("produces tap-ready phone, message, email, and social URLs", () => {
    expect(phoneLink("+1 (555) 123-4567")).toBe("tel:+15551234567");
    expect(messageLink("+1 (555) 123-4567")).toBe("sms:+15551234567");
    expect(emailLink("sarah@example.com")).toBe("mailto:sarah@example.com");
    expect(linkedInLink("sarah-smith")).toBe("https://www.linkedin.com/in/sarah-smith");
    expect(linkedInLink("www.linkedin.com/in/sarah-smith")).toBe("https://www.linkedin.com/in/sarah-smith");
    expect(linkedInLink("https://lnkd.in/sarah-shortlink")).toBe("https://lnkd.in/sarah-shortlink");
    expect(instagramLink("@sarah")).toBe("https://www.instagram.com/sarah");
    expect(instagramLink("www.instagram.com/sarah")).toBe("https://www.instagram.com/sarah");
    expect(whatsAppLink("+1 555 123 4567")).toBe("https://wa.me/15551234567");
    expect(websiteLink("example.com/gift")).toBe("https://example.com/gift");
  });

  it("rejects unsafe schemes and malformed contact values", () => {
    expect(websiteLink("javascript:alert(1)")).toBeNull();
    expect(linkedInLink("javascript:alert(1)")).toBeNull();
    expect(instagramLink("data:text/html,hello")).toBeNull();
    expect(emailLink("sarah@example.com?subject=surprise")).toBeNull();
    expect(phoneLink("hello")).toBeNull();
  });
});
