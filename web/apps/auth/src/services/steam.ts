import jsSHA from "jssha";
import { Secret } from "otpauth";

/**
 * Steam OTPs.
 *
 * Steam's algorithm is a custom variant of TOTP that uses a 26-character
 * alphabet instead of digits.
 *
 * A Dart implementation of the algorithm can be found in
 * https://github.com/elliotwutingfeng/steam_totp/blob/main/lib/src/steam_totp_base.dart
 * (MIT license), and we use that as a reference. Our implementation is written
 * in the style of the other TOTP/HOTP classes that are provided by the otpauth
 * JS library that we use for the normal TOTP/HOTP generation
 * https://github.com/hectorm/otpauth/blob/master/src/hotp.js (MIT license).
 */
export class Steam {
    secret: Secret;
    period: number;

    constructor({ secret }: { secret: string }) {
        this.secret = Secret.fromBase32(secret);
        this.period = 30;
    }

    generate({ timestamp }: { timestamp: number } = { timestamp: Date.now() }) {
        const counter = Math.floor(timestamp / 1000 / this.period);
        const digest = new Uint8Array(
            sha1HMACDigest(this.secret.buffer), uintToBuf(counter)),
        );

        return `${timestamp}`;
    }
}

// We don't necessarily need this dependency, we could use SubtleCrypto here
// instead too. However, SubtleCrypto has an async interface, and we already
// have a transitive dependency on jssha via otpauth, so just using it here
// doesn't increase our bundle size any further.
const sha1HMACDigest = (key: ArrayBuffer, message: ArrayBuffer) => {
    const hmac = new jsSHA("SHA-1", "ARRAYBUFFER");
    hmac.setHMACKey(key, "ARRAYBUFFER");
    hmac.update(message);
    return hmac.getHMAC("ARRAYBUFFER");
};
