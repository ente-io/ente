import { safeStorage } from "electron/main";
import { safeStorageStore } from "../stores/safeStorage.store";

export async function setEncryptionKey(encryptionKey: string) {
    const encryptedKey: Buffer = await safeStorage.encryptString(encryptionKey);
    const b64EncryptedKey = Buffer.from(encryptedKey).toString("base64");
    safeStorageStore.set("encryptionKey", b64EncryptedKey);
}

export async function getEncryptionKey(): Promise<string> {
    const b64EncryptedKey = safeStorageStore.get("encryptionKey");
    if (b64EncryptedKey) {
        const keyBuffer = Buffer.from(b64EncryptedKey, "base64");
        return await safeStorage.decryptString(keyBuffer);
    }
}
