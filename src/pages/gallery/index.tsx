import React, {
    createContext,
    useContext,
    useEffect,
    useRef,
    useState,
} from 'react';
import { useRouter } from 'next/router';
import { clearKeys, getKey, SESSION_KEYS } from 'utils/storage/sessionStorage';
import {
    getLocalFiles,
    syncFiles,
    updateMagicMetadata,
    trashFiles,
    deleteFromTrash,
} from 'services/fileService';
import styled from 'styled-components';
import {
    syncCollections,
    getCollectionsAndTheirLatestFile,
    getFavItemIds,
    getLocalCollections,
    getNonEmptyCollections,
    createCollection,
} from 'services/collectionService';
import constants from 'utils/strings/constants';
import billingService from 'services/billingService';
import { checkSubscriptionPurchase } from 'utils/billing';

import FullScreenDropZone from 'components/FullScreenDropZone';
import Sidebar from 'components/Sidebar';
import { checkConnectivity } from 'utils/common';
import {
    isFirstLogin,
    justSignedUp,
    setIsFirstLogin,
    setJustSignedUp,
} from 'utils/storage';
import { isTokenValid, logoutUser } from 'services/userService';
import MessageDialog, { MessageAttributes } from 'components/MessageDialog';
import { useDropzone } from 'react-dropzone';
import EnteSpinner from 'components/EnteSpinner';
import { LoadingOverlay } from 'components/LoadingOverlay';
import PhotoFrame from 'components/PhotoFrame';
import {
    changeFilesVisibility,
    downloadFiles,
    getNonTrashedUniqueUserFiles,
    getSelectedFiles,
    mergeMetadata,
    sortFiles,
    sortFilesIntoCollections,
} from 'utils/file';
import SearchBar from 'components/Search';
import SelectedFileOptions from 'components/pages/gallery/SelectedFileOptions';
import CollectionSelector, {
    CollectionSelectorAttributes,
} from 'components/pages/gallery/CollectionSelector';
import CollectionNamer, {
    CollectionNamerAttributes,
} from 'components/pages/gallery/CollectionNamer';
import AlertBanner from 'components/pages/gallery/AlertBanner';
import UploadButton from 'components/pages/gallery/UploadButton';
import PlanSelector from 'components/pages/gallery/PlanSelector';
import Upload from 'components/pages/gallery/Upload';
import {
    ALL_SECTION,
    ARCHIVE_SECTION,
    CollectionType,
    TRASH_SECTION,
} from 'constants/collection';
import { AppContext } from 'pages/_app';
import { CustomError, ServerErrorCodes } from 'utils/error';
import { PAGES } from 'constants/pages';
import {
    COLLECTION_OPS_TYPE,
    isSharedCollection,
    handleCollectionOps,
    getSelectedCollection,
    isFavoriteCollection,
} from 'utils/collection';
import { logError } from 'utils/sentry';
import {
    clearLocalTrash,
    emptyTrash,
    getLocalTrash,
    getTrashedFiles,
    syncTrash,
} from 'services/trashService';
import { Trash } from 'types/trash';

import DeleteBtn from 'components/DeleteBtn';
import FixCreationTime, {
    FixCreationTimeAttributes,
} from 'components/FixCreationTime';
import { Collection, CollectionAndItsLatestFile } from 'types/collection';
import { EnteFile } from 'types/file';
import {
    GalleryContextType,
    SelectedState,
    Search,
    NotificationAttributes,
} from 'types/gallery';
import Collections from 'components/pages/gallery/Collections';
import { VISIBILITY_STATE } from 'constants/file';
import ToastNotification from 'components/ToastNotification';
import {
    clubDuplicatesByTime,
    getDuplicateFiles,
} from 'services/deduplicationService';
import ClubDuplicateFilesByTime from 'components/ClubDuplicateFilesByTime';
import BackButton from 'components/BackButton';

export const DeadCenter = styled.div`
    flex: 1;
    display: flex;
    justify-content: center;
    align-items: center;
    text-align: center;
    flex-direction: column;
`;
const AlertContainer = styled.div`
    background-color: #111;
    padding: 5px 0;
    font-size: 14px;
    text-align: center;
`;

const defaultGalleryContext: GalleryContextType = {
    thumbs: new Map(),
    files: new Map(),
    showPlanSelectorModal: () => null,
    closeMessageDialog: () => null,
    setActiveCollection: () => null,
    syncWithRemote: () => null,
    setDialogMessage: () => null,

    setNotificationAttributes: () => null,
    setBlockingLoad: () => null,
    clubSameTimeFilesOnly: false,
    setClubSameTimeFilesOnly: null,
    fileSizeMap: new Map<number, number>(),
    isDeduplicating: false,
    setIsDeduplicating: null,
};

export const GalleryContext = createContext<GalleryContextType>(
    defaultGalleryContext
);

export default function Gallery() {
    const router = useRouter();
    const [collections, setCollections] = useState<Collection[]>([]);
    const [collectionsAndTheirLatestFile, setCollectionsAndTheirLatestFile] =
        useState<CollectionAndItsLatestFile[]>([]);
    const [files, setFiles] = useState<EnteFile[]>(null);
    const [favItemIds, setFavItemIds] = useState<Set<number>>();
    const [bannerMessage, setBannerMessage] = useState<JSX.Element | string>(
        null
    );
    const [isFirstLoad, setIsFirstLoad] = useState(false);
    const [isFirstFetch, setIsFirstFetch] = useState(false);
    const [selected, setSelected] = useState<SelectedState>({
        count: 0,
        collectionID: 0,
    });
    const [dialogMessage, setDialogMessage] = useState<MessageAttributes>();
    const [messageDialogView, setMessageDialogView] = useState(false);
    const [planModalView, setPlanModalView] = useState(false);
    const [blockingLoad, setBlockingLoad] = useState(false);
    const [collectionSelectorAttributes, setCollectionSelectorAttributes] =
        useState<CollectionSelectorAttributes>(null);
    const [collectionSelectorView, setCollectionSelectorView] = useState(false);
    const [collectionNamerAttributes, setCollectionNamerAttributes] =
        useState<CollectionNamerAttributes>(null);
    const [collectionNamerView, setCollectionNamerView] = useState(false);
    const [search, setSearch] = useState<Search>({
        date: null,
        location: null,
        fileIndex: null,
    });
    const [uploadInProgress, setUploadInProgress] = useState(false);
    const {
        getRootProps,
        getInputProps,
        open: openFileUploader,
        acceptedFiles,
        fileRejections,
    } = useDropzone({
        noClick: true,
        noKeyboard: true,
        disabled: uploadInProgress,
    });

    const [isInSearchMode, setIsInSearchMode] = useState(false);
    const [searchStats, setSearchStats] = useState(null);
    const syncInProgress = useRef(true);
    const resync = useRef(false);
    const [deleted, setDeleted] = useState<number[]>([]);
    const appContext = useContext(AppContext);
    const [collectionFilesCount, setCollectionFilesCount] =
        useState<Map<number, number>>();
    const [activeCollection, setActiveCollection] = useState<number>(undefined);
    const [trash, setTrash] = useState<Trash>([]);
    const [fixCreationTimeView, setFixCreationTimeView] = useState(false);
    const [fixCreationTimeAttributes, setFixCreationTimeAttributes] =
        useState<FixCreationTimeAttributes>(null);

    const [notificationAttributes, setNotificationAttributes] =
        useState<NotificationAttributes>(null);

    const [isDeduplicating, setIsDeduplicating] = useState(false);
    const [duplicateFiles, setDuplicateFiles] = useState<EnteFile[]>([]);
    const [clubSameTimeFilesOnly, setClubSameTimeFilesOnly] = useState(false);
    const [fileSizeMap, setFileSizeMap] = useState(new Map<number, number>());

    const showPlanSelectorModal = () => setPlanModalView(true);
    const closeMessageDialog = () => setMessageDialogView(false);

    const clearNotificationAttributes = () => setNotificationAttributes(null);

    useEffect(() => {
        const key = getKey(SESSION_KEYS.ENCRYPTION_KEY);
        if (!key) {
            appContext.setRedirectURL(router.asPath);
            router.push(PAGES.ROOT);
            return;
        }
        const main = async () => {
            setActiveCollection(ALL_SECTION);
            setIsFirstLoad(isFirstLogin());
            setIsFirstFetch(true);
            if (justSignedUp()) {
                setPlanModalView(true);
            }
            setIsFirstLogin(false);
            const files = mergeMetadata(await getLocalFiles());
            const collections = await getLocalCollections();
            const trash = await getLocalTrash();
            const trashedFile = getTrashedFiles(trash);
            setFiles(sortFiles([...files, ...trashedFile]));
            setCollections(collections);
            setTrash(trash);
            await setDerivativeState(collections, files);
            await syncWithRemote(true);
            setIsFirstLoad(false);
            setJustSignedUp(false);
            setIsFirstFetch(false);
        };
        main();
        appContext.showNavBar(true);
    }, []);

    useEffect(() => {
        const main = async () => {
            if (isDeduplicating) {
                appContext.startLoading();
                let duplicates = await getDuplicateFiles();
                if (clubSameTimeFilesOnly) {
                    duplicates = clubDuplicatesByTime(duplicates);
                }

                const currFileSizeMap = new Map<number, number>();

                let allDuplicateFiles: EnteFile[] = [];
                let toSelectFileIDs: number[] = [];
                let count = 0;

                for (const dupe of duplicates) {
                    allDuplicateFiles = allDuplicateFiles.concat(dupe.files);
                    // select all except first file
                    toSelectFileIDs = toSelectFileIDs.concat(
                        dupe.files.slice(1).map((f) => f.id)
                    );
                    count += dupe.files.length - 1;

                    for (const file of dupe.files) {
                        currFileSizeMap.set(file.id, dupe.size);
                    }
                }
                setDuplicateFiles(allDuplicateFiles);
                setFileSizeMap(currFileSizeMap);

                const selectedFiles = {
                    count: count,
                    collectionID: ALL_SECTION,
                };

                for (const fileID of toSelectFileIDs) {
                    selectedFiles[fileID] = true;
                }
                setSelected(selectedFiles);
                setActiveCollection(ALL_SECTION);
                appContext.finishLoading();
            } else {
                setDuplicateFiles([]);
                setFileSizeMap(new Map<number, number>());
                setClubSameTimeFilesOnly(false);
            }
        };

        main();
    }, [isDeduplicating, clubSameTimeFilesOnly]);

    useEffect(() => setMessageDialogView(true), [dialogMessage]);

    useEffect(
        () => collectionSelectorAttributes && setCollectionSelectorView(true),
        [collectionSelectorAttributes]
    );

    useEffect(
        () => collectionNamerAttributes && setCollectionNamerView(true),
        [collectionNamerAttributes]
    );
    useEffect(
        () => fixCreationTimeAttributes && setFixCreationTimeView(true),
        [fixCreationTimeAttributes]
    );

    useEffect(() => {
        if (typeof activeCollection === 'undefined') {
            return;
        }
        let collectionURL = '';
        if (activeCollection !== ALL_SECTION) {
            collectionURL += '?collection=';
            if (activeCollection === ARCHIVE_SECTION) {
                collectionURL += constants.ARCHIVE;
            } else if (activeCollection === TRASH_SECTION) {
                collectionURL += constants.TRASH;
            } else {
                collectionURL += activeCollection;
            }
        }
        const href = `/gallery${collectionURL}`;
        router.push(href, undefined, { shallow: true });
    }, [activeCollection]);

    useEffect(() => {
        const key = getKey(SESSION_KEYS.ENCRYPTION_KEY);
        if (router.isReady && key) {
            checkSubscriptionPurchase(
                setDialogMessage,
                router,
                setBlockingLoad
            );
        }
    }, [router.isReady]);

    const syncWithRemote = async (force = false, silent = false) => {
        if (syncInProgress.current && !force) {
            resync.current = true;
            return;
        }
        syncInProgress.current = true;
        try {
            checkConnectivity();
            if (!(await isTokenValid())) {
                throw new Error(ServerErrorCodes.SESSION_EXPIRED);
            }
            !silent && appContext.startLoading();
            await billingService.syncSubscription();
            const collections = await syncCollections();
            setCollections(collections);
            const files = await syncFiles(collections, setFiles);

            await setDerivativeState(collections, files);
            const trash = await syncTrash(collections, setFiles, files);
            setTrash(trash);
        } catch (e) {
            switch (e.message) {
                case ServerErrorCodes.SESSION_EXPIRED:
                    setBannerMessage(constants.SESSION_EXPIRED_MESSAGE);
                    setDialogMessage({
                        title: constants.SESSION_EXPIRED,
                        content: constants.SESSION_EXPIRED_MESSAGE,
                        staticBackdrop: true,
                        nonClosable: true,
                        proceed: {
                            text: constants.LOGIN,
                            action: logoutUser,
                            variant: 'success',
                        },
                    });
                    break;
                case CustomError.KEY_MISSING:
                    clearKeys();
                    router.push(PAGES.CREDENTIALS);
                    break;
            }
        } finally {
            !silent && appContext.finishLoading();
        }
        syncInProgress.current = false;
        if (resync.current) {
            resync.current = false;
            syncWithRemote();
        }
    };

    const setDerivativeState = async (
        collections: Collection[],
        files: EnteFile[]
    ) => {
        const favItemIds = await getFavItemIds(files);
        setFavItemIds(favItemIds);
        const nonEmptyCollections = getNonEmptyCollections(collections, files);
        setCollections(nonEmptyCollections);
        const collectionsAndTheirLatestFile = getCollectionsAndTheirLatestFile(
            nonEmptyCollections,
            files
        );
        setCollectionsAndTheirLatestFile(collectionsAndTheirLatestFile);
        const collectionWiseFiles = sortFilesIntoCollections(files);
        const collectionFilesCount = new Map<number, number>();
        for (const [id, files] of collectionWiseFiles) {
            collectionFilesCount.set(id, files.length);
        }
        setCollectionFilesCount(collectionFilesCount);
    };

    const clearSelection = function () {
        setSelected({ count: 0, collectionID: 0 });
    };

    if (!files) {
        return <div />;
    }
    const collectionOpsHelper =
        (ops: COLLECTION_OPS_TYPE) => async (collection: Collection) => {
            appContext.startLoading();
            try {
                await handleCollectionOps(
                    ops,
                    setCollectionSelectorView,
                    selected,
                    files,
                    setActiveCollection,
                    collection
                );
                clearSelection();
            } catch (e) {
                logError(e, 'collection ops failed', { ops });
                setDialogMessage({
                    title: constants.ERROR,
                    staticBackdrop: true,
                    close: { variant: 'danger' },
                    content: constants.UNKNOWN_ERROR,
                });
            } finally {
                await syncWithRemote(false, true);
                appContext.finishLoading();
            }
        };

    const changeFilesVisibilityHelper = async (
        visibility: VISIBILITY_STATE
    ) => {
        appContext.startLoading();
        try {
            const updatedFiles = await changeFilesVisibility(
                files,
                selected,
                visibility
            );
            await updateMagicMetadata(updatedFiles);
            clearSelection();
        } catch (e) {
            logError(e, 'change file visibility failed');
            switch (e.status?.toString()) {
                case ServerErrorCodes.FORBIDDEN:
                    setDialogMessage({
                        title: constants.ERROR,
                        staticBackdrop: true,
                        close: { variant: 'danger' },
                        content: constants.NOT_FILE_OWNER,
                    });
                    return;
            }
            setDialogMessage({
                title: constants.ERROR,
                staticBackdrop: true,
                close: { variant: 'danger' },
                content: constants.UNKNOWN_ERROR,
            });
        } finally {
            await syncWithRemote(false, true);
            appContext.finishLoading();
        }
    };

    const showCreateCollectionModal = (ops: COLLECTION_OPS_TYPE) => {
        const callback = async (collectionName: string) => {
            try {
                const collection = await createCollection(
                    collectionName,
                    CollectionType.album,
                    collections
                );

                await collectionOpsHelper(ops)(collection);
            } catch (e) {
                logError(e, 'create and collection ops failed');
                setDialogMessage({
                    title: constants.ERROR,
                    staticBackdrop: true,
                    close: { variant: 'danger' },
                    content: constants.UNKNOWN_ERROR,
                });
            }
        };
        return () =>
            setCollectionNamerAttributes({
                title: constants.CREATE_COLLECTION,
                buttonText: constants.CREATE,
                autoFilledName: '',
                callback,
            });
    };

    const deleteFileHelper = async (permanent?: boolean) => {
        appContext.startLoading();
        try {
            const selectedFiles = getSelectedFiles(selected, files);
            if (permanent) {
                await deleteFromTrash(selectedFiles.map((file) => file.id));
                setDeleted([
                    ...deleted,
                    ...selectedFiles.map((file) => file.id),
                ]);
            } else {
                await trashFiles(selectedFiles);
            }
            clearSelection();
        } catch (e) {
            switch (e.status?.toString()) {
                case ServerErrorCodes.FORBIDDEN:
                    setDialogMessage({
                        title: constants.ERROR,
                        staticBackdrop: true,
                        close: { variant: 'danger' },
                        content: constants.NOT_FILE_OWNER,
                    });
            }
            setDialogMessage({
                title: constants.ERROR,
                staticBackdrop: true,
                close: { variant: 'danger' },
                content: constants.UNKNOWN_ERROR,
            });
        } finally {
            await syncWithRemote(false, true);
            appContext.finishLoading();
        }
    };

    const updateSearch = (newSearch: Search) => {
        setActiveCollection(ALL_SECTION);
        setSearch(newSearch);
        setSearchStats(null);
    };

    const closeCollectionSelector = (closeBtnClick?: boolean) => {
        if (closeBtnClick === true) {
            appContext.resetSharedFiles();
        }
        setCollectionSelectorView(false);
    };

    const emptyTrashHandler = () =>
        setDialogMessage({
            title: constants.CONFIRM_EMPTY_TRASH,
            content: constants.EMPTY_TRASH_MESSAGE,
            staticBackdrop: true,
            proceed: {
                action: emptyTrashHelper,
                text: constants.EMPTY_TRASH,
                variant: 'danger',
            },
            close: { text: constants.CANCEL },
        });
    const emptyTrashHelper = async () => {
        appContext.startLoading();
        try {
            await emptyTrash();
            if (selected.collectionID === TRASH_SECTION) {
                clearSelection();
            }
            await clearLocalTrash();
            setActiveCollection(ALL_SECTION);
        } catch (e) {
            setDialogMessage({
                title: constants.ERROR,
                staticBackdrop: true,
                close: { variant: 'danger' },
                content: constants.UNKNOWN_ERROR,
            });
        } finally {
            await syncWithRemote(false, true);
            appContext.finishLoading();
        }
    };

    const fixTimeHelper = async () => {
        const selectedFiles = getSelectedFiles(selected, files);
        setFixCreationTimeAttributes({ files: selectedFiles });
        clearSelection();
    };

    const downloadHelper = async () => {
        const selectedFiles = getSelectedFiles(selected, files);
        clearSelection();
        appContext.startLoading();
        await downloadFiles(selectedFiles);
        appContext.finishLoading();
    };

    return (
        <GalleryContext.Provider
            value={{
                ...defaultGalleryContext,
                showPlanSelectorModal,
                closeMessageDialog,
                setActiveCollection,
                syncWithRemote,
                setDialogMessage,

                setNotificationAttributes,
                setBlockingLoad,
                clubSameTimeFilesOnly,
                setClubSameTimeFilesOnly,
                fileSizeMap,
                setIsDeduplicating: setIsDeduplicating,
                isDeduplicating: isDeduplicating,
            }}>
            <FullScreenDropZone
                getRootProps={getRootProps}
                getInputProps={getInputProps}>
                <AlertBanner bannerMessage={bannerMessage} />
                <ToastNotification
                    attributes={notificationAttributes}
                    clearAttributes={clearNotificationAttributes}
                />
                <MessageDialog
                    size="lg"
                    show={messageDialogView}
                    onHide={closeMessageDialog}
                    attributes={dialogMessage}
                />
                <Upload
                    syncWithRemote={syncWithRemote}
                    setBannerMessage={setBannerMessage}
                    acceptedFiles={acceptedFiles}
                    showCollectionSelector={setCollectionSelectorView.bind(
                        null,
                        true
                    )}
                    setCollectionSelectorAttributes={
                        setCollectionSelectorAttributes
                    }
                    closeCollectionSelector={setCollectionSelectorView.bind(
                        null,
                        false
                    )}
                    setLoading={setBlockingLoad}
                    setCollectionNamerAttributes={setCollectionNamerAttributes}
                    setDialogMessage={setDialogMessage}
                    setUploadInProgress={setUploadInProgress}
                    fileRejections={fileRejections}
                    setFiles={setFiles}
                    isFirstUpload={collectionsAndTheirLatestFile?.length === 0}
                />
                {!isDeduplicating && (
                    <>
                        <SearchBar
                            isOpen={isInSearchMode}
                            setOpen={setIsInSearchMode}
                            isFirstFetch={isFirstFetch}
                            collections={collections}
                            files={getNonTrashedUniqueUserFiles(files)}
                            setActiveCollection={setActiveCollection}
                            setSearch={updateSearch}
                            searchStats={searchStats}
                        />
                        <Collections
                            collections={collections}
                            collectionAndTheirLatestFile={
                                collectionsAndTheirLatestFile
                            }
                            isInSearchMode={isInSearchMode}
                            activeCollection={activeCollection}
                            setActiveCollection={setActiveCollection}
                            syncWithRemote={syncWithRemote}
                            setDialogMessage={setDialogMessage}
                            setCollectionNamerAttributes={
                                setCollectionNamerAttributes
                            }
                            collectionFilesCount={collectionFilesCount}
                        />
                    </>
                )}
                {blockingLoad && (
                    <LoadingOverlay>
                        <EnteSpinner />
                    </LoadingOverlay>
                )}
                {isFirstLoad && (
                    <AlertContainer>
                        {constants.INITIAL_LOAD_DELAY_WARNING}
                    </AlertContainer>
                )}
                <PlanSelector
                    modalView={planModalView}
                    closeModal={() => setPlanModalView(false)}
                    setDialogMessage={setDialogMessage}
                    setLoading={setBlockingLoad}
                />
                <CollectionNamer
                    show={collectionNamerView}
                    onHide={setCollectionNamerView.bind(null, false)}
                    attributes={collectionNamerAttributes}
                />
                <CollectionSelector
                    show={collectionSelectorView}
                    onHide={closeCollectionSelector}
                    collectionsAndTheirLatestFile={
                        collectionsAndTheirLatestFile
                    }
                    attributes={collectionSelectorAttributes}
                />
                <FixCreationTime
                    isOpen={fixCreationTimeView}
                    hide={() => setFixCreationTimeView(false)}
                    show={() => setFixCreationTimeView(true)}
                    attributes={fixCreationTimeAttributes}
                />

                {isDeduplicating ? (
                    <>
                        <BackButton setIsDeduplicating={setIsDeduplicating} />
                        <ClubDuplicateFilesByTime />
                    </>
                ) : (
                    <>
                        <UploadButton
                            isFirstFetch={isFirstFetch}
                            openFileUploader={openFileUploader}
                        />
                        <Sidebar
                            collections={collections}
                            setDialogMessage={setDialogMessage}
                            setLoading={setBlockingLoad}
                        />
                    </>
                )}

                <PhotoFrame
                    files={isDeduplicating ? duplicateFiles : files}
                    setFiles={isDeduplicating ? setDuplicateFiles : setFiles}
                    syncWithRemote={syncWithRemote}
                    favItemIds={favItemIds}
                    setSelected={setSelected}
                    selected={selected}
                    isFirstLoad={isFirstLoad}
                    openFileUploader={openFileUploader}
                    isInSearchMode={isInSearchMode}
                    search={search}
                    setSearchStats={setSearchStats}
                    deleted={deleted}
                    activeCollection={activeCollection}
                    isSharedCollection={isSharedCollection(
                        activeCollection,
                        collections
                    )}
                    enableDownload={true}
                />

                {selected.count > 0 &&
                    selected.collectionID === activeCollection && (
                        <SelectedFileOptions
                            addToCollectionHelper={collectionOpsHelper(
                                COLLECTION_OPS_TYPE.ADD
                            )}
                            archiveFilesHelper={() =>
                                changeFilesVisibilityHelper(
                                    VISIBILITY_STATE.ARCHIVED
                                )
                            }
                            unArchiveFilesHelper={() =>
                                changeFilesVisibilityHelper(
                                    VISIBILITY_STATE.VISIBLE
                                )
                            }
                            moveToCollectionHelper={collectionOpsHelper(
                                COLLECTION_OPS_TYPE.MOVE
                            )}
                            restoreToCollectionHelper={collectionOpsHelper(
                                COLLECTION_OPS_TYPE.RESTORE
                            )}
                            showCreateCollectionModal={
                                showCreateCollectionModal
                            }
                            setDialogMessage={setDialogMessage}
                            setCollectionSelectorAttributes={
                                setCollectionSelectorAttributes
                            }
                            deleteFileHelper={deleteFileHelper}
                            removeFromCollectionHelper={() =>
                                collectionOpsHelper(COLLECTION_OPS_TYPE.REMOVE)(
                                    getSelectedCollection(
                                        activeCollection,
                                        collections
                                    )
                                )
                            }
                            fixTimeHelper={fixTimeHelper}
                            downloadHelper={downloadHelper}
                            count={selected.count}
                            clearSelection={clearSelection}
                            activeCollection={activeCollection}
                            isFavoriteCollection={isFavoriteCollection(
                                activeCollection,
                                collections
                            )}
                        />
                    )}
                {activeCollection === TRASH_SECTION && trash?.length > 0 && (
                    <DeleteBtn onClick={emptyTrashHandler} />
                )}
            </FullScreenDropZone>
        </GalleryContext.Provider>
    );
}
