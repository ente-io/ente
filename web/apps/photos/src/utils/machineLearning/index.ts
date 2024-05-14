import { FILE_TYPE } from "@/media/file-type";
import { decodeLivePhoto } from "@/media/live-photo";
import log from "@/next/log";
import PQueue from "p-queue";
import DownloadManager from "services/download";
import { getLocalFiles } from "services/fileService";
import { Dimensions } from "services/ml/geom";
import { DetectedFace } from "services/ml/types";
import { EnteFile } from "types/file";
import { getRenderableImage } from "utils/file";
import { clamp } from "utils/image";

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

async function getImageBlobBitmap(blob: Blob): Promise<ImageBitmap> {
    return await createImageBitmap(blob);
}

async function getOriginalFile(file: EnteFile, queue?: PQueue) {
    let fileStream;
    if (queue) {
        fileStream = await queue.add(() => DownloadManager.getFile(file));
    } else {
        fileStream = await DownloadManager.getFile(file);
    }
    return new Response(fileStream).blob();
}

async function getOriginalConvertedFile(file: EnteFile, queue?: PQueue) {
    const fileBlob = await getOriginalFile(file, queue);
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

export async function getOriginalImageBitmap(file: EnteFile, queue?: PQueue) {
    const fileBlob = await getOriginalConvertedFile(file, queue);
    log.info("[MLService] Got file: ", file.id.toString());
    return getImageBlobBitmap(fileBlob);
}

export async function getThumbnailImageBitmap(file: EnteFile) {
    const thumb = await DownloadManager.getThumbnail(file);
    log.info("[MLService] Got thumbnail: ", file.id.toString());

    return getImageBlobBitmap(new Blob([thumb]));
}

export async function getLocalFileImageBitmap(
    enteFile: EnteFile,
    localFile: globalThis.File,
) {
    let fileBlob = localFile as Blob;
    fileBlob = await getRenderableImage(enteFile.metadata.title, fileBlob);
    return getImageBlobBitmap(fileBlob);
}
