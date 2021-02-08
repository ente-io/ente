import React, { useEffect, useState } from 'react';
import { useRouter } from 'next/router';
import Spinner from 'react-bootstrap/Spinner';
import { getKey, SESSION_KEYS } from 'utils/storage/sessionStorage';
import {
    file,
    getFile,
    getPreview,
    fetchData,
    localFiles,
} from 'services/fileService';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import PreviewCard from './components/PreviewCard';
import { getActualKey, getToken } from 'utils/common/key';
import styled from 'styled-components';
import PhotoSwipe from 'components/PhotoSwipe/PhotoSwipe';
import { Options } from 'photoswipe';
import AutoSizer from 'react-virtualized-auto-sizer';
import { VariableSizeList as List } from 'react-window';
import LoadingBar from 'react-top-loading-bar'
import Collections from './components/Collections';
import Upload from './components/Upload';
import {
    collection,
    fetchUpdatedCollections,
    collectionLatestFile,
    getCollectionLatestFile,
    getFavItemIds,
    getLocalCollections
} from 'services/collectionService';
import constants from 'utils/strings/constants';

enum ITEM_TYPE {
    TIME = 'TIME',
    TILE = 'TILE',
}
export enum FILE_TYPE {
    IMAGE,
    VIDEO,
    OTHERS
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

const ListContainer = styled.div<{columns: number}>`
    display: grid;
    grid-template-columns: repeat(${props => props.columns}, 1fr);
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

export default function Gallery(props) {
    const router = useRouter();
    const [loading, setLoading] = useState(false);
    const [collections, setCollections] = useState<collection[]>([]);
    const [collectionLatestFile, setCollectionLatestFile] = useState<
        collectionLatestFile[]
    >([]);
    const [data, setData] = useState<file[]>();
    const [favItemIds, setFavItemIds] = useState<Set<number>>();
    const [open, setOpen] = useState(false);
    const [options, setOptions] = useState<Options>({
        history: false,
        maxSpreadZoom: 5,
    });
    const fetching: { [k: number]: boolean } = {};
    const [sinceTime, setSinceTime] = useState(0);

    const [progress, setProgress] = useState(0)

    useEffect(() => {
        const key = getKey(SESSION_KEYS.ENCRYPTION_KEY);
        if (!key) {
            router.push('/');
        }
        const main = async () => {
            setLoading(true);
            const data = await localFiles();
            const collections = await getLocalCollections();
            setData(data);
            setCollections(collections);
            setLoading(false);
            setProgress(80);
            await syncWithRemote();
            setProgress(100);
        };
        main();
        props.setUploadButtonView(true);
    }, []);

    const syncWithRemote = async () => {
        const token = getToken();
        const encryptionKey = await getActualKey();
        const updatedCollections = await fetchUpdatedCollections(token, encryptionKey);
        const data = await fetchData(token, updatedCollections);
        const collections = await getLocalCollections();
        const collectionLatestFile = await getCollectionLatestFile(collections, data);
        const favItemIds = await getFavItemIds(data);
        if (updatedCollections.length > 0) {
            setCollections(collections);
            setData(data);
        }
        setCollectionLatestFile(collectionLatestFile);
        setFavItemIds(favItemIds);
        setSinceTime((new Date()).getTime());
        props.setUploadButtonView(true);
    }

    const updateUrl = (index: number) => (url: string) => {
        data[index] = {
            ...data[index],
            msrc: url,
            w: window.innerWidth,
            h: window.innerHeight,
        };
        if (data[index].metadata.fileType === FILE_TYPE.VIDEO && !data[index].html) {
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
        if (data[index].metadata.fileType === FILE_TYPE.IMAGE && !data[index].src) {
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

    const handleClose = () => {
        setOpen(false);
        // syncWithRemote();
    };

    const onThumbnailClick = (index: number) => () => {
        setOptions({
            ...options,
            index,
        });
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
        const token = getData(LS_KEYS.USER).token;
        if (!item.msrc) {
            const url = await getPreview(token, item);
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
        if ((!item.src || item.src === item.msrc) && !fetching[item.dataIndex]) {
            fetching[item.dataIndex] = true;
            const url = await getFile(token, item);
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

    if (!data || loading) {
        return (
            <div className='text-center'>
                <Spinner animation='border' variant='primary' />
            </div>
        );
    }

    const selectCollection = (id?: string) => {
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
            <LoadingBar
                color='#007bff'
                progress={progress}
                onLoaderFinished={() => setProgress(0)}
            />
            <Collections
                collections={collections}
                selected={router.query.collection?.toString()}
                selectCollection={selectCollection}
            />
            <Upload
                uploadModalView={props.uploadModalView}
                closeUploadModal={props.closeUploadModal}
                showUploadModal={props.showUploadModal}
                collectionLatestFile={collectionLatestFile}
                refetchData={syncWithRemote}

            />
            {filteredData.length ? (
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
                                        new Date(item.metadata.creationTime / 1000),
                                        new Date(currentDate)
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
                                        date: dateTimeFormat.format(currentDate),
                                    });
                                    timeStampList.push({
                                        itemType: ITEM_TYPE.TILE,
                                        items: [item],
                                        itemStartIndex: index,
                                    });
                                    listItemIndex = 1;
                                } else {
                                    if (listItemIndex < columns) {
                                        timeStampList[timeStampList.length - 1].items.push(item);
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

                            return (
                                <List
                                    itemSize={(index) =>
                                        timeStampList[index].itemType === ITEM_TYPE.TIME
                                            ? 45
                                            : 200
                                    }
                                    height={height}
                                    width={width}
                                    itemCount={timeStampList.length}
                                    key={`${router.query.collection}-${columns}-${sinceTime}`}
                                >
                                    {({ index, style }) => {
                                        return (<ListItem style={style}>
                                            <ListContainer columns={timeStampList[index].itemType === ITEM_TYPE.TIME
                                                ? 1 : columns}>
                                                {
                                                    timeStampList[index].itemType === ITEM_TYPE.TIME
                                                        ? <DateContainer>{timeStampList[index].date}</DateContainer>
                                                        : timeStampList[index].items.map((item, idx) =>{
                                                            return getThumbnail(filteredData, timeStampList[index].itemStartIndex + idx);
                                                        })
                                                }
                                            </ListContainer>
                                        </ListItem>);
                                    }}
                                </List>
                            );
                        }}
                    </AutoSizer>
                    <PhotoSwipe
                        isOpen={open}
                        items={filteredData}
                        options={options}
                        onClose={handleClose}
                        gettingData={getSlideData}
                        favItemIds={favItemIds}
                        setFavItemIds={setFavItemIds}
                    />
                </Container>
            ) : (
                    <DeadCenter>
                        <div>{constants.NOTHING_HERE}</div>
                    </DeadCenter>
                )}
        </>
    );
}
