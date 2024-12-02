import log from "@/base/log";
import {
    downloadManager,
    type LivePhotoSourceURL,
    type SourceURLs,
} from "@/gallery/services/download";
import { EnteFile } from "@/media/file";
import { FileType } from "@/media/file-type";
import type { GalleryBarMode } from "@/new/photos/components/gallery/reducer";
import { TRASH_SECTION } from "@/new/photos/services/collection";
import { PHOTOS_PAGES } from "@ente/shared/constants/pages";
import useMemoSingleThreaded from "@ente/shared/hooks/useMemoSingleThreaded";
import { styled } from "@mui/material";
import PhotoViewer, { type PhotoViewerProps } from "components/PhotoViewer";
import { useRouter } from "next/router";
import { GalleryContext } from "pages/gallery";
import PhotoSwipe from "photoswipe";
import { useContext, useEffect, useState } from "react";
import AutoSizer from "react-virtualized-auto-sizer";
import { Duplicate } from "services/deduplicationService";
import {
    SelectedState,
    SetFilesDownloadProgressAttributesCreator,
} from "types/gallery";
import { handleSelectCreator } from "utils/photoFrame";
import { PhotoList } from "./PhotoList";
import { DedupePhotoList } from "./PhotoList/dedupe";
import PreviewCard from "./pages/gallery/PreviewCard";

const Container = styled("div")`
    display: block;
    flex: 1;
    width: 100%;
    flex-wrap: wrap;
    margin: 0 auto;
    overflow: hidden;
    .pswp-thumbnail {
        display: inline-block;
        cursor: pointer;
    }
`;

const PHOTOSWIPE_HASH_SUFFIX = "&opened";

/**
 * An {@link EnteFile} augmented with various in-memory state used for
 * displaying it in the photo viewer.
 */
export type DisplayFile = EnteFile & {
    src?: string;
    srcURLs?: SourceURLs;
    msrc?: string;
    html?: string;
    w?: number;
    h?: number;
    title?: string;
    isSourceLoaded?: boolean;
    conversionFailed?: boolean;
    canForceConvert?: boolean;
};

export interface PhotoFrameProps {
    page:
        | PHOTOS_PAGES.GALLERY
        | PHOTOS_PAGES.DEDUPLICATE
        | PHOTOS_PAGES.SHARED_ALBUMS;
    mode?: GalleryBarMode;
    /**
     * This is an experimental prop, to see if we can merge the separate
     * "isInSearchMode" state kept by the gallery to be instead provided as a
     * another mode in which the gallery operates.
     */
    modePlus?: GalleryBarMode | "search";
    files: EnteFile[];
    duplicates?: Duplicate[];
    syncWithRemote: () => Promise<void>;
    favItemIds?: Set<number>;
    setSelected: (
        selected: SelectedState | ((selected: SelectedState) => SelectedState),
    ) => void;
    selected: SelectedState;
    markTempDeleted?: (tempDeletedFiles: EnteFile[]) => void;
    /** This will be set if mode is not "people". */
    activeCollectionID: number;
    /** This will be set if mode is "people". */
    activePersonID?: string | undefined;
    enableDownload?: boolean;
    fileToCollectionsMap: Map<number, number[]>;
    collectionNameMap: Map<number, string>;
    showAppDownloadBanner?: boolean;
    setIsPhotoSwipeOpen?: (value: boolean) => void;
    isInHiddenSection?: boolean;
    setFilesDownloadProgressAttributesCreator?: SetFilesDownloadProgressAttributesCreator;
    selectable?: boolean;
    onSelectPerson?: PhotoViewerProps["onSelectPerson"];
}

const PhotoFrame = ({
    page,
    duplicates,
    mode,
    modePlus,
    files,
    syncWithRemote,
    favItemIds,
    setSelected,
    selected,
    markTempDeleted,
    activeCollectionID,
    activePersonID,
    enableDownload,
    fileToCollectionsMap,
    collectionNameMap,
    showAppDownloadBanner,
    setIsPhotoSwipeOpen,
    isInHiddenSection,
    setFilesDownloadProgressAttributesCreator,
    selectable,
    onSelectPerson,
}: PhotoFrameProps) => {
    const [open, setOpen] = useState(false);
    const [currentIndex, setCurrentIndex] = useState<number>(0);
    const [fetching, setFetching] = useState<Record<number, boolean>>({});
    const [thumbFetching, setThumbFetching] = useState<Record<number, boolean>>(
        {},
    );
    const galleryContext = useContext(GalleryContext);
    const [rangeStart, setRangeStart] = useState(null);
    const [currentHover, setCurrentHover] = useState(null);
    const [isShiftKeyPressed, setIsShiftKeyPressed] = useState(false);
    const router = useRouter();

    const displayFiles = useMemoSingleThreaded(() => {
        return files.map((item) => {
            const filteredItem = {
                ...item,
                w: window.innerWidth,
                h: window.innerHeight,
                title: item.pubMagicMetadata?.data.caption,
            };
            return filteredItem as DisplayFile;
        });
    }, [files]);

    useEffect(() => {
        setFetching({});
        setThumbFetching({});
    }, [displayFiles]);

    useEffect(() => {
        const currentURL = new URL(window.location.href);
        const end = currentURL.hash.lastIndexOf("&");
        const hash = currentURL.hash.slice(1, end !== -1 ? end : undefined);
        if (open) {
            router.push({
                hash: hash + PHOTOSWIPE_HASH_SUFFIX,
            });
        } else {
            router.push({
                hash: hash,
            });
        }
    }, [open]);

    useEffect(() => {
        const handleKeyDown = (e: KeyboardEvent) => {
            if (e.key === "Shift") {
                setIsShiftKeyPressed(true);
            }
        };
        const handleKeyUp = (e: KeyboardEvent) => {
            if (e.key === "Shift") {
                setIsShiftKeyPressed(false);
            }
        };
        document.addEventListener("keydown", handleKeyDown, false);
        document.addEventListener("keyup", handleKeyUp, false);

        router.events.on("hashChangeComplete", (url: string) => {
            const start = url.indexOf("#");
            const hash = url.slice(start !== -1 ? start : url.length);
            const shouldPhotoSwipeBeOpened = hash.endsWith(
                PHOTOSWIPE_HASH_SUFFIX,
            );
            if (shouldPhotoSwipeBeOpened) {
                setIsPhotoSwipeOpen?.(true);
                setOpen(true);
            } else {
                setIsPhotoSwipeOpen?.(false);
                setOpen(false);
            }
        });

        return () => {
            document.removeEventListener("keydown", handleKeyDown, false);
            document.removeEventListener("keyup", handleKeyUp, false);
        };
    }, []);

    useEffect(() => {
        if (selected.count === 0) {
            setRangeStart(null);
        }
    }, [selected]);

    if (!displayFiles) {
        return <div />;
    }

    // Return a (curried) function which will return true if the URL was updated
    // (for the given params), and false otherwise.
    const updateThumbURL =
        (index: number) => (id: number, url: string, forceUpdate?: boolean) => {
            const file = displayFiles[index];
            // This is to prevent outdated call from updating the wrong file.
            if (file.id !== id) {
                log.info(
                    `Ignoring stale updateThumbURL for display file at index ${index} (file ID ${file.id}, expected ${id})`,
                );
                throw Error("Update URL file id mismatch");
            }
            if (file.msrc && !forceUpdate) {
                return false;
            }
            updateDisplayFileThumbnail(file, url);
            return true;
        };

    const handleClose = (needUpdate) => {
        setOpen(false);
        needUpdate && syncWithRemote();
        setIsPhotoSwipeOpen?.(false);
    };

    const onThumbnailClick = (index: number) => () => {
        setCurrentIndex(index);
        setOpen(true);
        setIsPhotoSwipeOpen?.(true);
    };

    const handleSelect = handleSelectCreator(
        setSelected,
        mode,
        activeCollectionID,
        activePersonID,
        setRangeStart,
    );

    const onHoverOver = (index: number) => () => {
        setCurrentHover(index);
    };

    const handleRangeSelect = (index: number) => () => {
        if (typeof rangeStart !== "undefined" && rangeStart !== index) {
            const direction =
                (index - rangeStart) / Math.abs(index - rangeStart);
            let checked = true;
            for (
                let i = rangeStart;
                (index - i) * direction >= 0;
                i += direction
            ) {
                checked = checked && !!selected[displayFiles[i].id];
            }
            for (
                let i = rangeStart;
                (index - i) * direction > 0;
                i += direction
            ) {
                handleSelect(
                    displayFiles[i].id,
                    displayFiles[i].ownerID === galleryContext.user?.id,
                )(!checked);
            }
            handleSelect(
                displayFiles[index].id,
                displayFiles[index].ownerID === galleryContext.user?.id,
                index,
            )(!checked);
        }
    };

    const getThumbnail = (
        item: DisplayFile,
        index: number,
        isScrolling: boolean,
    ) => (
        <PreviewCard
            key={`tile-${item.id}-selected-${selected[item.id] ?? false}`}
            file={item}
            updateURL={updateThumbURL(index)}
            onClick={onThumbnailClick(index)}
            selectable={selectable}
            onSelect={handleSelect(
                item.id,
                item.ownerID === galleryContext.user?.id,
                index,
            )}
            selected={
                (!mode
                    ? selected.collectionID === activeCollectionID
                    : mode == selected.context?.mode &&
                      (selected.context.mode == "people"
                          ? selected.context.personID == activePersonID
                          : selected.context.collectionID ==
                            activeCollectionID)) && selected[item.id]
            }
            selectOnClick={selected.count > 0}
            onHover={onHoverOver(index)}
            onRangeSelect={handleRangeSelect(index)}
            isRangeSelectActive={isShiftKeyPressed && selected.count > 0}
            isInsSelectRange={
                (index >= rangeStart && index <= currentHover) ||
                (index >= currentHover && index <= rangeStart)
            }
            activeCollectionID={activeCollectionID}
            showPlaceholder={isScrolling}
            isFav={favItemIds?.has(item.id)}
        />
    );

    const getSlideData = async (
        instance: PhotoSwipe<PhotoSwipe.Options>,
        index: number,
        item: DisplayFile,
    ) => {
        log.info(
            `[${item.id}] getSlideData called for thumbnail: ${!!item.msrc} sourceLoaded: ${!!item.isSourceLoaded} fetching: ${!!fetching[item.id]}`,
        );

        if (!item.msrc) {
            try {
                if (thumbFetching[item.id]) {
                    log.info(`[${item.id}] thumb download already in progress`);
                    return;
                }
                log.info(`[${item.id}] doesn't have thumbnail`);
                thumbFetching[item.id] = true;
                // URL will always be defined (unless an error is thrown) since
                // we are not passing the `cachedOnly` option.
                const url = await downloadManager.renderableThumbnailURL(item)!;
                updateThumbnail(instance, index, item, url, false);
            } catch (e) {
                log.error("getSlideData failed get msrc url failed", e);
                thumbFetching[item.id] = false;
            }
        }

        if (item.isSourceLoaded || item.conversionFailed) {
            if (item.isSourceLoaded) {
                log.info(`[${item.id}] source already loaded`);
            }
            if (item.conversionFailed) {
                log.info(`[${item.id}] conversion failed`);
            }
            return;
        }
        if (fetching[item.id]) {
            log.info(`[${item.id}] file download already in progress`);
            return;
        }

        try {
            log.info(`[${item.id}] new file src request`);
            fetching[item.id] = true;
            const srcURLs = await downloadManager.getFileForPreview(item);
            if (item.metadata.fileType === FileType.livePhoto) {
                const srcImgURL = srcURLs.url as LivePhotoSourceURL;
                const imageURL = await srcImgURL.image();

                const dummyImgSrcUrl: SourceURLs = {
                    url: imageURL,
                    type: "normal",
                };
                updateSource(instance, index, item, dummyImgSrcUrl, false);
                if (!imageURL) {
                    // no image url, no need to load video
                    return;
                }

                const videoURL = await srcImgURL.video();
                const loadedLivePhotoSrcURL: SourceURLs = {
                    url: { video: videoURL, image: imageURL },
                    type: "livePhoto",
                };
                updateSource(
                    instance,
                    index,
                    item,
                    loadedLivePhotoSrcURL,
                    true,
                );
            } else {
                updateSource(instance, index, item, srcURLs, false);
            }
        } catch (e) {
            log.error("getSlideData failed get src url failed", e);
            fetching[item.id] = false;
            // no-op
        }
    };

    const updateThumbnail = (
        instance: PhotoSwipe<PhotoSwipe.Options>,
        index: number,
        item: DisplayFile,
        url: string,
        forceUpdate?: boolean,
    ) => {
        try {
            if (updateThumbURL(index)(item.id, url, forceUpdate)) {
                log.info(
                    `[${item.id}] calling invalidateCurrItems for thumbnail msrc: ${!!item.msrc}`,
                );
                instance.invalidateCurrItems();
                if ((instance as any).isOpen()) {
                    instance.updateSize(true);
                }
            }
        } catch (e) {
            log.error("updating photoswipe after msrc url update failed", e);
            // ignore
        }
    };

    const updateSource = (
        instance: PhotoSwipe<PhotoSwipe.Options>,
        index: number,
        item: DisplayFile,
        srcURL: SourceURLs,
        overwrite: boolean,
    ) => {
        const file = displayFiles[index];
        // This is to prevent outdated call from updating the wrong file.
        if (file.id !== item.id) {
            log.info(
                `Ignoring stale updateSourceURL for display file at index ${index} (file ID ${file.id}, expected ${item.id})`,
            );
            throw new Error("Update URL file id mismatch");
        }
        if (file.isSourceLoaded && !overwrite) return;
        if (file.conversionFailed) throw new Error("File conversion failed");

        updateDisplayFileSource(file, srcURL, enableDownload);
        instance.invalidateCurrItems();
        if ((instance as any).isOpen()) {
            instance.updateSize(true);
        }
    };

    const forceConvertItem = async (
        instance: PhotoSwipe<PhotoSwipe.Options>,
        index: number,
        item: DisplayFile,
    ) => {
        updateThumbnail(instance, index, item, item.msrc, true);

        try {
            log.info(
                `[${item.id}] new file getConvertedVideo request ${item.metadata.title}}`,
            );
            fetching[item.id] = true;

            const srcURL = await downloadManager.getFileForPreview(item, {
                forceConvert: true,
            });

            updateSource(instance, index, item, srcURL, true);
        } catch (e) {
            log.error("getConvertedVideo failed get src url failed", e);
            fetching[item.id] = false;
            // no-op
        }
    };

    return (
        <Container>
            <AutoSizer>
                {({ height, width }) =>
                    page === PHOTOS_PAGES.DEDUPLICATE ? (
                        <DedupePhotoList
                            width={width}
                            height={height}
                            getThumbnail={getThumbnail}
                            duplicates={duplicates}
                            activeCollectionID={activeCollectionID}
                            showAppDownloadBanner={showAppDownloadBanner}
                        />
                    ) : (
                        <PhotoList
                            width={width}
                            height={height}
                            getThumbnail={getThumbnail}
                            mode={mode}
                            modePlus={modePlus}
                            displayFiles={displayFiles}
                            activeCollectionID={activeCollectionID}
                            activePersonID={activePersonID}
                            showAppDownloadBanner={showAppDownloadBanner}
                        />
                    )
                }
            </AutoSizer>
            <PhotoViewer
                isOpen={open}
                items={displayFiles}
                currentIndex={currentIndex}
                onClose={handleClose}
                gettingData={getSlideData}
                forceConvertItem={forceConvertItem}
                favItemIds={favItemIds}
                markTempDeleted={markTempDeleted}
                isTrashCollection={activeCollectionID === TRASH_SECTION}
                isInHiddenSection={isInHiddenSection}
                enableDownload={enableDownload}
                fileToCollectionsMap={fileToCollectionsMap}
                collectionNameMap={collectionNameMap}
                setFilesDownloadProgressAttributesCreator={
                    setFilesDownloadProgressAttributesCreator
                }
                onSelectPerson={onSelectPerson}
            />
        </Container>
    );
};

export default PhotoFrame;

const updateDisplayFileThumbnail = (file: DisplayFile, url: string) => {
    file.w = window.innerWidth;
    file.h = window.innerHeight;
    file.msrc = url;
    file.canForceConvert = false;
    file.isSourceLoaded = false;
    file.conversionFailed = false;
    if (file.metadata.fileType === FileType.image) {
        file.src = url;
    } else {
        file.html = `
            <div class = 'pswp-item-container'>
                <img src="${url}"/>
            </div>
            `;
    }
};

const updateDisplayFileSource = (
    file: DisplayFile,
    srcURLs: SourceURLs,
    enableDownload: boolean,
) => {
    const { url } = srcURLs;
    const isRenderable = !!url;
    file.w = window.innerWidth;
    file.h = window.innerHeight;
    file.isSourceLoaded =
        file.metadata.fileType === FileType.livePhoto
            ? srcURLs.type === "livePhoto"
            : true;
    file.canForceConvert = srcURLs.canForceConvert;
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
};
