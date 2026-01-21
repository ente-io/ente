/**
 * OTP generation utilities.
 * Ported from apps/auth/src/services/code.ts.
 */
import { HOTP, TOTP } from "otpauth";
import { Steam } from "./steam";
import type { Code } from "./types";

/**
 * Generate a pair of OTPs from the given code.
 *
 * @param code The parsed code data.
 * @param timeOffset Millisecond delta to apply to Date.now for TOTP.
 * @returns [currentOTP, nextOTP]
 */
export const generateOTPs = (
    code: Code,
    timeOffset: number
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
 * Get the remaining seconds until the current OTP expires.
 */
export const getRemainingSeconds = (code: Code, timeOffset: number): number => {
    const timestamp = Date.now() + timeOffset;
    const elapsed = Math.floor(timestamp / 1000) % code.period;
    return code.period - elapsed;
};

/**
 * Get the progress (0-1) through the current OTP period.
 * Uses millisecond precision for smooth animation.
 */
export const getProgress = (code: Code, timeOffset: number): number => {
    const periodMs = code.period * 1000;
    const timestamp = Date.now() + timeOffset;
    const timeRemaining = periodMs - (timestamp % periodMs);
    return timeRemaining / periodMs;
};
