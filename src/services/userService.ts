import {KeyAttributes} from 'types';
import {getEndpoint} from 'utils/common/apiUtil';
import {clearKeys} from 'utils/storage/sessionStorage';
import router from 'next/router';
import {clearData} from 'utils/storage/localStorage';
import localForage from 'utils/storage/localForage';
import {getToken} from 'utils/common/key';
import HTTPService from './HTTPService';

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

export const getOtt = (email: string) => HTTPService.get(`${ENDPOINT}/users/ott`, {
    email,
    client: 'web',
});
export const getPublicKey = async (email: string) => {
    const token = getToken();

    const resp = await HTTPService.get(
        `${ENDPOINT}/users/public-key`,
        {email},
        {
            'X-Auth-Token': token,
        },
    );
    return resp.data.publicKey;
};

export const verifyOtt = (email: string, ott: string) => HTTPService.get(`${ENDPOINT}/users/credentials`, {email, ott});

export const putAttributes = (token: string, keyAttributes: KeyAttributes) => HTTPService.put(
    `${ENDPOINT}/users/attributes`,
    {keyAttributes},
    null,
    {
        'X-Auth-Token': token,
    },
);

export const setKeys = (token: string, updatedKey: UpdatedKey) => HTTPService.put(`${ENDPOINT}/users/keys`, updatedKey, null, {
    'X-Auth-Token': token,
});

export const setRecoveryKey = (token: string, recoveryKey: RecoveryKey) => HTTPService.put(
    `${ENDPOINT}/users/recovery-key`,
    recoveryKey,
    null,
    {
        'X-Auth-Token': token,
    },
);

export const logoutUser = async () => {
    clearKeys();
    clearData();
    await caches.delete('thumbs');
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
