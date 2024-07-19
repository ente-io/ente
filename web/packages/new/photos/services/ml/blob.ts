import { basename } from "@/base/file";
import { FILE_TYPE } from "@/media/file-type";
import { decodeLivePhoto } from "@/media/live-photo";
import { ensure } from "@/utils/ensure";
import type { EnteFile } from "../../types/file";
import { renderableImageBlob } from "../../utils/file";
import { readStream } from "../../utils/native-stream";
import DownloadManager from "../download";
import type { UploadItem } from "../upload/types";
import type { MLWorkerElectron } from "./worker-types";

/**
 * A data structure containing data about an image in all formats that the
 * various indexing steps need. Consolidating all the data here and parsing them
 * in one go obviates the need for each indexing step to roll their own parsing.
 */
export interface IndexableImage {
    /**
     * The original file's data, and a renderable representation of it (both as
     * {@link Blob}s).
     */
    blobs: IndexableBlobs;
    /**
     * An {@link ImageBitmap} from the original or converted image.
     *
     * This bitmap is constructed from the original file's data if the
     * browser knows how to handle it; otherwise we first convert it to a JPEG
     * and then create the bitmap from that.
     */
    bitmap: ImageBitmap;
    /**
     * The RGBA {@link ImageData} of the {@link bitmap}, obtained by rendering
     * it to an offscreen canvas.
     */
    data: ImageData;
}

/**
 * A pair of blobs - the original, and a possibly converted "renderable" one -
 * for a file that we're trying to index.
 */
export interface IndexableBlobs {
    /**
     * The original file's data (as a {@link Blob}).
     *
     * -   For images this is guaranteed to be present.
     * -   For videos it will not be present.
     * -   For live photos it will the (original) image component of the live
     *     photo.
     */
    original: Blob | undefined;
    /**
     * The original (if the browser possibly supports rendering this type of
     * images) or otherwise a converted JPEG blob.
     *
     * This blob is meant to be used to construct the {@link ImageBitmap}
     * that'll be used for further operations that need access to the RGB data
     * of the image.
     *
     * -   For images this is constructed from the image.
     * -   For videos this is constructed from the thumbnail.
     * -   For live photos this is constructed from the image component of the
     *     live photo.
     */
    renderable: Blob;
}

/**
 * Create an {@link ImageBitmap} from the given {@link imageBlob}, and return
 * both the image bitmap and its {@link ImageData}.
 */
export const imageBitmapAndData = async (
    imageBlob: Blob,
): Promise<IndexableImage> => {
    const imageBitmap = await createImageBitmap(imageBlob);

    const { width, height } = imageBitmap;

    // Use an OffscreenCanvas to get the bitmap's data.
    const offscreenCanvas = new OffscreenCanvas(width, height);
    const ctx = ensure(offscreenCanvas.getContext("2d"));
    ctx.drawImage(imageBitmap, 0, 0, width, height);
    const imageData = ctx.getImageData(0, 0, width, height);

    return { bitmap: imageBitmap, data: imageData };
};

/**
 * Return a {@link Blob} that can be used to create an {@link ImageBitmap}.
 *
 * The blob from the relevant image component is either constructed using the
 * given {@link uploadItem} if present, otherwise it is downloaded from remote.
 *
 * -   For images the original is used.
 * -   For live photos the original image component is used.
 * -   For videos the thumbnail is used.
 *
 * @param enteFile The {@link EnteFile} to index.
 *
 * @param uploadItem If we're called during the upload process, then this will
 * be set to the {@link UploadItem} that was uploaded. This way, we can directly
 * use the on-disk file instead of needing to download the original from remote.
 *
 * @param electron The {@link MLWorkerElectron} instance that allows us to call
 * our Node.js layer for various functionality.
 */
export const renderableBlob = async (
    enteFile: EnteFile,
    uploadItem: UploadItem | undefined,
    electron: MLWorkerElectron,
): Promise<Blob> =>
    uploadItem
        ? await renderableUploadItemBlob(enteFile, uploadItem, electron)
        : await indexableBlobs(enteFile);

const renderableUploadItemBlob = async (
    enteFile: EnteFile,
    uploadItem: UploadItem,
    electron: MLWorkerElectron,
) => {
    const fileType = enteFile.metadata.fileType;
    let blob: Blob | undefined;
    if (fileType == FILE_TYPE.VIDEO) {
        const thumbnailData = await DownloadManager.getThumbnail(enteFile);
        blob = new Blob([ensure(thumbnailData)]);
    } else {
        const file = await readNonVideoUploadItem(uploadItem, electron);
        blob = await renderableImageBlob(enteFile.metadata.title, file);
    }
    return ensure(blob);
};

/**
 * Read the given {@link uploadItem} into an in-memory representation.
 *
 * See: [Note: Reading a UploadItem]
 *
 * @param uploadItem An {@link UploadItem} which we are trying to index. The
 * code calling us guarantees that this function will not be called for videos.
 *
 * @returns a web {@link File} that can be used to access the upload item's
 * contents.
 */
const readNonVideoUploadItem = async (
    uploadItem: UploadItem,
    electron: MLWorkerElectron,
): Promise<File> => {
    if (typeof uploadItem == "string" || Array.isArray(uploadItem)) {
        const { response, lastModifiedMs } = await readStream(
            electron,
            uploadItem,
        );
        const path = typeof uploadItem == "string" ? uploadItem : uploadItem[1];
        // This function will not be called for videos, and for images
        // it is reasonable to read the entire stream into memory here.
        return new File([await response.arrayBuffer()], basename(path), {
            lastModified: lastModifiedMs,
        });
    } else {
        if (uploadItem instanceof File) {
            return uploadItem;
        } else {
            return uploadItem.file;
        }
    }
};

/**
 * Return a pair of blobs for the given file - the original, and a renderable
 * one (possibly involving a JPEG conversion).
 */
export const indexableBlobs = async (
    enteFile: EnteFile,
): Promise<IndexableBlobs> => {
    const fileType = enteFile.metadata.fileType;
    if (fileType == FILE_TYPE.VIDEO) {
        const thumbnailData = await DownloadManager.getThumbnail(enteFile);
        return {
            original: undefined,
            renderable: new Blob([ensure(thumbnailData)]),
        };
    }

    const fileStream = await DownloadManager.getFile(enteFile);
    const fileBlob = await new Response(fileStream).blob();
    let blob: Blob | undefined;
    if (fileType == FILE_TYPE.LIVE_PHOTO) {
        const { imageFileName, imageData } = await decodeLivePhoto(
            enteFile.metadata.title,
            fileBlob,
        );
        blob = await renderableImageBlob(imageFileName, new Blob([imageData]));
    } else if (fileType == FILE_TYPE.IMAGE) {
        blob = await renderableImageBlob(enteFile.metadata.title, fileBlob);
    } else {
        // A layer above us should've already filtered these out.
        throw new Error(`Cannot index unsupported file type ${fileType}`);
    }

    if (!blob)
        throw new 

    }

    return { original: fileBlob, renderable: ensure(blob) };
};
