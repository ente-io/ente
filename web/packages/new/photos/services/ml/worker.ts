import { markIndexingFailed, saveFaceIndex } from "@/new/photos/services/ml/db";
import type { FaceIndex } from "@/new/photos/services/ml/types";
import type { EnteFile } from "@/new/photos/types/file";
import log from "@/next/log";
// import { expose } from "comlink";
import { fileLogID } from "../../utils/file";
import { pullFaceEmbeddings, putFaceIndex } from "./embedding";
import { indexFaces } from "./index-face";

/**
 * Run operations related to machine learning (e.g. indexing) in a Web Worker.
 *
 * This is a normal class that is however exposed (via comlink) as a proxy
 * running inside a Web Worker. This way, we do not bother the main thread with
 * tasks that might degrade interactivity.
 */
export class MLWorker {
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
