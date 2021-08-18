import { FILE_TYPE } from 'services/fileService';
import { CustomError } from 'utils/common/errorUtil';
import { convertHEIC2JPEG } from 'utils/file';
import { logError } from 'utils/sentry';

const THUMBNAIL_HEIGHT = 720;
const MAX_ATTEMPTS = 3;
const MIN_THUMBNAIL_SIZE = 50000;

const WAIT_TIME_THUMBNAIL_GENERATION = 10 * 1000;

export async function generateThumbnail(
    worker,
    file: globalThis.File,
    fileType: FILE_TYPE,
    isHEIC: boolean
): Promise<{ thumbnail: Uint8Array; hasStaticThumbnail: boolean }> {
    try {
        let hasStaticThumbnail = false;
        let canvas = document.createElement('canvas');
        try {
            if (fileType === FILE_TYPE.IMAGE) {
                canvas = await generateImageThumbnail(file, isHEIC);
            } else {
                canvas = await generateVideoThumbnail(file);
            }
        } catch (e) {
            logError(e);
            // ignore and set staticThumbnail
            hasStaticThumbnail = true;
        }
        const thumbnailBlob = await thumbnailCanvasToBlob(canvas);
        const thumbnail = await worker.getUint8ArrayView(thumbnailBlob);
        return { thumbnail, hasStaticThumbnail };
    } catch (e) {
        logError(e, 'Error generating thumbnail');
        throw e;
    }
}

export async function generateImageThumbnail(
    file: globalThis.File,
    isHEIC: boolean
) {
    const canvas = document.createElement('canvas');
    const canvasCTX = canvas.getContext('2d');

    let imageURL = null;
    let timeout = null;

    if (isHEIC) {
        file = new globalThis.File([await convertHEIC2JPEG(file)], null, null);
    }
    let image = new Image();
    imageURL = URL.createObjectURL(file);
    image.setAttribute('src', imageURL);
    await new Promise((resolve, reject) => {
        image.onload = () => {
            try {
                const thumbnailWidth =
                    (image.width * THUMBNAIL_HEIGHT) / image.height;
                canvas.width = thumbnailWidth;
                canvas.height = THUMBNAIL_HEIGHT;
                canvasCTX.drawImage(
                    image,
                    0,
                    0,
                    thumbnailWidth,
                    THUMBNAIL_HEIGHT
                );
                image = null;
                clearTimeout(timeout);
                resolve(null);
            } catch (e) {
                reject(e);
                logError(e);
                reject(
                    Error(
                        `${CustomError.THUMBNAIL_GENERATION_FAILED} err: ${e}`
                    )
                );
            }
        };
        timeout = setTimeout(
            () =>
                reject(
                    Error(
                        `wait time exceeded for format ${
                            file.name.split('.').slice(-1)[0]
                        }`
                    )
                ),
            WAIT_TIME_THUMBNAIL_GENERATION
        );
    });
    return canvas;
}

export async function generateVideoThumbnail(file: globalThis.File) {
    const canvas = document.createElement('canvas');
    const canvasCTX = canvas.getContext('2d');

    let videoURL = null;
    let timeout = null;

    await new Promise((resolve, reject) => {
        let video = document.createElement('video');
        videoURL = URL.createObjectURL(file);
        video.addEventListener('timeupdate', function () {
            try {
                if (!video) {
                    return;
                }
                const thumbnailWidth =
                    (video.videoWidth * THUMBNAIL_HEIGHT) / video.videoHeight;
                canvas.width = thumbnailWidth;
                canvas.height = THUMBNAIL_HEIGHT;
                canvasCTX.drawImage(
                    video,
                    0,
                    0,
                    thumbnailWidth,
                    THUMBNAIL_HEIGHT
                );
                video = null;
                clearTimeout(timeout);
                resolve(null);
            } catch (e) {
                const err = Error(
                    `${CustomError.THUMBNAIL_GENERATION_FAILED} err: ${e}`
                );
                logError(err);
                reject(err);
            }
        });
        video.preload = 'metadata';
        video.src = videoURL;
        video.currentTime = 3;
        timeout = setTimeout(
            () =>
                reject(
                    Error(
                        `wait time exceeded for format ${
                            file.name.split('.').slice(-1)[0]
                        }`
                    )
                ),
            WAIT_TIME_THUMBNAIL_GENERATION
        );
    });
    return canvas;
}

export async function thumbnailCanvasToBlob(canvas: HTMLCanvasElement) {
    let thumbnailBlob = null;
    let attempts = 0;
    let quality = 1;

    do {
        thumbnailBlob = await new Promise((resolve) => {
            canvas.toBlob(
                function (blob) {
                    resolve(blob);
                },
                'image/jpeg',
                quality
            );
        });
        thumbnailBlob = thumbnailBlob ?? new Blob([]);
        attempts++;
        quality /= 2;
    } while (
        thumbnailBlob.size > MIN_THUMBNAIL_SIZE &&
        attempts <= MAX_ATTEMPTS
    );

    return thumbnailBlob;
}
