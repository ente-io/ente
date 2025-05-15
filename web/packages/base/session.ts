import { z } from "zod";
import { decryptBox } from "./crypto";
import { toB64 } from "./crypto/libsodium";

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

/**
 * Save the user's encrypted master key in the session storage.
 *
 * @param keyB64 The user's master key as a base64 encoded string.
 */
// TODO(RE):
// export const saveMasterKeyInSessionStore = async (
//     keyB64: string,
//     fromDesktop?: boolean,
// ) => {
//     const cryptoWorker = await sharedCryptoWorker();
//     const sessionKeyAttributes =
//         await cryptoWorker.generateKeyAndEncryptToB64(key);
//     setKey(keyType, sessionKeyAttributes);
//     const electron = globalThis.electron;
//     if (electron && !fromDesktop) {
//         electron.saveMasterKeyB64(key);
//     }
// };

/**
 * Return the user's decrypted master key from session storage.
 *
 * Precondition: The user should be logged in.
 */
export const masterKeyFromSession = async () => {
    const key = await masterKeyFromSessionIfLoggedIn();
    if (key) {
        return key;
    } else {
        throw new Error(
            "The user's master key was not found in session storage. Likely they are not logged in.",
        );
    }
};

/**
 * Return `true` if the user's encrypted master key is present in the session.
 *
 * Use {@link masterKeyFromSessionIfLoggedIn} to get the actual master key after
 * decrypting it. This function is instead useful as a quick check to verify if
 * we have credentials at hand or not.
 */
export const haveCredentialsInSession = () =>
    !!sessionStorage.getItem("encryptionKey");

/**
 * Return the decrypted user's master key from session storage if they are
 * logged in, otherwise return `undefined`.
 */
export const masterKeyFromSessionIfLoggedIn = async () => {
    // TODO: Same value as the deprecated getKey("encryptionKey")
    const value = sessionStorage.getItem("encryptionKey");
    if (!value) return undefined;

    const { encryptedData, key, nonce } = SessionKeyData.parse(
        JSON.parse(value),
    );
    return decryptBox({ encryptedData, nonce }, key);
};

/**
 * Variant of {@link masterKeyFromSession} that returns the master key as a
 * base64 string.
 */
export const masterKeyB64FromSession = () => masterKeyFromSession().then(toB64);

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
    return decryptBox({ encryptedData, nonce }, key);
};
