/**
 * @file Authenticated encryption with XSalsa20-Poly1305.
 *
 * SecretBox encrypts and authenticates a single, self-contained value under a
 * 256-bit key. It suits small, independent pieces of data such as a wrapped key
 * or a short field. Ente uses blob for data attached to an object (file or
 * collection metadata and the like), and stream for file contents, which are
 * encrypted in chunks.
 *
 * The name comes from libsodium, which exposes this same construction as
 * `crypto_secretbox`; the implementation here is pure Rust but wire-compatible
 * (recorded per function below).
 *
 * Every message takes a 192-bit nonce. The nonce is not secret, but it must
 * never be reused with the same key (see {@link secretboxEncryptWithNonce}). The
 * {@link secretboxEncrypt} and {@link secretboxEncryptCombined} functions
 * generate a fresh random nonce for you, which is the safe default.
 *
 * Two payload shapes are offered, differing only in how the nonce travels:
 *
 * - Split ({@link secretboxEncrypt} / {@link secretboxDecrypt}): the ciphertext
 *   (`MAC ‖ ct`) and the nonce are returned separately.
 *
 * - Combined ({@link secretboxEncryptCombined} / {@link
 *   secretboxDecryptCombined}): the nonce is prepended to the ciphertext to form
 *   one self-contained buffer (`nonce ‖ MAC ‖ ct`).
 */
import { loadWasmCore } from "./load";
import { Key, Nonce } from "./types";

/**
 * A secretbox ciphertext together with the nonce needed to open it, as returned
 * by {@link secretboxEncrypt}.
 *
 * This is the split shape, with the nonce held separately from the ciphertext;
 * {@link secretboxEncryptCombined} produces the combined alternative.
 */
export interface EncryptedBox {
    /**
     * The Poly1305 tag followed by the ciphertext:
     * `MAC (16 bytes) ‖ ciphertext`.
     */
    encryptedData: Uint8Array;
    /**
     * The nonce that encrypted {@link encryptedData}. Needed to decrypt, and not
     * secret, but never reused with the same key.
     */
    nonce: Nonce;
}

/**
 * Encrypt `data` under `key`, generating a fresh random nonce.
 *
 * This is the default choice for secretbox encryption: a new nonce is generated
 * on every call, so a (key, nonce) pair cannot be reused by mistake. The
 * plaintext is not padded, so the ciphertext length reveals the exact plaintext
 * length.
 *
 * Returns the ciphertext and the generated nonce; decrypt with
 * {@link secretboxDecrypt}.
 *
 * Wire-compatible with libsodium's `crypto_secretbox_easy`.
 */
export const secretboxEncrypt = async (
    data: Uint8Array,
    key: Key,
): Promise<EncryptedBox> => {
    const wasm = await loadWasmCore();
    const box = wasm.secretboxEncrypt(data, key.bytes);
    try {
        return {
            encryptedData: box.encryptedData,
            nonce: Nonce.fromBytes(box.nonce),
        };
    } finally {
        box.free();
    }
};

/**
 * Encrypt `data` under `key` with a caller-supplied `nonce`.
 *
 * Prefer {@link secretboxEncrypt}, which generates the nonce for you. Reach for
 * this only when the nonce is fixed by something else, for example re-creating a
 * ciphertext that must match bytes produced earlier.
 *
 * The nonce must be unique for every message encrypted under a given key.
 * Reusing a (key, nonce) pair is catastrophic: it reveals the XOR of the two
 * plaintexts and makes the Poly1305 tag forgeable, breaking both
 * confidentiality and authenticity. The nonce itself need not be secret.
 *
 * Returns `MAC (16 bytes) ‖ ciphertext`, wire-compatible with libsodium's
 * `crypto_secretbox_easy`.
 */
export const secretboxEncryptWithNonce = async (
    data: Uint8Array,
    nonce: Nonce,
    key: Key,
): Promise<Uint8Array> => {
    const wasm = await loadWasmCore();
    return wasm.secretboxEncryptWithNonce(data, nonce.bytes, key.bytes);
};

/**
 * Decrypt a ciphertext produced by {@link secretboxEncrypt}.
 *
 * Pass the same `nonce` and `key` that encrypted it. `data` is
 * `MAC (16 bytes) ‖ ciphertext`. The Poly1305 tag is verified before any
 * plaintext is returned, so a successful result is also proof that the
 * ciphertext was not altered.
 *
 * Throws if `data` is smaller than the tag, or if the tag does not verify,
 * which is the case whenever the key, nonce, or ciphertext is wrong or the data
 * was tampered with.
 *
 * Wire-compatible with libsodium's `crypto_secretbox_open_easy`.
 */
export const secretboxDecrypt = async (
    data: Uint8Array,
    nonce: Nonce,
    key: Key,
): Promise<Uint8Array> => {
    const wasm = await loadWasmCore();
    return wasm.secretboxDecrypt(data, nonce.bytes, key.bytes);
};

/**
 * Encrypt `data` under `key` into one self-contained buffer.
 *
 * Like {@link secretboxEncrypt}, but prepends a fresh random nonce to the
 * ciphertext, returning `nonce (24 bytes) ‖ MAC (16 bytes) ‖ ciphertext`:
 * everything needed to decrypt except the key. Prefer this when a single opaque
 * blob is easier to store or pass around than a separate ciphertext and nonce.
 * Decrypt with {@link secretboxDecryptCombined}.
 *
 * The `MAC ‖ ciphertext` body is wire-compatible with libsodium's
 * `crypto_secretbox_easy`; prepending the nonce is an Ente convention, not part
 * of libsodium itself.
 */
export const secretboxEncryptCombined = async (
    data: Uint8Array,
    key: Key,
): Promise<Uint8Array> => {
    const wasm = await loadWasmCore();
    return wasm.secretboxEncryptCombined(data, key.bytes);
};

/**
 * Decrypt a combined buffer produced by {@link secretboxEncryptCombined}.
 *
 * Splits the leading nonce from the `MAC ‖ ciphertext` body, then verifies the
 * tag and decrypts as {@link secretboxDecrypt} does.
 *
 * Throws if `data` is too short to hold a nonce and tag, otherwise the same as
 * {@link secretboxDecrypt}.
 *
 * The body is wire-compatible with libsodium's `crypto_secretbox_open_easy`;
 * the leading nonce is an Ente convention.
 */
export const secretboxDecryptCombined = async (
    data: Uint8Array,
    key: Key,
): Promise<Uint8Array> => {
    const wasm = await loadWasmCore();
    return wasm.secretboxDecryptCombined(data, key.bytes);
};
