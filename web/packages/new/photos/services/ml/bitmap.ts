import { FILE_TYPE } from "@/media/file-type";
import { decodeLivePhoto } from "@/media/live-photo";
import { ensure } from "@/utils/ensure";
import type { EnteFile } from "../../types/file";
import { renderableImageBlob } from "../../utils/file";
import DownloadManager from "../download";

/**
 * Return a {@link ImageBitmap}, using {@link file} if present otherwise
 * downloading the source image corresponding to {@link enteFile} from remote.
 *
 * -   For images the original is used.
 * -   For live photos the original image component is used.
 * -   For videos their thumbnail is used.
 */
export const renderableImageBitmap = async (
    enteFile: EnteFile,
    file?: File | undefined,
) => {
    const fileType = enteFile.metadata.fileType;
    let blob: Blob;
    if (fileType == FILE_TYPE.VIDEO) {
        const thumbnailData = await DownloadManager.getThumbnail(enteFile);
        blob = new Blob([ensure(thumbnailData)]);
    } else {
        blob = ensure(
            file
                ? await renderableImageBlob(enteFile.metadata.title, file)
                : await fetchRenderableBlob(enteFile),
        );
    }
    return createImageBitmap(blob);
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
