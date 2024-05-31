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
const fetchAndSaveFeatureFlags = async () => {};

/**
 * Return `true` if the current user is marked as an "internal" user.
 */
export const isInternalUser = async () => {};

/**
 * Return `true` if the current user is marked as an "beta" user.
 */
export const isBetaUser = async () => {};
