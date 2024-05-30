import log from "@/next/log";
import { putFaceEmbedding } from "services/face/remote";
import type { EnteFile } from "types/file";
import { logIdentifier } from "utils/file";
import { closeFaceDBConnectionsIfNeeded, markIndexingFailed } from "./db";
import { indexFaces } from "./f-index";
import type { MlFileData } from "./types-old";

/**
 * Index faces in a file, save the persist the results locally, and put them on
 * remote.
 *
 * This class is instantiated in a Web Worker so as to not get in the way of the
 * main thread. It could've been a bunch of free standing functions too, it is
 * just a class for convenience of compatibility with how the rest of our
 * comlink workers are structured.
 */
export class FaceIndexerWorker {
    /*
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
     */
    async index(enteFile: EnteFile, file: File | undefined, userAgent: string) {
        const f = logIdentifier(enteFile);

        let faceIndex: MlFileData;
        try {
            faceIndex = await indexFaces(enteFile, file);
            log.debug(() => ({ f, faceIndex }));
        } catch (e) {
            // Mark indexing as having failed only if the indexing itself
            // failed, not if there were subsequent failures (like when trying
            // to put the result to remote or save it to the local face DB).
            log.error(`Failed to index faces in file ${f}`, e);
            markIndexingFailed(enteFile.id);
            throw e;
        }

        await putFaceEmbedding(enteFile, faceIndex, userAgent);
        return faceIndex;
    }

    /**
     * Calls {@link closeFaceDBConnectionsIfNeeded} to close any open
     * connections to the face DB from the web worker's context.
     */
    closeFaceDB() {
        closeFaceDBConnectionsIfNeeded();
    }
}
