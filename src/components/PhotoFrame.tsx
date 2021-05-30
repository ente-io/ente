import router from 'next/router';
import {
    DeadCenter,
    FILE_TYPE,
    GalleryContext,
    Search,
    SetFiles,
    setSearchStats,
} from 'pages/gallery';
import PreviewCard from 'pages/gallery/components/PreviewCard';
import React, { useContext, useEffect, useRef, useState } from 'react';
import { Button } from 'react-bootstrap';
import { File } from 'services/fileService';
import styled from 'styled-components';
import DownloadManager from 'services/downloadManager';
import constants from 'utils/strings/constants';
import AutoSizer from 'react-virtualized-auto-sizer';
import { VariableSizeList as List } from 'react-window';
import PhotoSwipe from 'components/PhotoSwipe/PhotoSwipe';
import { isInsideBox, isSameDay as isSameDayAnyYear } from 'utils/search';
import CloudUpload from './CloudUpload';

const DATE_CONTAINER_HEIGHT = 45;
const IMAGE_CONTAINER_HEIGHT = 200;
const NO_OF_PAGES = 2;
const A_DAY = 24 * 60 * 60 * 1000;

interface TimeStampListItem {
    itemType: ITEM_TYPE;
    items?: File[];
    itemStartIndex?: number;
    date?: string;
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
    margin-bottom: 1rem;

    .pswp-thumbnail {
        display: inline-block;
        cursor: pointer;
    }
`;

const ListItem = styled.div`
    display: flex;
    justify-content: center;
`;

const ListContainer = styled.div<{ columns: number }>`
    display: grid;
    grid-template-columns: repeat(${(props) => props.columns}, 1fr);
    grid-column-gap: 8px;
    padding: 0 8px;
    max-width: 100%;
    color: #fff;

    @media (min-width: 1000px) {
        width: 1000px;
    }

    @media (min-width: 450px) and (max-width: 1000px) {
        width: 600px;
    }

    @media (max-width: 450px) {
        width: 100%;
    }
`;

const DateContainer = styled.div`
    padding-top: 15px;
`;

const BannerContainer = styled.div`
    color: #979797;
    display: flex;
    align-items: center;
    justify-content: center;
    text-align: center;
`;

const EmptyScreen = styled.div`
    display: flex;
    justify-content: center;
    align-items: center;
    flex-direction: column;
    flex: 1;
    color: #2dc262;

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
    setSelected;
    selected;
    isFirstLoad;
    openFileUploader;
    loadingBar;
    searchMode: boolean;
    search: Search;
    setSearchStats: setSearchStats;
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
}: Props) => {
    const [open, setOpen] = useState(false);
    const [currentIndex, setCurrentIndex] = useState<number>(0);
    const fetching: { [k: number]: boolean } = {};
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
        if (galleryContext.resetList) {
            listRef.current?.resetAfterIndex(0);
        }
    }, [galleryContext.resetList]);

    const updateUrl = (index: number) => (url: string) => {
        files[index] = {
            ...files[index],
            msrc: url,
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
        setSelected((selected) => ({
            ...selected,
            [id]: checked,
            count: checked ? selected.count + 1 : selected.count - 1,
        }));
    };
    const getThumbnail = (file: File[], index: number) => (
        <PreviewCard
            key={`tile-${file[index].id}`}
            file={file[index]}
            updateUrl={updateUrl(file[index].dataIndex)}
            onClick={onThumbnailClick(index)}
            selectable
            onSelect={handleSelect(file[index].id)}
            selected={selected[file[index].id]}
            selectOnClick={selected.count > 0}
        />
    );

    const getSlideData = async (instance: any, index: number, item: File) => {
        if (!item.msrc) {
            let url;
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
            let url;
            if (galleryContext.files.has(item.id)) {
                url = galleryContext.files.get(item.id);
            } else {
                url = await DownloadManager.getFile(item);
                galleryContext.files.set(item.id, url);
            }
            updateSrcUrl(item.dataIndex, url);
            if (item.metadata.fileType === FILE_TYPE.VIDEO) {
                item.html = `
                    <video width="320" height="240" controls>
                        <source src="${url}" />
                        Your browser does not support the video tag.
                    </video>
                `;
                delete item.src;
                item.w = window.innerWidth;
            } else {
                item.src = url;
            }
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
            if (
                search.date &&
                !isSameDayAnyYear(search.date)(
                    new Date(item.metadata.creationTime / 1000),
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
            if (!idSet.has(item.id)) {
                if (
                    !router.query.collection ||
                    router.query.collection === item.collectionID.toString()
                ) {
                    idSet.add(item.id);
                    return true;
                }
                return false;
            }
            return false;
        });

    const isSameDay = (first, second) => (
        first.getFullYear() === second.getFullYear() &&
            first.getMonth() === second.getMonth() &&
            first.getDate() === second.getDate()
    );

    return (
        <>
            {!isFirstLoad && files.length === 0 && !searchMode ? (
                <EmptyScreen>
                    <CloudUpload width={150} height={150} />
                    <Button
                        variant="outline-success"
                        onClick={openFileUploader}
                        style={{
                            paddingLeft: '32px',
                            paddingRight: '32px',
                            paddingTop: '12px',
                            paddingBottom: '12px',
                        }}
                    >
                        {constants.UPLOAD_FIRST_PHOTO}
                    </Button>
                </EmptyScreen>
            ) : filteredData.length ? (
                <Container>
                    <AutoSizer>
                        {({ height, width }) => {
                            let columns;
                            if (width >= 1000) {
                                columns = 5;
                            } else if (width < 1000 && width >= 450) {
                                columns = 3;
                            } else if (width < 450 && width >= 300) {
                                columns = 2;
                            } else {
                                columns = 1;
                            }

                            const timeStampList: TimeStampListItem[] = [];
                            let listItemIndex = 0;
                            let currentDate = -1;
                            filteredData.forEach((item, index) => {
                                if (
                                    !isSameDay(
                                        new Date(
                                            item.metadata.creationTime / 1000,
                                        ),
                                        new Date(currentDate),
                                    )
                                ) {
                                    currentDate = item.metadata.creationTime / 1000;
                                    const dateTimeFormat = new Intl.DateTimeFormat('en-IN', {
                                        weekday: 'short',
                                        year: 'numeric',
                                        month: 'long',
                                        day: 'numeric',
                                    });
                                    timeStampList.push({
                                        itemType: ITEM_TYPE.TIME,
                                        date: isSameDay(
                                            new Date(currentDate),
                                            new Date(),
                                        ) ?
                                            'Today' :
                                            isSameDay(
                                                new Date(currentDate),
                                                new Date(Date.now() - A_DAY),
                                            ) ?
                                                'Yesterday' :
                                                dateTimeFormat.format(
                                                    currentDate,
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
                            files.length < 30 && !searchMode &&
                                timeStampList.push({
                                    itemType: ITEM_TYPE.BANNER,
                                    banner: (
                                        <BannerContainer>
                                            {constants.INSTALL_MOBILE_APP()}
                                        </BannerContainer>
                                    ),
                                    id: 'install-banner',
                                    height: 48,
                                });
                            const extraRowsToRender = Math.ceil(
                                (NO_OF_PAGES * height) / IMAGE_CONTAINER_HEIGHT,
                            );

                            const generateKey = (index) => {
                                switch (timeStampList[index].itemType) {
                                case ITEM_TYPE.TILE:
                                    return `${timeStampList[index].items[0].id}-${timeStampList[index].items.slice(-1)[0].id}`;
                                default:
                                    return `${timeStampList[index].id}-${index}`;
                                }
                            };

                            const getItemSize = (index) => {
                                switch (timeStampList[index].itemType) {
                                case ITEM_TYPE.TIME:
                                    return DATE_CONTAINER_HEIGHT;
                                case ITEM_TYPE.TILE:
                                    return IMAGE_CONTAINER_HEIGHT;
                                default:
                                    return timeStampList[index].height;
                                }
                            };

                            const renderListItem = (listItem) => {
                                switch (listItem.itemType) {
                                case ITEM_TYPE.TIME:
                                    return (
                                        <DateContainer>
                                            {listItem.date}
                                        </DateContainer>
                                    );
                                case ITEM_TYPE.BANNER:
                                    return listItem.banner;
                                default:
                                    return (listItem.items.map(
                                        (item, idx) => getThumbnail(
                                            filteredData,
                                            listItem.itemStartIndex + idx,
                                        ),
                                    ));
                                }
                            };

                            return (
                                <List
                                    key={`${columns}-${router.query.collection}`}
                                    ref={listRef}
                                    itemSize={getItemSize}
                                    height={height}
                                    width={width}
                                    itemCount={timeStampList.length}
                                    itemKey={generateKey}
                                    overscanCount={extraRowsToRender}
                                >
                                    {({ index, style }) => (
                                        <ListItem style={style}>
                                            <ListContainer
                                                columns={
                                                    timeStampList[index].itemType === ITEM_TYPE.TILE ?
                                                        columns :1
                                                }
                                            >
                                                {renderListItem(timeStampList[index])}
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
