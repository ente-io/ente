import { sharedCryptoWorker } from "ente-base/crypto";
import { setKey, type SessionKey } from "ente-shared/storage/sessionStorage";

export const saveKeyInSessionStore = async (
    keyType: SessionKey,
    key: string,
    fromDesktop?: boolean,
) => {
    const cryptoWorker = await sharedCryptoWorker();
    const sessionKeyAttributes =
        await cryptoWorker.generateKeyAndEncryptToB64(key);
    setKey(keyType, sessionKeyAttributes);
    const electron = globalThis.electron;
    if (electron && !fromDesktop && keyType == "encryptionKey") {
        electron.saveMasterKeyInSafeStorage(key);
    }
};
