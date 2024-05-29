import log from "@/next/log";
import { wait } from "@/utils/promise";
import type { EnteFile } from "types/file";
import { markIndexingFailed } from "./db";
import { indexFaces } from "./f-index";

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
    /** Live indexing queue. */
    private liveItems: { file: File; enteFile: EnteFile }[];
    /** True when we have been paused externally. */
    private isPaused = false;
    /** Timeout for when the next time we will wake up. */
    private wakeTimeout: ReturnType<typeof setTimeout> | undefined;

    /**
     * Add {@link file} associated with {@link enteFile} to the live indexing
     * queue.
     */
    enqueueFile(file: File, enteFile: EnteFile) {
        this.liveItems.push({ file, enteFile });
        this.wakeUpIfNeeded();
    }

    private wakeUpIfNeeded() {
        // If we were asked to pause, don't do anything.
        if (this.isPaused) return;
        // Already awake.
        if (!this.wakeTimeout) return;
        // Cancel the alarm, wake up now.
        clearTimeout(this.wakeTimeout);
        this.wakeTimeout = undefined;
        // Get to work.
        this.tick();
    }

    private async tick() {
        const item = this.liveItems.pop();
        if (!item) {
            // TODO-ML: backfill instead if needed here.
            if (!this.isPaused) {
                this.wakeTimeout = setTimeout(() => {
                    this.wakeTimeout = undefined;
                    this.wakeUpIfNeeded();
                }, 30 * 1000);
            }
            return;
        }

        const fileID = item.enteFile.id;
        try {
            const faceIndex = await indexFaces(item.enteFile, item.file);
        } catch (e) {
            log.error(`Failed to index faces in file ${fileID}`, e);
            markIndexingFailed(item.enteFile.id);
        }

        // Let the runloop drain.
        await wait(0);
        // Run again.
        this.tick();
    }
}
