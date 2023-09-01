import { FILE_TYPE } from 'constants/file';
import { t } from 'i18next';
import { EnteFile } from 'types/file';
import { MergedSourceURL } from 'types/gallery';
import { logError } from 'utils/sentry';

// Define the get_mime function
const get_mime = function (filetype) {
    let mimetype = '';
    const media_container = 'video';
    switch (filetype) {
        case 'mp4':
            mimetype = 'video/mp4; codecs="avc1.42E01E, mp4a.40.2"';
            break;
        case 'ogg':
            mimetype = 'video/ogg; codecs="theora, vorbis"';
            break;
        case 'webm':
            mimetype = 'video/webm; codecs="vp8, vorbis"';
            break;
    }
    return {
        mimetype: mimetype,
        container: media_container,
    };
};

// Check to see if the browser can render the file type
// using HTML5
const supports_media = function (mimetype, container) {
    const elem = document.createElement(container);
    if (typeof elem.canPlayType === 'function') {
        const playable = elem.canPlayType(mimetype);
        if (
            playable.toLowerCase() === 'maybe' ||
            playable.toLowerCase() === 'probably'
        ) {
            return true;
        }
    }
    return false;
};
export function isPlaybackPossible(fielName: string): boolean {
    const extension = get_mime(fielName.split('.').pop());
    return supports_media(extension.mimetype, extension.container);
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
    if (file.metadata.fileType === FILE_TYPE.VIDEO) {
        file.html = `
                <div class="pswp-item-container">
                    <img src="${url}" onContextMenu="return false;"/>
                    <div class="spinner-border text-light" role="status">
                        <span class="sr-only">Loading...</span>
                    </div>
                </div>
            `;
    } else if (file.metadata.fileType === FILE_TYPE.LIVE_PHOTO) {
        file.html = `
                <div class="pswp-item-container">
                    <img src="${url}" onContextMenu="return false;"/>
                    <div class="spinner-border text-light" role="status">
                        <span class="sr-only">Loading...</span>
                    </div>
                </div>
            `;
    } else if (file.metadata.fileType === FILE_TYPE.IMAGE) {
        file.src = url;
    } else {
        logError(
            Error(`unknown file type - ${file.metadata.fileType}`),
            'Unknown file type'
        );
        file.src = url;
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
    if (file.metadata.fileType === FILE_TYPE.LIVE_PHOTO) {
        [originalImageURL, originalVideoURL] = urls.original;
        [convertedImageURL, convertedVideoURL] = urls.converted;
    } else if (file.metadata.fileType === FILE_TYPE.VIDEO) {
        [originalVideoURL] = urls.original;
        [convertedVideoURL] = urls.converted;
    } else if (file.metadata.fileType === FILE_TYPE.IMAGE) {
        [originalImageURL] = urls.original;
        [convertedImageURL] = urls.converted;
    } else {
        [originalURL] = urls.original;
    }

    const isPlayable =
        convertedVideoURL && isPlaybackPossible(file.metadata.title);

    file.w = window.innerWidth;
    file.h = window.innerHeight;
    file.isSourceLoaded = true;
    file.originalImageURL = originalImageURL;
    file.originalVideoURL = originalVideoURL;

    if (file.metadata.fileType === FILE_TYPE.VIDEO) {
        if (isPlayable) {
            file.html = `
                <video controls onContextMenu="return false;">
                    <source src="${convertedVideoURL}" />
                    Your browser does not support the video tag.
                </video>
                `;
        } else {
            file.html = `
                <div class="pswp-item-container">
                    <img src="${file.msrc}" onContextMenu="return false;"/>
                    <div class="download-banner">
                        ${t('VIDEO_PLAYBACK_FAILED_DOWNLOAD_INSTEAD')}
                        <button class = "btn btn-outline-success" id = "download-btn-${
                            file.id
                        }">${t('DOWNLOAD')}</button>
                    </div>
                </div>
                `;
        }
    } else if (file.metadata.fileType === FILE_TYPE.LIVE_PHOTO) {
        if (isPlayable) {
            file.html = `
                <div class = 'pswp-item-container'>
                    <img id = "live-photo-image-${file.id}" src="${convertedImageURL}" onContextMenu="return false;"/>
                    <video id = "live-photo-video-${file.id}" loop muted onContextMenu="return false;">
                        <source src="${convertedVideoURL}" />
                        Your browser does not support the video tag.
                    </video>
                </div>
                `;
        } else {
            file.html = `
                <div class="pswp-item-container">
                    <img src="${file.msrc}" onContextMenu="return false;"/>
                    <div class="download-banner">
                        ${t('VIDEO_PLAYBACK_FAILED_DOWNLOAD_INSTEAD')}
                        <button class = "btn btn-outline-success" id = "download-btn-${
                            file.id
                        }">Download</button>
                    </div>
                </div>
                `;
        }
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
