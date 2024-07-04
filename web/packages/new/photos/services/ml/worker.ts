import type { EnteFile } from "@/new/photos/types/file";
import { fileLogID } from "@/new/photos/utils/file";
import { clientPackageName } from "@/next/app";
import { getKVN } from "@/next/kv";
import { ensureAuthToken } from "@/next/local-user";
import log from "@/next/log";
import { ensure } from "@/utils/ensure";
import { wait } from "@/utils/promise";
import { expose } from "comlink";
import downloadManager from "../download";
import { getAllLocalFiles, getLocalTrashedFiles } from "../files";
import type { UploadItem } from "../upload/types";
import {
    indexableFileIDs,
    markIndexingFailed,
    saveFaceIndex,
    updateAssumingLocalFiles,
} from "./db";
import { pullFaceEmbeddings, putFaceIndex } from "./embedding";
import { type FaceIndex, indexFaces } from "./face";
import type { MLWorkerElectron } from "./worker-electron";

const idleDurationStart = 5; /* 5 seconds */
const idleDurationMax = 16 * 60; /* 16 minutes */

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
    private shouldSync = false;
    private liveQ: { enteFile: EnteFile; uploadItem: UploadItem }[] = [];
    private state: "idle" | "pull" | "indexing" = "idle";
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
        this.shouldSync = true;
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
        if (this.liveQ.length < 50) {
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
            shouldSync: this.shouldSync,
            liveQ: this.liveQ,
            idleDuration: this.idleDuration,
        }));

        const scheduleTick = () => void setTimeout(() => this.tick(), 0);

        // If we've been asked to sync, do that irrespective of anything else.
        if (this.shouldSync) {
            this.shouldSync = false;
            this.state = "pull";
            void pull().then((didPull) => {
                // Reset the idle duration if we did pull something.
                if (didPull) this.idleDuration = idleDurationStart;
                // Either ways, tick again.
                scheduleTick();
            });
            // Return without waiting for the pull.
            return;
        }

        const liveQ = this.liveQ.map((i) => i.enteFile);
        this.liveQ = [];
        this.state = "indexing";
        const allSuccess = await indexNextBatch(
            liveQ,
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
}

expose(MLWorker);

/**
 * Pull embeddings from remote.
 */
const pull = pullFaceEmbeddings;

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
    liveQ: EnteFile[],
    electron: MLWorkerElectron,
    userAgent: string,
) => {
    if (!self.navigator.onLine) {
        log.info("Skipping ML indexing since we are not online");
        return false;
    }

    const userID = ensure(await getKVN("userID"));

    const files =
        liveQ.length > 0
            ? liveQ
            : await syncWithLocalFilesAndGetFilesToIndex(userID, 200);
    if (files.length == 0) return false;

    let allSuccess = true;
    for (const file of files) {
        try {
            await index(file, undefined, electron, userAgent);
            // Possibly unnecessary, but let us drain the microtask queue.
            await wait(0);
        } catch {
            allSuccess = false;
        }
    }

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
 * Index faces in a file, save the persist the results locally, and put them
 * on remote.
 *
 * @param enteFile The {@link EnteFile} to index.
 *
 * @param file If the file is one which is being uploaded from the current
 * client, then we will also have access to the file's content. In such
 * cases, pass a web {@link File} object to use that its data directly for
 * face indexing. If this is not provided, then the file's contents will be
 * downloaded and decrypted from remote.
 *
 * @param userAgent The UA of the client that is doing the indexing (us).
 */
export const index = async (
    enteFile: EnteFile,
    file: File | undefined,
    electron: MLWorkerElectron,
    userAgent: string,
) => {
    const f = fileLogID(enteFile);
    const startTime = Date.now();

    let faceIndex: FaceIndex;
    try {
        faceIndex = await indexFaces(enteFile, file, electron, userAgent);
    } catch (e) {
        // Mark indexing as having failed only if the indexing itself
        // failed, not if there were subsequent failures (like when trying
        // to put the result to remote or save it to the local face DB).
        log.error(`Failed to index faces in ${f}`, e);
        await markIndexingFailed(enteFile.id);
        throw e;
    }

    try {
        await putFaceIndex(enteFile, faceIndex);
        await saveFaceIndex(faceIndex);
    } catch (e) {
        log.error(`Failed to put/save face index for ${f}`, e);
        throw e;
    }

    log.debug(() => {
        const nf = faceIndex.faceEmbedding.faces.length;
        const ms = Date.now() - startTime;
        return `Indexed ${nf} faces in ${f} (${ms} ms)`;
    });

    return faceIndex;
};
