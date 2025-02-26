import { authenticatedRequestHeaders, ensureOk } from "@/base/http";
import { apiURL } from "@/base/origins";
import { nullToUndefined } from "@/utils/transform";
import { z } from "zod";

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
    encryptedChallenge: z.string().nullable().transform(nullToUndefined),
});

export const getAccountDeleteChallenge = async () => {
    const res = await fetch(await apiURL("/users/delete-challenge"), {
        headers: await authenticatedRequestHeaders(),
    });
    ensureOk(res);
    return DeleteChallengeResponse.parse(await res.json());
};

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
