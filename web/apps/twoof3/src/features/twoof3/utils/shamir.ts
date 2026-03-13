const GF_POLY = 0x11b;
const VERSION = 1;
const HEADER_LENGTH = 14;
const ID_LENGTH = 6;
const MAX_SECRET_BYTES = 2048;
export const SHARE_PREFIX = "2of3-";

const gfMul = (left: number, right: number) => {
    let result = 0;
    let a = left;
    let b = right;

    while (b > 0) {
        if (b & 1) result ^= a;
        a <<= 1;
        if (a & 0x100) a ^= GF_POLY;
        b >>= 1;
    }

    return result;
};

const gfPow = (value: number, exponent: number) => {
    let result = 1;

    for (let count = 0; count < exponent; count++) {
        result = gfMul(result, value);
    }

    return result;
};

const gfInv = (value: number) => {
    if (value === 0) {
        throw new Error("Cannot divide by zero in GF(256)");
    }

    return gfPow(value, 254);
};

const gfDiv = (left: number, right: number) => {
    if (left === 0) return 0;
    return gfMul(left, gfInv(right));
};

const checksumBytes = (bytes: Uint8Array) => {
    let hash = 0x811c9dc5;

    for (const byte of bytes) {
        hash ^= byte;
        hash = Math.imul(hash, 0x01000193) >>> 0;
    }

    return new Uint8Array([
        (hash >>> 24) & 0xff,
        (hash >>> 16) & 0xff,
        (hash >>> 8) & 0xff,
        hash & 0xff,
    ]);
};

const base64UrlEncode = (bytes: Uint8Array) => {
    let binary = "";
    for (const byte of bytes) {
        binary += String.fromCharCode(byte);
    }

    return btoa(binary)
        .replace(/\+/g, "-")
        .replace(/\//g, "_")
        .replace(/=+$/u, "");
};

const base64UrlLength = (byteLength: number) => {
    const fullGroups = Math.floor(byteLength / 3);
    const remainder = byteLength % 3;
    return fullGroups * 4 + (remainder === 0 ? 0 : remainder + 1);
};

const base64UrlDecode = (value: string) => {
    const padded = value.replace(/-/g, "+").replace(/_/g, "/");
    const normalized = padded + "=".repeat((4 - (padded.length % 4 || 4)) % 4);

    const binary = atob(normalized);
    return Uint8Array.from(binary, (char) => char.charCodeAt(0));
};

const joinBytes = (...chunks: Uint8Array[]) => {
    const totalLength = chunks.reduce((sum, chunk) => sum + chunk.length, 0);
    const output = new Uint8Array(totalLength);
    let offset = 0;

    for (const chunk of chunks) {
        output.set(chunk, offset);
        offset += chunk.length;
    }

    return output;
};

export interface SplitShare {
    encoded: string;
    index: 1 | 2 | 3;
}

export interface ParsedShare {
    checksum: Uint8Array;
    data: Uint8Array;
    encoded: string;
    id: string;
    index: 1 | 2 | 3;
    length: number;
}

export const encodedShareLengthForSecretBytes = (secretByteLength: number) =>
    SHARE_PREFIX.length + base64UrlLength(HEADER_LENGTH + secretByteLength);

export const maxSecretBytesForEncodedShareLength = (maxShareLength: number) => {
    let best = 0;

    for (
        let secretByteLength = 1;
        secretByteLength <= MAX_SECRET_BYTES;
        secretByteLength++
    ) {
        if (
            encodedShareLengthForSecretBytes(secretByteLength) > maxShareLength
        ) {
            break;
        }
        best = secretByteLength;
    }

    return best;
};

export const splitSecret = (secret: string): SplitShare[] => {
    const secretBytes = new TextEncoder().encode(secret);

    if (secretBytes.length === 0) {
        throw new Error("Enter something first.");
    }

    if (secretBytes.length > MAX_SECRET_BYTES) {
        throw new Error("This secret is too large for 2of3.");
    }

    const randomId = crypto.getRandomValues(new Uint8Array(ID_LENGTH));
    const checksum = checksumBytes(secretBytes);
    const coefficients = crypto.getRandomValues(
        new Uint8Array(secretBytes.length),
    );
    const shares = [
        new Uint8Array(secretBytes.length),
        new Uint8Array(secretBytes.length),
        new Uint8Array(secretBytes.length),
    ];

    for (let index = 0; index < secretBytes.length; index++) {
        const secretByte = secretBytes[index]!;
        const coefficient = coefficients[index]!;
        shares[0]![index] = secretByte ^ coefficient;
        shares[1]![index] = secretByte ^ gfMul(coefficient, 2);
        shares[2]![index] = secretByte ^ gfMul(coefficient, 3);
    }

    return shares.map((shareBytes, shareOffset) => {
        const index = (shareOffset + 1) as 1 | 2 | 3;
        const header = new Uint8Array([
            VERSION,
            index,
            (secretBytes.length >>> 8) & 0xff,
            secretBytes.length & 0xff,
        ]);

        const payload = joinBytes(header, randomId, checksum, shareBytes);
        return { encoded: `${SHARE_PREFIX}${base64UrlEncode(payload)}`, index };
    });
};

export const parseShare = (input: string): ParsedShare => {
    const encoded = input.trim();
    if (!encoded.startsWith(SHARE_PREFIX)) {
        throw new Error("That code does not look like a 2of3 share.");
    }

    const payload = base64UrlDecode(encoded.slice(SHARE_PREFIX.length));
    if (payload.length <= HEADER_LENGTH) {
        throw new Error("That share looks incomplete.");
    }

    const version = payload[0];
    const index = payload[1];
    const length = ((payload[2] ?? 0) << 8) | (payload[3] ?? 0);

    if (version !== VERSION) {
        throw new Error("This share was created by a newer format.");
    }

    if (index !== 1 && index !== 2 && index !== 3) {
        throw new Error("This share number is invalid.");
    }

    if (payload.length !== HEADER_LENGTH + length) {
        throw new Error("This share was cut off.");
    }

    const idBytes = payload.slice(4, 10);
    const checksum = payload.slice(10, 14);
    const data = payload.slice(14);

    return {
        checksum,
        data,
        encoded,
        id: base64UrlEncode(idBytes),
        index,
        length,
    };
};

export const combineShares = (firstInput: string, secondInput: string) => {
    const first = parseShare(firstInput);
    const second = parseShare(secondInput);

    if (first.id !== second.id || first.length !== second.length) {
        throw new Error(
            "These two cards are from different sets. Match the # on both cards.",
        );
    }

    if (first.index === second.index) {
        throw new Error("Use two different cards from the same set.");
    }

    const output = new Uint8Array(first.length);
    const denominator = first.index ^ second.index;

    for (let index = 0; index < first.length; index++) {
        const left = gfMul(
            first.data[index]!,
            gfDiv(second.index, denominator),
        );
        const right = gfMul(
            second.data[index]!,
            gfDiv(first.index, denominator),
        );
        output[index] = left ^ right;
    }

    const expectedChecksum = checksumBytes(output);
    if (
        expectedChecksum.some(
            (byte, index) =>
                byte !== first.checksum[index] ||
                byte !== second.checksum[index],
        )
    ) {
        throw new Error("These shares did not reconstruct a valid secret.");
    }

    return new TextDecoder().decode(output);
};
