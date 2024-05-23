import { ensure } from "@/utils/ensure";
import { HOTP, TOTP } from "otpauth";

/**
 * A parsed representation of an *OTP code URI.
 *
 * This is all the data we need to drive a OTP generator.
 */
export interface Code {
    /** A unique id for the corresponding "auth entity" in our system. */
    id?: String;
    /** The type of the code. */
    type: "totp" | "hotp";
    /** The user's account or email for which this code is used. */
    account: string;
    /** The name of the entity that issued this code. */
    issuer: string;
    /** Number of digits in the generated OTP. */
    digits: number;
    /**
     * The time period (in seconds) for which a single OTP generated from this
     * code remains valid.
     */
    period: number;
    /**
     * The secret that is used to drive the OTP generator.
     *
     * This is an arbitrary key encoded in Base32 that drives the HMAC (in a
     * {@link type}-specific manner).
     */
    secret: string;
    /** The (HMAC) algorithm used by the OTP generator. */
    algorithm: "sha1" | "sha256" | "sha512";
    /** The original string from which this code was generated. */
    uriString: string;
}

/**
 * Convert a OTP code URI into its parse representation, a {@link Code}.
 *
 * @param id A unique ID of this code within the auth app.
 *
 * @param uriString A string specifying how to generate a TOTP/HOTP/Steam OTP
 * code. These strings are of the form:
 *
 * - (TOTP)
 *   otpauth://totp/ACME:user@example.org?algorithm=SHA1&digits=6&issuer=acme&period=30&secret=ALPHANUM
 */
export const codeFromURIString = (id: string, uriString: string): Code => {
    const url = new URL(uriString);

    return {
        id,
        type: parseType(url),
        account: _getAccount(uriPath),
        issuer: _getIssuer(uriPath, uriParams),
        digits: parseDigits(url),
        period: parsePeriod(url),
        secret: parseSecret(url),
        algorithm: parseAlgorithm(url),
        uriString,
    };
};

const parseType = (url: URL): Code["type"] => {
    const t = url.host.toLowerCase();
    if (t == "totp" || t == "hotp") return t;
    throw new Error(`Unsupported code with host ${t}`);
};

const _getAccount = (uriPath: string): string => {
    try {
        const path = decodeURIComponent(uriPath);
        if (path.includes(":")) {
            return path.split(":")[1];
        } else if (path.includes("/")) {
            return path.split("/")[1];
        }
    } catch (e) {
        return "";
    }
};

const _getIssuer = (uriPath: string, uriParams: { get?: any }): string => {
    try {
        if (uriParams["issuer"] !== undefined) {
            let issuer = uriParams["issuer"];
            // This is to handle bug in the ente auth app
            if (issuer.endsWith("period")) {
                issuer = issuer.substring(0, issuer.length - 6);
            }
            return issuer;
        }
        let path = decodeURIComponent(uriPath);
        if (path.startsWith("totp/") || path.startsWith("hotp/")) {
            path = path.substring(5);
        }
        if (path.includes(":")) {
            return path.split(":")[0];
        } else if (path.includes("-")) {
            return path.split("-")[0];
        }
        return path;
    } catch (e) {
        return "";
    }
};

const parseDigits = (url: URL): number =>
    parseInt(url.searchParams.get("digits") ?? "", 10) || 6;

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

const parseSecret = (url: URL): string =>
    ensure(url.searchParams.get("secret")).replaceAll(" ", "").toUpperCase();

/**
 * Generate a pair of OTPs (one time passwords) from the given {@link code}.
 *
 * @param code The parsed code data, including the secret and code type.
 *
 * @returns a pair of OTPs, the current one and the next one, using the given
 * {@link code}.
 */
export const generateOTPs = (code: Code): [otp: string, nextOTP: string] => {
    let otp: string;
    let nextOTP: string;
    switch (code.type) {
        case "totp": {
            const totp = new TOTP({
                secret: code.secret,
                algorithm: code.algorithm,
                period: code.period,
                digits: code.digits,
            });
            otp = totp.generate();
            nextOTP = totp.generate({
                timestamp: new Date().getTime() + code.period * 1000,
            });
            break;
        }

        case "hotp": {
            const hotp = new HOTP({
                secret: code.secret,
                counter: 0,
                algorithm: code.algorithm,
            });
            otp = hotp.generate();
            nextOTP = hotp.generate({ counter: 1 });
            break;
        }
    }
    return [otp, nextOTP];
};
