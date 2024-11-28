import { appName } from "@/base/app";
import type { B64EncryptionResult } from "@/base/crypto/libsodium";
import { authenticatedRequestHeaders, ensureOk } from "@/base/http";
import { apiURL } from "@/base/origins";
import HTTPService from "@ente/shared/network/HTTPService";
import { getToken } from "@ente/shared/storage/localStorage/helpers";
import type { KeyAttributes } from "@ente/shared/user/types";

export interface UserVerificationResponse {
    id: number;
    keyAttributes?: KeyAttributes;
    encryptedToken?: string;
    token?: string;
    twoFactorSessionID: string;
    passkeySessionID: string;
    /**
     * If both passkeys and TOTP based two factors are enabled, then {@link
     * twoFactorSessionIDV2} will be set to the TOTP session ID instead of
     * {@link twoFactorSessionID}.
     */
    twoFactorSessionIDV2?: string | undefined;
    srpM2?: string;
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

export const sendOtt = async (email: string) => {
    return HTTPService.post(await apiURL("/users/ott"), {
        email,
        client: appName == "auth" ? "totp" : "web",
    });
};

export const verifyOtt = async (
    email: string,
    ott: string,
    referral: string,
) => {
    const cleanedReferral = `web:${referral?.trim() || ""}`;
    return HTTPService.post(await apiURL("/users/verify-email"), {
        email,
        ott,
        source: cleanedReferral,
    });
};

export const putAttributes = async (
    token: string,
    keyAttributes: KeyAttributes,
) =>
    HTTPService.put(
        await apiURL("/users/attributes"),
        { keyAttributes },
        undefined,
        {
            "X-Auth-Token": token,
        },
    );

/**
 * Log the user out on remote, if possible and needed.
 */
export const remoteLogoutIfNeeded = async () => {
    let headers: HeadersInit;
    try {
        headers = await authenticatedRequestHeaders();
    } catch {
        // If the logout is attempted during the signup flow itself, then we
        // won't have an auth token.
        return;
    }

    const res = await fetch(await apiURL("/users/logout"), {
        method: "POST",
        headers,
    });
    if (res.status == 401) {
        // Ignore if we get a 401 Unauthorized, this is expected to happen on
        // token expiry.
        return;
    }

    ensureOk(res);
};

export const verifyTwoFactor = async (code: string, sessionID: string) => {
    const resp = await HTTPService.post(
        await apiURL("/users/two-factor/verify"),
        {
            code,
            sessionID,
        },
    );
    return resp.data as UserVerificationResponse;
};

/** The type of the second factor we're trying to act on */
export type TwoFactorType = "totp" | "passkey";

export const recoverTwoFactor = async (
    sessionID: string,
    twoFactorType: TwoFactorType,
) => {
    const resp = await HTTPService.get(
        await apiURL("/users/two-factor/recover"),
        {
            sessionID,
            twoFactorType,
        },
    );
    return resp.data as TwoFactorRecoveryResponse;
};

export const removeTwoFactor = async (
    sessionID: string,
    secret: string,
    twoFactorType: TwoFactorType,
) => {
    const resp = await HTTPService.post(
        await apiURL("/users/two-factor/remove"),
        {
            sessionID,
            secret,
            twoFactorType,
        },
    );
    return resp.data as TwoFactorVerificationResponse;
};

export const changeEmail = async (email: string, ott: string) => {
    await HTTPService.post(
        await apiURL("/users/change-email"),
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
    await HTTPService.post(await apiURL("/users/ott"), {
        email,
        client: "web",
        purpose: "change",
    });
};

export const setupTwoFactor = async () => {
    const resp = await HTTPService.post(
        await apiURL("/users/two-factor/setup"),
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
        await apiURL("/users/two-factor/enable"),
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

export const setRecoveryKey = async (token: string, recoveryKey: RecoveryKey) =>
    HTTPService.put(
        await apiURL("/users/recovery-key"),
        recoveryKey,
        undefined,
        {
            "X-Auth-Token": token,
        },
    );
