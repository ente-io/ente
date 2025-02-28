import { useModalVisibility } from "@/base/components/utils/modal";
import { isSameDay } from "@/base/date";
import { formattedDate } from "@/base/i18n-date";
import log from "@/base/log";
import type { FileInfoProps } from "@/gallery/components/FileInfo";
import {
    downloadManager,
    type LivePhotoSourceURL,
    type LoadedLivePhotoSourceURL,
    type RenderableSourceURLs,
} from "@/gallery/services/download";
import type { Collection } from "@/media/collection";
import { EnteFile } from "@/media/file";
import { FileType } from "@/media/file-type";
import { FileViewer } from "@/new/photos/components/FileViewerComponents";
import type { GalleryBarMode } from "@/new/photos/components/gallery/reducer";
import { TRASH_SECTION } from "@/new/photos/services/collection";
import { styled } from "@mui/material";
import { PhotoViewer } from "components/PhotoViewer";
import { t } from "i18next";
import { useRouter } from "next/router";
import { GalleryContext } from "pages/gallery";
import PhotoSwipe from "photoswipe";
import { useCallback, useContext, useEffect, useMemo, useState } from "react";
import AutoSizer from "react-virtualized-auto-sizer";
import {
    addToFavorites,
    removeFromFavorites,
} from "services/collectionService";
import uploadManager from "services/upload/uploadManager";
import {
    SelectedState,
    SetFilesDownloadProgressAttributesCreator,
} from "types/gallery";
import { handleSelectCreator } from "utils/photoFrame";
import { PhotoList } from "./PhotoList";
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
    srcURLs?: RenderableSourceURLs;
    /**
     * An object URL corresponding to the image portion, if any, associated with
     * the {@link DisplayFile}.
     *
     * - For images, this will be the object URL of the renderable image itself.
     * - For live photos, this will be the object URL of the image portion of
     *   the live photo.
     * - For videos, this will not be defined.
     */
    associatedImageURL?: string | undefined;
    msrc?: string;
    html?: string;
    w?: number;
    h?: number;
    title?: string;
    isSourceLoaded?: boolean;
    conversionFailed?: boolean;
    canForceConvert?: boolean;
    /**
     * [Note: Timeline date string]
     *
     * The timeline date string is a formatted date string under which a
     * particular file should be grouped in the gallery listing. e.g. "Today",
     * "Yesterday", "Fri, 21 Feb" etc.
     *
     * All files which have the same timelineDateString will be grouped under a
     * single section in the gallery listing, prefixed by the timelineDateString
     * itself, and a checkbox to select all files on that date.
     */
    timelineDateString?: string;
};

export type PhotoFrameProps = Pick<
    FileInfoProps,
    | "fileCollectionIDs"
    | "allCollectionsNameByID"
    | "onSelectCollection"
    | "onSelectPerson"
> & {
    mode?: GalleryBarMode;
    /**
     * This is an experimental prop, to see if we can merge the separate
     * "isInSearchMode" state kept by the gallery to be instead provided as a
     * another mode in which the gallery operates.
     */
    modePlus?: GalleryBarMode | "search";
    files: EnteFile[];
    setSelected: (
        selected: SelectedState | ((selected: SelectedState) => SelectedState),
    ) => void;
    selected: SelectedState;
    /**
     * File IDs of all the files that the user has marked as a favorite.
     *
     * Not set in the context of the shared albums app.
     */
    favoriteFileIDs?: Set<number>;
    /**
     * Called when the component wants to update the in-memory, unsynced,
     * favorite status of a file.
     *
     * For more details, see {@link unsyncedFavoriteUpdates} in the gallery
     * reducer's documentation.
     *
     * Not set in the context of the shared albums app.
     */
    onMarkUnsyncedFavoriteUpdate?: (
        fileID: number,
        isFavorite: boolean,
    ) => void;
    /**
     * Called when the component wants to mark the given files as deleted in the
     * the in-memory, unsynced, state maintained by the top level gallery.
     *
     * For more details, see {@link unsyncedFavoriteUpdates} in the gallery
     * reducer's documentation.
     *
     * Not set in the context of the shared albums app.
     */
    onMarkTempDeleted?: (files: EnteFile[]) => void;
    /** This will be set if mode is not "people". */
    activeCollectionID: number;
    /** This will be set if mode is "people". */
    activePersonID?: string | undefined;
    enableDownload?: boolean;
    showAppDownloadBanner?: boolean;
    setIsPhotoSwipeOpen?: (value: boolean) => void;
    isInHiddenSection?: boolean;
    setFilesDownloadProgressAttributesCreator?: SetFilesDownloadProgressAttributesCreator;
    selectable?: boolean;
    onSyncWithRemote: () => Promise<void>;
};

/**
 * TODO: Rename me to FileListWithViewer (or Gallery?)
 */
const PhotoFrame = ({
    mode,
    modePlus,
    files,
    setSelected,
    selected,
    favoriteFileIDs,
    onMarkUnsyncedFavoriteUpdate,
    onMarkTempDeleted,
    activeCollectionID,
    activePersonID,
    enableDownload,
    fileCollectionIDs,
    allCollectionsNameByID,
    showAppDownloadBanner,
    setIsPhotoSwipeOpen,
    isInHiddenSection,
    setFilesDownloadProgressAttributesCreator,
    selectable,
    onSyncWithRemote,
    onSelectCollection,
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

    const { show: showFileViewer, props: fileViewerVisibilityProps } =
        useModalVisibility();

    const [displayFiles, setDisplayFiles] = useState<DisplayFile[] | undefined>(
        undefined,
    );

    useEffect(() => {
        const result = files.map((file) => ({
            ...file,
            w: window.innerWidth,
            h: window.innerHeight,
            title: file.pubMagicMetadata?.data.caption,
            timelineDateString: fileTimelineDateString(file),
        }));
        setDisplayFiles(result);
        setFetching({});
        setThumbFetching({});
    }, [files]);

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

    const handleTriggerSyncWithRemote = useCallback(
        () => void onSyncWithRemote(),
        [onSyncWithRemote],
    );

    const handleToggleFavorite = useMemo(() => {
        return favoriteFileIDs
            ? (file: EnteFile) => {
                  const isFavorite = favoriteFileIDs!.has(file.id);
                  return (isFavorite ? removeFromFavorites : addToFavorites)(
                      file,
                  );
              }
            : undefined;
    }, [favoriteFileIDs]);

    const handleSaveEditedImageCopy = useCallback(
        (editedFile: File, collection: Collection, enteFile: EnteFile) => {
            uploadManager.prepareForNewUpload();
            uploadManager.showUploadProgressDialog();
            uploadManager.uploadFile(editedFile, collection, enteFile);
        },
        [],
    );

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
        if (process.env.NEXT_PUBLIC_ENTE_WIP_PS5) {
            throw new Error("Not implemented");
        } else {
            setOpen(false);
            needUpdate && onSyncWithRemote();
            setIsPhotoSwipeOpen?.(false);
        }
    };

    const onThumbnailClick = (index: number) => () => {
        setCurrentIndex(index);
        if (process.env.NEXT_PUBLIC_ENTE_WIP_PS5) {
            showFileViewer();
        } else {
            setOpen(true);
            setIsPhotoSwipeOpen?.(true);
        }
    };

    const handleSelect = handleSelectCreator(
        setSelected,
        mode,
        galleryContext.user?.id,
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
                handleSelect(displayFiles[i])(!checked);
            }
            handleSelect(displayFiles[index], index)(!checked);
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
            onSelect={handleSelect(item, index)}
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
            isFav={favoriteFileIDs?.has(item.id)}
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
            const srcURLs = await downloadManager.renderableSourceURLs(item);
            if (item.metadata.fileType === FileType.livePhoto) {
                const srcImgURL = srcURLs.url as LivePhotoSourceURL;
                const imageURL = await srcImgURL.image();

                const dummyImgSrcUrl: RenderableSourceURLs = {
                    url: imageURL,
                    type: "normal",
                };
                updateSource(instance, index, item, dummyImgSrcUrl, false);
                if (!imageURL) {
                    // no image url, no need to load video
                    return;
                }

                const videoURL = await srcImgURL.video();
                const loadedLivePhotoSrcURL: RenderableSourceURLs = {
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
        srcURL: RenderableSourceURLs,
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

            const srcURL = await downloadManager.renderableSourceURLs(item, {
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
            {process.env.NEXT_PUBLIC_ENTE_WIP_PS5 && (
                <FileViewer
                    {...fileViewerVisibilityProps}
                    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
                    /* @ts-ignore TODO(PS): test */
                    user={galleryContext.user ?? undefined}
                    files={files}
                    initialIndex={currentIndex}
                    disableDownload={!enableDownload}
                    isInHiddenSection={isInHiddenSection}
                    isInTrashSection={activeCollectionID === TRASH_SECTION}
                    onTriggerSyncWithRemote={handleTriggerSyncWithRemote}
                    onToggleFavorite={handleToggleFavorite}
                    onSaveEditedImageCopy={handleSaveEditedImageCopy}
                    {...{
                        favoriteFileIDs,
                        fileCollectionIDs,
                        allCollectionsNameByID,
                        onSelectCollection,
                        onSelectPerson,
                    }}
                />
            )}
            <AutoSizer>
                {({ height, width }) => (
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
                )}
            </AutoSizer>
            <PhotoViewer
                isOpen={open}
                items={displayFiles}
                currentIndex={currentIndex}
                onClose={handleClose}
                gettingData={getSlideData}
                forceConvertItem={forceConvertItem}
                isTrashCollection={activeCollectionID === TRASH_SECTION}
                isInHiddenSection={isInHiddenSection}
                enableDownload={enableDownload}
                {...{
                    favoriteFileIDs,
                    onMarkUnsyncedFavoriteUpdate,
                    onMarkTempDeleted,
                    setFilesDownloadProgressAttributesCreator,
                    fileCollectionIDs,
                    allCollectionsNameByID,
                    onSelectCollection,
                    onSelectPerson,
                }}
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
    srcURLs: RenderableSourceURLs,
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
    file.associatedImageURL = (() => {
        switch (file.metadata.fileType) {
            case FileType.image:
                return srcURLs.url as string;
            case FileType.livePhoto:
                return (srcURLs.url as LoadedLivePhotoSourceURL).image;
            default:
                return undefined;
        }
    })();
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
                url as LoadedLivePhotoSourceURL;

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

/**
 * See: [Note: Timeline date string]
 */
const fileTimelineDateString = (item: EnteFile) => {
    const date = new Date(item.metadata.creationTime / 1000);
    return isSameDay(date, new Date())
        ? t("today")
        : isSameDay(date, new Date(Date.now() - 24 * 60 * 60 * 1000))
          ? t("yesterday")
          : formattedDate(date);
};
