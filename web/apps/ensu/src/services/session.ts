import { ensureCryptoInit, enteWasm } from "./wasm";

/**
 * Session storage key used to store the encrypted master key.
 *
 * This intentionally matches the key name used by other Ente web apps, but note
 * that session storage is origin-scoped, so this does not conflict with other
 * apps.
 */
const MASTER_KEY_SESSION_KEY = "encryptionKey";

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
    const value = sessionStorage.getItem(MASTER_KEY_SESSION_KEY);
    if (!value) return undefined;

    const { encryptedData, key, nonce } = JSON.parse(value) as SessionKeyData;

    await ensureCryptoInit();
    const wasm = await enteWasm();
    return await wasm.crypto_decrypt_box(encryptedData, nonce, key);
};

/** Save the master key (base64) in session storage. */
export const saveMasterKeyInSession = async (masterKeyB64: string) => {
    sessionStorage.setItem(
        MASTER_KEY_SESSION_KEY,
        JSON.stringify(await sessionKeyData(masterKeyB64)),
    );
};

/** Remove the master key from session storage. */
export const clearMasterKeyFromSession = () => {
    sessionStorage.removeItem(MASTER_KEY_SESSION_KEY);
};
