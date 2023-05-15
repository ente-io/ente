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
    CollectionType,
    TRASH_SECTION,
} from 'constants/collection';
import { isSharedFile } from 'utils/file';
import { updateFileMsrcProps, updateFileSrcProps } from 'utils/photoFrame';
import { PhotoList } from './PhotoList';
import { MergedSourceURL, SelectedState } from 'types/gallery';
import PublicCollectionDownloadManager from 'services/publicCollectionDownloadManager';
import { PublicCollectionGalleryContext } from 'utils/publicCollectionGallery';
import { useRouter } from 'next/router';
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
import { isHiddenCollection } from 'utils/collection';
import { t } from 'i18next';

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
    isInSearchMode,
    search,
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
                    // only show single copy of a file
                    if (idSet.has(item.id)) {
                        return false;
                    }

                    if (
                        activeCollection === TRASH_SECTION ||
                        isDeduplicating ||
                        activeCollection === HIDDEN_SECTION ||
                        isIncomingSharedCollection
                    ) {
                        idSet.add(item.id);
                        return true;
                    }

                    // SEARCH MODE
                    if (isInSearchMode) {
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
                            search?.person &&
                            search.person.files.indexOf(item.id) === -1
                        ) {
                            return false;
                        }
                        if (
                            search?.thing &&
                            search.thing.files.indexOf(item.id) === -1
                        ) {
                            return false;
                        }
                        if (
                            search?.text &&
                            search.text.files.indexOf(item.id) === -1
                        ) {
                            return false;
                        }
                        if (
                            search?.files &&
                            search.files.indexOf(item.id) === -1
                        ) {
                            return false;
                        }
                        idSet.add(item.id);
                        return true;
                    }

                    // shared files can only be seen in their respective shared collection
                    if (isSharedFile(user, item)) {
                        if (activeCollection === item.collectionID) {
                            idSet.add(item.id);
                            return true;
                        } else {
                            return false;
                        }
                    }

                    // Archived files/collection files can only be seen in archive section or their respective collection
                    if (
                        IsArchived(item) ||
                        archivedCollections.has(item.collectionID)
                    ) {
                        if (
                            activeCollection === ARCHIVE_SECTION ||
                            activeCollection === item.collectionID
                        ) {
                            idSet.add(item.id);
                            return true;
                        } else {
                            return false;
                        }
                    }

                    // ALL SECTION - show all files
                    if (activeCollection === ALL_SECTION) {
                        idSet.add(item.id);
                        return true;
                    }

                    // COLLECTION SECTION - show files in the active collection
                    if (activeCollection === item.collectionID) {
                        idSet.add(item.id);
                        return true;
                    } else {
                        return false;
                    }
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
        search?.files,
        search?.location,
        search?.person,
        search?.thing,
        search?.text,
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
                collections.map((collection) => {
                    if (isHiddenCollection(collection)) {
                        return [collection.id, t('HIDDEN')];
                    } else if (collection.type === CollectionType.favorites) {
                        return [collection.id, t('FAVORITES')];
                    } else if (
                        collection.type === CollectionType.uncategorized
                    ) {
                        return [collection.id, t('UNCATEGORIZED')];
                    } else {
                        return [collection.id, collection.name];
                    }
                })
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
        if (file.msrc && file.msrc !== url) {
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
                    filteredData[i].ownerID === user?.id
                )(!checked);
            }
            handleSelect(
                filteredData[index].id,
                filteredData[index].ownerID === user?.id,
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
            onSelect={handleSelect(item.id, item.ownerID === user?.id, index)}
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
    );
};

export default PhotoFrame;
