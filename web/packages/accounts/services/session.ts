import {
    savedOriginalKeyAttributes,
    savedSRPAttributes,
} from "ente-accounts/services/accounts-db";
import type { KeyAttributes } from "ente-accounts/services/user";
import { authenticatedRequestHeaders, HTTPError } from "ente-base/http";
import log from "ente-base/log";
import { apiURL } from "ente-base/origins";
import { savedAuthToken } from "ente-base/token";
import { nullToUndefined } from "ente-utils/transform";
import { z } from "zod/v4";
import { getSRPAttributes, type SRPAttributes } from "./srp";
import {
    ensureLocalUser,
    putUserKeyAttributes,
    RemoteKeyAttributes,
} from "./user";

type SessionValidity =
    | { status: "invalid" }
    | { status: "valid" }
    | {
          status: "validButPasswordChanged";
          updatedKeyAttributes: KeyAttributes;
          updatedSRPAttributes: SRPAttributes;
      };

const SessionValidityResponse = z.object({
    hasSetKeys: z.boolean(),
    /**
     * Will not be present if {@link hasSetKeys} is `false`.
     */
    keyAttributes: RemoteKeyAttributes.nullish().transform(nullToUndefined),
});

/**
 * Check if the local token and/or key attributes we have are still valid.
 *
 * This function does not take any parameters because it reads the current state
 * (key attributes) from local storage.
 *
 * @returns
 *
 * - status "invalid" if the current token has been invalidated,
 * - status "valid" normally
 * - status "validButPasswordChanged" we detected that user changed their
 *   password on a different device (without choosing the option to log out of
 *   all existing sessions).
 *
 * ---
 *
 * [Note: Handling password changes]
 *
 * If the user changes their password on a different device, then we need to
 * update our local state so that we use the latest password for verification.
 *
 * There is a straightforward way of doing this by always making a blocking API
 * call before showing the password unlock page, however that would add latency
 * to the 99% user experience (of normal unlocks) for the 1% case (they've
 * changed their password elsewhere).
 *
 * The approach we instead use is to make an non-blocking `/session-validity`
 * API call when this page is loaded. Usually this'll complete well before the
 * password enters their password and presses "Sign in", but we also
 * transparently await for this API call to finish before initiating the actual
 * verification. Thus there is no extra latency in the happy paths.
 *
 * The `/session-validity` API call tells us:
 *
 * 1. Whether or not the session has been invalidated (by the user choosing to
 *    log out from all devices elsewhere).
 *
 * 2. What are their latest key attributes.
 *
 * If the session has been invalidated, we log them out here too.
 *
 * If the key attributes we get are different from the ones we have locally, we
 * regenerate new ones locally, and then use those for verifying the password
 * subsequently.
 */
export const checkSessionValidity = async (): Promise<SessionValidity> => {
    const res = await fetch(await apiURL("/users/session-validity/v2"), {
        headers: await authenticatedRequestHeaders(),
    });
    if (!res.ok) {
        if (res.status == 401)
            return { status: "invalid" }; /* session is no longer valid */
        else throw new HTTPError(res);
    }

    // See if the response contains keyAttributes (it will not if `hasSetKeys`
    // in the response is `false`).
    const { keyAttributes } = SessionValidityResponse.parse(await res.json());
    if (keyAttributes) {
        const remoteKeyAttributes = keyAttributes;

        // We should have these values locally if we reach here.
        const email = ensureLocalUser().email;
        const localSRPAttributes = savedSRPAttributes()!;

        // Fetch the remote SRP attributes.
        //
        // The key attributes we have saved locally are the locally generated
        // ones for interactive usage, and thus they'll always differ from the
        // ones we get from remote. To detect if the user changed their
        // password, we also need to fetch their SRP attributes (which will be
        // identical between remote and us if the password is the same).
        const remoteSRPAttributes = await getSRPAttributes(email);

        // If we get something (and usually we should),
        if (remoteSRPAttributes) {
            // See if it is different from the one we have locally. Use the kekSalt
            // as a proxy for comparing the entire object (The kekSalt will be
            // different if a new password has been generated).
            if (remoteSRPAttributes.kekSalt != localSRPAttributes.kekSalt) {
                // The token is still valid, but the key and SRP attributes have
                // changed.
                return {
                    status: "validButPasswordChanged",
                    updatedKeyAttributes: remoteKeyAttributes,
                    updatedSRPAttributes: remoteSRPAttributes,
                };
            }
        }
    }

    // The token is still valid.
    return { status: "valid" };
};

/**
 * Return `true` if the user does not have a saved auth token, of it is no
 * longer valid. If needed, also update the key attributes at remote.
 *
 * This is a subset of {@link checkSessionValidity} that has been tailored for
 * use during each remote pull, to detect if the user has been logged out
 * elsewhere.
 *
 * @returns `true` if either we don't have an auth token, or if remote tells us
 * that the auth token (and the associated session) has been invalidated. In all
 * other cases, return `false`.
 *
 * In particular, this function doesn't throw and instead returns `false` on
 * errors. This is because returning `true` will trigger a blocking alert that
 * ends in logging the user out, and we don't want to log the user out on on
 * e.g. transient network issues.
 */
export const isSessionInvalid = async (): Promise<boolean> => {
    const token = await savedAuthToken();
    if (!token) {
        return true; /* No saved token, session is invalid */
    }

    try {
        const res = await fetch(await apiURL("/users/session-validity/v2"), {
            headers: await authenticatedRequestHeaders(),
        });
        if (!res.ok) {
            if (res.status == 401) return true; /* session is no longer valid */
            else throw new HTTPError(res);
        }

        const { hasSetKeys } = SessionValidityResponse.parse(await res.json());
        if (!hasSetKeys) {
            const originalKeyAttributes = savedOriginalKeyAttributes();
            if (originalKeyAttributes)
                await putUserKeyAttributes(originalKeyAttributes);
        }
    } catch (e) {
        log.warn("Failed to check session validity", e);
        // Don't logout user on potentially transient errors.
        return false;
    }

    // Everything seems ok.
    return false;
};
