import { FILE_TYPE } from 'constants/file';
import { EnteFile } from 'types/file';
import { MergedSourceURL } from 'types/gallery';
import { logError } from 'utils/sentry';

const WAIT_FOR_VIDEO_PLAYBACK = 1 * 1000;

export async function isPlaybackPossible(url: string): Promise<boolean> {
    return await new Promise((resolve) => {
        const t = setTimeout(() => {
            resolve(false);
        }, WAIT_FOR_VIDEO_PLAYBACK);

        const video = document.createElement('video');
        video.addEventListener('canplay', function () {
            clearTimeout(t);
            video.remove(); // Clean up the video element
            // also check for duration > 0 to make sure it is not a broken video
            if (video.duration > 0) {
                resolve(true);
            } else {
                resolve(false);
            }
        });
        video.addEventListener('error', function () {
            clearTimeout(t);
            video.remove();
            resolve(false);
        });

        video.src = url;
    });
}

export async function playVideo(livePhotoVideo, livePhotoImage) {
    const videoPlaying = !livePhotoVideo.paused;
    if (videoPlaying) return;
    livePhotoVideo.style.opacity = 1;
    livePhotoImage.style.opacity = 0;
    livePhotoVideo.load();
    livePhotoVideo.play().catch(() => {
        pauseVideo(livePhotoVideo, livePhotoImage);
    });
}

export async function pauseVideo(livePhotoVideo, livePhotoImage) {
    const videoPlaying = !livePhotoVideo.paused;
    if (!videoPlaying) return;
    livePhotoVideo.pause();
    livePhotoVideo.style.opacity = 0;
    livePhotoImage.style.opacity = 1;
}

export function updateFileMsrcProps(file: EnteFile, url: string) {
    file.msrc = url;
    file.isSourceLoaded = false;
    file.conversionFailed = false;
    file.isConverted = false;
    if (file.metadata.fileType === FILE_TYPE.IMAGE) {
        file.src = url;
    } else {
        file.html = `
            <div class = 'pswp-item-container'>
                <img src="${url}"/>
            </div>
            `;
    }
}

export async function updateFileSrcProps(
    file: EnteFile,
    mergedURL: MergedSourceURL
) {
    const urls = {
        original: mergedURL.original.split(','),
        converted: mergedURL.converted.split(','),
    };
    let originalImageURL;
    let originalVideoURL;
    let convertedImageURL;
    let convertedVideoURL;
    let originalURL;
    let isConverted;
    let conversionFailed;
    if (file.metadata.fileType === FILE_TYPE.LIVE_PHOTO) {
        [originalImageURL, originalVideoURL] = urls.original;
        [convertedImageURL, convertedVideoURL] = urls.converted;
        isConverted =
            originalVideoURL !== convertedVideoURL ||
            originalImageURL !== convertedImageURL;
        conversionFailed = !convertedVideoURL || !convertedImageURL;
    } else if (file.metadata.fileType === FILE_TYPE.VIDEO) {
        [originalVideoURL] = urls.original;
        [convertedVideoURL] = urls.converted;
        isConverted = originalVideoURL !== convertedVideoURL;
        conversionFailed = !convertedVideoURL;
    } else if (file.metadata.fileType === FILE_TYPE.IMAGE) {
        [originalImageURL] = urls.original;
        [convertedImageURL] = urls.converted;
        isConverted = originalImageURL !== convertedImageURL;
        conversionFailed = !convertedImageURL;
    } else {
        [originalURL] = urls.original;
        isConverted = false;
        conversionFailed = false;
    }

    const isPlayable = !isConverted || (isConverted && !conversionFailed);

    file.w = window.innerWidth;
    file.h = window.innerHeight;
    file.isSourceLoaded = true;
    file.originalImageURL = originalImageURL;
    file.originalVideoURL = originalVideoURL;
    file.isConverted = isConverted;
    file.conversionFailed = conversionFailed;

    if (!isPlayable) {
        return;
    }

    if (file.metadata.fileType === FILE_TYPE.VIDEO) {
        file.html = `
                <video controls onContextMenu="return false;">
                    <source src="${convertedVideoURL}" />
                    Your browser does not support the video tag.
                </video>
                `;
    } else if (file.metadata.fileType === FILE_TYPE.LIVE_PHOTO) {
        file.html = `
                <div class = 'pswp-item-container'>
                    <img id = "live-photo-image-${file.id}" src="${convertedImageURL}" onContextMenu="return false;"/>
                    <video id = "live-photo-video-${file.id}" loop muted onContextMenu="return false;">
                        <source src="${convertedVideoURL}" />
                        Your browser does not support the video tag.
                    </video>
                </div>
                `;
    } else if (file.metadata.fileType === FILE_TYPE.IMAGE) {
        file.src = convertedImageURL;
    } else {
        logError(
            Error(`unknown file type - ${file.metadata.fileType}`),
            'Unknown file type'
        );
        file.src = originalURL;
    }
}
