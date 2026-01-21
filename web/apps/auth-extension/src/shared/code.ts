/**
 * Code parsing and management.
 * Ported from apps/auth/src/services/code.ts.
 */
import { z } from "zod";
import type { Code, CodeDisplay } from "./types";

const nullToUndefined = <T>(val: T | null | undefined): T | undefined =>
    val === null ? undefined : val;

const CodeDisplaySchema = z.object({
    trashed: z.boolean().nullish().transform(nullToUndefined),
    pinned: z.boolean().nullish().transform(nullToUndefined),
    note: z.string().nullish().transform(nullToUndefined),
});

/**
 * Convert an OTP code URI into its parsed representation.
 */
export const codeFromURIString = (id: string, uriString: string): Code => {
    try {
        return _codeFromURIString(id, uriString);
    } catch (e) {
        // Handle legacy encodings with "#" that cause URL parsing issues.
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
    // Handle browser-specific URL parsing differences.
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
        // Handle bug in old versions of Ente Auth app.
        if (issuer.endsWith("period")) {
            issuer = issuer.substring(0, issuer.length - 6);
        }
        return issuer;
    }

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
    } catch {
        console.error(`Ignoring unparseable code display: ${s}`);
        return undefined;
    }
};

/**
 * Format an OTP code for display (e.g., "123 456").
 */
export const prettyFormatCode = (code: string): string => {
    if (code.length === 6) {
        return `${code.slice(0, 3)} ${code.slice(3)}`;
    }
    return code;
};
