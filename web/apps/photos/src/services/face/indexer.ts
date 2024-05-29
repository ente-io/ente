import type { EnteFile } from "types/file";

/**
 * Face indexing orchestrator.
 *
 * This is class that drives the face indexing process, across all files that
 * need to still be indexed. This usually runs in a Web Worker so as to not get
 * in the way of the main thread.
 *
 * It operates in two modes - live indexing and backfill.
 *
 * In live indexing, any files that are being uploaded from the current client
 * are provided to the indexer, which indexes them. This is more efficient since
 * we already have the file's content at hand and do not have to download and
 * decrypt it.
 *
 * In backfill, the indexer figures out if any of the user's files (irrespective
 * of where they were uploaded from) still need to be indexed, and if so,
 * downloads, decrypts and indexes them.
 *
 * Live indexing has higher priority, backfill runs otherwise.
 *
 * If nothing needs to be indexed, the indexer goes to sleep for a while.
 */
export class FaceIndexer {
    private liveItems: [file: File, enteFile: EnteFile][];

    /**
     * Add {@link file} associated with {@link enteFile} to the live indexing
     * queue.
     */
    enqueueFile(file: File, enteFile: EnteFile) {
        this.liveItems.push([file, enteFile]);
    }

    tick() {

    }
}
