import { z } from "zod/v4";
import { decryptBox, decryptBoxBytes, encryptBox, generateKey } from "./crypto";

/**
 * Remove all data stored in session storage (data tied to the browser tab).
 *
 * See `docs/storage.md` for more details about session storage. Currently, only
 * the following entries are stored in session storage:
 *
 * - "encryptionKey"
 * - "keyEncryptionKey" (transient)
 */
export const clearSessionStorage = () => sessionStorage.clear();

/**
 * Schema of JSON string value for the "encryptionKey" and "keyEncryptionKey"
 * keys strings stored in session storage.
 */
const SessionKeyData = z.object({
    encryptedData: z.string(),
    key: z.string(),
    nonce: z.string(),
});

type SessionKeyData = z.infer<typeof SessionKeyData>;

const sessionKeyData = async (keyData: string): Promise<SessionKeyData> => {
    const key = await generateKey();
    const box = await encryptBox(keyData, key);
    return { key, ...box };
};

/**
 * Return the user's decrypted master key (as a base64 string) from session
 * storage, or throw if the session storage does not have the master key (which
 * likely indicates that the user is not logged in).
 */
export const ensureMasterKeyFromSession = async () => {
    const key = await masterKeyFromSession();
    if (!key) throw new Error("Master key not found in session");
    return key;
};

/**
 * Return `true` if the user's encrypted master key is present in the session.
 *
 * Use {@link masterKeyFromSession} to get the actual master key after
 * decrypting it. This function is a similar but quicker check to verify if we
 * have credentials at hand or not, however it doesn't attempt to verify that
 * the key present in the session can actually be decrypted.
 */
export const haveCredentialsInSession = () =>
    !!sessionStorage.getItem("encryptionKey");

/**
 * Return the decrypted user's master key (as a base64 string) from session
 * storage if they are logged in, otherwise return `undefined`.
 *
 * See also {@link ensureMasterKeyFromSession}, which is usually what we need.
 */
export const masterKeyFromSession = async () => {
    // TODO: Same value as the deprecated getKey("encryptionKey")
    const value = sessionStorage.getItem("encryptionKey");
    if (!value) return undefined;

    const { encryptedData, key, nonce } = SessionKeyData.parse(
        JSON.parse(value),
    );
    return decryptBox({ encryptedData, nonce }, key);
};

/**
 * Save the user's encrypted master key in the session storage.
 *
 * @param masterKey The user's master key (as a base64 encoded string).
 */
export const saveMasterKeyInSessionStore = async (
    masterKey: string,
    // TODO: ?
    fromDesktop?: boolean,
) => {
    await saveKeyInSessionStore("encryptionKey", masterKey);
    const electron = globalThis.electron;
    if (electron && !fromDesktop) {
        await electron.saveMasterKeyB64(masterKey);
    }
};

/**
 * Save the provided key in session storage.
 *
 * @param keyName The name of the key use for the session storage entry.
 *
 * @param keyData The base64 encoded bytes of the key.
 */
const saveKeyInSessionStore = async (keyName: string, keyData: string) => {
    sessionStorage.setItem(
        keyName,
        JSON.stringify(await sessionKeyData(keyData)),
    );
};

/**
 * Return the decrypted user's key encryption key ("kek") from session storage
 * if present, otherwise return `undefined`.
 *
 * [Note: Stashing kek in session store]
 *
 * During login, if the user has set a second factor (passkey or TOTP), then we
 * need to redirect them to the accounts app or TOTP page to verify the second
 * factor. This second factor verification happens after password verification,
 * but simply storing the decrypted kek in-memory wouldn't work because the
 * second factor redirect can happen to a separate accounts app altogether.
 *
 * So instead, we stash the encrypted kek in session store (using
 * {@link stashKeyEncryptionKeyInSessionStore}), and after redirect, retrieve
 * it (after clearing it) using {@link unstashKeyEncryptionKeyFromSession}.
 */
export const unstashKeyEncryptionKeyFromSession = async () => {
    // TODO: Same value as the deprecated getKey("keyEncryptionKey")
    const value = sessionStorage.getItem("keyEncryptionKey");
    if (!value) return undefined;

    sessionStorage.removeItem("keyEncryptionKey");

    const { encryptedData, key, nonce } = SessionKeyData.parse(
        JSON.parse(value),
    );
    return decryptBoxBytes({ encryptedData, nonce }, key);
};
