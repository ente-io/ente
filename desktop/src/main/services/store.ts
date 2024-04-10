import { safeStorage } from "electron/main";
import { keysStore } from "../stores/keys.store";
import { safeStorageStore } from "../stores/safeStorage.store";
import { uploadStatusStore } from "../stores/upload.store";
import { watchStore } from "../stores/watch.store";

export const clearStores = () => {
    uploadStatusStore.clear();
    keysStore.clear();
    safeStorageStore.clear();
    watchStore.clear();
};

export const saveEncryptionKey = async (encryptionKey: string) => {
    const encryptedKey: Buffer = await safeStorage.encryptString(encryptionKey);
    const b64EncryptedKey = Buffer.from(encryptedKey).toString("base64");
    safeStorageStore.set("encryptionKey", b64EncryptedKey);
};

export const encryptionKey = async (): Promise<string | undefined> => {
    const b64EncryptedKey = safeStorageStore.get("encryptionKey");
    if (!b64EncryptedKey) return undefined;
    const keyBuffer = Buffer.from(b64EncryptedKey, "base64");
    return await safeStorage.decryptString(keyBuffer);
};
