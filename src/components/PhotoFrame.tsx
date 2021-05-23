import router from 'next/router';
import { DeadCenter, FILE_TYPE } from 'pages/gallery';
import PreviewCard from 'pages/gallery/components/PreviewCard';
import React, { useState } from 'react';
import { Alert, Button } from 'react-bootstrap';
import { File } from 'services/fileService';
import styled from 'styled-components';
import DownloadManager from 'services/downloadManager';
import constants from 'utils/strings/constants';
import AutoSizer from 'react-virtualized-auto-sizer';
import { VariableSizeList as List } from 'react-window';
import PhotoSwipe from 'components/PhotoSwipe/PhotoSwipe';

const DATE_CONTAINER_HEIGHT = 45;
const IMAGE_CONTAINER_HEIGHT = 200;
const NO_OF_PAGES = 2;
const A_DAY = 24 * 60 * 60 * 1000;

type SetFiles = React.Dispatch<React.SetStateAction<File[]>>;

interface TimeStampListItem {
    itemType: ITEM_TYPE;
    items?: File[];
    itemStartIndex?: number;
    date?: string;
    banner?: any;
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
    sinceTime: number;
    setSelected;
    selected;
    isFirstLoad;
    openFileUploader;
    loadingBar;
}

const PhotoFrame = ({
    files,
    setFiles,
    syncWithRemote,
    favItemIds,
    sinceTime,
    setSelected,
    selected,
    isFirstLoad,
    openFileUploader,
    loadingBar,
}: Props) => {
    const [open, setOpen] = useState(false);
    const [currentIndex, setCurrentIndex] = useState<number>(0);
    const fetching: { [k: number]: boolean } = {};

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
    const getThumbnail = (file: File[], index: number) => {
        return (
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
    };

    const getSlideData = async (instance: any, index: number, item: File) => {
        if (!item.msrc) {
            const url = await DownloadManager.getPreview(item);
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
            const url = await DownloadManager.getFile(item);
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

    let idSet = new Set();

    const filteredData = files
        .map((item, index) => ({
            ...item,
            dataIndex: index,
        }))
        .filter((item) => {
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

    const isSameDay = (first, second) => {
        return (
            first.getFullYear() === second.getFullYear() &&
            first.getMonth() === second.getMonth() &&
            first.getDate() === second.getDate()
        );
    };

    return (
        <>
            {!isFirstLoad && files.length == 0 ? (
                <div
                    style={{
                        height: '60%',
                        display: 'grid',
                        placeItems: 'center',
                    }}
                >
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
                </div>
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
                                            month: 'long',
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
                                    });
                                    timeStampList.push({
                                        itemType: ITEM_TYPE.TILE,
                                        items: [item],
                                        itemStartIndex: index,
                                    });
                                    listItemIndex = 1;
                                } else {
                                    if (listItemIndex < columns) {
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
                                }
                            });
                            files.length < 30 &&
                                timeStampList.push({
                                    itemType: ITEM_TYPE.BANNER,
                                    banner: (
                                        <Alert
                                            variant="success"
                                            style={{
                                                color: 'rgb(151, 151, 151)',
                                                backgroundColor:
                                                    'rgb(25, 25, 25)',
                                                border: 'none',
                                                margin: 0,
                                                display: 'flex',
                                                alignItems: 'center',
                                                justifyContent: 'center',
                                            }}
                                        >
                                            {constants.INSTALL_MOBILE_APP()}
                                        </Alert>
                                    ),
                                });
                            const extraRowsToRender = Math.ceil(
                                (NO_OF_PAGES * height) / IMAGE_CONTAINER_HEIGHT
                            );
                            return (
                                <List
                                    itemSize={(index) =>
                                        timeStampList[index].itemType ===
                                        ITEM_TYPE.TILE
                                            ? IMAGE_CONTAINER_HEIGHT
                                            : DATE_CONTAINER_HEIGHT
                                    }
                                    height={height}
                                    width={width}
                                    itemCount={timeStampList.length}
                                    key={`${router.query.collection}-${columns}-${sinceTime}`}
                                    overscanCount={extraRowsToRender}
                                >
                                    {({ index, style }) => {
                                        return (
                                            <ListItem
                                                style={
                                                    timeStampList[index]
                                                        .itemType ===
                                                    ITEM_TYPE.BANNER
                                                        ? {
                                                              ...style,
                                                              top: Math.max(
                                                                  Number(
                                                                      style.top
                                                                  ),
                                                                  height - 45
                                                              ),
                                                              height:
                                                                  width < 450
                                                                      ? Number(
                                                                            style.height
                                                                        ) * 2
                                                                      : style.height,
                                                          }
                                                        : style
                                                }
                                            >
                                                <ListContainer
                                                    columns={
                                                        timeStampList[index]
                                                            .itemType ===
                                                        ITEM_TYPE.TILE
                                                            ? columns
                                                            : 1
                                                    }
                                                >
                                                    {timeStampList[index]
                                                        .itemType ===
                                                    ITEM_TYPE.TIME ? (
                                                        <DateContainer>
                                                            {
                                                                timeStampList[
                                                                    index
                                                                ].date
                                                            }
                                                        </DateContainer>
                                                    ) : timeStampList[index]
                                                          .itemType ===
                                                      ITEM_TYPE.BANNER ? (
                                                        <>
                                                            {
                                                                timeStampList[
                                                                    index
                                                                ].banner
                                                            }
                                                        </>
                                                    ) : (
                                                        timeStampList[
                                                            index
                                                        ].items.map(
                                                            (item, idx) => {
                                                                return getThumbnail(
                                                                    filteredData,
                                                                    timeStampList[
                                                                        index
                                                                    ]
                                                                        .itemStartIndex +
                                                                        idx
                                                                );
                                                            }
                                                        )
                                                    )}
                                                </ListContainer>
                                            </ListItem>
                                        );
                                    }}
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
