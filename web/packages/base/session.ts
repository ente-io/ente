import { getToken } from "ente-shared/storage/localStorage/helpers";
import { z } from "zod/v4";
import { decryptBox, decryptBoxBytes, encryptBox, generateKey } from "./crypto";
import { isDevBuild } from "./env";
import log from "./log";
import { getAuthToken } from "./token";

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
        await electron.saveMasterKeyInSafeStorage(masterKey);
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

    if (haveCredentialsInSession()) return;

    let masterKey: string | undefined;
    try {
        masterKey = await electron.masterKeyFromSafeStorage();
    } catch (e) {
        log.error("Failed to read master key from safe storage", e);
    }
    if (masterKey) {
        // Do not use `saveMasterKeyInSessionStore`, that will (unnecessarily)
        // overwrite the OS safe storage again.
        await saveKeyInSessionStore("encryptionKey", masterKey);
    }
};

/**
 * Return true if we both have the user's master key in session storage, and
 * their auth token in KV DB.
 */
export const haveAuthenticatedSession = async () => {
    if (!(await masterKeyFromSession())) return false;
    const lsToken = getToken();
    const kvToken = await getAuthToken();
    // TODO: To avoid changing old behaviour, this currently relies on the token
    // from local storage. Both should be the same though, so it throws an error
    // on dev build (tag: Migration).
    if (isDevBuild) {
        if (lsToken != kvToken)
            throw new Error("Local storage and indexed DB mismatch");
    }
    return !!lsToken;
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
