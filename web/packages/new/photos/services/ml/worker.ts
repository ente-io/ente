import { clientPackageName } from "@/base/app";
import { assertionFailed } from "@/base/assert";
import { isHTTP4xxError } from "@/base/http";
import { getKVN } from "@/base/kv";
import log from "@/base/log";
import type { ElectronMLWorker } from "@/base/types/ipc";
import { fileLogID, type EnteFile } from "@/media/file";
import { wait } from "@/utils/promise";
import { expose, wrap } from "comlink";
import { getAllLocalFiles, getLocalTrashedFiles } from "../files";
import type { UploadItem } from "../upload/types";
import {
    createImageBitmapAndData,
    fetchRenderableBlob,
    type ImageBitmapAndData,
} from "./blob";
import {
    _clipMatches,
    clearCachedCLIPIndexes,
    clipIndexingVersion,
    indexCLIP,
    type CLIPIndex,
} from "./clip";
import {
    _clusterFaces,
    reconcileClusters,
    type ClusteringProgress,
} from "./cluster";
import { saveFaceCrops } from "./crop";
import {
    getIndexableFileIDs,
    markIndexingFailed,
    savedFaceIndexes,
    saveIndexes,
    updateAssumingLocalFiles,
} from "./db";
import { faceIndexingVersion, indexFaces, type FaceIndex } from "./face";
import {
    fetchMLData,
    putMLData,
    type RawRemoteMLData,
    type RemoteMLData,
} from "./ml-data";
import { _suggestionsAndChoicesForPerson, type CGroupPerson } from "./people";
import type { CLIPMatches, MLWorkerDelegate } from "./worker-types";

/**
 * A rough hint at what the worker is up to.
 *
 * -   "init": Worker has been created but hasn't done anything yet.
 * -   "idle": Not doing anything
 * -   "tick": Transitioning to a new state
 * -   "indexing": Indexing
 * -   "fetching": A subset of indexing
 *
 * During indexing, the state is set to "fetching" whenever remote provided us
 * data for more than 50% of the files that we requested from it in the last
 * fetch during indexing.
 */
export type WorkerState = "init" | "idle" | "tick" | "indexing" | "fetching";

const idleDurationStart = 5; /* 5 seconds */
const idleDurationMax = 16 * 60; /* 16 minutes */

interface IndexableItem {
    /** The {@link EnteFile} to (potentially) index. */
    file: EnteFile;
    /** If the file was uploaded from the current client, then its contents. */
    uploadItem: UploadItem | undefined;
    /** The existing ML data on remote corresponding to this file. */
    remoteMLData: RemoteMLData | undefined;
}

/**
 * Run operations related to machine learning (e.g. indexing) in a Web Worker.
 *
 * This is a normal class that is however exposed (via comlink) as a proxy
 * running inside a Web Worker. This way, we do not bother the main thread with
 * tasks that might degrade interactivity.
 *
 * Conceptually, the MLWorker state machine is as follows:
 *
 *     ext. event      state           then state
 *    ------------- --------------- --------------
 *     sync         -> "backfillq"  -> "idle"
 *     upload       -> "liveq"      -> "idle"
 *     idleTimeout  -> "backfillq"  -> "idle"
 *
 * where:
 *
 * -   "liveq": indexing items that are being uploaded,
 * -   "backfillq": index unindexed items otherwise.
 * -   "idle": in between state transitions.
 *
 * In addition, MLWorker can also be invoked for interactive tasks: in
 * particular, for finding the closest CLIP match when the user does a search.
 */
export class MLWorker {
    /** The last known state of the worker. */
    public state: WorkerState = "init";
    /** If the worker is currently clustering, then its last known progress. */
    public clusteringProgess: ClusteringProgress | undefined;

    private electron: ElectronMLWorker | undefined;
    private delegate: MLWorkerDelegate | undefined;
    private liveQ: IndexableItem[] = [];
    private idleTimeout: ReturnType<typeof setTimeout> | undefined;
    private idleDuration = idleDurationStart; /* unit: seconds */
    /** Resolvers for pending promises returned from calls to {@link index}. */
    private onNextIdles: ((count: number) => void)[] = [];
    /**
     * Number of items processed since the last time {@link onNextIdles} was
     * drained.
     */
    private countSinceLastIdle = 0;

    /**
     * Initialize a new {@link MLWorker}.
     *
     * This is conceptually the constructor, however it is easier to have this
     * as a separate function to avoid complicating the comlink types further.
     *
     * @param port A {@link MessagePort} that allows us to communicate with an
     * Electron utility process running in the Node.js layer of our desktop app,
     * exposing an object that conforms to the {@link ElectronMLWorker}
     * interface.
     *
     * @param delegate The {@link MLWorkerDelegate} the worker can use to inform
     * the main thread of interesting events.
     */
    init(port: MessagePort, delegate: MLWorkerDelegate) {
        this.electron = wrap<ElectronMLWorker>(port);
        this.delegate = delegate;
    }

    /**
     * Start backfilling if needed, and return after there are no more items
     * remaining to backfill.
     *
     * During a backfill, we first attempt to fetch ML data for files which
     * don't have that data locally. If on fetching we find what we need, we
     * save it locally. Otherwise we index them.
     *
     * @return The count of items processed since the last last time we were
     * idle.
     */
    index() {
        const nextIdle = new Promise<number>((resolve) =>
            this.onNextIdles.push(resolve),
        );
        this.wakeUp();
        return nextIdle;
    }

    /** Invoked in response to external events. */
    private wakeUp() {
        if (this.state == "init" || this.state == "idle") {
            // We are currently paused. Get back to work.
            if (this.idleTimeout) clearTimeout(this.idleTimeout);
            this.idleTimeout = undefined;
            // Change state so that multiple calls to `wakeUp` don't cause
            // multiple calls to `tick`.
            this.state = "tick";
            // Enqueue a tick.
            void this.tick();
        } else {
            // In the middle of a task. Do nothing, `this.tick` will
            // automatically be invoked when the current task finishes.
        }
    }

    /**
     * Called when a file is uploaded from the current client.
     *
     * This is a great opportunity to index since we already have the in-memory
     * representation of the file's contents with us and won't need to download
     * the file from remote.
     */
    onUpload(file: EnteFile, uploadItem: UploadItem) {
        // Add the recently uploaded file to the live indexing queue.
        //
        // Limit the queue to some maximum so that we don't keep growing
        // indefinitely (and cause memory pressure) if the speed of uploads is
        // exceeding the speed of indexing.
        //
        // In general, we can be sloppy with the items in the live queue (as
        // long as we're not systematically ignoring it). This is because the
        // live queue is just an optimization: if a file doesn't get indexed via
        // the live queue, it'll later get indexed anyway when we backfill.
        if (this.liveQ.length < 200) {
            // The file is just being uploaded, and so will not have any
            // pre-existing ML data on remote.
            this.liveQ.push({ file, uploadItem, remoteMLData: undefined });
            this.wakeUp();
        } else {
            log.debug(() => "Ignoring upload item since liveQ is full");
        }
    }

    /**
     * Find {@link CLIPMatches} for a given normalized {@link searchPhrase}.
     */
    async clipMatches(searchPhrase: string): Promise<CLIPMatches | undefined> {
        return _clipMatches(searchPhrase, this.electron!);
    }

    private async tick() {
        log.debug(() => [
            "ml/tick",
            {
                state: this.state,
                liveQ: this.liveQ,
                idleDuration: this.idleDuration,
            },
        ]);

        const scheduleTick = () => void setTimeout(() => this.tick(), 0);

        const liveQ = this.liveQ;
        this.liveQ = [];

        // Retain the previous state if it was one of the indexing states. This
        // prevents jumping between "fetching" and "indexing" being shown in the
        // UI during the initial load.
        if (this.state != "fetching" && this.state != "indexing")
            this.state = "indexing";

        // Use the liveQ if present, otherwise get the next batch to backfill.
        const items = liveQ.length ? liveQ : await this.backfillQ();

        this.countSinceLastIdle += items.length;

        // If there is items remaining,
        if (items.length > 0) {
            // Index them.
            const allSuccess = await indexNextBatch(
                items,
                this.electron!,
                this.delegate,
            );
            if (allSuccess) {
                // Everything is running smoothly. Reset the idle duration.
                this.idleDuration = idleDurationStart;
                // And tick again.
                scheduleTick();
                return;
            }
        }

        // We come here in three scenarios - either there is nothing left to do,
        // or we cannot currently do it (e.g. user is offline), or we
        // encountered failures during indexing.
        //
        // Failures are not really expected, so something unexpected might be
        // going on, or remote might be having issues.
        //
        // So in all cases, we pause for exponentially longer durations of time
        // (limited to some maximum).

        this.state = "idle";
        this.idleDuration = Math.min(this.idleDuration * 2, idleDurationMax);
        this.idleTimeout = setTimeout(scheduleTick, this.idleDuration * 1000);
        this.delegate?.workerDidUpdateStatus();

        // Resolve any awaiting promises returned from `index`.
        const onNextIdles = this.onNextIdles;
        const countSinceLastIdle = this.countSinceLastIdle;
        this.onNextIdles = [];
        this.countSinceLastIdle = 0;
        onNextIdles.forEach((f) => f(countSinceLastIdle));

        // If no one was waiting, then let the main thread know via a different
        // channel so that it can update the clusters and people.
        if (onNextIdles.length == 0 && countSinceLastIdle > 0) {
            this.delegate?.workerDidUnawaitedIndex();
        }
    }

    /** Return the next batch of items to backfill (if any). */
    private async backfillQ() {
        const userID = (await getKVN("userID"))!;
        // Find files that our local DB thinks need syncing.
        const fileByID = await syncWithLocalFilesAndGetFilesToIndex(
            userID,
            200,
        );
        if (!fileByID.size) return [];

        // Fetch their existing ML data (if any).
        const mlDataByID = await fetchMLData(fileByID);

        // If the number of files for which remote gave us data is more than 50%
        // of what we asked of it, assume we are "fetching", not "indexing".
        // This is a heuristic to try and show a better indexing state in the UI
        // (so that the user does not think that their files are being
        // unnecessarily reindexed).
        if (this.state != "indexing" && this.state != "fetching")
            assertionFailed(`Unexpected state ${this.state}`);
        this.state =
            mlDataByID.size * 2 > fileByID.size ? "fetching" : "indexing";

        // Return files after annotating them with their existing ML data.
        return Array.from(fileByID, ([id, file]) => ({
            file,
            uploadItem: undefined,
            remoteMLData: mlDataByID.get(id),
        }));
    }

    /**
     * Run face clustering on all faces, and update both local and remote state
     * as appropriate.
     *
     * This should only be invoked when the face indexing (including syncing
     * with remote) is complete so that we cluster the latest set of faces, and
     * after we have fetched the latest cgroups from remote (so that we do no
     * overwrite any remote updates).
     *
     * @param masterKey The user's master key, required for updating remote
     * cgroups if needed.
     */
    async clusterFaces(masterKey: Uint8Array) {
        const { clusters, modifiedClusterIDs } = await _clusterFaces(
            await savedFaceIndexes(),
            await getAllLocalFiles(),
            (progress) => this.updateClusteringProgress(progress),
        );
        await reconcileClusters(clusters, modifiedClusterIDs, masterKey);
        this.updateClusteringProgress(undefined);
    }

    private updateClusteringProgress(progress: ClusteringProgress | undefined) {
        this.clusteringProgess = progress;
        this.delegate?.workerDidUpdateStatus();
    }

    /**
     * Return suggestions and choices for the given cgroup {@link person}.
     */
    async suggestionsAndChoicesForPerson(person: CGroupPerson) {
        return _suggestionsAndChoicesForPerson(person);
    }
}

expose(MLWorker);

/**
 * Index the given batch of items.
 *
 * Returns `false` to indicate that either an error occurred, or that we cannot
 * currently process files since we don't have network connectivity.
 *
 * Which means that when it returns true, all is well and if there are more
 * things pending to process, we should chug along at full speed.
 */
const indexNextBatch = async (
    items: IndexableItem[],
    electron: ElectronMLWorker,
    delegate: MLWorkerDelegate | undefined,
) => {
    // Don't try to index if we wouldn't be able to upload them anyway. The
    // liveQ has already been drained, but that's fine, it'll be rare that we
    // were able to upload just a bit ago but don't have network now.
    if (!self.navigator.onLine) {
        log.info("Skipping ML indexing since we are not online");
        return false;
    }

    // Keep track if any of the items failed.
    let allSuccess = true;

    // Index up to 4 items simultaneously.
    const tasks = new Array<Promise<void> | undefined>(4).fill(undefined);

    let i = 0;
    while (i < items.length) {
        for (let j = 0; j < tasks.length; j++) {
            if (i < items.length && !tasks[j]) {
                // Use an IIFE to capture the value of j at the time of
                // invocation.
                tasks[j] = ((item: IndexableItem, j: number) =>
                    index(item, electron)
                        .then(() => {
                            tasks[j] = undefined;
                        })
                        .catch(() => {
                            allSuccess = false;
                            tasks[j] = undefined;
                        }))(items[i++]!, j);
            }
        }

        // Wait for at least one to complete (the other runners continue running
        // even if one promise reaches the finish line).
        await Promise.race(tasks);

        // Let the main thread now we're doing something.
        delegate?.workerDidUpdateStatus();

        // Let us drain the microtask queue. This also gives a chance for other
        // interactive tasks like `clipMatches` to run.
        await wait(0);
    }

    // Wait for the pending tasks to drain out.
    await Promise.all(tasks);

    // Clear any cached CLIP indexes, since now we might have new ones.
    clearCachedCLIPIndexes();

    // Return true if nothing failed.
    return allSuccess;
};

/**
 * Sync face DB with the local (and potentially indexable) files that we know
 * about. Then return the next {@link count} files that still need to be
 * indexed.
 *
 * When returning from amongst pending files, prefer the most recent ones first.
 *
 * For specifics of what a "sync" entails, see {@link updateAssumingLocalFiles}.
 *
 * @param userID Sync only files owned by a {@link userID} with the face DB.
 *
 * @param count Limit the resulting list of indexable files to {@link count}.
 */
const syncWithLocalFilesAndGetFilesToIndex = async (
    userID: number,
    count: number,
): Promise<Map<number, EnteFile>> => {
    const isIndexable = (f: EnteFile) => f.ownerID == userID;

    const localFiles = await getAllLocalFiles();
    const localFileByID = new Map(
        localFiles.filter(isIndexable).map((f) => [f.id, f]),
    );

    const localTrashFileIDs = (await getLocalTrashedFiles()).map((f) => f.id);

    await updateAssumingLocalFiles(
        Array.from(localFileByID.keys()),
        localTrashFileIDs,
    );

    const fileIDsToIndex = await getIndexableFileIDs(count);
    return new Map(fileIDsToIndex.map((id) => [id, localFileByID.get(id)!]));
};

/**
 * Index file, save the persist the results locally, and put them on remote.
 *
 * Indexing a file involves computing its various ML embeddings: faces and CLIP.
 * Since we have the original file in memory, we also save the face crops.
 *
 * [Note: Transient and permanent indexing failures]
 *
 * We mark indexing for a file as having failed only if there is a good chance
 * that the indexing failed because of some inherent issue with that particular
 * file, and not if there were generic failures (like when trying to save the
 * indexes to remote).
 *
 * When we mark it as failed, then a flag is persisted corresponding to this
 * file in the ML DB so that it won't get reindexed in future runs. This are
 * thus considered as permanent failures.
 *
 * > We might retry these in future versions if we identify reasons for indexing
 * > to fail (it ideally shouldn't) and rectify them.
 *
 * On the other hand, saving the face index to remote might fail for transient
 * issues (network issues, or remote having hiccups). We don't mark a file as
 * failed permanently in such cases, so that it gets retried at some point.
 * These are considered as transient failures.
 *
 * However, it is vary hard to pre-emptively enumerate all possible failure
 * modes, and there is a the possibility of some non-transient failure getting
 * classified as a transient failure and causing the client to try and index the
 * same file again and again, when in fact there is a issue specific to that
 * file which is preventing the index from being saved. What exactly? We don't
 * know, but the possibility exists.
 *
 * To reduce the chances of this happening, we treat HTTP 4xx responses as
 * permanent failures too - there are no known cases where a client retrying a
 * 4xx response would work, and there are expected (but rare) cases where a
 * client might get a non-retriable 4xx (e.g. if the file has over ~700 faces,
 * then remote will return a 413 Request Entity Too Large).
 */
const index = async (
    { file, uploadItem, remoteMLData }: IndexableItem,
    electron: ElectronMLWorker,
) => {
    const f = fileLogID(file);
    const fileID = file.id;

    // Massage the existing data (if any) that we got from remote to the form
    // that the rest of this function operates on.
    //
    // Discard any existing data that is made by an older indexing pipelines.
    // See: [Note: Embedding versions]

    const existingRemoteFaceIndex = remoteMLData?.parsed?.face;
    const existingRemoteCLIPIndex = remoteMLData?.parsed?.clip;

    let existingFaceIndex: FaceIndex | undefined;
    if (
        existingRemoteFaceIndex &&
        existingRemoteFaceIndex.version >= faceIndexingVersion
    ) {
        // Destructure the data we got from remote so that we only retain the
        // fields we're interested in the object that gets put into indexed db.
        const { width, height, faces } = existingRemoteFaceIndex;
        existingFaceIndex = { width, height, faces };
    }

    let existingCLIPIndex: CLIPIndex | undefined;
    if (
        existingRemoteCLIPIndex &&
        existingRemoteCLIPIndex.version >= clipIndexingVersion
    ) {
        const { embedding } = existingRemoteCLIPIndex;
        existingCLIPIndex = { embedding };
    }

    // If we already have all the ML data types then just update our local db
    // and return.

    if (existingFaceIndex && existingCLIPIndex) {
        try {
            await saveIndexes(
                { fileID, ...existingFaceIndex },
                { fileID, ...existingCLIPIndex },
            );
        } catch (e) {
            log.error(`Failed to save indexes for ${f}`, e);
            throw e;
        }
        return;
    }

    // There is at least one ML data type that still needs to be indexed.

    const renderableBlob = await fetchRenderableBlob(
        file,
        uploadItem,
        electron,
    );

    let image: ImageBitmapAndData;
    try {
        image = await createImageBitmapAndData(renderableBlob);
    } catch (e) {
        // If we cannot get the raw image data for the file, then retrying again
        // won't help (if in the future we enhance the underlying code for
        // `indexableBlobs` to handle this failing type we can trigger a
        // reindexing attempt for failed files).
        //
        // See: [Note: Transient and permanent indexing failures]
        log.error(`Failed to get image data for indexing ${f}`, e);
        await markIndexingFailed(file.id);
        throw e;
    }

    try {
        let faceIndex: FaceIndex;
        let clipIndex: CLIPIndex;

        const startTime = Date.now();

        try {
            [faceIndex, clipIndex] = await Promise.all([
                existingFaceIndex ?? indexFaces(file, image, electron),
                existingCLIPIndex ?? indexCLIP(image, electron),
            ]);
        } catch (e) {
            // See: [Note: Transient and permanent indexing failures]
            log.error(`Failed to index ${f}`, e);
            await markIndexingFailed(file.id);
            throw e;
        }

        log.debug(() => {
            const ms = Date.now() - startTime;
            const msg = [];
            if (!existingFaceIndex) msg.push(`${faceIndex.faces.length} faces`);
            if (!existingCLIPIndex) msg.push("clip");
            return `Indexed ${msg.join(" and ")} in ${f} (${ms} ms)`;
        });

        const remoteFaceIndex = existingRemoteFaceIndex ?? {
            version: faceIndexingVersion,
            client: clientPackageName,
            ...faceIndex,
        };

        const remoteCLIPIndex = existingRemoteCLIPIndex ?? {
            version: clipIndexingVersion,
            client: clientPackageName,
            ...clipIndex,
        };

        // Perform an "upsert" by using the existing raw data we got from the
        // remote as the base, and inserting or overwriting any newly indexed
        // parts. See: [Note: Preserve unknown ML data fields].

        const existingRawMLData = remoteMLData?.raw ?? {};
        const rawMLData: RawRemoteMLData = {
            ...existingRawMLData,
            face: remoteFaceIndex,
            clip: remoteCLIPIndex,
        };

        log.debug(() => ["Uploading ML data", rawMLData]);

        try {
            await putMLData(file, rawMLData);
        } catch (e) {
            // See: [Note: Transient and permanent indexing failures]
            log.error(`Failed to put ML data for ${f}`, e);
            if (isHTTP4xxError(e)) await markIndexingFailed(file.id);
            throw e;
        }

        try {
            await saveIndexes(
                { fileID, ...faceIndex },
                { fileID, ...clipIndex },
            );
        } catch (e) {
            // Not sure if DB failures should be considered permanent or
            // transient. There isn't a known case where writing to the local
            // indexedDB should systematically fail. It could fail if there was
            // no space on device, but that's eminently retriable.
            log.error(`Failed to save indexes for ${f}`, e);
            throw e;
        }

        // This step, saving face crops, is conceptually not part of the
        // indexing pipeline; we just do it here since we have already have the
        // ImageBitmap at hand. Ignore errors that happen during this since it
        // does not impact the generated face index.
        if (!existingFaceIndex) {
            try {
                await saveFaceCrops(image.bitmap, faceIndex);
            } catch (e) {
                log.error(`Failed to save face crops for ${f}`, e);
            }
        }
    } finally {
        image.bitmap.close();
    }
};
