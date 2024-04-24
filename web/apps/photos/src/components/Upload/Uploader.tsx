import { ensureElectron } from "@/next/electron";
import log from "@/next/log";
import { ElectronFile } from "@/next/types/file";
import type { CollectionMapping, Electron } from "@/next/types/ipc";
import { CustomError } from "@ente/shared/error";
import { isPromise } from "@ente/shared/utils";
import DiscFullIcon from "@mui/icons-material/DiscFull";
import UserNameInputDialog from "components/UserNameInputDialog";
import { PICKED_UPLOAD_TYPE, UPLOAD_STAGES } from "constants/upload";
import { t } from "i18next";
import isElectron from "is-electron";
import { AppContext } from "pages/_app";
import { GalleryContext } from "pages/gallery";
import { useContext, useEffect, useRef, useState } from "react";
import billingService from "services/billingService";
import { getLatestCollections } from "services/collectionService";
import {
    getPublicCollectionUID,
    getPublicCollectionUploaderName,
    savePublicCollectionUploaderName,
} from "services/publicCollectionService";
import uploadManager, {
    setToUploadCollection,
} from "services/upload/uploadManager";
import watcher from "services/watch";
import { NotificationAttributes } from "types/Notification";
import { Collection } from "types/collection";
import {
    CollectionSelectorIntent,
    SetCollectionSelectorAttributes,
    SetCollections,
    SetFiles,
    SetLoading,
    UploadTypeSelectorIntent,
} from "types/gallery";
import { FileWithCollection, type FileWithCollection2 } from "types/upload";
import {
    InProgressUpload,
    SegregatedFinishedUploads,
    UploadCounter,
    UploadFileNames,
} from "types/upload/ui";
import { getOrCreateAlbum } from "utils/collection";
import { PublicCollectionGalleryContext } from "utils/publicCollectionGallery";
import {
    getDownloadAppMessage,
    getRootLevelFileWithFolderNotAllowMessage,
} from "utils/ui";
import {
    DEFAULT_IMPORT_SUGGESTION,
    filterOutSystemFiles,
    getImportSuggestion,
    groupFilesBasedOnParentFolder,
    type ImportSuggestion,
} from "utils/upload";
import { SetCollectionNamerAttributes } from "../Collections/CollectionNamer";
import { CollectionMappingChoiceModal } from "./CollectionMappingChoiceModal";
import UploadProgress from "./UploadProgress";
import UploadTypeSelector from "./UploadTypeSelector";

const FIRST_ALBUM_NAME = "My First Album";

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
    showUploadFilesDialog: () => void;
    showUploadDirsDialog: () => void;
    webFolderSelectorFiles: File[];
    webFileSelectorFiles: File[];
    dragAndDropFiles: File[];
    uploadCollection?: Collection;
    uploadTypeSelectorIntent: UploadTypeSelectorIntent;
    activeCollection?: Collection;
}

export default function Uploader(props: Props) {
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
     * Paths of file to upload that we've received over the IPC bridge from the
     * code running in the Node.js layer of our desktop app.
     */
    const [desktopFilePaths, setDesktopFilePaths] = useState<
        string[] | undefined
    >();
    const [electronFiles, setElectronFiles] = useState<ElectronFile[]>(null);
    const [webFiles, setWebFiles] = useState([]);

    const toUploadFiles = useRef<
        File[] | ElectronFile[] | string[] | undefined | null
    >(null);
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
    // This is set when the user choses a type to upload from the upload type selector dialog
    const pickedUploadType = useRef<PICKED_UPLOAD_TYPE>(null);
    const zipPaths = useRef<string[]>(null);
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
        appContext.resetSharedFiles();
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

        if (isElectron()) {
            ensureElectron()
                .pendingUploads()
                .then((pending) => {
                    if (pending) {
                        log.info("Resuming pending desktop upload", pending);
                        resumeDesktopUpload(
                            pending.type == "files"
                                ? PICKED_UPLOAD_TYPE.FILES
                                : PICKED_UPLOAD_TYPE.ZIPS,
                            pending.files,
                            pending.collectionName,
                        );
                    }
                });

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
        }
    }, [
        publicCollectionGalleryContext.accessedThroughSharedURL,
        publicCollectionGalleryContext.token,
        publicCollectionGalleryContext.passwordToken,
        appContext.isCFProxyDisabled,
    ]);

    // this handles the change of selectorFiles changes on web when user selects
    // files for upload through the opened file/folder selector or dragAndDrop them
    //  the webFiles state is update which triggers the upload of those files
    useEffect(() => {
        if (appContext.watchFolderView) {
            // if watch folder dialog is open don't catch the dropped file
            // as they are folder being dropped for watching
            return;
        }
        if (
            pickedUploadType.current === PICKED_UPLOAD_TYPE.FOLDERS &&
            props.webFolderSelectorFiles?.length > 0
        ) {
            log.info(`received folder upload request`);
            setWebFiles(props.webFolderSelectorFiles);
        } else if (
            pickedUploadType.current === PICKED_UPLOAD_TYPE.FILES &&
            props.webFileSelectorFiles?.length > 0
        ) {
            log.info(`received file upload request`);
            setWebFiles(props.webFileSelectorFiles);
        } else if (props.dragAndDropFiles?.length > 0) {
            isDragAndDrop.current = true;
            if (electron) {
                const main = async () => {
                    try {
                        log.info(`uploading dropped files from desktop app`);
                        // check and parse dropped files which are zip files
                        let electronFiles = [] as ElectronFile[];
                        for (const file of props.dragAndDropFiles) {
                            if (file.name.endsWith(".zip")) {
                                const zipFiles =
                                    await electron.getElectronFilesFromGoogleZip(
                                        (file as any).path,
                                    );
                                log.info(
                                    `zip file - ${file.name} contains ${zipFiles.length} files`,
                                );
                                electronFiles = [...electronFiles, ...zipFiles];
                            } else {
                                // type cast to ElectronFile as the file is dropped from desktop app
                                // type file and ElectronFile should be interchangeable, but currently they have some differences.
                                // Typescript is giving error
                                // Conversion of type 'File' to type 'ElectronFile' may be a mistake because neither type sufficiently
                                // overlaps with the other. If this was intentional, convert the expression to 'unknown' first.
                                // Type 'File' is missing the following properties from type 'ElectronFile': path, blob
                                // for now patching by type casting first to unknown and then to ElectronFile
                                // TODO: fix types and remove type cast
                                electronFiles.push(
                                    file as unknown as ElectronFile,
                                );
                            }
                        }
                        log.info(
                            `uploading dropped files from desktop app - ${electronFiles.length} files found`,
                        );
                        setElectronFiles(electronFiles);
                    } catch (e) {
                        log.error("failed to upload desktop dropped files", e);
                        setWebFiles(props.dragAndDropFiles);
                    }
                };
                main();
            } else {
                log.info(`uploading dropped files from web app`);
                setWebFiles(props.dragAndDropFiles);
            }
        }
    }, [
        props.dragAndDropFiles,
        props.webFileSelectorFiles,
        props.webFolderSelectorFiles,
    ]);

    useEffect(() => {
        if (
            desktopFilePaths?.length > 0 ||
            electronFiles?.length > 0 ||
            webFiles?.length > 0 ||
            appContext.sharedFiles?.length > 0
        ) {
            log.info(
                `upload request type: ${
                    desktopFilePaths?.length > 0
                        ? "desktopFilePaths"
                        : electronFiles?.length > 0
                          ? "electronFiles"
                          : webFiles?.length > 0
                            ? "webFiles"
                            : "sharedFiles"
                } count ${
                    desktopFilePaths?.length ??
                    electronFiles?.length ??
                    webFiles?.length ??
                    appContext?.sharedFiles.length
                }`,
            );
            if (uploadManager.isUploadRunning()) {
                if (watcher.isUploadRunning()) {
                    // Pause watch folder sync on user upload
                    log.info(
                        "Folder watcher was uploading, pausing it to first run user upload",
                    );
                    watcher.pauseRunningSync();
                } else {
                    log.info(
                        "Ignoring new upload request because an upload is already running",
                    );
                    return;
                }
            }
            uploadRunning.current = true;
            props.closeUploadTypeSelector();
            props.setLoading(true);
            if (webFiles?.length > 0) {
                // File selection by drag and drop or selection of file.
                toUploadFiles.current = webFiles;
                setWebFiles([]);
            } else if (appContext.sharedFiles?.length > 0) {
                toUploadFiles.current = appContext.sharedFiles;
                appContext.resetSharedFiles();
            } else if (electronFiles?.length > 0) {
                // File selection from desktop app - deprecated
                toUploadFiles.current = electronFiles;
                setElectronFiles([]);
            } else if (desktopFilePaths && desktopFilePaths.length > 0) {
                // File selection from our desktop app
                toUploadFiles.current = desktopFilePaths;
                setDesktopFilePaths(undefined);
            }

            toUploadFiles.current = filterOutSystemFiles(toUploadFiles.current);
            if (toUploadFiles.current.length === 0) {
                props.setLoading(false);
                return;
            }

            const importSuggestion = getImportSuggestion(
                pickedUploadType.current,
                toUploadFiles.current.map((file) =>
                    typeof file == "string" ? file : file["path"],
                ),
            );
            setImportSuggestion(importSuggestion);

            handleCollectionCreationAndUpload(
                importSuggestion,
                props.isFirstUpload,
                pickedUploadType.current,
                publicCollectionGalleryContext.accessedThroughSharedURL,
            );
            pickedUploadType.current = null;
            props.setLoading(false);
        }
    }, [webFiles, appContext.sharedFiles, electronFiles, desktopFilePaths]);

    const resumeDesktopUpload = async (
        type: PICKED_UPLOAD_TYPE,
        electronFiles: ElectronFile[],
        collectionName: string,
    ) => {
        if (electronFiles && electronFiles?.length > 0) {
            isPendingDesktopUpload.current = true;
            pendingDesktopUploadCollectionName.current = collectionName;
            pickedUploadType.current = type;
            setElectronFiles(electronFiles);
        }
    };

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
        try {
            log.info(
                `upload file to an existing collection name:${collection.name}, collectionID:${collection.id}`,
            );
            await preCollectionCreationAction();
            const filesWithCollectionToUpload: FileWithCollection[] =
                toUploadFiles.current.map((file, index) => ({
                    file,
                    localID: index,
                    collectionID: collection.id,
                }));
            await waitInQueueAndUploadFiles(
                filesWithCollectionToUpload,
                [collection],
                uploaderName,
            );
        } catch (e) {
            log.error("Failed to upload files to existing collections", e);
        }
    };

    const uploadFilesToNewCollections = async (
        strategy: CollectionMapping,
        collectionName?: string,
    ) => {
        try {
            log.info(
                `upload file to an new collections strategy:${strategy} ,collectionName:${collectionName}`,
            );
            await preCollectionCreationAction();
            let filesWithCollectionToUpload: FileWithCollection2[] = [];
            const collections: Collection[] = [];
            let collectionNameToFilesMap = new Map<
                string,
                File[] | ElectronFile[] | string[]
            >();
            if (strategy == "root") {
                collectionNameToFilesMap.set(
                    collectionName,
                    toUploadFiles.current,
                );
            } else {
                collectionNameToFilesMap = groupFilesBasedOnParentFolder(
                    toUploadFiles.current,
                );
            }
            log.info(
                `upload collections - [${[...collectionNameToFilesMap.keys()]}]`,
            );
            try {
                const existingCollection = await getLatestCollections();
                let index = 0;
                for (const [
                    collectionName,
                    files,
                ] of collectionNameToFilesMap) {
                    const collection = await getOrCreateAlbum(
                        collectionName,
                        existingCollection,
                    );
                    collections.push(collection);
                    props.setCollections([
                        ...existingCollection,
                        ...collections,
                    ]);
                    filesWithCollectionToUpload = [
                        ...filesWithCollectionToUpload,
                        ...files.map((file) => ({
                            localID: index++,
                            collectionID: collection.id,
                            file,
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
            await waitInQueueAndUploadFiles(
                /* TODO(MR): ElectronFile changes */
                filesWithCollectionToUpload as FileWithCollection[],
                collections,
            );
            toUploadFiles.current = null;
        } catch (e) {
            log.error("Failed to upload files to new collections", e);
        }
    };

    const waitInQueueAndUploadFiles = async (
        filesWithCollectionToUploadIn: FileWithCollection[],
        collections: Collection[],
        uploaderName?: string,
    ) => {
        const currentPromise = currentUploadPromise.current;
        currentUploadPromise.current = waitAndRun(
            currentPromise,
            async () =>
                await uploadFiles(
                    filesWithCollectionToUploadIn,
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
        filesWithCollectionToUploadIn: FileWithCollection[],
        collections: Collection[],
        uploaderName?: string,
    ) => {
        try {
            log.info("uploadFiles called");
            preUploadAction();
            if (
                electron &&
                !isPendingDesktopUpload.current &&
                !watcher.isUploadRunning()
            ) {
                await setToUploadCollection(collections);
                if (zipPaths.current) {
                    await electron.setPendingUploadFiles(
                        "zips",
                        zipPaths.current,
                    );
                    zipPaths.current = null;
                }
                await electron.setPendingUploadFiles(
                    "files",
                    filesWithCollectionToUploadIn.map(
                        ({ file }) => (file as ElectronFile).path,
                    ),
                );
            }
            const shouldCloseUploadProgress =
                await uploadManager.queueFilesForUpload(
                    filesWithCollectionToUploadIn,
                    collections,
                    uploaderName,
                );
            if (shouldCloseUploadProgress) {
                closeUploadProgress();
            }
            if (isElectron()) {
                if (watcher.isUploadRunning()) {
                    await watcher.allFileUploadsDone(
                        /* TODO(MR): ElectronFile changes */
                        filesWithCollectionToUploadIn as FileWithCollection2[],
                        collections,
                    );
                } else if (watcher.isSyncPaused()) {
                    // resume the service after user upload is done
                    watcher.resumePausedSync();
                }
            }
        } catch (e) {
            log.error("failed to upload files", e);
            showUserFacingError(e.message);
            closeUploadProgress();
        } finally {
            postUploadAction();
        }
    };

    const retryFailed = async () => {
        try {
            log.info("user retrying failed  upload");
            const filesWithCollections =
                uploadManager.getFailedFilesWithCollections();
            const uploaderName = uploadManager.getUploaderName();
            await preUploadAction();
            await uploadManager.queueFilesForUpload(
                /* TODO(MR): ElectronFile changes */
                filesWithCollections.files as FileWithCollection[],
                filesWithCollections.collections,
                uploaderName,
            );
        } catch (e) {
            log.error("retry failed files failed", e);
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

    const handleCollectionCreationAndUpload = async (
        importSuggestion: ImportSuggestion,
        isFirstUpload: boolean,
        pickedUploadType: PICKED_UPLOAD_TYPE,
        accessedThroughSharedURL?: boolean,
    ) => {
        try {
            if (accessedThroughSharedURL) {
                log.info(
                    `uploading files to public collection - ${props.uploadCollection.name}  - ${props.uploadCollection.id}`,
                );
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
                    log.info(
                        `upload pending files to collection - ${pendingDesktopUploadCollectionName.current}`,
                    );
                    uploadFilesToNewCollections(
                        "root",
                        pendingDesktopUploadCollectionName.current,
                    );
                    pendingDesktopUploadCollectionName.current = null;
                } else {
                    log.info(
                        `pending upload - strategy - "multiple collections" `,
                    );
                    uploadFilesToNewCollections("parent");
                }
                return;
            }
            if (isElectron() && pickedUploadType === PICKED_UPLOAD_TYPE.ZIPS) {
                log.info("uploading zip files");
                uploadFilesToNewCollections("parent");
                return;
            }
            if (isFirstUpload && !importSuggestion.rootFolderName) {
                importSuggestion.rootFolderName = FIRST_ALBUM_NAME;
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
                log.info(`nested folders detected`);
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
        } catch (e) {
            log.error("handleCollectionCreationAndUpload failed", e);
        }
    };

    const handleDesktopUpload = async (
        type: PICKED_UPLOAD_TYPE,
        electron: Electron,
    ) => {
        let files: ElectronFile[];
        pickedUploadType.current = type;
        if (type === PICKED_UPLOAD_TYPE.FILES) {
            files = await electron.showUploadFilesDialog();
        } else if (type === PICKED_UPLOAD_TYPE.FOLDERS) {
            files = await electron.showUploadDirsDialog();
        } else {
            const response = await electron.showUploadZipDialog();
            files = response.files;
            zipPaths.current = response.zipPaths;
        }
        if (files?.length > 0) {
            log.info(
                ` desktop upload for type:${type} and fileCount: ${files?.length} requested`,
            );
            setElectronFiles(files);
            props.closeUploadTypeSelector();
        }
    };

    const handleWebUpload = async (type: PICKED_UPLOAD_TYPE) => {
        pickedUploadType.current = type;
        if (type === PICKED_UPLOAD_TYPE.FILES) {
            props.showUploadFilesDialog();
        } else if (type === PICKED_UPLOAD_TYPE.FOLDERS) {
            props.showUploadDirsDialog();
        } else {
            appContext.setDialogMessage(getDownloadAppMessage());
        }
    };

    const cancelUploads = () => {
        uploadManager.cancelRunningUpload();
    };

    const handleUpload = (type) => () => {
        if (electron) {
            handleDesktopUpload(type, electron);
        } else {
            handleWebUpload(type);
        }
    };

    const handleFileUpload = handleUpload(PICKED_UPLOAD_TYPE.FILES);
    const handleFolderUpload = handleUpload(PICKED_UPLOAD_TYPE.FOLDERS);
    const handleZipUpload = handleUpload(PICKED_UPLOAD_TYPE.ZIPS);

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

    const handleUploadToSingleCollection = () => {
        uploadToSingleNewCollection(importSuggestion.rootFolderName);
    };

    const handleUploadToMultipleCollections = () => {
        if (importSuggestion.hasRootLevelFileWithFolder) {
            appContext.setDialogMessage(
                getRootLevelFileWithFolderNotAllowMessage(),
            );
            return;
        }
        uploadFilesToNewCollections("parent");
    };

    const didSelectCollectionMapping = (mapping: CollectionMapping) => {
        switch (mapping) {
            case "root":
                handleUploadToSingleCollection();
                break;
            case "parent":
                handleUploadToMultipleCollections();
                break;
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
                show={props.uploadTypeSelectorView}
                onClose={props.closeUploadTypeSelector}
                uploadFiles={handleFileUpload}
                uploadFolders={handleFolderUpload}
                uploadGoogleTakeoutZips={handleZipUpload}
                uploadTypeSelectorIntent={props.uploadTypeSelectorIntent}
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
                toUploadFilesCount={toUploadFiles.current?.length}
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
