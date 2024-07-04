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
