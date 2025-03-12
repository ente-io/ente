/* eslint-disable @typescript-eslint/no-empty-function */
import { resetFileViewerDataSourceOnClose } from "@/gallery/components/viewer/data-source";
import { isHiddenCollection } from "@/new/photos/services/collection";
import {
    getAllLatestCollections,
    syncTrash,
} from "@/new/photos/services/collections";
import { syncFiles } from "@/new/photos/services/files";
import { isMLSupported, mlStatusSync, mlSync } from "@/new/photos/services/ml";
import { searchDataSync } from "@/new/photos/services/search";
import { syncSettings } from "@/new/photos/services/settings";
import { splitByPredicate } from "@/utils/array";

/**
 * Part 1 of {@link sync}. See TODO below for why this is split.
 */
export const preCollectionsAndFilesSync = async () => {
    await Promise.all([syncSettings(), isMLSupported && mlStatusSync()]);
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
    await Promise.all([searchDataSync()]);
    // ML sync might take a very long time for initial indexing, so don't wait
    // for it to finish.
    void mlSync();
};

/**
 * Sync our local file and collection state with remote.
 *
 * This is a subset of {@link sync}, independently exposed for use at times when
 * we only want to sync collections and files (e.g. we just made some API
 * request that modified collections or files, and so now want to sync our local
 * changes to match remote).
 *
 * A bespoke version of this in currently used by the gallery component when it
 * syncs - it needs a broken down, bespoke version because it also keeps local
 * state variables that need to be updated with the various callbacks that we
 * ignore in this version.
 */
export const syncFilesAndCollections = async () => {
    const allCollections = await getAllLatestCollections();
    const [hiddenCollections, normalCollections] = splitByPredicate(
        allCollections,
        isHiddenCollection,
    );
    const didUpdateNormalFiles = await syncFiles(
        "normal",
        normalCollections,
        () => {},
        () => {},
    );
    const didUpdateHiddenFiles = await syncFiles(
        "hidden",
        hiddenCollections,
        () => {},
        () => {},
    );
    await syncTrash(allCollections, () => {});
    if (didUpdateNormalFiles || didUpdateHiddenFiles) {
        // TODO: Ok for now since we're only called by deduper, but still needs
        // fixing instead of a hidden gotcha.
        // exportService.onLocalFilesUpdated();
        resetFileViewerDataSourceOnClose();
    }
};
