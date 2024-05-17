import { FILE_TYPE } from "@/media/file-type";
import { decodeLivePhoto } from "@/media/live-photo";
import log from "@/next/log";
import DownloadManager from "services/download";
import { Dimensions } from "services/face/geom";
import { DetectedFace, MLSyncFileContext } from "services/face/types";
import { getLocalFiles } from "services/fileService";
import { EnteFile } from "types/file";
import { getRenderableImage } from "utils/file";
import { clamp } from "utils/image";

export const fetchImageBitmapForContext = async (
    fileContext: MLSyncFileContext,
) => {
    if (fileContext.imageBitmap) {
        return fileContext.imageBitmap;
    }
    if (fileContext.localFile) {
        if (fileContext.enteFile.metadata.fileType !== FILE_TYPE.IMAGE) {
            throw new Error("Local file of only image type is supported");
        }
        fileContext.imageBitmap = await getLocalFileImageBitmap(
            fileContext.enteFile,
            fileContext.localFile,
        );
    } else if (
        [FILE_TYPE.IMAGE, FILE_TYPE.LIVE_PHOTO].includes(
            fileContext.enteFile.metadata.fileType,
        )
    ) {
        fileContext.imageBitmap = await fetchImageBitmap(fileContext.enteFile);
    } else {
        // TODO-ML(MR): We don't do it on videos, when will we ever come
        // here?
        fileContext.imageBitmap = await getThumbnailImageBitmap(
            fileContext.enteFile,
        );
    }

    fileContext.newMlFile.imageSource = "Original";
    const { width, height } = fileContext.imageBitmap;
    fileContext.newMlFile.imageDimensions = { width, height };

    return fileContext.imageBitmap;
};

export async function getLocalFile(fileId: number) {
    const localFiles = await getLocalFiles();
    return localFiles.find((f) => f.id === fileId);
}

export function getFaceId(detectedFace: DetectedFace, imageDims: Dimensions) {
    const xMin = clamp(
        detectedFace.detection.box.x / imageDims.width,
        0.0,
        0.999999,
    )
        .toFixed(5)
        .substring(2);
    const yMin = clamp(
        detectedFace.detection.box.y / imageDims.height,
        0.0,
        0.999999,
    )
        .toFixed(5)
        .substring(2);
    const xMax = clamp(
        (detectedFace.detection.box.x + detectedFace.detection.box.width) /
            imageDims.width,
        0.0,
        0.999999,
    )
        .toFixed(5)
        .substring(2);
    const yMax = clamp(
        (detectedFace.detection.box.y + detectedFace.detection.box.height) /
            imageDims.height,
        0.0,
        0.999999,
    )
        .toFixed(5)
        .substring(2);

    const rawFaceID = `${xMin}_${yMin}_${xMax}_${yMax}`;
    const faceID = `${detectedFace.fileId}_${rawFaceID}`;

    return faceID;
}

export const fetchImageBitmap = async (file: EnteFile) =>
    fetchRenderableBlob(file).then(createImageBitmap);

async function fetchRenderableBlob(file: EnteFile) {
    const fileStream = await DownloadManager.getFile(file);
    const fileBlob = await new Response(fileStream).blob();
    if (file.metadata.fileType === FILE_TYPE.IMAGE) {
        return await getRenderableImage(file.metadata.title, fileBlob);
    } else {
        const { imageFileName, imageData } = await decodeLivePhoto(
            file.metadata.title,
            fileBlob,
        );
        return await getRenderableImage(imageFileName, new Blob([imageData]));
    }
}

export async function getThumbnailImageBitmap(file: EnteFile) {
    const thumb = await DownloadManager.getThumbnail(file);
    log.info("[MLService] Got thumbnail: ", file.id.toString());

    return createImageBitmap(new Blob([thumb]));
}

export async function getLocalFileImageBitmap(
    enteFile: EnteFile,
    localFile: globalThis.File,
) {
    let fileBlob = localFile as Blob;
    fileBlob = await getRenderableImage(enteFile.metadata.title, fileBlob);
    return createImageBitmap(fileBlob);
}
