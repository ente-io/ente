import { sessionExpiredDialogAttributes } from "@/accounts/components/utils/dialog";
import { stashRedirect } from "@/accounts/services/redirect";
import type { MiniDialogAttributes } from "@/base/components/MiniDialog";
import { NavbarBase } from "@/base/components/Navbar";
import { ActivityIndicator } from "@/base/components/mui/ActivityIndicator";
import { errorDialogAttributes } from "@/base/components/utils/dialog";
import { useIsSmallWidth } from "@/base/components/utils/hooks";
import { useModalVisibility } from "@/base/components/utils/modal";
import log from "@/base/log";
import { type Collection } from "@/media/collection";
import { mergeMetadata, type EnteFile } from "@/media/file";
import {
    CollectionSelector,
    type CollectionSelectorAttributes,
} from "@/new/photos/components/CollectionSelector";
import { PlanSelector } from "@/new/photos/components/PlanSelector";
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
    useGalleryReducer,
    type GalleryBarMode,
} from "@/new/photos/components/gallery/reducer";
import { usePeopleStateSnapshot } from "@/new/photos/components/utils/use-snapshot";
import { shouldShowWhatsNew } from "@/new/photos/services/changelog";
import {
    ALL_SECTION,
    DUMMY_UNCATEGORIZED_COLLECTION,
    isHiddenCollection,
} from "@/new/photos/services/collection";
import { areOnlySystemCollections } from "@/new/photos/services/collection/ui";
import {
    getLocalFiles,
    getLocalTrashedFiles,
    sortFiles,
} from "@/new/photos/services/files";
import {
    filterSearchableFiles,
    setSearchCollectionsAndFiles,
} from "@/new/photos/services/search";
import type { SearchOption } from "@/new/photos/services/search/types";
import { initSettings } from "@/new/photos/services/settings";
import {
    initUserDetailsOrTriggerSync,
    redirectToCustomerPortal,
    userDetailsSnapshot,
    verifyStripeSubscription,
} from "@/new/photos/services/user-details";
import { useAppContext } from "@/new/photos/types/context";
import { splitByPredicate } from "@/utils/array";
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
import { Export } from "components/Export";
import {
    FilesDownloadProgress,
    FilesDownloadProgressAttributes,
} from "components/FilesDownloadProgress";
import { FixCreationTime } from "components/FixCreationTime";
import FullScreenDropZone from "components/FullScreenDropZone";
import GalleryEmptyState from "components/GalleryEmptyState";
import { LoadingOverlay } from "components/LoadingOverlay";
import PhotoFrame from "components/PhotoFrame";
import { ITEM_TYPE, TimeStampListItem } from "components/PhotoList";
import Sidebar from "components/Sidebar";
import { type UploadTypeSelectorIntent } from "components/Upload/UploadTypeSelector";
import Uploader from "components/Upload/Uploader";
import { UploadSelectorInputs } from "components/UploadSelectorInputs";
import SelectedFileOptions from "components/pages/gallery/SelectedFileOptions";
import { t } from "i18next";
import { useRouter, type NextRouter } from "next/router";
import { createContext, useCallback, useEffect, useRef, useState } from "react";
import { useDropzone } from "react-dropzone";
import { Trans } from "react-i18next";
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
import {
    COLLECTION_OPS_TYPE,
    getSelectedCollection,
    handleCollectionOps,
} from "utils/collection";
import { FILE_OPS_TYPE, getSelectedFiles, handleFileOps } from "utils/file";

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
        showLoadingBar,
        hideLoadingBar,
        showMiniDialog,
        onGenericError,
        logout,
        ...appContext
    } = useAppContext();
    const [userIDToEmailMap, setUserIDToEmailMap] =
        useState<Map<number, string>>(null);
    const [emailList, setEmailList] = useState<string[]>(null);

    const [uploadTypeSelectorView, setUploadTypeSelectorView] = useState(false);
    const [uploadTypeSelectorIntent, setUploadTypeSelectorIntent] =
        useState<UploadTypeSelectorIntent>("upload");

    const [sidebarView, setSidebarView] = useState(false);

    const closeSidebar = () => setSidebarView(false);
    const openSidebar = () => setSidebarView(true);

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
    // If the fix creation time dialog is being shown, then the list of files on
    // which it should act.
    const [fixCreationTimeFiles, setFixCreationTimeFiles] = useState<
        EnteFile[]
    >([]);

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

    const [openCollectionSelector, setOpenCollectionSelector] = useState(false);
    const [collectionSelectorAttributes, setCollectionSelectorAttributes] =
        useState<CollectionSelectorAttributes | undefined>();

    const { show: showPlanSelector, props: planSelectorVisibilityProps } =
        useModalVisibility();
    const { show: showWhatsNew, props: whatsNewVisibilityProps } =
        useModalVisibility();
    const { show: showFixCreationTime, props: fixCreationTimeVisibilityProps } =
        useModalVisibility();
    const { show: showExport, props: exportVisibilityProps } =
        useModalVisibility();

    // TODO: Temp
    const user = state.user;
    const familyData = state.familyData;
    const collections = state.collections;
    const files = state.files;
    const hiddenFiles = state.hiddenFiles;
    const collectionSummaries = state.collectionSummaries;
    const barMode = state.view?.type ?? "albums";
    const activeCollectionID =
        state.view?.type == "people"
            ? undefined
            : state.view?.activeCollectionSummaryID;
    const activeCollection =
        state.view?.type == "people" ? undefined : state.view?.activeCollection;
    const activePerson =
        state.view?.type == "people" ? state.view.activePerson : undefined;
    const activePersonID = activePerson?.id;
    const isInSearchMode = state.isInSearchMode;
    const filteredFiles = state.filteredFiles;

    if (process.env.NEXT_PUBLIC_ENTE_WIP_CL) console.log("render", state);

    const router = useRouter();

    // Ensure that the keys in local storage are not malformed by verifying that
    // the recoveryKey can be decrypted with the masterKey.
    // Note: This is not bullet-proof.
    const validateKey = async () => {
        try {
            await getRecoveryKey();
            return true;
        } catch {
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
            initSettings();
            await initUserDetailsOrTriggerSync();
            setupSelectAllKeyBoardShortcutHandler();
            dispatch({ type: "showAll" });
            setIsFirstLoad(isFirstLogin());
            if (justSignedUp()) {
                showPlanSelector();
            }
            setIsFirstLogin(false);
            const user = getData(LS_KEYS.USER);
            // TODO: Pass entire snapshot to reducer?
            const familyData = userDetailsSnapshot()?.familyData;
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
        () => setSearchCollectionsAndFiles({ collections, files }),
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
        if (router.isReady && getKey(SESSION_KEYS.ENCRYPTION_KEY)) {
            handleSubscriptionCompletionRedirectIfNeeded(
                showMiniDialog,
                showLoadingBar,
                router,
            );
        }
    }, [router.isReady]);

    useEffect(() => {
        dispatch({ type: "setPeopleState", peopleState });
    }, [peopleState]);

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

    // TODO: Make this a normal useEffect.
    useMemoSingleThreaded(async () => {
        if (selectedSearchOption) {
            const searchResults = await filterSearchableFiles(
                selectedSearchOption.suggestion,
            );
            dispatch({ type: "setSearchResults", searchResults });
        }
    }, [selectedSearchOption]);

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
            planSelectorVisibilityProps.open ||
            fixCreationTimeVisibilityProps.open ||
            exportVisibilityProps.open ||
            authenticateUserModalView ||
            isPhotoSwipeOpen ||
            !filteredFiles?.length ||
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
                barMode == "people" && activePersonID
                    ? {
                          mode: "people" as const,
                          personID: activePersonID,
                      }
                    : {
                          mode: barMode as "albums" | "hidden-albums",
                          collectionID: activeCollectionID!,
                      },
        };

        filteredFiles.forEach((item) => {
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

    const showSessionExpiredDialog = () =>
        showMiniDialog(sessionExpiredDialogAttributes(logout));

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
            !silent && showLoadingBar();
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
                (files) => dispatch({ type: "setFiles", files }),
                (files) => dispatch({ type: "fetchFiles", files }),
            );
            await syncFiles(
                "hidden",
                hiddenCollections,
                (hiddenFiles) =>
                    dispatch({ type: "setHiddenFiles", hiddenFiles }),
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
                    showSessionExpiredDialog();
                    break;
                case CustomError.KEY_MISSING:
                    clearKeys();
                    router.push(PAGES.CREDENTIALS);
                    break;
                default:
                    log.error("syncWithRemote failed", e);
            }
        } finally {
            dispatch({ type: "clearTempDeleted" });
            dispatch({ type: "clearTempHidden" });
            !silent && hideLoadingBar();
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
            showLoadingBar();
            try {
                setOpenCollectionSelector(false);
                const selectedFiles = getSelectedFiles(selected, filteredFiles);
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
                onGenericError(e);
            } finally {
                hideLoadingBar();
            }
        };

    const fileOpsHelper = (ops: FILE_OPS_TYPE) => async () => {
        showLoadingBar();
        try {
            // passing files here instead of filteredData for hide ops because we want to move all files copies to hidden collection
            const selectedFiles = getSelectedFiles(
                selected,
                ops === FILE_OPS_TYPE.HIDE ? files : filteredFiles,
            );
            const toProcessFiles =
                ops === FILE_OPS_TYPE.DOWNLOAD
                    ? selectedFiles
                    : selectedFiles.filter((file) => file.ownerID === user.id);
            if (toProcessFiles.length > 0) {
                await handleFileOps(
                    ops,
                    toProcessFiles,
                    (files) => dispatch({ type: "markTempDeleted", files }),
                    () => dispatch({ type: "clearTempDeleted" }),
                    (files) => dispatch({ type: "markTempHidden", files }),
                    () => dispatch({ type: "clearTempHidden" }),
                    (files) => {
                        setFixCreationTimeFiles(files);
                        showFixCreationTime();
                    },
                    setFilesDownloadProgressAttributesCreator,
                );
            }
            clearSelection();
            await syncWithRemote(false, true);
        } catch (e) {
            onGenericError(e);
        } finally {
            hideLoadingBar();
        }
    };

    const showCreateCollectionModal = (ops: COLLECTION_OPS_TYPE) => {
        const callback = async (collectionName: string) => {
            try {
                showLoadingBar();
                const collection = await createAlbum(collectionName);
                await collectionOpsHelper(ops)(collection);
            } catch (e) {
                onGenericError(e);
            } finally {
                hideLoadingBar();
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
            : dispatch({ type: "showAlbums" });

    const openHiddenSection: GalleryContextType["openHiddenSection"] = (
        callback,
    ) => {
        authenticateUser(() => {
            dispatch({ type: "showHidden" });
            callback?.();
        });
    };

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

    if (!user) {
        // Don't render until we dispatch "mount" with the logged in user.
        return <div></div>;
    }

    return (
        <GalleryContext.Provider
            value={{
                ...defaultGalleryContext,
                showPlanSelectorModal: showPlanSelector,
                setActiveCollectionID: handleSetActiveCollectionID,
                onShowCollection: (id) =>
                    dispatch({
                        type: "showNormalOrHiddenCollectionSummary",
                        collectionSummaryID: id,
                    }),
                syncWithRemote,
                setBlockingLoad,
                photoListHeader,
                openExportModal: showExport,
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
                    {...planSelectorVisibilityProps}
                    setLoading={(v) => setBlockingLoad(v)}
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
                    {...fixCreationTimeVisibilityProps}
                    files={fixCreationTimeFiles}
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
                            onBack={() => dispatch({ type: "showAlbums" })}
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
                                onSelectPeople: () =>
                                    dispatch({ type: "showPeople" }),
                                onSelectPerson: (personID) =>
                                    dispatch({ type: "showPerson", personID }),
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
                        hiddenCollectionSummaries:
                            state.hiddenCollectionSummaries,
                        people:
                            (state.view.type == "people"
                                ? state.view.visiblePeople
                                : undefined) ?? [],
                        activePerson,
                        onSelectPerson: (personID) =>
                            dispatch({ type: "showPerson", personID }),
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
                    showSessionExpiredMessage={showSessionExpiredDialog}
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
                  state.view.type == "people" &&
                  !state.view.activePerson ? (
                    <PeopleEmptyState />
                ) : (
                    <PhotoFrame
                        page={PAGES.GALLERY}
                        mode={barMode}
                        modePlus={isInSearchMode ? "search" : barMode}
                        files={filteredFiles}
                        syncWithRemote={syncWithRemote}
                        favItemIds={state.favoriteFileIDs}
                        setSelected={setSelected}
                        selected={selected}
                        markTempDeleted={(files) =>
                            dispatch({ type: "markTempDeleted", files })
                        }
                        setIsPhotoSwipeOpen={setIsPhotoSwipeOpen}
                        activeCollectionID={activeCollectionID}
                        activePersonID={activePerson?.id}
                        enableDownload={true}
                        fileToCollectionsMap={state.fileCollectionIDs}
                        collectionNameMap={state.allCollectionNameByID}
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
                <Export
                    {...exportVisibilityProps}
                    collectionNameMap={state.allCollectionNameByID}
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
 * When the payments app redirects back to us after a plan purchase or update
 * completes, it sets various query parameters to relay the status of the action
 * back to us.
 *
 * Check if these query parameters exist, and if so, act on them appropriately.
 */
export async function handleSubscriptionCompletionRedirectIfNeeded(
    showMiniDialog: (attributes: MiniDialogAttributes) => void,
    showLoadingBar: () => void,
    router: NextRouter,
) {
    const { session_id: sessionID, status, reason } = router.query;

    if (status == "success") {
        try {
            const subscription = await verifyStripeSubscription(sessionID);
            showMiniDialog({
                title: t("thank_you"),
                message: (
                    <Trans
                        i18nKey="subscription_purchase_success"
                        values={{ date: subscription?.expiryTime }}
                    />
                ),
                continue: { text: t("ok") },
                cancel: false,
            });
        } catch (e) {
            log.error("Subscription verification failed", e);
            showMiniDialog(
                errorDialogAttributes(t("subscription_verification_error")),
            );
        }
    } else if (status == "fail") {
        log.error(`Subscription purchase failed: ${reason}`);
        switch (reason) {
            case "canceled":
                showMiniDialog({
                    message: t("subscription_purchase_cancelled"),
                    continue: { text: t("ok"), color: "primary" },
                    cancel: false,
                });
                break;
            case "requires_payment_method":
                showMiniDialog({
                    title: t("update_payment_method"),
                    message: t("update_payment_method_message"),
                    continue: {
                        text: t("update_payment_method"),
                        action: () => {
                            showLoadingBar();
                            return redirectToCustomerPortal();
                        },
                    },
                });
                break;
            case "authentication_failed":
                showMiniDialog({
                    title: t("update_payment_method"),
                    message: t("payment_method_authentication_failed"),
                    continue: {
                        text: t("update_payment_method"),
                        action: () => {
                            showLoadingBar();
                            return redirectToCustomerPortal();
                        },
                    },
                });
                break;
            default:
                showMiniDialog(
                    errorDialogAttributes(t("subscription_purchase_failed")),
                );
        }
    }
}

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
