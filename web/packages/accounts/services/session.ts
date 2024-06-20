import { authenticatedRequestHeaders } from "@/next/http";
import { apiOrigin } from "@ente/shared/network/api";
import { LS_KEYS, getData } from "@ente/shared/storage/localStorage";
import type { KeyAttributes } from "@ente/shared/user/types";

const getSessionValidity = async () => {
    const url = `${apiOrigin()}/users/session-validity/v2`;
    const res = await fetch(url, {
        headers: authenticatedRequestHeaders()
    });
    if (!res.ok) {
        if (res.status == 401) return false; /* session is no longer valid */
        else throw new Error(`Failed to fetch ${url}: HTTP ${res.status}`);
    }


    export const isTokenValid = async (token: string) => {
        try {
            const resp = await HTTPService.get(
                `${ENDPOINT}/users/session-validity/v2`,
                null,
                {
                    "X-Auth-Token": token,
                },
            );
            try {
                if (resp.data[HAS_SET_KEYS] === undefined) {
                    throw Error("resp.data.hasSetKey undefined");
                }
                if (!resp.data["hasSetKeys"]) {
                    try {
                        await putAttributes(
                            token,
                            getData(LS_KEYS.ORIGINAL_KEY_ATTRIBUTES),
                        );
                    } catch (e) {
                        log.error("put attribute failed", e);
                    }
                }
            } catch (e) {
                log.error("hasSetKeys not set in session validity response", e);
            }
            return true;
        } catch (e) {
            log.error("session-validity api call failed", e);
            if (
                e instanceof ApiError &&
                e.httpStatusCode === HttpStatusCode.Unauthorized
            ) {
                return false;
            } else {
                return true;
            }
        }
    };

}
/**
 * [Note: Handle password changes]
 *
 * If the user changes their password on a different device, then we need to
 * update our local state so that we use the latest password for verification.
 *
 * There is a straightforward way of doing this by always making a blocking API
 * call before showing this page, however that would add latency to the 99% user
 * experience (of normal unlocks) for the 1% case (they've changed their
 * password elsewhere).
 *
 * Another alternative would be to non-blockingly check if their password has
 * changed (e.g. by comparing the remote and local SRP attributes), and if so,
 * log them out. This would be a robust solution, except users might've chosen
 * the "Don't log me out of other devices" option when changing their password
 * from the mobile app.
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
 * regenerate new ones locally, and then use those for verifying the password.
 *
 * It does not take any parameters because it reads the current state (key
 * attributes) from local storage.
 *
 * @returns true if the session is valid, false if the session is invalid, and
 * the (new) remote {@link KeyAttributes} if they've changed.
 *
 * @throws Exceptions if something goes wrong (it doesn't attempt to swallow
 * failures, it is upto the caller to decide how to deal with failures in
 * determining session validity).
 */
const checkSessionValidity = async (): boolean | KeyAttributes => {
    const user = getData(LS_KEYS.USER);
    if (!user?.email) return "invalid";

    try {
        const serverAttributes = await getSRPAttributes(email);
        // (Arbitrarily) compare the salt to figure out if something changed
        // (salt will always change on password changes).
        if (serverAttributes?.kekSalt !== localSRPAttributes.kekSalt)
            return true; /* password indeed did change */
        return false;
    } catch (e) {
        // Ignore errors here. In rare cases, the stars may align and cause the
        // API calls to fail in that 1 case where the user indeed changed their
        // password, but we also don't want to start logging people out for
        // harmless transient issues like network errors.
        log.error("Failed to compare SRP attributes", e);
        return false;
    }
};

