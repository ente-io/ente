import {
    DeadCenter,
    GalleryContext,
    Search,
    SelectedState,
    SetFiles,
    setSearchStats,
} from 'pages/gallery';
import PreviewCard from './pages/gallery/PreviewCard';
import React, { useContext, useEffect, useRef, useState } from 'react';
import { Button } from 'react-bootstrap';
import { File, FILE_TYPE } from 'services/fileService';
import styled from 'styled-components';
import DownloadManager from 'services/downloadManager';
import constants from 'utils/strings/constants';
import AutoSizer from 'react-virtualized-auto-sizer';
import { VariableSizeList as List } from 'react-window';
import PhotoSwipe from 'components/PhotoSwipe/PhotoSwipe';
import { isInsideBox, isSameDay as isSameDayAnyYear } from 'utils/search';
import { SetDialogMessage } from './MessageDialog';
import { CustomError } from 'utils/common/errorUtil';
import {
    GAP_BTW_TILES,
    DATE_CONTAINER_HEIGHT,
    IMAGE_CONTAINER_MAX_HEIGHT,
    IMAGE_CONTAINER_MAX_WIDTH,
    MIN_COLUMNS,
    SPACE_BTW_DATES,
} from 'types';
import { fileIsArchived } from 'utils/file';
import { ARCHIVE_SECTION } from './pages/gallery/Collections';
import { isSharedFile } from 'utils/file';

const NO_OF_PAGES = 2;
const A_DAY = 24 * 60 * 60 * 1000;
const WAIT_FOR_VIDEO_PLAYBACK = 1 * 1000;

interface TimeStampListItem {
    itemType: ITEM_TYPE;
    items?: File[];
    itemStartIndex?: number;
    date?: string;
    dates?: {
        date: string;
        span: number;
    }[];
    groups?: number[];
    banner?: any;
    id?: string;
    height?: number;
}

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

const ListItem = styled.div`
    display: flex;
    justify-content: center;
`;

const getTemplateColumns = (columns: number, groups?: number[]): string => {
    if (groups) {
        const sum = groups.reduce((acc, item) => acc + item, 0);
        if (sum < columns) {
            groups[groups.length - 1] += columns - sum;
        }
        return groups
            .map((x) => `repeat(${x}, 1fr)`)
            .join(` ${SPACE_BTW_DATES}px `);
    } else {
        return `repeat(${columns}, 1fr)`;
    }
};

const ListContainer = styled.div<{ columns: number; groups?: number[] }>`
    display: grid;
    grid-template-columns: ${({ columns, groups }) =>
        getTemplateColumns(columns, groups)};
    grid-column-gap: ${GAP_BTW_TILES}px;
    padding: 0 24px;
    width: 100%;
    color: #fff;

    @media (max-width: ${IMAGE_CONTAINER_MAX_WIDTH * 4}px) {
        padding: 0 4px;
    }
`;

const DateContainer = styled.div<{ span: number }>`
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    grid-column: span ${(props) => props.span};
    display: flex;
    align-items: center;
    height: ${DATE_CONTAINER_HEIGHT}px;
`;

const BannerContainer = styled.div<{ span: number }>`
    color: #979797;
    text-align: center;
    grid-column: span ${(props) => props.span};
    display: flex;
    justify-content: center;
    align-items: flex-end;
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

enum ITEM_TYPE {
    TIME = 'TIME',
    TILE = 'TILE',
    BANNER = 'BANNER',
}

interface Props {
    files: File[];
    setFiles: SetFiles;
    syncWithRemote: () => Promise<void>;
    favItemIds: Set<number>;
    setSelected: (
        selected: SelectedState | ((selected: SelectedState) => SelectedState)
    ) => void;
    selected: SelectedState;
    isFirstLoad;
    openFileUploader;
    loadingBar;
    searchMode: boolean;
    search: Search;
    setSearchStats: setSearchStats;
    deleted?: number[];
    archived?: number[];
    setDialogMessage: SetDialogMessage;
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
    loadingBar,
    searchMode,
    search,
    setSearchStats,
    deleted,
    archived,
    setDialogMessage,
    activeCollection,
    isSharedCollection,
}: Props) => {
    const [open, setOpen] = useState(false);
    const [currentIndex, setCurrentIndex] = useState<number>(0);
    const [fetching, setFetching] = useState<{ [k: number]: boolean }>({});
    const startTime = Date.now();
    const galleryContext = useContext(GalleryContext);
    const listRef = useRef(null);

    useEffect(() => {
        if (searchMode) {
            setSearchStats({
                resultCount: filteredData.length,
                timeTaken: (Date.now() - startTime) / 1000,
            });
        }
    }, [search]);

    useEffect(() => {
        listRef.current?.resetAfterIndex(0);
        setFetching({});
    }, [files, search, deleted]);

    const updateUrl = (index: number) => (url: string) => {
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

    const updateSrcUrl = (index: number, url: string) => {
        files[index] = {
            ...files[index],
            src: url,
            w: window.innerWidth,
            h: window.innerHeight,
        };
        if (files[index].metadata.fileType === FILE_TYPE.VIDEO) {
            files[index].html = `
                <video controls>
                    <source src="${url}" />
                    Your browser does not support the video tag.
                </video>
            `;
            delete files[index].src;
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

    const handleSelect = (id: number) => (checked: boolean) => {
        if (selected.collectionID !== activeCollection) {
            setSelected({ count: 0, collectionID: 0 });
        }
        setSelected((selected) => ({
            ...selected,
            [id]: checked,
            count: checked ? selected.count + 1 : selected.count - 1,
            collectionID: activeCollection,
        }));
    };
    const getThumbnail = (file: File[], index: number) => (
        <PreviewCard
            key={`tile-${file[index].id}`}
            file={file[index]}
            updateUrl={updateUrl(file[index].dataIndex)}
            onClick={onThumbnailClick(index)}
            selectable={!isSharedCollection}
            onSelect={handleSelect(file[index].id)}
            selected={
                selected.collectionID === activeCollection &&
                selected[file[index].id]
            }
            selectOnClick={selected.count > 0}
        />
    );

    const getSlideData = async (instance: any, index: number, item: File) => {
        if (!item.msrc) {
            let url: string;
            if (galleryContext.thumbs.has(item.id)) {
                url = galleryContext.thumbs.get(item.id);
            } else {
                url = await DownloadManager.getPreview(item);
                galleryContext.thumbs.set(item.id, url);
            }
            updateUrl(item.dataIndex)(url);
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
        }
        if (!fetching[item.dataIndex]) {
            fetching[item.dataIndex] = true;
            let url: string;
            if (galleryContext.files.has(item.id)) {
                url = galleryContext.files.get(item.id);
            } else {
                url = await DownloadManager.getFile(item, true);
                galleryContext.files.set(item.id, url);
            }
            updateSrcUrl(item.dataIndex, url);
            if (item.metadata.fileType === FILE_TYPE.VIDEO) {
                try {
                    await new Promise((resolve, reject) => {
                        const video = document.createElement('video');
                        video.addEventListener('timeupdate', function () {
                            clearTimeout(t);
                            resolve(null);
                        });
                        video.preload = 'metadata';
                        video.src = url;
                        video.currentTime = 3;
                        const t = setTimeout(() => {
                            reject(
                                Error(
                                    `${CustomError.VIDEO_PLAYBACK_FAILED} err: wait time exceeded`
                                )
                            );
                        }, WAIT_FOR_VIDEO_PLAYBACK);
                    });
                    item.html = `
                        <video width="320" height="240" controls>
                            <source src="${url}" />
                            Your browser does not support the video tag.
                        </video>
                    `;
                    delete item.src;
                } catch (e) {
                    const downloadFile = async () => {
                        const a = document.createElement('a');
                        a.style.display = 'none';
                        a.href = url;
                        a.download = item.metadata.title;
                        document.body.appendChild(a);
                        a.click();
                        a.remove();
                        setOpen(false);
                    };
                    setDialogMessage({
                        title: constants.VIDEO_PLAYBACK_FAILED,
                        content:
                            constants.VIDEO_PLAYBACK_FAILED_DOWNLOAD_INSTEAD,
                        staticBackdrop: true,
                        proceed: {
                            text: constants.DOWNLOAD,
                            action: downloadFile,
                            variant: 'success',
                        },
                        close: {
                            text: constants.CLOSE,
                            action: () => setOpen(false),
                        },
                    });
                    return;
                }
            } else {
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
        }
    };

    const idSet = new Set();
    const filteredData = files
        .map((item, index) => ({
            ...item,
            dataIndex: index,
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
            if (
                activeCollection === 0 &&
                (fileIsArchived(item) || archived.includes(item.id))
            ) {
                return false;
            }
            if (activeCollection === ARCHIVE_SECTION && !fileIsArchived(item)) {
                return false;
            }

            if (isSharedFile(item) && !isSharedCollection) {
                return false;
            }
            if (!idSet.has(item.id)) {
                if (
                    activeCollection <= 0 ||
                    activeCollection === item.collectionID
                ) {
                    idSet.add(item.id);
                    return true;
                }
                return false;
            }
            return false;
        });

    const isSameDay = (first, second) =>
        first.getFullYear() === second.getFullYear() &&
        first.getMonth() === second.getMonth() &&
        first.getDate() === second.getDate();

    /**
     * Checks and merge multiple dates into a single row.
     *
     * @param items
     * @param columns
     * @returns
     */
    const mergeTimeStampList = (
        items: TimeStampListItem[],
        columns: number
    ): TimeStampListItem[] => {
        const newList: TimeStampListItem[] = [];
        let index = 0;
        let newIndex = 0;
        while (index < items.length) {
            const currItem = items[index];
            // If the current item is of type time, then it is not part of an ongoing date.
            // So, there is a possibility of merge.
            if (currItem.itemType === ITEM_TYPE.TIME) {
                // If new list pointer is not at the end of list then
                // we can add more items to the same list.
                if (newList[newIndex]) {
                    // Check if items can be added to same list
                    if (
                        newList[newIndex + 1].items.length +
                            items[index + 1].items.length <=
                        columns
                    ) {
                        newList[newIndex].dates.push({
                            date: currItem.date,
                            span: items[index + 1].items.length,
                        });
                        newList[newIndex + 1].items = newList[
                            newIndex + 1
                        ].items.concat(items[index + 1].items);
                        index += 2;
                    } else {
                        // Adding items would exceed the number of columns.
                        // So, move new list pointer to the end. Hence, in next iteration,
                        // items will be added to a new list.
                        newIndex += 2;
                    }
                } else {
                    // New list pointer was at the end of list so simply add new items to the list.
                    newList.push({
                        ...currItem,
                        date: null,
                        dates: [
                            {
                                date: currItem.date,
                                span: items[index + 1].items.length,
                            },
                        ],
                    });
                    newList.push(items[index + 1]);
                    index += 2;
                }
            } else {
                // Merge cannot happen. Simply add all items to new list
                // and set new list point to the end of list.
                newList.push(currItem);
                index++;
                newIndex = newList.length;
            }
        }
        for (let i = 0; i < newList.length; i++) {
            const currItem = newList[i];
            const nextItem = newList[i + 1];
            if (currItem.itemType === ITEM_TYPE.TIME) {
                if (currItem.dates.length > 1) {
                    currItem.groups = currItem.dates.map((item) => item.span);
                    nextItem.groups = currItem.groups;
                }
            }
        }
        return newList;
    };

    return (
        <>
            {!isFirstLoad && files.length === 0 && !searchMode ? (
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
            ) : filteredData.length ? (
                <Container>
                    <AutoSizer>
                        {({ height, width }) => {
                            let columns = Math.floor(
                                width / IMAGE_CONTAINER_MAX_WIDTH
                            );
                            let listItemHeight = IMAGE_CONTAINER_MAX_HEIGHT;
                            let skipMerge = false;
                            if (columns < MIN_COLUMNS) {
                                columns = MIN_COLUMNS;
                                listItemHeight = width / MIN_COLUMNS;
                                skipMerge = true;
                            }

                            let timeStampList: TimeStampListItem[] = [];
                            let listItemIndex = 0;
                            let currentDate = -1;
                            filteredData.forEach((item, index) => {
                                if (
                                    !isSameDay(
                                        new Date(
                                            item.metadata.creationTime / 1000
                                        ),
                                        new Date(currentDate)
                                    )
                                ) {
                                    currentDate =
                                        item.metadata.creationTime / 1000;
                                    const dateTimeFormat =
                                        new Intl.DateTimeFormat('en-IN', {
                                            weekday: 'short',
                                            year: 'numeric',
                                            month: 'short',
                                            day: 'numeric',
                                        });
                                    timeStampList.push({
                                        itemType: ITEM_TYPE.TIME,
                                        date: isSameDay(
                                            new Date(currentDate),
                                            new Date()
                                        )
                                            ? 'Today'
                                            : isSameDay(
                                                  new Date(currentDate),
                                                  new Date(Date.now() - A_DAY)
                                              )
                                            ? 'Yesterday'
                                            : dateTimeFormat.format(
                                                  currentDate
                                              ),
                                        id: currentDate.toString(),
                                    });
                                    timeStampList.push({
                                        itemType: ITEM_TYPE.TILE,
                                        items: [item],
                                        itemStartIndex: index,
                                    });
                                    listItemIndex = 1;
                                } else if (listItemIndex < columns) {
                                    timeStampList[
                                        timeStampList.length - 1
                                    ].items.push(item);
                                    listItemIndex++;
                                } else {
                                    listItemIndex = 1;
                                    timeStampList.push({
                                        itemType: ITEM_TYPE.TILE,
                                        items: [item],
                                        itemStartIndex: index,
                                    });
                                }
                            });

                            if (!skipMerge) {
                                timeStampList = mergeTimeStampList(
                                    timeStampList,
                                    columns
                                );
                            }

                            const getItemSize = (index) => {
                                switch (timeStampList[index].itemType) {
                                    case ITEM_TYPE.TIME:
                                        return DATE_CONTAINER_HEIGHT;
                                    case ITEM_TYPE.TILE:
                                        return listItemHeight;
                                    default:
                                        return timeStampList[index].height;
                                }
                            };

                            const photoFrameHeight = (() => {
                                let sum = 0;
                                for (let i = 0; i < timeStampList.length; i++) {
                                    sum += getItemSize(i);
                                }
                                return sum;
                            })();
                            files.length < 30 &&
                                !searchMode &&
                                timeStampList.push({
                                    itemType: ITEM_TYPE.BANNER,
                                    banner: (
                                        <BannerContainer span={columns}>
                                            <p>
                                                {constants.INSTALL_MOBILE_APP()}
                                            </p>
                                        </BannerContainer>
                                    ),
                                    id: 'install-banner',
                                    height: Math.max(
                                        48,
                                        height - photoFrameHeight
                                    ),
                                });
                            const extraRowsToRender = Math.ceil(
                                (NO_OF_PAGES * height) /
                                    IMAGE_CONTAINER_MAX_HEIGHT
                            );

                            const generateKey = (index) => {
                                switch (timeStampList[index].itemType) {
                                    case ITEM_TYPE.TILE:
                                        return `${
                                            timeStampList[index].items[0].id
                                        }-${
                                            timeStampList[index].items.slice(
                                                -1
                                            )[0].id
                                        }`;
                                    default:
                                        return `${timeStampList[index].id}-${index}`;
                                }
                            };

                            const renderListItem = (
                                listItem: TimeStampListItem
                            ) => {
                                switch (listItem.itemType) {
                                    case ITEM_TYPE.TIME:
                                        return listItem.dates ? (
                                            listItem.dates.map((item) => (
                                                <>
                                                    <DateContainer
                                                        key={item.date}
                                                        span={item.span}>
                                                        {item.date}
                                                    </DateContainer>
                                                    <div />
                                                </>
                                            ))
                                        ) : (
                                            <DateContainer span={columns}>
                                                {listItem.date}
                                            </DateContainer>
                                        );
                                    case ITEM_TYPE.BANNER:
                                        return listItem.banner;
                                    default: {
                                        const ret = listItem.items.map(
                                            (item, idx) =>
                                                getThumbnail(
                                                    filteredData,
                                                    listItem.itemStartIndex +
                                                        idx
                                                )
                                        );
                                        if (listItem.groups) {
                                            let sum = 0;
                                            for (
                                                let i = 0;
                                                i < listItem.groups.length - 1;
                                                i++
                                            ) {
                                                sum = sum + listItem.groups[i];
                                                ret.splice(sum, 0, <div />);
                                                sum += 1;
                                            }
                                        }
                                        return ret;
                                    }
                                }
                            };

                            return (
                                <List
                                    key={`${columns}-${listItemHeight}-${activeCollection}`}
                                    ref={listRef}
                                    itemSize={getItemSize}
                                    height={height}
                                    width={width}
                                    itemCount={timeStampList.length}
                                    itemKey={generateKey}
                                    overscanCount={extraRowsToRender}>
                                    {({ index, style }) => (
                                        <ListItem style={style}>
                                            <ListContainer
                                                columns={columns}
                                                groups={
                                                    timeStampList[index].groups
                                                }>
                                                {renderListItem(
                                                    timeStampList[index]
                                                )}
                                            </ListContainer>
                                        </ListItem>
                                    )}
                                </List>
                            );
                        }}
                    </AutoSizer>
                    <PhotoSwipe
                        isOpen={open}
                        items={filteredData}
                        currentIndex={currentIndex}
                        onClose={handleClose}
                        gettingData={getSlideData}
                        favItemIds={favItemIds}
                        loadingBar={loadingBar}
                        isSharedCollection={isSharedCollection}
                    />
                </Container>
            ) : (
                <DeadCenter>
                    <div>{constants.NOTHING_HERE}</div>
                </DeadCenter>
            )}
        </>
    );
};

export default PhotoFrame;
