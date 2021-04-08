import React, { useEffect, useRef, useState } from 'react';
import { useRouter } from 'next/router';
import { getKey, SESSION_KEYS } from 'utils/storage/sessionStorage';
import { file, syncData, localFiles, deleteFiles } from 'services/fileService';
import PreviewCard from './components/PreviewCard';
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
import { Alert, Button, Jumbotron } from 'react-bootstrap';
import billingService from 'services/billingService';
import PlanSelector from './components/PlanSelector';
import { isSubscribed } from 'utils/billingUtil';

import Delete from 'components/Delete';
import ConfirmDialog, { CONFIRM_ACTION } from 'components/ConfirmDialog';
import FullScreenDropZone from 'components/FullScreenDropZone';
import Sidebar from 'components/Sidebar';
import UploadButton from './components/UploadButton';
import { checkConnectivity } from 'utils/common';
import { isFirstLogin, setIsFirstLogin } from 'utils/storage';
import { logoutUser } from 'services/userService';
import AlertBanner from './components/AlertBanner';
import MessageDialog, { MessageAttributes } from 'components/MessageDialog';
const DATE_CONTAINER_HEIGHT = 45;
const IMAGE_CONTAINER_HEIGHT = 200;
const NO_OF_PAGES = 2;
const A_DAY = 24 * 60 * 60 * 1000;
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

const DateContainer = styled.div`
    padding-top: 15px;
`;

interface Props {
    getRootProps;
    getInputProps;
    openFileUploader;
    acceptedFiles;
    collectionSelectorView;
    closeCollectionSelector;
    showCollectionSelector;
    err;
}

const DeleteBtn = styled.button`
    border: none;
    background-color: #ff6666;
    position: fixed;
    z-index: 1;
    bottom: 20px;
    right: 20px;
    width: 60px;
    height: 60px;
    border-radius: 50%;
    color: #fff;
`;

export type selectedState = {
    [k: number]: boolean;
    count: number;
};

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
    const [bannerMessage, setBannerMessage] = useState<string>(null);
    const [sinceTime, setSinceTime] = useState(0);
    const [isFirstLoad, setIsFirstLoad] = useState(false);
    const [selected, setSelected] = useState<selectedState>({ count: 0 });
    const [confirmAction, setConfirmAction] = useState<CONFIRM_ACTION>(null);
    const [dialogMessage, setDialogMessage] = useState<MessageAttributes>();
    const [planModalView, setPlanModalView] = useState(false);

    const loadingBar = useRef(null);
    useEffect(() => {
        const key = getKey(SESSION_KEYS.ENCRYPTION_KEY);
        if (!key) {
            router.push('/');
            return;
        }
        const main = async () => {
            setIsFirstLoad(isFirstLogin());
            setIsFirstLogin(false);
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
    }, []);

    const syncWithRemote = async () => {
        try {
            checkConnectivity();
            loadingBar.current?.continuousStart();
            const collections = await syncCollections();
            const { data, isUpdated } = await syncData(collections);
            await billingService.updatePlans();
            await billingService.syncSubscription();
            const nonEmptyCollections = getNonEmptyCollections(
                collections,
                data
            );
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
        } catch (e) {
            setBannerMessage(e.message);
            if (e.message === constants.SESSION_EXPIRED_MESSAGE) {
                setConfirmAction(CONFIRM_ACTION.SESSION_EXPIRED);
            }
        } finally {
            loadingBar.current?.complete();
        }
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

    const handleSelect = (id: number) => (checked: boolean) => {
        setSelected({
            ...selected,
            [id]: checked,
            count: checked ? selected.count + 1 : selected.count - 1,
        });
    };

    const getThumbnail = (file: file[], index: number) => {
        return (
            <PreviewCard
                key={`tile-${file[index].id}`}
                data={file[index]}
                updateUrl={updateUrl(file[index].dataIndex)}
                onClick={onThumbnailClick(index)}
                selectable
                onSelect={handleSelect(file[index].id)}
                selected={selected[file[index].id]}
                selectOnClick={selected.count > 0}
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
    const confirmCallbacks = new Map<CONFIRM_ACTION, Function>([
        [
            CONFIRM_ACTION.DELETE,
            async function () {
                await deleteFiles(selected);
                syncWithRemote();
                setConfirmAction(null);
                setSelected({ count: 0 });
            },
        ],
        [CONFIRM_ACTION.SESSION_EXPIRED, logoutUser],
        [CONFIRM_ACTION.LOGOUT, logoutUser],
        [
            CONFIRM_ACTION.DOWNLOAD_APP,
            function () {
                var win = window.open(constants.APP_DOWNLOAD_URL, '_blank');
                win.focus();
                setConfirmAction(null);
            },
        ],
        [
            CONFIRM_ACTION.CANCEL_SUBSCRIPTION,
            async function () {
                try {
                    await billingService.cancelSubscription();
                    setDialogMessage({
                        title: constants.SUBSCRIPTION_CANCEL_SUCCESS,
                        close: { variant: 'success' },
                    });
                } catch (e) {
                    setDialogMessage({
                        title: constants.SUBSCRIPTION_CANCEL_FAILED,
                        close: { variant: 'danger' },
                    });
                }
                setConfirmAction(null);
            },
        ],
        [
            CONFIRM_ACTION.UPDATE_PAYMENT_METHOD,
            async function (event) {
                try {
                    event.preventDefault();
                    await billingService.redirectToCustomerPortal();
                } catch (error) {
                    setDialogMessage({
                        title: constants.UNKNOWN_ERROR,
                        close: { variant: 'danger' },
                    });
                }
                setConfirmAction(null);
            },
        ],
    ]);

    return (
        <FullScreenDropZone
            getRootProps={props.getRootProps}
            getInputProps={props.getInputProps}
            showCollectionSelector={props.showCollectionSelector}
        >
            <LoadingBar color="#2dc262" ref={loadingBar} />
            {isFirstLoad && (
                <div className="text-center">
                    <Alert variant="success">
                        {constants.INITIAL_LOAD_DELAY_WARNING}
                    </Alert>
                </div>
            )}
            {!isSubscribed() && (
                <Button
                    id="checkout"
                    variant="success"
                    size="lg"
                    block
                    onClick={() => setPlanModalView(true)}
                >
                    {constants.SUBSCRIBE}
                </Button>
            )}
            <PlanSelector
                modalView={planModalView}
                closeModal={() => setPlanModalView(false)}
                setDialogMessage={setDialogMessage}
                setConfirmAction={setConfirmAction}
            />
            <AlertBanner bannerMessage={bannerMessage} />
            <ConfirmDialog
                show={confirmAction !== null}
                onHide={() => setConfirmAction(null)}
                callback={confirmCallbacks.get(confirmAction)}
                action={confirmAction}
            />
            <MessageDialog
                show={dialogMessage != null}
                onHide={() => setDialogMessage(null)}
                attributes={dialogMessage}
            />
            <Collections
                collections={collections}
                selected={Number(router.query.collection)}
                selectCollection={selectCollection}
            />
            <Upload
                collectionSelectorView={props.collectionSelectorView}
                closeCollectionSelector={props.closeCollectionSelector}
                collectionAndItsLatestFile={collectionAndItsLatestFile}
                refetchData={syncWithRemote}
                setBannerMessage={setBannerMessage}
                acceptedFiles={props.acceptedFiles}
            />
            <Sidebar
                files={data}
                collections={collections}
                setConfirmAction={setConfirmAction}
                somethingWentWrong={() =>
                    setDialogMessage({
                        title: constants.UNKNOWN_ERROR,
                        close: { variant: 'danger' },
                    })
                }
                setPlanModalView={setPlanModalView}
                setBannerMessage={setBannerMessage}
            />
            <UploadButton openFileUploader={props.openFileUploader} />
            {!isFirstLoad && data.length == 0 ? (
                <div
                    style={{
                        height: '60%',
                        display: 'grid',
                        placeItems: 'center',
                    }}
                >
                    <Button
                        variant="outline-success"
                        onClick={props.openFileUploader}
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
            {selected.count && (
                <DeleteBtn
                    onClick={() => setConfirmAction(CONFIRM_ACTION.DELETE)}
                >
                    <Delete />
                </DeleteBtn>
            )}
        </FullScreenDropZone>
    );
}
