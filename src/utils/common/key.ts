import { getData, LS_KEYS } from "utils/storage/localStorage";
import { getKey, SESSION_KEYS } from "utils/storage/sessionStorage";
import * as Comlink from "comlink";

const CryptoWorker: any = typeof window !== 'undefined'
    && Comlink.wrap(new Worker("worker/crypto.worker.js", { type: 'module' }));

export const getActualKey = async () => {
    const cryptoWorker = await new CryptoWorker();
    const encryptedKey = getKey(SESSION_KEYS.ENCRYPTION_KEY).encryptionKey;
    const session = getData(LS_KEYS.SESSION);
    const key = await cryptoWorker.decryptToB64(encryptedKey, session.sessionNonce, session.sessionKey);
    return key;
}
