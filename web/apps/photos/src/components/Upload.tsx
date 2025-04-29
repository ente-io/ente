import ChevronRightIcon from "@mui/icons-material/ChevronRight";
import DiscFullIcon from "@mui/icons-material/DiscFull";
import GoogleIcon from "@mui/icons-material/Google";
import ImageOutlinedIcon from "@mui/icons-material/ImageOutlined";
import PermMediaOutlinedIcon from "@mui/icons-material/PermMediaOutlined";
import {
    Box,
    CircularProgress,
    Dialog,
    DialogTitle,
    Link,
    Stack,
    Typography,
    type DialogProps,
} from "@mui/material";
import { isDesktop } from "ente-base/app";
import { SpacedRow } from "ente-base/components/containers";
import { DialogCloseIconButton } from "ente-base/components/mui/DialogCloseIconButton";
import { FocusVisibleButton } from "ente-base/components/mui/FocusVisibleButton";
import { RowButton } from "ente-base/components/RowButton";
import { useIsTouchscreen } from "ente-base/components/utils/hooks";
import {
    useModalVisibility,
    type ModalVisibilityProps,
} from "ente-base/components/utils/modal";
import { useBaseContext } from "ente-base/context";
import { basename, dirname, joinPath } from "ente-base/file-name";
import log from "ente-base/log";
import type { CollectionMapping, Electron, ZipItem } from "ente-base/types/ipc";
import { useFileInput } from "ente-gallery/components/utils/use-file-input";
import type {
    FileAndPath,
    UploadItem,
    UploadPhase,
} from "ente-gallery/services/upload";
import type { Collection } from "ente-media/collection";
import type { EnteFile } from "ente-media/file";
import { UploaderNameInput } from "ente-new/albums/components/UploaderNameInput";
import { CollectionMappingChoice } from "ente-new/photos/components/CollectionMappingChoice";
import type { CollectionSelectorAttributes } from "ente-new/photos/components/CollectionSelector";
import { downloadAppDialogAttributes } from "ente-new/photos/components/utils/download";
import { getLatestCollections } from "ente-new/photos/services/collections";
import { exportMetadataDirectoryName } from "ente-new/photos/services/export";
import { redirectToCustomerPortal } from "ente-new/photos/services/user-details";
import { usePhotosAppContext } from "ente-new/photos/types/context";
import { CustomError } from "ente-shared/error";
import { firstNonEmpty } from "ente-utils/array";
import { t } from "i18next";
import { GalleryContext } from "pages/gallery";
import React, {
    useCallback,
    useContext,
    useEffect,
    useRef,
    useState,
} from "react";
import {
    getPublicCollectionUID,
    getPublicCollectionUploaderName,
    savePublicCollectionUploaderName,
} from "services/publicCollectionService";
import type {
    InProgressUpload,
    SegregatedFinishedUploads,
    UploadCounter,
    UploadFileNames,
    UploadItemWithCollection,
} from "services/upload/uploadManager";
import uploadManager from "services/upload/uploadManager";
import watcher from "services/watch";
import { SetLoading } from "types/gallery";
import { getOrCreateAlbum } from "utils/collection";
import { PublicCollectionGalleryContext } from "utils/publicCollectionGallery";
import { SetCollectionNamerAttributes } from "./Collections/CollectionNamer";
import { UploadProgress } from "./UploadProgress";

export type UploadTypeSelectorIntent = "upload" | "import" | "collect";

interface UploadProps {
    syncWithRemote: (force?: boolean, silent?: boolean) => Promise<void>;
    closeUploadTypeSelector: () => void;
    /**
     * Show the collection selector with the given {@link attributes}.
     */
    onOpenCollectionSelector?: (
        attributes: CollectionSelectorAttributes,
    ) => void;
    /**
     * Close the collection selector if it is open.
     */
    onCloseCollectionSelector?: () => void;
    setCollectionNamerAttributes?: SetCollectionNamerAttributes;
    setLoading: SetLoading;
    setShouldDisableDropzone: (value: boolean) => void;
    showCollectionSelector?: () => void;
    /**
     * Callback invoked when a file is uploaded.
     *
     * @param file The newly uploaded file.
     */
    onUploadFile: (file: EnteFile) => void;
    /**
     * Called when the plan selection modal should be shown.
     *
     * It is optional because {@link Upload} is also used by the public albums
     * app, where the scenario requiring this will not arise.
     */
    onShowPlanSelector?: () => void;
    setCollections?: (cs: Collection[]) => void;
    isFirstUpload?: boolean;
    uploadTypeSelectorView: boolean;
    showSessionExpiredMessage: () => void;
    dragAndDropFiles: File[];
    uploadCollection?: Collection;
    uploadTypeSelectorIntent: UploadTypeSelectorIntent;
    activeCollection?: Collection;
}

type UploadType = "files" | "folders" | "zips";

type UploadItemAndPath = [UploadItem, string];

/**
 * Top level component that houses the infrastructure for handling uploads.
 */
export const Upload: React.FC<UploadProps> = ({
    isFirstUpload,
    dragAndDropFiles,
    onUploadFile,
    onShowPlanSelector,
    showSessionExpiredMessage,
    ...props
}) => {
    const { showMiniDialog, onGenericError } = useBaseContext();
    const { showNotification, watchFolderView } = usePhotosAppContext();
    const galleryContext = useContext(GalleryContext);
    const publicCollectionGalleryContext = useContext(
        PublicCollectionGalleryContext,
    );

    const [uploadProgressView, setUploadProgressView] = useState(false);
    const [uploadPhase, setUploadPhase] = useState<UploadPhase>("preparing");
    const [uploadFileNames, setUploadFileNames] = useState<UploadFileNames>();
    const [uploadCounter, setUploadCounter] = useState<UploadCounter>({
        finished: 0,
        total: 0,
    });
    const [inProgressUploads, setInProgressUploads] = useState<
        InProgressUpload[]
    >([]);
    const [finishedUploads, setFinishedUploads] =
        useState<SegregatedFinishedUploads>(new Map());
    const [percentComplete, setPercentComplete] = useState(0);
    const [hasLivePhotos, setHasLivePhotos] = useState(false);

    const [openCollectionMappingChoice, setOpenCollectionMappingChoice] =
        useState(false);
    const [importSuggestion, setImportSuggestion] = useState<ImportSuggestion>(
        defaultImportSuggestion,
    );
    const {
        show: showUploaderNameInput,
        props: uploaderNameInputVisibilityProps,
    } = useModalVisibility();

    /**
     * {@link File}s that the user drag-dropped or selected for uploads (web).
     *
     * This is the only type of selection that is possible when we're running in
     * the browser.
     */
    const [webFiles, setWebFiles] = useState<File[]>([]);
    /**
     * {@link File}s that the user drag-dropped or selected for uploads,
     * augmented with their paths (desktop).
     *
     * These siblings of {@link webFiles} come into play when we are running in
     * the context of our desktop app.
     */
    const [desktopFiles, setDesktopFiles] = useState<FileAndPath[]>([]);
    /**
     * Paths of file to upload that we've received over the IPC bridge from the
     * code running in the Node.js layer of our desktop app.
     *
     * Unlike {@link filesWithPaths} which are still user initiated,
     * {@link desktopFilePaths} can be set via programmatic action. For example,
     * if the user has setup a folder watch, and a new file is added on their
     * local file system in one of the watched folders, then the relevant path
     * of the new file would get added to {@link desktopFilePaths}.
     */
    const [desktopFilePaths, setDesktopFilePaths] = useState<string[]>([]);
    /**
     * (zip file path, entry within zip file) tuples for zip files that the user
     * is trying to upload.
     *
     * These are only set when we are running in the context of our desktop app.
     * They may be set either on a user action (when the user selects or
     * drag-drops zip files) or programmatically (when the app is trying to
     * resume pending uploads from a previous session).
     */
    const [desktopZipItems, setDesktopZipItems] = useState<ZipItem[]>([]);

    /**
     * Consolidated and cleaned list obtained from {@link webFiles},
     * {@link desktopFiles}, {@link desktopFilePaths} and
     * {@link desktopZipItems}.
     *
     * Augment each {@link UploadItem} with its "path" (relative path or name in
     * the case of {@link webFiles}, absolute path in the case of
     * {@link desktopFiles}, {@link desktopFilePaths}, and the path within the
     * zip file for {@link desktopZipItems}).
     *
     * See the documentation of {@link UploadItem} for more details.
     */
    const uploadItemsAndPaths = useRef<UploadItemAndPath[]>([]);

    /**
     * If true, then the next upload we'll be processing was initiated by our
     * desktop app.
     */
    const isPendingDesktopUpload = useRef(false);

    /**
     * If set, this will be the name of the collection that our desktop app
     * wishes for us to upload into.
     */
    const pendingDesktopUploadCollectionName = useRef<string>("");

    /**
     * This is set to thue user's choice when the user chooses one of the
     * predefined type to upload from the upload type selector dialog
     */
    const selectedUploadType = useRef<UploadType | undefined>(undefined);

    const currentUploadPromise = useRef<Promise<void> | undefined>(undefined);
    const uploadRunning = useRef(false);
    const uploaderNameRef = useRef<string>(null);
    const isDragAndDrop = useRef(false);

    /**
     * `true` if we've activated one hidden {@link Inputs} that allow the user
     * to select items, and haven't heard back from the browser as to the
     * selection (or cancellation).
     *
     * [Note: Showing an activity indicator during upload item selection]
     *
     * When selecting a large number of items (100K+), the browser can take
     * significant time (10s+) before it hands back control to us. The
     * {@link isInputPending} state tracks this intermediate state, and we use
     * it to show an activity indicator to let that the user know that their
     * selection is still being processed.
     */
    const [isInputPending, setIsInputPending] = useState(false);

    /**
     * Files that were selected by the user in the last activation of one of the
     * hidden {@link Inputs}.
     */
    const [selectedInputFiles, setSelectedInputFiles] = useState<File[]>([]);

    const handleInputSelect = useCallback((files: File[]) => {
        setIsInputPending(false);
        setSelectedInputFiles(files);
    }, []);

    const handleInputCancel = useCallback(() => {
        setIsInputPending(false);
    }, []);

    const {
        getInputProps: getFileSelectorInputProps,
        openSelector: openFileSelector,
    } = useFileInput({
        directory: false,
        onSelect: handleInputSelect,
        onCancel: handleInputCancel,
    });

    const {
        getInputProps: getFolderSelectorInputProps,
        openSelector: openFolderSelector,
    } = useFileInput({
        directory: true,
        onSelect: handleInputSelect,
        onCancel: handleInputCancel,
    });

    const {
        getInputProps: getZipFileSelectorInputProps,
        openSelector: openZipFileSelector,
    } = useFileInput({
        directory: false,
        accept: ".zip",
        onSelect: handleInputSelect,
        onCancel: handleInputCancel,
    });

    const electron = globalThis.electron;

    const closeUploadProgress = () => setUploadProgressView(false);

    const handleCollectionMappingChoiceClose = () => {
        setOpenCollectionMappingChoice(false);
        uploadRunning.current = false;
    };

    const handleCollectionSelectorCancel = () => {
        uploadRunning.current = false;
    };

    const handleUploaderNameInputClose = () => {
        uploaderNameInputVisibilityProps.onClose();
        uploadRunning.current = false;
    };

    useEffect(() => {
        uploadManager.init(
            {
                setPercentComplete,
                setUploadCounter,
                setInProgressUploads,
                setFinishedUploads,
                setUploadPhase,
                setUploadFilenames: setUploadFileNames,
                setHasLivePhotos,
                setUploadProgressView,
            },
            onUploadFile,
            publicCollectionGalleryContext.credentials,
        );

        if (uploadManager.isUploadRunning()) {
            setUploadProgressView(true);
        }

        if (electron) {
            const upload = (collectionName: string, filePaths: string[]) => {
                isPendingDesktopUpload.current = true;
                pendingDesktopUploadCollectionName.current = collectionName;
                setDesktopFilePaths(filePaths);
            };

            const requestSyncWithRemote = () => {
                props.syncWithRemote().catch((e: unknown) => {
                    log.error(
                        "Ignoring error when syncing trash changes with remote",
                        e,
                    );
                });
            };

            watcher.init(upload, requestSyncWithRemote);

            electron.pendingUploads().then((pending) => {
                if (!pending) return;

                const { collectionName, filePaths, zipItems } = pending;

                log.info(
                    `Resuming pending of upload of ${filePaths.length + zipItems.length} items${collectionName ? " to collection " + collectionName : ""}`,
                );
                isPendingDesktopUpload.current = true;
                pendingDesktopUploadCollectionName.current = collectionName;
                setDesktopFilePaths(filePaths);
                setDesktopZipItems(zipItems);
            });
        }
    }, [publicCollectionGalleryContext.credentials]);

    // Handle selected files when user selects files for upload through the open
    // file / open folder selection dialog, or drag-and-drops them.
    useEffect(() => {
        if (watchFolderView) {
            // if watch folder dialog is open don't catch the dropped file
            // as they are folder being dropped for watching
            return;
        }

        let files: File[];
        isDragAndDrop.current = false;

        switch (selectedUploadType.current) {
            case "files":
            case "folders":
            case "zips":
                files = selectedInputFiles;
                break;

            default:
                isDragAndDrop.current = true;
                files = dragAndDropFiles;
                break;
        }

        if (electron) {
            desktopFilesAndZipItems(electron, files).then(
                ({ fileAndPaths, zipItems }) => {
                    setDesktopFiles(fileAndPaths);
                    setDesktopZipItems(zipItems);
                },
            );
        } else {
            setWebFiles(files);
        }
    }, [selectedInputFiles, dragAndDropFiles]);

    // Trigger an upload when any of the dependencies change.
    useEffect(() => {
        // About the paths:
        //
        // - These are not necessarily the full paths. In particular, when
        //   running on the browser they'll be the relative paths (at best) or
        //   just the file-name otherwise.
        //
        // - All the paths use POSIX separators. See inline comments.
        //
        // - For zips we concatenate the path of the zip to the path within the
        //   zip for the purpose of computing the nesting.
        const allItemAndPaths = [
            // Relative path (using POSIX separators) or the file's name.
            webFiles.map((f) => [f, pathLikeForWebFile(f)]),
            // The paths we get from the desktop app all eventually come either
            // from electron.selectDirectory or electron.pathForFile, both of
            // which return POSIX paths.
            desktopFiles.map((fp) => [fp, fp.path]),
            desktopFilePaths.map((p) => [p, p]),
            // Concatenate the path of the item within the zip to path of the
            // zip. This won't affect the upload: this path is only used for
            // computation of the "parent" folder, and this concatenation best
            // reflects the nesting.
            //
            // Re POSIXness: The first path, that of the zip file itself, is
            // POSIX like the other paths we get over the IPC boundary. And the
            // second path, ze[1], the entry name, uses POSIX separators because
            // that is what the ZIP format uses.
            desktopZipItems.map((ze) => [ze, joinPath(dirname(ze[0]), ze[1])]),
        ].flat() as UploadItemAndPath[];

        if (allItemAndPaths.length == 0) return;

        if (uploadManager.isUploadRunning()) {
            if (watcher.isUploadRunning()) {
                log.info("Pausing watch folder sync to prioritize user upload");
                watcher.pauseRunningSync();
            } else {
                log.info(
                    "Ignoring new upload request when upload is already running",
                );
                return;
            }
        }

        uploadRunning.current = true;
        props.closeUploadTypeSelector();
        props.setLoading(true);

        setWebFiles([]);
        setDesktopFiles([]);
        setDesktopFilePaths([]);
        setDesktopZipItems([]);

        // Remove hidden files (files whose names begins with a ".").
        const prunedItemAndPaths = allItemAndPaths.filter(
            ([, p]) => !basename(p).startsWith("."),
        );

        uploadItemsAndPaths.current = prunedItemAndPaths;
        if (uploadItemsAndPaths.current.length === 0) {
            props.setLoading(false);
            return;
        }

        const importSuggestion = deriveImportSuggestion(
            selectedUploadType.current,
            prunedItemAndPaths.map(([, p]) => p),
        );
        setImportSuggestion(importSuggestion);

        log.debug(() => ["Upload request", uploadItemsAndPaths.current]);
        log.debug(() => ["Import suggestion", importSuggestion]);

        const _selectedUploadType = selectedUploadType.current;
        selectedUploadType.current = null;
        props.setLoading(false);

        (async () => {
            if (publicCollectionGalleryContext.credentials) {
                const uploaderName = await getPublicCollectionUploaderName(
                    getPublicCollectionUID(
                        publicCollectionGalleryContext.credentials.accessToken,
                    ),
                );
                uploaderNameRef.current = uploaderName;
                showUploaderNameInput();
                return;
            }

            if (isPendingDesktopUpload.current) {
                isPendingDesktopUpload.current = false;
                if (pendingDesktopUploadCollectionName.current) {
                    uploadFilesToNewCollections(
                        "root",
                        pendingDesktopUploadCollectionName.current,
                    );
                    pendingDesktopUploadCollectionName.current = null;
                } else {
                    uploadFilesToNewCollections("parent");
                }
                return;
            }

            if (electron && _selectedUploadType == "zips") {
                uploadFilesToNewCollections("parent");
                return;
            }

            if (isFirstUpload && !importSuggestion.rootFolderName) {
                importSuggestion.rootFolderName = t(
                    "autogenerated_first_album_name",
                );
            }

            if (isDragAndDrop.current) {
                isDragAndDrop.current = false;
                if (
                    props.activeCollection &&
                    props.activeCollection.owner.id === galleryContext.user?.id
                ) {
                    uploadFilesToExistingCollection(props.activeCollection);
                    return;
                }
            }

            let showNextModal = () => {};
            if (importSuggestion.hasNestedFolders) {
                showNextModal = () => setOpenCollectionMappingChoice(true);
            } else {
                showNextModal = () =>
                    showCollectionCreateModal(importSuggestion.rootFolderName);
            }

            props.onOpenCollectionSelector({
                action: "upload",
                onSelectCollection: uploadFilesToExistingCollection,
                onCreateCollection: showNextModal,
                onCancel: handleCollectionSelectorCancel,
            });
        })();
    }, [webFiles, desktopFiles, desktopFilePaths, desktopZipItems]);

    const preCollectionCreationAction = async () => {
        props.onCloseCollectionSelector?.();
        props.setShouldDisableDropzone(!uploadManager.shouldAllowNewUpload());
        setUploadPhase("preparing");
        setUploadProgressView(true);
    };

    const uploadFilesToExistingCollection = async (
        collection: Collection,
        uploaderName?: string,
    ) => {
        await preCollectionCreationAction();
        const uploadItemsWithCollection = uploadItemsAndPaths.current.map(
            ([uploadItem], index) => ({
                uploadItem,
                localID: index,
                collectionID: collection.id,
            }),
        );
        await waitInQueueAndUploadFiles(
            uploadItemsWithCollection,
            [collection],
            uploaderName,
        );
        uploadItemsAndPaths.current = null;
    };

    const uploadFilesToNewCollections = async (
        mapping: CollectionMapping,
        collectionName?: string,
    ) => {
        await preCollectionCreationAction();
        let uploadItemsWithCollection: UploadItemWithCollection[] = [];
        const collections: Collection[] = [];
        let collectionNameToUploadItems = new Map<string, UploadItem[]>();
        if (mapping == "root") {
            collectionNameToUploadItems.set(
                collectionName,
                uploadItemsAndPaths.current.map(([i]) => i),
            );
        } else {
            collectionNameToUploadItems = groupFilesBasedOnParentFolder(
                uploadItemsAndPaths.current,
                collectionName,
            );
        }
        try {
            const existingCollections = await getLatestCollections();
            let index = 0;
            for (const [
                collectionName,
                uploadItems,
            ] of collectionNameToUploadItems) {
                const collection = await getOrCreateAlbum(
                    collectionName,
                    existingCollections,
                );
                collections.push(collection);
                props.setCollections([...existingCollections, ...collections]);
                uploadItemsWithCollection = [
                    ...uploadItemsWithCollection,
                    ...uploadItems.map((uploadItem) => ({
                        localID: index++,
                        collectionID: collection.id,
                        uploadItem,
                    })),
                ];
            }
        } catch (e) {
            closeUploadProgress();
            onGenericError(e);
            return;
        }
        await waitInQueueAndUploadFiles(uploadItemsWithCollection, collections);
        uploadItemsAndPaths.current = null;
    };

    const waitInQueueAndUploadFiles = async (
        uploadItemsWithCollection: UploadItemWithCollection[],
        collections: Collection[],
        uploaderName?: string,
    ) => {
        const currentPromise = currentUploadPromise.current;
        currentUploadPromise.current = (async () => {
            if (currentPromise) await currentPromise;
            return uploadFiles(
                uploadItemsWithCollection,
                collections,
                uploaderName,
            );
        })();
        await currentUploadPromise.current;
    };

    const preUploadAction = async () => {
        uploadManager.prepareForNewUpload();
        setUploadProgressView(true);
        await props.syncWithRemote(true, true);
    };

    function postUploadAction() {
        props.setShouldDisableDropzone(false);
        uploadRunning.current = false;
        props.syncWithRemote();
    }

    const uploadFiles = async (
        uploadItemsWithCollection: UploadItemWithCollection[],
        collections: Collection[],
        uploaderName?: string,
    ) => {
        try {
            preUploadAction();
            if (
                electron &&
                !isPendingDesktopUpload.current &&
                !watcher.isUploadRunning()
            ) {
                setPendingUploads(
                    electron,
                    collections,
                    uploadItemsWithCollection
                        .map(({ uploadItem }) => uploadItem)
                        .filter((x) => x),
                );
            }
            const wereFilesProcessed = await uploadManager.uploadItems(
                uploadItemsWithCollection,
                collections,
                uploaderName,
            );
            if (!wereFilesProcessed) closeUploadProgress();
            if (isDesktop) {
                if (watcher.isUploadRunning()) {
                    await watcher.allFileUploadsDone(
                        uploadItemsWithCollection,
                        collections,
                    );
                } else if (watcher.isSyncPaused()) {
                    // Resume folder watch after the user upload that
                    // interrupted it is done.
                    watcher.resumePausedSync();
                }
            }
        } catch (e) {
            log.error("Failed to upload files", e);
            showUserFacingError(e.message);
            closeUploadProgress();
        } finally {
            postUploadAction();
        }
    };

    const retryFailed = async () => {
        try {
            log.info("Retrying failed uploads");
            const { items, collections } =
                uploadManager.getFailedItemsWithCollections();
            const uploaderName = uploadManager.getUploaderName();
            await preUploadAction();
            await uploadManager.uploadItems(items, collections, uploaderName);
        } catch (e) {
            log.error("Retrying failed uploads failed", e);
            showUserFacingError(e.message);
            closeUploadProgress();
        } finally {
            postUploadAction();
        }
    };

    function showUserFacingError(err: string) {
        switch (err) {
            case CustomError.SESSION_EXPIRED:
                showSessionExpiredMessage();
                break;
            case CustomError.SUBSCRIPTION_EXPIRED:
                showNotification({
                    color: "critical",
                    captionFirst: true,
                    caption: t("subscription_expired"),
                    title: t("renew_now"),
                    onClick: redirectToCustomerPortal,
                });
                break;
            case CustomError.STORAGE_QUOTA_EXCEEDED:
                showNotification({
                    color: "critical",
                    captionFirst: true,
                    caption: t("storage_quota_exceeded"),
                    title: t("upgrade_now"),
                    onClick: onShowPlanSelector,
                    startIcon: <DiscFullIcon />,
                });
                break;
            default:
                showNotification({
                    color: "critical",
                    title: t("generic_error_retry"),
                });
        }
    }

    const uploadToSingleNewCollection = (collectionName: string) => {
        uploadFilesToNewCollections("root", collectionName);
    };

    const showCollectionCreateModal = (suggestedName: string) => {
        props.setCollectionNamerAttributes({
            title: t("new_album"),
            buttonText: t("create"),
            autoFilledName: suggestedName,
            callback: uploadToSingleNewCollection,
        });
    };

    const cancelUploads = () => {
        uploadManager.cancelRunningUpload();
    };

    const handleUploadTypeSelect = (type: UploadType) => {
        selectedUploadType.current = type;
        setIsInputPending(true);
        switch (type) {
            case "files":
                openFileSelector();
                break;
            case "folders":
                openFolderSelector();
                break;
            case "zips":
                if (electron) {
                    openZipFileSelector();
                } else {
                    showMiniDialog(downloadAppDialogAttributes());
                }
                break;
        }
    };

    const handlePublicUpload = async (
        uploaderName: string,
        skipSave?: boolean,
    ) => {
        try {
            if (!skipSave) {
                savePublicCollectionUploaderName(
                    getPublicCollectionUID(
                        publicCollectionGalleryContext.credentials.accessToken,
                    ),
                    uploaderName,
                );
            }
            await uploadFilesToExistingCollection(
                props.uploadCollection,
                uploaderName,
            );
        } catch (e) {
            log.error("public upload failed ", e);
        }
    };

    const handleCollectionMappingSelect = (mapping: CollectionMapping) =>
        uploadFilesToNewCollections(
            mapping,
            importSuggestion.rootFolderName ??
                t("autogenerated_default_album_name"),
        );

    return (
        <>
            <Inputs
                {...{
                    getFileSelectorInputProps,
                    getFolderSelectorInputProps,
                    getZipFileSelectorInputProps,
                }}
            />
            <CollectionMappingChoice
                open={openCollectionMappingChoice}
                onClose={handleCollectionMappingChoiceClose}
                onSelect={handleCollectionMappingSelect}
            />
            <UploadTypeSelector
                open={props.uploadTypeSelectorView}
                onClose={props.closeUploadTypeSelector}
                intent={props.uploadTypeSelectorIntent}
                pendingUploadType={
                    isInputPending ? selectedUploadType.current : undefined
                }
                onSelect={handleUploadTypeSelect}
            />
            <UploadProgress
                open={uploadProgressView}
                onClose={closeUploadProgress}
                percentComplete={percentComplete}
                uploadFileNames={uploadFileNames}
                uploadCounter={uploadCounter}
                uploadPhase={uploadPhase}
                inProgressUploads={inProgressUploads}
                hasLivePhotos={hasLivePhotos}
                retryFailed={retryFailed}
                finishedUploads={finishedUploads}
                cancelUploads={cancelUploads}
            />
            <UploaderNameInput
                open={uploaderNameInputVisibilityProps.open}
                onClose={handleUploaderNameInputClose}
                uploaderName={uploaderNameRef.current}
                uploadFileCount={uploadItemsAndPaths.current?.length ?? 0}
                onSubmit={handlePublicUpload}
            />
        </>
    );
};

type GetInputProps = () => React.HTMLAttributes<HTMLInputElement>;

interface InputsProps {
    getFileSelectorInputProps: GetInputProps;
    getFolderSelectorInputProps: GetInputProps;
    getZipFileSelectorInputProps: GetInputProps;
}

/**
 * Create a bunch of HTML inputs elements, one each for the given props.
 *
 * These hidden input element serve as the way for us to show various file /
 * folder Selector dialogs and handle drag and drop inputs.
 */
const Inputs: React.FC<InputsProps> = ({
    getFileSelectorInputProps,
    getFolderSelectorInputProps,
    getZipFileSelectorInputProps,
}) => (
    <>
        <input {...getFileSelectorInputProps()} />
        <input {...getFolderSelectorInputProps()} />
        <input {...getZipFileSelectorInputProps()} />
    </>
);

const desktopFilesAndZipItems = async (electron: Electron, files: File[]) => {
    const fileAndPaths: FileAndPath[] = [];
    let zipItems: ZipItem[] = [];

    for (const file of files) {
        const path = electron.pathForFile(file);
        if (file.name.endsWith(".zip")) {
            zipItems = zipItems.concat(await electron.listZipItems(path));
        } else {
            fileAndPaths.push({ file, path });
        }
    }

    return { fileAndPaths, zipItems };
};

/**
 * Return the relative path or name of a File object selected or
 * drag-and-dropped on the web.
 *
 * There are three cases here:
 *
 * 1. If the user selects individual file(s), then the returned File objects
 *    will only have a `name`.
 *
 * 2. If the user selects directory(ies), then the returned File objects will
 *    have a `webkitRelativePath`. For more details, see [Note:
 *    webkitRelativePath]. In particular, these will POSIX separators.
 *
 * 3. If the user drags-and-drops, then the react-dropzone library that we use
 *    will internally convert `webkitRelativePath` to `path`, but otherwise it
 *    behaves same as case 2.
 *    https://github.com/react-dropzone/file-selector/blob/master/src/file.ts#L1214
 */
const pathLikeForWebFile = (file: File): string =>
    firstNonEmpty([
        // We need to check first, since path is not a property of
        // the standard File objects.
        "path" in file && typeof file.path == "string" ? file.path : undefined,
        file.webkitRelativePath,
        file.name,
    ])!;

/**
 * This is used to prompt the user the make upload strategy choice.
 *
 * This is derived from the items that the user selected.
 */
interface ImportSuggestion {
    rootFolderName: string;
    hasNestedFolders: boolean;
}

const defaultImportSuggestion: ImportSuggestion = {
    rootFolderName: "",
    hasNestedFolders: false,
};

const deriveImportSuggestion = (
    uploadType: UploadType,
    paths: string[],
): ImportSuggestion => {
    if (isDesktop && uploadType == "files") {
        return defaultImportSuggestion;
    }

    const separatorCounts = new Map(
        paths.map((s) => [s, s.match(/\//g)?.length ?? 0]),
    );
    const separatorCount = (s: string) => separatorCounts.get(s)!;
    paths.sort((path1, path2) => separatorCount(path1) - separatorCount(path2));
    const firstPath = paths[0];
    const lastPath = paths[paths.length - 1];

    const L = firstPath.length;
    let i = 0;
    const firstFileFolder = firstPath.substring(0, firstPath.lastIndexOf("/"));
    const lastFileFolder = lastPath.substring(0, lastPath.lastIndexOf("/"));

    while (i < L && firstPath.charAt(i) === lastPath.charAt(i)) i++;
    let commonPathPrefix = firstPath.substring(0, i);

    if (commonPathPrefix) {
        commonPathPrefix = commonPathPrefix.substring(
            0,
            commonPathPrefix.lastIndexOf("/"),
        );
        if (commonPathPrefix) {
            commonPathPrefix = commonPathPrefix.substring(
                commonPathPrefix.lastIndexOf("/") + 1,
            );
        }
    }

    return {
        rootFolderName: commonPathPrefix || null,
        hasNestedFolders: firstFileFolder !== lastFileFolder,
    };
};

/**
 * Group files that are that have the same parent folder into collections.
 *
 * For Example, if the user selects files have a directory structure like:
 *
 *               a
 *             / |  \
 *            b  j   c
 *           /|\    /  \
 *          e f g   h  i
 *
 * The files will grouped into 3 collections:
 *
 *     [
 *       a => [j],
 *       b => [e,f,g],
 *       c => [h, i]
 *     ]
 *
 * @param defaultFolderName Optional collection name to use for any rooted files
 * that do not have a parent folder. The function will throw if a default is not
 * provided and we encounter any such files without a parent.
 */
const groupFilesBasedOnParentFolder = (
    uploadItemAndPaths: UploadItemAndPath[],
    defaultFolderName: string | undefined,
) => {
    const result = new Map<string, UploadItem[]>();
    for (const [uploadItem, pathOrName] of uploadItemAndPaths) {
        let folderPath = pathOrName.substring(0, pathOrName.lastIndexOf("/"));
        // If the parent folder of a file is "metadata", then we consider it to
        // be part of the parent folder.
        //
        // e.g. for FileList
        //
        //    [a/x.png, a/metadata/x.png.json]
        //
        // they will both be grouped into the collection "a". This is so that we
        // cluster the metadata json files in the same collection as the file it
        // is for.
        if (folderPath.endsWith(exportMetadataDirectoryName)) {
            folderPath = folderPath.substring(0, folderPath.lastIndexOf("/"));
        }
        let folderName = folderPath.substring(folderPath.lastIndexOf("/") + 1);
        if (!folderName) {
            if (!defaultFolderName)
                throw Error(`Leaf file (without default): ${folderPath}`);
            folderName = defaultFolderName;
        }
        if (!result.has(folderName)) result.set(folderName, []);
        result.get(folderName).push(uploadItem);
    }
    return result;
};

const setPendingUploads = async (
    electron: Electron,
    collections: Collection[],
    uploadItems: UploadItem[],
) => {
    let collectionName: string | undefined;
    /* collection being one suggest one of two things
        1. Either the user has upload to a single existing collection
        2. Created a new single collection to upload to
            may have had multiple folder, but chose to upload
            to one album
        hence saving the collection name when upload collection count is 1
        helps the info of user choosing this options
        and on next upload we can directly start uploading to this collection
    */
    if (collections.length == 1) {
        collectionName = collections[0].name;
    }

    const filePaths: string[] = [];
    const zipItems: ZipItem[] = [];
    for (const item of uploadItems) {
        if (item instanceof File) {
            throw new Error("Unexpected web file for a desktop pending upload");
        } else if (typeof item == "string") {
            filePaths.push(item);
        } else if (Array.isArray(item)) {
            zipItems.push(item);
        } else {
            filePaths.push(item.path);
        }
    }

    await electron.setPendingUploads({ collectionName, filePaths, zipItems });
};

type UploadTypeSelectorProps = ModalVisibilityProps & {
    /**
     * The particular context / scenario in which this upload is occurring.
     */
    intent: UploadTypeSelectorIntent;
    /**
     * If we're waiting on the user to select items using a previously activated
     * file input, then this will be set to the type of that input.
     */
    pendingUploadType: UploadType | undefined;
    /**
     * Called when the user selects one of the options.
     */
    onSelect: (type: UploadType) => void;
};

/**
 * Request the user to specify which type of file / folder / zip it is that they
 * wish to upload.
 *
 * This selector (and the "Upload" button) is functionally redundant, the user
 * can just drag and drop any of these into the app to directly initiate the
 * upload. But having an explicit easy to reach button is also necessary for new
 * users, or for cases where drag-and-drop might not be appropriate.
 */
const UploadTypeSelector: React.FC<UploadTypeSelectorProps> = ({
    open,
    onClose,
    intent,
    pendingUploadType,
    onSelect,
}) => {
    const publicCollectionGalleryContext = useContext(
        PublicCollectionGalleryContext,
    );

    // Directly show the file selector for the public albums app on likely
    // mobile devices.
    const directlyShowUploadFiles = useIsTouchscreen();

    useEffect(() => {
        if (
            open &&
            directlyShowUploadFiles &&
            publicCollectionGalleryContext.credentials
        ) {
            onSelect("files");
            onClose();
        }
    }, [open]);

    const handleClose: DialogProps["onClose"] = (_, reason) => {
        // Disable backdrop clicks and esc keypresses if a selection is pending
        // processing so that the user doesn't inadvertently close the dialog.
        if (
            pendingUploadType &&
            (reason == "backdropClick" || reason == "escapeKeyDown")
        ) {
            return;
        }
        onClose();
    };

    return (
        <Dialog
            open={open}
            onClose={handleClose}
            fullWidth
            slotProps={{
                paper: {
                    sx: (theme) => ({
                        maxWidth: "375px",
                        p: 1,
                        [theme.breakpoints.down(360)]: { p: 0 },
                    }),
                },
            }}
        >
            <UploadOptions
                {...{ intent, pendingUploadType, onSelect, onClose }}
            />
        </Dialog>
    );
};

type UploadOptionsProps = Pick<
    UploadTypeSelectorProps,
    "onClose" | "intent" | "pendingUploadType" | "onSelect"
>;

const UploadOptions: React.FC<UploadOptionsProps> = ({
    intent,
    pendingUploadType,
    onSelect,
    onClose,
}) => {
    // [Note: Dialog state remains preserved on reopening]
    //
    // Keep dialog content specific state here, in a separate component, so that
    // this state is not tied to the lifetime of the dialog.
    //
    // If we don't do this, then a MUI dialog retains whatever it was doing when
    // it was last closed. Sometimes that is desirable, but sometimes not, and
    // in the latter cases moving the instance specific state to a child works.

    const [showTakeoutOptions, setShowTakeoutOptions] = useState(false);

    const handleTakeoutClose = () => setShowTakeoutOptions(false);

    const handleSelect = (option: UploadType) => {
        switch (option) {
            case "files":
                onSelect("files");
                break;
            case "folders":
                onSelect("folders");
                break;
            case "zips":
                !showTakeoutOptions
                    ? setShowTakeoutOptions(true)
                    : onSelect("zips");
                break;
        }
    };

    return !showTakeoutOptions ? (
        <DefaultOptions
            {...{ intent, pendingUploadType, onClose }}
            onSelect={handleSelect}
        />
    ) : (
        <TakeoutOptions onSelect={handleSelect} onClose={handleTakeoutClose} />
    );
};

const DefaultOptions: React.FC<UploadOptionsProps> = ({
    intent,
    pendingUploadType,
    onClose,
    onSelect,
}) => {
    return (
        <>
            <SpacedRow>
                <DialogTitle variant="h5">
                    {intent == "collect"
                        ? t("select_photos")
                        : intent == "import"
                          ? t("import")
                          : t("upload")}
                </DialogTitle>
                <DialogCloseIconButton {...{ onClose }} />
            </SpacedRow>
            <Box sx={{ p: "12px", pt: "16px" }}>
                <Stack sx={{ gap: 0.5 }}>
                    {intent != "import" && (
                        <RowButton
                            startIcon={<ImageOutlinedIcon />}
                            endIcon={
                                pendingUploadType == "files" ? (
                                    <PendingIndicator />
                                ) : (
                                    <ChevronRightIcon />
                                )
                            }
                            label={t("file")}
                            onClick={() => onSelect("files")}
                        />
                    )}
                    <RowButton
                        startIcon={<PermMediaOutlinedIcon />}
                        endIcon={
                            pendingUploadType == "folders" ? (
                                <PendingIndicator />
                            ) : (
                                <ChevronRightIcon />
                            )
                        }
                        label={t("folder")}
                        onClick={() => onSelect("folders")}
                    />
                    {intent != "collect" && (
                        <RowButton
                            startIcon={<GoogleIcon />}
                            endIcon={<ChevronRightIcon />}
                            label={t("google_takeout")}
                            onClick={() => onSelect("zips")}
                        />
                    )}
                </Stack>
                <Typography
                    sx={{
                        color: "text.muted",
                        p: "12px",
                        pt: "24px",
                        textAlign: "center",
                    }}
                >
                    {t("drag_and_drop_hint")}
                </Typography>
            </Box>
        </>
    );
};

const PendingIndicator = () => (
    <CircularProgress size={18} sx={{ color: "stroke.muted" }} />
);

const TakeoutOptions: React.FC<
    Pick<UploadOptionsProps, "onSelect" | "onClose">
> = ({ onSelect, onClose }) => (
    <>
        <SpacedRow>
            <DialogTitle variant="h5">{t("google_takeout")}</DialogTitle>
            <DialogCloseIconButton {...{ onClose }} />
        </SpacedRow>
        <Stack sx={{ padding: "18px 12px 20px 12px", gap: "16px" }}>
            <Stack sx={{ gap: "8px" }}>
                <FocusVisibleButton
                    color="accent"
                    fullWidth
                    onClick={() => onSelect("folders")}
                >
                    {t("select_folder")}
                </FocusVisibleButton>
                <FocusVisibleButton
                    color="secondary"
                    fullWidth
                    onClick={() => onSelect("zips")}
                >
                    {t("select_zips")}
                </FocusVisibleButton>
                <Link
                    href="https://help.ente.io/photos/migration/from-google-photos/"
                    target="_blank"
                    rel="noopener"
                >
                    <FocusVisibleButton color="secondary" fullWidth>
                        {t("faq")}
                    </FocusVisibleButton>
                </Link>
            </Stack>
            <Typography variant="small" sx={{ color: "text.muted" }}>
                {t("takeout_hint")}
            </Typography>
        </Stack>
    </>
);
