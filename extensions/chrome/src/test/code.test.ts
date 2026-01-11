import { describe, it, expect } from "vitest";
import { codeFromURIString, generateOTPs, getSecondsRemaining } from "@/lib/services/code";

describe("codeFromURIString", () => {
  it("should parse a basic TOTP URI", () => {
    const uri = "otpauth://totp/GitHub:user@example.com?secret=JBSWY3DPEHPK3PXP&issuer=GitHub";
    const code = codeFromURIString("test-id", uri);

    expect(code).toBeDefined();
    expect(code.issuer).toBe("GitHub");
    expect(code.account).toBe("user@example.com");
    expect(code.secret).toBe("JBSWY3DPEHPK3PXP");
    expect(code.type).toBe("totp");
    expect(code.length).toBe(6); // Code uses 'length' not 'digits'
    expect(code.period).toBe(30);
  });

  it("should parse TOTP URI with custom digits and period", () => {
    const uri = "otpauth://totp/Test?secret=JBSWY3DPEHPK3PXP&digits=8&period=60";
    const code = codeFromURIString("test-id", uri);

    expect(code).toBeDefined();
    expect(code.length).toBe(8);
    expect(code.period).toBe(60);
  });

  it("should parse HOTP URI", () => {
    const uri = "otpauth://hotp/Service?secret=JBSWY3DPEHPK3PXP&counter=42";
    const code = codeFromURIString("test-id", uri);

    expect(code).toBeDefined();
    expect(code.type).toBe("hotp");
    expect(code.counter).toBe(42);
  });

  it("should handle Steam type URI", () => {
    // Steam uses otpauth://steam/ protocol
    const uri = "otpauth://steam/Steam:username?secret=JBSWY3DPEHPK3PXP";
    const code = codeFromURIString("test-id", uri);

    expect(code).toBeDefined();
    expect(code.type).toBe("steam");
  });

  it("should throw for invalid URI", () => {
    expect(() => codeFromURIString("test-id", "not-a-valid-uri")).toThrow();
  });

  it("should use label as issuer if query issuer is missing", () => {
    const uri = "otpauth://totp/MyService:user?secret=JBSWY3DPEHPK3PXP";
    const code = codeFromURIString("test-id", uri);

    expect(code).toBeDefined();
    // Note: issuer parsing lowercases the path portion
    expect(code.issuer.toLowerCase()).toBe("myservice");
    expect(code.account).toBe("user");
  });
});

describe("generateOTPs", () => {
  it("should generate 6-digit TOTP codes", () => {
    const code = {
      id: "test",
      type: "totp" as const,
      secret: "JBSWY3DPEHPK3PXP",
      issuer: "Test",
      account: "user",
      length: 6,
      period: 30,
      algorithm: "sha1" as const,
      uriString: "otpauth://totp/Test:user?secret=JBSWY3DPEHPK3PXP",
      codeDisplay: undefined,
    };

    const [current, next] = generateOTPs(code, 0);

    expect(current).toMatch(/^\d{6}$/);
    expect(next).toMatch(/^\d{6}$/);
  });

  it("should generate 8-digit codes when specified", () => {
    const code = {
      id: "test",
      type: "totp" as const,
      secret: "JBSWY3DPEHPK3PXP",
      issuer: "Test",
      account: "user",
      length: 8,
      period: 30,
      algorithm: "sha1" as const,
      uriString: "otpauth://totp/Test:user?secret=JBSWY3DPEHPK3PXP&digits=8",
      codeDisplay: undefined,
    };

    const [current, next] = generateOTPs(code, 0);

    expect(current).toMatch(/^\d{8}$/);
    expect(next).toMatch(/^\d{8}$/);
  });
});

describe("getSecondsRemaining", () => {
  it("should return seconds remaining in current period", () => {
    const code = {
      id: "test",
      type: "totp" as const,
      secret: "JBSWY3DPEHPK3PXP",
      issuer: "Test",
      account: "user",
      length: 6,
      period: 30,
      algorithm: "sha1" as const,
      uriString: "otpauth://totp/Test:user?secret=JBSWY3DPEHPK3PXP",
      codeDisplay: undefined,
    };

    const remaining = getSecondsRemaining(code, 0);

    expect(remaining).toBeGreaterThanOrEqual(0);
    expect(remaining).toBeLessThanOrEqual(30);
  });
});
