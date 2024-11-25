/**
 * @file Storage (in-memory, local, remote) and update of various settings.
 */

/* eslint-disable @typescript-eslint/prefer-nullish-coalescing */

import { localUser } from "@/base/local-user";
import log from "@/base/log";
import { updateShouldDisableCFUploadProxy } from "@/gallery/services/upload";
import { nullToUndefined } from "@/utils/transform";
import { z } from "zod";
import { fetchFeatureFlags, updateRemoteFlag } from "./remote-store";

/**
 * In-memory flags that tracks various settings.
 *
 * Some of these are local only, some of these are synced with remote.
 *
 * [Note: Remote flag lifecycle]
 *
 * At a high level, this is how the app manages remote flags:
 *
 * 1.  On app start, the initial are read from local storage in
 *     {@link initSettings}.
 *
 * 2.  During the remote sync, remote flags are fetched and saved in local
 *     storage, and the in-memory state updated to reflect the latest values
 *     ({@link syncSettings}).
 *
 * 3.  Updating a value also cause an unconditional fetch and update
 *     ({@link syncSettings}).
 *
 * 4.  The individual getter functions for the flags (e.g.
 *     {@link isInternalUser}) return the in-memory values, and so are suitable
 *     for frequent use during UI rendering.
 *
 * 5.  Everything gets reset to the default state on {@link logoutSettings}.
 */
export interface Settings {
    /**
     * `true` if the current user is an internal user.
     */
    isInternalUser: boolean;

    /**
     * `true` if maps are enabled.
     */
    mapEnabled: boolean;

    /**
     * `true` if the user has saved a preference to disable workers for uploads.
     *
     * Unlike {@link shouldDisableCFUploadProxy}, whose value reflects other
     * factors that are taken into account to determine the effective value of
     * this setting, this function returns only the saved user preference.
     */
    cfUploadProxyDisabled: boolean;
}

const defaultSettings = (): Settings => ({
    isInternalUser: false,
    mapEnabled: false,
    cfUploadProxyDisabled: false,
});

/**
 * Internal in-memory state shared by the functions in this module.
 *
 * This entire object will be reset on logout.
 */
class SettingsState {
    constructor() {
        this.settingsSnapshot = defaultSettings();
    }

    /**
     * Subscriptions to {@link Settings} updates attached using
     * {@link settingsSubscribe}.
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
 * Read in the locally persisted settings into memory, but otherwise do not
 * initiate any network requests to fetch the latest values.
 *
 * This assumes that the user is already logged in.
 */
export const initSettings = () => {
    void updateShouldDisableCFUploadProxy(savedCFProxyDisabled());
    syncSettingsSnapshotWithLocalStorage();
};

export const logoutSettings = () => {
    _state = new SettingsState();
};

/**
 * Fetch remote flags from remote and save them in local storage for subsequent
 * lookup. Then use the results to update our in memory state if needed.
 */
export const syncSettings = async () => {
    const jsonString = await fetchFeatureFlags().then((res) => res.text());
    saveRemoteFeatureFlagsJSONString(jsonString);
    syncSettingsSnapshotWithLocalStorage();
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
    mapEnabled: z.boolean().nullish().transform(nullToUndefined),
});

type FeatureFlags = z.infer<typeof FeatureFlags>;

const syncSettingsSnapshotWithLocalStorage = () => {
    const flags = savedRemoteFeatureFlags();
    const settings = defaultSettings();
    settings.isInternalUser = flags?.internalUser || isInternalUserViaEmail();
    settings.mapEnabled = flags?.mapEnabled || false;
    settings.cfUploadProxyDisabled = savedCFProxyDisabled();
    setSettingsSnapshot(settings);
};

/**
 * A function that can be used to subscribe to updates to {@link Settings}.
 *
 * See: [Note: Snapshots and useSyncExternalStore].
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
 * See also {@link settingsSubscribe}.
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

const cfProxyDisabledKey = "cfProxyDisabled";

const saveCFProxyDisabled = (v: boolean) =>
    v
        ? localStorage.setItem(cfProxyDisabledKey, "1")
        : localStorage.removeItem(cfProxyDisabledKey);

const savedCFProxyDisabled = () => {
    const v = localStorage.getItem(cfProxyDisabledKey);
    if (!v) return false;
    if (v == "1") return true;

    // Older versions of the app used to store this flag in a different
    // format, so see if this is one of those, and if so, migrate it too.
    try {
        const value = z
            .object({ value: z.boolean() })
            .parse(JSON.parse(v)).value;
        saveCFProxyDisabled(value);
        return value;
    } catch (e) {
        log.warn(`Ignoring ${cfProxyDisabledKey} value: ${v}`, e);
        localStorage.removeItem(cfProxyDisabledKey);
        return false;
    }
};

/**
 * Save the user preference for disabling uploads via Cloudflare Workers, also
 * notifying the upload subsystem of the change.
 */
export const updateCFProxyDisabledPreference = async (value: boolean) => {
    saveCFProxyDisabled(value);
    await updateShouldDisableCFUploadProxy(value);
    syncSettingsSnapshotWithLocalStorage();
};
