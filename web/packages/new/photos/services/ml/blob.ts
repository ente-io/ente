import { basename } from "@/base/file";
import type { ElectronMLWorker } from "@/base/types/ipc";
import { FileType } from "@/media/file-type";
import { decodeLivePhoto } from "@/media/live-photo";
import { ensure } from "@/utils/ensure";
import type { EnteFile } from "../../types/file";
import { renderableImageBlob } from "../../utils/file";
import { readStream } from "../../utils/native-stream";
import DownloadManager from "../download";
import type { UploadItem } from "../upload/types";

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
    originalImageBlob: Blob | undefined;
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
    renderableBlob: Blob;
}

/**
 * Indexable blobs augmented with the image bitmap and RGBA data.
 *
 * This is data structure containing data about an image in all formats that the
 * various indexing steps need. Consolidating all the data here and parsing them
 * in one go obviates the need for each indexing step to roll their own parsing.
 */
export interface ImageBitmapAndData {
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
 * Create an {@link ImageBitmap} from the given {@link imageBlob}, and return
 * both the image bitmap and its {@link ImageData}.
 */
export const imageBitmapAndData = async (
    imageBlob: Blob,
): Promise<ImageBitmapAndData> => {
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
 * Return a pair of blobs for the given data - the original, and a renderable
 * one (possibly involving a JPEG conversion).
 *
 * The blob from the relevant image component is either constructed using the
 * given {@link uploadItem} if present, otherwise it is downloaded from remote.
 *
 * -   For images the original is used.
 * -   For live photos the original image component is used.
 * -   For videos the thumbnail is used.
 *
 * Then, if the image blob we have seems to be something that the browser cannot
 * handle, we convert it into a JPEG blob so that it can subsequently be used to
 * create an {@link ImageBitmap}.
 *
 * @param enteFile The {@link EnteFile} to index.
 *
 * @param uploadItem If we're called during the upload process, then this will
 * be set to the {@link UploadItem} that was uploaded. This way, we can directly
 * use the on-disk file instead of needing to download the original from remote.
 *
 * @param electron The {@link ElectronMLWorker} instance that stands as a
 * witness that we're actually running in our desktop app (and thus can safely
 * call our Node.js layer for various functionality).
 */
export const indexableBlobs = async (
    enteFile: EnteFile,
    uploadItem: UploadItem | undefined,
    electron: ElectronMLWorker,
): Promise<IndexableBlobs> =>
    uploadItem
        ? await indexableUploadItemBlobs(enteFile, uploadItem, electron)
        : await indexableEnteFileBlobs(enteFile);

const indexableUploadItemBlobs = async (
    enteFile: EnteFile,
    uploadItem: UploadItem,
    electron: ElectronMLWorker,
) => {
    const fileType = enteFile.metadata.fileType;
    let originalImageBlob: Blob | undefined;
    let renderableBlob: Blob;
    if (fileType == FileType.video) {
        const thumbnailData = await DownloadManager.getThumbnail(enteFile);
        renderableBlob = new Blob([ensure(thumbnailData)]);
    } else {
        originalImageBlob = await readNonVideoUploadItem(uploadItem, electron);
        renderableBlob = await renderableImageBlob(
            enteFile.metadata.title,
            originalImageBlob,
        );
    }
    return { originalImageBlob, renderableBlob };
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
    electron: ElectronMLWorker,
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
 *
 * -  The original will be downloaded if needed
 * -  The original will be converted to JPEG if needed
 */
export const indexableEnteFileBlobs = async (
    enteFile: EnteFile,
): Promise<IndexableBlobs> => {
    const fileType = enteFile.metadata.fileType;
    if (fileType == FileType.video) {
        const thumbnailData = await DownloadManager.getThumbnail(enteFile);
        return {
            originalImageBlob: undefined,
            renderableBlob: new Blob([ensure(thumbnailData)]),
        };
    }

    const fileStream = await DownloadManager.getFile(enteFile);
    const originalImageBlob = await new Response(fileStream).blob();

    let renderableBlob: Blob;
    if (fileType == FileType.livePhoto) {
        const { imageFileName, imageData } = await decodeLivePhoto(
            enteFile.metadata.title,
            originalImageBlob,
        );
        renderableBlob = await renderableImageBlob(
            imageFileName,
            new Blob([imageData]),
        );
    } else if (fileType == FileType.image) {
        renderableBlob = await renderableImageBlob(
            enteFile.metadata.title,
            originalImageBlob,
        );
    } else {
        // A layer above us should've already filtered these out.
        throw new Error(`Cannot index unsupported file type ${fileType}`);
    }

    return { originalImageBlob, renderableBlob };
};
