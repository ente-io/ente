import { describe, it, expect } from "vitest";
import type { Code } from "@/lib/types/code";
import { checkPhishing, matchCodesToSite } from "@/lib/services/site-matcher";

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

  it("adds a low-confidence fuzzy match for common issuer-to-domain cases", () => {
    const code = mkCode({ issuer: "Bitwarden" });
    const matches = matchCodesToSite([code], "https://bitwarden.com/login");
    expect(matches[0]?.matchType).toBe("fuzzy");
  });

  it("flags phishing when issuer has known domains and the current site doesn't match", () => {
    const result = checkPhishing("https://githuub.com/login", "GitHub");
    expect(result.isPhishing).toBe(true);
    expect(result.expectedDomains?.length).toBeGreaterThan(0);
  });
});

