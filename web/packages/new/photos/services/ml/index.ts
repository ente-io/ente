/**
 * @file Main thread interface to the ML subsystem.
 */

import { isDesktop } from "@/base/app";
import { blobCache } from "@/base/blob-cache";
import { ensureElectron } from "@/base/electron";
import log from "@/base/log";
import type { Electron } from "@/base/types/ipc";
import { ComlinkWorker } from "@/base/worker/comlink-worker";
import { FileType } from "@/media/file-type";
import type { EnteFile } from "@/new/photos/types/file";
import { ensure } from "@/utils/ensure";
import { throttled } from "@/utils/promise";
import { proxy } from "comlink";
import { isInternalUser } from "../feature-flags";
import { getRemoteFlag, updateRemoteFlag } from "../remote-store";
import type { UploadItem } from "../upload/types";
import { regenerateFaceCrops } from "./crop";
import { clearMLDB, faceIndex, indexableAndIndexedCounts } from "./db";
import { MLWorker } from "./worker";

/**
 * In-memory flag that tracks if ML is enabled.
 *
 * -   On app start, this is read from local storage during {@link initML}.
 *
 * -   It gets updated when we sync with remote (so if the user enables/disables
 *     ML on a different device, this local value will also become true/false).
 *
 * -   It gets updated when the user enables/disables ML on this device.
 *
 * -   It is cleared in {@link logoutML}.
 */
let _isMLEnabled = false;

/** Cached instance of the {@link ComlinkWorker} that wraps our web worker. */
let _comlinkWorker: ComlinkWorker<typeof MLWorker> | undefined;

/**
 * Subscriptions to {@link MLStatus}.
 *
 * See {@link mlStatusSubscribe}.
 */
let _mlStatusListeners: (() => void)[] = [];

/**
 * Snapshot of {@link MLStatus}.
 *
 * See {@link mlStatusSnapshot}.
 */
let _mlStatusSnapshot: MLStatus | undefined;

/** Lazily created, cached, instance of {@link MLWorker}. */
const worker = async () => {
    if (!_comlinkWorker) _comlinkWorker = await createComlinkWorker();
    return _comlinkWorker.remote;
};

const createComlinkWorker = async () => {
    const electron = ensureElectron();
    const mlWorkerElectron = {
        detectFaces: electron.detectFaces,
        computeFaceEmbeddings: electron.computeFaceEmbeddings,
        computeCLIPImageEmbedding: electron.computeCLIPImageEmbedding,
    };
    const delegate = {
        workerDidProcessFile,
    };

    // Obtain a message port from the Electron layer.
    const messagePort = await createMLWorker(electron);

    const cw = new ComlinkWorker<typeof MLWorker>(
        "ML",
        new Worker(new URL("worker.ts", import.meta.url)),
    );

    await cw.remote.then((w) => {
        // Pass the message port to our web worker.
        cw.worker.postMessage("createMLWorker/port", [messagePort]);
        // Initialize it.
        return w.init(proxy(mlWorkerElectron), proxy(delegate));
    });

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
 * Obtain a port from the Node.js layer that can be used to communicate with the
 * ML worker process.
 */
const createMLWorker = async (electron: Electron): Promise<MessagePort> => {
    electron.createMLWorker();

    // The main process will do its thing, and send back the port it created to
    // us by sending an message on the "createMLWorker/port" channel via the
    // postMessage API. This roundabout way is needed because MessagePorts
    // cannot be transferred via the usual send/invoke pattern.

    return new Promise((resolve) => {
        window.onmessage = ({ source, data, ports }: MessageEvent) => {
            // The source check verifies that the message is coming from the
            // preload script. The data is the message that was posted.
            if (source == window && data == "createMLWorker/port")
                resolve(ensure(ports[0]));
        };
    });
};

/**
 * Return true if the current client supports ML.
 *
 * ML currently only works when we're running in our desktop app.
 */
export const isMLSupported = isDesktop;

/**
 * TODO-ML: This will not be needed when we move to a public beta.
 * Was this someone who might've enabled the beta ML? If so, show them the
 * coming back soon banner while we finalize it.
 */
export const canEnableML = async () =>
    // TODO-ML: The interim condition should be
    // isDevBuild || (await isInternalUser()) || (await isBetaUser());
    await isInternalUser();

/**
 * Initialize the ML subsystem if the user has enabled it in preferences.
 */
export const initML = () => {
    _isMLEnabled = isMLEnabledLocal();
};

export const logoutML = async () => {
    // `terminateMLWorker` is conceptually also part of this sequence, but for
    // the reasons mentioned in [Note: Caching IDB instances in separate
    // execution contexts], it gets called first in the logout sequence, and
    // then this function (`logoutML`) gets called at a later point in time.

    _isMLEnabled = false;
    _mlStatusListeners = [];
    _mlStatusSnapshot = undefined;
    await clearMLDB();
};

/**
 * Return true if the user has enabled machine learning in their preferences.
 *
 * Enabling ML enables in both locally by persisting a local storage flag, and
 * sets a flag on remote so that the user's other devices can also enable it
 * when they next sync with remote.
 */
export const isMLEnabled = () =>
    // Implementation note: Keep it fast, it might be called frequently.
    _isMLEnabled;

/**
 * Enable ML.
 *
 * Persist the user's preference both locally and on remote, and trigger a sync.
 */
export const enableML = async () => {
    await updateIsMLEnabledRemote(true);
    setIsMLEnabledLocal(true);
    _isMLEnabled = true;
    setInterimScheduledStatus();
    triggerStatusUpdate();
    triggerMLSync();
};

/**
 * Disable ML.
 *
 * Stop any in-progress ML tasks, and persist the user's preference both locally
 * and on remote.
 */
export const disableML = async () => {
    await updateIsMLEnabledRemote(false);
    setIsMLEnabledLocal(false);
    _isMLEnabled = false;
    terminateMLWorker();
    triggerStatusUpdate();
};

/**
 * Return true if our local persistence thinks that ML is enabled.
 *
 * This setting is persisted locally (in local storage). It is not synced with
 * remote and only tracks if ML is enabled locally.
 *
 * The remote status is tracked with a separate {@link isMLEnabledRemote} flag
 * that is synced with remote.
 */
const isMLEnabledLocal = () =>
    // TODO-ML: Rename this flag
    localStorage.getItem("faceIndexingEnabled") == "1";

/**
 * Update the (locally stored) value of {@link isMLEnabledLocal}.
 */
const setIsMLEnabledLocal = (enabled: boolean) =>
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

/**
 * Return `true` if the flag to enable ML is set on remote.
 */
const getIsMLEnabledRemote = () => getRemoteFlag(mlRemoteKey);

/**
 * Update the remote flag that tracks the user's ML preference.
 */
const updateIsMLEnabledRemote = (enabled: boolean) =>
    updateRemoteFlag(mlRemoteKey, enabled);

/**
 * Trigger a "sync", whatever that means for the ML subsystem.
 *
 * This is called during the global sync sequence.
 *
 * * It checks with remote if the ML flag is set, and updates our local flag to
 *   reflect that value.
 *
 * * If ML is enabled, it pulls any missing embeddings from remote and starts
 *   indexing to backfill any missing values.
 */
export const triggerMLSync = () => void mlSync();

const mlSync = async () => {
    _isMLEnabled = await getIsMLEnabledRemote();
    setIsMLEnabledLocal(_isMLEnabled);
    triggerStatusUpdate();

    if (_isMLEnabled) void worker().then((w) => w.sync());
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
    if (enteFile.metadata.fileType !== FileType.image) return;
    log.debug(() => ["ml/liveq", { enteFile, uploadItem }]);
    void worker().then((w) => w.onUpload(enteFile, uploadItem));
};

export type MLStatus =
    | { phase: "disabled" /* The ML remote flag is off */ }
    | {
          /**
           * Which phase we are in within the indexing pipeline when viewed across the
           * user's entire library:
           *
           * - "scheduled": A ML job is scheduled. Likely there are files we
           *   know of that have not been indexed, but is also the state before
           *   the first run of the indexer after app start.
           *
           * - "indexing": The indexer is currently running.
           *
           * - "clustering": All file we know of have been indexed, and we are now
           *   clustering the faces that were found.
           *
           * - "done": ML indexing and face clustering is complete for the user's
           *   library.
           */
          phase: "scheduled" | "indexing" | "clustering" | "done";
          /** The number of files that have already been indexed. */
          nSyncedFiles: number;
          /** The total number of files that are eligible for indexing. */
          nTotalFiles: number;
      };

/**
 * A function that can be used to subscribe to updates in the ML status.
 *
 * This, along with {@link mlStatusSnapshot}, is meant to be used as arguments
 * to React's {@link useSyncExternalStore}.
 *
 * @param callback A function that will be invoked whenever the result of
 * {@link mlStatusSnapshot} changes.
 *
 * @returns A function that can be used to clear the subscription.
 */
export const mlStatusSubscribe = (onChange: () => void): (() => void) => {
    _mlStatusListeners.push(onChange);
    return () => {
        _mlStatusListeners = _mlStatusListeners.filter((l) => l != onChange);
    };
};

/**
 * Return the last known, cached {@link MLStatus}.
 *
 * This, along with {@link mlStatusSnapshot}, is meant to be used as arguments
 * to React's {@link useSyncExternalStore}.
 *
 * A return value of `undefined` indicates that we're still performing the
 * asynchronous tasks that are needed to get the status.
 */
export const mlStatusSnapshot = (): MLStatus | undefined => {
    const result = _mlStatusSnapshot;
    // We don't have it yet, trigger an update.
    if (!result) triggerStatusUpdate();
    return result;
};

/**
 * Trigger an asynchronous and unconditional update of the {@link MLStatus}
 * snapshot.
 */
const triggerStatusUpdate = () => void updateMLStatusSnapshot();

/** Unconditionally update of the {@link MLStatus} snapshot. */
const updateMLStatusSnapshot = async () =>
    setMLStatusSnapshot(await getMLStatus());

const setMLStatusSnapshot = (snapshot: MLStatus) => {
    _mlStatusSnapshot = snapshot;
    _mlStatusListeners.forEach((l) => l());
};

/**
 * Compute the current state of the ML subsystem.
 */
const getMLStatus = async (): Promise<MLStatus> => {
    if (!_isMLEnabled) return { phase: "disabled" };

    const { indexedCount, indexableCount } = await indexableAndIndexedCounts();

    let phase: MLStatus["phase"];
    if (indexableCount > 0) {
        const isIndexing = await (await worker()).isIndexing();
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
 * When the user enables or resumes ML, we wish to give immediate feedback.
 *
 * So this is an intermediate state with possibly incorrect counts (but correct
 * phase) that is set immediately to trigger a UI update. It uses the counts
 * from the last known status, and just updates the phase.
 *
 * Once the worker is initialized and the correct counts fetched, this will
 * update to the correct state (should take less than a second).
 */
const setInterimScheduledStatus = () => {
    let nSyncedFiles = 0,
        nTotalFiles = 0;
    if (_mlStatusSnapshot && _mlStatusSnapshot.phase != "disabled") {
        ({ nSyncedFiles, nTotalFiles } = _mlStatusSnapshot);
    }
    setMLStatusSnapshot({ phase: "scheduled", nSyncedFiles, nTotalFiles });
};

const workerDidProcessFile = throttled(updateMLStatusSnapshot, 2000);

/**
 * Return the IDs of all the faces in the given {@link enteFile} that are not
 * associated with a person cluster.
 */
export const unidentifiedFaceIDs = async (
    enteFile: EnteFile,
): Promise<string[]> => {
    const index = await faceIndex(enteFile.id);
    return index?.faces.map((f) => f.faceID) ?? [];
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

    const faceIDs = index.faces.map((f) => f.faceID);
    const cache = await blobCache("face-crops");
    for (const id of faceIDs) {
        if (!(await cache.has(id))) {
            await regenerateFaceCrops(enteFile, index);
            return true;
        }
    }

    return false;
};
