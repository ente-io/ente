/**
 * Steam TOTP implementation.
 * Ported from web/apps/auth/src/services/steam.ts
 *
 * Steam's algorithm is a custom variant of TOTP that uses a 26-character
 * alphabet instead of digits.
 */
import jsSHA from "jssha";
import { Secret } from "otpauth";

export class Steam {
  secret: Secret;
  period: number;

  constructor({ secret }: { secret: string }) {
    this.secret = Secret.fromBase32(secret);
    this.period = 30;
  }

  generate({ timestamp }: { timestamp: number } = { timestamp: Date.now() }) {
    // Same as regular TOTP.
    const counter = Math.floor(timestamp / 1000 / this.period);

    // Same as regular HOTP, but algorithm is fixed to SHA-1.
    const digest = sha1HMACDigest(this.secret.buffer, uintToArray(counter));

    // Same calculation as regular HOTP.
    const offset = digest[digest.length - 1]! & 15;
    let otp =
      ((digest[offset]! & 127) << 24) |
      ((digest[offset + 1]! & 255) << 16) |
      ((digest[offset + 2]! & 255) << 8) |
      (digest[offset + 3]! & 255);

    // However, instead of using this as the OTP, use it to index into
    // the steam OTP alphabet.
    const alphabet = "23456789BCDFGHJKMNPQRTVWXY";
    const N = alphabet.length;
    const steamOTP = [];
    for (let i = 0; i < 5; i++) {
      steamOTP.push(alphabet[otp % N]);
      otp = Math.trunc(otp / N);
    }
    return steamOTP.join("");
  }
}

/**
 * Convert a number to an 8-byte array (big-endian).
 */
const uintToArray = (n: number): Uint8Array => {
  const result = new Uint8Array(8);
  for (let i = 7; i >= 0; i--) {
    result[i] = n & 255;
    n >>= 8;
  }
  return result;
};

/**
 * Calculate SHA-1 HMAC digest.
 */
const sha1HMACDigest = (key: ArrayBuffer, message: Uint8Array): Uint8Array => {
  const hmac = new jsSHA("SHA-1", "UINT8ARRAY");
  hmac.setHMACKey(key, "ARRAYBUFFER");
  hmac.update(message);
  return hmac.getHMAC("UINT8ARRAY");
};
