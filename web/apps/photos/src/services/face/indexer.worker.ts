import log from "@/next/log";
import type { EnteFile } from "types/file";
import { markIndexingFailed } from "./db";
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
    async index(enteFile: EnteFile, file: File | undefined) {
        const fileID = enteFile.id;
        try {
            const faceIndex = await indexFaces(enteFile, file);
            log.info(`faces in file ${fileID}`, faceIndex);
        } catch (e) {
            log.error(`Failed to index faces in file ${fileID}`, e);
            markIndexingFailed(enteFile.id);
        }
    }
}
