import { markIndexingFailed, saveFaceIndex } from "@/new/photos/services/ml/db";
import type { FaceIndex } from "@/new/photos/services/ml/types";
import type { EnteFile } from "@/new/photos/types/file";
import log from "@/next/log";
// import { expose } from "comlink";
import { fileLogID } from "../../utils/file";
import { pullFaceEmbeddings, putFaceIndex } from "./embedding";
import { indexFaces } from "./index-face";
import { wait } from "@/utils/promise";

/**
 * The MLWorker state machine.
 *
 *     ext. event      state           then state
 *    ------------- --------------- --------------
 *     sync         -> "pull"       -> "idle"
 *     upload       -> "liveq"      -> "idle"
 *     idleTimeout  -> "backfillq"  -> "idle"
 *
 * where
 *
 * -   "pull": pulling embeddings from remote
 * -   "liveq": indexing items that are being uploaded
 * -   "backfillq": indexing unindexed items otherwise
 * -   "idle": in between state transitions
 */
type MLWorkerState = "idle" | "pull" | "liveq" | "backfillq";

/**
 * Run operations related to machine learning (e.g. indexing) in a Web Worker.
 *
 * This is a normal class that is however exposed (via comlink) as a proxy
 * running inside a Web Worker. This way, we do not bother the main thread with
 * tasks that might degrade interactivity.
 */
export class MLWorker {
    private state: MLWorkerState = "idle";
    private isSyncing = false;
    private shouldSync = false;
    private liveQ: EnteFile[] = [];
    private idleTimeout: ReturnType<typeof setTimeout> | undefined;

    /**
     * Pull embeddings from remote, and start backfilling if needed.
     *
     * This function enqueues the pull and returns immediately without waiting
     * for the pull to complete.
     */
    sync() {
        this.shouldSync = true;
        if (this.idleTimeout) {
            clearTimeout(this.idleTimeout);
            this.idleTimeout = undefined;
            this.tick();
        } else {
            // this.tick will get run when the current task finishes.
        }
    }

    private tick() {
        // Schedule a new macrotask (by using setTimeout) instead of scheduling
        // a new microtask (by directly resolving the promise). This is likely
        // unnecessary; I'm doing this as a partially out of superstition aiming
        // to to give GC a chance to run if needed and generally ease execution
        // / memory pressure.
        const next = () => setTimeout(() => this.tick(), 0);

        // If we've been asked to sync, do that irrespective of anything else.
        if (this.shouldSync) {
            this.shouldSync = false;
            this.state = "pull";
            void this.pull().then(next);
            return;
        }

        // Otherwise see if there is something in the live queue.
        if (this.liveQ.length > 0) {
            this.state = "liveq";
            void this.liveq().then(next);
            return;
        }

        // // Otherwise check to see if there is something to backfill.
        // const { indexableCount } = await indexedAndIndexableCounts();
        // if (indexableCount > 0) {
        //     this.state = "backfillq";
        //     void this.liveq().then(() => this.tick());
        //     return;
        // }

        // if (this.isSyncing) return;
        // this.isSyncing = true;
        // this.isSyncing = false;
        // void this.next();
    }

    async pull() {
        await pullFaceEmbeddings();
    }

    async liveq() {
        console.log("liveq");
        await wait(0);
    }
}

// TODO-ML: Temorarily disable
// expose(MLWorker);

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
    userAgent: string,
) => {
    const f = fileLogID(enteFile);
    const startTime = Date.now();

    let faceIndex: FaceIndex;
    try {
        faceIndex = await indexFaces(enteFile, file, userAgent);
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
