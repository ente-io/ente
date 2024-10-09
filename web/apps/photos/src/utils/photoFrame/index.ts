import log from "@/base/log";
import { FileType } from "@/media/file-type";
import type { SelectionContext } from "@/new/photos/components/gallery";
import type { GalleryBarMode } from "@/new/photos/components/gallery/BarImpl";
import type { LivePhotoSourceURL, SourceURLs } from "@/new/photos/types/file";
import { EnteFile } from "@/new/photos/types/file";
import { ensure } from "@/utils/ensure";
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
    if (file.metadata.fileType === FileType.image) {
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
        file.metadata.fileType === FileType.livePhoto
            ? srcURLs.type === "livePhoto"
            : true;
    file.isConverted = !isOriginal;
    file.conversionFailed = !isRenderable;
    file.srcURLs = srcURLs;
    if (!isRenderable) {
        file.isSourceLoaded = true;
        return;
    }

    if (file.metadata.fileType === FileType.video) {
        file.html = `
                <video controls ${
                    !enableDownload && 'controlsList="nodownload"'
                } onContextMenu="return false;">
                    <source src="${url}" />
                    Your browser does not support the video tag.
                </video>
                `;
    } else if (file.metadata.fileType === FileType.livePhoto) {
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
    } else if (file.metadata.fileType === FileType.image) {
        file.src = url as string;
    } else {
        log.error(`unknown file type - ${file.metadata.fileType}`);
        file.src = url as string;
    }
}

export const handleSelectCreator =
    (
        setSelected: SetSelectedState,
        mode: GalleryBarMode | undefined,
        activeCollectionID: number,
        activePersonID: string | undefined,
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
            if (!mode) {
                // Retain older behavior for non-gallery call sites.
                if (selected.collectionID !== activeCollectionID) {
                    selected = {
                        ownCount: 0,
                        count: 0,
                        collectionID: 0,
                        context: undefined,
                    };
                }
            } else if (!selected.context) {
                // Gallery will specify a mode, but a fresh selection starts off
                // without a context, so fill it in with the current context.
                selected = {
                    ...selected,
                    context:
                        mode == "people"
                            ? { mode, personID: ensure(activePersonID) }
                            : {
                                  mode,
                                  collectionID: ensure(activeCollectionID),
                              },
                };
            } else {
                // Both mode and context are defined.
                if (selected.context.mode != mode) {
                    // Clear selection if mode has changed.
                    selected = {
                        ownCount: 0,
                        count: 0,
                        collectionID: 0,
                        context:
                            mode == "people"
                                ? { mode, personID: ensure(activePersonID) }
                                : {
                                      mode,
                                      collectionID: ensure(activeCollectionID),
                                  },
                    };
                } else {
                    if (selected.context?.mode == "people") {
                        if (selected.context.personID != activePersonID) {
                            // Clear selection if person has changed.
                            selected = {
                                ownCount: 0,
                                count: 0,
                                collectionID: 0,
                                context: {
                                    mode: selected.context?.mode,
                                    personID: ensure(activePersonID),
                                },
                            };
                        }
                    } else {
                        if (
                            selected.context.collectionID != activeCollectionID
                        ) {
                            // Clear selection if collection has changed.
                            selected = {
                                ownCount: 0,
                                count: 0,
                                collectionID: 0,
                                context: {
                                    mode: selected.context?.mode,
                                    collectionID: ensure(activeCollectionID),
                                },
                            };
                        }
                    }
                }
            }

            const newContext: SelectionContext | undefined = !mode
                ? undefined
                : mode == "people"
                  ? { mode, personID: ensure(activePersonID) }
                  : { mode, collectionID: ensure(activeCollectionID) };

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
                context: newContext,
                ...handleAllCounterChange(),
            };
        });
    };
