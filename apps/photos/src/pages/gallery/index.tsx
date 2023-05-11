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
    moveToHiddenCollection,
} from 'services/collectionService';
import { t } from 'i18next';

import { checkSubscriptionPurchase } from 'utils/billing';

import FullScreenDropZone from 'components/FullScreenDropZone';
import Sidebar from 'components/Sidebar';
import { preloadImage } from 'utils/common';
import {
    isFirstLogin,
    justSignedUp,
    setIsFirstLogin,
    setJustSignedUp,
} from 'utils/storage';
import { isTokenValid, logoutUser, validateKey } from 'services/userService';
import { useDropzone } from 'react-dropzone';
import EnteSpinner from 'components/EnteSpinner';
import { LoadingOverlay } from 'components/LoadingOverlay';
import PhotoFrame from 'components/PhotoFrame';
import {
    changeFilesVisibility,
    downloadFiles,
    getSearchableFiles,
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
    CollectionSummaryType,
    CollectionType,
    HIDDEN_SECTION,
    DUMMY_UNCATEGORIZED_SECTION,
    TRASH_SECTION,
} from 'constants/collection';
import { AppContext } from 'pages/_app';
import { CustomError, ServerErrorCodes } from 'utils/error';
import { PAGES } from 'constants/pages';
import {
    COLLECTION_OPS_TYPE,
    handleCollectionOps,
    getSelectedCollection,
    getArchivedCollections,
    hasNonSystemCollections,
    getSearchableCollections,
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
import {
    GalleryContextType,
    SelectedState,
    UploadTypeSelectorIntent,
} from 'types/gallery';
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
import { checkConnectivity } from 'utils/common';
import { SYNC_INTERVAL_IN_MICROSECONDS } from 'constants/gallery';
import ElectronService from 'services/electron/common';
import uploadManager from 'services/upload/uploadManager';
import { getToken } from 'utils/common/key';
import ExportModal from 'components/ExportModal';
import GalleryEmptyState from 'components/GalleryEmptyState';
import AuthenticateUserModal from 'components/AuthenticateUserModal';

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
    openExportModal: () => null,
    authenticateUser: () => null,
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
    const [hasNoPersonalFiles, setHasNoPersonalFiles] = useState(false);
    const [selected, setSelected] = useState<SelectedState>({
        ownCount: 0,
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
    const syncInterval = useRef<NodeJS.Timeout>();
    const resync = useRef<{ force: boolean; silent: boolean }>();
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
    const [uploadTypeSelectorIntent, setUploadTypeSelectorIntent] =
        useState<UploadTypeSelectorIntent>(
            UploadTypeSelectorIntent.normalUpload
        );

    const [sidebarView, setSidebarView] = useState(false);

    const closeSidebar = () => setSidebarView(false);
    const openSidebar = () => setSidebarView(true);
    const [photoListHeader, setPhotoListHeader] =
        useState<TimeStampListItem>(null);

    const [exportModalView, setExportModalView] = useState(false);

    const [authenticateUserModalView, setAuthenticateUserModalView] =
        useState(false);

    const onAuthenticateCallback = useRef<() => void>();

    const authenticateUser = (callback: () => void) => {
        onAuthenticateCallback.current = callback;
        setAuthenticateUserModalView(true);
    };
    const closeAuthenticateUserModal = () =>
        setAuthenticateUserModalView(false);

    const showSessionExpiredMessage = () =>
        setDialogMessage({
            title: t('SESSION_EXPIRED'),
            content: t('SESSION_EXPIRED_MESSAGE'),

            nonClosable: true,
            proceed: {
                text: t('LOGIN'),
                action: logoutUser,
                variant: 'accent',
            },
        });

    useEffect(() => {
        appContext.showNavBar(true);
        const key = getKey(SESSION_KEYS.ENCRYPTION_KEY);
        if (!key) {
            appContext.setRedirectURL(router.asPath);
            router.push(PAGES.ROOT);
            return;
        }
        preloadImage('/images/subscription-card-background');
        const main = async () => {
            const valid = await validateKey();
            if (!valid) {
                return;
            }
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
            syncInterval.current = setInterval(() => {
                syncWithRemote(false, true);
            }, SYNC_INTERVAL_IN_MICROSECONDS);
            ElectronService.registerForegroundEventListener(() => {
                syncWithRemote(false, true);
            });
        };
        main();
        return () => {
            clearInterval(syncInterval.current);
            ElectronService.registerForegroundEventListener(() => {});
        };
    }, []);

    useEffect(() => {
        if (!user || !files || !collections) {
            return;
        }
        setDerivativeState(user, collections, files);
    }, [collections, files]);

    useEffect(() => {
        collectionSelectorAttributes && setCollectionSelectorView(true);
    }, [collectionSelectorAttributes]);

    useEffect(() => {
        collectionNamerAttributes && setCollectionNamerView(true);
    }, [collectionNamerAttributes]);
    useEffect(() => {
        fixCreationTimeAttributes && setFixCreationTimeView(true);
    }, [fixCreationTimeAttributes]);

    useEffect(() => {
        if (typeof activeCollection === 'undefined') {
            return;
        }
        let collectionURL = '';
        if (activeCollection !== ALL_SECTION) {
            collectionURL += '?collection=';
            if (activeCollection === ARCHIVE_SECTION) {
                collectionURL += t('ARCHIVE_SECTION_NAME');
            } else if (activeCollection === TRASH_SECTION) {
                collectionURL += t('TRASH');
            } else if (activeCollection === DUMMY_UNCATEGORIZED_SECTION) {
                collectionURL += t('UNCATEGORIZED');
            } else if (activeCollection === HIDDEN_SECTION) {
                collectionURL += t('HIDDEN');
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
                itemType: ITEM_TYPE.HEADER,
            });
        }
    }, [isInSearchMode, searchResultSummary]);

    const syncWithRemote = async (force = false, silent = false) => {
        if (syncInProgress.current && !force) {
            resync.current = { force, silent };
            return;
        }
        syncInProgress.current = true;
        try {
            checkConnectivity();
            const token = getToken();
            if (!token) {
                return;
            }
            const tokenValid = await isTokenValid(token);
            if (!tokenValid) {
                throw new Error(ServerErrorCodes.SESSION_EXPIRED);
            }
            !silent && startLoading();
            const collections = await syncCollections();
            setCollections(collections);
            const files = await syncFiles(collections, setFiles);
            await syncTrash(collections, files, setFiles);
        } catch (e) {
            switch (e.message) {
                case ServerErrorCodes.SESSION_EXPIRED:
                    showSessionExpiredMessage();
                    break;
                case CustomError.KEY_MISSING:
                    clearKeys();
                    router.push(PAGES.CREDENTIALS);
                    break;
                case CustomError.NO_INTERNET_CONNECTION:
                    break;
                default:
                    logError(e, 'syncWithRemote failed');
            }
        } finally {
            setDeletedFileIds(new Set());
            !silent && finishLoading();
        }
        syncInProgress.current = false;
        if (resync.current) {
            const { force, silent } = resync.current;
            setTimeout(() => syncWithRemote(force, silent), 0);
            resync.current = null;
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

        const collectionSummaries = await getCollectionSummaries(
            user,
            collections,
            files,
            archivedCollections
        );
        setCollectionSummaries(collectionSummaries);
        const hasNoPersonalFiles = files.every(
            (file) => file.ownerID !== user.id
        );
        setHasNoPersonalFiles(hasNoPersonalFiles);
    };

    const clearSelection = function () {
        setSelected({ ownCount: 0, count: 0, collectionID: 0 });
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
                const toProcessFiles =
                    ops === COLLECTION_OPS_TYPE.REMOVE
                        ? selectedFiles
                        : selectedFiles.filter(
                              (file) => file.ownerID === user.id
                          );
                if (toProcessFiles.length === 0) {
                    return;
                }
                await handleCollectionOps(ops, collection, toProcessFiles);
                clearSelection();
                await syncWithRemote(false, true);
                setActiveCollection(collection.id);
            } catch (e) {
                logError(e, 'collection ops failed', { ops });
                setDialogMessage({
                    title: t('ERROR'),

                    close: { variant: 'critical' },
                    content: t('UNKNOWN_ERROR'),
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
                        title: t('ERROR'),

                        close: { variant: 'critical' },
                        content: t('NOT_FILE_OWNER'),
                    });
                    return;
            }
            setDialogMessage({
                title: t('ERROR'),

                close: { variant: 'critical' },
                content: t('UNKNOWN_ERROR'),
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
                    title: t('ERROR'),

                    close: { variant: 'critical' },
                    content: t('UNKNOWN_ERROR'),
                });
            } finally {
                finishLoading();
            }
        };
        return () =>
            setCollectionNamerAttributes({
                title: t('CREATE_COLLECTION'),
                buttonText: t('CREATE'),
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
                        title: t('ERROR'),

                        close: { variant: 'critical' },
                        content: t('NOT_FILE_OWNER'),
                    });
            }
            setDialogMessage({
                title: t('ERROR'),

                close: { variant: 'critical' },
                content: t('UNKNOWN_ERROR'),
            });
        } finally {
            await syncWithRemote(false, true);
            finishLoading();
        }
    };

    const hideFilesHelper = async () => {
        startLoading();
        try {
            const selectedFiles = getSelectedFiles(selected, files);
            await moveToHiddenCollection(selectedFiles);
            clearSelection();
        } catch (e) {
            switch (e.status?.toString()) {
                case ServerErrorCodes.FORBIDDEN:
                    setDialogMessage({
                        title: t('ERROR'),

                        close: { variant: 'critical' },
                        content: t('NOT_FILE_OWNER'),
                    });
            }
            setDialogMessage({
                title: t('ERROR'),

                close: { variant: 'critical' },
                content: t('UNKNOWN_ERROR'),
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
            setSearch(newSearch);
        }
        if (!newSearch?.collection) {
            setIsInSearchMode(!!newSearch);
            setSetSearchResultSummary(summary);
        } else {
            setIsInSearchMode(false);
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

    const openUploader = (intent = UploadTypeSelectorIntent.normalUpload) => {
        if (!uploadManager.shouldAllowNewUpload()) {
            return;
        }
        setUploadTypeSelectorView(true);
        setUploadTypeSelectorIntent(intent);
    };

    const closeCollectionSelector = () => {
        setCollectionSelectorView(false);
    };

    const openExportModal = () => {
        setExportModalView(true);
    };

    const closeExportModal = () => {
        setExportModalView(false);
    };

    return (
        <GalleryContext.Provider
            value={{
                ...defaultGalleryContext,
                showPlanSelectorModal,
                setActiveCollection,
                syncWithRemote,
                setBlockingLoad,
                photoListHeader,
                openExportModal,
                authenticateUser,
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
                        <Typography color="text.muted" variant="small">
                            {t('INITIAL_LOAD_DELAY_WARNING')}
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
                    collections={getSearchableCollections(collections)}
                    files={getSearchableFiles(files)}
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
                    uploadTypeSelectorIntent={uploadTypeSelectorIntent}
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
                {!isInSearchMode &&
                !isFirstLoad &&
                hasNoPersonalFiles &&
                activeCollection === ALL_SECTION ? (
                    <GalleryEmptyState openUploader={openUploader} />
                ) : (
                    <PhotoFrame
                        files={files}
                        collections={collections}
                        syncWithRemote={syncWithRemote}
                        favItemIds={favItemIds}
                        archivedCollections={archivedCollections}
                        setSelected={setSelected}
                        selected={selected}
                        isInSearchMode={isInSearchMode}
                        search={search}
                        deletedFileIds={deletedFileIds}
                        setDeletedFileIds={setDeletedFileIds}
                        activeCollection={activeCollection}
                        isIncomingSharedCollection={
                            collectionSummaries.get(activeCollection)?.type ===
                            CollectionSummaryType.incomingShare
                        }
                        enableDownload={true}
                    />
                )}
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
                            hideFilesHelper={hideFilesHelper}
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
                            ownCount={selected.ownCount}
                            clearSelection={clearSelection}
                            activeCollection={activeCollection}
                            isFavoriteCollection={
                                collectionSummaries.get(activeCollection)
                                    ?.type === CollectionSummaryType.favorites
                            }
                            isUncategorizedCollection={
                                collectionSummaries.get(activeCollection)
                                    ?.type ===
                                CollectionSummaryType.uncategorized
                            }
                            isIncomingSharedCollection={
                                collectionSummaries.get(activeCollection)
                                    ?.type ===
                                CollectionSummaryType.incomingShare
                            }
                            isInSearchMode={isInSearchMode}
                        />
                    )}
                <ExportModal show={exportModalView} onHide={closeExportModal} />
                <AuthenticateUserModal
                    open={authenticateUserModalView}
                    onClose={closeAuthenticateUserModal}
                    onAuthenticate={onAuthenticateCallback.current}
                />
            </FullScreenDropZone>
        </GalleryContext.Provider>
    );
}
