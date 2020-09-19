import { decrypt } from "utils/crypto/aes";
import { getData, LS_KEYS } from "utils/storage/localStorage";
import { getKey, SESSION_KEYS } from "utils/storage/sessionStorage";

export const getActualKey = async () =>  {
    const key = getKey(SESSION_KEYS.ENCRYPTION_KEY).encryptionKey;
    const session = getData(LS_KEYS.SESSION);
    return await decrypt(key, session.sessionKey, session.sessionIV);
}
