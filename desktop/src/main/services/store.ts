import { safeStorage } from "electron/main";
import { safeStorageStore } from "../stores/safe-storage";
import { uploadStatusStore } from "../stores/upload-status";
import { watchStore } from "../stores/watch";

/**
 * Clear all stores except user preferences.
 *
 * This is useful to reset state when the user logs out.
 */
export const clearStores = () => {
    safeStorageStore.clear();
    uploadStatusStore.clear();
    watchStore.clear();
};

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
