/**
 * @file Cryptographic operations for Ente web apps.
 *
 * Each function loads the WebAssembly backend on first use (so all are async)
 * and runs on the calling thread; run heavy operations from a Web Worker to
 * keep the UI responsive.
 */
import { loadWasmCore } from "./load";

/**
 * The result of {@link encryptBox}: the secretbox ciphertext and the randomly
 * generated nonce needed to decrypt it.
 */
export interface EncryptedBox {
    /** The encrypted data, a libsodium secretbox (`MAC ‖ ciphertext`). */
    encryptedData: Uint8Array;
    /**
     * The nonce generated during encryption. Required for decryption; not
     * secret.
     */
    nonce: Uint8Array;
}

/**
 * Encrypt `data` with `key` using XSalsa20-Poly1305 authenticated encryption
 * (libsodium's secretbox), generating a random nonce.
 *
 * Use {@link decryptBox} to decrypt the result.
 *
 * @param data The bytes to encrypt.
 * @param key A 32-byte secretbox key.
 * @returns The ciphertext and the generated nonce.
 */
export const encryptBox = async (
    data: Uint8Array,
    key: Uint8Array,
): Promise<EncryptedBox> => {
    const wasm = await loadWasmCore();
    const box = wasm.encryptBox(data, key);
    try {
        return { encryptedData: box.encryptedData, nonce: box.nonce };
    } finally {
        box.free();
    }
};

/**
 * Decrypt data encrypted with {@link encryptBox}.
 *
 * @param data The secretbox ciphertext (`MAC ‖ ciphertext`).
 * @param nonce The nonce produced during encryption.
 * @param key The 32-byte secretbox key used to encrypt.
 * @returns The decrypted bytes.
 */
export const decryptBox = async (
    data: Uint8Array,
    nonce: Uint8Array,
    key: Uint8Array,
): Promise<Uint8Array> => {
    const wasm = await loadWasmCore();
    return wasm.decryptBox(data, nonce, key);
};
