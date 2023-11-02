import HTTPService from '@ente/shared/network/HTTPService';
import { getEndpoint } from '@ente/shared/network/api';

import { getToken } from '@ente/shared/storage/localStorage/helpers';
import { KeyAttributes } from '@ente/shared/user/types';
import { ApiError } from '@ente/shared/error';
import { HttpStatusCode } from 'axios';
import {
    UserVerificationResponse,
    TwoFactorRecoveryResponse,
    TwoFactorVerificationResponse,
    TwoFactorSecret,
    RecoveryKey,
} from '@ente/accounts/types/user';
import { B64EncryptionResult } from '@ente/shared/crypto/types';

const ENDPOINT = getEndpoint();

export const sendOtt = (appName: string, email: string) => {
    return HTTPService.post(`${ENDPOINT}/users/ott`, {
        email,
        client: appName,
    });
};

export const verifyOtt = (email: string, ott: string) =>
    HTTPService.post(`${ENDPOINT}/users/verify-email`, { email, ott });

export const putAttributes = async (keyAttributes: KeyAttributes) => {
    const token = getToken();
    await HTTPService.put(
        `${ENDPOINT}/users/attributes`,
        { keyAttributes },
        undefined,
        {
            'X-Auth-Token': token,
        }
    );
};

export const _logout = async () => {
    // ignore if token missing can be triggered during sign up.
    if (!getToken()) return true;
    try {
        await HTTPService.post(`${ENDPOINT}/users/logout`, null, undefined, {
            'X-Auth-Token': getToken(),
        });
        return true;
    } catch (e) {
        // ignore if unauthorized, can be triggered during on token expiry.
        if (
            e instanceof ApiError &&
            e.httpStatusCode === HttpStatusCode.Unauthorized
        ) {
            return true;
        }
        // logError(e, '/users/logout failed');
        throw e;
    }
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
    return resp.data as UserVerificationResponse;
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

export const sendOTTForEmailChange = async (email: string) => {
    if (!getToken()) {
        return null;
    }
    await HTTPService.post(`${ENDPOINT}/users/ott`, {
        email,
        client: 'web',
        purpose: 'change',
    });
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

export const setRecoveryKey = (token: string, recoveryKey: RecoveryKey) =>
    HTTPService.put(`${ENDPOINT}/users/recovery-key`, recoveryKey, null, {
        'X-Auth-Token': token,
    });
