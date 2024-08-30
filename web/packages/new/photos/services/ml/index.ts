/**
 * @file Main thread interface to the ML subsystem.
 */

import { isDesktop } from "@/base/app";
import { assertionFailed } from "@/base/assert";
import { blobCache } from "@/base/blob-cache";
import { ensureElectron } from "@/base/electron";
import { isDevBuild } from "@/base/env";
import log from "@/base/log";
import type { Electron } from "@/base/types/ipc";
import { ComlinkWorker } from "@/base/worker/comlink-worker";
import { FileType } from "@/media/file-type";
import type { EnteFile } from "@/new/photos/types/file";
import { ensure } from "@/utils/ensure";
import { throttled } from "@/utils/promise";
import { proxy, transfer } from "comlink";
import { isInternalUser } from "../feature-flags";
import { getAllLocalFiles } from "../files";
import { getRemoteFlag, updateRemoteFlag } from "../remote-store";
import type { SearchPerson } from "../search/types";
import type { UploadItem } from "../upload/types";
import {
    type ClusteringOpts,
    type ClusterPreviewFace,
    type FaceCluster,
} from "./cluster";
import { regenerateFaceCrops } from "./crop";
import { clearMLDB, faceIndex, indexableAndIndexedCounts } from "./db";
import type { Face } from "./face";
import { MLWorker } from "./worker";
import type { CLIPMatches } from "./worker-types";

/**
 * Internal state of the ML subsystem.
 *
 * This are essentially cached values used by the functions of this module.
 *
 * This should be cleared on logout.
 */
class MLState {
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
    isMLEnabled = false;

    /**
     * Cached instance of the {@link ComlinkWorker} that wraps our web worker.
     */
    comlinkWorker: Promise<ComlinkWorker<typeof MLWorker>> | undefined;

    /**
     * Subscriptions to {@link MLStatus}.
     *
     * See {@link mlStatusSubscribe}.
     */
    mlStatusListeners: (() => void)[] = [];

    /**
     * Snapshot of {@link MLStatus}.
     *
     * See {@link mlStatusSnapshot}.
     */
    mlStatusSnapshot: MLStatus | undefined;

    /**
     * In flight face crop regeneration promises indexed by the IDs of the files
     * whose faces we are regenerating.
     */
    inFlightFaceCropRegens = new Map<number, Promise<void>>();
}

/** State shared by the functions in this module. See {@link MLState}. */
let _state = new MLState();

/** Lazily created, cached, instance of {@link MLWorker}. */
const worker = () =>
    (_state.comlinkWorker ??= createComlinkWorker()).then((cw) => cw.remote);

const createComlinkWorker = async () => {
    const electron = ensureElectron();
    const delegate = {
        workerDidProcessFileOrIdle,
    };

    // Obtain a message port from the Electron layer.
    const messagePort = await createMLWorker(electron);

    const cw = new ComlinkWorker<typeof MLWorker>(
        "ML",
        new Worker(new URL("worker.ts", import.meta.url)),
    );

    await cw.remote.then((w) =>
        // Forward the port to the web worker.
        w.init(transfer(messagePort, [messagePort]), proxy(delegate)),
    );

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
export const terminateMLWorker = async () => {
    if (_state.comlinkWorker) {
        await _state.comlinkWorker.then((cw) => cw.terminate());
        _state.comlinkWorker = undefined;
    }
};

/**
 * Obtain a port from the Node.js layer that can be used to communicate with the
 * ML worker process.
 */
const createMLWorker = (electron: Electron): Promise<MessagePort> => {
    // The main process will do its thing, and send back the port it created to
    // us by sending an message on the "createMLWorker/port" channel via the
    // postMessage API. This roundabout way is needed because MessagePorts
    // cannot be transferred via the usual send/invoke pattern.

    const port = new Promise<MessagePort>((resolve) => {
        const l = ({ source, data, ports }: MessageEvent) => {
            // The source check verifies that the message is coming from our own
            // preload script. The data is the message that was posted.
            if (source == window && data == "createMLWorker/port") {
                window.removeEventListener("message", l);
                resolve(ensure(ports[0]));
            }
        };
        window.addEventListener("message", l);
    });

    electron.createMLWorker();

    return port;
};

/**
 * Return true if the current client supports ML.
 *
 * ML currently only works when we're running in our desktop app.
 */
export const isMLSupported = isDesktop;

/**
 * Initialize the ML subsystem if the user has enabled it in preferences.
 */
export const initML = () => {
    _state.isMLEnabled = isMLEnabledLocal();
};

export const logoutML = async () => {
    // `terminateMLWorker` is conceptually also part of this sequence, but for
    // the reasons mentioned in [Note: Caching IDB instances in separate
    // execution contexts], it gets called first in the logout sequence, and
    // then this function (`logoutML`) gets called at a later point in time.

    _state = new MLState();
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
    _state.isMLEnabled;

/**
 * Enable ML.
 *
 * Persist the user's preference both locally and on remote, and trigger a sync.
 */
export const enableML = async () => {
    await updateIsMLEnabledRemote(true);
    setIsMLEnabledLocal(true);
    _state.isMLEnabled = true;
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
    _state.isMLEnabled = false;
    await terminateMLWorker();
    triggerStatusUpdate();
};

/**
 * Local storage key for {@link isMLEnabledLocal}.
 */
const mlLocalKey = "mlEnabled";

/**
 * Return true if our local persistence thinks that ML is enabled.
 *
 * This setting is persisted locally (in local storage). It is not synced with
 * remote and only tracks if ML is enabled locally.
 *
 * The remote status is tracked with a separate {@link isMLEnabledRemote} flag
 * that is synced with remote.
 */
const isMLEnabledLocal = () => {
    // Delete legacy ML keys.
    //
    // This code was added August 2024 (v1.7.3-beta) and can be removed at some
    // point when most clients have migrated (tag: Migration).
    localStorage.removeItem("faceIndexingEnabled");
    return localStorage.getItem(mlLocalKey) == "1";
};

/**
 * Update the (locally stored) value of {@link isMLEnabledLocal}.
 */
const setIsMLEnabledLocal = (enabled: boolean) =>
    enabled
        ? localStorage.setItem(mlLocalKey, "1")
        : localStorage.removeItem(mlLocalKey);

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
 * Sync the ML status with remote.
 *
 * This is called an at early point in the global sync sequence, without waiting
 * for the potentially long file information sync to complete.
 *
 * It checks with remote if the ML flag is set, and updates our local flag to
 * reflect that value.
 *
 * To trigger the actual ML sync, use {@link triggerMLSync}.
 */
export const triggerMLStatusSync = () => void mlStatusSync();

const mlStatusSync = async () => {
    _state.isMLEnabled = await getIsMLEnabledRemote();
    setIsMLEnabledLocal(_state.isMLEnabled);
    triggerStatusUpdate();
};

/**
 * Trigger a ML sync.
 *
 * This is called during the global sync sequence, after files information have
 * been synced with remote.
 *
 * If ML is enabled, it pulls any missing embeddings from remote and starts
 * indexing to backfill any missing values.
 *
 * This will only have an effect if {@link triggerMLSync} has been called at
 * least once prior to calling this in the sync sequence.
 */
export const triggerMLSync = () => void mlSync();

const mlSync = async () => {
    if (_state.isMLEnabled) await worker().then((w) => w.sync());
};

/**
 * Run indexing on a file which was uploaded from this client.
 *
 * Indexing only happens if ML is enabled.
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
    if (!isMLEnabled()) return;
    if (enteFile.metadata.fileType !== FileType.image) return;
    log.debug(() => ["ml/liveq", { enteFile, uploadItem }]);
    void worker().then((w) => w.onUpload(enteFile, uploadItem));
};

/**
 * WIP! Don't enable, dragon eggs are hatching here.
 */
export const wipClusterEnable = async (): Promise<boolean> =>
    (!!process.env.NEXT_PUBLIC_ENTE_WIP_CL && isDevBuild) ||
    (await isInternalUser());

// // TODO-Cluster temporary state here
let _wip_isClustering = false;
let _wip_searchPersons: SearchPerson[] | undefined;
let _wip_hasSwitchedOnce = false;

export const wipHasSwitchedOnceCmpAndSet = () => {
    if (_wip_hasSwitchedOnce) return true;
    _wip_hasSwitchedOnce = true;
    return false;
};

export const wipSearchPersons = async () => {
    if (!(await wipClusterEnable())) return [];
    return _wip_searchPersons ?? [];
};

export interface ClusterPreviewWithFile {
    clusterSize: number;
    faces: ClusterPreviewFaceWithFile[];
}

export type ClusterPreviewFaceWithFile = ClusterPreviewFace & {
    enteFile: EnteFile;
};

export interface ClusterDebugPageContents {
    clusteredFaceCount: number;
    unclusteredFaceCount: number;
    clusters: FaceCluster[];
    clusterPreviewsWithFile: ClusterPreviewWithFile[];
    unclusteredFacesWithFile: {
        face: Face;
        enteFile: EnteFile;
    }[];
    timeTakenMs: number;
}

export const wipClusterDebugPageContents = async (
    opts: ClusteringOpts,
): Promise<ClusterDebugPageContents> => {
    if (!(await wipClusterEnable())) throw new Error("Not implemented");

    log.info("clustering", opts);
    _wip_isClustering = true;
    _wip_searchPersons = undefined;
    triggerStatusUpdate();

    const {
        clusteredFaceCount,
        unclusteredFaceCount,
        clusterPreviews,
        clusters,
        cgroups,
        unclusteredFaces,
        timeTakenMs,
    } = await worker().then((w) => w.clusterFaces(opts));

    const localFiles = await getAllLocalFiles();
    const localFileByID = new Map(localFiles.map((f) => [f.id, f]));
    const fileForFace = ({ faceID }: Face) =>
        ensure(localFileByID.get(ensure(fileIDFromFaceID(faceID))));

    const clusterPreviewsWithFile = clusterPreviews.map(
        ({ clusterSize, faces }) => ({
            clusterSize,
            faces: faces.map(({ face, ...rest }) => ({
                face,
                enteFile: fileForFace(face),
                ...rest,
            })),
        }),
    );

    const unclusteredFacesWithFile = unclusteredFaces.map((face) => ({
        face,
        enteFile: fileForFace(face),
    }));

    const clusterByID = new Map(clusters.map((c) => [c.id, c]));

    const searchPersons = cgroups
        .map((cgroup) => {
            const faceID = ensure(cgroup.displayFaceID);
            const fileID = ensure(fileIDFromFaceID(faceID));
            const file = ensure(localFileByID.get(fileID));

            const faceIDs = cgroup.clusterIDs
                .map((id) => ensure(clusterByID.get(id)))
                .flatMap((cluster) => cluster.faceIDs);
            const fileIDs = faceIDs
                .map((faceID) => fileIDFromFaceID(faceID))
                .filter((fileID) => fileID !== undefined);

            return {
                id: cgroup.id,
                name: cgroup.name,
                faceIDs,
                files: [...new Set(fileIDs)],
                displayFaceID: faceID,
                displayFaceFile: file,
            };
        })
        .sort((a, b) => b.faceIDs.length - a.faceIDs.length);

    _wip_isClustering = false;
    _wip_searchPersons = searchPersons;
    triggerStatusUpdate();

    return {
        clusteredFaceCount,
        unclusteredFaceCount,
        clusters,
        clusterPreviewsWithFile,
        unclusteredFacesWithFile,
        timeTakenMs,
    };
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
           * - "fetching": The indexer is currently running, but we're primarily
           *   fetching indexes for existing files.
           *
           * - "clustering": All file we know of have been indexed, and we are now
           *   clustering the faces that were found.
           *
           * - "done": ML indexing and face clustering is complete for the user's
           *   library.
           */
          phase: "scheduled" | "indexing" | "fetching" | "clustering" | "done";
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
    _state.mlStatusListeners.push(onChange);
    return () => {
        _state.mlStatusListeners = _state.mlStatusListeners.filter(
            (l) => l != onChange,
        );
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
    const result = _state.mlStatusSnapshot;
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
    _state.mlStatusSnapshot = snapshot;
    _state.mlStatusListeners.forEach((l) => l());
};

/**
 * Compute the current state of the ML subsystem.
 */
const getMLStatus = async (): Promise<MLStatus> => {
    if (!_state.isMLEnabled) return { phase: "disabled" };

    const { indexedCount, indexableCount } = await indexableAndIndexedCounts();

    // During live uploads, the indexable count remains zero even as the indexer
    // is processing the newly uploaded items. This is because these "live
    // queue" items do not yet have a "file-status" entry.
    //
    // So use the state of the worker as a guide for the phase, not the
    // indexable count.

    let phase: MLStatus["phase"];
    const state = await (await worker()).state;
    if (state == "indexing" || state == "fetching") {
        phase = state;
    } else if (_wip_isClustering) {
        phase = "clustering";
    } else if (state == "init" || indexableCount > 0) {
        phase = "scheduled";
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
    if (
        _state.mlStatusSnapshot &&
        _state.mlStatusSnapshot.phase != "disabled"
    ) {
        ({ nSyncedFiles, nTotalFiles } = _state.mlStatusSnapshot);
    }
    setMLStatusSnapshot({ phase: "scheduled", nSyncedFiles, nTotalFiles });
};

const workerDidProcessFileOrIdle = throttled(updateMLStatusSnapshot, 2000);

/**
 * Use CLIP to perform a natural language search over image embeddings.
 *
 * @param searchPhrase The text entered by the user in the search box.
 *
 * It returns file (IDs) that should be shown in the search results, along with
 * their scores.
 *
 * The result can also be `undefined`, which indicates that the download for the
 * ML model is still in progress (trying again later should succeed).
 */
export const clipMatches = (
    searchPhrase: string,
): Promise<CLIPMatches | undefined> =>
    worker().then((w) => w.clipMatches(searchPhrase));

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
 * Extract the fileID of the {@link EnteFile} to which the face belongs from its
 * faceID.
 */
const fileIDFromFaceID = (faceID: string) => {
    const fileID = parseInt(faceID.split("_")[0] ?? "");
    if (isNaN(fileID)) {
        assertionFailed(`Ignoring attempt to parse invalid faceID ${faceID}`);
        return undefined;
    }
    return fileID;
};

/**
 * Return the cached face crop for the given face, regenerating it if needed.
 *
 * @param faceID The id of the face whose face crop we want.
 *
 * @param enteFile The {@link EnteFile} that contains this face.
 */
export const faceCrop = async (faceID: string, enteFile: EnteFile) => {
    let inFlight = _state.inFlightFaceCropRegens.get(enteFile.id);

    if (!inFlight) {
        inFlight = regenerateFaceCropsIfNeeded(enteFile);
        _state.inFlightFaceCropRegens.set(enteFile.id, inFlight);
    }

    await inFlight;

    const cache = await blobCache("face-crops");
    return cache.get(faceID);
};

/**
 * Check to see if any of the faces in the given file do not have a face crop
 * present locally. If so, then regenerate the face crops for all the faces in
 * the file (updating the "face-crops" {@link BlobCache}).
 */
const regenerateFaceCropsIfNeeded = async (enteFile: EnteFile) => {
    const index = await faceIndex(enteFile.id);
    if (!index) return;

    const cache = await blobCache("face-crops");
    const faceIDs = index.faces.map((f) => f.faceID);
    let needsRegen = false;
    for (const id of faceIDs) if (!(await cache.has(id))) needsRegen = true;

    if (needsRegen) await regenerateFaceCrops(enteFile, index);
};
