import { ensureElectron } from "@/next/electron";
import { convertBytesToHumanReadable, getFileNameSize } from "@/next/file";
import log from "@/next/log";
import { CustomError } from "@ente/shared/error";
import { FILE_TYPE } from "constants/file";
import { BLACK_THUMBNAIL_BASE64 } from "constants/upload";
import isElectron from "is-electron";
import * as FFmpegService from "services/ffmpeg/ffmpegService";
import HeicConversionService from "services/heicConversionService";
import { ElectronFile, FileTypeInfo } from "types/upload";
import { isFileHEIC } from "utils/file";
import { getUint8ArrayView } from "../readerService";

const MAX_THUMBNAIL_DIMENSION = 720;
const MIN_COMPRESSION_PERCENTAGE_SIZE_DIFF = 10;
const MAX_THUMBNAIL_SIZE = 100 * 1024;
const MIN_QUALITY = 0.5;
const MAX_QUALITY = 0.7;

const WAIT_TIME_THUMBNAIL_GENERATION = 30 * 1000;

interface Dimension {
    width: number;
    height: number;
}

export async function generateThumbnail(
    file: File | ElectronFile,
    fileTypeInfo: FileTypeInfo,
): Promise<{ thumbnail: Uint8Array; hasStaticThumbnail: boolean }> {
    try {
        log.info(`generating thumbnail for ${getFileNameSize(file)}`);
        let hasStaticThumbnail = false;
        let thumbnail: Uint8Array;
        try {
            if (fileTypeInfo.fileType === FILE_TYPE.IMAGE) {
                thumbnail = await generateImageThumbnail(file, fileTypeInfo);
            } else {
                thumbnail = await generateVideoThumbnail(file, fileTypeInfo);
            }
            if (thumbnail.length > 1.5 * MAX_THUMBNAIL_SIZE) {
                log.error(
                    `thumbnail greater than max limit - ${JSON.stringify({
                        thumbnailSize: convertBytesToHumanReadable(
                            thumbnail.length,
                        ),
                        fileSize: convertBytesToHumanReadable(file.size),
                        fileType: fileTypeInfo.exactType,
                    })}`,
                );
            }
            if (thumbnail.length === 0) {
                throw Error("EMPTY THUMBNAIL");
            }
            log.info(
                `thumbnail successfully generated ${getFileNameSize(file)}`,
            );
        } catch (e) {
            log.error(
                `thumbnail generation failed ${getFileNameSize(file)} with format ${fileTypeInfo.exactType}`,
                e,
            );
            thumbnail = Uint8Array.from(atob(BLACK_THUMBNAIL_BASE64), (c) =>
                c.charCodeAt(0),
            );
            hasStaticThumbnail = true;
        }
        return { thumbnail, hasStaticThumbnail };
    } catch (e) {
        log.error("Error generating static thumbnail", e);
        throw e;
    }
}

async function generateImageThumbnail(
    file: File | ElectronFile,
    fileTypeInfo: FileTypeInfo,
) {
    if (isElectron()) {
        try {
            return await generateImageThumbnailInElectron(
                file,
                MAX_THUMBNAIL_DIMENSION,
                MAX_THUMBNAIL_SIZE,
            );
        } catch (e) {
            return await generateImageThumbnailUsingCanvas(file, fileTypeInfo);
        }
    } else {
        return await generateImageThumbnailUsingCanvas(file, fileTypeInfo);
    }
}

const generateImageThumbnailInElectron = async (
    inputFile: File | ElectronFile,
    maxDimension: number,
    maxSize: number,
): Promise<Uint8Array> => {
    try {
        const startTime = Date.now();
        const thumb = await ensureElectron().generateImageThumbnail(
            inputFile,
            maxDimension,
            maxSize,
        );
        log.info(
            `originalFileSize:${convertBytesToHumanReadable(
                inputFile?.size,
            )},thumbFileSize:${convertBytesToHumanReadable(
                thumb?.length,
            )},  native thumbnail generation time: ${
                Date.now() - startTime
            }ms `,
        );
        return thumb;
    } catch (e) {
        if (
            e.message !==
            CustomError.WINDOWS_NATIVE_IMAGE_PROCESSING_NOT_SUPPORTED
        ) {
            log.error("failed to generate image thumbnail natively", e);
        }
        throw e;
    }
};

export async function generateImageThumbnailUsingCanvas(
    file: File | ElectronFile,
    fileTypeInfo: FileTypeInfo,
) {
    const canvas = document.createElement("canvas");
    const canvasCTX = canvas.getContext("2d");

    let imageURL = null;
    let timeout = null;
    const isHEIC = isFileHEIC(fileTypeInfo.exactType);
    if (isHEIC) {
        log.info(`HEICConverter called for ${getFileNameSize(file)}`);
        const convertedBlob = await HeicConversionService.convert(
            new Blob([await file.arrayBuffer()]),
        );
        file = new File([convertedBlob], file.name);
        log.info(`${getFileNameSize(file)} successfully converted`);
    }
    let image = new Image();
    imageURL = URL.createObjectURL(new Blob([await file.arrayBuffer()]));
    await new Promise((resolve, reject) => {
        image.setAttribute("src", imageURL);
        image.onload = () => {
            try {
                URL.revokeObjectURL(imageURL);
                const imageDimension = {
                    width: image.width,
                    height: image.height,
                };
                const thumbnailDimension = calculateThumbnailDimension(
                    imageDimension,
                    MAX_THUMBNAIL_DIMENSION,
                );
                canvas.width = thumbnailDimension.width;
                canvas.height = thumbnailDimension.height;
                canvasCTX.drawImage(
                    image,
                    0,
                    0,
                    thumbnailDimension.width,
                    thumbnailDimension.height,
                );
                image = null;
                clearTimeout(timeout);
                resolve(null);
            } catch (e) {
                const err = new Error(CustomError.THUMBNAIL_GENERATION_FAILED, {
                    cause: e,
                });
                reject(err);
            }
        };
        timeout = setTimeout(
            () => reject(new Error("Operation timed out")),
            WAIT_TIME_THUMBNAIL_GENERATION,
        );
    });
    const thumbnailBlob = await getCompressedThumbnailBlobFromCanvas(canvas);
    return await getUint8ArrayView(thumbnailBlob);
}

async function generateVideoThumbnail(
    file: File | ElectronFile,
    fileTypeInfo: FileTypeInfo,
) {
    let thumbnail: Uint8Array;
    try {
        log.info(
            `ffmpeg generateThumbnail called for ${getFileNameSize(file)}`,
        );

        const thumbnail = await FFmpegService.generateVideoThumbnail(file);
        log.info(
            `ffmpeg thumbnail successfully generated ${getFileNameSize(file)}`,
        );
        return await getUint8ArrayView(thumbnail);
    } catch (e) {
        log.info(
            `ffmpeg thumbnail generated failed  ${getFileNameSize(
                file,
            )} error: ${e.message}`,
        );
        log.error(
            `failed to generate thumbnail using ffmpeg for format ${fileTypeInfo.exactType}`,
            e,
        );
        thumbnail = await generateVideoThumbnailUsingCanvas(file);
    }
    return thumbnail;
}

export async function generateVideoThumbnailUsingCanvas(
    file: File | ElectronFile,
) {
    const canvas = document.createElement("canvas");
    const canvasCTX = canvas.getContext("2d");

    let timeout = null;
    let videoURL = null;

    let video = document.createElement("video");
    videoURL = URL.createObjectURL(new Blob([await file.arrayBuffer()]));
    await new Promise((resolve, reject) => {
        video.preload = "metadata";
        video.src = videoURL;
        video.addEventListener("loadeddata", function () {
            try {
                URL.revokeObjectURL(videoURL);
                if (!video) {
                    throw Error("video load failed");
                }
                const videoDimension = {
                    width: video.videoWidth,
                    height: video.videoHeight,
                };
                const thumbnailDimension = calculateThumbnailDimension(
                    videoDimension,
                    MAX_THUMBNAIL_DIMENSION,
                );
                canvas.width = thumbnailDimension.width;
                canvas.height = thumbnailDimension.height;
                canvasCTX.drawImage(
                    video,
                    0,
                    0,
                    thumbnailDimension.width,
                    thumbnailDimension.height,
                );
                video = null;
                clearTimeout(timeout);
                resolve(null);
            } catch (e) {
                const err = Error(
                    `${CustomError.THUMBNAIL_GENERATION_FAILED} err: ${e}`,
                );
                log.error(CustomError.THUMBNAIL_GENERATION_FAILED, e);
                reject(err);
            }
        });
        timeout = setTimeout(
            () => reject(new Error("Operation timed out")),
            WAIT_TIME_THUMBNAIL_GENERATION,
        );
    });
    const thumbnailBlob = await getCompressedThumbnailBlobFromCanvas(canvas);
    return await getUint8ArrayView(thumbnailBlob);
}

async function getCompressedThumbnailBlobFromCanvas(canvas: HTMLCanvasElement) {
    let thumbnailBlob: Blob = null;
    let prevSize = Number.MAX_SAFE_INTEGER;
    let quality = MAX_QUALITY;

    do {
        if (thumbnailBlob) {
            prevSize = thumbnailBlob.size;
        }
        thumbnailBlob = await new Promise((resolve) => {
            canvas.toBlob(
                function (blob) {
                    resolve(blob);
                },
                "image/jpeg",
                quality,
            );
        });
        thumbnailBlob = thumbnailBlob ?? new Blob([]);
        quality -= 0.1;
    } while (
        quality >= MIN_QUALITY &&
        thumbnailBlob.size > MAX_THUMBNAIL_SIZE &&
        percentageSizeDiff(thumbnailBlob.size, prevSize) >=
            MIN_COMPRESSION_PERCENTAGE_SIZE_DIFF
    );

    return thumbnailBlob;
}

function percentageSizeDiff(
    newThumbnailSize: number,
    oldThumbnailSize: number,
) {
    return ((oldThumbnailSize - newThumbnailSize) * 100) / oldThumbnailSize;
}

// method to calculate new size of image for limiting it to maximum width and height, maintaining aspect ratio
// returns {0,0} for invalid inputs
function calculateThumbnailDimension(
    originalDimension: Dimension,
    maxDimension: number,
): Dimension {
    if (originalDimension.height === 0 || originalDimension.width === 0) {
        return { width: 0, height: 0 };
    }
    const widthScaleFactor = maxDimension / originalDimension.width;
    const heightScaleFactor = maxDimension / originalDimension.height;
    const scaleFactor = Math.min(widthScaleFactor, heightScaleFactor);
    const thumbnailDimension = {
        width: Math.round(originalDimension.width * scaleFactor),
        height: Math.round(originalDimension.height * scaleFactor),
    };
    if (thumbnailDimension.width === 0 || thumbnailDimension.height === 0) {
        return { width: 0, height: 0 };
    }
    return thumbnailDimension;
}
