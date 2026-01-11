/**
 * TOTP/HOTP code parsing and generation.
 * Ported from web/apps/auth/src/services/code.ts
 */
import { HOTP, TOTP } from "otpauth";
import { z } from "zod";
import type { Code, CodeDisplay } from "../types/code";
import { Steam } from "./steam";

/**
 * Zod schema for CodeDisplay.
 */
const CodeDisplaySchema = z.object({
  trashed: z
    .boolean()
    .nullish()
    .transform((v) => v ?? undefined),
  pinned: z
    .boolean()
    .nullish()
    .transform((v) => v ?? undefined),
  note: z
    .string()
    .nullish()
    .transform((v) => v ?? undefined),
});

/**
 * Convert a OTP code URI into its parsed representation.
 *
 * @param id - Unique ID of this code
 * @param uriString - OTPAuth URI string (e.g., otpauth://totp/...)
 */
export const codeFromURIString = (id: string, uriString: string): Code => {
  try {
    return _codeFromURIString(id, uriString);
  } catch (e) {
    // Handle legacy encodings with "#" characters
    if (uriString.includes("#")) {
      return _codeFromURIString(id, uriString.replaceAll("#", "%23"));
    }
    throw e;
  }
};

const _codeFromURIString = (id: string, uriString: string): Code => {
  const url = new URL(uriString);
  const [type, path] = parsePathname(url);

  return {
    id,
    type,
    account: parseAccount(path),
    issuer: parseIssuer(url, path),
    length: parseLength(url, type),
    period: parsePeriod(url),
    algorithm: parseAlgorithm(url),
    counter: parseCounter(url),
    secret: parseSecret(url),
    codeDisplay: parseCodeDisplay(url),
    uriString,
  };
};

const parsePathname = (url: URL): [type: Code["type"], path: string] => {
  // Handle browser differences in URL parsing
  switch (url.host.toLowerCase()) {
    case "totp":
      return ["totp", url.pathname.toLowerCase()];
    case "hotp":
      return ["hotp", url.pathname.toLowerCase()];
    case "steam":
      return ["steam", url.pathname.toLowerCase()];
    default:
      break;
  }

  const p = url.pathname.toLowerCase();
  if (p.startsWith("//totp")) return ["totp", url.pathname.slice(6)];
  if (p.startsWith("//hotp")) return ["hotp", url.pathname.slice(6)];
  if (p.startsWith("//steam")) return ["steam", url.pathname.slice(7)];

  throw new Error(`Unsupported code or unparseable path "${url.pathname}"`);
};

const parseAccount = (path: string): string | undefined => {
  let p = decodeURIComponent(path);
  if (p.startsWith("/")) p = p.slice(1);
  if (p.includes(":")) p = p.split(":").slice(1).join(":");
  return p;
};

const parseIssuer = (url: URL, path: string): string => {
  let issuer = url.searchParams.get("issuer");
  if (issuer) {
    // Handle bug in old versions of Ente Auth app
    if (issuer.endsWith("period")) {
      issuer = issuer.substring(0, issuer.length - 6);
    }
    return issuer;
  }

  // Use prefix from account as issuer
  let p = decodeURIComponent(path);
  if (p.startsWith("/")) p = p.slice(1);

  if (p.includes(":")) p = p.split(":")[0]!;
  else if (p.includes("-")) p = p.split("-")[0]!;

  return p;
};

const parseLength = (url: URL, type: Code["type"]): number => {
  const defaultLength = type === "steam" ? 5 : 6;
  return parseInt(url.searchParams.get("digits") ?? "", 10) || defaultLength;
};

const parsePeriod = (url: URL): number =>
  parseInt(url.searchParams.get("period") ?? "", 10) || 30;

const parseAlgorithm = (url: URL): Code["algorithm"] => {
  switch (url.searchParams.get("algorithm")?.toLowerCase()) {
    case "sha256":
      return "sha256";
    case "sha512":
      return "sha512";
    default:
      return "sha1";
  }
};

const parseCounter = (url: URL): number | undefined => {
  const c = url.searchParams.get("counter");
  return c ? parseInt(c, 10) : undefined;
};

const parseSecret = (url: URL): string =>
  url.searchParams.get("secret")!.replaceAll(" ", "").toUpperCase();

const parseCodeDisplay = (url: URL): CodeDisplay | undefined => {
  const s = url.searchParams.get("codeDisplay");
  if (!s) return undefined;

  try {
    return CodeDisplaySchema.parse(JSON.parse(s));
  } catch (e) {
    console.error(`Ignoring unparseable code display ${s}`, e);
    return undefined;
  }
};

/**
 * Generate a pair of OTPs from the given code.
 *
 * @param code - The parsed code data
 * @param timeOffset - Millisecond delta to apply to Date.now
 * @returns A tuple of [current OTP, next OTP]
 */
export const generateOTPs = (
  code: Code,
  timeOffset: number,
): [otp: string, nextOTP: string] => {
  let otp: string;
  let nextOTP: string;
  const timestamp = Date.now() + timeOffset;

  switch (code.type) {
    case "totp": {
      const totp = new TOTP({
        secret: code.secret,
        algorithm: code.algorithm.toUpperCase() as "SHA1" | "SHA256" | "SHA512",
        period: code.period,
        digits: code.length,
      });
      otp = totp.generate({ timestamp });
      nextOTP = totp.generate({
        timestamp: timestamp + code.period * 1000,
      });
      break;
    }

    case "hotp": {
      const counter = code.counter ?? 0;
      const hotp = new HOTP({
        secret: code.secret,
        counter: counter,
        algorithm: code.algorithm.toUpperCase() as "SHA1" | "SHA256" | "SHA512",
      });
      otp = hotp.generate({ counter });
      nextOTP = hotp.generate({ counter: counter + 1 });
      break;
    }

    case "steam": {
      const steam = new Steam({ secret: code.secret });
      otp = steam.generate({ timestamp });
      nextOTP = steam.generate({
        timestamp: timestamp + code.period * 1000,
      });
      break;
    }
  }

  return [otp, nextOTP];
};

/**
 * Calculate seconds remaining until code expires.
 */
export const getSecondsRemaining = (
  code: Code,
  timeOffset: number,
): number => {
  const timestamp = Date.now() + timeOffset;
  const elapsed = (timestamp / 1000) % code.period;
  return Math.ceil(code.period - elapsed);
};

/**
 * Sort codes: pinned first, then alphabetically by issuer.
 */
export const sortCodes = (codes: Code[]): Code[] => {
  return [...codes].sort((a, b) => {
    // Pinned codes first
    if (a.codeDisplay?.pinned && !b.codeDisplay?.pinned) return -1;
    if (!a.codeDisplay?.pinned && b.codeDisplay?.pinned) return 1;

    // Then alphabetically by issuer
    if (a.issuer && b.issuer) {
      return a.issuer.localeCompare(b.issuer);
    }
    if (a.issuer) return -1;
    if (b.issuer) return 1;
    return 0;
  });
};

/**
 * Filter codes by search query.
 */
export const filterCodes = (codes: Code[], query: string): Code[] => {
  const q = query.toLowerCase().trim();
  if (!q) return codes;

  return codes.filter((code) => {
    const issuer = code.issuer?.toLowerCase() ?? "";
    const account = code.account?.toLowerCase() ?? "";
    const note = code.codeDisplay?.note?.toLowerCase() ?? "";
    return issuer.includes(q) || account.includes(q) || note.includes(q);
  });
};
