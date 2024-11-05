/**
 * @file Storage (in-memory, local, remote) and update of various settings.
 */

import { localUser } from "@/base/local-user";
import log from "@/base/log";
import { nullToUndefined } from "@/utils/transform";
import { z } from "zod";
import { fetchFeatureFlags, updateRemoteFlag } from "./remote-store";

/**
 * In-memory flags that tracks various settings.
 *
 * See: [Note: Remote flag lifecycle].
 */
export interface Settings {
    /**
     * `true` if the current user is an internal user.
     */
    isInternalUser: boolean;

    /**
     * `true` if maps are enabled.
     */
    isMapEnabled: boolean;
}

const defaultSettings = (): Settings => ({
    isInternalUser: false,
    isMapEnabled: false,
});

/**
 * Internal in-memory state shared by the functions in this module.
 *
 * This entire object will be reset on logout.
 */
class SettingsState {
    /**
     * An arbitrary token to identify the current login.
     *
     * It is used to discard stale completions.
     */
    id: number;

    constructor() {
        this.id = Math.random();
        this.settingsSnapshot = defaultSettings();
    }

    /**
     * True if we have performed a fetch for the logged in user since the app
     * started.
     */
    haveSynced = false;

    /**
     * Subscriptions to {@link Settings} updates.
     *
     * See {@link settingsSubscribe}.
     */
    settingsListeners: (() => void)[] = [];

    /**
     * Snapshot of the {@link Settings} returned by the {@link settingsSnapshot}
     * function.
     */
    settingsSnapshot: Settings;
}

/** State shared by the functions in this module. See {@link SettingsState}. */
let _state = new SettingsState();

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
 * [Note: Remote flag lifecycle]
 *
 * At a high level, this is how the app manages remote flags:
 *
 * 1.  On app start, the initial are read from local storage in
 *     {@link initSettings}.
 *
 * 2.  On app start, as part of the normal sync with remote, remote flags are
 *     fetched once and saved in local storage, and the in-memory state updated
 *     to reflect the latest values ({@link triggerSettingsSyncIfNeeded}). If
 *     this fetch fails, we try again periodically (on every sync with remote)
 *     until success.
 *
 * 3.  Some operations like opening the preferences panel or updating a value
 *     also cause an unconditional fetch and update ({@link syncSettings}).
 *
 * 4.  The individual getter functions for the flags (e.g.
 *     {@link isInternalUser}) return the in-memory values, and so are suitable
 *     for frequent use during UI rendering.
 *
 * 5.  Everything gets reset to the default state on {@link logoutSettings}.
 */
export const triggerSettingsSyncIfNeeded = () => {
    if (!_state.haveSynced) void syncSettings();
};

/**
 * Read in the locally persisted settings into memory, but otherwise do not
 * initiate any network requests to fetch the latest values.
 *
 * This assumes that the user is already logged in.
 */
export const initSettings = () => {
    readInMemoryFlagsFromLocalStorage();
};

export const logoutSettings = () => {
    _state = new SettingsState();
};

/**
 * Fetch remote flags from remote and save them in local storage for subsequent
 * lookup. Then use the results to update our in memory state if needed.
 */
export const syncSettings = async () => {
    const id = _state.id;
    const jsonString = await fetchFeatureFlags().then((res) => res.text());
    if (_state.id != id) {
        log.info("Discarding stale settings sync not for the current login");
        return;
    }
    saveRemoteFeatureFlagsJSONString(jsonString);
    readInMemoryFlagsFromLocalStorage();
    _state.haveSynced = true;
};

const saveRemoteFeatureFlagsJSONString = (s: string) =>
    localStorage.setItem("remoteFeatureFlags", s);

const savedRemoteFeatureFlags = () => {
    const s = localStorage.getItem("remoteFeatureFlags");
    if (!s) return undefined;
    return FeatureFlags.parse(JSON.parse(s));
};

const FeatureFlags = z.object({
    internalUser: z.boolean().nullish().transform(nullToUndefined),
    betaUser: z.boolean().nullish().transform(nullToUndefined),
});

type FeatureFlags = z.infer<typeof FeatureFlags>;

const readInMemoryFlagsFromLocalStorage = () => {
    const flags = savedRemoteFeatureFlags();
    const settings = defaultSettings();
    // eslint-disable-next-line @typescript-eslint/prefer-nullish-coalescing
    settings.isInternalUser = flags?.internalUser || isInternalUserViaEmail();
    setSettingsSnapshot(settings);
};

/**
 * A function that can be used to subscribe to updates to {@link Settings}.
 *
 * This, along with {@link settingsSnapshot}, is meant to be used as arguments
 * to React's {@link useSyncExternalStore}.
 *
 * @param callback A function that will be invoked whenever the result of
 * {@link settingsSnapshot} changes.
 *
 * @returns A function that can be used to clear the subscription.
 */
export const settingsSubscribe = (onChange: () => void): (() => void) => {
    _state.settingsListeners.push(onChange);
    return () => {
        _state.settingsListeners = _state.settingsListeners.filter(
            (l) => l != onChange,
        );
    };
};

/**
 * Return the last known, cached {@link Settings}.
 *
 * This, along with {@link settingsSubscribe}, is meant to be used as
 * arguments to React's {@link useSyncExternalStore}.
 */
export const settingsSnapshot = () => _state.settingsSnapshot;

const setSettingsSnapshot = (snapshot: Settings) => {
    _state.settingsSnapshot = snapshot;
    _state.settingsListeners.forEach((l) => l());
};

const isInternalUserViaEmail = () => {
    const user = localUser();
    return !!user?.email.endsWith("@ente.io");
};

/**
 * Return `true` if the current user is marked as an "internal" user.
 *
 * 1. Emails that end in `@ente.io` are considered as internal users.
 * 2. If the "internalUser" remote feature flag is set, the user is internal.
 * 3. Otherwise false.
 */
export const isInternalUser = () => settingsSnapshot().isInternalUser;

/**
 * Persist the user's map enabled preference both locally and on remote.
 */
export const updateMapEnabled = async (isEnabled: boolean) => {
    await updateRemoteFlag("mapEnabled", isEnabled);
    return syncSettings();
};
