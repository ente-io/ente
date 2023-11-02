import HTTPService from '@ente/shared/network/HTTPService';
import { getEndpoint } from '@ente/shared/network/api';

import { getToken } from '@ente/shared/storage/localStorage/helpers';

import {
    KeyAttributes,
    UserVerificationResponse,
} from '@ente/shared/user/types';
import { ApiError } from '@ente/shared/error';
import { HttpStatusCode } from 'axios';

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
