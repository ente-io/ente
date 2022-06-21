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
    updateFileMagicMetadata,
    trashFiles,
    deleteFromTrash,
} from 'services/fileService';
import { styled } from '@mui/material';
import {
    syncCollections,
    getFavItemIds,
    getLocalCollections,
    createCollection,
    getCollectionSummaries,
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
} from 'utils/file';
import SelectedFileOptions from 'components/pages/gallery/SelectedFileOptions';
import CollectionSelector, {
    CollectionSelectorAttributes,
} from 'components/pages/gallery/CollectionSelector';
import CollectionNamer, {
    CollectionNamerAttributes,
} from 'components/Collections/CollectionNamer';
import AlertBanner from 'components/pages/gallery/AlertBanner';
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
    getArchivedCollections,
    hasNonEmptyCollections,
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
import { Collection, CollectionSummaries } from 'types/collection';
import { EnteFile } from 'types/file';
import { GalleryContextType, SelectedState } from 'types/gallery';
import { VISIBILITY_STATE } from 'types/magicMetadata';
import Notification from 'components/Notification';
import { ElectronFile } from 'types/upload';
import importService from 'services/importService';
import Collections from 'components/Collections';
import { GalleryNavbar } from 'components/pages/gallery/Navbar';
import { Search, SearchResultSummary, UpdateSearch } from 'types/search';
import SearchResultInfo from 'components/Search/SearchResultInfo';
import { NotificationAttributes } from 'types/Notification';
import { ITEM_TYPE, TimeStampListItem } from 'components/PhotoList';

export const DeadCenter = styled('div')`
    flex: 1;
    display: flex;
    justify-content: center;
    align-items: center;
    text-align: center;
    flex-direction: column;
`;
const AlertContainer = styled('div')`
    background-color: #111;
    padding: 5px 0;
    font-size: 14px;
    text-align: center;
`;

const defaultGalleryContext: GalleryContextType = {
    thumbs: new Map(),
    files: new Map(),
    showPlanSelectorModal: () => null,
    setActiveCollection: () => null,
    syncWithRemote: () => null,
    setNotificationAttributes: () => null,
    setBlockingLoad: () => null,
    photoListHeader: null,
};

export const GalleryContext = createContext<GalleryContextType>(
    defaultGalleryContext
);

export default function Gallery() {
    const router = useRouter();
    const [collections, setCollections] = useState<Collection[]>(null);

    const [files, setFiles] = useState<EnteFile[]>(null);
    const [favItemIds, setFavItemIds] = useState<Set<number>>();
    const [bannerMessage, setBannerMessage] = useState<JSX.Element | string>();
    const [isFirstLoad, setIsFirstLoad] = useState(false);
    const [isFirstFetch, setIsFirstFetch] = useState(false);
    const [selected, setSelected] = useState<SelectedState>({
        count: 0,
        collectionID: 0,
    });
    const [planModalView, setPlanModalView] = useState(false);
    const [blockingLoad, setBlockingLoad] = useState(false);
    const [collectionSelectorAttributes, setCollectionSelectorAttributes] =
        useState<CollectionSelectorAttributes>(null);
    const [collectionSelectorView, setCollectionSelectorView] = useState(false);
    const [collectionNamerAttributes, setCollectionNamerAttributes] =
        useState<CollectionNamerAttributes>(null);
    const [collectionNamerView, setCollectionNamerView] = useState(false);
    const [search, setSearch] = useState<Search>(null);
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
    const [searchResultSummary, setSetSearchResultSummary] =
        useState<SearchResultSummary>(null);
    const syncInProgress = useRef(true);
    const resync = useRef(false);
    const [deleted, setDeleted] = useState<number[]>([]);
    const { startLoading, finishLoading, setDialogMessage, ...appContext } =
        useContext(AppContext);
    const [collectionSummaries, setCollectionSummaries] =
        useState<CollectionSummaries>();
    const [activeCollection, setActiveCollection] = useState<number>(undefined);
    const [trash, setTrash] = useState<Trash>([]);
    const [fixCreationTimeView, setFixCreationTimeView] = useState(false);
    const [fixCreationTimeAttributes, setFixCreationTimeAttributes] =
        useState<FixCreationTimeAttributes>(null);

    const [notificationView, setNotificationView] = useState(false);

    const closeNotification = () => setNotificationView(false);

    const [notificationAttributes, setNotificationAttributes] =
        useState<NotificationAttributes>(null);

    const [archivedCollections, setArchivedCollections] =
        useState<Set<number>>();

    const showPlanSelectorModal = () => setPlanModalView(true);

    const [electronFiles, setElectronFiles] = useState<ElectronFile[]>(null);
    const [uploadTypeSelectorView, setUploadTypeSelectorView] = useState(false);

    const [sidebarView, setSidebarView] = useState(false);

    const closeSidebar = () => setSidebarView(false);
    const openSidebar = () => setSidebarView(true);
    const [droppedFiles, setDroppedFiles] = useState([]);
    const [photoListHeader, setPhotoListHeader] =
        useState<TimeStampListItem>(null);

    const showSessionExpiredMessage = () =>
        setDialogMessage({
            title: constants.SESSION_EXPIRED,
            content: constants.SESSION_EXPIRED_MESSAGE,

            nonClosable: true,
            proceed: {
                text: constants.LOGIN,
                action: logoutUser,
                variant: 'accent',
            },
        });

    useEffect(() => {
        appContext.showNavBar(false);
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
            files.push(...getTrashedFiles(trash));
            setFiles(sortFiles(files));
            setCollections(collections);
            setTrash(trash);
            await syncWithRemote(true);
            setIsFirstLoad(false);
            setJustSignedUp(false);
            setIsFirstFetch(false);
        };
        main();
    }, []);

    useEffect(() => {
        setDerivativeState(collections, files);
    }, [collections, files]);

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

    useEffect(
        () => notificationAttributes && setNotificationView(true),
        [notificationAttributes]
    );

    useEffect(() => setDroppedFiles(acceptedFiles), [acceptedFiles]);

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

    useEffect(() => {
        if (isInSearchMode && searchResultSummary) {
            setPhotoListHeader({
                height: 104,
                item: (
                    <SearchResultInfo
                        searchResultSummary={searchResultSummary}
                    />
                ),
                itemType: ITEM_TYPE.STATIC,
            });
        }
    }, [isInSearchMode, searchResultSummary]);

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
            !silent && startLoading();
            await billingService.syncSubscription();
            const collections = await syncCollections();
            setCollections(collections);
            const files = await syncFiles(collections, setFiles);
            const trash = await syncTrash(collections, setFiles, files);
            setTrash(trash);
            files.push(...getTrashedFiles(trash));
        } catch (e) {
            logError(e, 'syncWithRemote failed');
            switch (e.message) {
                case ServerErrorCodes.SESSION_EXPIRED:
                    showSessionExpiredMessage();
                    break;
                case CustomError.KEY_MISSING:
                    clearKeys();
                    router.push(PAGES.CREDENTIALS);
                    break;
            }
        } finally {
            !silent && finishLoading();
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
        if (!collections || !files) {
            return;
        }
        const favItemIds = await getFavItemIds(files);
        setFavItemIds(favItemIds);
        const archivedCollections = getArchivedCollections(collections);
        setArchivedCollections(archivedCollections);

        const collectionSummaries = getCollectionSummaries(
            collections,
            files,
            archivedCollections
        );
        setCollectionSummaries(collectionSummaries);
    };

    const clearSelection = function () {
        setSelected({ count: 0, collectionID: 0 });
    };

    if (!files || !collectionSummaries) {
        return <div />;
    }
    const collectionOpsHelper =
        (ops: COLLECTION_OPS_TYPE) => async (collection: Collection) => {
            startLoading();
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

                    close: { variant: 'danger' },
                    content: constants.UNKNOWN_ERROR,
                });
            } finally {
                await syncWithRemote(false, true);
                finishLoading();
            }
        };

    const changeFilesVisibilityHelper = async (
        visibility: VISIBILITY_STATE
    ) => {
        startLoading();
        try {
            const updatedFiles = await changeFilesVisibility(
                files,
                selected,
                visibility
            );
            await updateFileMagicMetadata(updatedFiles);
            clearSelection();
        } catch (e) {
            logError(e, 'change file visibility failed');
            switch (e.status?.toString()) {
                case ServerErrorCodes.FORBIDDEN:
                    setDialogMessage({
                        title: constants.ERROR,

                        close: { variant: 'danger' },
                        content: constants.NOT_FILE_OWNER,
                    });
                    return;
            }
            setDialogMessage({
                title: constants.ERROR,

                close: { variant: 'danger' },
                content: constants.UNKNOWN_ERROR,
            });
        } finally {
            await syncWithRemote(false, true);
            finishLoading();
        }
    };

    const showCreateCollectionModal = (ops?: COLLECTION_OPS_TYPE) => {
        const callback = async (collectionName: string) => {
            try {
                startLoading();
                const collection = await createCollection(
                    collectionName,
                    CollectionType.album,
                    collections
                );
                if (ops) {
                    await collectionOpsHelper(ops)(collection);
                }
            } catch (e) {
                logError(e, 'create and collection ops failed', { ops });
                setDialogMessage({
                    title: constants.ERROR,

                    close: { variant: 'danger' },
                    content: constants.UNKNOWN_ERROR,
                });
            } finally {
                finishLoading();
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
        startLoading();
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

                        close: { variant: 'danger' },
                        content: constants.NOT_FILE_OWNER,
                    });
            }
            setDialogMessage({
                title: constants.ERROR,

                close: { variant: 'danger' },
                content: constants.UNKNOWN_ERROR,
            });
        } finally {
            await syncWithRemote(false, true);
            finishLoading();
        }
    };

    const updateSearch: UpdateSearch = (newSearch, summary) => {
        setActiveCollection(ALL_SECTION);
        setSearch(newSearch);
        setSetSearchResultSummary(summary);
        setIsInSearchMode(!!newSearch);
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

            proceed: {
                action: emptyTrashHelper,
                text: constants.EMPTY_TRASH,
                variant: 'danger',
            },
            close: { text: constants.CANCEL },
        });
    const emptyTrashHelper = async () => {
        startLoading();
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

                close: { variant: 'danger' },
                content: constants.UNKNOWN_ERROR,
            });
        } finally {
            await syncWithRemote(false, true);
            finishLoading();
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
        startLoading();
        await downloadFiles(selectedFiles);
        finishLoading();
    };

    const openUploader = () => {
        if (importService.checkAllElectronAPIsExists()) {
            setUploadTypeSelectorView(true);
        } else {
            openFileUploader();
        }
    };

    const resetSearch = () => {
        setSearch(null);
        setSetSearchResultSummary(null);
    };

    return (
        <GalleryContext.Provider
            value={{
                ...defaultGalleryContext,
                showPlanSelectorModal,
                setActiveCollection,
                syncWithRemote,
                setNotificationAttributes,
                setBlockingLoad,
                photoListHeader: photoListHeader,
            }}>
            <FullScreenDropZone
                getRootProps={getRootProps}
                getInputProps={getInputProps}>
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
                    setLoading={setBlockingLoad}
                />
                <AlertBanner bannerMessage={bannerMessage} />
                <Notification
                    open={notificationView}
                    onClose={closeNotification}
                    attributes={notificationAttributes}
                />
                <CollectionNamer
                    show={collectionNamerView}
                    onHide={setCollectionNamerView.bind(null, false)}
                    attributes={collectionNamerAttributes}
                />
                <CollectionSelector
                    open={collectionSelectorView}
                    onClose={closeCollectionSelector}
                    collectionSummaries={collectionSummaries}
                    attributes={collectionSelectorAttributes}
                    collections={collections}
                />
                <FixCreationTime
                    isOpen={fixCreationTimeView}
                    hide={() => setFixCreationTimeView(false)}
                    show={() => setFixCreationTimeView(true)}
                    attributes={fixCreationTimeAttributes}
                />
                <GalleryNavbar
                    openSidebar={openSidebar}
                    isFirstFetch={isFirstFetch}
                    openUploader={openUploader}
                    isInSearchMode={isInSearchMode}
                    collections={collections}
                    files={getNonTrashedUniqueUserFiles(files)}
                    setActiveCollection={setActiveCollection}
                    updateSearch={updateSearch}
                />

                <Collections
                    collections={collections}
                    isInSearchMode={isInSearchMode}
                    activeCollectionID={activeCollection}
                    setActiveCollectionID={setActiveCollection}
                    collectionSummaries={collectionSummaries}
                    setCollectionNamerAttributes={setCollectionNamerAttributes}
                    setPhotoListHeader={setPhotoListHeader}
                />

                <Upload
                    syncWithRemote={syncWithRemote}
                    setBannerMessage={setBannerMessage}
                    droppedFiles={droppedFiles}
                    clearDroppedFiles={() => setDroppedFiles([])}
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
                    uploadInProgress={uploadInProgress}
                    setUploadInProgress={setUploadInProgress}
                    fileRejections={fileRejections}
                    setFiles={setFiles}
                    isFirstUpload={hasNonEmptyCollections(collectionSummaries)}
                    electronFiles={electronFiles}
                    setElectronFiles={setElectronFiles}
                    uploadTypeSelectorView={uploadTypeSelectorView}
                    setUploadTypeSelectorView={setUploadTypeSelectorView}
                    showSessionExpiredMessage={showSessionExpiredMessage}
                />
                <Sidebar
                    collectionSummaries={collectionSummaries}
                    sidebarView={sidebarView}
                    closeSidebar={closeSidebar}
                />

                <PhotoFrame
                    files={files}
                    setFiles={setFiles}
                    syncWithRemote={syncWithRemote}
                    favItemIds={favItemIds}
                    archivedCollections={archivedCollections}
                    setSelected={setSelected}
                    selected={selected}
                    isFirstLoad={isFirstLoad}
                    openUploader={openUploader}
                    isInSearchMode={isInSearchMode}
                    search={search}
                    deleted={deleted}
                    activeCollection={activeCollection}
                    isSharedCollection={isSharedCollection(
                        activeCollection,
                        collections
                    )}
                    enableDownload={true}
                    resetSearch={resetSearch}
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
