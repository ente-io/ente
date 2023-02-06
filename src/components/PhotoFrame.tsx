import { GalleryContext } from 'pages/gallery';
import PreviewCard from './pages/gallery/PreviewCard';
import React, { useContext, useEffect, useRef, useState } from 'react';
import { EnteFile } from 'types/file';
import { styled } from '@mui/material';
import DownloadManager from 'services/downloadManager';
import AutoSizer from 'react-virtualized-auto-sizer';
import PhotoViewer from 'components/PhotoViewer';
import {
    ALL_SECTION,
    ARCHIVE_SECTION,
    TRASH_SECTION,
} from 'constants/collection';
import { isSharedFile } from 'utils/file';
import { updateFileMsrcProps, updateFileSrcProps } from 'utils/photoFrame';
import { PhotoList } from './PhotoList';
import { MergedSourceURL, SelectedState } from 'types/gallery';
import PublicCollectionDownloadManager from 'services/publicCollectionDownloadManager';
import { PublicCollectionGalleryContext } from 'utils/publicCollectionGallery';
import { useRouter } from 'next/router';
import EmptyScreen from './EmptyScreen';
import { AppContext } from 'pages/_app';
import { DeduplicateContext } from 'pages/deduplicate';
import { IsArchived } from 'utils/magicMetadata';
import { isSameDayAnyYear, isInsideBox } from 'utils/search';
import { Search } from 'types/search';
import { logError } from 'utils/sentry';
import { User } from 'types/user';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import { useMemo } from 'react';
import { Collection } from 'types/collection';
import { addLogLine } from 'utils/logging';
import PhotoSwipe from 'photoswipe';

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
    files: EnteFile[];
    collections?: Collection[];
    syncWithRemote: () => Promise<void>;
    favItemIds?: Set<number>;
    archivedCollections?: Set<number>;
    setSelected: (
        selected: SelectedState | ((selected: SelectedState) => SelectedState)
    ) => void;
    selected: SelectedState;
    isFirstLoad?;
    openUploader?;
    isInSearchMode?: boolean;
    search?: Search;
    deletedFileIds?: Set<number>;
    setDeletedFileIds?: (value: Set<number>) => void;
    activeCollection: number;
    isIncomingSharedCollection?: boolean;
    enableDownload?: boolean;
    isDeduplicating?: boolean;
    resetSearch?: () => void;
}

const PhotoFrame = ({
    files,
    collections,
    syncWithRemote,
    favItemIds,
    archivedCollections,
    setSelected,
    selected,
    isFirstLoad,
    openUploader,
    isInSearchMode,
    search,
    resetSearch,
    deletedFileIds,
    setDeletedFileIds,
    activeCollection,
    isIncomingSharedCollection,
    enableDownload,
    isDeduplicating,
}: Props) => {
    const [user, setUser] = useState<User>(null);
    const [open, setOpen] = useState(false);
    const [currentIndex, setCurrentIndex] = useState<number>(0);
    const [fetching, setFetching] = useState<{ [k: number]: boolean }>({});
    const galleryContext = useContext(GalleryContext);
    const appContext = useContext(AppContext);
    const deduplicateContext = useContext(DeduplicateContext);
    const publicCollectionGalleryContext = useContext(
        PublicCollectionGalleryContext
    );
    const [rangeStart, setRangeStart] = useState(null);
    const [currentHover, setCurrentHover] = useState(null);
    const [isShiftKeyPressed, setIsShiftKeyPressed] = useState(false);
    const router = useRouter();
    const [isSourceLoaded, setIsSourceLoaded] = useState(false);

    const updateInProgress = useRef(false);
    const updateRequired = useRef(false);

    const [filteredData, setFilteredData] = useState<EnteFile[]>([]);

    useEffect(() => {
        const user: User = getData(LS_KEYS.USER);
        setUser(user);
    }, []);

    useEffect(() => {
        const main = () => {
            if (updateInProgress.current) {
                updateRequired.current = true;
                return;
            }
            updateInProgress.current = true;
            const idSet = new Set();
            const user: User = getData(LS_KEYS.USER);

            const filteredData = files
                .filter((item) => {
                    if (
                        deletedFileIds?.has(item.id) &&
                        activeCollection !== TRASH_SECTION
                    ) {
                        return false;
                    }
                    if (
                        search?.date &&
                        !isSameDayAnyYear(search.date)(
                            new Date(item.metadata.creationTime / 1000)
                        )
                    ) {
                        return false;
                    }
                    if (
                        search?.location &&
                        !isInsideBox(
                            {
                                latitude: item.metadata.latitude,
                                longitude: item.metadata.longitude,
                            },
                            search.location
                        )
                    ) {
                        return false;
                    }
                    if (
                        !isDeduplicating &&
                        activeCollection === ALL_SECTION &&
                        (IsArchived(item) ||
                            archivedCollections?.has(item.collectionID))
                    ) {
                        return false;
                    }
                    if (
                        activeCollection === ARCHIVE_SECTION &&
                        !IsArchived(item)
                    ) {
                        return false;
                    }

                    if (
                        isSharedFile(user, item) &&
                        activeCollection !== item.collectionID
                    ) {
                        return false;
                    }
                    if (activeCollection === TRASH_SECTION && !item.isTrashed) {
                        return false;
                    }
                    if (activeCollection !== TRASH_SECTION && item.isTrashed) {
                        return false;
                    }
                    if (!idSet.has(item.id)) {
                        if (
                            activeCollection === ALL_SECTION ||
                            activeCollection === ARCHIVE_SECTION ||
                            activeCollection === TRASH_SECTION ||
                            activeCollection === item.collectionID ||
                            isInSearchMode
                        ) {
                            idSet.add(item.id);
                            return true;
                        }
                        return false;
                    }
                    return false;
                })
                .map((item) => {
                    const filteredItem = {
                        ...item,
                        w: window.innerWidth,
                        h: window.innerHeight,
                        title: item.pubMagicMetadata?.data.caption,
                    };
                    try {
                        if (galleryContext.thumbs.has(item.id)) {
                            updateFileMsrcProps(
                                filteredItem,
                                galleryContext.thumbs.get(item.id)
                            );
                        }
                        if (galleryContext.files.has(item.id)) {
                            updateFileSrcProps(
                                filteredItem,
                                galleryContext.files.get(item.id)
                            );
                        }
                    } catch (e) {
                        logError(e, 'PhotoFrame url prefill failed');
                    }
                    return filteredItem;
                });
            setFilteredData(filteredData);
            updateInProgress.current = false;
            if (updateRequired.current) {
                updateRequired.current = false;
                setTimeout(() => {
                    main();
                }, 0);
            }
        };
        main();
    }, [
        files,
        deletedFileIds,
        search?.date,
        search?.location,
        activeCollection,
    ]);

    useEffect(() => {
        setFetching({});
    }, [filteredData]);

    const fileToCollectionsMap = useMemo(() => {
        const fileToCollectionsMap = new Map<number, number[]>();
        files.forEach((file) => {
            if (!fileToCollectionsMap.get(file.id)) {
                fileToCollectionsMap.set(file.id, []);
            }
            fileToCollectionsMap.get(file.id).push(file.collectionID);
        });
        return fileToCollectionsMap;
    }, [files]);

    const collectionNameMap = useMemo(() => {
        if (collections) {
            return new Map<number, string>(
                collections.map((collection) => [
                    collection.id,
                    collection.name,
                ])
            );
        } else {
            return new Map();
        }
    }, [collections]);

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
                setOpen(true);
            } else {
                setOpen(false);
            }
        });

        return () => {
            document.removeEventListener('keydown', handleKeyDown, false);
            document.removeEventListener('keyup', handleKeyUp, false);
        };
    }, []);

    useEffect(() => {
        if (!isNaN(search?.file)) {
            const filteredDataIdx = filteredData.findIndex((file) => {
                return file.id === search.file;
            });
            if (!isNaN(filteredDataIdx)) {
                onThumbnailClick(filteredDataIdx)();
            }
            resetSearch();
        }
    }, [search, filteredData]);

    useEffect(() => {
        if (selected.count === 0) {
            setRangeStart(null);
        }
    }, [selected]);

    const updateURL = (index: number) => (id: number, url: string) => {
        const file = filteredData[index];
        // this is to prevent outdated updateURL call from updating the wrong file
        if (file.id !== id) {
            addLogLine(
                `PhotoSwipe: updateURL: file id mismatch: ${file.id} !== ${id}`
            );
            return;
        }
        if (file.msrc) {
            addLogLine(`PhotoSwipe: updateURL: msrc already set: ${file.msrc}`);
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
        mergedSrcURL: MergedSourceURL
    ) => {
        const file = filteredData[index];
        // this is to prevent outdate updateSrcURL call from updating the wrong file
        if (file.id !== id) {
            addLogLine(
                `PhotoSwipe: updateSrcURL: file id mismatch: ${file.id} !== ${id}`
            );
            return;
        }
        if (file.isSourceLoaded) {
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
        }
        await updateFileSrcProps(file, mergedSrcURL);
        setIsSourceLoaded(true);
    };

    const handleClose = (needUpdate) => {
        setOpen(false);
        needUpdate && syncWithRemote();
    };

    const onThumbnailClick = (index: number) => () => {
        setCurrentIndex(index);
        setOpen(true);
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
                if (selected.collectionID !== activeCollection) {
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
                    collectionID: activeCollection,
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
                checked = checked && !!selected[filteredData[i].id];
            }
            for (
                let i = rangeStart;
                (index - i) * direction > 0;
                i += direction
            ) {
                handleSelect(
                    filteredData[i].id,
                    filteredData[i].ownerID === user.id
                )(!checked);
            }
            handleSelect(
                filteredData[index].id,
                filteredData[index].ownerID === user.id,
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
            onSelect={handleSelect(item.id, item.ownerID === user.id, index)}
            selected={
                selected.collectionID === activeCollection && selected[item.id]
            }
            selectOnClick={selected.count > 0}
            onHover={onHoverOver(index)}
            onRangeSelect={handleRangeSelect(index)}
            isRangeSelectActive={isShiftKeyPressed && selected.count > 0}
            isInsSelectRange={
                (index >= rangeStart && index <= currentHover) ||
                (index >= currentHover && index <= rangeStart)
            }
            activeCollection={activeCollection}
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
            }] getSlideData called for thumbnail:${!!item.msrc} sourceLoaded:${isSourceLoaded} fetching:${
                fetching[item.id]
            }`
        );
        if (!item.msrc) {
            addLogLine(`[${item.id}] doesn't have thumbnail`);
            try {
                let url: string;
                if (galleryContext.thumbs.has(item.id)) {
                    addLogLine(
                        `[${item.id}] gallery context cache hit, using cached thumb`
                    );
                    url = galleryContext.thumbs.get(item.id);
                } else {
                    addLogLine(
                        `[${item.id}] gallery context cache miss, calling downloadManager to get thumb`
                    );
                    if (
                        publicCollectionGalleryContext.accessedThroughSharedURL
                    ) {
                        url =
                            await PublicCollectionDownloadManager.getThumbnail(
                                item,
                                publicCollectionGalleryContext.token,
                                publicCollectionGalleryContext.passwordToken
                            );
                    } else {
                        url = await DownloadManager.getThumbnail(item);
                    }
                    galleryContext.thumbs.set(item.id, url);
                }
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
        if (item.isSourceLoaded) {
            addLogLine(`[${item.id}] source already loaded`);
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
            if (galleryContext.files.has(item.id)) {
                addLogLine(
                    `[${item.id}] gallery context cache hit, using cached file`
                );
                srcURL = galleryContext.files.get(item.id);
            } else {
                addLogLine(
                    `[${item.id}] gallery context cache miss, calling downloadManager to get file`
                );
                appContext.startLoading();
                let downloadedURL;
                if (publicCollectionGalleryContext.accessedThroughSharedURL) {
                    downloadedURL =
                        await PublicCollectionDownloadManager.getFile(
                            item,
                            publicCollectionGalleryContext.token,
                            publicCollectionGalleryContext.passwordToken,
                            true
                        );
                } else {
                    downloadedURL = await DownloadManager.getFile(item, true);
                }
                appContext.finishLoading();
                const mergedURL: MergedSourceURL = {
                    original: downloadedURL.original.join(','),
                    converted: downloadedURL.converted.join(','),
                };
                galleryContext.files.set(item.id, mergedURL);
                srcURL = mergedURL;
            }
            setIsSourceLoaded(false);
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

    return (
        <>
            {!isFirstLoad &&
            files.length === 0 &&
            !isInSearchMode &&
            activeCollection === ALL_SECTION ? (
                <EmptyScreen openUploader={openUploader} />
            ) : (
                <Container>
                    <AutoSizer>
                        {({ height, width }) => (
                            <PhotoList
                                width={width}
                                height={height}
                                getThumbnail={getThumbnail}
                                filteredData={filteredData}
                                activeCollection={activeCollection}
                                showAppDownloadBanner={
                                    files.length < 30 &&
                                    !isInSearchMode &&
                                    !deduplicateContext.isOnDeduplicatePage
                                }
                            />
                        )}
                    </AutoSizer>
                    <PhotoViewer
                        isOpen={open}
                        items={filteredData}
                        currentIndex={currentIndex}
                        onClose={handleClose}
                        gettingData={getSlideData}
                        favItemIds={favItemIds}
                        deletedFileIds={deletedFileIds}
                        setDeletedFileIds={setDeletedFileIds}
                        isIncomingSharedCollection={isIncomingSharedCollection}
                        isTrashCollection={activeCollection === TRASH_SECTION}
                        enableDownload={enableDownload}
                        isSourceLoaded={isSourceLoaded}
                        fileToCollectionsMap={fileToCollectionsMap}
                        collectionNameMap={collectionNameMap}
                    />
                </Container>
            )}
        </>
    );
};

export default PhotoFrame;
