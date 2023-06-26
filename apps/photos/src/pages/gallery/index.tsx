import {
    createContext,
    useContext,
    useEffect,
    useMemo,
    useRef,
    useState,
} from 'react';
import { useRouter } from 'next/router';
import { clearKeys, getKey, SESSION_KEYS } from 'utils/storage/sessionStorage';
import { getMapEnabledStatus } from 'services/userService';
import {
    getLocalFiles,
    syncFiles,
    trashFiles,
    deleteFromTrash,
    getLocalHiddenFiles,
    syncHiddenFiles,
} from 'services/fileService';
import { styled, Typography } from '@mui/material';
import {
    getLatestCollections,
    getFavItemIds,
    getLocalCollections,
    createAlbum,
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
import { isTokenValid, validateKey } from 'services/userService';
import { useDropzone } from 'react-dropzone';
import EnteSpinner from 'components/EnteSpinner';
import { LoadingOverlay } from 'components/LoadingOverlay';
import PhotoFrame from 'components/PhotoFrame';
import {
    changeFilesVisibility,
    constructFileToCollectionMap,
    downloadFiles,
    getSelectedFiles,
    getUniqueFiles,
    isSharedFile,
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
    splitNormalAndHiddenCollections,
    constructCollectionNameMap,
} from 'utils/collection';
import { logError } from 'utils/sentry';
import { getLocalTrashedFiles, syncTrash } from 'services/trashService';

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
import { getData, LS_KEYS, setData } from 'utils/storage/localStorage';
import { CenteredFlex } from 'components/Container';
import { checkConnectivity } from 'utils/common';
import { SYNC_INTERVAL_IN_MICROSECONDS } from 'constants/gallery';
import ElectronService from 'services/electron/common';
import uploadManager from 'services/upload/uploadManager';
import { getToken } from 'utils/common/key';
import ExportModal from 'components/ExportModal';
import GalleryEmptyState from 'components/GalleryEmptyState';
import AuthenticateUserModal from 'components/AuthenticateUserModal';
import useMemoSingleThreaded from 'hooks/useMemoSingleThreaded';
import { IsArchived } from 'utils/magicMetadata';
import { isSameDayAnyYear, isInsideLocationTag } from 'utils/search';
import { getSessionExpiredMessage } from 'utils/ui';
import { syncEntities } from 'services/entityService';
import { userIdtoEmail } from 'services/collectionService';

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
    setIsInSearchMode: () => null,
    photoListHeader: null,
    openExportModal: () => null,
    authenticateUser: () => null,
    user: null,
    idToMail: new Map(),
};

export const GalleryContext = createContext<GalleryContextType>(
    defaultGalleryContext
);

export default function Gallery() {
    const router = useRouter();
    const [user, setUser] = useState(null);
    const [collections, setCollections] = useState<Collection[]>(null);
    const [files, setFiles] = useState<EnteFile[]>(null);
    const [hiddenFiles, setHiddenFiles] = useState<EnteFile[]>(null);
    const [trashedFiles, setTrashedFiles] = useState<EnteFile[]>(null);

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
    const [hiddenFileIds, setHiddenFileIds] = useState<Set<number>>(
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
            const files = sortFiles(mergeMetadata(await getLocalFiles()));
            const hiddenFiles = sortFiles(
                mergeMetadata(await getLocalHiddenFiles())
            );
            const collections = await getLocalCollections();
            const trashedFiles = await getLocalTrashedFiles();

            setUser(user);
            setFiles(files);
            setTrashedFiles(trashedFiles);
            setHiddenFiles(hiddenFiles);
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
        if (!user || !files || !collections || !hiddenFiles || !trashedFiles) {
            return;
        }
        setDerivativeState(user, collections, files, trashedFiles, hiddenFiles);
    }, [collections, files, hiddenFiles, trashedFiles, user]);

    const { idToMail } = useContext(GalleryContext);

    useEffect(() => {
        const fetchData = async () => {
            if (!collections) {
                return;
            }

            const userIdEmail = await userIdtoEmail();
            const idEmailMap = userIdEmail;

            idToMail.clear(); // Clear the existing map

            // Update idToMail with idEmailMap values
            for (const [id, email] of idEmailMap) {
                idToMail.set(id, email);
            }
        };
        fetchData();
    }, [collections]);

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
        const delayRouteChange = () => {
            setTimeout(() => {
                router.push(href, undefined, { shallow: true });
            }, 1000);
        };

        delayRouteChange();
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
        const main = async () => {
            const remoteMapValue = await getMapEnabledStatus();
            const mapEnabled = remoteMapValue;
            setData(LS_KEYS.MAPENABLED, { mapEnabled });
        };
        main();
    }, []);

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

    const filteredData = useMemoSingleThreaded((): EnteFile[] => {
        if (
            !files ||
            !user ||
            !trashedFiles ||
            !hiddenFiles ||
            !archivedCollections
        ) {
            return;
        }

        if (activeCollection === HIDDEN_SECTION && !isInSearchMode) {
            return getUniqueFiles([
                ...hiddenFiles,
                ...files.filter((file) => hiddenFileIds?.has(file.id)),
            ]);
        }

        if (activeCollection === TRASH_SECTION && !isInSearchMode) {
            return getUniqueFiles([
                ...trashedFiles,
                ...files.filter((file) => deletedFileIds?.has(file.id)),
            ]);
        }
        let sortAsc = false;
        if (activeCollection > 0) {
            // find matching collection in collections
            for (const collection of collections) {
                if (collection.id === activeCollection) {
                    sortAsc = collection?.pubMagicMetadata?.data?.asc ?? false;
                    break;
                }
            }
        }

        return getUniqueFiles(
            files.filter((item) => {
                if (deletedFileIds?.has(item.id)) {
                    return false;
                }

                if (hiddenFileIds?.has(item.id)) {
                    return false;
                }

                // SEARCH MODE
                if (isInSearchMode) {
                    // shared files are not searchable
                    if (isSharedFile(user, item)) {
                        return false;
                    }
                    if (
                        search?.date &&
                        !isSameDayAnyYear(search.date)(
                            new Date(item.metadata.creationTime / 1000)
                        )
                    ) {
                        return false;
                    }
                    if (
                        search?.location &&
                        !isInsideLocationTag(
                            {
                                latitude: item.metadata.latitude,
                                longitude: item.metadata.longitude,
                            },
                            search.location
                        )
                    ) {
                        return false;
                    }
                    if (
                        search?.person &&
                        search.person.files.indexOf(item.id) === -1
                    ) {
                        return false;
                    }
                    if (
                        search?.thing &&
                        search.thing.files.indexOf(item.id) === -1
                    ) {
                        return false;
                    }
                    if (
                        search?.text &&
                        search.text.files.indexOf(item.id) === -1
                    ) {
                        return false;
                    }
                    if (search?.files && search.files.indexOf(item.id) === -1) {
                        return false;
                    }
                    return true;
                }

                // shared files can only be seen in their respective collection
                if (isSharedFile(user, item)) {
                    if (activeCollection === item.collectionID) {
                        return true;
                    } else {
                        return false;
                    }
                }

                // archived collections files can only be seen in their respective collection
                if (archivedCollections.has(item.collectionID)) {
                    if (activeCollection === item.collectionID) {
                        return true;
                    } else {
                        return false;
                    }
                }

                // Archived files can only be seen in archive section or their respective collection
                if (IsArchived(item)) {
                    if (
                        activeCollection === ARCHIVE_SECTION ||
                        activeCollection === item.collectionID
                    ) {
                        return true;
                    } else {
                        return false;
                    }
                }

                // ALL SECTION - show all files
                if (activeCollection === ALL_SECTION) {
                    return true;
                }

                // COLLECTION SECTION - show files in the active collection
                if (activeCollection === item.collectionID) {
                    return true;
                } else {
                    return false;
                }
            }),
            sortAsc
        );
    }, [
        files,
        trashedFiles,
        hiddenFiles,
        deletedFileIds,
        hiddenFileIds,
        search,
        activeCollection,
        archivedCollections,
    ]);

    const fileToCollectionsMap = useMemoSingleThreaded(() => {
        return constructFileToCollectionMap(files);
    }, [files]);

    const collectionNameMap = useMemo(() => {
        return constructCollectionNameMap(collections);
    }, [collections]);

    const showSessionExpiredMessage = () => {
        setDialogMessage(getSessionExpiredMessage());
    };

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
            const collections = await getLatestCollections(true);
            const { normalCollections, hiddenCollections } =
                await splitNormalAndHiddenCollections(collections);
            setCollections(normalCollections);
            await syncFiles(normalCollections, setFiles);
            await syncHiddenFiles(hiddenCollections, setHiddenFiles);
            await syncTrash(collections, setTrashedFiles);
            await syncEntities();
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
            setHiddenFileIds(new Set());
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
        files: EnteFile[],
        trashedFiles: EnteFile[],
        hiddenFiles: EnteFile[]
    ) => {
        const favItemIds = await getFavItemIds(files);
        setFavItemIds(favItemIds);
        const archivedCollections = getArchivedCollections(collections);
        setArchivedCollections(archivedCollections);
        const collectionSummaries = await getCollectionSummaries(
            user,
            collections,
            files,
            trashedFiles,
            hiddenFiles,
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

    if (!collectionSummaries || !filteredData) {
        return <div />;
    }

    const collectionOpsHelper =
        (ops: COLLECTION_OPS_TYPE) => async (collection: Collection) => {
            startLoading();
            try {
                setCollectionSelectorView(false);
                const selectedFiles = getSelectedFiles(selected, filteredData);
                const toProcessFiles =
                    ops === COLLECTION_OPS_TYPE.REMOVE
                        ? selectedFiles
                        : selectedFiles.filter(
                              (file) => file.ownerID === user.id
                          );
                if (toProcessFiles.length === 0) {
                    return;
                }
                await handleCollectionOps(
                    ops,
                    collection,
                    toProcessFiles,
                    selected.collectionID
                );
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
            const selectedFiles = getSelectedFiles(selected, filteredData);
            await changeFilesVisibility(selectedFiles, visibility);
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
                const collection = await createAlbum(collectionName);
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
            const selectedFiles = getSelectedFiles(selected, filteredData);
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
            setDeletedFileIds(new Set());
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
            // passing files here instead of filteredData because we want to move all files copies to hidden collection
            const selectedFiles = getSelectedFiles(selected, files);
            setHiddenFileIds((hiddenFileIds) => {
                selectedFiles.forEach((file) => hiddenFileIds.add(file.id));
                return new Set(hiddenFileIds);
            });
            await moveToHiddenCollection(selectedFiles);
            clearSelection();
        } catch (e) {
            setHiddenFileIds(new Set());
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
        const selectedFiles = getSelectedFiles(selected, filteredData);
        setFixCreationTimeAttributes({ files: selectedFiles });
        clearSelection();
    };

    const downloadHelper = async () => {
        const selectedFiles = getSelectedFiles(selected, filteredData);
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
                setIsInSearchMode,
                photoListHeader,
                openExportModal,
                authenticateUser,
                user,
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
                    collections={collections}
                    files={files}
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
                        files={filteredData}
                        syncWithRemote={syncWithRemote}
                        favItemIds={favItemIds}
                        setSelected={setSelected}
                        selected={selected}
                        deletedFileIds={deletedFileIds}
                        setDeletedFileIds={setDeletedFileIds}
                        activeCollection={activeCollection}
                        isIncomingSharedCollection={
                            collectionSummaries.get(activeCollection)?.type ===
                            CollectionSummaryType.incomingShare
                        }
                        enableDownload={true}
                        fileToCollectionsMap={fileToCollectionsMap}
                        collectionNameMap={collectionNameMap}
                        showAppDownloadBanner={
                            files.length < 30 && !isInSearchMode
                        }
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
                            unhideToCollectionHelper={collectionOpsHelper(
                                COLLECTION_OPS_TYPE.UNHIDE
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
