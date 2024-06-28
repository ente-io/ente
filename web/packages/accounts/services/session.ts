import { authenticatedRequestHeaders } from "@/next/http";
import { ensureLocalUser } from "@/next/local-user";
import { apiURL } from "@/next/origins";
import { ensure } from "@/utils/ensure";
import { LS_KEYS, getData } from "@ente/shared/storage/localStorage";
import type { KeyAttributes } from "@ente/shared/user/types";
import { getSRPAttributes } from "../api/srp";
import type { SRPAttributes } from "../types/srp";

type SessionValidity =
    | { status: "invalid" }
    | { status: "valid" }
    | {
          status: "validButPasswordChanged";
          updatedKeyAttributes: KeyAttributes;
          updatedSRPAttributes: SRPAttributes;
      };

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
    const url = await apiURL("/users/session-validity/v2");
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

        // We should have these values locally if we reach here.
        const email = ensureLocalUser().email;
        const localSRPAttributes = ensure(getData(LS_KEYS.SRP_ATTRIBUTES));

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

    // The token is still valid (to the best of our ascertainable knowledge).
    return { status: "valid" };
};
