import { encryptBox } from "ente-base/crypto";
import {
    authenticatedRequestHeaders,
    ensureOk,
    publicRequestHeaders,
} from "ente-base/http";
import { apiURL } from "ente-base/origins";
import HTTPService from "ente-shared/network/HTTPService";
import { getData, setLSUser } from "ente-shared/storage/localStorage";
import { nullToUndefined } from "ente-utils/transform";
import { z } from "zod/v4";
import { getUserRecoveryKey } from "./recovery-key";

export interface User {
    id: number;
    email: string;
    token: string;
    encryptedToken: string;
    isTwoFactorEnabled: boolean;
    twoFactorSessionID: string;
}

// TODO: During login the only field present is email. Which makes this
// optionality indicated by these types incorrect.
const LocalUser = z.object({
    /** The user's ID. */
    id: z.number(),
    /** The user's email. */
    email: z.string(),
    /**
     * The user's (plaintext) auth token.
     *
     * It is used for making API calls on their behalf, by passing this token as
     * the value of the X-Auth-Token header in the HTTP request.
     */
    token: z.string(),
});

/** Locally available data for the logged in user */
export type LocalUser = z.infer<typeof LocalUser>;

/**
 * Return the logged-in user, if someone is indeed logged in. Otherwise return
 * `undefined`.
 *
 * The user's data is stored in the browser's localStorage. Thus, this function
 * only works from the main thread, not from web workers (local storage is not
 * accessible to web workers).
 */
export const localUser = (): LocalUser | undefined => {
    // TODO: duplicate of getData("user")
    const s = localStorage.getItem("user");
    if (!s) return undefined;
    return LocalUser.parse(JSON.parse(s));
};

/**
 * A wrapper over {@link localUser} with that throws if no one is logged in.
 */
export const ensureLocalUser = (): LocalUser =>
    ensureExpectedLoggedInValue(localUser());

/**
 * A function throws an error if a value that is expected to be truthy when the
 * user is logged in is instead falsey.
 *
 * This is meant as a convenience wrapper to assert that a value we expect when
 * the user is logged in is indeed there.
 */
export const ensureExpectedLoggedInValue = <T>(t: T | undefined): T => {
    if (!t) throw new Error("Not logged in");
    return t;
};

/**
 * The user's various encrypted keys and their related attributes.
 *
 * - Attributes to derive the KEK, the (master) key encryption key.
 * - Encrypted master key (with KEK)
 * - Encrypted master key (with recovery key)
 * - Encrypted recovery key (with master key).
 * - Public key and encrypted private key (with master key).
 *
 * The various "key" attributes are base64 encoded representations of the
 * underlying binary data.
 */
export interface KeyAttributes {
    /**
     * The user's master key encrypted with the key encryption key.
     *
     * Base64 encoded.
     *
     * [Note: Key encryption key]
     *
     * The user's master key is encrypted with a "key encryption key" (lovingly
     * called a "kek" sometimes).
     *
     * The kek itself is derived from the user's passphrase.
     *
     * 1. User enters passphrase on new device.
     *
     * 2. Client derives kek from this passphrase (using the {@link kekSalt},
     *    {@link opsLimit} and {@link memLimit} as parameters for the
     *    derivation).
     *
     * 3. Client use kek to decrypt the master key from {@link encryptedKey} and
     *    {@link keyDecryptionNonce}.
     */
    encryptedKey: string;
    /**
     * The nonce used during the encryption of the master key.
     *
     * Base64 encoded.
     *
     * @see {@link encryptedKey}.
     */
    keyDecryptionNonce: string;
    /**
     * The salt used during the derivation of the kek.
     *
     * Base64 encoded.
     *
     * See: [Note: Key encryption key].
     */
    kekSalt: string;
    /**
     * The operation limit used during the derivation of the kek.
     *
     * The {@link opsLimit} and {@link memLimit} are complementary parameters
     * that define the amount of work done by the key derivation function. See
     * the {@link deriveKey}, {@link deriveSensitiveKey} and
     * {@link deriveInteractiveKey} functions for more detail about them.
     *
     * See: [Note: Key encryption key].
     */
    opsLimit: number;
    /**
     * The memory limit used during the derivation of the kek.
     *
     * See {@link opsLimit} for more details.
     */
    memLimit: number;
    /**
     * The user's public key (part of their public-key keypair, the other half
     * being the {@link encryptedSecretKey}).
     *
     * Base64 encoded.
     */
    publicKey: string;
    /**
     * The user's private key (part of their public-key keypair, the other half
     * being the {@link publicKey}) encrypted with their master key.
     *
     * Base64 encoded.
     *
     * [Note: privateKey and secretKey]
     *
     * The nomenclature for the key pair follows libsodium's conventions
     * (https://doc.libsodium.org/public-key_cryptography/authenticated_encryption#key-pair-generation),
     * who possibly chose public + secret instead of public + private to avoid
     * confusion with shorthand notation (pk).
     *
     * However, the library author later changed their mind on this, so while
     * libsodium itself (the C library) and the documentation uses "secretKey",
     * the JavaScript implementation (libsodium.js) uses "privateKey".
     *
     * This structure uses the term "secretKey" since that is what the remote
     * protocol already was based on. Within the web app codebase, we use
     * "privateKey" since that is what the underlying libsodium.js uses.
     */
    encryptedSecretKey: string;
    /**
     * The nonce used during the encryption of {@link encryptedSecretKey}.
     */
    secretKeyDecryptionNonce: string;
    /**
     * The user's master key after being encrypted with their recovery key.
     *
     * Base64 encoded.
     *
     * This allows the user to recover their master key if they forget their
     * passphrase but still have their recovery key.
     *
     * Note: This value doesn't change after being initially created.
     */
    masterKeyEncryptedWithRecoveryKey?: string;
    /**
     * The nonce used during the encryption of
     * {@link masterKeyEncryptedWithRecoveryKey}.
     *
     * Base64 encoded.
     */
    masterKeyDecryptionNonce?: string;
    /**
     * The user's recovery key after being encrypted with their master key.
     *
     * Base64 encoded.
     *
     * Note: This value doesn't change after being initially created.
     */
    recoveryKeyEncryptedWithMasterKey?: string;
    /**
     * The nonce used during the encryption of
     * {@link recoveryKeyEncryptedWithMasterKey}.
     *
     * Base64 encoded.
     */
    recoveryKeyDecryptionNonce?: string;
}

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
 * Return {@link KeyAttributes} if they are present in local storage.
 *
 * The key attributes are stored in the browser's localStorage. Thus, this
 * function only works from the main thread, not from web workers (local storage
 * is not accessible to web workers).
 */
export const savedKeyAttributes = (): KeyAttributes | undefined => {
    const jsonString = localStorage.getItem("keyAttributes");
    if (!jsonString) return undefined;
    return RemoteKeyAttributes.parse(JSON.parse(jsonString));
};

/**
 * A variant of {@link savedKeyAttributes} that throws if keyAttributes are not
 * present in local storage.
 */
export const ensureSavedKeyAttributes = (): KeyAttributes =>
    ensureExpectedLoggedInValue(savedKeyAttributes());

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

export interface UpdatedKey {
    kekSalt: string;
    encryptedKey: string;
    keyDecryptionNonce: string;
    memLimit: number;
    opsLimit: number;
}

/**
 * Change the email associated with the user's account on remote.
 *
 * @param email The new email.
 *
 * @param ott The verification code that was sent to the new email.
 */
export const changeEmail = async (email: string, ott: string) =>
    ensureOk(
        await fetch(await apiURL("/users/change-email"), {
            method: "POST",
            headers: await authenticatedRequestHeaders(),
            body: JSON.stringify({ email, ott }),
        }),
    );

const TwoFactorSecret = z.object({
    /**
     * The 2FA secret code.
     */
    secretCode: z.string(),
    /**
     * A base64 encoded "image/png".
     */
    qrCode: z.string(),
});

export type TwoFactorSecret = z.infer<typeof TwoFactorSecret>;

/**
 * Start a TOTP based two factor setup process by fetching a secret code (and
 * the corresponding QR code) from remote.
 *
 * Once the user provides us with a TOTP generated using the provided secret, we
 * can finish the setup with {@link setupTwoFactorFinish}.
 */
export const setupTwoFactor = async (): Promise<TwoFactorSecret> => {
    const res = await fetch(await apiURL("/users/two-factor/setup"), {
        method: "POST",
        headers: await authenticatedRequestHeaders(),
    });
    ensureOk(res);
    return TwoFactorSecret.parse(await res.json());
};

/**
 * Finish the TOTP based two factor setup by provided a previously obtained
 * secret (using {@link setupTwoFactor}) and the current TOTP generated using
 * that secret.
 *
 * This updates both the state both locally and on remote.
 *
 * @param secretCode The value of {@link secretCode} from the
 * {@link TwoFactorSecret} obtained by {@link setupTwoFactor}.
 *
 * @param totp The current TOTP corresponding to {@link secretCode}.
 */
export const setupTwoFactorFinish = async (
    secretCode: string,
    totp: string,
) => {
    const box = await encryptBox(secretCode, await getUserRecoveryKey());
    await enableTwoFactor({
        code: totp,
        encryptedTwoFactorSecret: box.encryptedData,
        twoFactorSecretDecryptionNonce: box.nonce,
    });
    await setLSUser({ ...getData("user"), isTwoFactorEnabled: true });
};

interface EnableTwoFactorRequest {
    /**
     * The current value of the TOTP corresponding to the two factor {@link
     * secretCode} obtained from a previous call to {@link setupTwoFactor}.
     */
    code: string;
    /**
     * The {@link secretCode} encrypted with the user's recovery key.
     *
     * This is used in the case of second factor recovery.
     */
    encryptedTwoFactorSecret: string;
    /**
     * The nonce that was used when encrypting {@link encryptedTwoFactorSecret}.
     */
    twoFactorSecretDecryptionNonce: string;
}

/**
 * Enable the TOTP based two factor for the user by providing the current 2FA
 * code corresponding the two factor secret, and encrypted secrets for future
 * recovery (if needed).
 */
const enableTwoFactor = async (req: EnableTwoFactorRequest) =>
    ensureOk(
        await fetch(await apiURL("/users/two-factor/enable"), {
            method: "POST",
            headers: await authenticatedRequestHeaders(),
            body: JSON.stringify(req),
        }),
    );

/**
 * The result of a successful two factor verification (TOTP or passkey),
 * recovery removal (TOTP) or recovery bypass (passkey).
 */
export const TwoFactorAuthorizationResponse = z.object({
    /**
     * The user's ID
     */
    id: z.number(),
    /**
     * The user's key attributes.
     */
    keyAttributes: RemoteKeyAttributes,
    /**
     * A encrypted auth token.
     */
    encryptedToken: z.string(),
});

export type TwoFactorAuthorizationResponse = z.infer<
    typeof TwoFactorAuthorizationResponse
>;

export const verifyTwoFactor = async (
    code: string,
    sessionID: string,
): Promise<TwoFactorAuthorizationResponse> => {
    const res = await fetch(await apiURL("/users/two-factor/verify"), {
        method: "POST",
        headers: publicRequestHeaders(),
        body: JSON.stringify({ code, sessionID }),
    });
    ensureOk(res);
    return TwoFactorAuthorizationResponse.parse(await res.json());
};

/** The type of the second factor we're trying to act on */
export type TwoFactorType = "totp" | "passkey";

export interface TwoFactorRecoveryResponse {
    encryptedSecret: string;
    secretDecryptionNonce: string;
}

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

export interface TwoFactorVerificationResponse {
    id: number;
    keyAttributes: KeyAttributes;
    encryptedToken?: string;
    token?: string;
}

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
