/**
 * @file Main thread interface to the ML subsystem.
 */

import { FILE_TYPE } from "@/media/file-type";
import {
    isBetaUser,
    isInternalUser,
} from "@/new/photos/services/feature-flags";
import type { EnteFile } from "@/new/photos/types/file";
import { isDesktop } from "@/next/app";
import { blobCache } from "@/next/blob-cache";
import { ensureElectron } from "@/next/electron";
import log from "@/next/log";
import { ComlinkWorker } from "@/next/worker/comlink-worker";
import { proxy } from "comlink";
import { getRemoteFlag, updateRemoteFlag } from "../remote-store";
import type { UploadItem } from "../upload/types";
import { regenerateFaceCrops } from "./crop";
import { clearMLDB, faceIndex, indexableAndIndexedCounts } from "./db";
import { MLWorker } from "./worker";

/**
 * In-memory flag that tracks if ML is enabled locally.
 *
 * -   On app start, this is read from local storage during {@link initML}.
 *
 * -   It gets updated if the user enables/disables ML (remote) or if they
 *     pause/resume ML (local).
 *
 * -   It is cleared in {@link logoutML}.
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
    const electron = ensureElectron();
    const mlWorkerElectron = {
        appVersion: electron.appVersion,
        detectFaces: electron.detectFaces,
        computeFaceEmbeddings: electron.computeFaceEmbeddings,
        computeCLIPImageEmbedding: electron.computeCLIPImageEmbedding,
    };

    const cw = new ComlinkWorker<typeof MLWorker>(
        "ML",
        new Worker(new URL("worker.ts", import.meta.url)),
    );
    await cw.remote.then((w) => w.init(proxy(mlWorkerElectron)));
    return cw;
};

/**
 * Terminate {@link worker} (if any).
 *
 * This is useful during logout to immediately stop any background ML operations
 * that are in-flight for the current user. After the user logs in again, a new
 * {@link worker} will be created on demand for subsequent usage.
 *
 * It is also called when the user pauses or disables ML.
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
    _isMLEnabled = isMLEnabledLocally();
};

export const logoutML = async () => {
    // `terminateMLWorker` is conceptually also part of this, but for the
    // reasons mentioned in [Note: Caching IDB instances in separate execution
    // contexts], it gets called first in the logout sequence, and then this
    // function (`logoutML`) gets called at a later point in time.
    _isMLEnabled = false;
    await clearMLDB();
};

/**
 * Return true if we should show an UI option to the user to allow them to
 * enable ML.
 */
export const canEnableML = async () =>
    (await isInternalUser()) || (await isBetaUser());

/**
 * Return true if the user has enabled machine learning in their preferences.
 *
 * [Note: ML preferences]
 *
 * The user may enable ML. This enables in both locally by persisting a local
 * storage flag, and sets a flag on remote so that the user's other devices can
 * also enable it.
 *
 * The user may pause ML locally. This does not modify the remote flag, but it
 * unsets the local flag. Subsequently resuming ML (locally) will set the local
 * flag again.
 *
 * ML related operations are driven by the {@link isMLEnabled} property. This is
 * true if ML is enabled locally (which implies it is also enabled on remote).
 */
export const isMLEnabled = () =>
    // Implementation note: Keep it fast, the UI directly calls this many times.
    _isMLEnabled;

/**
 * Enable ML.
 *
 * Persist the user's preference both locally and on remote, and trigger a sync.
 */
export const enableML = () => {
    // TODO-ML: API call.
    setIsMLEnabledLocally(true);
    _isMLEnabled = true;
    triggerMLSync();
};

/**
 * Disable ML.
 *
 * Stop any in-progress ML tasks, and persist the user's preference both locally
 * and on remote.
 */
export const disableML = () => {
    // TODO-ML: API call.
    terminateMLWorker();
    setIsMLEnabledLocally(false);
    _isMLEnabled = false;
};

/**
 * Pause ML on this device.
 *
 * Stop any in-progress ML tasks, and persist the user's local preference.
 */
export const pauseML = () => {
    terminateMLWorker();
    setIsMLEnabledLocally(false);
    _isMLEnabled = false;
};

/**
 * Resume ML on this device.
 *
 * Persist the user's preference locally, and trigger a sync.
 */
export const resumeML = () => {
    setIsMLEnabledLocally(true);
    _isMLEnabled = true;
    triggerMLSync();
};

/**
 * Return true if ML is enabled locally.
 *
 * This setting is persisted locally (in local storage). It is not synced with
 * remote and only tracks if ML is enabled locally.
 *
 * The remote status is tracked with a separate {@link isMLEnabledRemote} flag
 * that is synced with remote.
 */
const isMLEnabledLocally = () =>
    localStorage.getItem("faceIndexingEnabled") == "1";

/**
 * Update the (locally stored) value of {@link isMLEnabledLocally}.
 */
const setIsMLEnabledLocally = (enabled: boolean) =>
    enabled
        ? localStorage.setItem("faceIndexingEnabled", "1")
        : localStorage.removeItem("faceIndexingEnabled");

/**
 * For historical reasons, this is called "faceSearchEnabled" (it started off as
 * a flag to ensure we have taken the face recognition consent from the user).
 *
 * Now it tracks the status of ML in general (which includes faces + consent).
 */
const mlRemoteKey = "faceSearchEnabled";
const getIsMLEnabledRemote = () => getRemoteFlag(mlRemoteKey);
const updateIsMLEnabledRemote = (enabled: boolean) =>
    updateRemoteFlag(mlRemoteKey, enabled);

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
 * @param uploadItem The item that was uploaded. This can be used to get at the
 * contents of the file that got uploaded. In case of live photos, this is the
 * image part of the live photo that was uploaded.
 */
export const indexNewUpload = (enteFile: EnteFile, uploadItem: UploadItem) => {
    if (!_isMLEnabled) return;
    if (enteFile.metadata.fileType !== FILE_TYPE.IMAGE) return;
    log.debug(() => ["ml/liveq", { enteFile, uploadItem }]);
    void worker().then((w) => w.onUpload(enteFile, uploadItem));
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
