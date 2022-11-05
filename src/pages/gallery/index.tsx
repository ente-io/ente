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
import { styled, Typography } from '@mui/material';
import {
    syncCollections,
    getFavItemIds,
    getLocalCollections,
    createCollection,
    getCollectionSummaries,
} from 'services/collectionService';
import constants from 'utils/strings/constants';
import { checkSubscriptionPurchase } from 'utils/billing';

import FullScreenDropZone from 'components/FullScreenDropZone';
import Sidebar from 'components/Sidebar';
import { checkConnectivity, preloadImage } from 'utils/common';
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
} from 'components/Collections/CollectionSelector';

import CollectionNamer, {
    CollectionNamerAttributes,
} from 'components/Collections/CollectionNamer';
import PlanSelector from 'components/pages/gallery/PlanSelector';
import Uploader from 'components/Upload/Uploader';
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
    hasNonSystemCollections,
} from 'utils/collection';
import { logError } from 'utils/sentry';
import {
    getLocalTrash,
    getTrashedFiles,
    syncTrash,
} from 'services/trashService';

import FixCreationTime, {
    FixCreationTimeAttributes,
} from 'components/FixCreationTime';
import { Collection, CollectionSummaries } from 'types/collection';
import { EnteFile } from 'types/file';
import { GalleryContextType, SelectedState } from 'types/gallery';
import { VISIBILITY_STATE } from 'types/magicMetadata';
import Collections from 'components/Collections';
import { GalleryNavbar } from 'components/pages/gallery/Navbar';
import { Search, SearchResultSummary, UpdateSearch } from 'types/search';
import SearchResultInfo from 'components/Search/SearchResultInfo';
import { ITEM_TYPE, TimeStampListItem } from 'components/PhotoList';
import UploadInputs from 'components/UploadSelectorInputs';
import useFileInput from 'hooks/useFileInput';
import { User } from 'types/user';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import { CenteredFlex } from 'components/Container';
import { testUpload } from 'tests/upload.test';

export const DeadCenter = styled('div')`
    flex: 1;
    display: flex;
    justify-content: center;
    align-items: center;
    text-align: center;
    flex-direction: column;
`;

const defaultGalleryContext: GalleryContextType = {
    thumbs: new Map(),
    files: new Map(),
    showPlanSelectorModal: () => null,
    setActiveCollection: () => null,
    syncWithRemote: () => null,
    setBlockingLoad: () => null,
    photoListHeader: null,
};

export const GalleryContext = createContext<GalleryContextType>(
    defaultGalleryContext
);

export default function Gallery() {
    const router = useRouter();
    const [user, setUser] = useState(null);
    const [collections, setCollections] = useState<Collection[]>(null);

    const [files, setFiles] = useState<EnteFile[]>(null);
    const [favItemIds, setFavItemIds] = useState<Set<number>>();

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
    const [shouldDisableDropzone, setShouldDisableDropzone] = useState(false);

    const {
        getRootProps: getDragAndDropRootProps,
        getInputProps: getDragAndDropInputProps,
        acceptedFiles: dragAndDropFiles,
    } = useDropzone({
        noClick: true,
        noKeyboard: true,
        disabled: shouldDisableDropzone,
    });
    const {
        selectedFiles: webFileSelectorFiles,
        open: openFileSelector,
        getInputProps: getFileSelectorInputProps,
    } = useFileInput({
        directory: false,
    });
    const {
        selectedFiles: webFolderSelectorFiles,
        open: openFolderSelector,
        getInputProps: getFolderSelectorInputProps,
    } = useFileInput({
        directory: true,
    });

    const [isInSearchMode, setIsInSearchMode] = useState(false);
    const [searchResultSummary, setSetSearchResultSummary] =
        useState<SearchResultSummary>(null);
    const syncInProgress = useRef(true);
    const resync = useRef(false);
    const [deletedFileIds, setDeletedFileIds] = useState<Set<number>>(
        new Set<number>()
    );
    const { startLoading, finishLoading, setDialogMessage, ...appContext } =
        useContext(AppContext);
    const [collectionSummaries, setCollectionSummaries] =
        useState<CollectionSummaries>();
    const [activeCollection, setActiveCollection] = useState<number>(undefined);
    const [fixCreationTimeView, setFixCreationTimeView] = useState(false);
    const [fixCreationTimeAttributes, setFixCreationTimeAttributes] =
        useState<FixCreationTimeAttributes>(null);

    const [archivedCollections, setArchivedCollections] =
        useState<Set<number>>();

    const showPlanSelectorModal = () => setPlanModalView(true);

    const [uploadTypeSelectorView, setUploadTypeSelectorView] = useState(false);

    const [sidebarView, setSidebarView] = useState(false);

    const closeSidebar = () => setSidebarView(false);
    const openSidebar = () => setSidebarView(true);
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
        testUpload();
        appContext.showNavBar(true);
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
            const user = getData(LS_KEYS.USER);
            let files = mergeMetadata(await getLocalFiles());
            const collections = await getLocalCollections();
            const trash = await getLocalTrash();
            files = [...files, ...getTrashedFiles(trash)];
            setUser(user);
            setFiles(sortFiles(files));
            setCollections(collections);
            await syncWithRemote(true);
            setIsFirstLoad(false);
            setJustSignedUp(false);
            setIsFirstFetch(false);
            preloadImage('/images/subscription-card-background');
        };
        main();
    }, []);

    useEffect(() => {
        if (!user || !files || !collections) {
            return;
        }
        setDerivativeState(user, collections, files);
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
                itemType: ITEM_TYPE.OTHER,
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
            const collections = await syncCollections();
            setCollections(collections);
            let files = await syncFiles(collections, setFiles);
            const trash = await syncTrash(collections, setFiles, files);
            files = [...files, ...getTrashedFiles(trash)];
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
        user: User,
        collections: Collection[],
        files: EnteFile[]
    ) => {
        const favItemIds = await getFavItemIds(files);
        setFavItemIds(favItemIds);
        const archivedCollections = getArchivedCollections(collections);
        setArchivedCollections(archivedCollections);

        const collectionSummaries = getCollectionSummaries(
            user,
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
                setCollectionSelectorView(false);
                const selectedFiles = getSelectedFiles(selected, files);
                await handleCollectionOps(
                    ops,
                    collection,
                    selectedFiles,
                    selected.collectionID
                );
                clearSelection();
                await syncWithRemote(false, true);
                setActiveCollection(collection.id);
            } catch (e) {
                logError(e, 'collection ops failed', { ops });
                setDialogMessage({
                    title: constants.ERROR,

                    close: { variant: 'danger' },
                    content: constants.UNKNOWN_ERROR,
                });
            } finally {
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

    const showCreateCollectionModal = (ops: COLLECTION_OPS_TYPE) => {
        const callback = async (collectionName: string) => {
            try {
                startLoading();
                const collection = await createCollection(
                    collectionName,
                    CollectionType.album,
                    collections
                );
                await collectionOpsHelper(ops)(collection);
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
            setDeletedFileIds((deletedFileIds) => {
                selectedFiles.forEach((file) => deletedFileIds.add(file.id));
                return new Set(deletedFileIds);
            });
            if (permanent) {
                await deleteFromTrash(selectedFiles.map((file) => file.id));
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
        if (newSearch?.collection) {
            setActiveCollection(newSearch?.collection);
        } else {
            setActiveCollection(ALL_SECTION);
            setSearch(newSearch);
        }
        if (!newSearch?.collection && !newSearch?.file) {
            setIsInSearchMode(!!newSearch);
            setSetSearchResultSummary(summary);
        } else {
            setIsInSearchMode(false);
        }
    };

    const closeCollectionSelector = (closeBtnClick?: boolean) => {
        if (closeBtnClick === true) {
            appContext.resetSharedFiles();
        }
        setCollectionSelectorView(false);
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

    const resetSearch = () => {
        setSearch(null);
        setSetSearchResultSummary(null);
    };

    const openUploader = () => {
        setUploadTypeSelectorView(true);
    };

    return (
        <GalleryContext.Provider
            value={{
                ...defaultGalleryContext,
                showPlanSelectorModal,
                setActiveCollection,
                syncWithRemote,
                setBlockingLoad,
                photoListHeader: photoListHeader,
            }}>
            <FullScreenDropZone
                getDragAndDropRootProps={getDragAndDropRootProps}>
                <UploadInputs
                    getDragAndDropInputProps={getDragAndDropInputProps}
                    getFileSelectorInputProps={getFileSelectorInputProps}
                    getFolderSelectorInputProps={getFolderSelectorInputProps}
                />
                {blockingLoad && (
                    <LoadingOverlay>
                        <EnteSpinner />
                    </LoadingOverlay>
                )}
                {isFirstLoad && (
                    <CenteredFlex>
                        <Typography color="text.secondary" variant="body2">
                            {constants.INITIAL_LOAD_DELAY_WARNING}
                        </Typography>
                    </CenteredFlex>
                )}
                <PlanSelector
                    modalView={planModalView}
                    closeModal={() => setPlanModalView(false)}
                    setLoading={setBlockingLoad}
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
                    setIsInSearchMode={setIsInSearchMode}
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

                <Uploader
                    syncWithRemote={syncWithRemote}
                    showCollectionSelector={setCollectionSelectorView.bind(
                        null,
                        true
                    )}
                    closeUploadTypeSelector={setUploadTypeSelectorView.bind(
                        null,
                        false
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
                    setShouldDisableDropzone={setShouldDisableDropzone}
                    setFiles={setFiles}
                    setCollections={setCollections}
                    isFirstUpload={
                        !hasNonSystemCollections(collectionSummaries)
                    }
                    webFileSelectorFiles={webFileSelectorFiles}
                    webFolderSelectorFiles={webFolderSelectorFiles}
                    dragAndDropFiles={dragAndDropFiles}
                    uploadTypeSelectorView={uploadTypeSelectorView}
                    showUploadFilesDialog={openFileSelector}
                    showUploadDirsDialog={openFolderSelector}
                    showSessionExpiredMessage={showSessionExpiredMessage}
                />
                <Sidebar
                    collectionSummaries={collectionSummaries}
                    sidebarView={sidebarView}
                    closeSidebar={closeSidebar}
                />
                <PhotoFrame
                    files={files}
                    syncWithRemote={syncWithRemote}
                    favItemIds={favItemIds}
                    archivedCollections={archivedCollections}
                    setSelected={setSelected}
                    selected={selected}
                    isFirstLoad={isFirstLoad}
                    openUploader={openUploader}
                    isInSearchMode={isInSearchMode}
                    search={search}
                    deletedFileIds={deletedFileIds}
                    setDeletedFileIds={setDeletedFileIds}
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
            </FullScreenDropZone>
        </GalleryContext.Provider>
    );
}
