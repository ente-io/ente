import { z } from "zod/v4";
import { decryptBox, encryptBox, generateKey } from "./crypto";
import log from "./log";

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
export const haveMasterKeyInSession = () =>
    !!sessionStorage.getItem("encryptionKey");

/**
 * Return the decrypted user's master key (as a base64 string) from session
 * storage if they are logged in, otherwise return `undefined`.
 *
 * See also {@link ensureMasterKeyFromSession}, which is usually what we need.
 */
export const masterKeyFromSession = async () => {
    const value = sessionStorage.getItem("encryptionKey");
    if (!value) return undefined;

    const { encryptedData, key, nonce } = SessionKeyData.parse(
        JSON.parse(value),
    );
    return decryptBox({ encryptedData, nonce }, key);
};

/**
 * Save the user's encrypted master key in the session storage. If we're running
 * in the context of our desktop app, also save it in the OS safe storage.
 *
 * See: [Note: Safe storage and interactive KEK attributes]
 *
 * @param masterKey The user's master key (as a base64 encoded string).
 */
export const saveMasterKeyInSessionAndSafeStore = async (masterKey: string) => {
    await saveKeyInSessionStore("encryptionKey", masterKey);
    try {
        await globalThis.electron?.saveMasterKeyInSafeStorage(masterKey);
    } catch (e) {
        // [Note: Safe storage is best effort]
        //
        // The user might be running on an OS which does not provide secure
        // storage. Practically this is rare, but it can happen, especially on
        // Linux if the app is run in a desktop environment without libsecret.
        //
        // So intercept failures to read and write to safe storage, and
        // gracefully degrade to how the web app behaves (ask the user for their
        // password in each session).
        log.warn("Failed to save master key in safe storage", e);
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
 * If we're running in the context of the desktop app, then read the master key
 * from the OS safe storage and put it into the session storage (if it is not
 * already present there).
 *
 * [Note: Safe storage and interactive KEK attributes]
 *
 * In the electron app we have the option of using the OS's safe storage (if
 * available) to store the master key so that the user does not have to reenter
 * their password each time they open the app.
 *
 * Such an ability is not present on browsers currently, so we need to ask the
 * user for their password to derive the KEK for decrypting their master key
 * each time they open the app in a new time (See: [Note: Key encryption key]).
 *
 * However, the default KEK parameters are not suitable for such frequent
 * interactive usage. So for the user's convenience, we also derive an new (so
 * called "intermediate") KEK using parameters suitable for interactive usage.
 * This KEK is not saved to remote, it is only maintained locally.
 *
 * In either case, eventually we want the encrypted key to be available in the
 * session for decrypting the user's files etc. In the web case, the page where
 * the user reenters their password will put it there, while on desktop
 * (assuming the key has already been saved to the OS safe storage), this
 * {@link updateSessionFromElectronSafeStorageIfNeeded} function will do it.
 */
export const updateSessionFromElectronSafeStorageIfNeeded = async () => {
    const electron = globalThis.electron;
    if (!electron) return;

    if (haveMasterKeyInSession()) return;

    let masterKey: string | undefined;
    try {
        masterKey = await electron.masterKeyFromSafeStorage();
    } catch (e) {
        // See: [Note: Safe storage is best effort]
        log.warn("Failed to read master key from safe storage", e);
    }
    if (masterKey) {
        await saveKeyInSessionStore("encryptionKey", masterKey);
    }
};

/**
 * Save the user's encypted key encryption key ("key") in session store
 * temporarily, until we get back here after completing the second factor.
 *
 * See:  [Note: Stashing KEK in session store]
 *
 * @param kek The user's key encryption key (as a base64 string).
 */
export const stashKeyEncryptionKeyInSessionStore = (kek: string) =>
    saveKeyInSessionStore("keyEncryptionKey", kek);

/**
 * Return the decrypted user's key encryption key ("KEK") from session storage
 * if present, otherwise return `undefined`.
 *
 * The key (if it was present) is also removed from session storage.
 *
 * @returns the previously stashed key (if any) as a base64 string.
 *
 * [Note: Stashing KEK in session store]
 *
 * During login, if the user has set a second factor (passkey or TOTP), then we
 * need to redirect them to the accounts app or TOTP page to verify the second
 * factor. This second factor verification happens after password verification,
 * but simply storing the decrypted KEK in-memory wouldn't work because the
 * second factor redirect can happen to a separate accounts app altogether.
 *
 * So instead, we stash the encrypted KEK in session store (using
 * {@link stashKeyEncryptionKeyInSessionStore}), and after redirect, retrieve it
 * (after clearing it) using {@link unstashKeyEncryptionKeyFromSession}.
 */
export const unstashKeyEncryptionKeyFromSession = async () => {
    const value = sessionStorage.getItem("keyEncryptionKey");
    if (!value) return undefined;

    sessionStorage.removeItem("keyEncryptionKey");

    const { encryptedData, key, nonce } = SessionKeyData.parse(
        JSON.parse(value),
    );
    return decryptBox({ encryptedData, nonce }, key);
};
