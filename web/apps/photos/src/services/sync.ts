import { fetchAndSaveFeatureFlagsIfNeeded } from "@/new/photos/services/feature-flags";
import {
    isMLSupported,
    triggerMLStatusSync,
    triggerMLSync,
} from "@/new/photos/services/ml";
import { syncEntities } from "services/entityService";
import { syncMapEnabled } from "services/userService";

/**
 * Part 1 of {@link sync}. See TODO below for why this is split.
 */
export const triggerPreFileInfoSync = () => {
    fetchAndSaveFeatureFlagsIfNeeded();
    if (isMLSupported) triggerMLStatusSync();
};

/**
 * Perform a soft "refresh" by making various API calls to fetch state from
 * remote, using it to update our local state, and triggering periodic jobs that
 * depend on the local state.
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
    await syncEntities();
    await syncMapEnabled();
    if (isMLSupported) triggerMLSync();
};
