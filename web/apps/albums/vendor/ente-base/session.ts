import { z } from "zod";
import { decryptBox, encryptBox, generateKey } from "./crypto";

export const clearSessionStorage = () => sessionStorage.clear();

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

const sessionKey = async (keyName: string) => {
    const value = sessionStorage.getItem(keyName);
    if (!value) return undefined;

    const { encryptedData, key, nonce } = SessionKeyData.parse(
        JSON.parse(value),
    );
    return decryptBox({ encryptedData, nonce }, key);
};

export const ensureMasterKeyFromSession = async () => {
    const key = await masterKeyFromSession();
    if (!key) throw new Error("Master key not found in session");
    return key;
};

export const haveMasterKeyInSession = () =>
    !!sessionStorage.getItem("encryptionKey");

export const masterKeyFromSession = async () => sessionKey("encryptionKey");

export const saveMasterKeyInSession = async (masterKey: string) => {
    sessionStorage.setItem(
        "encryptionKey",
        JSON.stringify(await sessionKeyData(masterKey)),
    );
};
