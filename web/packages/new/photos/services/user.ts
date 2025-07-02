import { ensureSavedKeyAttributes } from "ente-accounts/services/user";
import { boxSealOpenBytes, decryptBox } from "ente-base/crypto";
import type { KeyPair } from "ente-base/crypto/types";
import { authenticatedRequestHeaders, ensureOk } from "ente-base/http";
import { apiURL } from "ente-base/origins";
import { ensureMasterKeyFromSession } from "ente-base/session";
import { nullToUndefined } from "ente-utils/transform";
import { z } from "zod/v4";

/**
 * Return the public/private keypair of the currently logged in user.
 */
export const ensureUserKeyPair = async (): Promise<KeyPair> => {
    const { encryptedSecretKey, secretKeyDecryptionNonce, publicKey } =
        ensureSavedKeyAttributes();
    const privateKey = await decryptBox(
        { encryptedData: encryptedSecretKey, nonce: secretKeyDecryptionNonce },
        await ensureMasterKeyFromSession(),
    );
    return { publicKey, privateKey };
};

/**
 * Fetch the public key from remote for the user (if any) who has registered
 * with remote with the given {@link email}.
 *
 * @returns the base64 encoded public key of the user with {@link email}.
 */
export const getPublicKey = async (email: string) => {
    const res = await fetch(await apiURL("/users/public-key", { email }), {
        headers: await authenticatedRequestHeaders(),
    });
    ensureOk(res);
    return z.object({ publicKey: z.string() }).parse(await res.json())
        .publicKey;
};

/**
 * Fetch the two-factor status (whether or not it is enabled) from remote.
 */
export const get2FAStatus = async () => {
    const res = await fetch(await apiURL("/users/two-factor/status"), {
        headers: await authenticatedRequestHeaders(),
    });
    ensureOk(res);
    return z.object({ status: z.boolean() }).parse(await res.json()).status;
};

/**
 * Disable two-factor authentication for the current user on remote.
 */
export const disable2FA = async () =>
    ensureOk(
        await fetch(await apiURL("/users/two-factor/disable"), {
            method: "POST",
            headers: await authenticatedRequestHeaders(),
        }),
    );

const DeleteChallengeResponse = z.object({
    // allowDelete indicates whether the user is allowed to delete their account
    // via app (some special-cased accounts might need to contact support).
    allowDelete: z.boolean(),
    // An encrypted challenge that the client needs to decrypt and provide in
    // the actual account deletion request.
    encryptedChallenge: z.string().nullish().transform(nullToUndefined),
});

/**
 * Initiate an account deletion by obtaining a delete challenge from remote.
 *
 * Account deletion is a three step process:
 *
 * 1. Client obtains a encrypted challenge from remote by using
 *    {@link getAccountDeleteChallenge}.
 *
 * 2. Client asks the user to reverify their password to solve the challenge and
 *    obtain the decrypted challenge ({@link decryptDeleteAccountChallenge}).
 *
 * 3. Client performs the account deletion using the solved challenge
 *    ({@link deleteAccount}).
 */
export const getAccountDeleteChallenge = async () => {
    const res = await fetch(await apiURL("/users/delete-challenge"), {
        headers: await authenticatedRequestHeaders(),
    });
    ensureOk(res);
    return DeleteChallengeResponse.parse(await res.json());
};

/**
 * Decrypt the {@link encryptedChallenge} sent by remote during the delete
 * account flow ({@link getAccountDeleteChallenge}), returning a value that can
 * then directly be passed to the actual delete account request
 * ({@link deleteAccount}).
 */
export const decryptDeleteAccountChallenge = async (
    encryptedChallenge: string,
) =>
    new TextDecoder().decode(
        await boxSealOpenBytes(encryptedChallenge, await ensureUserKeyPair()),
    );

/**
 * Delete the logged in user's account on remote.
 *
 * @param challenge Decrypted value of the challenge previously obtained via
 * {@link getAccountDeleteChallenge}. The decryption algorithm is implemented in
 * {@link decryptDeleteAccountChallenge}.
 */
export const deleteAccount = async (
    challenge: string,
    reason: string,
    feedback: string,
) =>
    ensureOk(
        await fetch(await apiURL("/users/delete"), {
            method: "DELETE",
            headers: await authenticatedRequestHeaders(),
            body: JSON.stringify({ challenge, reason, feedback }),
        }),
    );
