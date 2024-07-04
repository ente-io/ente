/**
 * @file Main thread interface to the ML subsystem.
 */

import { FILE_TYPE } from "@/media/file-type";
import {
    isBetaUser,
    isInternalUser,
} from "@/new/photos/services/feature-flags";
import type { EnteFile } from "@/new/photos/types/file";
import { clientPackageName, isDesktop } from "@/next/app";
import { blobCache } from "@/next/blob-cache";
import { ensureElectron } from "@/next/electron";
import log from "@/next/log";
import { ComlinkWorker } from "@/next/worker/comlink-worker";
import { regenerateFaceCrops } from "./crop";
import { clearFaceDB, faceIndex, indexableAndIndexedCounts } from "./db";
import { MLWorker } from "./worker";

/**
 * In-memory flag that tracks if ML is enabled.
 *
 * -   On app start, this is read from local storage in the `initML` function.
 *
 * -   If the user updates their preference, then `setMLEnabled` will get called
 *     with the updated preference where this value will be updated (in addition
 *     to updating local storage).
 *
 * -   It is cleared in `logoutML`.
 */
let _isMLEnabled = false;

/** Cached instance of the {@link ComlinkWorker} that wraps our web worker. */
let _comlinkWorker: ComlinkWorker<typeof MLWorker> | undefined;

/** Lazily created, cached, instance of {@link MLWorker}. */
const worker = async () => {
    if (!_comlinkWorker) _comlinkWorker = await createComlinkWorker();
    return _comlinkWorker.remote;
};

const createComlinkWorker = async () => {
    const cw = new ComlinkWorker<typeof MLWorker>(
        "ml",
        new Worker(new URL("worker.ts", import.meta.url)),
    );
    const ua = await getUserAgent();
    await cw.remote.then((w) => w.init(ua));
    return cw;
};

const getUserAgent = async () =>
    `${clientPackageName}/${await ensureElectron().appVersion()}`;

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

/**
 * Initialize the ML subsystem if the user has enabled it in preferences.
 */
export const initML = () => {
    // ML currently only works when we're running in our desktop app.
    if (!isDesktop) return;
    // TODO-ML: Rename the isFace* flag since it now drives ML as a whole.
    _isMLEnabled = isFaceIndexingEnabled();
};

export const logoutML = async () => {
    // `terminateMLWorker` is conceptually also part of this, but for the
    // reasons mentioned in [Note: Caching IDB instances in separate execution
    // contexts], it gets called first in the logout sequence, and then this
    // `logoutML` gets called at a later point in time.
    _isMLEnabled = false;
    await clearFaceDB();
};

/**
 * Return true if we should show an option to the user to allow them to enable
 * face search in the UI.
 */
export const canEnableFaceIndexing = async () =>
    (await isInternalUser()) || (await isBetaUser());

/**
 * Return true if the user has enabled machine learning in their preferences.
 *
 * TODO-ML: The UI for this needs rework. We might retain the older remote (and
 * local) storage key, but otherwise this setting now reflects the state of ML
 * overall and not just face search.
 */
export const isMLEnabled = () =>
    // Impl note: Keep it fast, the UI directly calls this multiple times.
    _isMLEnabled;

/**
 * Enable ML.
 *
 * Persist the user's preference and trigger a sync.
 */
export const enableML = () => {
    setIsFaceIndexingEnabled(true);
    _isMLEnabled = true;
    triggerMLSync();
};

/**
 * Disable ML.
 *
 * Stop any in-progress ML tasks and persist the user's preference.
 */
export const disableML = () => {
    terminateMLWorker();
    setIsFaceIndexingEnabled(false);
    _isMLEnabled = false;
};

/**
 * Return true if the user has enabled face indexing in the app's settings.
 *
 * This setting is persisted locally (in local storage) and is not synced with
 * remote. There is a separate setting, "faceSearchEnabled" that is synced with
 * remote, but that tracks whether or not the user has enabled face search once
 * on any client. This {@link isFaceIndexingEnabled} property, on the other
 * hand, denotes whether or not indexing is enabled on the current client.
 */
const isFaceIndexingEnabled = () =>
    localStorage.getItem("faceIndexingEnabled") == "1";

/**
 * Update the (locally stored) value of {@link isFaceIndexingEnabled}.
 */
const setIsFaceIndexingEnabled = (enabled: boolean) =>
    enabled
        ? localStorage.setItem("faceIndexingEnabled", "1")
        : localStorage.removeItem("faceIndexingEnabled");

/**
 * Trigger a "sync", whatever that means for the ML subsystem.
 *
 * This is called during the global sync sequence. If ML is enabled, then we use
 * this as a signal to pull embeddings from remote, and start backfilling if
 * needed.
 *
 * This function does not wait for these processes to run to completion, and
 * returns immediately.
 */
export const triggerMLSync = () => {
    if (!_isMLEnabled) return;
    void worker().then((w) => w.sync());
};

/**
 * Run indexing on a file which was uploaded from this client.
 *
 * This function is called by the uploader when it uploads a new file from this
 * client, giving us the opportunity to index it live. This is only an
 * optimization - if we don't index it now it'll anyways get indexed later as
 * part of the batch jobs, but that might require downloading the file's
 * contents again.
 *
 * @param enteFile The {@link EnteFile} that got uploaded.
 *
 * @param file When available, the web {@link File} object representing the
 * contents of the file that got uploaded.
 */
export const indexNewlyUploadedFile = (
    enteFile: EnteFile,
    file: File | undefined,
) => {
    if (!_isMLEnabled) return;
    if (enteFile.metadata.fileType !== FILE_TYPE.IMAGE) return;
    log.debug(() => ({ t: "ml-liveq", enteFile, file }));
    // TODO-ML: 1. Use this file!
    // TODO-ML: 2. Handle cases when File is something else (e.g. on desktop).
    void worker().then((w) => w.onUpload(enteFile));
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

/**
 * Return the current state of the face indexing pipeline.
 *
 * Precondition: ML must be enabled.
 */
export const faceIndexingStatus = async (): Promise<FaceIndexingStatus> => {
    if (!isMLEnabled())
        throw new Error("Cannot get indexing status when ML is not enabled");

    const { indexedCount, indexableCount } = await indexableAndIndexedCounts();
    const isIndexing = await (await worker()).isIndexing();

    let phase: FaceIndexingStatus["phase"];
    if (indexableCount > 0) {
        phase = !isIndexing ? "scheduled" : "indexing";
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
 * Check to see if any of the faces in the given file do not have a face crop
 * present locally. If so, then regenerate the face crops for all the faces in
 * the file (updating the "face-crops" {@link BlobCache}).
 *
 * @returns true if one or more face crops were regenerated; false otherwise.
 */
export const regenerateFaceCropsIfNeeded = async (enteFile: EnteFile) => {
    const index = await faceIndex(enteFile.id);
    if (!index) return false;

    const faceIDs = index.faceEmbedding.faces.map((f) => f.faceID);
    const cache = await blobCache("face-crops");
    for (const id of faceIDs) {
        if (!(await cache.has(id))) {
            await regenerateFaceCrops(enteFile, index);
            return true;
        }
    }

    return false;
};
