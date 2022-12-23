import { B64EncryptionResult } from 'types/crypto';
import CryptoWorker from 'utils/crypto';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import { getKey, SESSION_KEYS } from 'utils/storage/sessionStorage';
import { CustomError } from '../error';

export const getActualKey = async () => {
    try {
        const encryptionKeyAttributes: B64EncryptionResult = getKey(
            SESSION_KEYS.ENCRYPTION_KEY
        );

        const cryptoWorker = await new CryptoWorker();
        const key: string = await cryptoWorker.decryptB64(
            encryptionKeyAttributes.encryptedData,
            encryptionKeyAttributes.nonce,
            encryptionKeyAttributes.key
        );
        return key;
    } catch (e) {
        throw new Error(CustomError.KEY_MISSING);
    }
};

export const getToken = () => getData(LS_KEYS.USER)?.token;
