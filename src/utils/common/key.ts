import { getData, LS_KEYS } from "utils/storage/localStorage";
import { getKey, SESSION_KEYS } from "utils/storage/sessionStorage";
import { decryptToB64 } from "utils/crypto/libsodium";

export const getActualKey = async () => {
    const encryptedKey = getKey(SESSION_KEYS.ENCRYPTION_KEY).encryptionKey;
    const session = getData(LS_KEYS.SESSION);
    const key = await decryptToB64(encryptedKey, session.sessionNonce, session.sessionKey);
    return key;
}
