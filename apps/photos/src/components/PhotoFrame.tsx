import { GalleryContext } from 'pages/gallery';
import PreviewCard from './pages/gallery/PreviewCard';
import { useContext, useEffect, useState } from 'react';
import { EnteFile } from 'types/file';
import { styled } from '@mui/material';
import DownloadManager, {
    LivePhotoSourceURL,
    SourceURLs,
} from 'services/download';
import AutoSizer from 'react-virtualized-auto-sizer';
import PhotoViewer from 'components/PhotoViewer';
import { TRASH_SECTION } from 'constants/collection';
import { updateFileMsrcProps, updateFileSrcProps } from 'utils/photoFrame';
import { SelectedState } from 'types/gallery';
import { PublicCollectionGalleryContext } from 'utils/publicCollectionGallery';
import { useRouter } from 'next/router';
import { logError } from '@ente/shared/sentry';
import { addLogLine } from '@ente/shared/logging';
import PhotoSwipe from 'photoswipe';
import useMemoSingleThreaded from '@ente/shared/hooks/useMemoSingleThreaded';
import { FILE_TYPE } from 'constants/file';
import { PHOTOS_PAGES } from '@ente/shared/constants/pages';
import { PhotoList } from './PhotoList';
import { DedupePhotoList } from './PhotoList/dedupe';
import { Duplicate } from 'services/deduplicationService';
import { CustomError } from '@ente/shared/error';

const Container = styled('div')`
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

const PHOTOSWIPE_HASH_SUFFIX = '&opened';

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
        selected: SelectedState | ((selected: SelectedState) => SelectedState)
    ) => void;
    selected: SelectedState;
    deletedFileIds?: Set<number>;
    setDeletedFileIds?: (value: Set<number>) => void;
    activeCollectionID: number;
    enableDownload?: boolean;
    fileToCollectionsMap: Map<number, number[]>;
    collectionNameMap: Map<number, string>;
    showAppDownloadBanner?: boolean;
    setIsPhotoSwipeOpen?: (value: boolean) => void;
    isInHiddenSection?: boolean;
}

const PhotoFrame = ({
    page,
    duplicates,
    files,
    syncWithRemote,
    favItemIds,
    setSelected,
    selected,
    deletedFileIds,
    setDeletedFileIds,
    activeCollectionID,
    enableDownload,
    fileToCollectionsMap,
    collectionNameMap,
    showAppDownloadBanner,
    setIsPhotoSwipeOpen,
    isInHiddenSection,
}: Props) => {
    const [open, setOpen] = useState(false);
    const [currentIndex, setCurrentIndex] = useState<number>(0);
    const [fetching, setFetching] = useState<{ [k: number]: boolean }>({});
    const [thumbFetching, setThumbFetching] = useState<{
        [k: number]: boolean;
    }>({});
    const galleryContext = useContext(GalleryContext);
    const publicCollectionGalleryContext = useContext(
        PublicCollectionGalleryContext
    );
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
        const end = currentURL.hash.lastIndexOf('&');
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
            if (e.key === 'Shift') {
                setIsShiftKeyPressed(true);
            }
        };
        const handleKeyUp = (e: KeyboardEvent) => {
            if (e.key === 'Shift') {
                setIsShiftKeyPressed(false);
            }
        };
        document.addEventListener('keydown', handleKeyDown, false);
        document.addEventListener('keyup', handleKeyUp, false);

        router.events.on('hashChangeComplete', (url: string) => {
            const start = url.indexOf('#');
            const hash = url.slice(start !== -1 ? start : url.length);
            const shouldPhotoSwipeBeOpened = hash.endsWith(
                PHOTOSWIPE_HASH_SUFFIX
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
            document.removeEventListener('keydown', handleKeyDown, false);
            document.removeEventListener('keyup', handleKeyUp, false);
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
                addLogLine(
                    `[${id}]PhotoSwipe: updateURL: file id mismatch: ${file.id} !== ${id}`
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
        forceUpdate?: boolean
    ) => {
        const file = displayFiles[index];
        // this is to prevent outdate updateSrcURL call from updating the wrong file
        if (file.id !== id) {
            addLogLine(
                `[${id}]PhotoSwipe: updateSrcURL: file id mismatch: ${file.id}`
            );
            throw Error(CustomError.UPDATE_URL_FILE_ID_MISMATCH);
        }
        if (file.isSourceLoaded && !forceUpdate) {
            throw Error(CustomError.URL_ALREADY_SET);
        } else if (file.conversionFailed) {
            addLogLine(`[${id}]PhotoSwipe: updateSrcURL: conversion failed`);
            throw Error(CustomError.FILE_CONVERSION_FAILED);
        }

        await updateFileSrcProps(file, srcURLs);
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

    const handleSelect =
        (id: number, isOwnFile: boolean, index?: number) =>
        (checked: boolean) => {
            if (typeof index !== 'undefined') {
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
    const onHoverOver = (index: number) => () => {
        setCurrentHover(index);
    };

    const handleRangeSelect = (index: number) => () => {
        if (typeof rangeStart !== 'undefined' && rangeStart !== index) {
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
                    displayFiles[i].ownerID === galleryContext.user?.id
                )(!checked);
            }
            handleSelect(
                displayFiles[index].id,
                displayFiles[index].ownerID === galleryContext.user?.id,
                index
            )(!checked);
        }
    };
    const getThumbnail = (
        item: EnteFile,
        index: number,
        isScrolling: boolean
    ) => (
        <PreviewCard
            key={`tile-${item.id}-selected-${selected[item.id] ?? false}`}
            file={item}
            updateURL={updateURL(index)}
            onClick={onThumbnailClick(index)}
            selectable={
                !publicCollectionGalleryContext?.accessedThroughSharedURL
            }
            onSelect={handleSelect(
                item.id,
                item.ownerID === galleryContext.user?.id,
                index
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
        item: EnteFile
    ) => {
        addLogLine(
            `[${
                item.id
            }] getSlideData called for thumbnail:${!!item.msrc} sourceLoaded:${
                item.isSourceLoaded
            } fetching:${fetching[item.id]}`
        );

        if (!item.msrc) {
            try {
                if (thumbFetching[item.id]) {
                    addLogLine(
                        `[${item.id}] thumb download already in progress`
                    );
                    return;
                }
                addLogLine(`[${item.id}] doesn't have thumbnail`);
                thumbFetching[item.id] = true;
                const url = await DownloadManager.getThumbnailForPreview(item);
                try {
                    updateURL(index)(item.id, url);
                    addLogLine(
                        `[${
                            item.id
                        }] calling invalidateCurrItems for thumbnail msrc :${!!item.msrc}`
                    );
                    instance.invalidateCurrItems();
                    if ((instance as any).isOpen()) {
                        instance.updateSize(true);
                    }
                } catch (e) {
                    if (e.message !== CustomError.URL_ALREADY_SET) {
                        logError(
                            e,
                            'updating photoswipe after msrc url update failed'
                        );
                    }
                    // ignore
                }
            } catch (e) {
                logError(e, 'getSlideData failed get msrc url failed');
                thumbFetching[item.id] = false;
            }
        }

        if (item.isSourceLoaded || item.conversionFailed) {
            if (item.isSourceLoaded) {
                addLogLine(`[${item.id}] source already loaded`);
            }
            if (item.conversionFailed) {
                addLogLine(`[${item.id}] conversion failed`);
            }
            return;
        }
        if (fetching[item.id]) {
            addLogLine(`[${item.id}] file download already in progress`);
            return;
        }

        try {
            addLogLine(`[${item.id}] new file src request`);
            fetching[item.id] = true;
            const srcURLs = await DownloadManager.getFileForPreview(item);
            if (item.metadata.fileType === FILE_TYPE.LIVE_PHOTO) {
                const srcImgURL = srcURLs.url as LivePhotoSourceURL;
                const imageURL = await srcImgURL.image();

                const dummyImgSrcUrl: SourceURLs = {
                    url: imageURL,
                    isOriginal: false,
                    isRenderable: !!imageURL,
                    type: 'normal',
                };
                try {
                    await updateSrcURL(index, item.id, dummyImgSrcUrl);
                    addLogLine(
                        `[${item.id}] calling invalidateCurrItems for live photo imgSrc, source loaded :${item.isSourceLoaded}`
                    );
                    instance.invalidateCurrItems();
                    if ((instance as any).isOpen()) {
                        instance.updateSize(true);
                    }
                } catch (e) {
                    if (e.message !== CustomError.URL_ALREADY_SET) {
                        logError(
                            e,
                            'updating photoswipe after for live photo imgSrc update failed'
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
                    type: 'livePhoto',
                };
                try {
                    await updateSrcURL(
                        index,
                        item.id,
                        loadedLivePhotoSrcURL,
                        true
                    );
                    addLogLine(
                        `[${item.id}] calling invalidateCurrItems for live photo complete, source loaded :${item.isSourceLoaded}`
                    );
                    instance.invalidateCurrItems();
                    if ((instance as any).isOpen()) {
                        instance.updateSize(true);
                    }
                } catch (e) {
                    if (e.message !== CustomError.URL_ALREADY_SET) {
                        logError(
                            e,
                            'updating photoswipe for live photo complete update failed'
                        );
                    }
                }
            } else {
                try {
                    await updateSrcURL(index, item.id, srcURLs);
                    addLogLine(
                        `[${item.id}] calling invalidateCurrItems for src, source loaded :${item.isSourceLoaded}`
                    );
                    instance.invalidateCurrItems();
                    if ((instance as any).isOpen()) {
                        instance.updateSize(true);
                    }
                } catch (e) {
                    if (e.message !== CustomError.URL_ALREADY_SET) {
                        logError(
                            e,
                            'updating photoswipe after src url update failed'
                        );
                    }
                }
            }
        } catch (e) {
            logError(e, 'getSlideData failed get src url failed');
            fetching[item.id] = false;
            // no-op
        }
    };

    const getConvertedItem = async (
        instance: PhotoSwipe<PhotoSwipe.Options>,
        index: number,
        item: EnteFile
    ) => {
        if (
            item.metadata.fileType !== FILE_TYPE.VIDEO &&
            item.metadata.fileType !== FILE_TYPE.LIVE_PHOTO
        ) {
            logError(
                new Error(),
                'getConvertedVideo called for non video file'
            );
            return;
        }
        if (item.conversionFailed) {
            logError(
                new Error(),
                'getConvertedVideo called for file that conversion failed'
            );
            return;
        }
        try {
            updateURL(index)(item.id, item.msrc, true);
            addLogLine(
                `[${
                    item.id
                }] calling invalidateCurrItems for thumbnail msrc :${!!item.msrc}`
            );
            instance.invalidateCurrItems();
            if ((instance as any).isOpen()) {
                instance.updateSize(true);
            }
        } catch (e) {
            if (e.message !== CustomError.URL_ALREADY_SET) {
                logError(e, 'updating photoswipe after msrc url update failed');
            }
            // ignore
        }
        try {
            addLogLine(
                `[${item.id}] new file getConvertedVideo request- ${item.metadata.title}}`
            );
            fetching[item.id] = true;

            const srcURL = await DownloadManager.getFileForPreview(item, true);

            try {
                await updateSrcURL(index, item.id, srcURL, true);
                addLogLine(
                    `[${item.id}] calling invalidateCurrItems for src, source loaded :${item.isSourceLoaded}`
                );
                instance.invalidateCurrItems();
                if ((instance as any).isOpen()) {
                    instance.updateSize(true);
                }
            } catch (e) {
                if (e.message !== CustomError.URL_ALREADY_SET) {
                    logError(
                        e,
                        'updating photoswipe after src url update failed'
                    );
                }
                throw e;
            }
        } catch (e) {
            logError(e, 'getConvertedVideo failed get src url failed');
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
                deletedFileIds={deletedFileIds}
                setDeletedFileIds={setDeletedFileIds}
                isTrashCollection={activeCollectionID === TRASH_SECTION}
                isInHiddenSection={isInHiddenSection}
                enableDownload={enableDownload}
                fileToCollectionsMap={fileToCollectionsMap}
                collectionNameMap={collectionNameMap}
            />
        </Container>
    );
};

export default PhotoFrame;
