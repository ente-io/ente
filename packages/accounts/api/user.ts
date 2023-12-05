import HTTPService from '@ente/shared/network/HTTPService';
import { getEndpoint } from '@ente/shared/network/api';

import { getToken } from '@ente/shared/storage/localStorage/helpers';
import { KeyAttributes } from '@ente/shared/user/types';
import { ApiError, CustomError } from '@ente/shared/error';
import { HttpStatusCode } from 'axios';
import {
    UserVerificationResponse,
    TwoFactorRecoveryResponse,
    TwoFactorVerificationResponse,
    TwoFactorSecret,
    RecoveryKey,
} from '@ente/accounts/types/user';
import { B64EncryptionResult } from '@ente/shared/crypto/types';
import { logError } from '@ente/shared/sentry';
import { APPS, OTT_CLIENTS } from '@ente/shared/apps/constants';

const ENDPOINT = getEndpoint();

export const sendOtt = (appName: APPS, email: string) => {
    return HTTPService.post(`${ENDPOINT}/users/ott`, {
        email,
        client: OTT_CLIENTS.get(appName),
    });
};

export const verifyOtt = (email: string, ott: string, referral: string) => {
    const cleanedReferral = `web:${referral?.trim() || ''}`;
    return HTTPService.post(`${ENDPOINT}/users/verify-email`, {
        email,
        ott,
        source: cleanedReferral,
    });
};

export const putAttributes = (token: string, keyAttributes: KeyAttributes) =>
    HTTPService.put(
        `${ENDPOINT}/users/attributes`,
        { keyAttributes },
        undefined,
        {
            'X-Auth-Token': token,
        }
    );

export const _logout = async () => {
    try {
        const token = getToken();
        await HTTPService.post(`${ENDPOINT}/users/logout`, null, undefined, {
            'X-Auth-Token': token,
        });
    } catch (e) {
        // ignore if token missing can be triggered during sign up.
        if (e instanceof Error && e.message === CustomError.TOKEN_MISSING) {
            return;
        }
        // ignore if unauthorized, can be triggered during on token expiry.
        else if (
            e instanceof ApiError &&
            e.httpStatusCode === HttpStatusCode.Unauthorized
        ) {
            return;
        }
        logError(e, '/users/logout failed');
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

export const disableTwoFactor = async () => {
    await HTTPService.post(`${ENDPOINT}/users/two-factor/disable`, null, null, {
        'X-Auth-Token': getToken(),
    });
};
