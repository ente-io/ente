import log from "ente-base/log";
import {
    isTauriAppRuntime,
    secureStorageDelete,
    secureStorageGet,
    secureStorageSet,
} from "./secure-storage";
import { ensureCryptoInit, enteWasm } from "./wasm";

/**
 * Session storage key used to store the encrypted master key.
 *
 * This intentionally matches the key name used by other Ente web apps, but note
 * that session storage is origin-scoped, so this does not conflict with other
 * apps.
 */
const MASTER_KEY_SESSION_KEY = "encryptionKey";
const MASTER_KEY_SECURE_STORAGE_KEY = "masterKey";
let _tauriMasterKeyCache: string | undefined;

interface SessionKeyData {
    encryptedData: string;
    key: string;
    nonce: string;
}

const sessionKeyData = async (keyDataB64: string): Promise<SessionKeyData> => {
    await ensureCryptoInit();
    const wasm = await enteWasm();

    const key = await wasm.crypto_generate_key();
    const box = await wasm.crypto_encrypt_box(keyDataB64, key);

    return { encryptedData: box.encrypted_data, nonce: box.nonce, key };
};

/** Return the decrypted master key (base64) from session storage, if present. */
export const masterKeyFromSession = async (): Promise<string | undefined> => {
    if (isTauriAppRuntime()) {
        if (_tauriMasterKeyCache) return _tauriMasterKeyCache;
        try {
            const masterKey = await secureStorageGet(
                MASTER_KEY_SECURE_STORAGE_KEY,
            );
            if (masterKey) {
                _tauriMasterKeyCache = masterKey;
                return masterKey;
            }
        } catch (error) {
            log.warn(
                "Failed to read master key from secure storage during session lookup",
                error,
            );
        }
    }

    const value = sessionStorage.getItem(MASTER_KEY_SESSION_KEY);
    if (!value) return undefined;

    const { encryptedData, key, nonce } = JSON.parse(value) as SessionKeyData;

    await ensureCryptoInit();
    const wasm = await enteWasm();
    const masterKey = await wasm.crypto_decrypt_box(encryptedData, nonce, key);
    if (isTauriAppRuntime()) {
        _tauriMasterKeyCache = masterKey;
    }
    return masterKey;
};

/** Save the master key (base64) in session storage and secure storage on Tauri. */
export const saveMasterKeyInSession = async (masterKeyB64: string) => {
    if (isTauriAppRuntime()) {
        _tauriMasterKeyCache = masterKeyB64;
        try {
            await secureStorageSet(MASTER_KEY_SECURE_STORAGE_KEY, masterKeyB64);
        } catch (error) {
            log.warn("Failed to save master key to secure storage", error);
        }
    }

    sessionStorage.setItem(
        MASTER_KEY_SESSION_KEY,
        JSON.stringify(await sessionKeyData(masterKeyB64)),
    );
};

/** Remove the master key from session storage. */
export const clearMasterKeyFromSession = () => {
    if (isTauriAppRuntime()) {
        _tauriMasterKeyCache = undefined;
    }
    sessionStorage.removeItem(MASTER_KEY_SESSION_KEY);
};

/** Remove the master key from session storage and Tauri secure storage. */
export const clearMasterKeyFromEverywhere = async () => {
    clearMasterKeyFromSession();
    if (isTauriAppRuntime()) {
        try {
            await secureStorageDelete(MASTER_KEY_SECURE_STORAGE_KEY);
        } catch (error) {
            log.warn("Failed to delete master key from secure storage", error);
        }
    }
};

/** Hydrate session storage from Tauri secure storage when possible. */
export const updateSessionFromTauriSecureStorageIfNeeded = async () => {
    if (!isTauriAppRuntime()) return;
    if (_tauriMasterKeyCache) return;

    try {
        const masterKey = await secureStorageGet(MASTER_KEY_SECURE_STORAGE_KEY);
        if (!masterKey) return;
        _tauriMasterKeyCache = masterKey;
    } catch (error) {
        log.warn("Failed to read master key from secure storage", error);
    }
};
