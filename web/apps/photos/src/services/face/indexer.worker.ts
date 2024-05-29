import log from "@/next/log";
import type { EnteFile } from "types/file";
import { logIdentifier } from "utils/file";
import { closeFaceDBConnectionsIfNeeded, markIndexingFailed } from "./db";
import { indexFaces } from "./f-index";

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
    async index(enteFile: EnteFile, file: File | undefined) {
        const f = logIdentifier(enteFile);
        try {
            const faceIndex = await indexFaces(enteFile, file);
            log.info(`faces in file ${f}`, faceIndex);
        } catch (e) {
            log.error(`Failed to index faces in file ${f}`, e);
            markIndexingFailed(enteFile.id);
        }
    }

    /**
     * Calls {@link closeFaceDBConnectionsIfNeeded} to close any open
     * connections to the face DB from the web worker's context.
     */
    closeFaceDB() {
        closeFaceDBConnectionsIfNeeded();
    }
}
