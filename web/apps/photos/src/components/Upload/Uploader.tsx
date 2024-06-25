import { basename } from "@/next/file";
import log from "@/next/log";
import type { CollectionMapping, Electron, ZipItem } from "@/next/types/ipc";
import { firstNonEmpty } from "@/utils/array";
import { ensure } from "@/utils/ensure";
import { CustomError } from "@ente/shared/error";
import { isPromise } from "@ente/shared/utils";
import DiscFullIcon from "@mui/icons-material/DiscFull";
import UserNameInputDialog from "components/UserNameInputDialog";
import { UPLOAD_STAGES } from "constants/upload";
import { t } from "i18next";
import isElectron from "is-electron";
import { AppContext } from "pages/_app";
import { GalleryContext } from "pages/gallery";
import { useContext, useEffect, useRef, useState } from "react";
import billingService from "services/billingService";
import { getLatestCollections } from "services/collectionService";
import { exportMetadataDirectoryName } from "services/export";
import {
    getPublicCollectionUID,
    getPublicCollectionUploaderName,
    savePublicCollectionUploaderName,
} from "services/publicCollectionService";
import type { FileAndPath, UploadItem } from "services/upload/types";
import type {
    InProgressUpload,
    SegregatedFinishedUploads,
    UploadCounter,
    UploadFileNames,
    UploadItemWithCollection,
} from "services/upload/uploadManager";
import uploadManager from "services/upload/uploadManager";
import watcher from "services/watch";
import { NotificationAttributes } from "types/Notification";
import { Collection } from "types/collection";
import {
    CollectionSelectorIntent,
    SetCollectionSelectorAttributes,
    SetCollections,
    SetFiles,
    SetLoading,
} from "types/gallery";
import { getOrCreateAlbum } from "utils/collection";
import { PublicCollectionGalleryContext } from "utils/publicCollectionGallery";
import {
    getDownloadAppMessage,
    getRootLevelFileWithFolderNotAllowMessage,
} from "utils/ui";
import { SetCollectionNamerAttributes } from "../Collections/CollectionNamer";
import { CollectionMappingChoiceModal } from "./CollectionMappingChoiceModal";
import UploadProgress from "./UploadProgress";
import {
    UploadTypeSelector,
    type UploadTypeSelectorIntent,
} from "./UploadTypeSelector";

enum PICKED_UPLOAD_TYPE {
    FILES = "files",
    FOLDERS = "folders",
    ZIPS = "zips",
}

interface Props {
    syncWithRemote: (force?: boolean, silent?: boolean) => Promise<void>;
    closeCollectionSelector?: () => void;
    closeUploadTypeSelector: () => void;
    setCollectionSelectorAttributes?: SetCollectionSelectorAttributes;
    setCollectionNamerAttributes?: SetCollectionNamerAttributes;
    setLoading: SetLoading;
    setShouldDisableDropzone: (value: boolean) => void;
    showCollectionSelector?: () => void;
    setFiles: SetFiles;
    setCollections?: SetCollections;
    isFirstUpload?: boolean;
    uploadTypeSelectorView: boolean;
    showSessionExpiredMessage: () => void;
    dragAndDropFiles: File[];
    openFileSelector: () => void;
    fileSelectorFiles: File[];
    openFolderSelector: () => void;
    folderSelectorFiles: File[];
    openZipFileSelector?: () => void;
    fileSelectorZipFiles?: File[];
    uploadCollection?: Collection;
    uploadTypeSelectorIntent: UploadTypeSelectorIntent;
    activeCollection?: Collection;
}

export default function Uploader({
    isFirstUpload,
    dragAndDropFiles,
    openFileSelector,
    fileSelectorFiles,
    openFolderSelector,
    folderSelectorFiles,
    openZipFileSelector,
    fileSelectorZipFiles,
    ...props
}: Props) {
    const appContext = useContext(AppContext);
    const galleryContext = useContext(GalleryContext);
    const publicCollectionGalleryContext = useContext(
        PublicCollectionGalleryContext,
    );

    const [uploadProgressView, setUploadProgressView] = useState(false);
    const [uploadStage, setUploadStage] = useState<UPLOAD_STAGES>(
        UPLOAD_STAGES.START,
    );
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

    const [choiceModalView, setChoiceModalView] = useState(false);
    const [userNameInputDialogView, setUserNameInputDialogView] =
        useState(false);
    const [importSuggestion, setImportSuggestion] = useState<ImportSuggestion>(
        DEFAULT_IMPORT_SUGGESTION,
    );

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
    const uploadItemsAndPaths = useRef<[UploadItem, string][]>([]);

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
    const pickedUploadType = useRef<PICKED_UPLOAD_TYPE>(null);

    const currentUploadPromise = useRef<Promise<void>>(null);
    const uploadRunning = useRef(false);
    const uploaderNameRef = useRef<string>(null);
    const isDragAndDrop = useRef(false);

    const electron = globalThis.electron;

    const closeUploadProgress = () => setUploadProgressView(false);
    const showUserNameInputDialog = () => setUserNameInputDialogView(true);

    const handleChoiceModalClose = () => {
        setChoiceModalView(false);
        uploadRunning.current = false;
    };

    const handleCollectionSelectorCancel = () => {
        uploadRunning.current = false;
    };

    const handleUserNameInputDialogClose = () => {
        setUserNameInputDialogView(false);
        uploadRunning.current = false;
    };

    useEffect(() => {
        uploadManager.init(
            {
                setPercentComplete,
                setUploadCounter,
                setInProgressUploads,
                setFinishedUploads,
                setUploadStage,
                setUploadFilenames: setUploadFileNames,
                setHasLivePhotos,
                setUploadProgressView,
            },
            props.setFiles,
            publicCollectionGalleryContext,
            appContext.isCFProxyDisabled,
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
                props.syncWithRemote().catch((e) => {
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
    }, [
        publicCollectionGalleryContext.accessedThroughSharedURL,
        publicCollectionGalleryContext.token,
        publicCollectionGalleryContext.passwordToken,
        appContext.isCFProxyDisabled,
    ]);

    // Handle selected files when user selects files for upload through the open
    // file / open folder selection dialog, or drag-and-drops them.
    useEffect(() => {
        if (appContext.watchFolderView) {
            // if watch folder dialog is open don't catch the dropped file
            // as they are folder being dropped for watching
            return;
        }

        let files: File[];

        switch (pickedUploadType.current) {
            case PICKED_UPLOAD_TYPE.FILES:
                files = fileSelectorFiles;
                break;

            case PICKED_UPLOAD_TYPE.FOLDERS:
                files = folderSelectorFiles;
                break;

            case PICKED_UPLOAD_TYPE.ZIPS:
                files = fileSelectorZipFiles;
                break;

            default:
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
    }, [
        dragAndDropFiles,
        fileSelectorFiles,
        folderSelectorFiles,
        fileSelectorZipFiles,
    ]);

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
        const allItemAndPaths = [
            // Relative path (using POSIX separators) or the file's name.
            webFiles.map((f) => [f, pathLikeForWebFile(f)]),
            // The paths we get from the desktop app all eventually come either
            // from electron.selectDirectory or electron.pathForFile, both of
            // which return POSIX paths.
            desktopFiles.map((fp) => [fp, fp.path]),
            desktopFilePaths.map((p) => [p, p]),
            // The first path, that of the zip file itself, is POSIX like the
            // other paths we get over the IPC boundary. And the second path,
            // ze[1], the entry name, uses POSIX separators because that is what
            // the ZIP format uses.
            desktopZipItems.map((ze) => [ze, ze[1]]),
        ].flat() as [UploadItem, string][];

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
            // eslint-disable-next-line @typescript-eslint/no-unused-vars
            ([_, p]) => !basename(p).startsWith("."),
        );

        uploadItemsAndPaths.current = prunedItemAndPaths;
        if (uploadItemsAndPaths.current.length === 0) {
            props.setLoading(false);
            return;
        }

        const importSuggestion = getImportSuggestion(
            pickedUploadType.current,
            // eslint-disable-next-line @typescript-eslint/no-unused-vars
            prunedItemAndPaths.map(([_, p]) => p),
        );
        setImportSuggestion(importSuggestion);

        log.debug(() => "Uploader invoked:");
        log.debug(() => uploadItemsAndPaths.current);
        log.debug(() => importSuggestion);

        const _pickedUploadType = pickedUploadType.current;
        pickedUploadType.current = null;
        props.setLoading(false);

        (async () => {
            if (publicCollectionGalleryContext.accessedThroughSharedURL) {
                const uploaderName = await getPublicCollectionUploaderName(
                    getPublicCollectionUID(
                        publicCollectionGalleryContext.token,
                    ),
                );
                uploaderNameRef.current = uploaderName;
                showUserNameInputDialog();
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

            if (electron && _pickedUploadType === PICKED_UPLOAD_TYPE.ZIPS) {
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
                showNextModal = () => setChoiceModalView(true);
            } else {
                showNextModal = () =>
                    showCollectionCreateModal(importSuggestion.rootFolderName);
            }

            props.setCollectionSelectorAttributes({
                callback: uploadFilesToExistingCollection,
                onCancel: handleCollectionSelectorCancel,
                showNextModal,
                intent: CollectionSelectorIntent.upload,
            });
        })();
    }, [webFiles, desktopFiles, desktopFilePaths, desktopZipItems]);

    const preCollectionCreationAction = async () => {
        props.closeCollectionSelector?.();
        props.setShouldDisableDropzone(!uploadManager.shouldAllowNewUpload());
        setUploadStage(UPLOAD_STAGES.START);
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
            log.error("Failed to create album", e);
            appContext.setDialogMessage({
                title: t("ERROR"),
                close: { variant: "critical" },
                content: t("CREATE_ALBUM_FAILED"),
            });
            throw e;
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
        currentUploadPromise.current = waitAndRun(
            currentPromise,
            async () =>
                await uploadFiles(
                    uploadItemsWithCollection,
                    collections,
                    uploaderName,
                ),
        );
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
            if (isElectron()) {
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
        let notification: NotificationAttributes;
        switch (err) {
            case CustomError.SESSION_EXPIRED:
                return props.showSessionExpiredMessage();
            case CustomError.SUBSCRIPTION_EXPIRED:
                notification = {
                    variant: "critical",
                    subtext: t("SUBSCRIPTION_EXPIRED"),
                    message: t("RENEW_NOW"),
                    onClick: () => billingService.redirectToCustomerPortal(),
                };
                break;
            case CustomError.STORAGE_QUOTA_EXCEEDED:
                notification = {
                    variant: "critical",
                    subtext: t("STORAGE_QUOTA_EXCEEDED"),
                    message: t("UPGRADE_NOW"),
                    onClick: () => galleryContext.showPlanSelectorModal(),
                    startIcon: <DiscFullIcon />,
                };
                break;
            default:
                notification = {
                    variant: "critical",
                    message: t("UNKNOWN_ERROR"),
                    onClick: () => null,
                };
        }
        appContext.setNotificationAttributes(notification);
    }

    const uploadToSingleNewCollection = (collectionName: string) => {
        uploadFilesToNewCollections("root", collectionName);
    };

    const showCollectionCreateModal = (suggestedName: string) => {
        props.setCollectionNamerAttributes({
            title: t("CREATE_COLLECTION"),
            buttonText: t("CREATE"),
            autoFilledName: suggestedName,
            callback: uploadToSingleNewCollection,
        });
    };

    const cancelUploads = () => {
        uploadManager.cancelRunningUpload();
    };

    const handleUpload = (type: PICKED_UPLOAD_TYPE) => {
        pickedUploadType.current = type;
        if (type === PICKED_UPLOAD_TYPE.FILES) {
            openFileSelector();
        } else if (type === PICKED_UPLOAD_TYPE.FOLDERS) {
            openFolderSelector();
        } else {
            if (openZipFileSelector && electron) {
                openZipFileSelector();
            } else {
                appContext.setDialogMessage(getDownloadAppMessage());
            }
        }
    };

    const handleFileUpload = () => handleUpload(PICKED_UPLOAD_TYPE.FILES);
    const handleFolderUpload = () => handleUpload(PICKED_UPLOAD_TYPE.FOLDERS);
    const handleZipUpload = () => handleUpload(PICKED_UPLOAD_TYPE.ZIPS);

    const handlePublicUpload = async (
        uploaderName: string,
        skipSave?: boolean,
    ) => {
        try {
            if (!skipSave) {
                savePublicCollectionUploaderName(
                    getPublicCollectionUID(
                        publicCollectionGalleryContext.token,
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

    const didSelectCollectionMapping = (mapping: CollectionMapping) => {
        switch (mapping) {
            case "root":
                uploadToSingleNewCollection(
                    // rootFolderName would be empty here if one edge case:
                    // - User drags and drops a mixture of files and folders
                    // - They select the "upload to multiple albums" option
                    // - The see the error, close the error
                    // - Then they select the "upload to single album" option
                    //
                    // In such a flow, we'll reach here with an empty
                    // rootFolderName. The proper fix for this would be
                    // rearrange the flow and ask them to name the album here,
                    // but we currently don't have support for chaining modals.
                    // So in the meanwhile, keep a fallback album name at hand.
                    importSuggestion.rootFolderName ??
                        t("autogenerated_default_album_name"),
                );
                break;
            case "parent":
                if (importSuggestion.hasRootLevelFileWithFolder) {
                    appContext.setDialogMessage(
                        getRootLevelFileWithFolderNotAllowMessage(),
                    );
                } else {
                    uploadFilesToNewCollections("parent");
                }
        }
    };

    return (
        <>
            <CollectionMappingChoiceModal
                open={choiceModalView}
                onClose={handleChoiceModalClose}
                didSelect={didSelectCollectionMapping}
            />
            <UploadTypeSelector
                open={props.uploadTypeSelectorView}
                onClose={props.closeUploadTypeSelector}
                intent={props.uploadTypeSelectorIntent}
                uploadFiles={handleFileUpload}
                uploadFolders={handleFolderUpload}
                uploadGoogleTakeoutZips={handleZipUpload}
            />
            <UploadProgress
                open={uploadProgressView}
                onClose={closeUploadProgress}
                percentComplete={percentComplete}
                uploadFileNames={uploadFileNames}
                uploadCounter={uploadCounter}
                uploadStage={uploadStage}
                inProgressUploads={inProgressUploads}
                hasLivePhotos={hasLivePhotos}
                retryFailed={retryFailed}
                finishedUploads={finishedUploads}
                cancelUploads={cancelUploads}
            />
            <UserNameInputDialog
                open={userNameInputDialogView}
                onClose={handleUserNameInputDialogClose}
                onNameSubmit={handlePublicUpload}
                toUploadFilesCount={uploadItemsAndPaths.current?.length}
                uploaderName={uploaderNameRef.current}
            />
        </>
    );
}

async function waitAndRun(
    waitPromise: Promise<void>,
    task: () => Promise<void>,
) {
    if (waitPromise && isPromise(waitPromise)) {
        await waitPromise;
    }
    await task();
}

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
    ensure(
        firstNonEmpty([
            // We need to check first, since path is not a property of
            // the standard File objects.
            "path" in file && typeof file.path == "string"
                ? file.path
                : undefined,
            file.webkitRelativePath,
            file.name,
        ]),
    );

// This is used to prompt the user the make upload strategy choice
interface ImportSuggestion {
    rootFolderName: string;
    hasNestedFolders: boolean;
    hasRootLevelFileWithFolder: boolean;
}

const DEFAULT_IMPORT_SUGGESTION: ImportSuggestion = {
    rootFolderName: "",
    hasNestedFolders: false,
    hasRootLevelFileWithFolder: false,
};

function getImportSuggestion(
    uploadType: PICKED_UPLOAD_TYPE,
    paths: string[],
): ImportSuggestion {
    if (isElectron() && uploadType === PICKED_UPLOAD_TYPE.FILES) {
        return DEFAULT_IMPORT_SUGGESTION;
    }

    const getCharCount = (str: string) => (str.match(/\//g) ?? []).length;
    paths.sort((path1, path2) => getCharCount(path1) - getCharCount(path2));
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
        hasRootLevelFileWithFolder: firstFileFolder === "",
    };
}

// This function groups files that are that have the same parent folder into collections
// For Example, for user files have a directory structure like this
//              a
//            / |  \
//           b  j   c
//          /|\    /  \
//         e f g   h  i
//
// The files will grouped into 3 collections.
// [a => [j],
// b => [e,f,g],
// c => [h, i]]
const groupFilesBasedOnParentFolder = (
    uploadItemsAndPaths: [UploadItem, string][],
) => {
    const result = new Map<string, UploadItem[]>();
    for (const [uploadItem, pathOrName] of uploadItemsAndPaths) {
        let folderPath = pathOrName.substring(0, pathOrName.lastIndexOf("/"));
        // If the parent folder of a file is "metadata"
        // we consider it to be part of the parent folder
        // For Eg,For FileList  -> [a/x.png, a/metadata/x.png.json]
        // they will both we grouped into the collection "a"
        // This is cluster the metadata json files in the same collection as the file it is for
        if (folderPath.endsWith(exportMetadataDirectoryName)) {
            folderPath = folderPath.substring(0, folderPath.lastIndexOf("/"));
        }
        const folderName = folderPath.substring(
            folderPath.lastIndexOf("/") + 1,
        );
        if (!folderName) throw Error("Unexpected empty folder name");
        if (!result.has(folderName)) result.set(folderName, []);
        result.get(folderName).push(uploadItem);
    }
    return result;
};

export const setPendingUploads = async (
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
