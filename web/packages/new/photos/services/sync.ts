import { resetFileViewerDataSourceOnClose } from "ente-gallery/components/viewer/data-source";
import { videoProcessingSyncIfNeeded } from "ente-gallery/services/video";
import type { Collection } from "ente-media/collection";
import type { EnteFile } from "ente-media/file";
import { isHiddenCollection } from "ente-new/photos/services/collection";
import {
    getAllLatestCollections,
    syncTrash,
} from "ente-new/photos/services/collections";
import { syncFiles } from "ente-new/photos/services/files";
import {
    isMLSupported,
    mlStatusSync,
    mlSync,
} from "ente-new/photos/services/ml";
import { searchDataSync } from "ente-new/photos/services/search";
import { syncSettings } from "ente-new/photos/services/settings";
import { splitByPredicate } from "ente-utils/array";

/**
 * Called during a full sync, before doing the collection and file sync.
 *
 * [Note: Remote sync]
 *
 * There are two types of remote syncs we perform:
 *
 * - A "collection and file" sync: Syncing our local state of collections and
 *   files with remote.
 *
 * - A "full" sync, which includes the collection and file sync, and more.
 *
 * The full sync is performed by the gallery page, in the following sequence:
 *
 * 1. {@link preCollectionAndFilesSync}
 * 2. {@link syncCollectionAndFiles}
 * 3. {@link postCollectionAndFilesSync}.
 *
 * In some other cases, where we know that only specific collection and/or file
 * state needs to be synced, step 2 ({@link syncCollectionAndFiles}) is
 * performed independently. The only example of such a cases currently is:
 *
 * - After deduping files.
 *
 * The full sync is performed in the following cases:
 *
 * - On the gallery page load (for both web and desktop).
 * - Every 5 minutes thereafter (while the user is on the gallery page).
 * - Each time the desktop app gains focus.
 * - When the file viewer is closed after performing some operation.
 */
export const preCollectionAndFilesSync = async () => {
    await Promise.all([syncSettings(), isMLSupported && mlStatusSync()]);
};

/**
 * Called during a full sync, after doing the collection and file sync.
 *
 * See: [Note: Remote sync]
 */
export const postCollectionAndFilesSync = async () => {
    await Promise.all([searchDataSync(), videoProcessingSyncIfNeeded()]);
    // ML sync might take a very long time for initial indexing, so don't wait
    // for it to finish.
    void mlSync();
};

interface SyncCallectionAndFilesOpts {
    /**
     * Called when saved collections, both normal and hidden, are (potentially)
     * updated.
     *
     * The callback is passed all the collections (as {@link collections}), and
     * also their splits into normal ({@link normalCollections}) and hidden
     * ({@link hiddenCollections}).
     */
    onSetCollections: (
        collections: Collection[],
        normalCollections: Collection[],
        hiddenCollections: Collection[],
    ) => void;
    /**
     * Called when saved normal (non-hidden, non-trash) files were replaced by
     * the given {@link files}.
     */
    onResetNormalFiles: (files: EnteFile[]) => void;
    /**
     * Called when saved normal files were augmented with the given newly
     * fetched {@link files}.
     */
    onFetchNormalFiles: (files: EnteFile[]) => void;
    /**
     * Called when saved hidden files were replaced by the given {@link files}.
     */
    onResetHiddenFiles: (files: EnteFile[]) => void;
    /**
     * Called when saved hidden files were augmented with the given newly
     * fetched {@link files}.
     */
    onFetchHiddenFiles: (files: EnteFile[]) => void;
    /**
     * Called when saved trashed files were replaced by the given {@link files}.
     */
    onResetTrashedFiles: (files: EnteFile[]) => void;
}

/**
 * Sync our local file and collection state with remote.
 *
 * This is a subset of a full sync, independently exposed for use at times when
 * we only want to sync collections and files (e.g. we just made some API
 * request that modified collections or files, and so now want to sync our local
 * changes to match remote).
 *
 * See: [Note: Remote sync]
 *
 * @param opts various callbacks that are used by gallery to update its local
 * state in tandem with the sync. The callbacks are optional since we might not
 * have local state to update, as is the case when this is invoked post dedup.
 *
 * @returns `true` if one or more normal or hidden files were updated during the
 * sync.
 */
export const syncCollectionAndFiles = async (
    opts?: SyncCallectionAndFilesOpts,
) => {
    const collections = await getAllLatestCollections();
    const [hiddenCollections, normalCollections] = splitByPredicate(
        collections,
        isHiddenCollection,
    );
    opts?.onSetCollections(collections, normalCollections, hiddenCollections);
    const didUpdateNormalFiles = await syncFiles(
        "normal",
        normalCollections,
        opts?.onResetNormalFiles,
        opts?.onFetchNormalFiles,
    );
    const didUpdateHiddenFiles = await syncFiles(
        "hidden",
        hiddenCollections,
        opts?.onResetHiddenFiles,
        opts?.onFetchHiddenFiles,
    );
    await syncTrash(collections, opts?.onResetTrashedFiles);
    if (didUpdateNormalFiles || didUpdateHiddenFiles) {
        // TODO: Ok for now since its is only commented for the deduper (gallery
        // does this on the return value), but still needs fixing instead of a
        // hidden gotcha. Fix is simple, just uncomment, but that can be done
        // once the exportService can be imported here in the ente-new package.
        //
        // exportService.onLocalFilesUpdated();
        resetFileViewerDataSourceOnClose();
        return true;
    }
    return false;
};
