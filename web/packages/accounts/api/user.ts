import type {
    RecoveryKey,
    TwoFactorRecoveryResponse,
    TwoFactorSecret,
    TwoFactorVerificationResponse,
    UserVerificationResponse,
} from "@ente/accounts/types/user";
import { APPS, OTT_CLIENTS } from "@ente/shared/apps/constants";
import type { B64EncryptionResult } from "@ente/shared/crypto/types";
import { ApiError, CustomError } from "@ente/shared/error";
import HTTPService from "@ente/shared/network/HTTPService";
import { getEndpoint } from "@ente/shared/network/api";
import { getToken } from "@ente/shared/storage/localStorage/helpers";
import type { KeyAttributes } from "@ente/shared/user/types";
import { HttpStatusCode } from "axios";
import { TwoFactorType } from "../constants/twofactor";

const ENDPOINT = getEndpoint();

export const sendOtt = (appName: APPS, email: string) => {
    return HTTPService.post(`${ENDPOINT}/users/ott`, {
        email,
        client: OTT_CLIENTS.get(appName),
    });
};

export const verifyOtt = (email: string, ott: string, referral: string) => {
    const cleanedReferral = `web:${referral?.trim() || ""}`;
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
            "X-Auth-Token": token,
        },
    );

/**
 * Verify that the given auth {@link token} is still valid.
 *
 * If the user changes their password on another device, then all existing
 * auth tokens get invalidated. Existing clients should at opportune times
 * make an API call with the auth token that they have saved locally to see
 * if the session should be invalidated. When this happens, we inform the
 * user with a dialog and prompt them to logout.
 */
export const validateAuthToken = async (token: string) => {
    try {
        await HTTPService.get(`${ENDPOINT}/users/session-validity/v2`, null, {
            "X-Auth-Token": token,
        });
        return true;
    } catch (e) {
        // We get back a 401 Unauthorized if the token is not valid.
        if (
            e instanceof ApiError &&
            e.httpStatusCode == HttpStatusCode.Unauthorized
        ) {
            return false;
        } else {
            throw e;
        }
    }
};

export const logout = async () => {
    try {
        const token = getToken();
        await HTTPService.post(`${ENDPOINT}/users/logout`, null, undefined, {
            "X-Auth-Token": token,
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
        throw e;
    }
};

export const verifyTwoFactor = async (code: string, sessionID: string) => {
    const resp = await HTTPService.post(`${ENDPOINT}/users/two-factor/verify`, {
        code,
        sessionID,
    });
    return resp.data as UserVerificationResponse;
};

export const recoverTwoFactor = async (
    sessionID: string,
    twoFactorType: TwoFactorType = TwoFactorType.TOTP,
) => {
    const resp = await HTTPService.get(`${ENDPOINT}/users/two-factor/recover`, {
        sessionID,
        twoFactorType,
    });
    return resp.data as TwoFactorRecoveryResponse;
};

export const removeTwoFactor = async (
    sessionID: string,
    secret: string,
    twoFactorType: TwoFactorType = TwoFactorType.TOTP,
) => {
    const resp = await HTTPService.post(`${ENDPOINT}/users/two-factor/remove`, {
        sessionID,
        secret,
        twoFactorType,
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
        undefined,
        {
            "X-Auth-Token": getToken(),
        },
    );
};

export const sendOTTForEmailChange = async (email: string) => {
    await HTTPService.post(`${ENDPOINT}/users/ott`, {
        email,
        client: "web",
        purpose: "change",
    });
};

export const setupTwoFactor = async () => {
    const resp = await HTTPService.post(
        `${ENDPOINT}/users/two-factor/setup`,
        null,
        undefined,
        {
            "X-Auth-Token": getToken(),
        },
    );
    return resp.data as TwoFactorSecret;
};

export const enableTwoFactor = async (
    code: string,
    recoveryEncryptedTwoFactorSecret: B64EncryptionResult,
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
        undefined,
        {
            "X-Auth-Token": getToken(),
        },
    );
};

export const setRecoveryKey = (token: string, recoveryKey: RecoveryKey) =>
    HTTPService.put(`${ENDPOINT}/users/recovery-key`, recoveryKey, undefined, {
        "X-Auth-Token": token,
    });

export const disableTwoFactor = async () => {
    await HTTPService.post(
        `${ENDPOINT}/users/two-factor/disable`,
        null,
        undefined,
        {
            "X-Auth-Token": getToken(),
        },
    );
};
