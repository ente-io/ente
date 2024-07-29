import { authenticatedRequestHeaders, ensureOk } from "@/base/http";
import { localUser } from "@/base/local-user";
import log from "@/base/log";
import { apiURL } from "@/base/origins";
import { nullToUndefined } from "@/utils/transform";
import { z } from "zod";

let _fetchTimeout: ReturnType<typeof setTimeout> | undefined;
let _haveFetched = false;

/**
 * Fetch feature flags (potentially user specific) from remote and save them in
 * local storage for subsequent lookup.
 *
 * It fetches only once per session, and so is safe to call as arbitrarily many
 * times. Remember to call {@link clearFeatureFlagSessionState} on logout to
 * clear any in memory state so that these can be fetched again on the
 * subsequent login.
 *
 * [Note: Feature Flags]
 *
 * The workflow with feature flags is:
 *
 * 1. On app start feature flags are fetched once and saved in local storage. If
 *    this fetch fails, we try again periodically (on every "sync") until
 *    success.
 *
 * 2. Attempts to access any individual feature flage (e.g.
 *    {@link isInternalUser}) returns the corresponding value from local storage
 *    (substituting a default if needed).
 *
 * 3. However, if perchance the fetch-on-app-start hasn't completed yet (or had
 *    failed), then a new fetch is tried. If even this fetch fails, we return
 *    the default. Otherwise the now fetched result is saved to local storage
 *    and the corresponding value returned.
 */
export const fetchAndSaveFeatureFlagsIfNeeded = () => {
    if (_haveFetched) return;
    if (_fetchTimeout) return;
    // Not critical, so fetch these after some delay.
    _fetchTimeout = setTimeout(() => {
        _fetchTimeout = undefined;
        void fetchAndSaveFeatureFlags().then(() => {
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
 * Fetch feature flags (potentially user specific) from remote and save them in
 * local storage for subsequent lookup.
 */
const fetchAndSaveFeatureFlags = () =>
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
            await fetchAndSaveFeatureFlags();
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
