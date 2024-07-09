import type { EnteFile } from "@/new/photos/types/file";
import type { ImageBitmapAndData } from "./bitmap";
import type { MLWorkerElectron } from "./worker-electron";

/**
 * The version of the CLIP indexing pipeline implemented by the current client.
 */
export const clipIndexingVersion = 1;

/**
 * The CLIP embedding for a file (and some metadata).
 *
 * See {@link FaceIndex} for a similar structure with more comprehensive
 * documentation.
 */
export interface CLIPIndex {
    /** The ID of the {@link EnteFile} whose index this is. */
    fileID: number;
    /** An integral version number of the indexing algorithm / pipeline. */
    version: number;
    /** The UA for the client which generated this embedding. */
    client: string;
    /** The CLIP embedding itself. */
    embedding: number[];
}

/**
 * Compute the CLIP embedding of a given file.
 *
 * This function is the entry point to the CLIP indexing pipeline. The file goes
 * through various stages:
 *
 * 1. Downloading the original if needed.
 * 2. Convert (if needed) and pre-process.
 * 3. Compute embeddings using ONNX/CLIP.
 *
 * Once all of it is done, it CLIP embedding (wrapped as a {@link CLIPIndex} so
 * that it can be saved locally and also uploaded to the user's remote storage
 * for use on their other devices).
 *
 * @param enteFile The {@link EnteFile} to index.
 *
 * @param uploadItem If we're called during the upload process, then this will
 * be set to the {@link UploadItem} that was uploaded. This way, we can directly
 * use the on-disk file instead of needing to download the original from remote.
 *
 * @param electron The {@link MLWorkerElectron} instance that allows us to call
 * our Node.js layer for various functionality.
 *
 * @param userAgent The UA of the client that is doing the indexing (us).
 */
export const indexCLIP = async (
    enteFile: EnteFile,
    image: ImageBitmapAndData,
    electron: MLWorkerElectron,
    userAgent: string,
): Promise<CLIPIndex> => {
    const { data: imageData } = image;
    const fileID = enteFile.id;

    return {
        fileID,
        version: clipIndexingVersion,
        client: userAgent,
        embedding: await indexCLIP_(imageData, electron),
    };
};

const indexCLIP_ = async (
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    _imageData: ImageData,
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    _electron: MLWorkerElectron,
    // eslint-disable-next-line @typescript-eslint/require-await
): Promise<number[]> => {
    throw new Error("TODO");
};
