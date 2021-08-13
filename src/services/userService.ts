import { KeyAttributes } from 'types';
import { getEndpoint } from 'utils/common/apiUtil';
import { clearKeys } from 'utils/storage/sessionStorage';
import router from 'next/router';
import { clearData } from 'utils/storage/localStorage';
import localForage from 'utils/storage/localForage';
import { getToken } from 'utils/common/key';
import HTTPService from './HTTPService';
import { B64EncryptionResult } from './upload/uploadService';
import { logError } from 'utils/sentry';
import { Subscription } from './billingService';

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
    twoFactorSessionID: string;
}

export interface TwoFactorVerificationResponse {
    id: number;
    keyAttributes: KeyAttributes;
    encryptedToken?: string;
    token?: string;
}

export interface TwoFactorSecret {
    secretCode: string;
    qrCode: string;
}

export interface TwoFactorRecoveryResponse {
    encryptedSecret: string;
    secretDecryptionNonce: string;
}

export interface UserDetails {
    email: string;
    usage: number;
    fileCount: number;
    sharedCollectionCount: number;
    subscription: Subscription;
}

export const getOtt = (email: string) =>
    HTTPService.get(`${ENDPOINT}/users/ott`, {
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
        }
    );
    return resp.data.publicKey;
};

export const verifyOtt = (email: string, ott: string) =>
    HTTPService.post(`${ENDPOINT}/users/verify-email`, { email, ott });

export const putAttributes = (token: string, keyAttributes: KeyAttributes) =>
    HTTPService.put(`${ENDPOINT}/users/attributes`, { keyAttributes }, null, {
        'X-Auth-Token': token,
    });

export const setKeys = (token: string, updatedKey: UpdatedKey) =>
    HTTPService.put(`${ENDPOINT}/users/keys`, updatedKey, null, {
        'X-Auth-Token': token,
    });

export const setRecoveryKey = (token: string, recoveryKey: RecoveryKey) =>
    HTTPService.put(`${ENDPOINT}/users/recovery-key`, recoveryKey, null, {
        'X-Auth-Token': token,
    });

export const logoutUser = async () => {
    // ignore server logout result as logoutUser can be triggered before sign up or on token expiry
    await _logout();
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
    const resp = await HTTPService.post(
        `${ENDPOINT}/users/two-factor/setup`,
        null,
        null,
        {
            'X-Auth-Token': getToken(),
        }
    );
    return resp.data as TwoFactorSecret;
};

export const enableTwoFactor = async (
    code: string,
    recoveryEncryptedTwoFactorSecret: B64EncryptionResult
) => {
    await HTTPService.post(
        `${ENDPOINT}/users/two-factor/enable`,
        {
            code,
            encryptedTwoFactorSecret:
                recoveryEncryptedTwoFactorSecret.encryptedData,
            twoFactorSecretDecryptionNonce:
                recoveryEncryptedTwoFactorSecret.nonce,
        },
        null,
        {
            'X-Auth-Token': getToken(),
        }
    );
};

export const verifyTwoFactor = async (code: string, sessionID: string) => {
    const resp = await HTTPService.post(
        `${ENDPOINT}/users/two-factor/verify`,
        {
            code,
            sessionID,
        },
        null
    );
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
        sessionID,
        secret,
    });
    return resp.data as TwoFactorVerificationResponse;
};

export const disableTwoFactor = async () => {
    await HTTPService.post(`${ENDPOINT}/users/two-factor/disable`, null, null, {
        'X-Auth-Token': getToken(),
    });
};

export const getTwoFactorStatus = async () => {
    const resp = await HTTPService.get(
        `${ENDPOINT}/users/two-factor/status`,
        null,
        {
            'X-Auth-Token': getToken(),
        }
    );
    return resp.data['status'];
};

export const _logout = async () => {
    if (!getToken()) return true;
    try {
        await HTTPService.post(`${ENDPOINT}/users/logout`, null, null, {
            'X-Auth-Token': getToken(),
        });
        return true;
    } catch (e) {
        logError(e, '/users/logout failed');
        return false;
    }
};

export const getOTTForEmailChange = async (email: string) => {
    if (!getToken()) {
        return null;
    }
    await HTTPService.get(`${ENDPOINT}/users/ott`, {
        email,
        client: 'web',
        purpose: 'change',
    });
};

export const changeEmail = async (email: string, ott: string) => {
    if (!getToken()) {
        return null;
    }
    await HTTPService.post(
        `${ENDPOINT}/users/change-email`,
        {
            email,
            ott,
        },
        null,
        {
            'X-Auth-Token': getToken(),
        }
    );
};

export const getUserDetails = async (): Promise<UserDetails> => {
    const token = getToken();

    const resp = await HTTPService.get(`${ENDPOINT}/users/details`, null, {
        'X-Auth-Token': token,
    });
    return resp.data['details'];
};
