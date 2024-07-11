import { safeStorage } from "electron/main";
import { safeStorageStore } from "../stores/safe-storage";
import { uploadStatusStore } from "../stores/upload-status";
import { userPreferences } from "../stores/user-preferences";
import { watchStore } from "../stores/watch";

/**
 * Clear all stores except user preferences.
 *
 * This function is useful to reset state when the user logs out. User
 * preferences are preserved since they contain things tied to the person using
 * the app or other machine specific state not tied to the account they were
 * using inside the app.
 */
export const clearStores = () => {
    safeStorageStore.clear();
    uploadStatusStore.clear();
    watchStore.clear();
};

/**
 * [Note: Safe storage keys]
 *
 * On macOS, `safeStorage` stores our data under a Keychain entry named
 * "<app-name> Safe Storage". In our case, "ente Safe Storage".
 */
export const saveEncryptionKey = (encryptionKey: string) => {
    const encryptedKey = safeStorage.encryptString(encryptionKey);
    const b64EncryptedKey = Buffer.from(encryptedKey).toString("base64");
    safeStorageStore.set("encryptionKey", b64EncryptedKey);
};

export const encryptionKey = (): string | undefined => {
    const b64EncryptedKey = safeStorageStore.get("encryptionKey");
    if (!b64EncryptedKey) return undefined;
    const keyBuffer = Buffer.from(b64EncryptedKey, "base64");
    return safeStorage.decryptString(keyBuffer);
};

export const lastShownChangelogVersion = (): number | undefined =>
    userPreferences.get("lastShownChangelogVersion");

export const setLastShownChangelogVersion = (version: number) =>
    userPreferences.set("lastShownChangelogVersion", version);
