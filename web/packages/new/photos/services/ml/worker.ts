import { expose } from "comlink";
import { pullFaceEmbeddings } from "./embedding";

/**
 * Run operations related to face indexing and search in a Web Worker.
 *
 * This is a normal class that is however exposed (via comlink) as a proxy
 * running inside a Web Worker. This way, we do not bother the main thread with
 * tasks that might degrade interactivity.
 */
export class FaceWorker {
    private isSyncing = false;

    /**
     * Pull embeddings from remote, and start backfilling if needed.
     */
    async sync() {
        if (this.isSyncing) return;
        this.isSyncing = true;
        await pullFaceEmbeddings();
        this.isSyncing = false;
    }
}

expose(FaceWorker);
