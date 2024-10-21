import { stashRedirect } from "@/accounts/services/redirect";
import { NavbarBase } from "@/base/components/Navbar";
import { ActivityIndicator } from "@/base/components/mui/ActivityIndicator";
import { useModalVisibility } from "@/base/components/utils/modal";
import { useIsSmallWidth } from "@/base/hooks";
import log from "@/base/log";
import { type Collection } from "@/media/collection";
import { mergeMetadata, type EnteFile } from "@/media/file";
import {
    CollectionSelector,
    type CollectionSelectorAttributes,
} from "@/new/photos/components/CollectionSelector";
import {
    SearchBar,
    type SearchBarProps,
} from "@/new/photos/components/SearchBar";
import { WhatsNew } from "@/new/photos/components/WhatsNew";
import {
    PeopleEmptyState,
    SearchResultsHeader,
} from "@/new/photos/components/gallery";
import {
    uniqueFilesByID,
    useGalleryReducer,
    type GalleryBarMode,
} from "@/new/photos/components/gallery/reducer";
import { usePeopleStateSnapshot } from "@/new/photos/components/utils/ml";
import { shouldShowWhatsNew } from "@/new/photos/services/changelog";
import {
    ALL_SECTION,
    ARCHIVE_SECTION,
    DUMMY_UNCATEGORIZED_COLLECTION,
    HIDDEN_ITEMS_SECTION,
    TRASH_SECTION,
    isHiddenCollection,
} from "@/new/photos/services/collection";
import { areOnlySystemCollections } from "@/new/photos/services/collection/ui";
import downloadManager from "@/new/photos/services/download";
import {
    getLocalFiles,
    getLocalTrashedFiles,
    sortFiles,
} from "@/new/photos/services/files";
import { isArchivedFile } from "@/new/photos/services/magic-metadata";
import type { Person } from "@/new/photos/services/ml/people";
import {
    filterSearchableFiles,
    setSearchCollectionsAndFiles,
} from "@/new/photos/services/search";
import type { SearchOption } from "@/new/photos/services/search/types";
import { AppContext } from "@/new/photos/types/context";
import { splitByPredicate } from "@/utils/array";
import { ensure } from "@/utils/ensure";
import {
    CenteredFlex,
    FlexWrapper,
    HorizontalFlex,
} from "@ente/shared/components/Container";
import { PHOTOS_PAGES as PAGES } from "@ente/shared/constants/pages";
import { getRecoveryKey } from "@ente/shared/crypto/helpers";
import { CustomError } from "@ente/shared/error";
import { useFileInput } from "@ente/shared/hooks/useFileInput";
import useMemoSingleThreaded from "@ente/shared/hooks/useMemoSingleThreaded";
import { LS_KEYS, getData } from "@ente/shared/storage/localStorage";
import {
    getToken,
    isFirstLogin,
    justSignedUp,
    setIsFirstLogin,
    setJustSignedUp,
} from "@ente/shared/storage/localStorage/helpers";
import {
    SESSION_KEYS,
    clearKeys,
    getKey,
} from "@ente/shared/storage/sessionStorage";
import ArrowBack from "@mui/icons-material/ArrowBack";
import FileUploadOutlinedIcon from "@mui/icons-material/FileUploadOutlined";
import MenuIcon from "@mui/icons-material/Menu";
import type { ButtonProps, IconButtonProps } from "@mui/material";
import { Box, Button, IconButton, Typography } from "@mui/material";
import AuthenticateUserModal from "components/AuthenticateUserModal";
import CollectionNamer, {
    CollectionNamerAttributes,
} from "components/Collections/CollectionNamer";
import { GalleryBarAndListHeader } from "components/Collections/GalleryBarAndListHeader";
import ExportModal from "components/ExportModal";
import {
    FilesDownloadProgress,
    FilesDownloadProgressAttributes,
} from "components/FilesDownloadProgress";
import FixCreationTime, {
    FixCreationTimeAttributes,
} from "components/FixCreationTime";
import FullScreenDropZone from "components/FullScreenDropZone";
import GalleryEmptyState from "components/GalleryEmptyState";
import { LoadingOverlay } from "components/LoadingOverlay";
import PhotoFrame from "components/PhotoFrame";
import { ITEM_TYPE, TimeStampListItem } from "components/PhotoList";
import Sidebar from "components/Sidebar";
import { type UploadTypeSelectorIntent } from "components/Upload/UploadTypeSelector";
import Uploader from "components/Upload/Uploader";
import { UploadSelectorInputs } from "components/UploadSelectorInputs";
import PlanSelector from "components/pages/gallery/PlanSelector";
import SelectedFileOptions from "components/pages/gallery/SelectedFileOptions";
import { t } from "i18next";
import { useRouter } from "next/router";
import {
    createContext,
    useCallback,
    useContext,
    useEffect,
    useMemo,
    useRef,
    useState,
} from "react";
import { useDropzone } from "react-dropzone";
import {
    constructEmailList,
    constructUserIDToEmailMap,
    createAlbum,
    createUnCategorizedCollection,
    getAllLatestCollections,
    getAllLocalCollections,
} from "services/collectionService";
import { syncFiles } from "services/fileService";
import { preFileInfoSync, sync } from "services/sync";
import { syncTrash } from "services/trashService";
import uploadManager from "services/upload/uploadManager";
import { isTokenValid } from "services/userService";
import {
    GalleryContextType,
    SelectedState,
    SetFilesDownloadProgressAttributes,
    SetFilesDownloadProgressAttributesCreator,
} from "types/gallery";
import { checkSubscriptionPurchase } from "utils/billing";
import {
    COLLECTION_OPS_TYPE,
    getSelectedCollection,
    handleCollectionOps,
} from "utils/collection";
import { FILE_OPS_TYPE, getSelectedFiles, handleFileOps } from "utils/file";
import { getSessionExpiredMessage } from "utils/ui";
import { getLocalFamilyData } from "utils/user/family";

const defaultGalleryContext: GalleryContextType = {
    showPlanSelectorModal: () => null,
    setActiveCollectionID: () => null,
    onShowCollection: () => null,
    syncWithRemote: () => null,
    setBlockingLoad: () => null,
    photoListHeader: null,
    openExportModal: () => null,
    authenticateUser: () => null,
    user: null,
    userIDToEmailMap: null,
    emailList: null,
    openHiddenSection: () => null,
    isClipSearchResult: null,
    selectedFile: null,
    setSelectedFiles: () => null,
};

export const GalleryContext = createContext<GalleryContextType>(
    defaultGalleryContext,
);

/**
 * The default view for logged in users.
 *
 * I heard you like ASCII art.
 *
 *        Navbar / Search         ^
 *     ---------------------      |
 *          Gallery Bar         sticky
 *     ---------------------   ---/---
 *       Photo List Header    scrollable
 *     ---------------------      |
 *           Photo List           v
 */
export default function Gallery() {
    const [state, dispatch] = useGalleryReducer();

    const [isFirstLoad, setIsFirstLoad] = useState(false);
    const [selected, setSelected] = useState<SelectedState>({
        ownCount: 0,
        count: 0,
        collectionID: 0,
        context: { mode: "albums", collectionID: ALL_SECTION },
    });
    const [planModalView, setPlanModalView] = useState(false);
    const [blockingLoad, setBlockingLoad] = useState(false);
    const [collectionNamerAttributes, setCollectionNamerAttributes] =
        useState<CollectionNamerAttributes>(null);
    const [collectionNamerView, setCollectionNamerView] = useState(false);
    const [shouldDisableDropzone, setShouldDisableDropzone] = useState(false);
    const [isPhotoSwipeOpen, setIsPhotoSwipeOpen] = useState(false);

    const {
        // A function to call to get the props we should apply to the container,
        getRootProps: getDragAndDropRootProps,
        // ... the props we should apply to the <input> element,
        getInputProps: getDragAndDropInputProps,
        // ... and the files that we got.
        acceptedFiles: dragAndDropFiles,
    } = useDropzone({
        noClick: true,
        noKeyboard: true,
        disabled: shouldDisableDropzone,
    });
    const {
        getInputProps: getFileSelectorInputProps,
        openSelector: openFileSelector,
        selectedFiles: fileSelectorFiles,
    } = useFileInput({
        directory: false,
    });
    const {
        getInputProps: getFolderSelectorInputProps,
        openSelector: openFolderSelector,
        selectedFiles: folderSelectorFiles,
    } = useFileInput({
        directory: true,
    });
    const {
        getInputProps: getZipFileSelectorInputProps,
        openSelector: openZipFileSelector,
        selectedFiles: fileSelectorZipFiles,
    } = useFileInput({
        directory: false,
        accept: ".zip",
    });

    const syncInProgress = useRef(false);
    const syncInterval = useRef<NodeJS.Timeout>();
    const resync = useRef<{ force: boolean; silent: boolean }>();

    const {
        startLoading,
        finishLoading,
        setDialogMessage,
        logout,
        ...appContext
    } = useContext(AppContext);
    const [userIDToEmailMap, setUserIDToEmailMap] =
        useState<Map<number, string>>(null);
    const [emailList, setEmailList] = useState<string[]>(null);
    const [fixCreationTimeView, setFixCreationTimeView] = useState(false);
    const [fixCreationTimeAttributes, setFixCreationTimeAttributes] =
        useState<FixCreationTimeAttributes>(null);

    const showPlanSelectorModal = () => setPlanModalView(true);

    const [uploadTypeSelectorView, setUploadTypeSelectorView] = useState(false);
    const [uploadTypeSelectorIntent, setUploadTypeSelectorIntent] =
        useState<UploadTypeSelectorIntent>("upload");

    const [sidebarView, setSidebarView] = useState(false);

    const closeSidebar = () => setSidebarView(false);
    const openSidebar = () => setSidebarView(true);

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

    // The option selected by the user selected from the search bar dropdown.
    const [selectedSearchOption, setSelectedSearchOption] = useState<
        SearchOption | undefined
    >();

    const peopleState = usePeopleStateSnapshot();

    const [isClipSearchResult, setIsClipSearchResult] =
        useState<boolean>(false);

    // The (non-sticky) header shown at the top of the gallery items.
    const [photoListHeader, setPhotoListHeader] =
        useState<TimeStampListItem>(null);

    const [
        filesDownloadProgressAttributesList,
        setFilesDownloadProgressAttributesList,
    ] = useState<FilesDownloadProgressAttributes[]>([]);

    // tempDeletedFileIds and tempHiddenFileIds are used to keep track of files
    // that are deleted/hidden in the current session but not yet synced with
    // the server.
    const [tempDeletedFileIds, setTempDeletedFileIds] = useState(
        new Set<number>(),
    );
    const [tempHiddenFileIds, setTempHiddenFileIds] = useState(
        new Set<number>(),
    );

    const [openCollectionSelector, setOpenCollectionSelector] = useState(false);
    const [collectionSelectorAttributes, setCollectionSelectorAttributes] =
        useState<CollectionSelectorAttributes | undefined>();

    const { show: showWhatsNew, props: whatsNewVisibilityProps } =
        useModalVisibility();

    // TODO: Temp
    const user = state.user;
    const familyData = state.familyData;
    const collections = state.collections;
    const hiddenCollections = state.hiddenCollections;
    const files = state.files;
    const hiddenFiles = state.hiddenFiles;
    const trashedFiles = state.trashedFiles;
    const archivedCollectionIDs = state.archivedCollectionIDs;
    const defaultHiddenCollectionIDs = state.defaultHiddenCollectionIDs;
    const hiddenFileIDs = state.hiddenFileIDs;
    const collectionNameMap = state.allCollectionNameByID;
    const fileToCollectionsMap = state.fileCollectionIDs;
    const collectionSummaries = state.collectionSummaries;
    const hiddenCollectionSummaries = state.hiddenCollectionSummaries;
    const barMode = state.barMode ?? "albums";
    const activeCollectionID = state.activeCollectionID;
    const activePersonID = state.activePersonID;
    const isInSearchMode = state.isInSearchMode;

    if (process.env.NEXT_PUBLIC_ENTE_WIP_CL) {
        console.log("render", { collections, hiddenCollections, files });
    }

    const router = useRouter();

    // Ensure that the keys in local storage are not malformed by verifying that
    // the recoveryKey can be decrypted with the masterKey.
    // Note: This is not bullet-proof.
    const validateKey = async () => {
        try {
            await getRecoveryKey();
            return true;
        } catch (e) {
            logout();
            return false;
        }
    };

    useEffect(() => {
        appContext.showNavBar(true);
        const key = getKey(SESSION_KEYS.ENCRYPTION_KEY);
        const token = getToken();
        if (!key || !token) {
            stashRedirect(PAGES.GALLERY);
            router.push("/");
            return;
        }
        preloadImage("/images/subscription-card-background");
        const electron = globalThis.electron;
        const main = async () => {
            const valid = await validateKey();
            if (!valid) {
                return;
            }
            await downloadManager.init(token);
            setupSelectAllKeyBoardShortcutHandler();
            dispatch({ type: "showAll" });
            setIsFirstLoad(isFirstLogin());
            if (justSignedUp()) {
                setPlanModalView(true);
            }
            setIsFirstLogin(false);
            const user = getData(LS_KEYS.USER);
            const familyData = getLocalFamilyData();
            const files = sortFiles(
                mergeMetadata(await getLocalFiles("normal")),
            );
            const hiddenFiles = sortFiles(
                mergeMetadata(await getLocalFiles("hidden")),
            );
            const allCollections = await getAllLocalCollections();
            const trashedFiles = await getLocalTrashedFiles();
            dispatch({
                type: "mount",
                user,
                familyData,
                allCollections,
                files,
                hiddenFiles,
                trashedFiles,
            });
            await syncWithRemote(true);
            setIsFirstLoad(false);
            setJustSignedUp(false);
            syncInterval.current = setInterval(
                () => syncWithRemote(false, true),
                5 * 60 * 1000 /* 5 minutes */,
            );
            if (electron) {
                electron.onMainWindowFocus(() => syncWithRemote(false, true));
                if (await shouldShowWhatsNew(electron)) showWhatsNew();
            }
        };
        main();
        return () => {
            clearInterval(syncInterval.current);
            if (electron) electron.onMainWindowFocus(undefined);
        };
    }, []);

    useEffect(
        () =>
            setSearchCollectionsAndFiles({
                collections: collections ?? [],
                files: uniqueFilesByID(files ?? []),
            }),
        [collections, files],
    );

    useEffect(() => {
        if (!collections || !user) {
            return;
        }
        const userIdToEmailMap = constructUserIDToEmailMap(user, collections);
        setUserIDToEmailMap(userIdToEmailMap);
    }, [collections]);

    useEffect(() => {
        if (!user || !collections) {
            return;
        }
        const emailList = constructEmailList(user, collections, familyData);
        setEmailList(emailList);
    }, [user, collections, familyData]);

    useEffect(() => {
        collectionNamerAttributes && setCollectionNamerView(true);
    }, [collectionNamerAttributes]);
    useEffect(() => {
        fixCreationTimeAttributes && setFixCreationTimeView(true);
    }, [fixCreationTimeAttributes]);

    useEffect(() => {
        if (typeof activeCollectionID === "undefined" || !router.isReady) {
            return;
        }
        let collectionURL = "";
        if (activeCollectionID !== ALL_SECTION) {
            // TODO: Is this URL param even used?
            collectionURL = `?collection=${activeCollectionID}`;
        }
        const href = `/gallery${collectionURL}`;
        router.push(href, undefined, { shallow: true });
    }, [activeCollectionID, router.isReady]);

    useEffect(() => {
        const key = getKey(SESSION_KEYS.ENCRYPTION_KEY);
        if (router.isReady && key) {
            checkSubscriptionPurchase(
                setDialogMessage,
                router,
                setBlockingLoad,
            );
        }
    }, [router.isReady]);

    useEffect(() => {
        if (isInSearchMode && selectedSearchOption) {
            setPhotoListHeader({
                height: 104,
                item: (
                    <SearchResultsHeader
                        selectedOption={selectedSearchOption}
                    />
                ),
                itemType: ITEM_TYPE.HEADER,
            });
        }
    }, [isInSearchMode, selectedSearchOption]);

    const activeCollection = useMemo(() => {
        if (!collections || !hiddenCollections) {
            return null;
        }
        return [...collections, ...hiddenCollections].find(
            (collection) => collection.id === activeCollectionID,
        );
    }, [collections, activeCollectionID]);

    // TODO: Make this a normal useEffect.
    useMemoSingleThreaded(async () => {
        if (
            !files ||
            !user ||
            !trashedFiles ||
            !hiddenFiles ||
            !archivedCollectionIDs
        ) {
            dispatch({
                type: "set",
                filteredData: [],
                galleryPeopleState: undefined,
            });
            return;
        }

        let filteredFiles: EnteFile[] = [];
        let galleryPeopleState:
            | { activePerson: Person | undefined; people: Person[] }
            | undefined;
        if (selectedSearchOption) {
            filteredFiles = await filterSearchableFiles(
                selectedSearchOption.suggestion,
            );
        } else if (barMode == "people") {
            let filteredPeople = peopleState?.people ?? [];
            let filteredVisiblePeople = peopleState?.visiblePeople ?? [];
            if (tempDeletedFileIds?.size ?? tempHiddenFileIds?.size) {
                // Prune the in-memory temp updates from the actual state to
                // obtain the UI state. Kept inside an preflight check to so
                // that the common path remains fast.
                const filterTemp = (ps: Person[]) =>
                    ps
                        .map((p) => ({
                            ...p,
                            fileIDs: p.fileIDs.filter(
                                (id) =>
                                    !tempDeletedFileIds?.has(id) &&
                                    !tempHiddenFileIds?.has(id),
                            ),
                        }))
                        .filter((p) => p.fileIDs.length > 0);
                filteredPeople = filterTemp(filteredPeople);
                filteredVisiblePeople = filterTemp(filteredVisiblePeople);
            }
            const findByID = (ps: Person[]) =>
                ps.find((p) => p.id == activePersonID);
            let activePerson = findByID(filteredVisiblePeople);
            if (!activePerson) {
                // This might be one of the normally hidden small clusters.
                activePerson = findByID(filteredPeople);
                if (activePerson) {
                    // Temporarily add this person's entry to the list of people
                    // surfaced in the people section.
                    filteredVisiblePeople.push(activePerson);
                } else {
                    // We don't have an "All" pseudo-album in people mode, so
                    // default to the first person in the list.
                    activePerson = filteredVisiblePeople[0];
                }
            }
            const pfSet = new Set(activePerson?.fileIDs ?? []);
            filteredFiles = uniqueFilesByID(
                files.filter(({ id }) => {
                    if (!pfSet.has(id)) return false;
                    return true;
                }),
            );
            galleryPeopleState = {
                activePerson,
                people: filteredVisiblePeople,
            };
        } else if (activeCollectionID === TRASH_SECTION) {
            filteredFiles = uniqueFilesByID([
                ...trashedFiles,
                ...files.filter((file) => tempDeletedFileIds?.has(file.id)),
            ]);
        } else {
            const baseFiles = barMode == "hidden-albums" ? hiddenFiles : files;
            filteredFiles = uniqueFilesByID(
                baseFiles.filter((item) => {
                    if (tempDeletedFileIds?.has(item.id)) {
                        return false;
                    }

                    if (
                        barMode != "hidden-albums" &&
                        tempHiddenFileIds?.has(item.id)
                    ) {
                        return false;
                    }

                    // archived collections files can only be seen in their respective collection
                    if (archivedCollectionIDs.has(item.collectionID)) {
                        if (activeCollectionID === item.collectionID) {
                            return true;
                        } else {
                            return false;
                        }
                    }

                    // HIDDEN ITEMS SECTION - show all individual hidden files
                    if (
                        activeCollectionID === HIDDEN_ITEMS_SECTION &&
                        defaultHiddenCollectionIDs.has(item.collectionID)
                    ) {
                        return true;
                    }

                    // Archived files can only be seen in archive section or their respective collection
                    if (isArchivedFile(item)) {
                        if (
                            activeCollectionID === ARCHIVE_SECTION ||
                            activeCollectionID === item.collectionID
                        ) {
                            return true;
                        } else {
                            return false;
                        }
                    }

                    // ALL SECTION - show all files
                    if (activeCollectionID === ALL_SECTION) {
                        // show all files except the ones in hidden collections
                        if (hiddenFileIDs.has(item.id)) {
                            return false;
                        } else {
                            return true;
                        }
                    }

                    // COLLECTION SECTION - show files in the active collection
                    if (activeCollectionID === item.collectionID) {
                        return true;
                    } else {
                        return false;
                    }
                }),
            );
            const sortAsc =
                activeCollection?.pubMagicMetadata?.data?.asc ?? false;
            if (sortAsc) {
                filteredFiles = sortFiles(filteredFiles, true);
            }
        }

        dispatch({
            type: "set",
            filteredData: filteredFiles,
            galleryPeopleState,
        });
    }, [
        barMode,
        files,
        trashedFiles,
        hiddenFiles,
        tempDeletedFileIds,
        tempHiddenFileIds,
        hiddenFileIDs,
        selectedSearchOption,
        activeCollectionID,
        archivedCollectionIDs,
        peopleState,
        activePersonID,
    ]);

    const { filteredData, ...galleryPeopleState } = state;

    const selectAll = (e: KeyboardEvent) => {
        // ignore ctrl/cmd + a if the user is typing in a text field
        if (
            e.target instanceof HTMLInputElement ||
            e.target instanceof HTMLTextAreaElement
        ) {
            return;
        }
        // if any of the modals are open, don't select all
        if (
            sidebarView ||
            uploadTypeSelectorView ||
            openCollectionSelector ||
            collectionNamerView ||
            fixCreationTimeView ||
            planModalView ||
            exportModalView ||
            authenticateUserModalView ||
            isPhotoSwipeOpen ||
            !filteredData?.length ||
            !user
        ) {
            return;
        }
        e.preventDefault();
        const selected = {
            ownCount: 0,
            count: 0,
            collectionID: activeCollectionID,
            context:
                barMode == "people" && galleryPeopleState?.activePerson?.id
                    ? {
                          mode: "people" as const,
                          personID: galleryPeopleState.activePerson.id,
                      }
                    : {
                          mode: barMode as "albums" | "hidden-albums",
                          collectionID: ensure(activeCollectionID),
                      },
        };

        filteredData.forEach((item) => {
            if (item.ownerID === user.id) {
                selected.ownCount++;
            }
            selected.count++;
            selected[item.id] = true;
        });
        setSelected(selected);
    };

    const clearSelection = () => {
        if (!selected?.count) {
            return;
        }
        setSelected({
            ownCount: 0,
            count: 0,
            collectionID: 0,
            context: undefined,
        });
    };

    const keyboardShortcutHandlerRef = useRef({
        selectAll,
        clearSelection,
    });

    useEffect(() => {
        keyboardShortcutHandlerRef.current = {
            selectAll,
            clearSelection,
        };
    }, [selectAll, clearSelection]);

    const showSessionExpiredMessage = () => {
        setDialogMessage(getSessionExpiredMessage(logout));
    };

    const syncWithRemote = async (force = false, silent = false) => {
        if (!navigator.onLine) return;
        if (syncInProgress.current && !force) {
            resync.current = { force, silent };
            return;
        }
        const isForced = syncInProgress.current && force;
        syncInProgress.current = true;
        try {
            const token = getToken();
            if (!token) {
                return;
            }
            const tokenValid = await isTokenValid(token);
            if (!tokenValid) {
                throw new Error(CustomError.SESSION_EXPIRED);
            }
            !silent && startLoading();
            await preFileInfoSync();
            const allCollections = await getAllLatestCollections();
            const [hiddenCollections, collections] = splitByPredicate(
                allCollections,
                isHiddenCollection,
            );
            dispatch({
                type: "setAllCollections",
                collections,
                hiddenCollections,
            });
            await syncFiles(
                "normal",
                collections,
                (files) => dispatch({ type: "resetFiles", files }),
                (files) => dispatch({ type: "fetchFiles", files }),
            );
            await syncFiles(
                "hidden",
                hiddenCollections,
                (hiddenFiles) =>
                    dispatch({ type: "resetHiddenFiles", hiddenFiles }),
                (hiddenFiles) =>
                    dispatch({ type: "fetchHiddenFiles", hiddenFiles }),
            );
            await syncTrash(allCollections, (trashedFiles: EnteFile[]) =>
                dispatch({ type: "setTrashedFiles", trashedFiles }),
            );
            // syncWithRemote is called with the force flag set to true before
            // doing an upload. So it is possible, say when resuming a pending
            // upload, that we get two syncWithRemotes happening in parallel.
            //
            // Do the non-file-related sync only for one of these parallel ones.
            if (!isForced) {
                await sync();
            }
        } catch (e) {
            switch (e.message) {
                case CustomError.SESSION_EXPIRED:
                    showSessionExpiredMessage();
                    break;
                case CustomError.KEY_MISSING:
                    clearKeys();
                    router.push(PAGES.CREDENTIALS);
                    break;
                default:
                    log.error("syncWithRemote failed", e);
            }
        } finally {
            setTempDeletedFileIds(new Set());
            setTempHiddenFileIds(new Set());
            !silent && finishLoading();
        }
        syncInProgress.current = false;
        if (resync.current) {
            const { force, silent } = resync.current;
            setTimeout(() => syncWithRemote(force, silent), 0);
            resync.current = null;
        }
    };

    const setupSelectAllKeyBoardShortcutHandler = () => {
        const handleKeyUp = (e: KeyboardEvent) => {
            switch (e.key) {
                case "Escape":
                    keyboardShortcutHandlerRef.current.clearSelection();
                    break;
                case "a":
                    if (e.ctrlKey || e.metaKey) {
                        keyboardShortcutHandlerRef.current.selectAll(e);
                    }
                    break;
            }
        };
        document.addEventListener("keydown", handleKeyUp);
        return () => {
            document.removeEventListener("keydown", handleKeyUp);
        };
    };

    const setFilesDownloadProgressAttributesCreator: SetFilesDownloadProgressAttributesCreator =
        (folderName, collectionID, isHidden) => {
            const id = filesDownloadProgressAttributesList?.length ?? 0;
            const updater: SetFilesDownloadProgressAttributes = (value) => {
                setFilesDownloadProgressAttributesList((prev) => {
                    const attributes = prev?.find((attr) => attr.id === id);
                    const updatedAttributes =
                        typeof value === "function"
                            ? value(attributes)
                            : { ...attributes, ...value };
                    const updatedAttributesList = attributes
                        ? prev.map((attr) =>
                              attr.id === id ? updatedAttributes : attr,
                          )
                        : [...prev, updatedAttributes];

                    return updatedAttributesList;
                });
            };
            updater({
                id,
                folderName,
                collectionID,
                isHidden,
                canceller: null,
                total: 0,
                success: 0,
                failed: 0,
                downloadDirPath: null,
            });
            return updater;
        };

    const collectionOpsHelper =
        (ops: COLLECTION_OPS_TYPE) => async (collection: Collection) => {
            startLoading();
            try {
                setOpenCollectionSelector(false);
                const selectedFiles = getSelectedFiles(selected, filteredData);
                const toProcessFiles =
                    ops === COLLECTION_OPS_TYPE.REMOVE
                        ? selectedFiles
                        : selectedFiles.filter(
                              (file) => file.ownerID === user.id,
                          );
                if (toProcessFiles.length > 0) {
                    await handleCollectionOps(
                        ops,
                        collection,
                        toProcessFiles,
                        selected.collectionID,
                    );
                }
                clearSelection();
                await syncWithRemote(false, true);
            } catch (e) {
                log.error(`collection ops (${ops}) failed`, e);
                setDialogMessage({
                    title: t("error"),

                    close: { variant: "critical" },
                    content: t("generic_error_retry"),
                });
            } finally {
                finishLoading();
            }
        };

    const fileOpsHelper = (ops: FILE_OPS_TYPE) => async () => {
        startLoading();
        try {
            // passing files here instead of filteredData for hide ops because we want to move all files copies to hidden collection
            const selectedFiles = getSelectedFiles(
                selected,
                ops === FILE_OPS_TYPE.HIDE ? files : filteredData,
            );
            const toProcessFiles =
                ops === FILE_OPS_TYPE.DOWNLOAD
                    ? selectedFiles
                    : selectedFiles.filter((file) => file.ownerID === user.id);
            if (toProcessFiles.length > 0) {
                await handleFileOps(
                    ops,
                    toProcessFiles,
                    setTempDeletedFileIds,
                    setTempHiddenFileIds,
                    setFixCreationTimeAttributes,
                    setFilesDownloadProgressAttributesCreator,
                );
            }
            clearSelection();
            await syncWithRemote(false, true);
        } catch (e) {
            log.error(`file ops (${ops}) failed`, e);
            setDialogMessage({
                title: t("error"),

                close: { variant: "critical" },
                content: t("generic_error_retry"),
            });
        } finally {
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
                log.error(`create and collection ops (${ops}) failed`, e);
                setDialogMessage({
                    title: t("error"),

                    close: { variant: "critical" },
                    content: t("generic_error_retry"),
                });
            } finally {
                finishLoading();
            }
        };
        return () =>
            setCollectionNamerAttributes({
                title: t("new_album"),
                buttonText: t("CREATE"),
                autoFilledName: "",
                callback,
            });
    };

    const handleSelectSearchOption = (
        searchOption: SearchOption | undefined,
    ) => {
        const type = searchOption?.suggestion.type;
        if (type == "collection" || type == "person") {
            if (type == "collection") {
                dispatch({
                    type: "showNormalOrHiddenCollectionSummary",
                    collectionSummaryID: searchOption.suggestion.collectionID,
                });
            } else {
                dispatch({
                    type: "showPerson",
                    personID: searchOption.suggestion.person.id,
                });
            }
            setSelectedSearchOption(undefined);
        } else if (searchOption) {
            dispatch({ type: "enterSearchMode" });
            setSelectedSearchOption(searchOption);
        } else {
            dispatch({ type: "exitSearch" });
            setSelectedSearchOption(undefined);
        }
        setIsClipSearchResult(type == "clip");
    };

    const openUploader = (intent?: UploadTypeSelectorIntent) => {
        if (!uploadManager.shouldAllowNewUpload()) {
            return;
        }
        setUploadTypeSelectorView(true);
        setUploadTypeSelectorIntent(intent ?? "upload");
    };

    const openExportModal = () => {
        setExportModalView(true);
    };

    const closeExportModal = () => {
        setExportModalView(false);
    };

    const handleSetActiveCollectionID = (
        collectionSummaryID: number | undefined,
    ) =>
        dispatch({
            type: "showNormalOrHiddenCollectionSummary",
            collectionSummaryID,
        });

    const handleChangeBarMode = (mode: GalleryBarMode) =>
        mode == "people"
            ? dispatch({ type: "showPeople" })
            : dispatch({ type: "showAll" });

    const openHiddenSection: GalleryContextType["openHiddenSection"] = (
        callback,
    ) => {
        authenticateUser(() => {
            dispatch({ type: "showHidden" });
            callback?.();
        });
    };

    const handleSelectPerson = (person: Person | undefined) =>
        person
            ? dispatch({ type: "showPerson", personID: person.id })
            : dispatch({ type: "showPeople" });

    const handleOpenCollectionSelector = useCallback(
        (attributes: CollectionSelectorAttributes) => {
            setCollectionSelectorAttributes(attributes);
            setOpenCollectionSelector(true);
        },
        [],
    );

    const handleCloseCollectionSelector = useCallback(
        () => setOpenCollectionSelector(false),
        [],
    );

    if (!user || !filteredData) {
        // Don't render until we get the logged in user and dispatch "mount".
        return <div></div>;
    }

    // `peopleState` will be undefined only when ML is disabled, otherwise it'll
    // be contain empty arrays (even if people are loading).
    const showPeopleSectionButton = peopleState !== undefined;

    return (
        <GalleryContext.Provider
            value={{
                ...defaultGalleryContext,
                showPlanSelectorModal,
                setActiveCollectionID: handleSetActiveCollectionID,
                onShowCollection: (id) =>
                    dispatch({
                        type: "showNormalOrHiddenCollectionSummary",
                        collectionSummaryID: id,
                    }),
                syncWithRemote,
                setBlockingLoad,
                photoListHeader,
                openExportModal,
                authenticateUser,
                userIDToEmailMap,
                user,
                emailList,
                openHiddenSection,
                isClipSearchResult,
                selectedFile: selected,
                setSelectedFiles: setSelected,
            }}
        >
            <FullScreenDropZone {...{ getDragAndDropRootProps }}>
                <UploadSelectorInputs
                    {...{
                        getDragAndDropInputProps,
                        getFileSelectorInputProps,
                        getFolderSelectorInputProps,
                        getZipFileSelectorInputProps,
                    }}
                />
                {blockingLoad && (
                    <LoadingOverlay>
                        <ActivityIndicator />
                    </LoadingOverlay>
                )}
                {isFirstLoad && (
                    <CenteredFlex>
                        <Typography color="text.muted" variant="small">
                            {t("INITIAL_LOAD_DELAY_WARNING")}
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
                    open={openCollectionSelector}
                    onClose={handleCloseCollectionSelector}
                    attributes={collectionSelectorAttributes}
                    collectionSummaries={collectionSummaries}
                    collectionForCollectionID={(id) =>
                        findCollectionCreatingUncategorizedIfNeeded(
                            collections,
                            id,
                        )
                    }
                />
                <FilesDownloadProgress
                    attributesList={filesDownloadProgressAttributesList}
                    setAttributesList={setFilesDownloadProgressAttributesList}
                />
                <FixCreationTime
                    isOpen={fixCreationTimeView}
                    hide={() => setFixCreationTimeView(false)}
                    attributes={fixCreationTimeAttributes}
                />

                <NavbarBase
                    sx={{
                        background: "transparent",
                        position: "absolute",
                        // Override the default 16px we get from NavbarBase
                        marginBottom: "12px",
                    }}
                >
                    {barMode == "hidden-albums" ? (
                        <HiddenSectionNavbarContents
                            onBack={() => dispatch({ type: "showAll" })}
                        />
                    ) : (
                        <NormalNavbarContents
                            {...{
                                openSidebar,
                                openUploader,
                                isInSearchMode,
                                onShowSearchInput: () =>
                                    dispatch({ type: "enterSearchMode" }),
                                onSelectSearchOption: handleSelectSearchOption,
                                onSelectPerson: handleSelectPerson,
                            }}
                        />
                    )}
                </NavbarBase>

                <GalleryBarAndListHeader
                    {...{
                        shouldHide: isInSearchMode,
                        mode: barMode,
                        onChangeMode: handleChangeBarMode,
                        collectionSummaries,
                        activeCollection,
                        activeCollectionID,
                        setActiveCollectionID: handleSetActiveCollectionID,
                        hiddenCollectionSummaries,
                        showPeopleSectionButton,
                        people: galleryPeopleState?.people ?? [],
                        activePerson: galleryPeopleState?.activePerson,
                        onSelectPerson: handleSelectPerson,
                        setCollectionNamerAttributes,
                        setPhotoListHeader,
                        setFilesDownloadProgressAttributesCreator,
                        filesDownloadProgressAttributesList,
                    }}
                />

                <Uploader
                    activeCollection={activeCollection}
                    syncWithRemote={syncWithRemote}
                    closeUploadTypeSelector={setUploadTypeSelectorView.bind(
                        null,
                        false,
                    )}
                    onOpenCollectionSelector={handleOpenCollectionSelector}
                    onCloseCollectionSelector={handleCloseCollectionSelector}
                    setLoading={setBlockingLoad}
                    setCollectionNamerAttributes={setCollectionNamerAttributes}
                    setShouldDisableDropzone={setShouldDisableDropzone}
                    onUploadFile={(file) =>
                        dispatch({ type: "uploadFile", file })
                    }
                    setCollections={(collections) =>
                        dispatch({ type: "setNormalCollections", collections })
                    }
                    isFirstUpload={areOnlySystemCollections(
                        collectionSummaries,
                    )}
                    {...{
                        dragAndDropFiles,
                        openFileSelector,
                        fileSelectorFiles,
                        openFolderSelector,
                        folderSelectorFiles,
                        openZipFileSelector,
                        fileSelectorZipFiles,
                        uploadTypeSelectorIntent,
                        uploadTypeSelectorView,
                        showSessionExpiredMessage,
                    }}
                />
                <Sidebar
                    collectionSummaries={collectionSummaries}
                    sidebarView={sidebarView}
                    closeSidebar={closeSidebar}
                />
                <WhatsNew {...whatsNewVisibilityProps} />
                {!isInSearchMode &&
                !isFirstLoad &&
                !files?.length &&
                !hiddenFiles?.length &&
                activeCollectionID === ALL_SECTION ? (
                    <GalleryEmptyState openUploader={openUploader} />
                ) : !isInSearchMode &&
                  !isFirstLoad &&
                  barMode == "people" &&
                  !galleryPeopleState?.activePerson ? (
                    <PeopleEmptyState />
                ) : (
                    <PhotoFrame
                        page={PAGES.GALLERY}
                        mode={barMode}
                        modePlus={isInSearchMode ? "search" : barMode}
                        files={filteredData}
                        syncWithRemote={syncWithRemote}
                        favItemIds={state.favoriteFileIDs}
                        setSelected={setSelected}
                        selected={selected}
                        tempDeletedFileIds={tempDeletedFileIds}
                        setTempDeletedFileIds={setTempDeletedFileIds}
                        setIsPhotoSwipeOpen={setIsPhotoSwipeOpen}
                        activeCollectionID={activeCollectionID}
                        activePersonID={galleryPeopleState?.activePerson?.id}
                        enableDownload={true}
                        fileToCollectionsMap={fileToCollectionsMap}
                        collectionNameMap={collectionNameMap}
                        showAppDownloadBanner={
                            files.length < 30 && !isInSearchMode
                        }
                        isInHiddenSection={barMode == "hidden-albums"}
                        setFilesDownloadProgressAttributesCreator={
                            setFilesDownloadProgressAttributesCreator
                        }
                        selectable={true}
                        onSelectPerson={(personID) => {
                            dispatch({ type: "showPerson", personID });
                        }}
                    />
                )}
                {selected.count > 0 &&
                    selected.collectionID === activeCollectionID && (
                        <SelectedFileOptions
                            handleCollectionOps={collectionOpsHelper}
                            handleFileOps={fileOpsHelper}
                            showCreateCollectionModal={
                                showCreateCollectionModal
                            }
                            onOpenCollectionSelector={
                                handleOpenCollectionSelector
                            }
                            count={selected.count}
                            ownCount={selected.ownCount}
                            clearSelection={clearSelection}
                            barMode={barMode}
                            activeCollectionID={activeCollectionID}
                            selectedCollection={getSelectedCollection(
                                selected.collectionID,
                                collections,
                            )}
                            isFavoriteCollection={
                                collectionSummaries.get(activeCollectionID)
                                    ?.type == "favorites"
                            }
                            isUncategorizedCollection={
                                collectionSummaries.get(activeCollectionID)
                                    ?.type == "uncategorized"
                            }
                            isIncomingSharedCollection={
                                collectionSummaries.get(activeCollectionID)
                                    ?.type == "incomingShareCollaborator" ||
                                collectionSummaries.get(activeCollectionID)
                                    ?.type == "incomingShareViewer"
                            }
                            isInSearchMode={isInSearchMode}
                            isInHiddenSection={barMode == "hidden-albums"}
                        />
                    )}
                <ExportModal
                    show={exportModalView}
                    onHide={closeExportModal}
                    collectionNameMap={collectionNameMap}
                />
                <AuthenticateUserModal
                    open={authenticateUserModalView}
                    onClose={closeAuthenticateUserModal}
                    onAuthenticate={onAuthenticateCallback.current}
                />
            </FullScreenDropZone>
        </GalleryContext.Provider>
    );
}

/**
 * Preload all three variants of a responsive image.
 */
const preloadImage = (imgBasePath: string) => {
    const srcset = [];
    for (let i = 1; i <= 3; i++) srcset.push(`${imgBasePath}/${i}x.png ${i}x`);
    new Image().srcset = srcset.join(",");
};

type NormalNavbarContentsProps = SearchBarProps & {
    openSidebar: () => void;
    openUploader: () => void;
};

const NormalNavbarContents: React.FC<NormalNavbarContentsProps> = ({
    openSidebar,
    openUploader,
    ...props
}) => (
    <>
        {!props.isInSearchMode && <SidebarButton onClick={openSidebar} />}
        <SearchBar {...props} />
        {!props.isInSearchMode && <UploadButton onClick={openUploader} />}
    </>
);

const SidebarButton: React.FC<IconButtonProps> = (props) => (
    <IconButton {...props}>
        <MenuIcon />
    </IconButton>
);

const UploadButton: React.FC<ButtonProps & IconButtonProps> = (props) => {
    const disabled = !uploadManager.shouldAllowNewUpload();
    const isSmallWidth = useIsSmallWidth();

    const icon = <FileUploadOutlinedIcon />;

    return (
        <Box>
            {isSmallWidth ? (
                <IconButton {...props} disabled={disabled}>
                    {icon}
                </IconButton>
            ) : (
                <Button
                    {...props}
                    disabled={disabled}
                    color={"secondary"}
                    startIcon={icon}
                >
                    {t("upload")}
                </Button>
            )}
        </Box>
    );
};

interface HiddenSectionNavbarContentsProps {
    onBack: () => void;
}

const HiddenSectionNavbarContents: React.FC<
    HiddenSectionNavbarContentsProps
> = ({ onBack }) => (
    <HorizontalFlex
        gap={"24px"}
        sx={{
            width: "100%",
            background: (theme) => theme.palette.background.default,
        }}
    >
        <IconButton onClick={onBack}>
            <ArrowBack />
        </IconButton>
        <FlexWrapper>
            <Typography>{t("section_hidden")}</Typography>
        </FlexWrapper>
    </HorizontalFlex>
);

/**
 * Return the {@link Collection} (from amongst {@link collections}) with the
 * given {@link collectionID}. As a special case, if collection ID is the
 * placeholder ID of the uncategorized collection, create it and then return it.
 */
const findCollectionCreatingUncategorizedIfNeeded = async (
    collections: Collection[],
    collectionID: number,
) => {
    if (collectionID == DUMMY_UNCATEGORIZED_COLLECTION) {
        return await createUnCategorizedCollection();
    } else {
        return collections.find((c) => c.id === collectionID);
    }
};
