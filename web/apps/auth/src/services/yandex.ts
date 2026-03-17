import jsSHA from "jssha";
import { Secret } from "otpauth";

const defaultDigits = 8;
const defaultPeriod = 30;
const secretLength = 16;
const fullSecretLength = 26;
const checksumPolynomial = 0x18f3;
const yandexAlphabet = "abcdefghijklmnopqrstuvwxyz";
const yandexModulo = yandexAlphabet.length ** defaultDigits;
const textEncoder = new TextEncoder();
const textDecoder = new TextDecoder();

export class Yandex {
    static readonly digits = defaultDigits;
    static readonly period = defaultPeriod;

    secret: Secret;
    pin: string;
    period: number;

    constructor({ secret, pin }: { secret: string; pin: string }) {
        this.secret = Secret.fromBase32(normalizeYandexSecret(secret));
        this.pin = pin;
        this.period = defaultPeriod;
    }

    generate({ timestamp }: { timestamp: number } = { timestamp: Date.now() }) {
        const pinBytes = textEncoder.encode(this.pin);
        const secretBytes = new Uint8Array(this.secret.buffer);
        const pinWithSecret = new Uint8Array(
            pinBytes.length + secretBytes.length,
        );
        pinWithSecret.set(pinBytes, 0);
        pinWithSecret.set(secretBytes, pinBytes.length);

        const keyHash = sha256Digest(pinWithSecret);
        const key = keyHash[0] === 0 ? keyHash.slice(1) : keyHash;

        const counter = Math.floor(timestamp / 1000 / this.period);
        const digest = sha256HMACDigest(
            toArrayBuffer(key),
            uintToArray(counter),
        );
        const offset = digest[digest.length - 1]! & 0x0f;
        const truncated = digest.slice(offset, offset + 8);
        const firstByte = truncated[0];
        if (firstByte == undefined) {
            throw new Error("Unable to derive Yandex OTP");
        }
        truncated[0] = firstByte & 0x7f;

        let otp = 0;
        for (const byte of truncated) {
            otp = (otp * 256 + byte) % yandexModulo;
        }

        const chars = Array.from({ length: defaultDigits });
        for (let i = defaultDigits - 1; i >= 0; i--) {
            chars[i] = yandexAlphabet[otp % yandexAlphabet.length]!;
            otp = Math.trunc(otp / yandexAlphabet.length);
        }
        return chars.join("");
    }
}

export const normalizeYandexSecret = (secret: string): string => {
    const bytes = decodeBase32(secret);
    validateSecret(bytes);
    const normalized =
        bytes.length === secretLength ? bytes : bytes.slice(0, secretLength);
    return new Secret({ buffer: toArrayBuffer(normalized) }).base32;
};

export const parseYandexPin = (pin: string): string => {
    const sanitizedPin = sanitizeBase32(pin);
    if (/^\d{4,16}$/.test(sanitizedPin)) return sanitizedPin;

    const decodedPin = textDecoder.decode(decodeBase32(sanitizedPin));
    if (!/^\d{4,16}$/.test(decodedPin)) {
        throw new Error("Invalid Yandex PIN");
    }

    return decodedPin;
};

const decodeBase32 = (value: string): Uint8Array =>
    new Uint8Array(Secret.fromBase32(sanitizeBase32(value)).buffer);

const toArrayBuffer = (value: Uint8Array): ArrayBuffer => value.slice().buffer;

const sanitizeBase32 = (value: string) =>
    value.trim().replaceAll(" ", "").replaceAll("-", "").toUpperCase();

const validateSecret = (secret: Uint8Array) => {
    if (![secretLength, fullSecretLength].includes(secret.length)) {
        throw new Error(`Invalid Yandex secret length: ${secret.length} bytes`);
    }

    if (secret.length === secretLength) return;

    const originalChecksum =
        ((secret[secret.length - 2]! & 0x0f) << 8) | secret[secret.length - 1]!;

    let accum = 0;
    let accumBits = 0;
    let inputTotalBitsAvailable = secret.length * 8 - 12;
    let inputIndex = 0;
    let inputBitsAvailable = 8;

    while (inputTotalBitsAvailable > 0) {
        let requiredBits = 13 - accumBits;
        if (inputTotalBitsAvailable < requiredBits) {
            requiredBits = inputTotalBitsAvailable;
        }

        while (requiredBits > 0) {
            let curInput =
                secret[inputIndex]! & ((1 << inputBitsAvailable) - 1);
            const bitsToRead = Math.min(requiredBits, inputBitsAvailable);

            curInput >>= inputBitsAvailable - bitsToRead;
            accum = ((accum << bitsToRead) | curInput) & 0xffff;

            inputTotalBitsAvailable -= bitsToRead;
            requiredBits -= bitsToRead;
            inputBitsAvailable -= bitsToRead;
            accumBits += bitsToRead;

            if (inputBitsAvailable === 0) {
                inputIndex += 1;
                inputBitsAvailable = 8;
            }
        }

        if (accumBits === 13) {
            accum ^= checksumPolynomial;
        }
        accumBits = 16 - countLeadingZeros(accum);
    }

    if (accum !== originalChecksum) {
        throw new Error("Yandex secret checksum invalid");
    }
};

const countLeadingZeros = (value: number) => {
    if (value === 0) return 16;

    let n = 0;
    let current = value;
    if ((current & 0xff00) === 0) {
        n += 8;
        current <<= 8;
    }
    if ((current & 0xf000) === 0) {
        n += 4;
        current <<= 4;
    }
    if ((current & 0xc000) === 0) {
        n += 2;
        current <<= 2;
    }
    if ((current & 0x8000) === 0) {
        n += 1;
    }

    return n;
};

const uintToArray = (n: number): Uint8Array => {
    const result = new Uint8Array(8);
    let remaining = n;
    for (let i = 7; i >= 0; i--) {
        result[i] = remaining & 0xff;
        remaining = Math.trunc(remaining / 256);
    }
    return result;
};

const sha256Digest = (message: Uint8Array) => {
    const sha = new jsSHA("SHA-256", "UINT8ARRAY");
    sha.update(message);
    return sha.getHash("UINT8ARRAY");
};

const sha256HMACDigest = (key: ArrayBuffer, message: Uint8Array) => {
    const hmac = new jsSHA("SHA-256", "UINT8ARRAY");
    hmac.setHMACKey(key, "ARRAYBUFFER");
    hmac.update(message);
    return hmac.getHMAC("UINT8ARRAY");
};
