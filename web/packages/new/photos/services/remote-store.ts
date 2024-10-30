import { authenticatedRequestHeaders, ensureOk } from "@/base/http";
import { localUser } from "@/base/local-user";
import log from "@/base/log";
import { apiURL } from "@/base/origins";
import { nullToUndefined } from "@/utils/transform";
import { z } from "zod";

/**
 * Internal in-memory state shared by the functions in this module.
 *
 * This entire object will be reset on logout.
 */
class SettingsState {
    /**
     * In-memory flag that tracks if maps are enabled.
     *
     * -   On app start, this is read from local storage in
     *     {@link initSettings}.
     *
     * -   It gets updated when we sync with remote (once per app start in
     *     {@link triggerRemoteFlagsFetchIfNeeded}, and whenever the user opens
     *     the preferences panel).
     *
     * -   It gets updated when the user toggles the corresponding setting on
     *     this device.
     *
     * -   It is cleared in {@link logoutML}.
     */
    isMapEnabled = false;
}

let _fetchTimeout: ReturnType<typeof setTimeout> | undefined;
let _haveFetched = false;

/**
 * Fetch remote flags (feature flags and other user specific preferences) from
 * remote and save them in local storage for subsequent lookup.
 *
 * It fetches only once per app lifetime, and so is safe to call as arbitrarily
 * many times. Remember to call {@link clearFeatureFlagSessionState} on logout
 * to clear any in memory state so that these can be fetched again on the
 * subsequent login.
 *
 * The local cache will also be updated if an individual flag is changed.
 *
 * [Note: Remote flags]
 *
 * The remote store provides a unified interface for persisting varied "remote
 * flags":
 *
 * -   User preferences like "mapEnabled"
 *
 * -   Feature flags like "isInternalUser"
 *
 * There are two APIs to get the current state from remote:
 *
 * 1.  GET /remote-store/feature-flags fetches the combined state (nb: even
 *     though the name of the endpoint has the word feature-flags, it also
 *     includes user preferences).
 *
 * 2.  GET /remote-store fetches individual values.
 *
 * Usually 1 is what we use, since it gets us everything in a single go, and
 * which we can also easily cache in local storage by saving the entire response
 * JSON blob.
 *
 * There is a single API (/remote-store/update) to update the state on remote.
 *
 * At a high level, this is how the app manages this state:
 *
 * 1.  On app start remote flags are fetched once and saved in local storage. If
 *     this fetch fails, we try again periodically (on every "sync") until
 *     success.
 *
 * 2. Attempts to access any individual feature flag (e.g.
 *    {@link isInternalUser}) returns the corresponding value from local storage
 *    (substituting a default if needed).
 *
 * 3. However, if perchance the fetch-on-app-start hasn't completed yet (or had
 *    failed), then a new fetch is tried. If even this fetch fails, we return
 *    the default. Otherwise the now fetched result is saved to local storage
 *    and the corresponding value returned.
 */
export const triggerRemoteFlagsFetchIfNeeded = () => {
    if (_haveFetched) return;
    if (_fetchTimeout) return;
    // Not critical, so fetch these after some delay.
    _fetchTimeout = setTimeout(() => {
        _fetchTimeout = undefined;
        void fetchAndSaveRemoteFlags().then(() => {
            _haveFetched = true;
        });
    }, 2000);
};

export const clearFeatureFlagSessionState = () => {
    if (_fetchTimeout) {
        clearTimeout(_fetchTimeout);
        _fetchTimeout = undefined;
    }
    _haveFetched = false;
};

/**
 * Fetch remote flags from remote and save them in local storage for subsequent
 * lookup.
 */
const fetchAndSaveRemoteFlags = () =>
    fetchFeatureFlags()
        .then((res) => res.text())
        .then(saveFlagJSONString);

const fetchFeatureFlags = async () => {
    const res = await fetch(await apiURL("/remote-store/feature-flags"), {
        headers: await authenticatedRequestHeaders(),
    });
    ensureOk(res);
    return res;
};

const saveFlagJSONString = (s: string) =>
    localStorage.setItem("remoteFeatureFlags", s);

const remoteFeatureFlags = () => {
    const s = localStorage.getItem("remoteFeatureFlags");
    if (!s) return undefined;
    return FeatureFlags.parse(JSON.parse(s));
};

const FeatureFlags = z.object({
    internalUser: z.boolean().nullish().transform(nullToUndefined),
    betaUser: z.boolean().nullish().transform(nullToUndefined),
});

type FeatureFlags = z.infer<typeof FeatureFlags>;

const remoteFeatureFlagsFetchingIfNeeded = async () => {
    let ff = remoteFeatureFlags();
    if (!ff) {
        try {
            await fetchAndSaveRemoteFlags();
        } catch (e) {
            log.warn("Ignoring error when fetching feature flags", e);
        }
        ff = remoteFeatureFlags();
    }
    return ff;
};

/**
 * Return `true` if the current user is marked as an "internal" user.
 *
 * 1. Emails that end in `@ente.io` are considered as internal users.
 * 2. If the "internalUser" remote feature flag is set, the user is internal.
 * 3. Otherwise false.
 *
 * See also: [Note: Feature Flags].
 */
export const isInternalUser = async () => {
    const user = localUser();
    if (user?.email.endsWith("@ente.io")) return true;

    const flags = await remoteFeatureFlagsFetchingIfNeeded();
    return flags?.internalUser ?? false;
};

/**
 * Return `true` if the current user is marked as a "beta" user.
 *
 * See also: [Note: Feature Flags].
 */
export const isBetaUser = async () => {
    const flags = await remoteFeatureFlagsFetchingIfNeeded();
    return flags?.betaUser ?? false;
};

/**
 * Fetch the value for the given {@link key} from remote store.
 *
 * If the key is not present in the remote store, return {@link defaultValue}.
 */
export const getRemoteValue = async (key: string, defaultValue: string) => {
    const url = await apiURL("/remote-store");
    const params = new URLSearchParams({ key, defaultValue });
    const res = await fetch(`${url}?${params.toString()}`, {
        headers: await authenticatedRequestHeaders(),
    });
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
