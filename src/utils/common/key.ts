import CryptoWorker from 'utils/crypto';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import { getKey, SESSION_KEYS } from 'utils/storage/sessionStorage';

export const getActualKey = async () => {
    const session = getData(LS_KEYS.SESSION);
    if (session == null) {
        return;
    }
    const cryptoWorker = await new CryptoWorker();
    const encryptedKey = getKey(SESSION_KEYS.ENCRYPTION_KEY)?.encryptionKey;
    const key: string = await cryptoWorker.decryptB64(
        encryptedKey,
        session.sessionNonce,
        session.sessionKey
    );
    return key;
};

export const getToken = () => {
    return getData(LS_KEYS.USER)?.token;
};
