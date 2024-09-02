import { clientPackageName } from "@/base/app";
import { assertionFailed } from "@/base/assert";
import { isHTTP4xxError } from "@/base/http";
import { getKVN } from "@/base/kv";
import { ensureAuthToken } from "@/base/local-user";
import log from "@/base/log";
import type { ElectronMLWorker } from "@/base/types/ipc";
import type { EnteFile } from "@/new/photos/types/file";
import { fileLogID } from "@/new/photos/utils/file";
import { ensure } from "@/utils/ensure";
import { wait } from "@/utils/promise";
import { expose, wrap } from "comlink";
import downloadManager from "../download";
import { getAllLocalFiles, getLocalTrashedFiles } from "../files";
import type { UploadItem } from "../upload/types";
import {
    createImageBitmapAndData,
    fetchRenderableBlob,
    type ImageBitmapAndData,
} from "./blob";
import {
    clipIndexingVersion,
    clipMatches,
    indexCLIP,
    type CLIPIndex,
} from "./clip";
import { clusterFaces, type ClusteringOpts } from "./cluster";
import { saveFaceCrops } from "./crop";
import {
    faceIndexes,
    indexableFileIDs,
    markIndexingFailed,
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
    /** The {@link EnteFile} to index (potentially). */
    enteFile: EnteFile;
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

    private electron: ElectronMLWorker | undefined;
    private delegate: MLWorkerDelegate | undefined;
    private liveQ: IndexableItem[] = [];
    private idleTimeout: ReturnType<typeof setTimeout> | undefined;
    private idleDuration = idleDurationStart; /* unit: seconds */

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
    async init(port: MessagePort, delegate: MLWorkerDelegate) {
        this.electron = wrap<ElectronMLWorker>(port);
        this.delegate = delegate;
        // Initialize the downloadManager running in the web worker with the
        // user's token. It'll be used to download files to index if needed.
        await downloadManager.init(await ensureAuthToken());
    }

    /**
     * Start backfilling if needed.
     *
     * This function enqueues a backfill attempt and returns immediately without
     * waiting for it complete.
     *
     * During a backfill, we first attempt to fetch ML data for files which
     * don't have that data locally. If on fetching we find what we need, we
     * save it locally. Otherwise we index them.
     */
    sync() {
        this.wakeUp();
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
    onUpload(enteFile: EnteFile, uploadItem: UploadItem) {
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
            this.liveQ.push({ enteFile, uploadItem, remoteMLData: undefined });
            this.wakeUp();
        } else {
            log.debug(() => "Ignoring upload item since liveQ is full");
        }
    }

    /**
     * Find {@link CLIPMatches} for a given {@link searchPhrase}.
     */
    async clipMatches(searchPhrase: string): Promise<CLIPMatches | undefined> {
        return clipMatches(searchPhrase, ensure(this.electron));
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

        const allSuccess = await indexNextBatch(
            items,
            ensure(this.electron),
            this.delegate,
        );
        if (allSuccess) {
            // Everything is running smoothly. Reset the idle duration.
            this.idleDuration = idleDurationStart;
            // And tick again.
            scheduleTick();
            return;
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
        this.delegate?.workerDidProcessFileOrIdle();
    }

    /** Return the next batch of items to backfill (if any). */
    private async backfillQ() {
        const userID = ensure(await getKVN("userID"));
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
            enteFile: file,
            uploadItem: undefined,
            remoteMLData: mlDataByID.get(id),
        }));
    }

    // TODO-Cluster
    async clusterFaces(opts: ClusteringOpts) {
        return clusterFaces(await faceIndexes(), opts);
    }
}

expose(MLWorker);

/**
 * Find out files which need to be indexed. Then index the next batch of them.
 *
 * Returns `false` to indicate that either an error occurred, or there are no
 * more files to process, or that we cannot currently process files.
 *
 * Which means that when it returns true, all is well and there are more
 * things pending to process, so we should chug along at full speed.
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

    // Nothing to do.
    if (items.length == 0) return false;

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
                        }))(ensure(items[i++]), j);
            }
        }

        // Wait for at least one to complete (the other runners continue running
        // even if one promise reaches the finish line).
        await Promise.race(tasks);

        // Let the main thread now we're doing something.
        delegate?.workerDidProcessFileOrIdle();

        // Let us drain the microtask queue. This also gives a chance for other
        // interactive tasks like `clipMatches` to run.
        await wait(0);
    }

    // Wait for the pending tasks to drain out.
    await Promise.all(tasks);

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

    const fileIDsToIndex = await indexableFileIDs(count);
    return new Map(
        fileIDsToIndex.map((id) => [id, ensure(localFileByID.get(id))]),
    );
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
    { enteFile, uploadItem, remoteMLData }: IndexableItem,
    electron: ElectronMLWorker,
) => {
    const f = fileLogID(enteFile);
    const fileID = enteFile.id;

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
        enteFile,
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
        await markIndexingFailed(enteFile.id);
        throw e;
    }

    try {
        let faceIndex: FaceIndex;
        let clipIndex: CLIPIndex;

        const startTime = Date.now();

        try {
            [faceIndex, clipIndex] = await Promise.all([
                existingFaceIndex ?? indexFaces(enteFile, image, electron),
                existingCLIPIndex ?? indexCLIP(image, electron),
            ]);
        } catch (e) {
            // See: [Note: Transient and permanent indexing failures]
            log.error(`Failed to index ${f}`, e);
            await markIndexingFailed(enteFile.id);
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
            await putMLData(enteFile, rawMLData);
        } catch (e) {
            // See: [Note: Transient and permanent indexing failures]
            log.error(`Failed to put ML data for ${f}`, e);
            if (isHTTP4xxError(e)) await markIndexingFailed(enteFile.id);
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
