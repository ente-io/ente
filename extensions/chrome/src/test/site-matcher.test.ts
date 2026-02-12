import { describe, it, expect } from "vitest";
import type { Code } from "@/lib/types/code";
import { matchCodesToSite } from "@/lib/services/site-matcher";

const mkCode = (overrides: Partial<Code>): Code => ({
  id: "code-id",
  type: "totp",
  issuer: "Example",
  account: "user@example.com",
  length: 6,
  period: 30,
  algorithm: "sha1",
  secret: "AAAAAAAA",
  codeDisplay: undefined,
  uriString: "otpauth://totp/Example:user@example.com?secret=AAAAAAAA&issuer=Example",
  ...overrides,
});

describe("site-matcher", () => {
  it("uses eTLD+1 for domain matching (PSL-aware)", () => {
    const code = mkCode({ issuer: "test.co.uk" });
    const matches = matchCodesToSite([code], "https://login.test.co.uk/path");
    expect(matches[0]?.matchType).toBe("domain");
  });

  it("does not match by fuzzy substring to reduce phishing risk", () => {
    const code = mkCode({ issuer: "Bitwarden" });
    const matches = matchCodesToSite([code], "https://bitwarden.com/login");
    expect(matches.length).toBe(0);
  });
});
