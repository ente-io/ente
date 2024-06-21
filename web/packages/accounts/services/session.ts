import { authenticatedRequestHeaders } from "@/next/http";
import { apiOrigin } from "@ente/shared/network/api";
import { LS_KEYS, getData } from "@ente/shared/storage/localStorage";
import type { KeyAttributes } from "@ente/shared/user/types";

type SessionValidity =
    | { status: "invalid" }
    | { status: "valid"; updatedKeyAttributes?: KeyAttributes };

/**
 * Check if the local token and/or key attributes we have are still valid.
 *
 * This function does not take any parameters because it reads the current state
 * (key attributes) from local storage.
 *
 * @returns status "invalid" if the current token has been invalidated, "valid"
 * otherwise. In case the {@link KeyAttributes} returned by remote are different
 * from the ones we have locally, then the {@link updatedKeyAttributes} property
 * will also be set alongwith the valid {@link status} in the result.
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
 * The approach we instead use is to make an non-blocking /session-validity API
 * call when this page is loaded. This API call tells us:
 *
 * 1.  Whether or not the session has been invalidated (by the user choosing to
 *     log out from all devices elsewhere).
 *
 * 2.  What are their latest key attributes.
 *
 * If the session has been invalidated, we log them out here too.
 *
 * If the key attributes we get are different from the ones we have locally, we
 * regenerate new ones locally, and then use those for verifying the password
 * subsequently.
 */
export const checkSessionValidity = async (): Promise<SessionValidity> => {
    const url = `${apiOrigin()}/users/session-validity/v2`;
    const res = await fetch(url, {
        headers: authenticatedRequestHeaders(),
    });
    if (!res.ok) {
        if (res.status == 401)
            return { status: "invalid" }; /* session is no longer valid */
        else throw new Error(`Failed to fetch ${url}: HTTP ${res.status}`);
    }
    // See if the response contains keyAttributes (they might not for older
    // deployments).
    const json = await res.json();
    if (
        "keyAttributes" in json &&
        typeof json.keyAttributes == "object" &&
        json.keyAttributes !== null
    ) {
        // Assume it is a `KeyAttributes`.
        //
        // Enhancement: Convert this to a zod validation.
        const remoteKeyAttributes = json.keyAttributes as KeyAttributes;
        // See if it is different from the one we have locally (if we have
        // something locally).
        const localKeyAttributes = getData(LS_KEYS.KEY_ATTRIBUTES);
        if (localKeyAttributes) {
            // The kekSalt will be different if the key attributes change.
            if (remoteKeyAttributes.kekSalt != localKeyAttributes.kekSalt) {
                // The token is still valid, but the key attributes have
                // changed.
                return {
                    status: "valid",
                    updatedKeyAttributes: remoteKeyAttributes,
                };
            }
        }
    }
    // The token is still valid, but AFAWK, the key attributes are still the same.
    return { status: "valid" };
};
