import { KeyAttributes } from 'types';
import { getEndpoint } from 'utils/common/apiUtil';
import { clearKeys } from 'utils/storage/sessionStorage';
import router from 'next/router';
import { clearData } from 'utils/storage/localStorage';
import localForage from 'utils/storage/localForage';
import { getToken } from 'utils/common/key';
import HTTPService from './HTTPService';
import { B64EncryptionResult } from './uploadService';

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
export interface EmailVerificationResponse {
    id: number;
    keyAttributes?: KeyAttributes;
    encryptedToken?: string;
    token?: string;
    twoFactorSessionID: string
}

export interface TwoFactorVerificationResponse {
    id: number;
    keyAttributes: KeyAttributes;
    encryptedToken?: string;
    token?: string;
}

export interface TwoFactorSecret {
    secretCode: string
    qrCode: string
}

export interface TwoFactorRecoveryResponse {
    encryptedSecret: string
    secretDecryptionNonce: string
}

export const getOtt = (email: string) => HTTPService.get(`${ENDPOINT}/users/ott`, {
    email,
    client: 'web',
});
export const getPublicKey = async (email: string) => {
    const token = getToken();

    const resp = await HTTPService.get(
        `${ENDPOINT}/users/public-key`,
        { email },
        {
            'X-Auth-Token': token,
        },
    );
    return resp.data.publicKey;
};

export const verifyOtt = (email: string, ott: string) => HTTPService.post(`${ENDPOINT}/users/verify-email`, { email, ott });

export const putAttributes = (token: string, keyAttributes: KeyAttributes) => HTTPService.put(
    `${ENDPOINT}/users/attributes`,
    { keyAttributes },
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

export const setupTwoFactor = async () => {
    const resp = await HTTPService.post(`${ENDPOINT}/users/two-factor/setup`, null, null, {
        'X-Auth-Token': getToken(),
    });
    return resp.data as TwoFactorSecret;
};

export const enableTwoFactor = async (otp: string, recoveryEncryptedTwoFactorSecret: B64EncryptionResult) => {
    await HTTPService.post(`${ENDPOINT}/users/two-factor/enable`, {
        otp,
        encryptedTwoFactorSecret: recoveryEncryptedTwoFactorSecret.encryptedData,
        twoFactorSecretDecryptionNonce: recoveryEncryptedTwoFactorSecret.nonce,
    }, null, {
        'X-Auth-Token': getToken(),
    });
};

export const verifyTwoFactor = async (otp: string, sessionID: string) => {
    const resp = await HTTPService.post(`${ENDPOINT}/users/two-factor/verify`, {
        otp, sessionID,
    }, null);
    return resp.data as TwoFactorVerificationResponse;
};

export const recoverTwoFactor = async (sessionID: string) => {
    const resp = await HTTPService.get(`${ENDPOINT}/users/two-factor/recover`, {
        sessionID,
    });
    return resp.data as TwoFactorRecoveryResponse;
};

export const removeTwoFactor = async (sessionID: string, secret: string) => {
    const resp = await HTTPService.post(`${ENDPOINT}/users/two-factor/remove`, {
        sessionID, secret,
    });
    return resp.data as TwoFactorVerificationResponse;
};
