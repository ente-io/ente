import { B64EncryptionResult } from 'types/crypto';
import ComlinkCryptoWorker from '@ente/shared/crypto';
import { getData, LS_KEYS } from '@ente/shared/storage/localStorage';
import { getKey, SESSION_KEYS } from '@ente/shared/storage/sessionStorage';
import { CustomError } from '../error';

export const getActualKey = async () => {
    try {
        const encryptionKeyAttributes: B64EncryptionResult = getKey(
            SESSION_KEYS.ENCRYPTION_KEY
        );

        const cryptoWorker = await ComlinkCryptoWorker.getInstance();
        const key = await cryptoWorker.decryptB64(
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
export const getUserID = () => getData(LS_KEYS.USER)?.id;
