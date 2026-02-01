/**
 * Minimal Node "crypto" shim for the browser.
 *
 * fast-srp-hap expects `crypto.createHash(..)` (sync) and `crypto.randomBytes(..)`.
 * We implement the small subset needed for SRP using jsSHA + WebCrypto RNG.
 */
import jsSHA from "jssha";
import { Buffer } from "buffer";

// fast-srp-hap uses the global `Buffer` symbol.
if (!(globalThis as any).Buffer) {
  (globalThis as any).Buffer = Buffer;
}

type HashAlg = "sha512" | "sha256";

const normalizeAlg = (algorithm: string): HashAlg => {
  const alg = algorithm.toLowerCase();
  if (alg === "sha512" || alg === "sha256") return alg;
  throw new Error(`Unsupported hash algorithm: ${algorithm}`);
};

export const createHash = (algorithm: string) => {
  const alg = normalizeAlg(algorithm);
  const hashName = alg === "sha512" ? "SHA-512" : "SHA-256";
  const sha = new jsSHA(hashName, "UINT8ARRAY");

  return {
    update(data: Buffer | Uint8Array | string) {
      if (typeof data === "string") {
        sha.update(new TextEncoder().encode(data));
      } else {
        sha.update(data instanceof Uint8Array ? data : new Uint8Array(data));
      }
      return this;
    },
    digest() {
      const out = sha.getHash("UINT8ARRAY") as Uint8Array;
      return Buffer.from(out);
    },
  };
};

export const randomBytes = (
  size: number,
  callback?: (err: Error | null, buf: Buffer | null) => void,
) => {
  try {
    const out = new Uint8Array(size);
    crypto.getRandomValues(out);
    const buf = Buffer.from(out);
    if (callback) {
      callback(null, buf);
      return;
    }
    return buf;
  } catch (e) {
    const err = e instanceof Error ? e : new Error(String(e));
    if (callback) {
      callback(err, null);
      return;
    }
    throw err;
  }
};

export default {
  createHash,
  randomBytes,
};
