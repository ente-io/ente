import type { EnteFile } from "@/new/photos/types/file";
import { fileLogID } from "@/new/photos/utils/file";
import { clientPackageName } from "@/next/app";
import { isHTTP4xxError } from "@/next/http";
import { getKVN } from "@/next/kv";
import { ensureAuthToken } from "@/next/local-user";
import log from "@/next/log";
import { ensure } from "@/utils/ensure";
import { wait } from "@/utils/promise";
import { expose } from "comlink";
import downloadManager from "../download";
import { getAllLocalFiles, getLocalTrashedFiles } from "../files";
import type { UploadItem } from "../upload/types";
import { imageBitmapAndData, type ImageBitmapAndData } from "./bitmap";
import { indexCLIP, type CLIPIndex } from "./clip";
import {
    indexableFileIDs,
    markIndexingFailed,
    saveCLIPIndex,
    saveFaceIndex,
    updateAssumingLocalFiles,
} from "./db";
import { pullFaceEmbeddings, putCLIPIndex, putFaceIndex } from "./embedding";
import { indexFaces, type FaceIndex } from "./face";
import type { MLWorkerElectron } from "./worker-electron";

const idleDurationStart = 5; /* 5 seconds */
const idleDurationMax = 16 * 60; /* 16 minutes */

interface IndexableItem {
    enteFile: EnteFile;
    uploadItem: UploadItem | undefined;
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
 *     sync         -> "pull"       -> "idle"
 *     upload       -> "liveq"      -> "idle"
 *     idleTimeout  -> "backfillq"  -> "idle"
 *
 * where:
 *
 * -   "pull": pulling embeddings from remote
 * -   "liveq": indexing items that are being uploaded
 * -   "backfillq": indexing unindexed items otherwise
 * -   "idle": in between state transitions
 */
export class MLWorker {
    private electron: MLWorkerElectron | undefined;
    private userAgent: string | undefined;
    private state: "idle" | "pull" | "indexing" = "idle";
    private shouldPull = false;
    private havePulledAtLeastOnce = false;
    private liveQ: IndexableItem[] = [];
    private idleTimeout: ReturnType<typeof setTimeout> | undefined;
    private idleDuration = idleDurationStart; /* unit: seconds */

    /**
     * Initialize a new {@link MLWorker}.
     *
     * This is conceptually the constructor, however it is easier to have this
     * as a separate function to avoid confounding the comlink types too much.
     *
     * @param electron The {@link MLWorkerElectron} that allows the worker to
     * use the functionality provided by our Node.js layer when running in the
     * context of our desktop app
     */
    async init(electron: MLWorkerElectron) {
        this.electron = electron;
        // Set the user agent that'll be set in the generated embeddings.
        this.userAgent = `${clientPackageName}/${await electron.appVersion()}`;
        // Initialize the downloadManager running in the web worker with the
        // user's token. It'll be used to download files to index if needed.
        await downloadManager.init(await ensureAuthToken());
    }

    /**
     * Pull embeddings from remote, and start backfilling if needed.
     *
     * This function enqueues the pull and returns immediately without waiting
     * for the pull to complete.
     *
     * While it only triggers a pull, once the pull is done it also checks for
     * pending items to backfill. So it implicitly also triggers a backfill
     * (which is why call it a less-precise sync instead of pull).
     */
    sync() {
        this.shouldPull = true;
        this.wakeUp();
    }

    /** Invoked in response to external events. */
    private wakeUp() {
        if (this.state == "idle") {
            // Currently paused. Get back to work.
            if (this.idleTimeout) clearTimeout(this.idleTimeout);
            this.idleTimeout = undefined;
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
            this.liveQ.push({ enteFile, uploadItem });
            this.wakeUp();
        } else {
            log.debug(() => "Ignoring upload item since liveQ is full");
        }
    }

    /**
     * Return true if we're currently indexing.
     */
    isIndexing() {
        return this.state == "indexing";
    }

    private async tick() {
        log.debug(() => ({
            t: "ml/tick",
            state: this.state,
            shouldSync: this.shouldPull,
            liveQ: this.liveQ,
            idleDuration: this.idleDuration,
        }));

        const scheduleTick = () => void setTimeout(() => this.tick(), 0);

        // If we've been asked to sync, do that irrespective of anything else.
        if (this.shouldPull) {
            // Allow this flag to be reset while we're busy pulling (triggering
            // another pull when we tick next).
            this.shouldPull = false;
            this.state = "pull";
            try {
                const didPull = await pull();
                // Mark that we completed once attempt at pulling successfully
                // (irrespective of whether or not that got us some data).
                this.havePulledAtLeastOnce = true;
                // Reset the idle duration if we did pull something.
                if (didPull) this.idleDuration = idleDurationStart;
            } catch (e) {
                log.error("Failed to pull embeddings", e);
            }
            // Tick again, even if we got an error.
            //
            // While the backfillQ won't be processed until at least a pull has
            // happened once (`havePulledAtLeastOnce`), the liveQ can still be
            // processed since these are new files without remote embeddings.
            scheduleTick();
            return;
        }

        const liveQ = this.liveQ;
        this.liveQ = [];
        this.state = "indexing";

        // Use the liveQ if present, otherwise get the next batch to backfill,
        // but only if we've pulled once from remote successfully (otherwise we
        // might end up reindexing files that were already indexed on remote but
        // which we didn't know about since pull failed, say, for transient
        // network issues).
        const items =
            liveQ.length > 0
                ? liveQ
                : this.havePulledAtLeastOnce
                  ? await this.backfillQ()
                  : [];

        const allSuccess = await indexNextBatch(
            items,
            ensure(this.electron),
            ensure(this.userAgent),
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
    }

    /** Return the next batch of items to backfill (if any). */
    async backfillQ() {
        const userID = ensure(await getKVN("userID"));
        return syncWithLocalFilesAndGetFilesToIndex(userID, 200).then((fs) =>
            fs.map((f) => ({ enteFile: f, uploadItem: undefined })),
        );
    }
}

expose(MLWorker);

/**
 * Pull embeddings from remote.
 *
 * Return true atleast one embedding was pulled.
 */
const pull = async () => {
    const res = await Promise.allSettled([
        pullFaceEmbeddings(),
        // TODO-ML: clip-test
        // pullCLIPEmbeddings(),
    ]);
    for (const r of res) {
        switch (r.status) {
            case "fulfilled":
                // Return true if any pulled something.
                if (r.value) return true;
                break;
            case "rejected":
                // Throw if any failed.
                throw r.reason;
        }
    }
    // Return false if neither pulled anything.
    return false;
};

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
    electron: MLWorkerElectron,
    userAgent: string,
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

    // Index, keeping track if any of the items failed.
    let allSuccess = true;
    for (const { enteFile, uploadItem } of items) {
        try {
            await index(enteFile, uploadItem, electron, userAgent);
            // Possibly unnecessary, but let us drain the microtask queue.
            await wait(0);
        } catch {
            allSuccess = false;
        }
    }

    // Return true if nothing failed.
    return allSuccess;
};

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
const syncWithLocalFilesAndGetFilesToIndex = async (
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

/**
 * Index file, save the persist the results locally, and put them on remote.
 *
 * @param enteFile The {@link EnteFile} to index.
 *
 * @param uploadItem If the file is one which is being uploaded from the current
 * client, then we will also have access to the file's content. In such cases,
 * passing a web {@link File} object will directly use that its data when
 * indexing. Otherwise (when this is not provided), the file's contents will be
 * downloaded and decrypted from remote.
 *
 * @param userAgent The UA of the client that is doing the indexing (us).
 */
const index = async (
    enteFile: EnteFile,
    uploadItem: UploadItem | undefined,
    electron: MLWorkerElectron,
    userAgent: string,
) => {
    const f = fileLogID(enteFile);
    const startTime = Date.now();

    const image = await imageBitmapAndData(enteFile, uploadItem, electron);
    const res = await Promise.allSettled([
        _indexFace(f, enteFile, image, electron, userAgent),
        // TODO-ML: clip-test
        // _indexCLIP(f, enteFile, image, electron, userAgent),
    ]);
    image.bitmap.close();

    const msg: string[] = [];
    for (const r of res) {
        if (r.status == "rejected") throw r.reason;
        else msg.push(r.value);
    }

    log.debug(() => {
        const ms = Date.now() - startTime;
        return `Indexed ${msg.join(" and ")} in ${f} (${ms} ms)`;
    });
};

const _indexFace = async (
    f: string,
    enteFile: EnteFile,
    image: ImageBitmapAndData,
    electron: MLWorkerElectron,
    userAgent: string,
) => {
    let faceIndex: FaceIndex;
    try {
        faceIndex = await indexFaces(enteFile, image, electron, userAgent);
    } catch (e) {
        log.error(`Failed to index faces in ${f}`, e);
        await markIndexingFailed(enteFile.id);
        throw e;
    }

    // [Note: Transient and permanent indexing failures]
    //
    // Generally speaking, we mark indexing for a file as having failed only if
    // the indexing itself failed, not if there were subsequent failures (like
    // when trying to put the result to remote or save it to the local face DB).
    //
    // When we mark it as failed, then a flag is persisted corresponding to this
    // file in the ML DB so that it won't get reindexed in future runs. This are
    // thus considered as permanent failures.
    //
    // > We might retry in future versions if we identify reasons for indexing
    // > to fail (it shouldn't) and rectify them.
    //
    // On the other hand, saving the face index to remote might fail for
    // transient issues (network issues, or remote having hiccups). We don't
    // mark a file as failed permanently in such cases, so that it gets retried
    // at some point. These are considered as transient failures.
    //
    // However, this opens the possibility of some non-transient failure getting
    // classified as a transient failure and causing the client to try and index
    // the same file again and again, when in fact there is a issue specific to
    // that file which is preventing the index from being saved. What exactly?
    // We don't know, but the possibility exists.
    //
    // To reduce the chances of this happening, we treat HTTP 4xx responses as
    // permanent failures too - there are no known cases where a client retrying
    // a 4xx response would work, and there are known (but rare) cases where a
    // client might get a 4xx (e.g. if the file has over ~700 faces, then remote
    // will return a 413 Request Entity Too Large).

    try {
        await putFaceIndex(enteFile, faceIndex);
        await saveFaceIndex(faceIndex);
    } catch (e) {
        log.error(`Failed to put/save face index for ${f}`, e);
        if (isHTTP4xxError(e)) await markIndexingFailed(enteFile.id);
        throw e;
    }

    // A message for debug printing.
    return `${faceIndex.faceEmbedding.faces.length} faces`;
};

// TODO-ML: clip-test export
export const _indexCLIP = async (
    f: string,
    enteFile: EnteFile,
    image: ImageBitmapAndData,
    electron: MLWorkerElectron,
    userAgent: string,
) => {
    let clipIndex: CLIPIndex;
    try {
        clipIndex = await indexCLIP(enteFile, image, electron, userAgent);
    } catch (e) {
        log.error(`Failed to index CLIP in ${f}`, e);
        await markIndexingFailed(enteFile.id);
        throw e;
    }

    // See: [Note: Transient and permanent indexing failures]
    try {
        await putCLIPIndex(enteFile, clipIndex);
        await saveCLIPIndex(clipIndex);
    } catch (e) {
        log.error(`Failed to put/save CLIP index for ${f}`, e);
        if (isHTTP4xxError(e)) await markIndexingFailed(enteFile.id);
        throw e;
    }

    // A message for debug printing.
    return "clip";
};
