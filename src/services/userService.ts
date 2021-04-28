import HTTPService from './HTTPService';
import { KeyAttributes } from 'types';
import { getEndpoint } from 'utils/common/apiUtil';
import { clearKeys } from 'utils/storage/sessionStorage';
import router from 'next/router';
import { clearData } from 'utils/storage/localStorage';
import localForage from 'utils/storage/localForage';
import { getToken } from 'utils/common/key';

export interface UpdatedKey {
    kekSalt: string;
    encryptedKey: string;
    keyDecryptionNonce: string;
    memLimit: number;
    opsLimit: number;
}

export interface RecoveryKey {
    masterKeyEncryptedWithRecoveryKey: string;
    masterKeyDecryptionNonce: string;
    recoveryKeyEncryptedWithMasterKey: string;
    recoveryKeyDecryptionNonce: string;
}
const ENDPOINT = getEndpoint();

export interface User {
    id: number;
    name: string;
    email: string;
}

export const getOtt = (email: string) => {
    return HTTPService.get(`${ENDPOINT}/users/ott`, {
        email: email,
        client: 'web',
    });
};
export const getPublicKey = async (email: string) => {
    const token = getToken();

    const resp = await HTTPService.get(
        `${ENDPOINT}/users/public-key`,
        { email },
        {
            'X-Auth-Token': token,
        }
    );
    return resp.data['publicKey'];
};

export const verifyOtt = (email: string, ott: string) => {
    return HTTPService.get(`${ENDPOINT}/users/credentials`, { email, ott });
};

export const putAttributes = (
    token: string,
    name: string,
    keyAttributes: KeyAttributes
) => {
    return HTTPService.put(
        `${ENDPOINT}/users/attributes`,
        { name: name ? name : '', keyAttributes: keyAttributes },
        null,
        {
            'X-Auth-Token': token,
        }
    );
};

export const setKeys = (token: string, updatedKey: UpdatedKey) => {
    return HTTPService.put(`${ENDPOINT}/users/keys`, updatedKey, null, {
        'X-Auth-Token': token,
    });
};

export const SetRecoveryKey = (token: string, recoveryKey: RecoveryKey) => {
    return HTTPService.put(
        `${ENDPOINT}/users/recovery-key`,
        recoveryKey,
        null,
        {
            'X-Auth-Token': token,
        }
    );
};

export const logoutUser = async () => {
    clearKeys();
    clearData();
    const cache = await caches.delete('thumbs');
    await clearFiles();
    router.push('/');
};

export const clearFiles = async () => {
    await localForage.clear();
};

export const isTokenValid = async () => {
    try {
        await HTTPService.get(`${ENDPOINT}/users/session-validity`, null, {
            'X-Auth-Token': getToken(),
        });
        return true;
    } catch (e) {
        return false;
    }
};
