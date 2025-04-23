import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import FileUploadOutlinedIcon from "@mui/icons-material/FileUploadOutlined";
import MenuIcon from "@mui/icons-material/Menu";
import { IconButton, Stack, Typography } from "@mui/material";
import { AuthenticateUser } from "components/AuthenticateUser";
import CollectionNamer, {
    CollectionNamerAttributes,
} from "components/Collections/CollectionNamer";
import { GalleryBarAndListHeader } from "components/Collections/GalleryBarAndListHeader";
import { Export } from "components/Export";
import { TimeStampListItem } from "components/FileList";
import { FileListWithViewer } from "components/FileListWithViewer";
import {
    FilesDownloadProgress,
    FilesDownloadProgressAttributes,
} from "components/FilesDownloadProgress";
import { FixCreationTime } from "components/FixCreationTime";
import GalleryEmptyState from "components/GalleryEmptyState";
import { Sidebar } from "components/Sidebar";
import { Upload, type UploadTypeSelectorIntent } from "components/Upload";
import SelectedFileOptions from "components/pages/gallery/SelectedFileOptions";
import { sessionExpiredDialogAttributes } from "ente-accounts/components/utils/dialog";
import { stashRedirect } from "ente-accounts/services/redirect";
import type { MiniDialogAttributes } from "ente-base/components/MiniDialog";
import { NavbarBase } from "ente-base/components/Navbar";
import { CenteredRow } from "ente-base/components/containers";
import { TranslucentLoadingOverlay } from "ente-base/components/loaders";
import type { ButtonishProps } from "ente-base/components/mui";
import { FocusVisibleButton } from "ente-base/components/mui/FocusVisibleButton";
import { errorDialogAttributes } from "ente-base/components/utils/dialog";
import { useIsSmallWidth } from "ente-base/components/utils/hooks";
import { useModalVisibility } from "ente-base/components/utils/modal";
import { useBaseContext } from "ente-base/context";
import log from "ente-base/log";
import { FullScreenDropZone } from "ente-gallery/components/FullScreenDropZone";
import { type Collection } from "ente-media/collection";
import { type EnteFile } from "ente-media/file";
import {
    updateRemotePrivateMagicMetadata,
    type ItemVisibility,
} from "ente-media/file-metadata";
import {
    CollectionSelector,
    type CollectionSelectorAttributes,
} from "ente-new/photos/components/CollectionSelector";
import { PlanSelector } from "ente-new/photos/components/PlanSelector";
import {
    SearchBar,
    type SearchBarProps,
} from "ente-new/photos/components/SearchBar";
import { WhatsNew } from "ente-new/photos/components/WhatsNew";
import {
    PeopleEmptyState,
    SearchResultsHeader,
} from "ente-new/photos/components/gallery";
import {
    constructUserIDToEmailMap,
    createShareeSuggestionEmails,
} from "ente-new/photos/components/gallery/helpers";
import {
    useGalleryReducer,
    type GalleryBarMode,
} from "ente-new/photos/components/gallery/reducer";
import { useIsOffline } from "ente-new/photos/components/utils/use-is-offline";
import { usePeopleStateSnapshot } from "ente-new/photos/components/utils/use-snapshot";
import { shouldShowWhatsNew } from "ente-new/photos/services/changelog";
import {
    ALL_SECTION,
    DUMMY_UNCATEGORIZED_COLLECTION,
} from "ente-new/photos/services/collection";
import { areOnlySystemCollections } from "ente-new/photos/services/collection/ui";
import { getAllLocalCollections } from "ente-new/photos/services/collections";
import {
    getLocalFiles,
    getLocalTrashedFiles,
} from "ente-new/photos/services/files";
import {
    filterSearchableFiles,
    setSearchCollectionsAndFiles,
} from "ente-new/photos/services/search";
import type { SearchOption } from "ente-new/photos/services/search/types";
import { initSettings } from "ente-new/photos/services/settings";
import {
    postCollectionAndFilesSync,
    preCollectionAndFilesSync,
    syncCollectionAndFiles,
} from "ente-new/photos/services/sync";
import {
    initUserDetailsOrTriggerSync,
    redirectToCustomerPortal,
    userDetailsSnapshot,
    verifyStripeSubscription,
} from "ente-new/photos/services/user-details";
import { usePhotosAppContext } from "ente-new/photos/types/context";
import { FlexWrapper } from "ente-shared/components/Container";
import { getRecoveryKey } from "ente-shared/crypto/helpers";
import { CustomError } from "ente-shared/error";
import { getData } from "ente-shared/storage/localStorage";
import {
    getToken,
    isFirstLogin,
    justSignedUp,
    setIsFirstLogin,
    setJustSignedUp,
} from "ente-shared/storage/localStorage/helpers";
import { clearKeys, getKey } from "ente-shared/storage/sessionStorage";
import { t } from "i18next";
import { useRouter, type NextRouter } from "next/router";
import { createContext, useCallback, useEffect, useRef, useState } from "react";
import { FileWithPath } from "react-dropzone";
import { Trans } from "react-i18next";
import {
    addToFavorites,
    createAlbum,
    createUnCategorizedCollection,
    removeFromFavorites,
} from "services/collectionService";
import exportService from "services/export";
import uploadManager from "services/upload/uploadManager";
import { isTokenValid } from "services/userService";
import {
    GalleryContextType,
    SelectedState,
    SetFilesDownloadProgressAttributes,
    SetFilesDownloadProgressAttributesCreator,
} from "types/gallery";
import {
    getSelectedCollection,
    handleCollectionOp,
    type CollectionOp,
} from "utils/collection";
import { getSelectedFiles, handleFileOp, type FileOp } from "utils/file";

const defaultGalleryContext: GalleryContextType = {
    setActiveCollectionID: () => null,
    syncWithRemote: () => null,
    setBlockingLoad: () => null,
    photoListHeader: null,
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
const Page: React.FC = () => {
    const { logout, showMiniDialog, onGenericError } = useBaseContext();
    const { showLoadingBar, hideLoadingBar, watchFolderView } =
        usePhotosAppContext();

    const isOffline = useIsOffline();
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
    const [dragAndDropFiles, setDragAndDropFiles] = useState<FileWithPath[]>(
        [],
    );
    const [isFileViewerOpen, setIsFileViewerOpen] = useState(false);

    const syncInProgress = useRef(false);
    const syncInterval = useRef<ReturnType<typeof setInterval> | undefined>(
        undefined,
    );
    const resync = useRef<{ force: boolean; silent: boolean } | undefined>(
        undefined,
    );

    const [userIDToEmailMap, setUserIDToEmailMap] =
        useState<Map<number, string>>(null);
    const [emailList, setEmailList] = useState<string[]>(null);

    const [uploadTypeSelectorView, setUploadTypeSelectorView] = useState(false);
    const [uploadTypeSelectorIntent, setUploadTypeSelectorIntent] =
        useState<UploadTypeSelectorIntent>("upload");

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

    const { show: showSidebar, props: sidebarVisibilityProps } =
        useModalVisibility();
    const { show: showPlanSelector, props: planSelectorVisibilityProps } =
        useModalVisibility();
    const { show: showWhatsNew, props: whatsNewVisibilityProps } =
        useModalVisibility();
    const { show: showFixCreationTime, props: fixCreationTimeVisibilityProps } =
        useModalVisibility();
    const { show: showExport, props: exportVisibilityProps } =
        useModalVisibility();
    const {
        show: showAuthenticateUser,
        props: authenticateUserVisibilityProps,
    } = useModalVisibility();

    const onAuthenticateCallback = useRef<(() => void) | undefined>(undefined);

    const authenticateUser = useCallback(
        () =>
            new Promise<void>((resolve) => {
                onAuthenticateCallback.current = resolve;
                showAuthenticateUser();
            }),
        [],
    );

    // Local aliases.
    const {
        user,
        familyData,
        normalCollections,
        normalFiles,
        hiddenFiles,
        favoriteFileIDs,
        collectionNameByID,
        fileNormalCollectionIDs,
        normalCollectionSummaries,
        pendingFavoriteUpdates,
        pendingVisibilityUpdates,
        isInSearchMode,
        filteredFiles,
    } = state;

    // Derived aliases.
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

    if (process.env.NEXT_PUBLIC_ENTE_TRACE) console.log("render", state);

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
        const key = getKey("encryptionKey");
        const token = getToken();
        if (!key || !token) {
            stashRedirect("/gallery");
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
            const user = getData("user");
            // TODO: Pass entire snapshot to reducer?
            const familyData = userDetailsSnapshot()?.familyData;
            dispatch({
                type: "mount",
                user,
                familyData,
                collections: await getAllLocalCollections(),
                normalFiles: await getLocalFiles("normal"),
                hiddenFiles: await getLocalFiles("hidden"),
                trashedFiles: await getLocalTrashedFiles(),
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

    useEffect(() => {
        setSearchCollectionsAndFiles({
            collections: normalCollections,
            files: normalFiles,
        });
    }, [normalCollections, normalFiles]);

    useEffect(() => {
        if (!user || !normalCollections) {
            return;
        }
        setUserIDToEmailMap(constructUserIDToEmailMap(user, normalCollections));
        setEmailList(
            createShareeSuggestionEmails(user, normalCollections, familyData),
        );
    }, [user, normalCollections, familyData]);

    useEffect(() => {
        collectionNamerAttributes && setCollectionNamerView(true);
    }, [collectionNamerAttributes]);

    useEffect(() => {
        if (typeof activeCollectionID == "undefined" || !router.isReady) {
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
        if (router.isReady && getKey("encryptionKey")) {
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
        if (isInSearchMode && state.searchSuggestion) {
            setPhotoListHeader({
                height: 104,
                item: (
                    <SearchResultsHeader
                        searchSuggestion={state.searchSuggestion}
                        fileCount={state.searchResults?.length ?? 0}
                    />
                ),
                tag: "header",
            });
        }
    }, [isInSearchMode, state.searchSuggestion, state.searchResults]);

    useEffect(() => {
        const pendingSearchSuggestion = state.pendingSearchSuggestions.at(-1);
        if (!state.isRecomputingSearchResults && pendingSearchSuggestion) {
            dispatch({ type: "updatingSearchResults" });
            filterSearchableFiles(pendingSearchSuggestion).then(
                (searchResults) => {
                    dispatch({ type: "setSearchResults", searchResults });
                },
            );
        }
    }, [state.isRecomputingSearchResults, state.pendingSearchSuggestions]);

    const selectAll = (e: KeyboardEvent) => {
        // Don't intercept Ctrl/Cmd + a if the user is typing in a text field.
        if (
            e.target instanceof HTMLInputElement ||
            e.target instanceof HTMLTextAreaElement
        ) {
            return;
        }

        // Prevent the browser's default select all handling (selecting all the
        // text in the gallery).
        e.preventDefault();

        // Don't select all if:
        if (
            // - We haven't fetched the user yet;
            !user ||
            // - There is nothing to select;
            !filteredFiles?.length ||
            // - Any of the modals are open.
            uploadTypeSelectorView ||
            openCollectionSelector ||
            collectionNamerView ||
            sidebarVisibilityProps.open ||
            planSelectorVisibilityProps.open ||
            fixCreationTimeVisibilityProps.open ||
            exportVisibilityProps.open ||
            authenticateUserVisibilityProps.open ||
            isFileViewerOpen
        ) {
            return;
        }

        // Create a selection with everything based on the current context.
        const selected = {
            ownCount: 0,
            count: 0,
            collectionID: activeCollectionID,
            context:
                barMode == "people" && activePersonID
                    ? { mode: "people" as const, personID: activePersonID }
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

    const keyboardShortcutHandlerRef = useRef({ selectAll, clearSelection });

    useEffect(() => {
        keyboardShortcutHandlerRef.current = { selectAll, clearSelection };
    }, [selectAll, clearSelection]);

    const showSessionExpiredDialog = useCallback(
        () => showMiniDialog(sessionExpiredDialogAttributes(logout)),
        [showMiniDialog, logout],
    );

    // [Note: Visual feedback to acknowledge user actions]
    //
    // In some infrequent cases, we want to acknowledge some user action (e.g.
    // pressing a keyboard shortcut which doesn't have an immediate on-screen
    // impact). In these cases, we tickle the loading bar at the top to
    // acknowledge that their action.
    //
    // TODO: Move to the new "GalleryContext"?
    const handleVisualFeedback = useCallback(() => {
        showLoadingBar();
        setTimeout(hideLoadingBar, 0);
    }, [showLoadingBar, hideLoadingBar]);

    const handleFileAndCollectionSyncWithRemote = useCallback(async () => {
        const didUpdateFiles = await syncCollectionAndFiles({
            onSetCollections: (
                collections,
                normalCollections,
                hiddenCollections,
            ) =>
                dispatch({
                    type: "setCollections",
                    collections,
                    normalCollections,
                    hiddenCollections,
                }),
            onResetNormalFiles: (files) =>
                dispatch({ type: "setNormalFiles", files }),
            onFetchNormalFiles: (files) =>
                dispatch({ type: "fetchNormalFiles", files }),
            onResetHiddenFiles: (files) =>
                dispatch({ type: "setHiddenFiles", files }),
            onFetchHiddenFiles: (files) =>
                dispatch({ type: "fetchHiddenFiles", files }),
            onResetTrashedFiles: (files) =>
                dispatch({ type: "setTrashedFiles", files }),
        });
        if (didUpdateFiles) {
            exportService.onLocalFilesUpdated();
        }
    }, []);

    const handleSyncWithRemote = useCallback(
        async (force = false, silent = false) => {
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
                await preCollectionAndFilesSync();
                await handleFileAndCollectionSyncWithRemote();
                // syncWithRemote is called with the force flag set to true before
                // doing an upload. So it is possible, say when resuming a pending
                // upload, that we get two syncWithRemotes happening in parallel.
                //
                // Do the non-file-related sync only for one of these parallel ones.
                if (!isForced) {
                    await postCollectionAndFilesSync();
                }
            } catch (e) {
                switch (e.message) {
                    case CustomError.SESSION_EXPIRED:
                        showSessionExpiredDialog();
                        break;
                    case CustomError.KEY_MISSING:
                        clearKeys();
                        router.push("/credentials");
                        break;
                    default:
                        log.error("syncWithRemote failed", e);
                }
            } finally {
                dispatch({ type: "clearUnsyncedState" });
                !silent && hideLoadingBar();
            }
            syncInProgress.current = false;
            if (resync.current) {
                const { force, silent } = resync.current;
                setTimeout(() => handleSyncWithRemote(force, silent), 0);
                resync.current = undefined;
            }
        },
        [
            showLoadingBar,
            hideLoadingBar,
            router,
            showSessionExpiredDialog,
            handleFileAndCollectionSyncWithRemote,
        ],
    );

    // Alias for existing code.
    const syncWithRemote = handleSyncWithRemote;

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
        useCallback((folderName, collectionID, isHidden) => {
            const id = Math.random();
            const updater: SetFilesDownloadProgressAttributes = (value) => {
                setFilesDownloadProgressAttributesList((prev) => {
                    const attributes = prev?.find((attr) => attr.id === id);
                    const updatedAttributes =
                        typeof value == "function"
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
        }, []);

    const collectionOpsHelper =
        (op: CollectionOp) => async (collection: Collection) => {
            showLoadingBar();
            try {
                setOpenCollectionSelector(false);
                const selectedFiles = getSelectedFiles(selected, filteredFiles);
                const toProcessFiles =
                    op == "remove"
                        ? selectedFiles
                        : selectedFiles.filter(
                              (file) => file.ownerID === user.id,
                          );
                if (toProcessFiles.length > 0) {
                    await handleCollectionOp(
                        op,
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

    const fileOpHelper = (op: FileOp) => async () => {
        showLoadingBar();
        try {
            // passing files here instead of filteredData for hide ops because we want to move all files copies to hidden collection
            const selectedFiles = getSelectedFiles(
                selected,
                op == "hide" ? normalFiles : filteredFiles,
            );
            const toProcessFiles =
                op == "download"
                    ? selectedFiles
                    : selectedFiles.filter((file) => file.ownerID === user.id);
            if (toProcessFiles.length > 0) {
                await handleFileOp(
                    op,
                    toProcessFiles,
                    handleMarkTempDeleted,
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

    const showCreateCollectionModal = (op: CollectionOp) => {
        const callback = async (collectionName: string) => {
            try {
                showLoadingBar();
                const collection = await createAlbum(collectionName);
                await collectionOpsHelper(op)(collection);
            } catch (e) {
                onGenericError(e);
            } finally {
                hideLoadingBar();
            }
        };
        return () =>
            setCollectionNamerAttributes({
                title: t("new_album"),
                buttonText: t("create"),
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
                    type: "showCollectionSummary",
                    collectionSummaryID: searchOption.suggestion.collectionID,
                });
            } else {
                dispatch({
                    type: "showPerson",
                    personID: searchOption.suggestion.person.id,
                });
            }
        } else if (searchOption) {
            dispatch({
                type: "enterSearchMode",
                searchSuggestion: searchOption.suggestion,
            });
        } else {
            dispatch({ type: "exitSearch" });
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
    ) => dispatch({ type: "showCollectionSummary", collectionSummaryID });

    const handleChangeBarMode = (mode: GalleryBarMode) =>
        mode == "people"
            ? dispatch({ type: "showPeople" })
            : dispatch({ type: "showAlbums" });

    const openHiddenSection: GalleryContextType["openHiddenSection"] = (
        callback,
    ) => {
        authenticateUser().then(() => {
            dispatch({ type: "showHidden" });
            callback?.();
        });
    };

    const handleToggleFavorite = useCallback(
        async (file: EnteFile) => {
            const fileID = file.id;
            const isFavorite = favoriteFileIDs.has(fileID);

            dispatch({ type: "addPendingFavoriteUpdate", fileID });
            try {
                await (isFavorite ? removeFromFavorites : addToFavorites)(
                    file,
                    true,
                );
                dispatch({
                    type: "unsyncedFavoriteUpdate",
                    fileID,
                    isFavorite: !isFavorite,
                });
            } finally {
                dispatch({ type: "removePendingFavoriteUpdate", fileID });
            }
        },
        [favoriteFileIDs],
    );

    const handleFileViewerFileVisibilityUpdate = useCallback(
        async (file: EnteFile, visibility: ItemVisibility) => {
            const fileID = file.id;
            dispatch({ type: "addPendingVisibilityUpdate", fileID });
            try {
                const privateMagicMetadata =
                    await updateRemotePrivateMagicMetadata(file, {
                        visibility,
                    });
                dispatch({
                    type: "unsyncedPrivateMagicMetadataUpdate",
                    fileID,
                    privateMagicMetadata,
                });
            } finally {
                dispatch({ type: "removePendingVisibilityUpdate", fileID });
            }
        },
        [],
    );

    const handleMarkTempDeleted = useCallback(
        (files: EnteFile[]) => dispatch({ type: "markTempDeleted", files }),
        [],
    );

    const handleSelectCollection = useCallback(
        (collectionID: number) =>
            dispatch({
                type: "showCollectionSummary",
                collectionSummaryID: collectionID,
            }),
        [],
    );

    const handleSelectPerson = useCallback(
        (personID: string) => dispatch({ type: "showPerson", personID }),
        [],
    );

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

    const showSelectionBar =
        selected.count > 0 && selected.collectionID === activeCollectionID;

    if (!user) {
        // Don't render until we dispatch "mount" with the logged in user.
        //
        // Tag: [Note: Gallery children can assume user]
        return <div></div>;
    }

    return (
        <GalleryContext.Provider
            value={{
                ...defaultGalleryContext,
                setActiveCollectionID: handleSetActiveCollectionID,
                syncWithRemote,
                setBlockingLoad,
                photoListHeader,
                userIDToEmailMap,
                user,
                emailList,
                openHiddenSection,
                isClipSearchResult,
                selectedFile: selected,
                setSelectedFiles: setSelected,
            }}
        >
            <FullScreenDropZone
                message={
                    watchFolderView
                        ? t("watch_folder_dropzone_hint")
                        : undefined
                }
                disabled={shouldDisableDropzone}
                onDrop={setDragAndDropFiles}
            >
                {blockingLoad && <TranslucentLoadingOverlay />}
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
                    collectionSummaries={normalCollectionSummaries}
                    collectionForCollectionID={(id) =>
                        findCollectionCreatingUncategorizedIfNeeded(
                            normalCollections,
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
                    sx={[
                        {
                            mb: "12px",
                            px: "24px",
                            "@media (width < 720px)": { px: "4px" },
                        },
                        showSelectionBar && { borderColor: "accent.main" },
                    ]}
                >
                    {showSelectionBar ? (
                        <SelectedFileOptions
                            handleCollectionOp={collectionOpsHelper}
                            handleFileOp={fileOpHelper}
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
                                normalCollections,
                            )}
                            isFavoriteCollection={
                                normalCollectionSummaries.get(
                                    activeCollectionID,
                                )?.type == "favorites"
                            }
                            isUncategorizedCollection={
                                normalCollectionSummaries.get(
                                    activeCollectionID,
                                )?.type == "uncategorized"
                            }
                            isIncomingSharedCollection={
                                normalCollectionSummaries.get(
                                    activeCollectionID,
                                )?.type == "incomingShareCollaborator" ||
                                normalCollectionSummaries.get(
                                    activeCollectionID,
                                )?.type == "incomingShareViewer"
                            }
                            isInSearchMode={isInSearchMode}
                            isInHiddenSection={barMode == "hidden-albums"}
                        />
                    ) : barMode == "hidden-albums" ? (
                        <HiddenSectionNavbarContents
                            onBack={() => dispatch({ type: "showAlbums" })}
                        />
                    ) : (
                        <NormalNavbarContents
                            {...{ isInSearchMode }}
                            onSidebar={showSidebar}
                            onUpload={openUploader}
                            onShowSearchInput={() =>
                                dispatch({ type: "enterSearchMode" })
                            }
                            onSelectSearchOption={handleSelectSearchOption}
                            onSelectPeople={() =>
                                dispatch({ type: "showPeople" })
                            }
                            onSelectPerson={handleSelectPerson}
                        />
                    )}
                </NavbarBase>
                {isFirstLoad && <FirstLoadMessage />}
                {isOffline && <OfflineMessage />}

                <GalleryBarAndListHeader
                    {...{
                        activeCollection,
                        activeCollectionID,
                        activePerson,
                        setCollectionNamerAttributes,
                        setPhotoListHeader,
                        setFilesDownloadProgressAttributesCreator,
                        filesDownloadProgressAttributesList,
                    }}
                    mode={barMode}
                    shouldHide={isInSearchMode}
                    collectionSummaries={normalCollectionSummaries}
                    hiddenCollectionSummaries={state.hiddenCollectionSummaries}
                    people={
                        (state.view.type == "people"
                            ? state.view.visiblePeople
                            : undefined) ?? []
                    }
                    onChangeMode={handleChangeBarMode}
                    setActiveCollectionID={handleSetActiveCollectionID}
                    onSelectPerson={handleSelectPerson}
                />

                <Upload
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
                        dispatch({ type: "uploadNormalFile", file })
                    }
                    onShowPlanSelector={showPlanSelector}
                    setCollections={(collections) =>
                        dispatch({ type: "setNormalCollections", collections })
                    }
                    isFirstUpload={areOnlySystemCollections(
                        normalCollectionSummaries,
                    )}
                    showSessionExpiredMessage={showSessionExpiredDialog}
                    {...{
                        dragAndDropFiles,
                        uploadTypeSelectorIntent,
                        uploadTypeSelectorView,
                    }}
                />
                <Sidebar
                    {...sidebarVisibilityProps}
                    collectionSummaries={normalCollectionSummaries}
                    onShowPlanSelector={showPlanSelector}
                    onShowExport={showExport}
                    onAuthenticateUser={authenticateUser}
                />
                <WhatsNew {...whatsNewVisibilityProps} />
                {!isInSearchMode &&
                !isFirstLoad &&
                !normalFiles?.length &&
                !hiddenFiles?.length &&
                activeCollectionID === ALL_SECTION ? (
                    <GalleryEmptyState openUploader={openUploader} />
                ) : !isInSearchMode &&
                  !isFirstLoad &&
                  state.view.type == "people" &&
                  !state.view.activePerson ? (
                    <PeopleEmptyState />
                ) : (
                    <FileListWithViewer
                        mode={barMode}
                        modePlus={isInSearchMode ? "search" : barMode}
                        user={user}
                        files={filteredFiles}
                        enableDownload={true}
                        showAppDownloadBanner={
                            normalFiles.length < 30 && !isInSearchMode
                        }
                        selectable={true}
                        selected={selected}
                        setSelected={setSelected}
                        activeCollectionID={activeCollectionID}
                        activePersonID={activePerson?.id}
                        isInIncomingSharedCollection={
                            normalCollectionSummaries.get(activeCollectionID)
                                ?.type == "incomingShareCollaborator" ||
                            normalCollectionSummaries.get(activeCollectionID)
                                ?.type == "incomingShareViewer"
                        }
                        isInHiddenSection={barMode == "hidden-albums"}
                        {...{
                            favoriteFileIDs,
                            collectionNameByID,
                            fileNormalCollectionIDs,
                            pendingFavoriteUpdates,
                            pendingVisibilityUpdates,
                        }}
                        setFilesDownloadProgressAttributesCreator={
                            setFilesDownloadProgressAttributesCreator
                        }
                        onToggleFavorite={handleToggleFavorite}
                        onFileVisibilityUpdate={
                            handleFileViewerFileVisibilityUpdate
                        }
                        onMarkTempDeleted={handleMarkTempDeleted}
                        onSetOpenFileViewer={setIsFileViewerOpen}
                        onSyncWithRemote={handleSyncWithRemote}
                        onVisualFeedback={handleVisualFeedback}
                        onSelectCollection={handleSelectCollection}
                        onSelectPerson={handleSelectPerson}
                    />
                )}
                <Export
                    {...exportVisibilityProps}
                    allCollectionsNameByID={collectionNameByID}
                />
                <AuthenticateUser
                    {...authenticateUserVisibilityProps}
                    onAuthenticate={onAuthenticateCallback.current!}
                />
            </FullScreenDropZone>
        </GalleryContext.Provider>
    );
};

export default Page;

const FirstLoadMessage: React.FC = () => (
    <CenteredRow>
        <Typography variant="small" sx={{ color: "text.muted" }}>
            {t("initial_load_delay_warning")}
        </Typography>
    </CenteredRow>
);

const OfflineMessage: React.FC = () => (
    <Typography
        variant="small"
        sx={{ bgcolor: "background.paper", p: 2, mb: 1, textAlign: "center" }}
    >
        {t("offline_message")}
    </Typography>
);

/**
 * Preload all three variants of a responsive image.
 */
const preloadImage = (imgBasePath: string) => {
    const srcset = [];
    for (let i = 1; i <= 3; i++) srcset.push(`${imgBasePath}/${i}x.png ${i}x`);
    new Image().srcset = srcset.join(",");
};

type NormalNavbarContentsProps = SearchBarProps & {
    /**
     * Called when the user activates the sidebar icon.
     */
    onSidebar: () => void;
    /**
     * Called when the user activates the upload button.
     */
    onUpload: () => void;
};

const NormalNavbarContents: React.FC<NormalNavbarContentsProps> = ({
    onSidebar,
    onUpload,
    ...props
}) => (
    <>
        {!props.isInSearchMode && <SidebarButton onClick={onSidebar} />}
        <SearchBar {...props} />
        {!props.isInSearchMode && <UploadButton onClick={onUpload} />}
    </>
);

const SidebarButton: React.FC<ButtonishProps> = ({ onClick }) => (
    <IconButton {...{ onClick }}>
        <MenuIcon />
    </IconButton>
);

const UploadButton: React.FC<ButtonishProps> = ({ onClick }) => {
    const disabled = !uploadManager.shouldAllowNewUpload();
    const isSmallWidth = useIsSmallWidth();

    const icon = <FileUploadOutlinedIcon />;

    return (
        <>
            {isSmallWidth ? (
                <IconButton {...{ onClick, disabled }}>{icon}</IconButton>
            ) : (
                <FocusVisibleButton
                    color="secondary"
                    startIcon={icon}
                    {...{ onClick, disabled }}
                >
                    {t("upload")}
                </FocusVisibleButton>
            )}
        </>
    );
};

interface HiddenSectionNavbarContentsProps {
    onBack: () => void;
}

const HiddenSectionNavbarContents: React.FC<
    HiddenSectionNavbarContentsProps
> = ({ onBack }) => (
    <Stack
        direction="row"
        sx={(theme) => ({
            gap: "24px",
            width: "100%",
            background: theme.vars.palette.background.default,
        })}
    >
        <IconButton onClick={onBack}>
            <ArrowBackIcon />
        </IconButton>
        <FlexWrapper>
            <Typography>{t("section_hidden")}</Typography>
        </FlexWrapper>
    </Stack>
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
