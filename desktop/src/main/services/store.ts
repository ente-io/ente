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
export const saveMasterKeyInSafeStorage = (masterKey: string) => {
    const encryptedKeyBuffer = safeStorage.encryptString(masterKey);
    const encryptedKey = Buffer.from(encryptedKeyBuffer).toString("base64");
    safeStorageStore.set("encryptionKey", encryptedKey);
};

export const masterKeyFromSafeStorage = (): string | undefined => {
    const encryptedKey = safeStorageStore.get("encryptionKey");
    if (!encryptedKey) return undefined;
    const encryptedKeyBuffer = Buffer.from(encryptedKey, "base64");
    return safeStorage.decryptString(encryptedKeyBuffer);
};

export const lastShownChangelogVersion = (): number | undefined =>
    userPreferences.get("lastShownChangelogVersion");

export const setLastShownChangelogVersion = (version: number) =>
    userPreferences.set("lastShownChangelogVersion", version);

/**
 * Return true if the dock icon should be hidden when the window is closed
 * [macOS only].
 *
 * On macOS, if this function returns true then when hiding ("closing" it with
 * the x traffic light) the window we also hide the app's icon in the dock. The
 * user can modify their preference using the Menu bar > ente > Settings > Hide
 * dock icon checkbox.
 *
 * If the user has not set a value for this preference (i.e., the value is
 * `undefined`), we use the default `true`. This is confusing, but this way we
 * can retain the preexisting preference key instead of doing a migration.
 *
 *     Value     | Behaviour
 *     ----------|--------------
 *     undefined |  default (hide)
 *     false     |  show
 *     true      |  hide
 *
 * On non-macOS platforms, it always returns false.
 */
export const shouldHideDockIcon = (): boolean =>
    process.platform == "darwin" &&
    userPreferences.get("hideDockIcon") !== false;

export const setShouldHideDockIcon = (hide: boolean) =>
    userPreferences.set("hideDockIcon", hide);
