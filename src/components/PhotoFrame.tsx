import { GalleryContext } from 'pages/gallery';
import PreviewCard from './pages/gallery/PreviewCard';
import React, { useContext, useEffect, useRef, useState } from 'react';
import { Button } from 'react-bootstrap';
import { EnteFile } from 'types/file';
import styled from 'styled-components';
import DownloadManager from 'services/downloadManager';
import constants from 'utils/strings/constants';
import AutoSizer from 'react-virtualized-auto-sizer';
import PhotoSwipe from 'components/PhotoSwipe/PhotoSwipe';
import { isInsideBox, isSameDay as isSameDayAnyYear } from 'utils/search';
import { fileIsArchived, formatDateRelative } from 'utils/file';
import {
    ALL_SECTION,
    ARCHIVE_SECTION,
    TRASH_SECTION,
} from 'constants/collection';
import { isSharedFile } from 'utils/file';
import { isPlaybackPossible } from 'utils/photoFrame';
import { PhotoList } from './PhotoList';
import { SetFiles, SelectedState, Search, setSearchStats } from 'types/gallery';
import { FILE_TYPE } from 'constants/file';
import PublicCollectionDownloadManager from 'services/publicCollectionDownloadManager';
import { PublicCollectionGalleryContext } from 'utils/publicCollectionGallery';
import { useRouter } from 'next/router';

const Container = styled.div`
    display: block;
    flex: 1;
    width: 100%;
    flex-wrap: wrap;
    margin: 0 auto;
    overflow-x: hidden;
    .pswp-thumbnail {
        display: inline-block;
        cursor: pointer;
    }
`;

const EmptyScreen = styled.div`
    display: flex;
    justify-content: center;
    align-items: center;
    flex-direction: column;
    flex: 1;
    color: #51cd7c;

    & > svg {
        filter: drop-shadow(3px 3px 5px rgba(45, 194, 98, 0.5));
    }
`;

const PHOTOSWIPE_HASH_SUFFIX = '&photoswipe-opened';

interface Props {
    files: EnteFile[];
    setFiles: SetFiles;
    syncWithRemote: () => Promise<void>;
    favItemIds: Set<number>;
    setSelected: (
        selected: SelectedState | ((selected: SelectedState) => SelectedState)
    ) => void;
    selected: SelectedState;
    isFirstLoad;
    openFileUploader;
    isInSearchMode: boolean;
    search: Search;
    setSearchStats: setSearchStats;
    deleted?: number[];
    activeCollection: number;
    isSharedCollection: boolean;
}

const PhotoFrame = ({
    files,
    setFiles,
    syncWithRemote,
    favItemIds,
    setSelected,
    selected,
    isFirstLoad,
    openFileUploader,
    isInSearchMode,
    search,
    setSearchStats,
    deleted,
    activeCollection,
    isSharedCollection,
}: Props) => {
    const [open, setOpen] = useState(false);
    const [currentIndex, setCurrentIndex] = useState<number>(0);
    const [fetching, setFetching] = useState<{ [k: number]: boolean }>({});
    const startTime = Date.now();
    const galleryContext = useContext(GalleryContext);
    const publicCollectionGalleryContext = useContext(
        PublicCollectionGalleryContext
    );
    const [rangeStart, setRangeStart] = useState(null);
    const [currentHover, setCurrentHover] = useState(null);
    const [isShiftKeyPressed, setIsShiftKeyPressed] = useState(false);
    const filteredDataRef = useRef([]);
    const filteredData = filteredDataRef?.current ?? [];
    const router = useRouter();
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
            const photoSwipeShouldBeOpened = hash.endsWith(
                PHOTOSWIPE_HASH_SUFFIX
            );
            if (photoSwipeShouldBeOpened) {
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
        if (isInSearchMode) {
            setSearchStats({
                resultCount: filteredData.length,
                timeTaken: (Date.now() - startTime) / 1000,
            });
        }
        if (search.fileIndex || search.fileIndex === 0) {
            const filteredDataIdx = filteredData.findIndex(
                (data) => data.dataIndex === search.fileIndex
            );
            if (filteredDataIdx || filteredDataIdx === 0) {
                onThumbnailClick(filteredDataIdx)();
            }
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

    useEffect(() => {
        const idSet = new Set();
        filteredDataRef.current = files
            .map((item, index) => ({
                ...item,
                dataIndex: index,
                w: window.innerWidth,
                h: window.innerHeight,
                ...(item.deleteBy && {
                    title: constants.AUTOMATIC_BIN_DELETE_MESSAGE(
                        formatDateRelative(item.deleteBy / 1000)
                    ),
                }),
            }))
            .filter((item) => {
                if (deleted.includes(item.id)) {
                    return false;
                }
                if (
                    search.date &&
                    !isSameDayAnyYear(search.date)(
                        new Date(item.metadata.creationTime / 1000)
                    )
                ) {
                    return false;
                }
                if (
                    search.location &&
                    !isInsideBox(item.metadata, search.location)
                ) {
                    return false;
                }
                if (activeCollection === ALL_SECTION && fileIsArchived(item)) {
                    return false;
                }
                if (
                    activeCollection === ARCHIVE_SECTION &&
                    !fileIsArchived(item)
                ) {
                    return false;
                }

                if (isSharedFile(item) && !isSharedCollection) {
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
    }, [files, deleted, search, activeCollection]);

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

    const updateURL = (index: number) => (url: string) => {
        files[index] = {
            ...files[index],
            msrc: url,
            src: files[index].src ? files[index].src : url,
            w: window.innerWidth,
            h: window.innerHeight,
        };
        if (
            files[index].metadata.fileType === FILE_TYPE.VIDEO &&
            !files[index].html
        ) {
            files[index].html = `
                <div class="video-loading">
                    <img src="${url}" />
                    <div class="spinner-border text-light" role="status">
                        <span class="sr-only">Loading...</span>
                    </div>
                </div>
            `;
            delete files[index].src;
        }
        if (
            files[index].metadata.fileType === FILE_TYPE.IMAGE &&
            !files[index].src
        ) {
            files[index].src = url;
        }
        setFiles(files);
    };

    const updateSrcURL = async (index: number, url: string) => {
        files[index] = {
            ...files[index],
            w: window.innerWidth,
            h: window.innerHeight,
        };
        if (files[index].metadata.fileType === FILE_TYPE.VIDEO) {
            if (await isPlaybackPossible(url)) {
                files[index].html = `
                <video controls>
                    <source src="${url}" />
                    Your browser does not support the video tag.
                </video>
            `;
            } else {
                files[index].html = `
                <div class="video-loading">
                    <img src="${files[index].msrc}" />
                    <div class="download-message" >
                        ${constants.VIDEO_PLAYBACK_FAILED_DOWNLOAD_INSTEAD}
                        <a class="btn btn-outline-success" href=${url} download="${files[index].metadata.title}"">Download</button>
                    </div>
                </div>
                `;
            }
        } else {
            files[index].src = url;
        }
        setFiles(files);
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
    const getThumbnail = (files: EnteFile[], index: number) =>
        files[index] ? (
            <PreviewCard
                key={`tile-${files[index].id}-selected-${
                    selected[files[index].id] ?? false
                }`}
                file={files[index]}
                updateURL={updateURL(files[index].dataIndex)}
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
                                publicCollectionGalleryContext.token
                            );
                    } else {
                        url = await DownloadManager.getThumbnail(item);
                    }
                    galleryContext.thumbs.set(item.id, url);
                }
                updateURL(item.dataIndex)(url);
                item.msrc = url;
                if (!item.src) {
                    item.src = url;
                }
                item.w = window.innerWidth;
                item.h = window.innerHeight;
                try {
                    instance.invalidateCurrItems();
                    instance.updateSize(true);
                } catch (e) {
                    // ignore
                }
            } catch (e) {
                // no-op
            }
        }
        if (!fetching[item.dataIndex]) {
            try {
                fetching[item.dataIndex] = true;
                let url: string;
                if (galleryContext.files.has(item.id)) {
                    url = galleryContext.files.get(item.id);
                } else {
                    if (
                        publicCollectionGalleryContext.accessedThroughSharedURL
                    ) {
                        url = await PublicCollectionDownloadManager.getFile(
                            item,
                            publicCollectionGalleryContext.token,
                            true
                        );
                    } else {
                        url = await DownloadManager.getFile(item, true);
                    }
                    galleryContext.files.set(item.id, url);
                }
                await updateSrcURL(item.dataIndex, url);
                item.html = files[item.dataIndex].html;
                item.src = files[item.dataIndex].src;
                item.w = files[item.dataIndex].w;
                item.h = files[item.dataIndex].h;
                try {
                    instance.invalidateCurrItems();
                    instance.updateSize(true);
                } catch (e) {
                    // ignore
                }
            } catch (e) {
                // no-op
            } finally {
                fetching[item.dataIndex] = false;
            }
        }
    };

    return (
        <>
            {!isFirstLoad && files.length === 0 && !isInSearchMode ? (
                <EmptyScreen>
                    <img height={150} src="/images/gallery.png" />
                    <div style={{ color: '#a6a6a6', marginTop: '16px' }}>
                        {constants.UPLOAD_FIRST_PHOTO_DESCRIPTION}
                    </div>
                    <Button
                        variant="outline-success"
                        onClick={openFileUploader}
                        style={{
                            marginTop: '32px',
                            paddingLeft: '32px',
                            paddingRight: '32px',
                            paddingTop: '12px',
                            paddingBottom: '12px',
                            fontWeight: 900,
                        }}>
                        {constants.UPLOAD_FIRST_PHOTO}
                    </Button>
                </EmptyScreen>
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
                                    files.length < 30 && !isInSearchMode
                                }
                                resetFetching={resetFetching}
                            />
                        )}
                    </AutoSizer>
                    <PhotoSwipe
                        isOpen={open}
                        items={filteredData}
                        currentIndex={currentIndex}
                        onClose={handleClose}
                        gettingData={getSlideData}
                        favItemIds={favItemIds}
                        isSharedCollection={isSharedCollection}
                        isTrashCollection={activeCollection === TRASH_SECTION}
                    />
                </Container>
            )}
        </>
    );
};

export default PhotoFrame;
