import { authenticatedRequestHeaders, ensureOk } from "ente-base/http";
import { apiURL } from "ente-base/origins";
import { z } from "zod/v4";

/**
 * [Note: Remote store]
 *
 * The remote store provides a unified interface for persisting varied "remote
 * flags":
 *
 * - User preferences like "mapEnabled"
 *
 * - Feature flags like "isInternalUser"
 *
 * There are two APIs to get the current state from remote:
 *
 * 1. GET /remote-store/feature-flags fetches the combined state (nb: even
 *    though the name of the endpoint has the word feature-flags, it also
 *    includes user preferences).
 *
 * 2. GET /remote-store fetches individual values.
 *
 * Usually 1 is what we use, since it gets us everything in a single go, and
 * which we can also easily cache in local storage by saving the entire response
 * JSON blob.
 *
 * There is a single API (/remote-store/update) to update the state on remote.
 */
export const fetchFeatureFlags = async () => {
    const res = await fetch(await apiURL("/remote-store/feature-flags"), {
        headers: await authenticatedRequestHeaders(),
    });
    ensureOk(res);
    return res;
};

/**
 * Fetch the value for the given {@link key} from remote store.
 *
 * If the key is not present in the remote store, return {@link defaultValue}.
 */
export const getRemoteValue = async (key: string, defaultValue: string) => {
    const res = await fetch(
        await apiURL("/remote-store", { key, defaultValue }),
        { headers: await authenticatedRequestHeaders() },
    );
    ensureOk(res);
    return GetRemoteStoreResponse.parse(await res.json())?.value;
};

const GetRemoteStoreResponse = z.object({ value: z.string() }).nullable();

/**
 * Convenience wrapper over {@link getRemoteValue} that returns booleans.
 */
export const getRemoteFlag = async (key: string) =>
    (await getRemoteValue(key, "false")) == "true";

/**
 * Update or insert {@link value} for the given {@link key} into remote store.
 */
export const updateRemoteValue = async (key: string, value: string) =>
    ensureOk(
        await fetch(await apiURL("/remote-store/update"), {
            method: "POST",
            headers: await authenticatedRequestHeaders(),
            body: JSON.stringify({ key, value }),
        }),
    );

/**
 * Convenience wrapper over {@link updateRemoteValue} that sets booleans.
 */
export const updateRemoteFlag = (key: string, value: boolean) =>
    updateRemoteValue(key, JSON.stringify(value));
