// TODO: Audit this file
// TODO: Too many null assertions in this file. The types need reworking.
/* eslint-disable react-hooks/exhaustive-deps */
/* eslint-disable @typescript-eslint/no-misused-promises */
/* eslint-disable @typescript-eslint/no-floating-promises */
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
import type { LocalUser } from "ente-accounts/services/user";
import { isDesktop } from "ente-base/app";
import { SpacedRow } from "ente-base/components/containers";
import { DialogCloseIconButton } from "ente-base/components/mui/DialogCloseIconButton";
import { FocusVisibleButton } from "ente-base/components/mui/FocusVisibleButton";
import { RowButton } from "ente-base/components/RowButton";
import { SingleInputDialog } from "ente-base/components/SingleInputDialog";
import { useIsTouchscreen } from "ente-base/components/utils/hooks";
import {
    useModalVisibility,
    type ModalVisibilityProps,
} from "ente-base/components/utils/modal";
import { useBaseContext } from "ente-base/context";
import { basename, dirname, joinPath } from "ente-base/file-name";
import type { PublicAlbumsCredentials } from "ente-base/http";
import log from "ente-base/log";
import type { CollectionMapping, Electron, ZipItem } from "ente-base/types/ipc";
import { type UploadTypeSelectorIntent } from "ente-gallery/components/Upload";
import { useFileInput } from "ente-gallery/components/utils/use-file-input";
import {
    groupItemsBasedOnParentFolder,
    uploadPathPrefix,
    type FileAndPath,
    type UploadItem,
    type UploadItemAndPath,
    type UploadPhase,
} from "ente-gallery/services/upload";
import type { ParsedMetadataJSON } from "ente-gallery/services/upload/metadata-json";
import {
    sessionExpiredErrorMessage,
    storageLimitExceededErrorMessage,
    subscriptionExpiredErrorMessage,
} from "ente-gallery/services/upload/upload-service";
import { CollectionSubType, type Collection } from "ente-media/collection";
import type { EnteFile } from "ente-media/file";
import { UploaderNameInput } from "ente-new/albums/components/UploaderNameInput";
import {
    savedPublicCollectionUploaderName,
    savePublicCollectionUploaderName,
} from "ente-new/albums/services/public-albums-fdb";
import { CollectionMappingChoice } from "ente-new/photos/components/CollectionMappingChoice";
import type { CollectionSelectorAttributes } from "ente-new/photos/components/CollectionSelector";
import type { RemotePullOpts } from "ente-new/photos/components/gallery";
import { downloadAppDialogAttributes } from "ente-new/photos/components/utils/download";
import {
    createAlbum,
    isHiddenCollection,
    savedNormalCollections,
} from "ente-new/photos/services/collection";
import { redirectToCustomerPortal } from "ente-new/photos/services/user-details";
import { usePhotosAppContext } from "ente-new/photos/types/context";
import { firstNonEmpty } from "ente-utils/array";
import { t } from "i18next";
import React, { useCallback, useEffect, useRef, useState } from "react";
import type {
    InProgressUpload,
    SegregatedFinishedUploads,
    UploadCounter,
    UploadFileNames,
    UploadItemWithCollection,
} from "services/upload-manager";
import { uploadManager } from "services/upload-manager";
import watcher from "services/watch";
import { UploadProgress } from "./UploadProgress";

interface UploadProps {
    /**
     * The logged in user, if any.
     *
     * This is only expected to be present when we're running it the context of
     * the photos app, where there is a logged in user. When used by the public
     * albums app, this prop can be omitted.
     */
    user?: LocalUser;
    /**
     * The {@link PublicAlbumsCredentials} to use, if any.
     *
     * These are expected to be set if we are in the context of the public
     * albums app, and should be undefined when we're in the photos app context.
     */
    publicAlbumsCredentials?: PublicAlbumsCredentials;
    isFirstUpload?: boolean;
    uploadTypeSelectorView: boolean;
    dragAndDropFiles: File[];
    uploadCollection?: Collection;
    uploadTypeSelectorIntent: UploadTypeSelectorIntent;
    activeCollection?: Collection;
    closeUploadTypeSelector: () => void;
    setLoading: (loading: boolean) => void;
    setShouldDisableDropzone: (value: boolean) => void;
    showCollectionSelector?: () => void;
    /**
     * Called when the uploader (or the file watcher) wants to perform a full
     * remote pull.
     *
     * See also {@link onRemoteFilesPull}.
     */
    onRemotePull: (opts?: RemotePullOpts) => Promise<void>;
    /**
     * Called when an action in the uploader requires us to first pull the
     * latest files and collections from remote.
     *
     * See: [Note: Full remote pull vs files pull]
     *
     * Specifically, this is used prior to creating a new album, to obtain
     * (potential) existing albums from remote so that they can be matched by
     * name if needed.
     *
     * This functionality is not needed during uploads to a public album, so
     * this property is optional; the public albums code need not provide it.
     */
    onRemoteFilesPull?: () => Promise<void>;
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
    /**
     * Called when the upload failed because the user's session has expired, and
     * the Upload component wants to prompt the user to log in again.
     */
    onShowSessionExpiredDialog: () => void;
}

type UploadType = "files" | "folders" | "zips";

/**
 * Top level component that houses the infrastructure for handling uploads.
 */
export const Upload: React.FC<UploadProps> = ({
    user,
    publicAlbumsCredentials,
    isFirstUpload,
    dragAndDropFiles,
    onRemotePull,
    onRemoteFilesPull,
    onOpenCollectionSelector,
    onCloseCollectionSelector,
    onUploadFile,
    onShowPlanSelector,
    onShowSessionExpiredDialog,
    ...props
}) => {
    const { showMiniDialog, onGenericError } = useBaseContext();
    const { showNotification, watchFolderView } = usePhotosAppContext();

    const [uploadProgressView, setUploadProgressView] = useState(false);
    const [uploadPhase, setUploadPhase] = useState<UploadPhase>("preparing");
    const [uploadFileNames, setUploadFileNames] = useState<UploadFileNames>();
    const [uploadCounter, setUploadCounter] = useState<UploadCounter>({
        finished: 0,
        total: 0,
    });
    const [inProgressUploads, setInProgressUploads] = useState(
        new Array<InProgressUpload>(),
    );
    const [finishedUploads, setFinishedUploads] =
        useState<SegregatedFinishedUploads>(new Map());
    const [percentComplete, setPercentComplete] = useState(0);
    const [hasLivePhotos, setHasLivePhotos] = useState(false);
    const [prefilledNewAlbumName, setPrefilledNewAlbumName] = useState("");
    const [uploaderName, setUploaderName] = useState("");

    const [openCollectionMappingChoice, setOpenCollectionMappingChoice] =
        useState(false);
    const [importSuggestion, setImportSuggestion] = useState<ImportSuggestion>(
        defaultImportSuggestion,
    );
    const {
        show: showNewAlbumNameInput,
        props: newAlbumNameInputVisibilityProps,
    } = useModalVisibility();
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
    const pendingDesktopUploadCollectionName = useRef<string | undefined>(
        undefined,
    );

    /**
     * This is set to thue user's choice when the user chooses one of the
     * predefined type to upload from the upload type selector dialog
     */
    const selectedUploadType = useRef<UploadType | undefined>(undefined);

    const currentUploadPromise = useRef<Promise<void> | undefined>(undefined);
    const uploadRunning = useRef(false);
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
                // eslint-disable-next-line @typescript-eslint/ban-ts-comment
                // @ts-ignore
                setUploadFilenames: setUploadFileNames,
                setHasLivePhotos,
                setUploadProgressView,
            },
            onUploadFile,
            publicAlbumsCredentials,
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

            watcher.init(upload, () => void onRemotePull());

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
    }, [publicAlbumsCredentials]);

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

        // Filter out files whose names begins with a ".".
        const prunedItemAndPaths = allItemAndPaths.filter(
            ([, p]) => !basename(p).startsWith("."),
        );

        uploadItemsAndPaths.current = prunedItemAndPaths;
        if (uploadItemsAndPaths.current.length == 0) {
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
        selectedUploadType.current = undefined;
        props.setLoading(false);

        (async () => {
            if (publicAlbumsCredentials) {
                setUploaderName(
                    (await savedPublicCollectionUploaderName(
                        publicAlbumsCredentials.accessToken,
                    )) ?? "",
                );
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
                    pendingDesktopUploadCollectionName.current = undefined;
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
                    props.activeCollection.owner.id == user?.id
                ) {
                    uploadFilesToExistingCollection(props.activeCollection);
                    return;
                }
            }

            // eslint-disable-next-line @typescript-eslint/no-empty-function
            let showNextModal = () => {};
            if (importSuggestion.hasNestedFolders) {
                showNextModal = () => setOpenCollectionMappingChoice(true);
            } else {
                showNextModal = () => {
                    setPrefilledNewAlbumName(importSuggestion.rootFolderName);
                    showNewAlbumNameInput();
                };
            }

            onOpenCollectionSelector?.({
                action: "upload",
                onSelectCollection: uploadFilesToExistingCollection,
                onCreateCollection: showNextModal,
                onCancel: handleCollectionSelectorCancel,
            });
        })();
    }, [
        publicAlbumsCredentials,
        webFiles,
        desktopFiles,
        desktopFilePaths,
        desktopZipItems,
    ]);

    const preCollectionCreationAction = () => {
        onCloseCollectionSelector?.();
        props.setShouldDisableDropzone(uploadManager.isUploadInProgress());
        setUploadPhase("preparing");
        setUploadProgressView(true);
    };

    const uploadFilesToExistingCollection = async (
        collection: Collection,
        uploaderName?: string,
    ) => {
        preCollectionCreationAction();
        const uploadItemsWithCollection = uploadItemsAndPaths.current.map(
            ([uploadItem, path], index) => ({
                uploadItem,
                pathPrefix: uploadPathPrefix(path),
                localID: index,
                collectionID: collection.id,
            }),
        );
        await waitInQueueAndUploadFiles(
            uploadItemsWithCollection,
            [collection],
            uploaderName,
        );
        uploadItemsAndPaths.current = [];
    };

    const uploadFilesToNewCollections = async (
        mapping: CollectionMapping,
        collectionName?: string,
    ) => {
        preCollectionCreationAction();
        let uploadItemsWithCollection: UploadItemWithCollection[] = [];
        let collectionNameToUploadItems = new Map<
            string,
            UploadItemAndPath[]
        >();
        if (mapping == "root") {
            collectionNameToUploadItems.set(
                // Un-enforced convention is that collectionName is always set
                // when mapping is "root". TODO: Reflect this in types.
                collectionName!,
                uploadItemsAndPaths.current,
            );
        } else {
            collectionNameToUploadItems = groupItemsBasedOnParentFolder(
                uploadItemsAndPaths.current,
                collectionName,
            );
        }
        const collections: Collection[] = [];
        try {
            await onRemoteFilesPull!();
            const existingCollections = await savedNormalCollections();
            let index = 0;
            for (const [
                collectionName,
                uploadItems,
            ] of collectionNameToUploadItems) {
                const collection = await matchExistingOrCreateAlbum(
                    collectionName,
                    user!,
                    existingCollections,
                );
                collections.push(collection);
                uploadItemsWithCollection = [
                    ...uploadItemsWithCollection,
                    ...uploadItems.map(([uploadItem, path]) => ({
                        localID: index++,
                        pathPrefix: uploadPathPrefix(path),
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
        uploadItemsAndPaths.current = [];
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

    const preUploadAction = async (
        parsedMetadataJSONMap?: Map<string, ParsedMetadataJSON>,
    ) => {
        uploadManager.prepareForNewUpload(parsedMetadataJSONMap);
        setUploadProgressView(true);
        await onRemotePull({ silent: true });
    };

    function postUploadAction() {
        props.setShouldDisableDropzone(false);
        uploadRunning.current = false;
        void onRemotePull();
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
                        .filter((x) => x !== undefined),
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
                    await watcher.allFileUploadsDone(uploadItemsWithCollection);
                } else if (watcher.isSyncPaused()) {
                    // Resume folder watch after the user upload that
                    // interrupted it is done.
                    watcher.resumePausedSync();
                }
            }
        } catch (e) {
            log.error("Failed to upload files", e);
            closeUploadProgress();
            notifyUser(e);
        } finally {
            postUploadAction();
        }
    };

    const retryFailed = async () => {
        try {
            log.info("Retrying failed uploads");
            const { items, collections, parsedMetadataJSONMap } =
                uploadManager.failedItemState();
            const uploaderName = uploadManager.getUploaderName();
            await preUploadAction(parsedMetadataJSONMap);
            await uploadManager.uploadItems(items, collections, uploaderName);
        } catch (e) {
            log.error("Retrying failed uploads failed", e);
            closeUploadProgress();
            notifyUser(e);
        } finally {
            postUploadAction();
        }
    };

    const notifyUser = (e: unknown) => {
        switch (e instanceof Error && e.message) {
            case sessionExpiredErrorMessage:
                onShowSessionExpiredDialog();
                break;
            case subscriptionExpiredErrorMessage:
                showNotification({
                    color: "critical",
                    captionFirst: true,
                    caption: t("subscription_expired"),
                    title: t("renew_now"),
                    onClick: redirectToCustomerPortal,
                });
                break;
            case storageLimitExceededErrorMessage:
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
    };

    const uploadToSingleNewCollection = (collectionName: string) => {
        uploadFilesToNewCollections("root", collectionName);
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

    const handlePublicUpload = (uploaderName: string) => {
        savePublicCollectionUploaderName(
            publicAlbumsCredentials!.accessToken,
            uploaderName,
        );

        // Do not keep the uploader name input dialog open while the upload is
        // progressing (the upload progress indicator will take out now).
        void uploadFilesToExistingCollection(
            props.uploadCollection!,
            uploaderName,
        );
    };

    const handleCollectionMappingSelect = (mapping: CollectionMapping) =>
        uploadFilesToNewCollections(
            mapping,
            importSuggestion.rootFolderName ||
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
                publicAlbumsCredentials={publicAlbumsCredentials}
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
                uploadFileNames={uploadFileNames!}
                uploadCounter={uploadCounter}
                uploadPhase={uploadPhase}
                inProgressUploads={inProgressUploads}
                hasLivePhotos={hasLivePhotos}
                retryFailed={retryFailed}
                finishedUploads={finishedUploads}
                cancelUploads={cancelUploads}
            />
            <SingleInputDialog
                {...newAlbumNameInputVisibilityProps}
                title={t("new_album")}
                label={t("album_name")}
                initialValue={prefilledNewAlbumName}
                submitButtonTitle={t("create")}
                onSubmit={uploadToSingleNewCollection}
            />
            <UploaderNameInput
                open={uploaderNameInputVisibilityProps.open}
                onClose={handleUploaderNameInputClose}
                uploaderName={uploaderName}
                uploadFileCount={uploadItemsAndPaths.current.length}
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
    uploadType: UploadType | undefined,
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
    const firstPath = paths[0]!;
    const lastPath = paths[paths.length - 1]!;

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
        rootFolderName: commonPathPrefix || "",
        hasNestedFolders: firstFileFolder !== lastFileFolder,
    };
};

const matchExistingOrCreateAlbum = async (
    albumName: string,
    user: LocalUser,
    existingCollections: Collection[],
) => {
    for (const collection of existingCollections) {
        if (
            // Name matches
            collection.name == albumName &&
            // Valid types
            (collection.type == "album" ||
                collection.type == "folder" ||
                collection.type == "uncategorized") &&
            // Not hidden
            !isHiddenCollection(collection) &&
            // Not a quicklink
            collection.magicMetadata?.data.subType !=
                CollectionSubType.quicklink &&
            // Owned by user
            collection.owner.id == user.id
        ) {
            log.info(
                `Found existing album ${albumName} with id ${collection.id}`,
            );
            return collection;
        }
    }

    const collection = await createAlbum(albumName);
    log.info(`Created new album ${albumName} with id ${collection.id}`);
    return collection;
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
        collectionName = collections[0]!.name;
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
} & Pick<UploadProps, "publicAlbumsCredentials">;

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
    publicAlbumsCredentials,
    intent,
    pendingUploadType,
    onSelect,
}) => {
    // Directly show the file selector for the public albums app on likely
    // mobile devices.
    const directlyShowUploadFiles = useIsTouchscreen();

    useEffect(() => {
        if (open && directlyShowUploadFiles && publicAlbumsCredentials) {
            onSelect("files");
            onClose();
        }
    }, [open, publicAlbumsCredentials]);

    const handleClose: DialogProps["onClose"] = () => {
        // Disable backdrop clicks and esc keypresses if a selection is pending
        // processing so that the user doesn't inadvertently close the dialog.
        if (pendingUploadType) return;
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
                if (!showTakeoutOptions) {
                    setShowTakeoutOptions(true);
                } else {
                    onSelect("zips");
                }
                break;
        }
    };

    return showTakeoutOptions ? (
        <TakeoutOptions onSelect={handleSelect} onClose={handleTakeoutClose} />
    ) : (
        <DefaultOptions
            {...{ intent, pendingUploadType, onClose }}
            onSelect={handleSelect}
        />
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
