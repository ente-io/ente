import { B64EncryptionResult } from 'services/upload/uploadService';
import CryptoWorker from 'utils/crypto';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import { getKey, SESSION_KEYS } from 'utils/storage/sessionStorage';
import { CustomError } from './errorUtil';

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

export const getStripePublishableKey = () =>
    process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY ??
    'pk_live_51HAhqDK59oeucIMOiTI6MDDM2UWUbCAJXJCGsvjJhiO8nYJz38rQq5T4iyQLDMKxqEDUfU5Hopuj4U5U4dff23oT00fHvZeodC';

export const getToken = () => getData(LS_KEYS.USER)?.token;
