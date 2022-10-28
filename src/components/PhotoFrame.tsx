import { GalleryContext } from 'pages/gallery';
import PreviewCard from './pages/gallery/PreviewCard';
import React, { useContext, useEffect, useState } from 'react';
import { EnteFile } from 'types/file';
import { styled } from '@mui/material';
import DownloadManager from 'services/downloadManager';
import constants from 'utils/strings/constants';
import AutoSizer from 'react-virtualized-auto-sizer';
import PhotoViewer from 'components/PhotoViewer';
import {
    ALL_SECTION,
    ARCHIVE_SECTION,
    TRASH_SECTION,
} from 'constants/collection';
import { isSharedFile } from 'utils/file';
import { isPlaybackPossible } from 'utils/photoFrame';
import { PhotoList } from './PhotoList';
import { SelectedState } from 'types/gallery';
import { FILE_TYPE } from 'constants/file';
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
import { CustomError } from 'utils/error';
import { User } from 'types/user';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import { useMemo } from 'react';

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
    isSharedCollection?: boolean;
    enableDownload?: boolean;
    isDeduplicating?: boolean;
    resetSearch?: () => void;
}

type SourceURL = {
    imageURL?: string;
    videoURL?: string;
};

const PhotoFrame = ({
    files,
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
    isSharedCollection,
    enableDownload,
    isDeduplicating,
}: Props) => {
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

    const filteredData = useMemo(() => {
        const idSet = new Set();
        const user: User = getData(LS_KEYS.USER);

        return files
            .map((item, index) => ({
                ...item,
                dataIndex: index,
                w: window.innerWidth,
                h: window.innerHeight,
            }))
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
                if (activeCollection === ARCHIVE_SECTION && !IsArchived(item)) {
                    return false;
                }

                if (isSharedFile(user, item) && !isSharedCollection) {
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
                        activeCollection === item.collectionID
                    ) {
                        idSet.add(item.id);
                        return true;
                    }
                    return false;
                }
                return false;
            });
    }, [files, deletedFileIds, search, activeCollection]);

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
            document.addEventListener('keydown', handleKeyDown, false);
            document.addEventListener('keyup', handleKeyUp, false);
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

    const resetFetching = () => {
        setFetching({});
    };

    useEffect(() => {
        if (selected.count === 0) {
            setRangeStart(null);
        }
    }, [selected]);

    const getFileIndexFromID = (files: EnteFile[], id: number) => {
        const index = files.findIndex((file) => file.id === id);
        if (index === -1) {
            throw CustomError.FILE_ID_NOT_FOUND;
        }
        return index;
    };

    const updateURL = (id: number) => (url: string) => {
        const updateFile = (file: EnteFile) => {
            file.msrc = url;
            file.w = window.innerWidth;
            file.h = window.innerHeight;

            if (file.metadata.fileType === FILE_TYPE.VIDEO && !file.html) {
                file.html = `
                <div class="pswp-item-container">
                    <img src="${url}" onContextMenu="return false;"/>
                    <div class="spinner-border text-light" role="status">
                        <span class="sr-only">Loading...</span>
                    </div>
                </div>
            `;
            } else if (
                file.metadata.fileType === FILE_TYPE.LIVE_PHOTO &&
                !file.html
            ) {
                file.html = `
                <div class="pswp-item-container">
                    <img src="${url}" onContextMenu="return false;"/>
                    <div class="spinner-border text-light" role="status">
                        <span class="sr-only">Loading...</span>
                    </div>
                </div>
            `;
            } else if (
                file.metadata.fileType === FILE_TYPE.IMAGE &&
                !file.src
            ) {
                file.src = url;
            }
            return file;
        };
        const index = getFileIndexFromID(files, id);
        return updateFile(files[index]);
    };

    const updateSrcURL = async (id: number, srcURL: SourceURL) => {
        const { videoURL, imageURL } = srcURL;
        const isPlayable = videoURL && (await isPlaybackPossible(videoURL));
        const updateFile = (file: EnteFile) => {
            file.w = window.innerWidth;
            file.h = window.innerHeight;

            if (file.metadata.fileType === FILE_TYPE.VIDEO) {
                if (isPlayable) {
                    file.html = `
            <video controls onContextMenu="return false;">
                <source src="${videoURL}" />
                Your browser does not support the video tag.
            </video>
        `;
                } else {
                    file.html = `
            <div class="pswp-item-container">
                <img src="${file.msrc}" onContextMenu="return false;"/>
                <div class="download-banner" >
                    ${constants.VIDEO_PLAYBACK_FAILED_DOWNLOAD_INSTEAD}
                    <a class="btn btn-outline-success" href=${videoURL} download="${file.metadata.title}"">Download</a>
                </div>
            </div>
            `;
                }
            } else if (file.metadata.fileType === FILE_TYPE.LIVE_PHOTO) {
                if (isPlayable) {
                    file.html = `
                <div class = 'pswp-item-container'>
                    <img id = "live-photo-image-${file.id}" src="${imageURL}" onContextMenu="return false;"/>
                    <video id = "live-photo-video-${file.id}" loop muted onContextMenu="return false;">
                        <source src="${videoURL}" />
                        Your browser does not support the video tag.
                    </video>
                </div>
                `;
                } else {
                    file.html = `
                <div class="pswp-item-container">
                    <img src="${file.msrc}" onContextMenu="return false;"/>
                    <div class="download-banner">
                        ${constants.VIDEO_PLAYBACK_FAILED_DOWNLOAD_INSTEAD}
                        <button class = "btn btn-outline-success" id = "download-btn-${file.id}">Download</button>
                    </div>
                </div>
                `;
                }
            } else {
                file.src = imageURL;
            }
            return file;
        };
        setIsSourceLoaded(true);
        const index = getFileIndexFromID(files, id);
        return updateFile(files[index]);
    };

    const handleClose = (needUpdate) => {
        setOpen(false);
        needUpdate && syncWithRemote();
    };

    const onThumbnailClick = (index: number) => () => {
        setCurrentIndex(index);
        setOpen(true);
    };

    const handleSelect = (id: number, index?: number) => (checked: boolean) => {
        if (selected.collectionID !== activeCollection) {
            setSelected({ count: 0, collectionID: 0 });
        }
        if (typeof index !== 'undefined') {
            if (checked) {
                setRangeStart(index);
            } else {
                setRangeStart(undefined);
            }
        }

        setSelected((selected) => ({
            ...selected,
            [id]: checked,
            count:
                selected[id] === checked
                    ? selected.count
                    : checked
                    ? selected.count + 1
                    : selected.count - 1,
            collectionID: activeCollection,
        }));
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
                handleSelect(filteredData[i].id)(!checked);
            }
            handleSelect(filteredData[index].id, index)(!checked);
        }
    };
    const getThumbnail = (
        files: EnteFile[],
        index: number,
        isScrolling: boolean
    ) =>
        files[index] ? (
            <PreviewCard
                key={`tile-${files[index].id}-selected-${
                    selected[files[index].id] ?? false
                }`}
                file={files[index]}
                updateURL={updateURL(files[index].id)}
                onClick={onThumbnailClick(index)}
                selectable={!isSharedCollection}
                onSelect={handleSelect(files[index].id, index)}
                selected={
                    selected.collectionID === activeCollection &&
                    selected[files[index].id]
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
        ) : (
            <></>
        );

    const getSlideData = async (
        instance: any,
        index: number,
        item: EnteFile
    ) => {
        if (!item.msrc) {
            try {
                let url: string;
                if (galleryContext.thumbs.has(item.id)) {
                    url = galleryContext.thumbs.get(item.id);
                } else {
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
                const newFile = updateURL(item.id)(url);
                item.msrc = newFile.msrc;
                item.html = newFile.html;
                item.src = newFile.src;
                item.w = newFile.w;
                item.h = newFile.h;

                try {
                    instance.invalidateCurrItems();
                    if (instance.isOpen()) {
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
        if (!fetching[item.id]) {
            try {
                fetching[item.id] = true;
                let urls: string[];
                if (galleryContext.files.has(item.id)) {
                    const mergedURL = galleryContext.files.get(item.id);
                    urls = mergedURL.split(',');
                } else {
                    appContext.startLoading();
                    if (
                        publicCollectionGalleryContext.accessedThroughSharedURL
                    ) {
                        urls = await PublicCollectionDownloadManager.getFile(
                            item,
                            publicCollectionGalleryContext.token,
                            publicCollectionGalleryContext.passwordToken,
                            true
                        );
                    } else {
                        urls = await DownloadManager.getFile(item, true);
                    }
                    appContext.finishLoading();
                    const mergedURL = urls.join(',');
                    galleryContext.files.set(item.id, mergedURL);
                }
                let imageURL;
                let videoURL;
                if (item.metadata.fileType === FILE_TYPE.LIVE_PHOTO) {
                    [imageURL, videoURL] = urls;
                } else if (item.metadata.fileType === FILE_TYPE.VIDEO) {
                    [videoURL] = urls;
                } else {
                    [imageURL] = urls;
                }
                setIsSourceLoaded(false);
                const newFile = await updateSrcURL(item.id, {
                    imageURL,
                    videoURL,
                });
                item.msrc = newFile.msrc;
                item.html = newFile.html;
                item.src = newFile.src;
                item.w = newFile.w;
                item.h = newFile.h;
                try {
                    instance.invalidateCurrItems();
                    if (instance.isOpen()) {
                        instance.updateSize(true);
                    }
                } catch (e) {
                    logError(
                        e,
                        'updating photoswipe after src url update failed'
                    );
                    // ignore
                }
            } catch (e) {
                logError(e, 'getSlideData failed get src url failed');
                // no-op
            } finally {
                fetching[item.id] = false;
            }
        }
    };

    return (
        <>
            {!isFirstLoad && files.length === 0 && !isInSearchMode ? (
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
                                resetFetching={resetFetching}
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
                        isSharedCollection={isSharedCollection}
                        isTrashCollection={activeCollection === TRASH_SECTION}
                        enableDownload={enableDownload}
                        isSourceLoaded={isSourceLoaded}
                    />
                </Container>
            )}
        </>
    );
};

export default PhotoFrame;
