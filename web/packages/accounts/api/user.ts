import type { AppName } from "@/next/types/app";
import type {
    RecoveryKey,
    TwoFactorRecoveryResponse,
    TwoFactorSecret,
    TwoFactorVerificationResponse,
    UserVerificationResponse,
} from "@ente/accounts/types/user";
import type { B64EncryptionResult } from "@ente/shared/crypto/types";
import { ApiError, CustomError } from "@ente/shared/error";
import HTTPService from "@ente/shared/network/HTTPService";
import { getEndpoint } from "@ente/shared/network/api";
import { getToken } from "@ente/shared/storage/localStorage/helpers";
import type { KeyAttributes } from "@ente/shared/user/types";
import { HttpStatusCode } from "axios";

const ENDPOINT = getEndpoint();

export const sendOtt = (appName: AppName, email: string) => {
    return HTTPService.post(`${ENDPOINT}/users/ott`, {
        email,
        client: appName == "auth" ? "totp" : "web",
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

/** The type of the second factor we're trying to act on */
export type TwoFactorType = "totp" | "passkey";

export const recoverTwoFactor = async (
    sessionID: string,
    twoFactorType: TwoFactorType,
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
    twoFactorType: TwoFactorType,
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
