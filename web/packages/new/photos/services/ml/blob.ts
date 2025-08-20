import { basename } from "ente-base/file-name";
import type { ElectronMLWorker } from "ente-base/types/ipc";
import { renderableImageBlob } from "ente-gallery/services/convert";
import { downloadManager } from "ente-gallery/services/download";
import {
    fileSystemUploadItemIfUnchanged,
    type ProcessableUploadItem,
    type UploadItem,
} from "ente-gallery/services/upload";
import { readStream } from "ente-gallery/utils/native-stream";
import type { EnteFile } from "ente-media/file";
import { fileFileName } from "ente-media/file-metadata";
import { FileType } from "ente-media/file-type";
import { decodeLivePhoto } from "ente-media/live-photo";

/**
 * An image bitmap and its RGBA data.
 *
 * This is data structure containing data about an image in all formats that the
 * various indexing steps need.
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
export const createImageBitmapAndData = async (
    imageBlob: Blob,
): Promise<ImageBitmapAndData> => {
    const imageBitmap = await createImageBitmap(imageBlob);

    const { width, height } = imageBitmap;

    // Use an OffscreenCanvas to get the bitmap's data.
    const offscreenCanvas = new OffscreenCanvas(width, height);
    const ctx = offscreenCanvas.getContext("2d")!;
    ctx.drawImage(imageBitmap, 0, 0, width, height);
    const imageData = ctx.getImageData(0, 0, width, height);

    return { bitmap: imageBitmap, data: imageData };
};

/**
 * Return a renderable blob (converting to JPEG if needed) for the given data.
 *
 * The blob from the relevant image component is either constructed using the
 * given {@link uploadItem} if present, otherwise it is downloaded from remote.
 *
 * - For images it is constructed from the image.
 * - For videos it is constructed from the thumbnail.
 * - For live photos it is constructed from the image component of the live
 *   photo.
 *
 * Then, if the image blob we have seems to be something that the browser cannot
 * handle, we convert it into a JPEG blob so that it can subsequently be used to
 * create an {@link ImageBitmap}.
 *
 * @param file The {@link EnteFile} to index.
 *
 * @param uploadItem If we're called during the upload process, then this will
 * be set to the {@link FilesystemUploadItem} that was uploaded so that we can
 * directly use the on-disk file instead of needing to download the original.
 *
 * @param electron The {@link ElectronMLWorker} instance that we can use to IPC
 * with the Node.js layer.
 */
export const fetchRenderableBlob = async (
    file: EnteFile,
    puItem: ProcessableUploadItem | undefined,
    electron: ElectronMLWorker,
): Promise<Blob> =>
    (puItem
        ? await fetchRenderableUploadItemBlob(file, puItem, electron)
        : undefined) ?? (await fetchRenderableEnteFileBlob(file));

const fetchRenderableUploadItemBlob = async (
    file: EnteFile,
    puItem: ProcessableUploadItem,
    electron: ElectronMLWorker,
) => {
    if (file.metadata.fileType == FileType.video) {
        const thumbnailData = await downloadManager.thumbnailData(file);
        return new Blob([thumbnailData!]);
    } else {
        const uploadItem =
            puItem instanceof File
                ? puItem
                : await fileSystemUploadItemIfUnchanged(
                      puItem,
                      electron.fsStatMtime,
                  );
        if (!uploadItem) {
            // The file on disk has changed. Fetch it from remote.
            return undefined;
        }
        const blob = await readNonVideoUploadItem(uploadItem, electron);
        return renderableImageBlob(blob, fileFileName(file));
    }
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
 * Return a renderable one (possibly involving a JPEG conversion) blob for the
 * given {@link EnteFile}.
 *
 * -  The original will be downloaded if needed.
 * -  The original will be converted to JPEG if needed.
 */
export const fetchRenderableEnteFileBlob = async (
    file: EnteFile,
): Promise<Blob> => {
    const fileType = file.metadata.fileType;
    if (fileType == FileType.video) {
        const thumbnailData = await downloadManager.thumbnailData(file);
        return new Blob([thumbnailData!]);
    }

    const originalFileBlob = await downloadManager.fileBlob(file, {
        background: true,
    });

    if (fileType == FileType.livePhoto) {
        const { imageFileName, imageData } = await decodeLivePhoto(
            fileFileName(file),
            originalFileBlob,
        );
        return renderableImageBlob(new Blob([imageData]), imageFileName);
    } else if (fileType == FileType.image) {
        return await renderableImageBlob(originalFileBlob, fileFileName(file));
    } else {
        // A layer above us should've already filtered these out.
        throw new Error(`Cannot index unsupported file type ${fileType}`);
    }
};
