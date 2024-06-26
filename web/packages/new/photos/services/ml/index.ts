/**
 * @file Main thread interface to {@link MLWorker}.
 */

import {
    isBetaUser,
    isInternalUser,
} from "@/new/photos/services/feature-flags";
import {
    getAllLocalFiles,
    getLocalTrashedFiles,
} from "@/new/photos/services/files";
import {
    faceIndex,
    indexableFileIDs,
    indexedAndIndexableCounts,
    updateAssumingLocalFiles,
} from "@/new/photos/services/ml/db";
import type { EnteFile } from "@/new/photos/types/file";
import { ComlinkWorker } from "@/next/worker/comlink-worker";
import { ensure } from "@/utils/ensure";
import { MLWorker } from "./worker";

/** Cached instance of the {@link ComlinkWorker} that wraps our web worker. */
let _comlinkWorker: ComlinkWorker<typeof MLWorker> | undefined;

/** Lazily created, cached, instance of {@link MLWorker}. */
export const worker = async () =>
    (_comlinkWorker ??= createComlinkWorker()).remote;

const createComlinkWorker = () =>
    new ComlinkWorker<typeof MLWorker>(
        "ml",
        new Worker(new URL("worker.ts", import.meta.url)),
    );

/**
 * Terminate {@link worker} (if any).
 *
 * This is useful during logout to immediately stop any background ML operations
 * that are in-flight for the current user. After the user logs in again, a new
 * {@link worker} will be created on demand for subsequent usage.
 */
export const terminateMLWorker = () => {
    if (_comlinkWorker) {
        _comlinkWorker.terminate();
        _comlinkWorker = undefined;
    }
};

export interface FaceIndexingStatus {
    /**
     * Which phase we are in within the indexing pipeline when viewed across the
     * user's entire library:
     *
     * - "scheduled": There are files we know of that have not been indexed.
     *
     * - "indexing": The face indexer is currently running.
     *
     * - "clustering": All files we know of have been indexed, and we are now
     *   clustering the faces that were found.
     *
     * - "done": Face indexing and clustering is complete for the user's
     *   library.
     */
    phase: "scheduled" | "indexing" | "clustering" | "done";
    /** The number of files that have already been indexed. */
    nSyncedFiles: number;
    /** The total number of files that are eligible for indexing. */
    nTotalFiles: number;
}

export const faceIndexingStatus = async (
    isSyncing: boolean,
): Promise<FaceIndexingStatus> => {
    const { indexedCount, indexableCount } = await indexedAndIndexableCounts();

    let phase: FaceIndexingStatus["phase"];
    if (indexableCount > 0) {
        if (!isSyncing) {
            phase = "scheduled";
        } else {
            phase = "indexing";
        }
    } else {
        phase = "done";
    }

    return {
        phase,
        nSyncedFiles: indexedCount,
        nTotalFiles: indexableCount + indexedCount,
    };
};

/**
 * Return the IDs of all the faces in the given {@link enteFile} that are not
 * associated with a person cluster.
 */
export const unidentifiedFaceIDs = async (
    enteFile: EnteFile,
): Promise<string[]> => {
    const index = await faceIndex(enteFile.id);
    return index?.faceEmbedding.faces.map((f) => f.faceID) ?? [];
};

/**
 * Return true if we should show an option to the user to allow them to enable
 * face search in the UI.
 */
export const canEnableFaceIndexing = async () =>
    (await isInternalUser()) || (await isBetaUser());

/**
 * Return true if the user has enabled face indexing in the app's settings.
 *
 * This setting is persisted locally (in local storage) and is not synced with
 * remote. There is a separate setting, "faceSearchEnabled" that is synced with
 * remote, but that tracks whether or not the user has enabled face search once
 * on any client. This {@link isFaceIndexingEnabled} property, on the other
 * hand, denotes whether or not indexing is enabled on the current client.
 */
export const isFaceIndexingEnabled = () =>
    localStorage.getItem("faceIndexingEnabled") == "1";

/**
 * Update the (locally stored) value of {@link isFaceIndexingEnabled}.
 */
export const setIsFaceIndexingEnabled = (enabled: boolean) =>
    enabled
        ? localStorage.setItem("faceIndexingEnabled", "1")
        : localStorage.removeItem("faceIndexingEnabled");

/**
 * Sync face DB with the local (and potentially indexable) files that we know
 * about. Then return the next {@link count} files that still need to be
 * indexed.
 *
 * For specifics of what a "sync" entails, see {@link updateAssumingLocalFiles}.
 *
 * @param userID Sync only files owned by a {@link userID} with the face DB.
 *
 * @param count Limit the resulting list of indexable files to {@link count}.
 */
export const syncWithLocalFilesAndGetFilesToIndex = async (
    userID: number,
    count: number,
): Promise<EnteFile[]> => {
    const isIndexable = (f: EnteFile) => f.ownerID == userID;

    const localFiles = await getAllLocalFiles();
    const localFilesByID = new Map(
        localFiles.filter(isIndexable).map((f) => [f.id, f]),
    );

    const localTrashFileIDs = (await getLocalTrashedFiles()).map((f) => f.id);

    await updateAssumingLocalFiles(
        Array.from(localFilesByID.keys()),
        localTrashFileIDs,
    );

    const fileIDsToIndex = await indexableFileIDs(count);
    return fileIDsToIndex.map((id) => ensure(localFilesByID.get(id)));
};
