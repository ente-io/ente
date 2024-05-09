import { ensure } from "@/utils/ensure";
import { withTimeout } from "@/utils/promise";

/** Maximum width or height of the generated thumbnail */
const maxThumbnailDimension = 720;
/** Maximum size (in bytes) of the generated thumbnail */
const maxThumbnailSize = 100 * 1024; // 100 KB

export const generateImageThumbnailUsingCanvas = async (blob: Blob) => {
    const canvas = document.createElement("canvas");
    const canvasCtx = ensure(canvas.getContext("2d"));

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
                } catch (e: unknown) {
                    // eslint-disable-next-line @typescript-eslint/prefer-promise-reject-errors
                    reject(e);
                }
            };
        }),
        30 * 1000,
    );

    return await compressedJPEGData(canvas);
};

export const generateVideoThumbnailUsingCanvas = async (blob: Blob) => {
    const canvas = document.createElement("canvas");
    const canvasCtx = ensure(canvas.getContext("2d"));

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
                    // eslint-disable-next-line @typescript-eslint/prefer-promise-reject-errors
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
    let blob: Blob | undefined | null;
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
        blob &&
        blob.size > maxThumbnailSize &&
        percentageSizeDiff(blob.size, prevSize) >= 10
    );

    return new Uint8Array(await ensure(blob).arrayBuffer());
};

const percentageSizeDiff = (
    newThumbnailSize: number,
    oldThumbnailSize: number,
) => ((oldThumbnailSize - newThumbnailSize) * 100) / oldThumbnailSize;
