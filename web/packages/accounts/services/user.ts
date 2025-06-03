import {
    authenticatedRequestHeaders,
    ensureOk,
    publicRequestHeaders,
} from "ente-base/http";
import { apiURL } from "ente-base/origins";
import HTTPService from "ente-shared/network/HTTPService";
import { getToken } from "ente-shared/storage/localStorage/helpers";
import type { KeyAttributes } from "ente-shared/user/types";
import { nullToUndefined } from "ente-utils/transform";
import { z } from "zod";

export interface UserVerificationResponse {
    id: number;
    keyAttributes?: KeyAttributes | undefined;
    encryptedToken?: string | undefined;
    token?: string;
    twoFactorSessionID?: string | undefined;
    passkeySessionID?: string | undefined;
    /**
     * Base URL for the accounts app where we should redirect to for passkey
     * verification.
     *
     * This will only be set if the user has setup a passkey (i.e., whenever
     * {@link passkeySessionID} is defined).
     */
    accountsUrl: string | undefined;
    /**
     * If both passkeys and TOTP based two factors are enabled, then {@link
     * twoFactorSessionIDV2} will be set to the TOTP session ID instead of
     * {@link twoFactorSessionID}.
     */
    twoFactorSessionIDV2?: string | undefined;
    srpM2?: string | undefined;
}

export interface TwoFactorVerificationResponse {
    id: number;
    keyAttributes: KeyAttributes;
    encryptedToken?: string;
    token?: string;
}

const TwoFactorSecret = z.object({
    secretCode: z.string(),
    qrCode: z.string(),
});

export type TwoFactorSecret = z.infer<typeof TwoFactorSecret>;

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

/**
 * Ask remote to send a OTP / OTT to the given email to verify that the user has
 * access to it. Subsequent the app will pass this OTT back via the
 * {@link verifyOTT} method.
 *
 * @param email The email to verify.
 *
 * @param purpose In which context is the email being verified. Remote applies
 * additional business rules depending on this. For example, passing the purpose
 * "login" ensures that the OTT is only sent to an already registered email.
 *
 * In cases where the purpose is ambiguous (e.g. we're not sure if it is an
 * existing login or a new signup), the purpose can be set to `undefined`.
 */
export const sendOTT = async (
    email: string,
    purpose: "change" | "signup" | "login" | undefined,
) =>
    ensureOk(
        await fetch(await apiURL("/users/ott"), {
            method: "POST",
            headers: publicRequestHeaders(),
            body: JSON.stringify({ email, purpose }),
        }),
    );

/**
 * Verify user's access to the given {@link email} by comparing the OTT that
 * remote previously sent to that email.
 *
 * @param email The email to verify.
 *
 * @param ott The OTT that the user entered.
 *
 * @param source During signup, we ask the user the referral "source" through
 * which they heard about Ente. When present (i.e. during signup, and if the
 * user indeed provided it), that source should be passed as this parameter.
 */
export const verifyEmail = async (
    email: string,
    ott: string,
    source: string | undefined,
): Promise<UserVerificationResponse> => {
    const res = await fetch(await apiURL("/users/verify-email"), {
        method: "POST",
        headers: publicRequestHeaders(),
        body: JSON.stringify({ email, ott, ...(source ? { source } : {}) }),
    });
    ensureOk(res);
    // See: [Note: strict mode migration]
    //
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    return EmailOrSRPAuthorizationResponse.parse(await res.json());
};

/**
 * Zod schema for {@link KeyAttributes}.
 */
export const RemoteKeyAttributes = z.object({
    kekSalt: z.string(),
    encryptedKey: z.string(),
    keyDecryptionNonce: z.string(),
    publicKey: z.string(),
    encryptedSecretKey: z.string(),
    secretKeyDecryptionNonce: z.string(),
    memLimit: z.number(),
    opsLimit: z.number(),
    masterKeyEncryptedWithRecoveryKey: z
        .string()
        .nullish()
        .transform(nullToUndefined),
    masterKeyDecryptionNonce: z.string().nullish().transform(nullToUndefined),
    recoveryKeyEncryptedWithMasterKey: z
        .string()
        .nullish()
        .transform(nullToUndefined),
    recoveryKeyDecryptionNonce: z.string().nullish().transform(nullToUndefined),
});

/**
 * Zod schema for response from remote on a successful user verification, either
 * via {@link verifyEmail} or {@link verifySRPSession}.
 *
 * If a second factor is enabled than one of the two factor session IDs
 * (`passkeySessionID`, `twoFactorSessionID` / `twoFactorSessionIDV2`) will be
 * set. Otherwise `keyAttributes` and `encryptedToken` will be set.
 */
export const EmailOrSRPAuthorizationResponse = z.object({
    id: z.number(),
    keyAttributes: RemoteKeyAttributes.nullish().transform(nullToUndefined),
    encryptedToken: z.string().nullish().transform(nullToUndefined),
    token: z.string().nullish().transform(nullToUndefined),
    twoFactorSessionID: z.string().nullish().transform(nullToUndefined),
    passkeySessionID: z.string().nullish().transform(nullToUndefined),
    // Base URL for the accounts app where we should redirect to for passkey
    // verification.
    accountsUrl: z.string().nullish().transform(nullToUndefined),
    // TwoFactorSessionIDV2 is only set if user has both passkey and two factor
    // enabled. This is to ensure older clients keep using passkey flow when
    // both are set. It is intended to be removed once all clients starts
    // surfacing both options for performing 2FA.
    //
    // See `useSecondFactorChoiceIfNeeded`.
    twoFactorSessionIDV2: z.string().nullish().transform(nullToUndefined),
    // srpM2 is sent only if the user is logging via SRP. It is is the SRP M2
    // value aka the proof that the server has the verifier.
    srpM2: z.string().nullish().transform(nullToUndefined),
});

/**
 * The result of a successful two factor verification (totp or passkey).
 */
export const TwoFactorAuthorizationResponse = z.object({
    id: z.number(),
    /** TODO: keyAttributes is guaranteed to be returned by museum, update the
     * types to reflect that. */
    keyAttributes: RemoteKeyAttributes.nullish().transform(nullToUndefined),
    /** TODO: encryptedToken is guaranteed to be returned by museum, update the
     * types to reflect that. */
    encryptedToken: z.string().nullish().transform(nullToUndefined),
});

export type TwoFactorAuthorizationResponse = z.infer<
    typeof TwoFactorAuthorizationResponse
>;

/**
 * Update or set the user's {@link KeyAttributes} on remote.
 */
export const putUserKeyAttributes = async (keyAttributes: KeyAttributes) =>
    ensureOk(
        await fetch(await apiURL("/users/attributes"), {
            method: "PUT",
            headers: await authenticatedRequestHeaders(),
            body: JSON.stringify({ keyAttributes }),
        }),
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
    const res = await fetch(await apiURL("/users/two-factor/verify"), {
        method: "POST",
        headers: publicRequestHeaders(),
        body: JSON.stringify({ code, sessionID }),
    });
    ensureOk(res);
    const json = await res.json();
    // TODO: Use zod here
    return json as UserVerificationResponse;
};

/** The type of the second factor we're trying to act on */
export type TwoFactorType = "totp" | "passkey";

export const recoverTwoFactor = async (
    sessionID: string,
    twoFactorType: TwoFactorType,
) => {
    const resp = await HTTPService.get(
        await apiURL("/users/two-factor/recover"),
        { sessionID, twoFactorType },
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
        { sessionID, secret, twoFactorType },
    );
    return resp.data as TwoFactorVerificationResponse;
};

export const changeEmail = async (email: string, ott: string) => {
    await HTTPService.post(
        await apiURL("/users/change-email"),
        { email, ott },
        undefined,
        { "X-Auth-Token": getToken() },
    );
};

/**
 * Start the two factor setup process by fetching a secret code (and the
 * corresponding QR code) from remote.
 */
export const setupTwoFactor = async () => {
    const res = await fetch(await apiURL("/users/two-factor/setup"), {
        method: "POST",
        headers: await authenticatedRequestHeaders(),
    });
    ensureOk(res);
    return TwoFactorSecret.parse(await res.json());
};

interface EnableTwoFactorRequest {
    code: string;
    encryptedTwoFactorSecret: string;
    twoFactorSecretDecryptionNonce: string;
}

/**
 * Enable two factor for the user by providing the 2FA code and the encrypted
 * secret from a previous call to {@link setupTwoFactor}.
 */
export const enableTwoFactor = async (req: EnableTwoFactorRequest) =>
    ensureOk(
        await fetch(await apiURL("/users/two-factor/enable"), {
            method: "POST",
            headers: await authenticatedRequestHeaders(),
            body: JSON.stringify(req),
        }),
    );

export interface RecoveryKeyAttributes {
    masterKeyEncryptedWithRecoveryKey: string;
    masterKeyDecryptionNonce: string;
    recoveryKeyEncryptedWithMasterKey: string;
    recoveryKeyDecryptionNonce: string;
}

/**
 * Update the encrypted recovery key attributes for the logged in user.
 *
 * In practice, this is not expected to be called and is meant as a rare
 * fallback for very old accounts created prior to recovery key related
 * attributes being assigned on account setup. Even for these, it'll be called
 * only once.
 */
export const putUserRecoveryKeyAttributes = async (
    recoveryKeyAttributes: RecoveryKeyAttributes,
) =>
    ensureOk(
        await fetch(await apiURL("/users/recovery-key"), {
            method: "PUT",
            headers: await authenticatedRequestHeaders(),
            body: JSON.stringify(recoveryKeyAttributes),
        }),
    );
