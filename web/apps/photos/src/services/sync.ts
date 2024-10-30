import { isMLSupported, mlStatusSync, mlSync } from "@/new/photos/services/ml";
import { searchDataSync } from "@/new/photos/services/search";
import { triggerSettingsSyncIfNeeded } from "@/new/photos/services/settings";
import { syncMapEnabled } from "services/userService";

/**
 * Part 1 of {@link sync}. See TODO below for why this is split.
 */
export const preFileInfoSync = async () => {
    triggerSettingsSyncIfNeeded();
    await Promise.all([isMLSupported && mlStatusSync()]);
};

/**
 * Sync our local state with remote on page load for web and focus for desktop.
 *
 * This function makes various API calls to fetch state from remote, using it to
 * update our local state, and triggering periodic jobs that depend on the local
 * state.
 *
 * This runs on initial page load (on both web and desktop). In addition for
 * desktop, it also runs each time the desktop app gains focus.
 *
 * TODO: This is called after we've synced the local files DBs with remote. That
 * code belongs here, but currently that state is persisted in the top level
 * gallery React component.
 *
 * So meanwhile we've split this sync into this method, which is called after
 * the file info has been synced (which can take a few minutes for large
 * libraries after initial login), and the `preFileInfoSync`, which is called
 * before doing the file sync and thus should run immediately after login.
 */
export const sync = async () => {
    await Promise.all([syncMapEnabled(), searchDataSync()]);
    // ML sync might take a very long time for initial indexing, so don't wait
    // for it to finish.
    void mlSync();
};
