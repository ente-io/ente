import log from "@/next/log";
import { ensure } from "@/utils/ensure";
import { apiOrigin } from "@ente/shared/network/api";
import { getToken } from "@ente/shared/storage/localStorage/helpers";

let _fetchTimeout: ReturnType<typeof setTimeout> | undefined;
let _haveFetched = false;

/**
 * Fetch feature flags (potentially user specific) from remote and save them in
 * local storage for subsequent lookup.
 *
 * It fetches only once per session, and so is safe to call as arbitrarily many
 * times. Remember to call {@link clearFeatureFlagSessionState} on logout to
 * forget that we've already fetched so that these can be fetched again on the
 * subsequent login.
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
    }, 5000);
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
    const url = `${apiOrigin}/remote-store/feature-flags`;
    const res = await fetch(url, {
        headers: {
            "X-Auth-Token": ensure(getToken()),
        },
    });
    if (!res.ok) throw new Error(`Failed to fetch ${url}: HTTP ${res.status}`);
    return res;
};

const saveFlagJSONString = (s: string) =>
    localStorage.setItem("remoteFeatureFlags", s);

const remoteFeatureFlags = () => {
    const s = localStorage.getItem("remoteFeatureFlags");
    if (!s) return undefined;
    return JSON.parse(s);
};

const remoteFeatureFlagsFetchingIfNeeded = async () => {
    let ff = await remoteFeatureFlags();
    if (!ff) {
        try {
            await fetchAndSaveFeatureFlags();
            ff = await remoteFeatureFlags();
        } catch (e) {
            log.warn("Ignoring error when fetching feature flags", e);
        }
    }
    return ff;
};

/**
 * Return `true` if the current user is marked as an "internal" user.
 */
export const isInternalUser = async () => {};

/**
 * Return `true` if the current user is marked as a "beta" user.
 */
export const isBetaUser = async () => {
    const flags = await remoteFeatureFlagsFetchingIfNeeded();
    // TODO(MR): Use Yup here
    if (
        flags &&
        typeof flags === "object" &&
        "betaUser" in flags &&
        typeof flags.betaUser == "boolean"
    )
        return flags.betaUser;
    return false;
};
