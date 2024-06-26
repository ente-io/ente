import { FILE_TYPE } from "@/media/file-type";
import type { LivePhotoSourceURL, SourceURLs } from "@/new/photos/types/file";
import { EnteFile } from "@/new/photos/types/file";
import log from "@/next/log";
import { SetSelectedState } from "types/gallery";

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
    enableDownload: boolean,
) {
    const { url, isRenderable, isOriginal } = srcURLs;
    file.w = window.innerWidth;
    file.h = window.innerHeight;
    file.isSourceLoaded =
        file.metadata.fileType === FILE_TYPE.LIVE_PHOTO
            ? srcURLs.type === "livePhoto"
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
        if (srcURLs.type === "normal") {
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
        log.error(`unknown file type - ${file.metadata.fileType}`);
        file.src = url as string;
    }
}

export const handleSelectCreator =
    (
        setSelected: SetSelectedState,
        activeCollectionID: number,
        setRangeStart?,
    ) =>
    (id: number, isOwnFile: boolean, index?: number) =>
    (checked: boolean) => {
        if (typeof index !== "undefined") {
            if (checked) {
                setRangeStart(index);
            } else {
                setRangeStart(undefined);
            }
        }
        setSelected((selected) => {
            if (selected.collectionID !== activeCollectionID) {
                selected = { ownCount: 0, count: 0, collectionID: 0 };
            }

            const handleCounterChange = (count: number) => {
                if (selected[id] === checked) {
                    return count;
                }
                if (checked) {
                    return count + 1;
                } else {
                    return count - 1;
                }
            };

            const handleAllCounterChange = () => {
                if (isOwnFile) {
                    return {
                        ownCount: handleCounterChange(selected.ownCount),
                        count: handleCounterChange(selected.count),
                    };
                } else {
                    return {
                        count: handleCounterChange(selected.count),
                    };
                }
            };
            return {
                ...selected,
                [id]: checked,
                collectionID: activeCollectionID,
                ...handleAllCounterChange(),
            };
        });
    };
