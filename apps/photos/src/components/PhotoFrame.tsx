import { GalleryContext } from 'pages/gallery';
import PreviewCard from './pages/gallery/PreviewCard';
import { useContext, useEffect, useState } from 'react';
import { EnteFile } from 'types/file';
import { styled } from '@mui/material';
import DownloadManager from 'services/download';
import AutoSizer from 'react-virtualized-auto-sizer';
import PhotoViewer from 'components/PhotoViewer';
import { TRASH_SECTION } from 'constants/collection';
import { updateFileMsrcProps, updateFileSrcProps } from 'utils/photoFrame';
import { MergedSourceURL, SelectedState } from 'types/gallery';
import { PublicCollectionGalleryContext } from 'utils/publicCollectionGallery';
import { useRouter } from 'next/router';
import { logError } from '@ente/shared/sentry';
import { addLogLine } from '@ente/shared/logging';
import PhotoSwipe from 'photoswipe';
import useMemoSingleThreaded from '@ente/shared/hooks/useMemoSingleThreaded';
import { getPlayableVideo } from 'utils/file';
import { FILE_TYPE } from 'constants/file';
import { PHOTOS_PAGES } from '@ente/shared/constants/pages';
import { PhotoList } from './PhotoList';
import { DedupePhotoList } from './PhotoList/dedupe';
import { Duplicate } from 'services/deduplicationService';

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
    const galleryContext = useContext(GalleryContext);
    const publicCollectionGalleryContext = useContext(
        PublicCollectionGalleryContext
    );
    const [rangeStart, setRangeStart] = useState(null);
    const [currentHover, setCurrentHover] = useState(null);
    const [isShiftKeyPressed, setIsShiftKeyPressed] = useState(false);
    const router = useRouter();

    const thumbsStore = publicCollectionGalleryContext?.accessedThroughSharedURL
        ? publicCollectionGalleryContext.thumbs
        : galleryContext.thumbs;

    const filesStore = publicCollectionGalleryContext?.accessedThroughSharedURL
        ? publicCollectionGalleryContext.files
        : galleryContext.files;

    const displayFiles = useMemoSingleThreaded(() => {
        return files.map((item) => {
            const filteredItem = {
                ...item,
                w: window.innerWidth,
                h: window.innerHeight,
                title: item.pubMagicMetadata?.data.caption,
            };
            try {
                if (thumbsStore.has(item.id)) {
                    updateFileMsrcProps(filteredItem, thumbsStore.get(item.id));
                }
                if (filesStore.has(item.id)) {
                    updateFileSrcProps(filteredItem, filesStore.get(item.id));
                }
            } catch (e) {
                logError(e, 'PhotoFrame url prefill failed');
            }
            return filteredItem;
        });
    }, [files]);

    useEffect(() => {
        setFetching({});
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
                    `PhotoSwipe: updateURL: file id mismatch: ${file.id} !== ${id}`
                );
                return;
            }
            if (file.msrc && file.msrc !== url && !forceUpdate) {
                addLogLine(
                    `PhotoSwipe: updateURL: msrc already set: ${file.msrc}`
                );
                logError(
                    new Error(
                        `PhotoSwipe: updateURL: msrc already set: ${file.msrc}`
                    ),
                    'PhotoSwipe: updateURL called with msrc already set'
                );
                return;
            }
            updateFileMsrcProps(file, url);
        };

    const updateSrcURL = async (
        index: number,
        id: number,
        mergedSrcURL: MergedSourceURL,
        forceUpdate?: boolean
    ) => {
        const file = displayFiles[index];
        // this is to prevent outdate updateSrcURL call from updating the wrong file
        if (file.id !== id) {
            addLogLine(
                `PhotoSwipe: updateSrcURL: file id mismatch: ${file.id} !== ${id}`
            );
            return;
        }
        if (file.isSourceLoaded && !forceUpdate) {
            addLogLine(
                `PhotoSwipe: updateSrcURL: source already loaded: ${file.id}`
            );
            logError(
                new Error(
                    `PhotoSwipe: updateSrcURL: source already loaded: ${file.id}`
                ),
                'PhotoSwipe updateSrcURL called when source already loaded'
            );
            return;
        } else if (file.conversionFailed) {
            addLogLine(
                `PhotoSwipe: updateSrcURL: conversion failed: ${file.id}`
            );
            logError(
                new Error(
                    `PhotoSwipe: updateSrcURL: conversion failed: ${file.id}`
                ),
                'PhotoSwipe updateSrcURL called when conversion failed'
            );
            return;
        }

        await updateFileSrcProps(file, mergedSrcURL);
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
            addLogLine(`[${item.id}] doesn't have thumbnail`);
            try {
                const url = await DownloadManager.getThumbnailForPreview(item);
                updateURL(index)(item.id, url);
                try {
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
                    logError(
                        e,
                        'updating photoswipe after msrc url update failed'
                    );
                    // ignore
                }
            } catch (e) {
                logError(e, 'getSlideData failed get msrc url failed');
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
            let srcURL: MergedSourceURL;
            if (filesStore.has(item.id)) {
                addLogLine(
                    `[${item.id}] gallery context cache hit, using cached file`
                );
                srcURL = filesStore.get(item.id);
            } else {
                addLogLine(
                    `[${item.id}] gallery context cache miss, calling downloadManager to get file`
                );
                const downloadedURL = await DownloadManager.getFileForPreview(
                    item
                );
                const mergedURL: MergedSourceURL = {
                    original: downloadedURL.original.join(','),
                    converted: downloadedURL.converted.join(','),
                };
                filesStore.set(item.id, mergedURL);
                srcURL = mergedURL;
            }
            await updateSrcURL(index, item.id, srcURL);

            try {
                addLogLine(
                    `[${item.id}] calling invalidateCurrItems for src, source loaded :${item.isSourceLoaded}`
                );
                instance.invalidateCurrItems();
                if ((instance as any).isOpen()) {
                    instance.updateSize(true);
                }
            } catch (e) {
                logError(e, 'updating photoswipe after src url update failed');
                throw e;
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
        updateURL(index)(item.id, item.msrc, true);
        try {
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
            logError(e, 'updating photoswipe after msrc url update failed');
            // ignore
        }
        try {
            addLogLine(
                `[${item.id}] new file getConvertedVideo request- ${item.metadata.title}}`
            );
            fetching[item.id] = true;
            if (!filesStore.has(item.id)) {
                addLogLine(
                    `[${item.id}] getConvertedVideo called for file that is not downloaded`
                );
                logError(
                    new Error(),
                    'getConvertedVideo called for file that is not downloaded'
                );
                // this should never happen, convert video button should not be visible if file is not downloaded
                return;
            }

            const srcURL = filesStore.get(item.id);
            let originalVideoURL;
            if (item.metadata.fileType === FILE_TYPE.VIDEO) {
                originalVideoURL = srcURL.original;
            } else {
                originalVideoURL = srcURL.original.split(',')[1];
            }
            const playableVideo = await getPlayableVideo(
                item.metadata.title,
                await (await fetch(originalVideoURL)).blob(),
                true
            );
            const convertedVideoURL = playableVideo
                ? URL.createObjectURL(playableVideo)
                : '';
            if (item.metadata.fileType === FILE_TYPE.VIDEO) {
                srcURL.converted = convertedVideoURL;
            } else {
                const prvConvertedImageURL = srcURL.converted.split(',')[0];
                srcURL.converted = [
                    prvConvertedImageURL,
                    convertedVideoURL,
                ].join(',');
            }

            filesStore.set(item.id, srcURL);

            await updateSrcURL(index, item.id, srcURL, true);

            try {
                addLogLine(
                    `[${item.id}] calling invalidateCurrItems for src, source loaded :${item.isSourceLoaded}`
                );
                instance.invalidateCurrItems();
                if ((instance as any).isOpen()) {
                    instance.updateSize(true);
                }
            } catch (e) {
                logError(e, 'updating photoswipe after src url update failed');
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
