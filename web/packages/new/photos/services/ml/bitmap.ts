import { FILE_TYPE } from "@/media/file-type";
import { decodeLivePhoto } from "@/media/live-photo";
import { basename } from "@/next/file";
import { ensure } from "@/utils/ensure";
import type { EnteFile } from "../../types/file";
import { renderableImageBlob } from "../../utils/file";
import { readStream } from "../../utils/native-stream";
import DownloadManager from "../download";
import type { UploadItem } from "../upload/types";
import type { MLWorkerElectron } from "./worker-electron";

export interface ImageBitmapAndData {
    bitmap: ImageBitmap;
    data: ImageData;
}

/**
 * Return an {@link ImageBitmap} and its {@link ImageData}.
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
export const imageBitmapAndData = async (
    enteFile: EnteFile,
    uploadItem: UploadItem | undefined,
    electron: MLWorkerElectron,
): Promise<ImageBitmapAndData> => {
    const imageBitmap = uploadItem
        ? await renderableUploadItemImageBitmap(enteFile, uploadItem, electron)
        : await renderableImageBitmap(enteFile);

    // Use an OffscreenCanvas to get the bitmap's data.

    const { width, height } = imageBitmap;

    const offscreenCanvas = new OffscreenCanvas(width, height);
    const ctx = ensure(offscreenCanvas.getContext("2d"));
    ctx.drawImage(imageBitmap, 0, 0, width, height);
    const imageData = ctx.getImageData(0, 0, width, height);

    // TODO-ML: This check isn't needed, keeping it around during scaffolding.
    if (
        imageBitmap.width != imageData.width ||
        imageBitmap.height != imageData.height
    )
        throw new Error("Dimension mismatch");

    return { bitmap: imageBitmap, data: imageData };
};

/**
 * Return a {@link ImageBitmap} that downloads the source image corresponding to
 * {@link enteFile} from remote.
 *
 * -   For images the original is used.
 * -   For live photos the original image component is used.
 * -   For videos the thumbnail is used.
 */
export const renderableImageBitmap = async (enteFile: EnteFile) => {
    const fileType = enteFile.metadata.fileType;
    let blob: Blob | undefined;
    if (fileType == FILE_TYPE.VIDEO) {
        const thumbnailData = await DownloadManager.getThumbnail(enteFile);
        blob = new Blob([ensure(thumbnailData)]);
    } else {
        blob = await fetchRenderableBlob(enteFile);
    }
    return createImageBitmap(ensure(blob));
};

/**
 * Variant of {@link renderableImageBitmap} that uses the given
 * {@link uploadItem} to construct the image bitmap instead of downloading the
 * original from remote.
 *
 * For videos the thumbnail is still downloaded from remote.
 */
export const renderableUploadItemImageBitmap = async (
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
    return createImageBitmap(ensure(blob));
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

const fetchRenderableBlob = async (enteFile: EnteFile) => {
    const fileStream = await DownloadManager.getFile(enteFile);
    const fileBlob = await new Response(fileStream).blob();
    const fileType = enteFile.metadata.fileType;
    if (fileType == FILE_TYPE.IMAGE) {
        return renderableImageBlob(enteFile.metadata.title, fileBlob);
    } else if (fileType == FILE_TYPE.LIVE_PHOTO) {
        const { imageFileName, imageData } = await decodeLivePhoto(
            enteFile.metadata.title,
            fileBlob,
        );
        return renderableImageBlob(imageFileName, new Blob([imageData]));
    } else {
        // A layer above us should've already filtered these out.
        throw new Error(`Cannot index unsupported file type ${fileType}`);
    }
};
