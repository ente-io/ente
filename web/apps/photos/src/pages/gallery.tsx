import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import FileUploadOutlinedIcon from "@mui/icons-material/FileUploadOutlined";
import MenuIcon from "@mui/icons-material/Menu";
import { IconButton, Stack, Typography } from "@mui/material";
import { AuthenticateUser } from "components/AuthenticateUser";
import { GalleryBarAndListHeader } from "components/Collections/GalleryBarAndListHeader";
import { TimeStampListItem } from "components/FileList";
import { FileListWithViewer } from "components/FileListWithViewer";
import {
    FilesDownloadProgress,
    FilesDownloadProgressAttributes,
} from "components/FilesDownloadProgress";
import { FixCreationTime } from "components/FixCreationTime";
import { Sidebar } from "components/Sidebar";
import { Upload } from "components/Upload";
import { sessionExpiredDialogAttributes } from "ente-accounts/components/utils/dialog";
import {
    getAndClearIsFirstLogin,
    getAndClearJustSignedUp,
    getData,
} from "ente-accounts/services/accounts-db";
import { stashRedirect } from "ente-accounts/services/redirect";
import { isSessionInvalid } from "ente-accounts/services/session";
import type { MiniDialogAttributes } from "ente-base/components/MiniDialog";
import { NavbarBase } from "ente-base/components/Navbar";
import { SingleInputDialog } from "ente-base/components/SingleInputDialog";
import { CenteredRow } from "ente-base/components/containers";
import { TranslucentLoadingOverlay } from "ente-base/components/loaders";
import type { ButtonishProps } from "ente-base/components/mui";
import { FocusVisibleButton } from "ente-base/components/mui/FocusVisibleButton";
import { errorDialogAttributes } from "ente-base/components/utils/dialog";
import { useIsSmallWidth } from "ente-base/components/utils/hooks";
import { useModalVisibility } from "ente-base/components/utils/modal";
import { useBaseContext } from "ente-base/context";
import log from "ente-base/log";
import {
    clearSessionStorage,
    haveCredentialsInSession,
    masterKeyFromSession,
} from "ente-base/session";
import { getAuthToken } from "ente-base/token";
import { FullScreenDropZone } from "ente-gallery/components/FullScreenDropZone";
import { type UploadTypeSelectorIntent } from "ente-gallery/components/Upload";
import { type Collection } from "ente-media/collection";
import { type EnteFile } from "ente-media/file";
import { type ItemVisibility } from "ente-media/file-metadata";
import {
    CollectionSelector,
    type CollectionSelectorAttributes,
} from "ente-new/photos/components/CollectionSelector";
import { Export } from "ente-new/photos/components/Export";
import { PlanSelector } from "ente-new/photos/components/PlanSelector";
import {
    SearchBar,
    type SearchBarProps,
} from "ente-new/photos/components/SearchBar";
import {
    SelectedFileOptions,
    type CollectionOp,
    type FileOp,
} from "ente-new/photos/components/SelectedFileOptions";
import { WhatsNew } from "ente-new/photos/components/WhatsNew";
import {
    GalleryEmptyState,
    PeopleEmptyState,
    SearchResultsHeader,
    type RemotePullOpts,
} from "ente-new/photos/components/gallery";
import {
    findCollectionCreatingUncategorizedIfNeeded,
    performCollectionOp,
    validateKey,
} from "ente-new/photos/components/gallery/helpers";
import {
    useGalleryReducer,
    type GalleryBarMode,
} from "ente-new/photos/components/gallery/reducer";
import { notifyOthersFilesDialogAttributes } from "ente-new/photos/components/utils/dialog-attributes";
import { useIsOffline } from "ente-new/photos/components/utils/use-is-offline";
import { usePeopleStateSnapshot } from "ente-new/photos/components/utils/use-snapshot";
import { shouldShowWhatsNew } from "ente-new/photos/services/changelog";
import {
    addToFavoritesCollection,
    createAlbum,
    removeFromCollection,
    removeFromFavoritesCollection,
} from "ente-new/photos/services/collection";
import {
    haveOnlySystemCollections,
    PseudoCollectionID,
} from "ente-new/photos/services/collection-summary";
import exportService from "ente-new/photos/services/export";
import { updateFilesVisibility } from "ente-new/photos/services/file";
import {
    savedCollectionFiles,
    savedCollections,
    savedTrashItems,
} from "ente-new/photos/services/photos-fdb";
import {
    postPullFiles,
    prePullFiles,
    pullFiles,
} from "ente-new/photos/services/pull";
import {
    filterSearchableFiles,
    updateSearchCollectionsAndFiles,
} from "ente-new/photos/services/search";
import type { SearchOption } from "ente-new/photos/services/search/types";
import { initSettings } from "ente-new/photos/services/settings";
import {
    initUserDetailsOrTriggerPull,
    redirectToCustomerPortal,
    userDetailsSnapshot,
    verifyStripeSubscription,
} from "ente-new/photos/services/user-details";
import { usePhotosAppContext } from "ente-new/photos/types/context";
import { PromiseQueue } from "ente-utils/promise";
import { t } from "i18next";
import { useRouter, type NextRouter } from "next/router";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { FileWithPath } from "react-dropzone";
import { Trans } from "react-i18next";
import { uploadManager } from "services/upload-manager";
import {
    SelectedState,
    SetFilesDownloadProgressAttributes,
    SetFilesDownloadProgressAttributesCreator,
} from "types/gallery";
import { getSelectedFiles, performFileOp } from "utils/file";

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
        context: { mode: "albums", collectionID: PseudoCollectionID.all },
    });
    const [blockingLoad, setBlockingLoad] = useState(false);
    const [shouldDisableDropzone, setShouldDisableDropzone] = useState(false);
    const [dragAndDropFiles, setDragAndDropFiles] = useState<FileWithPath[]>(
        [],
    );
    const [isFileViewerOpen, setIsFileViewerOpen] = useState(false);

    /**
     * A queue to serialize calls to {@link remoteFilesPull}.
     */
    const remoteFilesPullQueue = useRef(new PromiseQueue<void>());
    /**
     * A queue to serialize calls to {@link remotePull}.
     */
    const remotePullQueue = useRef(new PromiseQueue<void>());

    const [uploadTypeSelectorView, setUploadTypeSelectorView] = useState(false);
    const [uploadTypeSelectorIntent, setUploadTypeSelectorIntent] =
        useState<UploadTypeSelectorIntent>("upload");

    // If the fix creation time dialog is being shown, then the list of files on
    // which it should act.
    const [fixCreationTimeFiles, setFixCreationTimeFiles] = useState<
        EnteFile[]
    >([]);

    const peopleState = usePeopleStateSnapshot();

    // The (non-sticky) header shown at the top of the gallery items.
    const [photoListHeader, setPhotoListHeader] =
        useState<TimeStampListItem>(null);

    const [
        filesDownloadProgressAttributesList,
        setFilesDownloadProgressAttributesList,
    ] = useState<FilesDownloadProgressAttributes[]>([]);
    const [, setPostCreateAlbumOp] = useState<CollectionOp | undefined>(
        undefined,
    );

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
    const { show: showAlbumNameInput, props: albumNameInputVisibilityProps } =
        useModalVisibility();

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
    const activeCollectionSummary =
        state.view?.type == "people"
            ? undefined
            : state.view?.activeCollectionSummary;
    const activePerson =
        state.view?.type == "people" ? state.view.activePerson : undefined;
    const activePersonID = activePerson?.id;

    // TODO: Move into reducer
    const barCollectionSummaries = useMemo(
        () =>
            barMode == "hidden-albums"
                ? state.hiddenCollectionSummaries
                : state.normalCollectionSummaries,
        [
            barMode,
            state.hiddenCollectionSummaries,
            state.normalCollectionSummaries,
        ],
    );

    if (process.env.NEXT_PUBLIC_ENTE_TRACE) console.log("render", state);

    const router = useRouter();

    useEffect(() => {
        const electron = globalThis.electron;
        let syncIntervalID: ReturnType<typeof setInterval> | undefined;

        void (async () => {
            if (!haveCredentialsInSession() || !(await getAuthToken())) {
                // If we don't have master key or auth token, reauthenticate.
                stashRedirect("/gallery");
                router.push("/");
                return;
            }

            if (!(await validateKey())) {
                // If we have credentials but they can't be decrypted, reset.
                //
                // This code is never expected to run, it is only kept as a
                // safety valve.
                logout();
                return;
            }

            // We are logged in and everything looks fine. Proceed with page
            // load initialization.

            // One time inits.
            preloadImage("/images/subscription-card-background");
            initSettings();
            await initUserDetailsOrTriggerPull();
            setupSelectAllKeyBoardShortcutHandler();

            // Show the initial state while the rest of the sequence proceeds.
            dispatch({ type: "showAll" });

            // If this is the user's first login on this client, then show them
            // a message informing the that the initial load might take time.
            setIsFirstLoad(getAndClearIsFirstLogin());

            // If the user created a new account on this client, show them the
            // plan options.
            if (getAndClearJustSignedUp()) {
                showPlanSelector();
            }

            // Initialize the reducer.
            const user = getData("user");
            // TODO: Pass entire snapshot to reducer?
            const familyData = userDetailsSnapshot()?.familyData;
            dispatch({
                type: "mount",
                user,
                familyData,
                collections: await savedCollections(),
                collectionFiles: await savedCollectionFiles(),
                trashItems: await savedTrashItems(),
            });

            // Fetch data from remote.
            await remotePull();

            // Clear the first load message if needed.
            setIsFirstLoad(false);

            // Start the interval that does a periodic pull.
            syncIntervalID = setInterval(
                () => remotePull({ silent: true }),
                5 * 60 * 1000 /* 5 minutes */,
            );

            if (electron) {
                electron.onMainWindowFocus(() => remotePull({ silent: true }));
                if (await shouldShowWhatsNew(electron)) showWhatsNew();
            }
        })();

        return () => {
            clearInterval(syncIntervalID);
            if (electron) electron.onMainWindowFocus(undefined);
        };
    }, []);

    useEffect(() => {
        if (typeof activeCollectionID == "undefined" || !router.isReady) {
            return;
        }
        let collectionURL = "";
        if (activeCollectionID !== PseudoCollectionID.all) {
            // TODO: Is this URL param even used?
            collectionURL = `?collection=${activeCollectionID}`;
        }
        const href = `/gallery${collectionURL}`;
        router.push(href, undefined, { shallow: true });
    }, [activeCollectionID, router.isReady]);

    useEffect(() => {
        if (router.isReady && haveCredentialsInSession()) {
            handleSubscriptionCompletionRedirectIfNeeded(
                showMiniDialog,
                showLoadingBar,
                router,
            );
        }
    }, [router.isReady]);

    useEffect(() => {
        updateSearchCollectionsAndFiles(
            state.collections,
            state.collectionFiles,
            state.hiddenCollectionIDs,
            state.hiddenFileIDs,
        );
    }, [
        state.collections,
        state.collectionFiles,
        state.hiddenCollectionIDs,
        state.hiddenFileIDs,
    ]);

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
            sidebarVisibilityProps.open ||
            planSelectorVisibilityProps.open ||
            fixCreationTimeVisibilityProps.open ||
            exportVisibilityProps.open ||
            authenticateUserVisibilityProps.open ||
            albumNameInputVisibilityProps.open ||
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
    const handleVisualFeedback = useCallback(() => {
        showLoadingBar();
        setTimeout(hideLoadingBar, 0);
    }, [showLoadingBar, hideLoadingBar]);

    /**
     * Pull latest collections, collection files and trash items from remote.
     *
     * This wraps the vanilla {@link pullFiles} with two adornments:
     *
     * 1. Any local database updates due to the pull are also reflected in state
     *    updates to the Gallery's reducer.
     *
     * 2. Parallel calls are serialized so that there is only one invocation of
     *    the underlying {@link pullFiles} at a time.
     *
     * [Note: Full remote pull vs files pull]
     *
     * For interactive operations, if we know that our operation will not have
     * other transitive effects beyond collections, collection files and trash,
     * this is a better option as compared to a full remote pull since it
     * involves a lesser number of API requests (and thus, time).
     */
    const remoteFilesPull = useCallback(
        () =>
            remoteFilesPullQueue.current.add(() =>
                pullFiles({
                    onSetCollections: (collections) =>
                        dispatch({ type: "setCollections", collections }),
                    onSetCollectionFiles: (collectionFiles) =>
                        dispatch({
                            type: "setCollectionFiles",
                            collectionFiles,
                        }),
                    onSetTrashedItems: (trashItems) =>
                        dispatch({ type: "setTrashItems", trashItems }),
                    onDidUpdateCollectionFiles: () =>
                        exportService.onLocalFilesUpdated(),
                }),
            ),
        [],
    );

    /**
     * Perform a serialized full remote pull, also updating our component state
     * to match the updates to the local database.
     *
     * See {@link remoteFilesPull} for the general concept. This is a similar
     * wrapper over the full remote pull sequence which also adds pre-flight
     * checks (e.g. to ensure that the user's session has not expired).
     *
     * This method will usually not throw; exceptions during the pull itself are
     * caught. This is so that this promise can be unguardedly awaited without
     * failing the main operations it forms the tail end of: the remote changes
     * would've already been successfully applied, and possibly transient pull
     * failures should get resolved on the next retry.
     */
    const remotePull = useCallback(
        async (opts?: RemotePullOpts) =>
            remotePullQueue.current.add(async () => {
                const { silent } = opts ?? {};

                // Pre-flight checks.
                if (!navigator.onLine) return;
                if (await isSessionInvalid()) {
                    showSessionExpiredDialog();
                    return;
                }
                if (!(await masterKeyFromSession())) {
                    clearSessionStorage();
                    router.push("/credentials");
                    return;
                }

                // The pull itself.
                try {
                    if (!silent) showLoadingBar();
                    await prePullFiles();
                    await remoteFilesPull();
                    await postPullFiles();
                } catch (e) {
                    log.error("Remote pull failed", e);
                } finally {
                    dispatch({ type: "clearUnsyncedState" });
                    if (!silent) hideLoadingBar();
                }
            }),
        [
            showLoadingBar,
            hideLoadingBar,
            router,
            showSessionExpiredDialog,
            remoteFilesPull,
        ],
    );

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

    const handleRemoveFilesFromCollection = (collection: Collection) => {
        void (async () => {
            showLoadingBar();
            let notifyOthersFiles = false;
            try {
                setOpenCollectionSelector(false);
                const selectedFiles = getSelectedFiles(selected, filteredFiles);
                const processedCount = await removeFromCollection(
                    collection,
                    selectedFiles,
                );
                notifyOthersFiles = processedCount != selectedFiles.length;
                clearSelection();
                await remotePull({ silent: true });
            } catch (e) {
                onGenericError(e);
            } finally {
                hideLoadingBar();
            }

            if (notifyOthersFiles) {
                showMiniDialog(notifyOthersFilesDialogAttributes());
            }
        })();
    };

    const createOnSelectForCollectionOp =
        (op: CollectionOp) => (selectedCollection: Collection) => {
            void (async () => {
                showLoadingBar();
                try {
                    setOpenCollectionSelector(false);
                    const selectedFiles = getSelectedFiles(
                        selected,
                        filteredFiles,
                    );
                    const userFiles = selectedFiles.filter(
                        (f) => f.ownerID == user.id,
                    );
                    const sourceCollectionID = selected.collectionID;
                    if (userFiles.length > 0) {
                        await performCollectionOp(
                            op,
                            selectedCollection,
                            userFiles,
                            sourceCollectionID,
                        );
                    }
                    // See: [Note: Add and move of non-user files]
                    if (userFiles.length != selectedFiles.length) {
                        showMiniDialog(notifyOthersFilesDialogAttributes());
                    }
                    clearSelection();
                    await remotePull({ silent: true });
                } catch (e) {
                    onGenericError(e);
                } finally {
                    hideLoadingBar();
                }
            })();
        };

    const createOnCreateForCollectionOp = useCallback(
        (op: CollectionOp) => {
            setPostCreateAlbumOp(op);
            return showAlbumNameInput;
        },
        [showAlbumNameInput],
    );

    const handleAlbumNameSubmit = useCallback(
        async (name: string) => {
            const collection = await createAlbum(name);
            setPostCreateAlbumOp((postCreateAlbumOp) => {
                // The function returned by createHandleCollectionOp does its
                // own progress and error reporting, defer to that.
                createOnSelectForCollectionOp(postCreateAlbumOp!)(collection);
                return undefined;
            });
        },
        [createOnSelectForCollectionOp],
    );

    const createFileOpHandler = (op: FileOp) => () => {
        void (async () => {
            showLoadingBar();
            try {
                const selectedFiles = getSelectedFiles(
                    selected,
                    op == "hide"
                        ? // passing files here instead of filteredData for hide since
                          // we want to move all files copies to hidden collection
                          state.collectionFiles.filter(
                              (f) => !state.hiddenFileIDs.has(f.id),
                          )
                        : filteredFiles,
                );
                const toProcessFiles =
                    op == "download"
                        ? selectedFiles
                        : selectedFiles.filter(
                              (file) => file.ownerID == user.id,
                          );
                if (toProcessFiles.length > 0) {
                    await performFileOp(
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
                // Apart from download, the other operations currently only work
                // on the user's own files.
                //
                // See: [Note: Add and move of non-user files].
                if (toProcessFiles.length != selectedFiles.length) {
                    showMiniDialog(notifyOthersFilesDialogAttributes());
                }
                clearSelection();
                await remotePull({ silent: true });
            } catch (e) {
                onGenericError(e);
            } finally {
                hideLoadingBar();
            }
        })();
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
    };

    const openUploader = (intent?: UploadTypeSelectorIntent) => {
        if (uploadManager.isUploadInProgress()) return;
        setUploadTypeSelectorView(true);
        setUploadTypeSelectorIntent(intent ?? "upload");
    };

    const handleShowCollectionSummary = (
        collectionSummaryID: number | undefined,
    ) => {
        // Trigger a pull of the latest data from remote when opening the trash.
        //
        // This is needed for a specific scenario:
        //
        // 1. User deletes a collection, selecting the option to delete files.
        // 2. Museum acks, and then client does a trash pull.
        //
        // This trash pull will not contain the files that belonged to the
        // collection that got deleted because the collection deletion is a
        // asynchronous operation.
        //
        // So the user might not see the entry for the just deleted file if they
        // were to go to the trash meanwhile (until the next pull happens). To
        // avoid this, we trigger a trash pull whenever it is opened.
        if (collectionSummaryID == PseudoCollectionID.trash) {
            void remoteFilesPull();
        }

        dispatch({ type: "showCollectionSummary", collectionSummaryID });
    };

    // The same function can also be used to show collections since the
    // namespace for the collection IDs and collection summary IDs are disjoint.
    const handleShowCollection = handleShowCollectionSummary;

    const handleChangeBarMode = (mode: GalleryBarMode) =>
        mode == "people"
            ? dispatch({ type: "showPeople" })
            : dispatch({ type: "showAlbums" });

    const handleShowHiddenSection = useCallback(
        () => authenticateUser().then(() => dispatch({ type: "showHidden" })),
        [],
    );

    const handleFileViewerToggleFavorite = useCallback(
        async (file: EnteFile) => {
            const fileID = file.id;
            const isFavorite = favoriteFileIDs.has(fileID);

            dispatch({ type: "addPendingFavoriteUpdate", fileID });
            try {
                const action = isFavorite
                    ? removeFromFavoritesCollection
                    : addToFavoritesCollection;
                await action([file]);
                dispatch({
                    type: "unsyncedFavoriteUpdate",
                    fileID,
                    isFavorite: !isFavorite,
                });
            } finally {
                dispatch({ type: "removePendingFavoriteUpdate", fileID });
            }
        },
        [user, favoriteFileIDs],
    );

    const handleFileViewerFileVisibilityUpdate = useCallback(
        async (file: EnteFile, visibility: ItemVisibility) => {
            const fileID = file.id;
            dispatch({ type: "addPendingVisibilityUpdate", fileID });
            try {
                await updateFilesVisibility([file], visibility);
                // [Note: Interactive updates to file metadata]
                //
                // 1. Update the remote metadata.
                //
                // 2. Construct a fake a metadata object with the updates
                //    reflected in it.
                //
                // 3. The caller (eventually) triggers a remote pull in the
                //    background, but meanwhile uses this updated metadata.
                //
                // TODO(RE): Replace with file fetch?
                dispatch({
                    type: "unsyncedPrivateMagicMetadataUpdate",
                    fileID,
                    privateMagicMetadata: {
                        ...file.magicMetadata,
                        version: (file.magicMetadata?.version ?? 0) + 1,
                        data: { ...file.magicMetadata?.data, visibility },
                    },
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
        <FullScreenDropZone
            message={
                watchFolderView ? t("watch_folder_dropzone_hint") : undefined
            }
            disabled={shouldDisableDropzone}
            onDrop={setDragAndDropFiles}
        >
            {blockingLoad && <TranslucentLoadingOverlay />}
            <PlanSelector
                {...planSelectorVisibilityProps}
                setLoading={(v) => setBlockingLoad(v)}
            />
            <CollectionSelector
                open={openCollectionSelector}
                onClose={handleCloseCollectionSelector}
                attributes={collectionSelectorAttributes}
                collectionSummaries={normalCollectionSummaries}
                collectionForCollectionSummaryID={(id) =>
                    // Null assert since the collection selector should only
                    // show "selectable" normalCollectionSummaries. See:
                    // [Note: Picking from selectable collection summaries].
                    findCollectionCreatingUncategorizedIfNeeded(
                        state.collections,
                        id,
                    )!
                }
            />
            <FilesDownloadProgress
                attributesList={filesDownloadProgressAttributesList}
                setAttributesList={setFilesDownloadProgressAttributesList}
                onShowHiddenSection={handleShowHiddenSection}
                onShowCollection={handleShowCollection}
            />
            <FixCreationTime
                {...fixCreationTimeVisibilityProps}
                files={fixCreationTimeFiles}
                onRemotePull={remotePull}
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
                        barMode={barMode}
                        isInSearchMode={isInSearchMode}
                        collection={
                            isInSearchMode ? undefined : activeCollection
                        }
                        collectionSummary={
                            isInSearchMode ? undefined : activeCollectionSummary
                        }
                        selectedFileCount={selected.count}
                        selectedOwnFileCount={selected.ownCount}
                        onClearSelection={clearSelection}
                        onRemoveFilesFromCollection={
                            handleRemoveFilesFromCollection
                        }
                        onOpenCollectionSelector={handleOpenCollectionSelector}
                        {...{
                            createOnCreateForCollectionOp,
                            createOnSelectForCollectionOp,
                            createFileOpHandler,
                        }}
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
                        onSelectPeople={() => dispatch({ type: "showPeople" })}
                        onSelectPerson={handleSelectPerson}
                    />
                )}
            </NavbarBase>
            {isFirstLoad && <FirstLoadMessage />}
            {isOffline && <OfflineMessage />}

            <GalleryBarAndListHeader
                {...{
                    user,
                    activeCollection,
                    activeCollectionID,
                    activePerson,
                    setPhotoListHeader,
                    setFilesDownloadProgressAttributesCreator,
                    filesDownloadProgressAttributesList,
                }}
                mode={barMode}
                shouldHide={isInSearchMode}
                barCollectionSummaries={barCollectionSummaries}
                emailByUserID={state.emailByUserID}
                shareSuggestionEmails={state.shareSuggestionEmails}
                people={
                    (state.view.type == "people"
                        ? state.view.visiblePeople
                        : undefined) ?? []
                }
                onChangeMode={handleChangeBarMode}
                setBlockingLoad={setBlockingLoad}
                setActiveCollectionID={handleShowCollectionSummary}
                onRemotePull={remotePull}
                onSelectPerson={handleSelectPerson}
            />

            <Upload
                {...{
                    user,
                    dragAndDropFiles,
                    uploadTypeSelectorIntent,
                    uploadTypeSelectorView,
                }}
                isFirstUpload={haveOnlySystemCollections(
                    normalCollectionSummaries,
                )}
                activeCollection={activeCollection}
                closeUploadTypeSelector={setUploadTypeSelectorView.bind(
                    null,
                    false,
                )}
                setLoading={setBlockingLoad}
                setShouldDisableDropzone={setShouldDisableDropzone}
                onRemotePull={remotePull}
                onRemoteFilesPull={remoteFilesPull}
                onOpenCollectionSelector={handleOpenCollectionSelector}
                onCloseCollectionSelector={handleCloseCollectionSelector}
                onUploadFile={(file) => dispatch({ type: "uploadFile", file })}
                onShowPlanSelector={showPlanSelector}
                onShowSessionExpiredDialog={showSessionExpiredDialog}
            />
            <Sidebar
                {...sidebarVisibilityProps}
                normalCollectionSummaries={normalCollectionSummaries}
                uncategorizedCollectionSummaryID={
                    state.uncategorizedCollectionSummaryID
                }
                onShowPlanSelector={showPlanSelector}
                onShowCollectionSummary={handleShowCollectionSummary}
                onShowHiddenSection={handleShowHiddenSection}
                onShowExport={showExport}
                onAuthenticateUser={authenticateUser}
            />
            <WhatsNew {...whatsNewVisibilityProps} />
            {!isInSearchMode &&
            !isFirstLoad &&
            !state.collectionFiles.length &&
            activeCollectionID === PseudoCollectionID.all ? (
                <GalleryEmptyState
                    isUploadInProgress={uploadManager.isUploadInProgress()}
                    onUpload={openUploader}
                />
            ) : !isInSearchMode &&
              !isFirstLoad &&
              state.view.type == "people" &&
              !state.view.activePerson ? (
                <PeopleEmptyState />
            ) : (
                <FileListWithViewer
                    mode={barMode}
                    modePlus={isInSearchMode ? "search" : barMode}
                    header={photoListHeader}
                    user={user}
                    files={filteredFiles}
                    enableDownload={true}
                    showAppDownloadBanner={
                        state.collectionFiles.length < 30 && !isInSearchMode
                    }
                    isMagicSearchResult={state.searchSuggestion?.type == "clip"}
                    selectable={true}
                    selected={selected}
                    setSelected={setSelected}
                    activeCollectionID={activeCollectionID}
                    activePersonID={activePerson?.id}
                    isInIncomingSharedCollection={activeCollectionSummary?.attributes.has(
                        "sharedIncoming",
                    )}
                    isInHiddenSection={barMode == "hidden-albums"}
                    {...{
                        favoriteFileIDs,
                        collectionNameByID,
                        fileNormalCollectionIDs,
                        pendingFavoriteUpdates,
                        pendingVisibilityUpdates,
                    }}
                    emailByUserID={state.emailByUserID}
                    setFilesDownloadProgressAttributesCreator={
                        setFilesDownloadProgressAttributesCreator
                    }
                    onToggleFavorite={handleFileViewerToggleFavorite}
                    onFileVisibilityUpdate={
                        handleFileViewerFileVisibilityUpdate
                    }
                    onMarkTempDeleted={handleMarkTempDeleted}
                    onSetOpenFileViewer={setIsFileViewerOpen}
                    onRemotePull={remotePull}
                    onRemoteFilesPull={remoteFilesPull}
                    onVisualFeedback={handleVisualFeedback}
                    onSelectCollection={handleSelectCollection}
                    onSelectPerson={handleSelectPerson}
                />
            )}
            <Export {...exportVisibilityProps} {...{ collectionNameByID }} />
            <AuthenticateUser
                {...authenticateUserVisibilityProps}
                onAuthenticate={onAuthenticateCallback.current!}
            />
            <SingleInputDialog
                {...albumNameInputVisibilityProps}
                title={t("new_album")}
                label={t("album_name")}
                submitButtonTitle={t("create")}
                onSubmit={handleAlbumNameSubmit}
            />
        </FullScreenDropZone>
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
    const disabled = uploadManager.isUploadInProgress();
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
            flex: 1,
            alignItems: "center",
            background: theme.vars.palette.background.default,
        })}
    >
        <IconButton onClick={onBack}>
            <ArrowBackIcon />
        </IconButton>
        <Typography sx={{ flex: 1 }}>{t("section_hidden")}</Typography>
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
