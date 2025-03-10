/**
 * @file Main thread interface to the ML subsystem.
 */

import { isDesktop } from "@/base/app";
import { blobCache } from "@/base/blob-cache";
import { ensureElectron } from "@/base/electron";
import log from "@/base/log";
import { masterKeyFromSession } from "@/base/session";
import type { Electron } from "@/base/types/ipc";
import { ComlinkWorker } from "@/base/worker/comlink-worker";
import type { UploadItem } from "@/gallery/services/upload";
import type { EnteFile } from "@/media/file";
import { FileType } from "@/media/file-type";
import { throttled } from "@/utils/promise";
import { proxy, transfer } from "comlink";
import { getRemoteFlag, updateRemoteFlag } from "../remote-store";
import { setSearchPeople } from "../search";
import {
    addUserEntity,
    pullUserEntities,
    updateOrCreateUserEntities,
    type CGroup,
} from "../user-entity";
import { deleteUserEntity } from "../user-entity/remote";
import type { FaceCluster } from "./cluster";
import { regenerateFaceCrops } from "./crop";
import {
    clearMLDB,
    getIndexableAndIndexedCounts,
    resetFailedFileStatuses,
    savedFaceIndex,
} from "./db";
import {
    _applyPersonSuggestionUpdates,
    filterNamedPeople,
    reconstructPeopleState,
    type CGroupPerson,
    type PeopleState,
    type PersonSuggestionUpdates,
} from "./people";
import { MLWorker } from "./worker";
import type { CLIPMatches } from "./worker-types";

/**
 * Internal state of the ML subsystem.
 *
 * These are essentially cached values used by the functions of this module.
 *
 * They will be cleared on logout.
 */
class MLState {
    /**
     * In-memory flag that tracks if ML is enabled.
     *
     * - On app start, this is read from local storage during {@link initML}.
     *
     * - It gets updated when we sync with remote (so if the user
     *   enables/disables ML on a different device, this local value will also
     *   become true/false).
     *
     * - It gets updated when the user enables/disables ML on this device.
     *
     * - It is cleared in {@link logoutML}.
     */
    isMLEnabled = false;

    /**
     * Cached instance of the {@link ComlinkWorker} that wraps our web worker.
     */
    comlinkWorker: Promise<ComlinkWorker<typeof MLWorker>> | undefined;

    /**
     * `true` if a sync is currently in progress.
     */
    isSyncing = false;

    /**
     * Subscriptions to {@link MLStatus} updates attached using
     * {@link mlStatusSubscribe}.
     */
    mlStatusListeners: (() => void)[] = [];

    /**
     * Snapshot of the {@link MLStatus} returned by the {@link mlStatusSnapshot}
     * function.
     */
    mlStatusSnapshot: MLStatus | undefined;

    /**
     * Subscriptions to updates to the {@link PeopleState} attached using
     * {@link peopleStateSubscribe}.
     */
    peopleStateListeners: (() => void)[] = [];

    /**
     * Snapshot of the {@link PeopleState} return by the
     * {@link peopleStateSnapshot} function.
     *
     * It will be `undefined` only if ML is disabled. Otherwise, it will be an
     * empty array even if the snapshot is pending its first sync.
     */
    peopleStateSnapshot: PeopleState | undefined;

    /**
     * `true` if a reset has been requested via
     * {@link retryIndexingFailuresIfNeeded}.
     */
    needsResetFailures = false;

    /**
     * In flight face crop regeneration promises indexed by the IDs of the files
     * whose faces we are regenerating.
     */
    inFlightFaceCropRegens = new Map<number, Promise<void>>();

    /**
     * Cached object URLs to face crops that we have previously vended out.
     *
     * The cache is only cleared on logout.
     */
    faceCropObjectURLCache = new Map<string, string>();
}

/** State shared by the functions in this module. See {@link MLState}. */
let _state = new MLState();

/** Lazily created, cached, instance of {@link MLWorker}. */
const worker = () =>
    (_state.comlinkWorker ??= createComlinkWorker()).then((cw) => cw.remote);

const createComlinkWorker = async () => {
    const electron = ensureElectron();
    const delegate = { workerDidUpdateStatus, workerDidUnawaitedIndex };

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
                resolve(ports[0]!);
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
    resetPeopleStateSnapshot();
};

export const logoutML = async () => {
    // `terminateMLWorker` is conceptually also part of this sequence, but for
    // the reasons mentioned in [Note: Caching IDB instances in separate
    // execution contexts], it gets called first in the logout sequence, and
    // then this function (`logoutML`) gets called at a later point in time.

    [..._state.faceCropObjectURLCache.values()].forEach((url) =>
        URL.revokeObjectURL(url),
    );
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
    resetPeopleStateSnapshot();
    // Trigger updates, but don't wait for them to finish.
    void updateMLStatusSnapshot().then(mlSync);
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
    _state.isSyncing = false;
    await terminateMLWorker();
    triggerStatusUpdate();
    resetPeopleStateSnapshot();
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
const isMLEnabledLocal = () => localStorage.getItem(mlLocalKey) == "1";

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
 * Reset failures so that indexing is attempted again.
 *
 * When indexing of some individual files fails for non-retriable reasons, we
 * mark those as failures locally.
 *
 * See: [Note: Transient and permanent indexing failures].
 *
 * Sometimes we might wish to reattempt these though (e.g. when adding support
 * for more file formats).
 *
 * In such cases, this function can be called early on (during an app version
 * upgrade) to set an in-memory flag which tell us that before attemepting a
 * sync, we should reset existing failed statii.
 *
 * Since this is not a critical operation, we only keep this as an in-memory
 * flag, failure to honor this will not have permanent repercussions (e.g. the
 * file would eventually get indexed on mobile, or during logout / login, or
 * during the next time an reattempt is made).
 */
export const retryIndexingFailuresIfNeeded = () => {
    _state.needsResetFailures = true;
};

/**
 * Sync the ML status with remote.
 *
 * This is called an at early point in the global sync sequence, without waiting
 * for the potentially long file information sync to complete.
 *
 * It checks with remote if the ML flag is set, and updates our local flag to
 * reflect that value.
 *
 * To perform the actual ML sync, use {@link mlSync}.
 */
export const mlStatusSync = async () => {
    _state.isMLEnabled = await getIsMLEnabledRemote();
    setIsMLEnabledLocal(_state.isMLEnabled);
    return updateMLStatusSnapshot();
};

/**
 * Perform a ML sync, whatever is applicable.
 *
 * This is called during the global sync sequence, after files information have
 * been synced with remote.
 *
 * If ML is enabled, it pulls any missing embeddings from remote and starts
 * indexing to backfill any missing values. It also syncs cgroups and updates
 * the search service to use the latest values. Finally, it uses the latest
 * files, faces and cgroups to update the people shown in the UI.
 *
 * This will only have an effect if {@link mlStatusSync} has been called at
 * least once prior to calling this in the sync sequence.
 */
export const mlSync = async () => {
    if (!_state.isMLEnabled) return;
    if (_state.isSyncing) return;
    _state.isSyncing = true;

    if (_state.needsResetFailures) {
        // CAS. See documentation for retryIndexingFailures why swapping the
        // flag before performing the operation is fine.
        _state.needsResetFailures = false;
        await resetFailedFileStatuses();
    }

    // Dependency order for the sync
    //
    //     files -> faces -> cgroups -> clusters -> people
    //

    // Fetch indexes, or index locally if needed.
    await worker().then((w) => w.index());

    await updateClustersAndPeople();

    _state.isSyncing = false;
};

const workerDidUnawaitedIndex = () => void updateClustersAndPeople();

const updateClustersAndPeople = async () => {
    const masterKey = await masterKeyFromSession();

    // Fetch existing cgroups from remote.
    await pullUserEntities("cgroup", masterKey);

    // Generate or update local clusters.
    await (await worker()).clusterFaces(masterKey);

    // Update the people shown in the UI.
    await updatePeopleState();
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
 * @param file The {@link EnteFile} that got uploaded.
 *
 * @param uploadItem The item that was uploaded. This can be used to get at the
 * contents of the file that got uploaded. In case of live photos, this is the
 * image part of the live photo that was uploaded.
 */
export const indexNewUpload = (file: EnteFile, uploadItem: UploadItem) => {
    if (!isMLEnabled()) return;
    if (file.metadata.fileType !== FileType.image) return;
    log.debug(() => ["ml/liveq", { file, uploadItem }]);
    void worker().then((w) => w.onUpload(file, uploadItem));
};

export type MLStatus =
    | { phase: "disabled" /* The ML remote flag is off */ }
    | {
          /**
           * Which phase we are in within the indexing pipeline when viewed
           * across the user's entire library:
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
           * - "clustering": All files we know of have been indexed, and we are
           *   now clustering the faces that were found.
           *
           * - "done": ML indexing and face clustering is complete for the
           *   user's library.
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
 * See: [Note: Snapshots and useSyncExternalStore].
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
 * See also {@link mlStatusSubscribe}.
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
 * Trigger an asynchronous update of the {@link MLStatus} snapshot, and return
 * without waiting for it to finish.
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

    const w = await worker();

    // The worker has a clustering progress set iff it is clustering. This
    // overrides other behaviours.
    const clusteringProgress = await w.clusteringProgess;
    if (clusteringProgress) {
        return {
            phase: "clustering",
            nSyncedFiles: clusteringProgress.completed,
            nTotalFiles: clusteringProgress.total,
        };
    }

    const { indexedCount, indexableCount } =
        await getIndexableAndIndexedCounts();

    // During live uploads, the indexable count remains zero even as the indexer
    // is processing the newly uploaded items. This is because these "live
    // queue" items do not yet have a "file-status" entry.
    //
    // So use the state of the worker as a guide for the phase, not the
    // indexable count.

    let phase: MLStatus["phase"];
    const state = await w.state;
    if (state == "indexing" || state == "fetching") {
        phase = state;
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

const workerDidUpdateStatus = throttled(updateMLStatusSnapshot, 2000);

/**
 * A function that can be used to subscribe to updates to {@link Person}s.
 *
 * See: [Note: Snapshots and useSyncExternalStore].
 */
export const peopleStateSubscribe = (onChange: () => void): (() => void) => {
    _state.peopleStateListeners.push(onChange);
    return () => {
        _state.peopleStateListeners = _state.peopleStateListeners.filter(
            (l) => l != onChange,
        );
    };
};

/**
 * If ML is enabled, set the people snapshot to an empty array to indicate that
 * ML is enabled, but we're still reading in the set of people.
 *
 * Otherwise, if ML is disabled, set the people snapshot to `undefined`.
 */
const resetPeopleStateSnapshot = () =>
    setPeopleStateSnapshot(
        _state.isMLEnabled
            ? { people: [], visiblePeople: [], personByFaceID: new Map() }
            : undefined,
    );

/**
 * Return the last known, cached {@link PeopleState}.
 *
 * See also {@link peopleStateSubscribe}.
 *
 * A return value of `undefined` indicates that ML is disabled. In all other
 * cases, the list of people will be either empty (if we're either still loading
 * the initial list of people, or if the user doesn't have any people), or,
 * well, non-empty.
 */
export const peopleStateSnapshot = () => _state.peopleStateSnapshot;

// Update our, and the search subsystem's, snapshot of people state by
// reconstructing it from the latest local state.
const updatePeopleState = async () => {
    const state = await reconstructPeopleState();

    // Notify the search subsystem of the update (search only uses named ones).
    setSearchPeople(filterNamedPeople(state.visiblePeople));

    // Update our in-memory state.
    setPeopleStateSnapshot(state);
};

const setPeopleStateSnapshot = (snapshot: PeopleState | undefined) => {
    _state.peopleStateSnapshot = snapshot;
    _state.peopleStateListeners.forEach((l) => l());
};

/**
 * Use CLIP to perform a natural language search over image embeddings.
 *
 * @param searchPhrase Normalized (trimmed and lowercased) search phrase.
 *
 * It returns file (IDs) that should be shown in the search results, each
 * annotated with its score.
 *
 * The result can also be `undefined`, which indicates that the download for the
 * ML model is still in progress (trying again later should succeed).
 */
export const clipMatches = (
    searchPhrase: string,
): Promise<CLIPMatches | undefined> =>
    worker().then((w) => w.clipMatches(searchPhrase));

/**
 * A face ID annotated with the ID of the person or cluster with which it is
 * associated.
 */
export interface AnnotatedFaceID {
    faceID: string;
    personID: string;
}

/**
 * Return the list of faces found in the given {@link file}.
 */
export const getAnnotatedFacesForFile = async (
    file: EnteFile,
): Promise<AnnotatedFaceID[]> => {
    if (!isMLEnabled()) return [];

    const index = await savedFaceIndex(file.id);
    if (!index) return [];

    const personByFaceID = _state.peopleStateSnapshot?.personByFaceID;
    if (!personByFaceID) return [];

    const sortableFaces: [AnnotatedFaceID, number][] = [];
    for (const { faceID } of index.faces) {
        const person = personByFaceID.get(faceID);
        if (!person) continue;
        sortableFaces.push([
            { faceID, personID: person.id },
            person.fileIDs.length,
        ]);
    }

    sortableFaces.sort(([, a], [, b]) => b - a);
    return sortableFaces.map(([f]) => f);
};

/**
 * Return a URL to the face crop for the given face, regenerating it if needed.
 *
 * The resultant URL is cached (both the object URL itself, and the underlying
 * file crop blob used to generete it).
 *
 * @param faceID The id of the face whose face crop we want.
 *
 * @param file The {@link EnteFile} that contains this face.
 */
export const faceCrop = async (faceID: string, file: EnteFile) => {
    let inFlight = _state.inFlightFaceCropRegens.get(file.id);

    if (!inFlight) {
        inFlight = regenerateFaceCropsIfNeeded(file);
        _state.inFlightFaceCropRegens.set(file.id, inFlight);
    }

    await inFlight;

    let url = _state.faceCropObjectURLCache.get(faceID);
    if (!url) {
        const cache = await blobCache("face-crops");
        const blob = await cache.get(faceID);
        if (blob) {
            url = URL.createObjectURL(blob);
            if (url) _state.faceCropObjectURLCache.set(faceID, url);
        }
    }

    return url;
};

/**
 * Check to see if any of the faces in the given file do not have a face crop
 * present locally. If so, then regenerate the face crops for all the faces in
 * the file (updating the "face-crops" {@link BlobCache}).
 */
const regenerateFaceCropsIfNeeded = async (file: EnteFile) => {
    const index = await savedFaceIndex(file.id);
    if (!index) return;

    const cache = await blobCache("face-crops");
    const faceIDs = index.faces.map((f) => f.faceID);
    let needsRegen = false;
    for (const id of faceIDs) if (!(await cache.has(id))) needsRegen = true;

    if (needsRegen) await regenerateFaceCrops(file, index);
};

/**
 * Convert a cluster into a named person, updating both remote and local state.
 *
 * @param name Name of the new cgroup user entity.
 *
 * @param cluster The underlying cluster to use to populate the cgroup.
 *
 * @returns The entity ID of the newly created cgroup.
 */
export const addCGroup = async (name: string, cluster: FaceCluster) => {
    const masterKey = await masterKeyFromSession();
    const id = await addUserEntity(
        "cgroup",
        { name, assigned: [cluster], isHidden: false },
        masterKey,
    );
    await mlSync();
    return id;
};

/**
 * Add a new cluster to an existing named person.
 *
 * If this cluster contains any faces that had previously been marked as not
 * belonging to the person, then they will be removed from the rejected list and
 * will get reassociated to the person.
 *
 * @param cgroup The existing cgroup underlying the person. This is the (remote)
 * user entity that will get updated.
 *
 * @param cluster The new cluster of faces to associate with this person.
 */
export const addClusterToCGroup = async (
    cgroup: CGroup,
    cluster: FaceCluster,
) => {
    const clusterFaceIDs = new Set(cluster.faces);
    const assigned = cgroup.data.assigned.concat([cluster]);
    const rejectedFaceIDs = cgroup.data.rejectedFaceIDs.filter(
        (id) => !clusterFaceIDs.has(id),
    );

    const masterKey = await masterKeyFromSession();
    await updateOrCreateUserEntities(
        "cgroup",
        [{ ...cgroup, data: { ...cgroup.data, assigned, rejectedFaceIDs } }],
        masterKey,
    );
    return mlSync();
};

/**
 * Rename an existing named person.
 *
 * @param name The new name to use.
 *
 * @param cgroup The existing cgroup underlying the person. This is the (remote)
 * user entity that will get updated.
 */
export const renameCGroup = async (cgroup: CGroup, name: string) => {
    const masterKey = await masterKeyFromSession();
    await updateOrCreateUserEntities(
        "cgroup",
        [{ ...cgroup, data: { ...cgroup.data, name } }],
        masterKey,
    );
    return mlSync();
};

/**
 * Delete an existing person.
 *
 * @param cgroup The existing cgroup underlying the person.
 */
export const deleteCGroup = async ({ id }: CGroup) => {
    await deleteUserEntity(id);
    return mlSync();
};

/**
 * Return suggestions for the given {@link person}.
 *
 * The suggestion computation happens in a web worker.
 */
export const suggestionsAndChoicesForPerson = async (person: CGroupPerson) =>
    worker().then((w) => w.suggestionsAndChoicesForPerson(person));

/**
 * Implementation for the "save" action on the SuggestionsDialog.
 *
 * See {@link _applyPersonSuggestionUpdates} for more details.
 */
export const applyPersonSuggestionUpdates = async (
    cgroup: CGroup,
    updates: PersonSuggestionUpdates,
) => {
    const masterKey = await masterKeyFromSession();
    await _applyPersonSuggestionUpdates(cgroup, updates, masterKey);
    return mlSync();
};

/**
 * Ignore/hide a cluster.
 *
 * This converts the cluster into a cgroup so that it can be synced with remote,
 * setting the hidden flag so that it is not surfaced in the UI.
 *
 * @param cluster The {@link FaceCluster} to hide.
 */
export const ignoreCluster = async (cluster: FaceCluster) => {
    const masterKey = await masterKeyFromSession();
    await addUserEntity(
        "cgroup",
        { name: "", assigned: [cluster], isHidden: true },
        masterKey,
    );
    return mlSync();
};
