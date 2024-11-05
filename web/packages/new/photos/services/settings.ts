/**
 * @file Storage (in-memory, local, remote) and update of various settings.
 */

/* eslint-disable @typescript-eslint/prefer-nullish-coalescing */

import { localUser } from "@/base/local-user";
import log from "@/base/log";
import { customAPIOrigin } from "@/base/origins";
import { nullToUndefined } from "@/utils/transform";
import { z } from "zod";
import { fetchFeatureFlags, updateRemoteFlag } from "./remote-store";

/**
 * In-memory flags that tracks various settings.
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
}

const defaultSettings = (): Settings => ({
    isInternalUser: false,
    mapEnabled: false,
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

const readInMemoryFlagsFromLocalStorage = () => {
    const flags = savedRemoteFeatureFlags();
    const settings = defaultSettings();
    settings.isInternalUser = flags?.internalUser || isInternalUserViaEmail();
    settings.mapEnabled = flags?.mapEnabled || false;
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

/**
 * Return true to disable the upload of files via Cloudflare Workers.
 *
 * These workers were introduced as a way of make file uploads faster:
 * https://ente.io/blog/tech/making-uploads-faster/
 *
 * By default, that's the route we take. However, during development or when
 * self-hosting it can be convenient to turn this flag on to directly upload to
 * the S3-compatible URLs returned by the ente API.
 *
 * Note the double negative (Enhancement: maybe remove the double negative,
 * rename this to say getUseDirectUpload).
 */
export async function getDisableCFUploadProxyFlag(): Promise<boolean> {
    // If a custom origin is set, that means we're not running a production
    // deployment (maybe we're running locally, or being self-hosted).
    //
    // In such cases, disable the Cloudflare upload proxy (which won't work for
    // self-hosters), and instead just directly use the upload URLs that museum
    // gives us.
    if (await customAPIOrigin()) return true;

    try {
        const featureFlags = (
            await fetch("https://static.ente.io/feature_flags.json")
        ).json() as GetFeatureFlagResponse;
        return featureFlags.disableCFUploadProxy ?? false;
    } catch (e) {
        log.error("failed to get feature flags", e);
        return false;
    }
}

export interface GetFeatureFlagResponse {
    disableCFUploadProxy?: boolean;
}
