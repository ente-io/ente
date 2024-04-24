import { FILE_TYPE } from "@/media/file";
import log from "@/next/log";
import { type Electron } from "@/next/types/ipc";
import { withTimeout } from "@ente/shared/utils";
import { BLACK_THUMBNAIL_BASE64 } from "constants/upload";
import * as ffmpeg from "services/ffmpeg";
import { heicToJPEG } from "services/heic-convert";
import { FileTypeInfo } from "types/upload";
import { isFileHEIC } from "utils/file";

/** Maximum width or height of the generated thumbnail */
const maxThumbnailDimension = 720;
/** Maximum size (in bytes) of the generated thumbnail */
const maxThumbnailSize = 100 * 1024; // 100 KB

/**
 * Generate a JPEG thumbnail for the given image or video blob.
 *
 * The thumbnail has a smaller file size so that is quick to load. But more
 * importantly, it uses a universal file format (JPEG in our case) so that the
 * thumbnail itself can be opened in all clients, even those like the web client
 * itself that might not yet have support for more exotic formats.
 *
 * @param blob The image or video blob whose thumbnail we want to generate.
 *
 * @param fileTypeInfo The type information for the file this blob came from.
 *
 * @return The JPEG data of the generated thumbnail.
 */
export const generateThumbnailWeb = async (
    blob: Blob,
    fileTypeInfo: FileTypeInfo,
): Promise<Uint8Array> =>
    fileTypeInfo.fileType === FILE_TYPE.IMAGE
        ? await generateImageThumbnailUsingCanvas(blob, fileTypeInfo)
        : await generateVideoThumbnailWeb(blob);

const generateImageThumbnailUsingCanvas = async (
    blob: Blob,
    fileTypeInfo: FileTypeInfo,
) => {
    if (isFileHEIC(fileTypeInfo.exactType)) {
        log.debug(() => `Pre-converting HEIC to JPEG for thumbnail generation`);
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

const generateVideoThumbnailWeb = async (blob: Blob) => {
    try {
        return await ffmpeg.generateVideoThumbnailWeb(blob);
    } catch (e) {
        log.error(
            `Failed to generate video thumbnail using the wasm FFmpeg web worker, will fallback to canvas`,
            e,
        );
        return generateVideoThumbnailUsingCanvas(blob);
    }
};

const generateVideoThumbnailUsingCanvas = async (blob: Blob) => {
    const canvas = document.createElement("canvas");
    const canvasCtx = canvas.getContext("2d");

    const videoURL = URL.createObjectURL(blob);
    await withTimeout(
        new Promise((resolve, reject) => {
            const video = document.createElement("video");
            video.preload = "metadata";
            video.src = videoURL;
            video.addEventListener("loadeddata", () => {
                try {
                    URL.revokeObjectURL(videoURL);
                    const { width, height } = scaledThumbnailDimensions(
                        video.videoWidth,
                        video.videoHeight,
                        maxThumbnailDimension,
                    );
                    canvas.width = width;
                    canvas.height = height;
                    canvasCtx.drawImage(video, 0, 0, width, height);
                    resolve(undefined);
                } catch (e) {
                    reject(e);
                }
            });
        }),
        30 * 1000,
    );

    return await compressedJPEGData(canvas);
};

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

    return new Uint8Array(await blob.arrayBuffer());
};

const percentageSizeDiff = (
    newThumbnailSize: number,
    oldThumbnailSize: number,
) => ((oldThumbnailSize - newThumbnailSize) * 100) / oldThumbnailSize;

/**
 * Generate a JPEG thumbnail for the given file or path using native tools.
 *
 * This function only works when we're running in the context of our desktop
 * app, and this dependency is enforced by the need to pass the {@link electron}
 * object which we use to perform IPC with the Node.js side of our desktop app.
 *
 * @param dataOrPath Contents of an image or video file, or the path to the
 * image or video file on the user's local filesystem, whose thumbnail we want
 * to generate.
 *
 * @param fileTypeInfo The type information for {@link dataOrPath}.
 *
 * @return The JPEG data of the generated thumbnail.
 *
 * See also {@link generateThumbnailWeb}.
 */
export const generateThumbnailNative = async (
    electron: Electron,
    dataOrPath: Uint8Array | string,
    fileTypeInfo: FileTypeInfo,
): Promise<Uint8Array> =>
    fileTypeInfo.fileType === FILE_TYPE.IMAGE
        ? await electron.generateImageThumbnail(
              dataOrPath,
              maxThumbnailDimension,
              maxThumbnailSize,
          )
        : ffmpeg.generateVideoThumbnailNative(electron, dataOrPath);

/**
 * A fallback, black, thumbnail for use in cases where thumbnail generation
 * fails.
 */
export const fallbackThumbnail = () =>
    Uint8Array.from(atob(BLACK_THUMBNAIL_BASE64), (c) => c.charCodeAt(0));
