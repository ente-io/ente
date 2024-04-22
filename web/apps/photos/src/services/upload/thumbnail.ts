import { fopLabel } from "@/next/file";
import log from "@/next/log";
import { ElectronFile, type DesktopFilePath } from "@/next/types/file";
import { CustomErrorMessage, type Electron } from "@/next/types/ipc";
import { CustomError } from "@ente/shared/error";
import { withTimeout } from "@ente/shared/utils";
import { FILE_TYPE } from "constants/file";
import { BLACK_THUMBNAIL_BASE64 } from "constants/upload";
import * as FFmpegService from "services/ffmpeg";
import { heicToJPEG } from "services/heic-convert";
import { FileTypeInfo } from "types/upload";
import { isFileHEIC } from "utils/file";
import { getUint8ArrayView } from "../readerService";

/** Maximum width or height of the generated thumbnail */
const maxThumbnailDimension = 720;
/** Maximum size (in bytes) of the generated thumbnail */
const maxThumbnailSize = 100 * 1024; // 100 KB

const WAIT_TIME_THUMBNAIL_GENERATION = 30 * 1000;

class ModuleState {
    /**
     * This will be set to true if we get an error from the Node.js side of our
     * desktop app telling us that native JPEG conversion is not available for
     * the current OS/arch combination. That way, we can stop pestering it again
     * and again (saving an IPC round-trip).
     *
     * Note the double negative when it is used.
     */
    isNativeThumbnailCreationNotAvailable = false;
}

const moduleState = new ModuleState();

interface GeneratedThumbnail {
    /** The JPEG data of the generated thumbnail */
    thumbnail: Uint8Array;
    /**
     * `true` if this is a fallback (all black) thumbnail we're returning since
     * thumbnail generation failed for some reason.
     */
    hasStaticThumbnail: boolean;
}

/**
 * Generate a JPEG thumbnail for the given image or video data.
 *
 * The thumbnail has a smaller file size so that is quick to load. But more
 * importantly, it uses a universal file format (JPEG in our case) so that the
 * thumbnail itself can be opened in all clients, even those like the web client
 * itself that might not yet have support for more exotic formats.
 *
 * @param blob The data (blob) of the file whose thumbnail we want to generate.
 * @param fileTypeInfo The type of the file whose {@link blob} we were given.
 *
 * @return {@link GeneratedThumbnail}, a thin wrapper for the raw JPEG bytes of
 * the generated thumbnail.
 */
export const generateThumbnail = async (
    blob: Blob,
    fileTypeInfo: FileTypeInfo,
): Promise<GeneratedThumbnail> => {
    try {
        const thumbnail =
            fileTypeInfo.fileType === FILE_TYPE.IMAGE
                ? await generateImageThumbnail(blob, fileTypeInfo)
                : await generateVideoThumbnail(blob, fileTypeInfo);

        if (thumbnail.length == 0) throw new Error("Empty thumbnail");
        return { thumbnail, hasStaticThumbnail: false };
    } catch (e) {
        log.error(
            `Failed to generate thumbnail for format ${fileTypeInfo.exactType}`,
            e,
        );
        return { thumbnail: fallbackThumbnail(), hasStaticThumbnail: true };
    }
};

/**
 * A fallback, black, thumbnail for use in cases where thumbnail generation
 * fails.
 */
const fallbackThumbnail = () =>
    Uint8Array.from(atob(BLACK_THUMBNAIL_BASE64), (c) => c.charCodeAt(0));

const generateImageThumbnail = async (
    blob: Blob,
    fileTypeInfo: FileTypeInfo,
) => {
    let jpegData: Uint8Array | undefined;

    const electron = globalThis.electron;
    const available = !moduleState.isNativeThumbnailCreationNotAvailable;
    if (electron && available) {
        // If we're running in our desktop app, try to make the thumbnail using
        // the native tools available there-in, it'll be faster than doing it on
        // the web layer.
        try {
            jpegData = await generateImageThumbnailInElectron(electron, file);
        } catch (e) {
            if (e.message == CustomErrorMessage.NotAvailable) {
                moduleState.isNativeThumbnailCreationNotAvailable = true;
            } else {
                log.error("Native thumbnail creation failed", e);
            }
        }
    }

    if (!jpegData) {
        jpegData = await generateImageThumbnailUsingCanvas(blob, fileTypeInfo);
    }
    return jpegData;
};

const generateImageThumbnailInElectron = async (
    electron: Electron,
    inputFile: File | ElectronFile,
): Promise<Uint8Array> => {
    const startTime = Date.now();
    const jpegData = await electron.generateImageThumbnail(
        inputFile,
        maxThumbnailDimension,
        maxThumbnailSize,
    );
    log.debug(
        () => `Native thumbnail generation took ${Date.now() - startTime} ms`,
    );
    return jpegData;
};

const generateImageThumbnailUsingCanvas = async (
    blob: Blob,
    fileTypeInfo: FileTypeInfo,
) => {
    if (isFileHEIC(fileTypeInfo.exactType)) {
        log.debug(() => `Pre-converting ${fileTypeInfo.exactType} to JPEG`);
        blob = await heicToJPEG(blob);
    }

    const canvas = document.createElement("canvas");
    const canvasCtx = canvas.getContext("2d");

    const imageURL = URL.createObjectURL(blob);
    await withTimeout(
        new Promise((resolve, reject) => {
            const image = new Image();
            image.setAttribute("src", imageURL);
            image.onload = () => {
                try {
                    URL.revokeObjectURL(imageURL);
                    const { width, height } = scaledThumbnailDimensions(
                        image.width,
                        image.height,
                        maxThumbnailDimension,
                    );
                    canvas.width = width;
                    canvas.height = height;
                    canvasCtx.drawImage(image, 0, 0, width, height);
                    resolve(undefined);
                } catch (e) {
                    reject(e);
                }
            };
        }),
        30 * 1000,
    );

    return await compressedJPEGData(canvas);
};

const generateVideoThumbnail = async (fileOrPath: File | DesktopFilePath) => {
    try {
        return await FFmpegService.generateVideoThumbnail(fileOrPath);
    } catch (e) {
        log.error(
            `Failed to generate thumbnail using FFmpeg for ${fopLabel(fileOrPath)}`,
            e,
        );
        // If we're on the web, try falling back to using the canvas instead.
        if (fileOrPath instanceof File) {
            log.info();
        }

        return await generateVideoThumbnailUsingCanvas(file);
    }
    return thumbnail;
};

async function generateVideoThumbnailUsingCanvas(file: File | ElectronFile) {
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
                const { width, height } = scaledThumbnailDimensions(
                    video.videoWidth,
                    video.videoHeight,
                    maxThumbnailDimension,
                );
                canvas.width = width;
                canvas.height = height;
                canvasCTX.drawImage(video, 0, 0, width, height);
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

const compressedJPEGData = async (canvas: HTMLCanvasElement) => {
    let blob: Blob;
    let prevSize = Number.MAX_SAFE_INTEGER;
    let quality = 0.7;

    do {
        if (blob) prevSize = blob.size;
        blob = await new Promise((resolve) => {
            canvas.toBlob((blob) => resolve(blob), "image/jpeg", quality);
        });
        quality -= 0.1;
    } while (
        quality >= 0.5 &&
        blob.size > maxThumbnailSize &&
        percentageSizeDiff(blob.size, prevSize) >= 10
    );

    return blob;
};

const percentageSizeDiff = (
    newThumbnailSize: number,
    oldThumbnailSize: number,
) => ((oldThumbnailSize - newThumbnailSize) * 100) / oldThumbnailSize;

/**
 * Compute the size of the thumbnail to create for an image with the given
 * {@link width} and {@link height}.
 *
 * This function calculates a new size of an image for limiting it to maximum
 * width and height (both specified by {@link maxDimension}), while maintaining
 * aspect ratio.
 *
 * It returns `{0, 0}` for invalid inputs.
 */
const scaledThumbnailDimensions = (
    width: number,
    height: number,
    maxDimension: number,
): { width: number; height: number } => {
    if (width === 0 || height === 0) return { width: 0, height: 0 };
    const widthScaleFactor = maxDimension / width;
    const heightScaleFactor = maxDimension / height;
    const scaleFactor = Math.min(widthScaleFactor, heightScaleFactor);
    const thumbnailDimensions = {
        width: Math.round(width * scaleFactor),
        height: Math.round(height * scaleFactor),
    };
    if (thumbnailDimensions.width === 0 || thumbnailDimensions.height === 0)
        return { width: 0, height: 0 };
    return thumbnailDimensions;
};
