import { FILE_TYPE } from 'constants/file';
import { EnteFile } from 'types/file';
import { logError } from '@ente/shared/sentry';
import { LivePhotoSourceURL, SourceURLs } from 'services/download';

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
    file.w = window.innerWidth;
    file.h = window.innerHeight;
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
    srcURLs: SourceURLs,
    enableDownload: boolean
) {
    const { url, isRenderable, isOriginal } = srcURLs;
    file.w = window.innerWidth;
    file.h = window.innerHeight;
    file.isSourceLoaded =
        file.metadata.fileType === FILE_TYPE.LIVE_PHOTO
            ? srcURLs.type === 'livePhoto'
            : true;
    file.isConverted = !isOriginal;
    file.conversionFailed = !isRenderable;
    file.srcURLs = srcURLs;
    if (!isRenderable) {
        file.isSourceLoaded = true;
        return;
    }

    if (file.metadata.fileType === FILE_TYPE.VIDEO) {
        file.html = `
                <video controls ${
                    !enableDownload && 'controlsList="nodownload"'
                } onContextMenu="return false;">
                    <source src="${url}" />
                    Your browser does not support the video tag.
                </video>
                `;
    } else if (file.metadata.fileType === FILE_TYPE.LIVE_PHOTO) {
        if (srcURLs.type === 'normal') {
            file.html = `
                <div class = 'pswp-item-container'>
                    <img id = "live-photo-image-${file.id}" src="${url}" onContextMenu="return false;"/>
                </div>
                `;
        } else {
            const { image: imageURL, video: videoURL } =
                url as LivePhotoSourceURL;

            file.html = `
            <div class = 'pswp-item-container'>
                <img id = "live-photo-image-${file.id}" src="${imageURL}" onContextMenu="return false;"/>
                <video id = "live-photo-video-${file.id}" loop muted onContextMenu="return false;">
                    <source src="${videoURL}" />
                    Your browser does not support the video tag.
                </video>
            </div>
            `;
        }
    } else if (file.metadata.fileType === FILE_TYPE.IMAGE) {
        file.src = url as string;
    } else {
        logError(
            Error(`unknown file type - ${file.metadata.fileType}`),
            'Unknown file type'
        );
        file.src = url as string;
    }
}
