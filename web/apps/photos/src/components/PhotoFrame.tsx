import { FILE_TYPE } from "@/media/file-type";
import type { LivePhotoSourceURL, SourceURLs } from "@/new/photos/types/file";
import { EnteFile } from "@/new/photos/types/file";
import log from "@/next/log";
import { PHOTOS_PAGES } from "@ente/shared/constants/pages";
import { CustomError } from "@ente/shared/error";
import useMemoSingleThreaded from "@ente/shared/hooks/useMemoSingleThreaded";
import { styled } from "@mui/material";
import PhotoViewer from "components/PhotoViewer";
import { TRASH_SECTION } from "constants/collection";
import { useRouter } from "next/router";
import { GalleryContext } from "pages/gallery";
import PhotoSwipe from "photoswipe";
import { useContext, useEffect, useState } from "react";
import AutoSizer from "react-virtualized-auto-sizer";
import { Duplicate } from "services/deduplicationService";
import DownloadManager from "services/download";
import {
    SelectedState,
    SetFilesDownloadProgressAttributesCreator,
} from "types/gallery";
import {
    handleSelectCreator,
    updateFileMsrcProps,
    updateFileSrcProps,
} from "utils/photoFrame";
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

interface Props {
    page:
        | PHOTOS_PAGES.GALLERY
        | PHOTOS_PAGES.DEDUPLICATE
        | PHOTOS_PAGES.SHARED_ALBUMS;
    files: EnteFile[];
    duplicates?: Duplicate[];
    syncWithRemote: () => Promise<void>;
    favItemIds?: Set<number>;
    setSelected: (
        selected: SelectedState | ((selected: SelectedState) => SelectedState),
    ) => void;
    selected: SelectedState;
    tempDeletedFileIds?: Set<number>;
    setTempDeletedFileIds?: (value: Set<number>) => void;
    activeCollectionID: number;
    enableDownload?: boolean;
    fileToCollectionsMap: Map<number, number[]>;
    collectionNameMap: Map<number, string>;
    showAppDownloadBanner?: boolean;
    setIsPhotoSwipeOpen?: (value: boolean) => void;
    isInHiddenSection?: boolean;
    setFilesDownloadProgressAttributesCreator?: SetFilesDownloadProgressAttributesCreator;
}

const PhotoFrame = ({
    page,
    duplicates,
    files,
    syncWithRemote,
    favItemIds,
    setSelected,
    selected,
    tempDeletedFileIds,
    setTempDeletedFileIds,
    activeCollectionID,
    enableDownload,
    fileToCollectionsMap,
    collectionNameMap,
    showAppDownloadBanner,
    setIsPhotoSwipeOpen,
    isInHiddenSection,
    setFilesDownloadProgressAttributesCreator,
}: Props) => {
    const [open, setOpen] = useState(false);
    const [currentIndex, setCurrentIndex] = useState<number>(0);
    const [fetching, setFetching] = useState<{ [k: number]: boolean }>({});
    const [thumbFetching, setThumbFetching] = useState<{
        [k: number]: boolean;
    }>({});
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
            return filteredItem;
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

    const updateURL =
        (index: number) => (id: number, url: string, forceUpdate?: boolean) => {
            const file = displayFiles[index];
            // this is to prevent outdated updateURL call from updating the wrong file
            if (file.id !== id) {
                log.info(
                    `[${id}]PhotoSwipe: updateURL: file id mismatch: ${file.id} !== ${id}`,
                );
                throw Error(CustomError.UPDATE_URL_FILE_ID_MISMATCH);
            }
            if (file.msrc && !forceUpdate) {
                throw Error(CustomError.URL_ALREADY_SET);
            }
            updateFileMsrcProps(file, url);
        };

    const updateSrcURL = async (
        index: number,
        id: number,
        srcURLs: SourceURLs,
        forceUpdate?: boolean,
    ) => {
        const file = displayFiles[index];
        // this is to prevent outdate updateSrcURL call from updating the wrong file
        if (file.id !== id) {
            log.info(
                `[${id}]PhotoSwipe: updateSrcURL: file id mismatch: ${file.id}`,
            );
            throw Error(CustomError.UPDATE_URL_FILE_ID_MISMATCH);
        }
        if (file.isSourceLoaded && !forceUpdate) {
            throw Error(CustomError.URL_ALREADY_SET);
        } else if (file.conversionFailed) {
            log.info(`[${id}]PhotoSwipe: updateSrcURL: conversion failed`);
            throw Error(CustomError.FILE_CONVERSION_FAILED);
        }

        await updateFileSrcProps(file, srcURLs, enableDownload);
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
        activeCollectionID,
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
        item: EnteFile,
        index: number,
        isScrolling: boolean,
    ) => (
        <PreviewCard
            key={`tile-${item.id}-selected-${selected[item.id] ?? false}`}
            file={item}
            updateURL={updateURL(index)}
            onClick={onThumbnailClick(index)}
            selectable={enableDownload}
            onSelect={handleSelect(
                item.id,
                item.ownerID === galleryContext.user?.id,
                index,
            )}
            selected={
                selected.collectionID === activeCollectionID &&
                selected[item.id]
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
        />
    );

    const getSlideData = async (
        instance: PhotoSwipe<PhotoSwipe.Options>,
        index: number,
        item: EnteFile,
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
                const url = await DownloadManager.getThumbnailForPreview(item);
                try {
                    updateURL(index)(item.id, url);
                    log.info(
                        `[${item.id}] calling invalidateCurrItems for thumbnail msrc: ${!!item.msrc}`,
                    );
                    instance.invalidateCurrItems();
                    if ((instance as any).isOpen()) {
                        instance.updateSize(true);
                    }
                } catch (e) {
                    if (e.message !== CustomError.URL_ALREADY_SET) {
                        log.error(
                            "updating photoswipe after msrc url update failed",
                            e,
                        );
                    }
                    // ignore
                }
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
            const srcURLs = await DownloadManager.getFileForPreview(item);
            if (item.metadata.fileType === FILE_TYPE.LIVE_PHOTO) {
                const srcImgURL = srcURLs.url as LivePhotoSourceURL;
                const imageURL = await srcImgURL.image();

                const dummyImgSrcUrl: SourceURLs = {
                    url: imageURL,
                    isOriginal: false,
                    isRenderable: !!imageURL,
                    type: "normal",
                };
                try {
                    await updateSrcURL(index, item.id, dummyImgSrcUrl);
                    log.info(
                        `[${item.id}] calling invalidateCurrItems for live photo imgSrc, source loaded: ${item.isSourceLoaded}`,
                    );
                    instance.invalidateCurrItems();
                    if ((instance as any).isOpen()) {
                        instance.updateSize(true);
                    }
                } catch (e) {
                    if (e.message !== CustomError.URL_ALREADY_SET) {
                        log.error(
                            "updating photoswipe after for live photo imgSrc update failed",
                            e,
                        );
                    }
                }
                if (!imageURL) {
                    // no image url, no need to load video
                    return;
                }

                const videoURL = await srcImgURL.video();
                const loadedLivePhotoSrcURL: SourceURLs = {
                    url: { video: videoURL, image: imageURL },
                    isOriginal: false,
                    isRenderable: !!videoURL,
                    type: "livePhoto",
                };
                try {
                    await updateSrcURL(
                        index,
                        item.id,
                        loadedLivePhotoSrcURL,
                        true,
                    );
                    log.info(
                        `[${item.id}] calling invalidateCurrItems for live photo complete, source loaded: ${item.isSourceLoaded}`,
                    );
                    instance.invalidateCurrItems();
                    if ((instance as any).isOpen()) {
                        instance.updateSize(true);
                    }
                } catch (e) {
                    if (e.message !== CustomError.URL_ALREADY_SET) {
                        log.error(
                            "updating photoswipe for live photo complete update failed",
                            e,
                        );
                    }
                }
            } else {
                try {
                    await updateSrcURL(index, item.id, srcURLs);
                    log.info(
                        `[${item.id}] calling invalidateCurrItems for src, source loaded: ${item.isSourceLoaded}`,
                    );
                    instance.invalidateCurrItems();
                    if ((instance as any).isOpen()) {
                        instance.updateSize(true);
                    }
                } catch (e) {
                    if (e.message !== CustomError.URL_ALREADY_SET) {
                        log.error(
                            "updating photoswipe after src url update failed",
                            e,
                        );
                    }
                }
            }
        } catch (e) {
            log.error("getSlideData failed get src url failed", e);
            fetching[item.id] = false;
            // no-op
        }
    };

    const getConvertedItem = async (
        instance: PhotoSwipe<PhotoSwipe.Options>,
        index: number,
        item: EnteFile,
    ) => {
        if (
            item.metadata.fileType !== FILE_TYPE.VIDEO &&
            item.metadata.fileType !== FILE_TYPE.LIVE_PHOTO
        ) {
            log.error("getConvertedVideo called for non video file");
            return;
        }
        if (item.conversionFailed) {
            log.error(
                "getConvertedVideo called for file that conversion failed",
            );
            return;
        }
        try {
            updateURL(index)(item.id, item.msrc, true);
            log.info(
                `[${item.id}] calling invalidateCurrItems for thumbnail msrc: ${!!item.msrc}`,
            );
            instance.invalidateCurrItems();
            if ((instance as any).isOpen()) {
                instance.updateSize(true);
            }
        } catch (e) {
            if (e.message !== CustomError.URL_ALREADY_SET) {
                log.error(
                    "updating photoswipe after msrc url update failed",
                    e,
                );
            }
            // ignore
        }
        try {
            log.info(
                `[${item.id}] new file getConvertedVideo request ${item.metadata.title}}`,
            );
            fetching[item.id] = true;

            const srcURL = await DownloadManager.getFileForPreview(item, true);

            try {
                await updateSrcURL(index, item.id, srcURL, true);
                log.info(
                    `[${item.id}] calling invalidateCurrItems for src, source loaded: ${item.isSourceLoaded}`,
                );
                instance.invalidateCurrItems();
                if ((instance as any).isOpen()) {
                    instance.updateSize(true);
                }
            } catch (e) {
                if (e.message !== CustomError.URL_ALREADY_SET) {
                    log.error(
                        "updating photoswipe after src url update failed",
                        e,
                    );
                }
                throw e;
            }
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
                            displayFiles={displayFiles}
                            activeCollectionID={activeCollectionID}
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
                getConvertedItem={getConvertedItem}
                favItemIds={favItemIds}
                tempDeletedFileIds={tempDeletedFileIds}
                setTempDeletedFileIds={setTempDeletedFileIds}
                isTrashCollection={activeCollectionID === TRASH_SECTION}
                isInHiddenSection={isInHiddenSection}
                enableDownload={enableDownload}
                fileToCollectionsMap={fileToCollectionsMap}
                collectionNameMap={collectionNameMap}
                setFilesDownloadProgressAttributesCreator={
                    setFilesDownloadProgressAttributesCreator
                }
            />
        </Container>
    );
};

export default PhotoFrame;
