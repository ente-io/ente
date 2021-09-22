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
    File,
    getLocalFiles,
    deleteFiles,
    syncFiles,
    updateMagicMetadata,
} from 'services/fileService';
import styled from 'styled-components';
import LoadingBar from 'react-top-loading-bar';
import {
    Collection,
    syncCollections,
    CollectionAndItsLatestFile,
    getCollectionsAndTheirLatestFile,
    getFavItemIds,
    getLocalCollections,
    getNonEmptyCollections,
    setLocalCollection,
} from 'services/collectionService';
import constants from 'utils/strings/constants';
import billingService from 'services/billingService';
import { checkSubscriptionPurchase } from 'utils/billingUtil';

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
    archiveFiles,
    getSelectedFileIds,
    sortFilesIntoCollections,
} from 'utils/file';
import { addFilesToCollection } from 'utils/collection';
import SearchBar, { DateValue } from 'components/SearchBar';
import { Bbox } from 'services/searchService';
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
import Collections from 'components/pages/gallery/Collections';
import { AppContext } from 'pages/_app';
import { CustomError, ServerErrorCodes } from 'utils/common/errorUtil';
import { PAGES } from 'types';

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

export type SelectedState = {
    [k: number]: boolean;
    count: number;
    collectionID: number;
};
export type SetFiles = React.Dispatch<React.SetStateAction<File[]>>;
export type SetCollections = React.Dispatch<React.SetStateAction<Collection[]>>;
export type SetLoading = React.Dispatch<React.SetStateAction<Boolean>>;
export type setSearchStats = React.Dispatch<React.SetStateAction<SearchStats>>;

export type Search = {
    date?: DateValue;
    location?: Bbox;
};
export interface SearchStats {
    resultCount: number;
    timeTaken: number;
}

type GalleryContextType = {
    thumbs: Map<number, string>;
    files: Map<number, string>;
    showPlanSelectorModal: () => void;
    setActiveCollection: (collection: number) => void;
};

const defaultGalleryContext: GalleryContextType = {
    thumbs: new Map(),
    files: new Map(),
    showPlanSelectorModal: () => null,
    setActiveCollection: () => null,
};

export const GalleryContext = createContext<GalleryContextType>(
    defaultGalleryContext
);

export default function Gallery() {
    const router = useRouter();
    const [collections, setCollections] = useState<Collection[]>([]);
    const [collectionsAndTheirLatestFile, setCollectionsAndTheirLatestFile] =
        useState<CollectionAndItsLatestFile[]>([]);
    const [files, setFiles] = useState<File[]>(null);
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
    const [dialogView, setDialogView] = useState(false);
    const [planModalView, setPlanModalView] = useState(false);
    const [loading, setLoading] = useState(false);
    const [collectionSelectorAttributes, setCollectionSelectorAttributes] =
        useState<CollectionSelectorAttributes>(null);
    const [collectionSelectorView, setCollectionSelectorView] = useState(false);
    const [collectionNamerAttributes, setCollectionNamerAttributes] =
        useState<CollectionNamerAttributes>(null);
    const [collectionNamerView, setCollectionNamerView] = useState(false);
    const [search, setSearch] = useState<Search>({
        date: null,
        location: null,
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

    const loadingBar = useRef(null);
    const [searchMode, setSearchMode] = useState(false);
    const [searchStats, setSearchStats] = useState(null);
    const syncInProgress = useRef(true);
    const resync = useRef(false);
    const [deleted, setDeleted] = useState<number[]>([]);
    const appContext = useContext(AppContext);
    const [collectionFilesCount, setCollectionFilesCount] =
        useState<Map<number, number>>();
    const [activeCollection, setActiveCollection] = useState(0);

    useEffect(() => {
        const key = getKey(SESSION_KEYS.ENCRYPTION_KEY);
        if (!key) {
            router.push(PAGES.ROOT);
            return;
        }
        const main = async () => {
            setIsFirstLoad(isFirstLogin());
            setIsFirstFetch(true);
            if (justSignedUp()) {
                setPlanModalView(true);
            }
            setIsFirstLogin(false);
            const files = await getLocalFiles();
            const collections = await getLocalCollections();
            setFiles(files);
            setCollections(collections);
            await setDerivativeState(collections, files);
            await checkSubscriptionPurchase(
                setDialogMessage,
                router,
                setLoading
            );
            await syncWithRemote(true);
            setIsFirstLoad(false);
            setJustSignedUp(false);
            setIsFirstFetch(false);
        };
        main();
        appContext.showNavBar(true);
    }, []);

    useEffect(() => setDialogView(true), [dialogMessage]);

    useEffect(() => {
        if (collectionSelectorAttributes) {
            setCollectionSelectorView(true);
        }
    }, [collectionSelectorAttributes]);

    useEffect(() => setCollectionNamerView(true), [collectionNamerAttributes]);

    useEffect(() => {
        const href = `/gallery${
            activeCollection ? `?collection=${activeCollection.toString()}` : ''
        }`;
        router.push(href, undefined, { shallow: true });
    }, [activeCollection]);

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
            !silent && loadingBar.current?.continuousStart();
            await billingService.syncSubscription();
            const collections = await syncCollections();
            setCollections(collections);
            const { files } = await syncFiles(collections, setFiles);
            await setDerivativeState(collections, files);
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
            !silent && loadingBar.current?.complete();
        }
        syncInProgress.current = false;
        if (resync.current) {
            resync.current = false;
            syncWithRemote();
        }
    };

    const setDerivativeState = async (collections, files) => {
        const nonEmptyCollections = getNonEmptyCollections(collections, files);
        const collectionsAndTheirLatestFile =
            await getCollectionsAndTheirLatestFile(nonEmptyCollections, files);
        const collectionWiseFiles = sortFilesIntoCollections(files);
        const collectionFilesCount = new Map<number, number>();
        for (const [id, files] of collectionWiseFiles) {
            collectionFilesCount.set(id, files.length);
        }
        setCollections(nonEmptyCollections);
        setLocalCollection(nonEmptyCollections);
        setCollectionsAndTheirLatestFile(collectionsAndTheirLatestFile);
        setCollectionFilesCount(collectionFilesCount);
        const favItemIds = await getFavItemIds(files);
        setFavItemIds(favItemIds);
    };

    const clearSelection = function () {
        setSelected({ count: 0, collectionID: 0 });
    };

    if (!files) {
        return <div />;
    }
    const addToCollectionHelper = async (
        collectionName: string,
        collection: Collection
    ) => {
        loadingBar.current?.continuousStart();
        try {
            await addFilesToCollection(
                setCollectionSelectorView,
                selected,
                files,
                clearSelection,
                syncWithRemote,
                setActiveCollection,
                collectionName,
                collection
            );
        } catch (e) {
            setDialogMessage({
                title: constants.ERROR,
                staticBackdrop: true,
                close: { variant: 'danger' },
                content: constants.UNKNOWN_ERROR,
            });
        }
    };
    const archiveFilesHelper = async () => {
        loadingBar.current?.continuousStart();
        try {
            const archivedFiles = await archiveFiles(files, selected);
            await updateMagicMetadata(archivedFiles);
            setDeleted([...deleted, ...archivedFiles.map((file) => file.id)]);
        } catch (e) {
            console.log(e);
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
            clearSelection();
            syncWithRemote();
            loadingBar.current.complete();
        }
    };

    const showCreateCollectionModal = () =>
        setCollectionNamerAttributes({
            title: constants.CREATE_COLLECTION,
            buttonText: constants.CREATE,
            autoFilledName: '',
            callback: (collectionName) =>
                addToCollectionHelper(collectionName, null),
        });

    const deleteFileHelper = async () => {
        loadingBar.current?.continuousStart();
        try {
            const fileIds = getSelectedFileIds(selected);
            await deleteFiles(fileIds);
            setDeleted([...deleted, ...fileIds]);
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
            clearSelection();
            syncWithRemote();
            loadingBar.current.complete();
        }
    };

    const updateSearch = (search: Search) => {
        setSearch(search);
        setSearchStats(null);
    };

    const closeCollectionSelector = (closeBtnClick?: boolean) => {
        if (closeBtnClick === true) {
            appContext.resetSharedFiles();
        }
        setCollectionSelectorView(false);
    };

    return (
        <GalleryContext.Provider
            value={{
                ...defaultGalleryContext,
                showPlanSelectorModal: () => setPlanModalView(true),
                setActiveCollection,
            }}>
            <FullScreenDropZone
                getRootProps={getRootProps}
                getInputProps={getInputProps}
                showCollectionSelector={setCollectionSelectorView.bind(
                    null,
                    true
                )}>
                {loading && (
                    <LoadingOverlay>
                        <EnteSpinner />
                    </LoadingOverlay>
                )}
                <LoadingBar color="#51cd7c" ref={loadingBar} />
                {isFirstLoad && (
                    <AlertContainer>
                        {constants.INITIAL_LOAD_DELAY_WARNING}
                    </AlertContainer>
                )}
                <PlanSelector
                    modalView={planModalView}
                    closeModal={() => setPlanModalView(false)}
                    setDialogMessage={setDialogMessage}
                    setLoading={setLoading}
                />
                <AlertBanner bannerMessage={bannerMessage} />
                <MessageDialog
                    size="lg"
                    show={dialogView}
                    onHide={() => setDialogView(false)}
                    attributes={dialogMessage}
                />
                <SearchBar
                    isOpen={searchMode}
                    setOpen={setSearchMode}
                    loadingBar={loadingBar}
                    isFirstFetch={isFirstFetch}
                    setCollections={setCollections}
                    setSearch={updateSearch}
                    files={files}
                    searchStats={searchStats}
                />
                <Collections
                    collections={collections}
                    searchMode={searchMode}
                    activeCollection={activeCollection}
                    setActiveCollection={setActiveCollection}
                    syncWithRemote={syncWithRemote}
                    setDialogMessage={setDialogMessage}
                    setCollectionNamerAttributes={setCollectionNamerAttributes}
                    startLoadingBar={loadingBar.current?.continuousStart}
                    collectionFilesCount={collectionFilesCount}
                />
                <CollectionNamer
                    show={collectionNamerView}
                    onHide={setCollectionNamerView.bind(null, false)}
                    attributes={collectionNamerAttributes}
                />
                <CollectionSelector
                    show={
                        collectionSelectorView &&
                        !(collectionsAndTheirLatestFile?.length === 0)
                    }
                    onHide={closeCollectionSelector}
                    collectionsAndTheirLatestFile={
                        collectionsAndTheirLatestFile
                    }
                    attributes={collectionSelectorAttributes}
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
                    setLoading={setLoading}
                    setCollectionNamerAttributes={setCollectionNamerAttributes}
                    setDialogMessage={setDialogMessage}
                    setUploadInProgress={setUploadInProgress}
                    fileRejections={fileRejections}
                    setFiles={setFiles}
                    isFirstUpload={collectionsAndTheirLatestFile?.length === 0}
                />
                <Sidebar
                    collections={collections}
                    setDialogMessage={setDialogMessage}
                    setLoading={setLoading}
                />
                <UploadButton
                    isFirstFetch={isFirstFetch}
                    openFileUploader={openFileUploader}
                />
                <PhotoFrame
                    files={files}
                    setFiles={setFiles}
                    syncWithRemote={syncWithRemote}
                    favItemIds={favItemIds}
                    setSelected={setSelected}
                    selected={selected}
                    isFirstLoad={isFirstLoad}
                    openFileUploader={openFileUploader}
                    loadingBar={loadingBar}
                    searchMode={searchMode}
                    search={search}
                    setSearchStats={setSearchStats}
                    deleted={deleted}
                    setDialogMessage={setDialogMessage}
                    activeCollection={activeCollection}
                />
                {selected.count > 0 &&
                    selected.collectionID === activeCollection && (
                        <SelectedFileOptions
                            addToCollectionHelper={addToCollectionHelper}
                            archiveFilesHelper={archiveFilesHelper}
                            showCreateCollectionModal={
                                showCreateCollectionModal
                            }
                            setDialogMessage={setDialogMessage}
                            setCollectionSelectorAttributes={
                                setCollectionSelectorAttributes
                            }
                            deleteFileHelper={deleteFileHelper}
                            count={selected.count}
                            clearSelection={clearSelection}
                        />
                    )}
            </FullScreenDropZone>
        </GalleryContext.Provider>
    );
}
