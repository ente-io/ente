import { FILE_TYPE } from "@/media/file-type";
import { decodeLivePhoto } from "@/media/live-photo";
import { ensure } from "@/utils/ensure";
import type { EnteFile } from "../../types/file";
import { getRenderableImage } from "../../utils/file";
import DownloadManager from "../download";

/**
 * Return a "renderable" image blob, using {@link file} if present otherwise
 * downloading the source image corresponding to {@link enteFile} from remote.
 *
 * For videos their thumbnail is used.
 */
export const renderableImageBlob = async (
    enteFile: EnteFile,
    file?: File | undefined,
) => {
    const fileType = enteFile.metadata.fileType;
    if (fileType == FILE_TYPE.VIDEO) {
        const thumbnailData = await DownloadManager.getThumbnail(enteFile);
        return new Blob([ensure(thumbnailData)]);
    } else {
        return ensure(
            file
                ? await getRenderableImage(enteFile.metadata.title, file)
                : await fetchRenderableBlob(enteFile),
        );
    }
};

const fetchRenderableBlob = async (enteFile: EnteFile) => {
    const fileStream = await DownloadManager.getFile(enteFile);
    const fileBlob = await new Response(fileStream).blob();
    const fileType = enteFile.metadata.fileType;
    if (fileType == FILE_TYPE.IMAGE) {
        return getRenderableImage(enteFile.metadata.title, fileBlob);
    } else if (fileType == FILE_TYPE.LIVE_PHOTO) {
        const { imageFileName, imageData } = await decodeLivePhoto(
            enteFile.metadata.title,
            fileBlob,
        );
        return getRenderableImage(imageFileName, new Blob([imageData]));
    } else {
        // A layer above us should've already filtered these out.
        throw new Error(`Cannot index unsupported file type ${fileType}`);
    }
};
