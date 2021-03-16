import React, { useEffect, useRef, useState } from 'react';
import { useRouter } from 'next/router';
import { getKey, SESSION_KEYS } from 'utils/storage/sessionStorage';
import { file, syncData, localFiles } from 'services/fileService';
import PreviewCard from './components/PreviewCard';
import { getActualKey, getToken } from 'utils/common/key';
import styled from 'styled-components';
import PhotoSwipe from 'components/PhotoSwipe/PhotoSwipe';
import AutoSizer from 'react-virtualized-auto-sizer';
import { VariableSizeList as List } from 'react-window';
import LoadingBar from 'react-top-loading-bar';
import Collections from './components/Collections';
import Upload from './components/Upload';
import DownloadManager from 'services/downloadManager';
import {
    collection,
    syncCollections,
    CollectionAndItsLatestFile,
    getCollectionAndItsLatestFile,
    getFavItemIds,
    getLocalCollections,
    getCollectionUpdationTime,
    getNonEmptyCollections,
} from 'services/collectionService';
import constants from 'utils/strings/constants';
import AlertBanner from './components/AlertBanner';
import { Alert, Button, Jumbotron } from 'react-bootstrap';

const DATE_CONTAINER_HEIGHT = 45;
const IMAGE_CONTAINER_HEIGHT = 200;
const NO_OF_PAGES = 2;

enum ITEM_TYPE {
    TIME = 'TIME',
    TILE = 'TILE',
}
export enum FILE_TYPE {
    IMAGE,
    VIDEO,
    OTHERS,
}

interface TimeStampListItem {
    itemType: ITEM_TYPE;
    items?: file[];
    itemStartIndex?: number;
    date?: string;
}

const Container = styled.div`
    display: block;
    flex: 1;
    width: 100%;
    flex-wrap: wrap;
    margin: 0 auto;

    .pswp-thumbnail {
        display: inline-block;
        cursor: pointer;
    }
`;

const ListItem = styled.div`
    display: flex;
    justify-content: center;
`;

const DeadCenter = styled.div`
    flex: 1;
    display: flex;
    justify-content: center;
    align-items: center;
    color: #fff;
    text-align: center;
    flex-direction: column;
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

const Image = styled.img`
    width: 200px;
    max-width: 100%;
    display: block;
    text-align: center;
    margin-left: auto;
    margin-right: auto;
    margin-bottom: 20px;
`;

const DateContainer = styled.div`
    padding-top: 15px;
`;

interface Props {
    openFileUploader;
    acceptedFiles;
    uploadModalView;
    closeUploadModal;
    setNavbarIconView;
    err;
}
export default function Gallery(props: Props) {
    const router = useRouter();
    const [collections, setCollections] = useState<collection[]>([]);
    const [
        collectionAndItsLatestFile,
        setCollectionAndItsLatestFile,
    ] = useState<CollectionAndItsLatestFile[]>([]);
    const [data, setData] = useState<file[]>();
    const [favItemIds, setFavItemIds] = useState<Set<number>>();
    const [open, setOpen] = useState(false);
    const [currentIndex, setCurrentIndex] = useState<number>(0);
    const fetching: { [k: number]: boolean } = {};
    const [bannerErrorCode, setBannerErrorCode] = useState<number>(null);
    const [sinceTime, setSinceTime] = useState(0);
    const [isFirstLoad, setIsFirstLoad] = useState(false);

    const loadingBar = useRef(null);
    useEffect(() => {
        const key = getKey(SESSION_KEYS.ENCRYPTION_KEY);
        if (!key) {
            router.push('/');
            return;
        }
        const main = async () => {
            setIsFirstLoad((await getCollectionUpdationTime()) == 0);
            const data = await localFiles();
            const collections = await getLocalCollections();
            const nonEmptyCollections = getNonEmptyCollections(
                collections,
                data
            );
            const collectionAndItsLatestFile = await getCollectionAndItsLatestFile(
                nonEmptyCollections,
                data
            );
            setData(data);
            setCollections(nonEmptyCollections);
            setCollectionAndItsLatestFile(collectionAndItsLatestFile);
            const favItemIds = await getFavItemIds(data);
            setFavItemIds(favItemIds);

            await syncWithRemote();
            setIsFirstLoad(false);
        };
        main();
        props.setNavbarIconView(true);
    }, []);

    const syncWithRemote = async () => {
        loadingBar.current?.continuousStart();
        const collections = await syncCollections();
        const { data, isUpdated } = await syncData(collections);
        const nonEmptyCollections = getNonEmptyCollections(collections, data);
        const collectionAndItsLatestFile = await getCollectionAndItsLatestFile(
            nonEmptyCollections,
            data
        );
        const favItemIds = await getFavItemIds(data);
        setCollections(nonEmptyCollections);
        if (isUpdated) {
            setData(data);
        }
        setCollectionAndItsLatestFile(collectionAndItsLatestFile);
        setFavItemIds(favItemIds);
        setSinceTime(new Date().getTime());
        loadingBar.current?.complete();
    };

    const updateUrl = (index: number) => (url: string) => {
        data[index] = {
            ...data[index],
            msrc: url,
            w: window.innerWidth,
            h: window.innerHeight,
        };
        if (
            data[index].metadata.fileType === FILE_TYPE.VIDEO &&
            !data[index].html
        ) {
            data[index].html = `
                <div class="video-loading">
                    <img src="${url}" />
                    <div class="spinner-border text-light" role="status">
                        <span class="sr-only">Loading...</span>
                    </div>
                </div>
            `;
            delete data[index].src;
        }
        if (
            data[index].metadata.fileType === FILE_TYPE.IMAGE &&
            !data[index].src
        ) {
            data[index].src = url;
        }
        setData(data);
    };

    const updateSrcUrl = (index: number, url: string) => {
        data[index] = {
            ...data[index],
            src: url,
            w: window.innerWidth,
            h: window.innerHeight,
        };
        if (data[index].metadata.fileType === FILE_TYPE.VIDEO) {
            data[index].html = `
                <video controls>
                    <source src="${url}" />
                    Your browser does not support the video tag.
                </video>
            `;
            delete data[index].src;
        }
        setData(data);
    };

    const handleClose = (needUpdate) => {
        setOpen(false);
        needUpdate && syncWithRemote();
    };

    const onThumbnailClick = (index: number) => () => {
        setCurrentIndex(index);
        setOpen(true);
    };

    const getThumbnail = (file: file[], index: number) => {
        return (
            <PreviewCard
                key={`tile-${file[index].id}`}
                data={file[index]}
                updateUrl={updateUrl(file[index].dataIndex)}
                onClick={onThumbnailClick(index)}
            />
        );
    };

    const getSlideData = async (instance: any, index: number, item: file) => {
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

    if (!data) {
        return <div />;
    }

    const selectCollection = (id?: number) => {
        const href = `/gallery?collection=${id || ''}`;
        router.push(href, undefined, { shallow: true });
    };

    let idSet = new Set();
    const filteredData = data
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
            <LoadingBar color="#2dc262" ref={loadingBar} />
            {isFirstLoad && (
                <div className="text-center">
                    <Alert variant="success">
                        {constants.INITIAL_LOAD_DELAY_WARNING}
                    </Alert>
                </div>
            )}
            <AlertBanner bannerErrorCode={bannerErrorCode} />

            <Collections
                collections={collections}
                selected={Number(router.query.collection)}
                selectCollection={selectCollection}
            />
            <Upload
                uploadModalView={props.uploadModalView}
                closeUploadModal={props.closeUploadModal}
                collectionAndItsLatestFile={collectionAndItsLatestFile}
                refetchData={syncWithRemote}
                setBannerErrorCode={setBannerErrorCode}
                acceptedFiles={props.acceptedFiles}
            />
            {!isFirstLoad && data.length == 0 ? (
                <Jumbotron>
                    <Image alt="vault" src="/vault.png" />
                    <Button variant="primary" onClick={props.openFileUploader}>
                        {constants.UPLOAD_FIRST_PHOTO}
                    </Button>
                </Jumbotron>
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
                                    const dateTimeFormat = new Intl.DateTimeFormat(
                                        'en-IN',
                                        {
                                            weekday: 'short',
                                            year: 'numeric',
                                            month: 'long',
                                            day: 'numeric',
                                        }
                                    );
                                    timeStampList.push({
                                        itemType: ITEM_TYPE.TIME,
                                        date: dateTimeFormat.format(
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
                            const extraRowsToRender = Math.ceil(
                                (NO_OF_PAGES * height) / IMAGE_CONTAINER_HEIGHT
                            );
                            return (
                                <List
                                    itemSize={(index) =>
                                        timeStampList[index].itemType ===
                                        ITEM_TYPE.TIME
                                            ? DATE_CONTAINER_HEIGHT
                                            : IMAGE_CONTAINER_HEIGHT
                                    }
                                    height={height}
                                    width={width}
                                    itemCount={timeStampList.length}
                                    key={`${router.query.collection}-${columns}-${sinceTime}`}
                                    overscanCount={extraRowsToRender}
                                >
                                    {({ index, style }) => {
                                        return (
                                            <ListItem style={style}>
                                                <ListContainer
                                                    columns={
                                                        timeStampList[index]
                                                            .itemType ===
                                                        ITEM_TYPE.TIME
                                                            ? 1
                                                            : columns
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
            {data.length < 30 && (
                <Alert
                    variant="success"
                    style={{
                        position: 'fixed',
                        bottom: '1%',
                        width: '100%',
                        textAlign: 'center',
                        marginBottom: '0px',
                    }}
                >
                    {constants.INSTALL_MOBILE_APP()}
                </Alert>
            )}
        </>
    );
}
