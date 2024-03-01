import { useContext, useEffect, useRef, useState } from "react";

import { t } from "i18next";
import { Trans } from "react-i18next";
import { getLatestCollections } from "services/collectionService";

import UploadProgress from "./UploadProgress";

import ElectronAPIs from "@ente/shared/electron";
import { CustomError } from "@ente/shared/error";
import { addLogLine } from "@ente/shared/logging";
import { logError } from "@ente/shared/sentry";
import DiscFullIcon from "@mui/icons-material/DiscFull";
import UserNameInputDialog from "components/UserNameInputDialog";
import {
    DEFAULT_IMPORT_SUGGESTION,
    PICKED_UPLOAD_TYPE,
    UPLOAD_STAGES,
    UPLOAD_STRATEGY,
} from "constants/upload";
import isElectron from "is-electron";
import { AppContext } from "pages/_app";
import { GalleryContext } from "pages/gallery";
import billingService from "services/billingService";
import ImportService from "services/importService";
import {
    getPublicCollectionUID,
    getPublicCollectionUploaderName,
    savePublicCollectionUploaderName,
} from "services/publicCollectionService";
import uploadManager from "services/upload/uploadManager";
import watchFolderService from "services/watchFolder/watchFolderService";
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
import {
    ElectronFile,
    FileWithCollection,
    ImportSuggestion,
} from "types/upload";
import {
    InProgressUpload,
    SegregatedFinishedUploads,
    UploadCounter,
    UploadFileNames,
} from "types/upload/ui";
import { getOrCreateAlbum } from "utils/collection";
import { downloadApp, waitAndRun } from "utils/common";
import { PublicCollectionGalleryContext } from "utils/publicCollectionGallery";
import {
    getDownloadAppMessage,
    getRootLevelFileWithFolderNotAllowMessage,
} from "utils/ui";
import {
    filterOutSystemFiles,
    getImportSuggestion,
    groupFilesBasedOnParentFolder,
} from "utils/upload";
import { isCanvasBlocked } from "utils/upload/isCanvasBlocked";
import { SetCollectionNamerAttributes } from "../Collections/CollectionNamer";
import UploadStrategyChoiceModal from "./UploadStrategyChoiceModal";
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
    const [electronFiles, setElectronFiles] = useState<ElectronFile[]>(null);
    const [webFiles, setWebFiles] = useState([]);

    const toUploadFiles = useRef<File[] | ElectronFile[]>(null);
    const isPendingDesktopUpload = useRef(false);
    const pendingDesktopUploadCollectionName = useRef<string>("");
    // This is set when the user choses a type to upload from the upload type selector dialog
    const pickedUploadType = useRef<PICKED_UPLOAD_TYPE>(null);
    const zipPaths = useRef<string[]>(null);
    const currentUploadPromise = useRef<Promise<void>>(null);
    const uploadRunning = useRef(false);
    const uploaderNameRef = useRef<string>(null);
    const isDragAndDrop = useRef(false);

    const closeUploadProgress = () => setUploadProgressView(false);
    const showUserNameInputDialog = () => setUserNameInputDialogView(true);

    const setCollectionName = (collectionName: string) => {
        isPendingDesktopUpload.current = true;
        pendingDesktopUploadCollectionName.current = collectionName;
    };

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
            ImportService.getPendingUploads().then(
                ({ files: electronFiles, collectionName, type }) => {
                    addLogLine(
                        `found pending desktop upload, resuming uploads`,
                    );
                    resumeDesktopUpload(type, electronFiles, collectionName);
                },
            );
            watchFolderService.init(
                setElectronFiles,
                setCollectionName,
                props.syncWithRemote,
                appContext.setIsFolderSyncRunning,
            );
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
            addLogLine(`received folder upload request`);
            setWebFiles(props.webFolderSelectorFiles);
        } else if (
            pickedUploadType.current === PICKED_UPLOAD_TYPE.FILES &&
            props.webFileSelectorFiles?.length > 0
        ) {
            addLogLine(`received file upload request`);
            setWebFiles(props.webFileSelectorFiles);
        } else if (props.dragAndDropFiles?.length > 0) {
            isDragAndDrop.current = true;
            if (isElectron()) {
                const main = async () => {
                    try {
                        addLogLine(`uploading dropped files from desktop app`);
                        // check and parse dropped files which are zip files
                        let electronFiles = [] as ElectronFile[];
                        for (const file of props.dragAndDropFiles) {
                            if (file.name.endsWith(".zip")) {
                                const zipFiles =
                                    await ElectronAPIs.getElectronFilesFromGoogleZip(
                                        (file as any).path,
                                    );
                                addLogLine(
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
                        addLogLine(
                            `uploading dropped files from desktop app - ${electronFiles.length} files found`,
                        );
                        setElectronFiles(electronFiles);
                    } catch (e) {
                        logError(e, "failed to upload desktop dropped files");
                        setWebFiles(props.dragAndDropFiles);
                    }
                };
                main();
            } else {
                addLogLine(`uploading dropped files from web app`);
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
            electronFiles?.length > 0 ||
            webFiles?.length > 0 ||
            appContext.sharedFiles?.length > 0
        ) {
            addLogLine(
                `upload request type:${
                    electronFiles?.length > 0
                        ? "electronFiles"
                        : webFiles?.length > 0
                          ? "webFiles"
                          : "sharedFiles"
                } count ${
                    electronFiles?.length ??
                    webFiles?.length ??
                    appContext?.sharedFiles.length
                }`,
            );
            if (uploadManager.isUploadRunning()) {
                if (watchFolderService.isUploadRunning()) {
                    addLogLine(
                        "watchFolder upload was running, pausing it to run user upload",
                    );
                    // pause watch folder service on user upload
                    watchFolderService.pauseRunningSync();
                } else {
                    addLogLine(
                        "an upload is already running, rejecting new upload request",
                    );
                    // no-op
                    // a user upload is already in progress
                    return;
                }
            }
            if (isCanvasBlocked()) {
                addLogLine("canvas blocked, blocking upload");
                appContext.setDialogMessage({
                    title: t("CANVAS_BLOCKED_TITLE"),

                    content: <Trans i18nKey="CANVAS_BLOCKED_MESSAGE" />,
                    close: { text: t("CLOSE") },
                    proceed: {
                        text: t("DOWNLOAD"),
                        action: downloadApp,
                        variant: "accent",
                    },
                });
                return;
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
                // File selection from desktop app
                toUploadFiles.current = electronFiles;
                setElectronFiles([]);
            }

            toUploadFiles.current = filterOutSystemFiles(toUploadFiles.current);
            if (toUploadFiles.current.length === 0) {
                props.setLoading(false);
                return;
            }

            const importSuggestion = getImportSuggestion(
                pickedUploadType.current,
                toUploadFiles.current,
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
    }, [webFiles, appContext.sharedFiles, electronFiles]);

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
            addLogLine(
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
            logError(e, "Failed to upload files to existing collections");
        }
    };

    const uploadFilesToNewCollections = async (
        strategy: UPLOAD_STRATEGY,
        collectionName?: string,
    ) => {
        try {
            addLogLine(
                `upload file to an new collections strategy:${strategy} ,collectionName:${collectionName}`,
            );
            await preCollectionCreationAction();
            let filesWithCollectionToUpload: FileWithCollection[] = [];
            const collections: Collection[] = [];
            let collectionNameToFilesMap = new Map<
                string,
                (File | ElectronFile)[]
            >();
            if (strategy === UPLOAD_STRATEGY.SINGLE_COLLECTION) {
                collectionNameToFilesMap.set(
                    collectionName,
                    toUploadFiles.current,
                );
            } else {
                collectionNameToFilesMap = groupFilesBasedOnParentFolder(
                    toUploadFiles.current,
                );
            }
            addLogLine(
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
                logError(e, "Failed to create album");
                appContext.setDialogMessage({
                    title: t("ERROR"),

                    close: { variant: "critical" },
                    content: t("CREATE_ALBUM_FAILED"),
                });
                throw e;
            }
            await waitInQueueAndUploadFiles(
                filesWithCollectionToUpload,
                collections,
            );
            toUploadFiles.current = null;
        } catch (e) {
            logError(e, "Failed to upload files to new collections");
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
            addLogLine("uploadFiles called");
            preUploadAction();
            if (
                isElectron() &&
                !isPendingDesktopUpload.current &&
                !watchFolderService.isUploadRunning()
            ) {
                await ImportService.setToUploadCollection(collections);
                if (zipPaths.current) {
                    ElectronAPIs.setToUploadFiles(
                        PICKED_UPLOAD_TYPE.ZIPS,
                        zipPaths.current,
                    );
                    zipPaths.current = null;
                }
                ElectronAPIs.setToUploadFiles(
                    PICKED_UPLOAD_TYPE.FILES,
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
                if (watchFolderService.isUploadRunning()) {
                    await watchFolderService.allFileUploadsDone(
                        filesWithCollectionToUploadIn,
                        collections,
                    );
                } else if (watchFolderService.isSyncPaused()) {
                    // resume the service after user upload is done
                    watchFolderService.resumePausedSync();
                }
            }
        } catch (err) {
            logError(err, "failed to upload files");
            showUserFacingError(err.message);
            closeUploadProgress();
        } finally {
            postUploadAction();
        }
    };

    const retryFailed = async () => {
        try {
            addLogLine("user retrying failed  upload");
            const filesWithCollections =
                uploadManager.getFailedFilesWithCollections();
            const uploaderName = uploadManager.getUploaderName();
            await preUploadAction();
            await uploadManager.queueFilesForUpload(
                filesWithCollections.files,
                filesWithCollections.collections,
                uploaderName,
            );
        } catch (err) {
            logError(err, "retry failed files failed");
            showUserFacingError(err.message);
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
        uploadFilesToNewCollections(
            UPLOAD_STRATEGY.SINGLE_COLLECTION,
            collectionName,
        );
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
                addLogLine(
                    `uploading files to pulbic collection - ${props.uploadCollection.name}  - ${props.uploadCollection.id}`,
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
                    addLogLine(
                        `upload pending files to collection - ${pendingDesktopUploadCollectionName.current}`,
                    );
                    uploadFilesToNewCollections(
                        UPLOAD_STRATEGY.SINGLE_COLLECTION,
                        pendingDesktopUploadCollectionName.current,
                    );
                    pendingDesktopUploadCollectionName.current = null;
                } else {
                    addLogLine(
                        `pending upload - strategy - "multiple collections" `,
                    );
                    uploadFilesToNewCollections(
                        UPLOAD_STRATEGY.COLLECTION_PER_FOLDER,
                    );
                }
                return;
            }
            if (isElectron() && pickedUploadType === PICKED_UPLOAD_TYPE.ZIPS) {
                addLogLine("uploading zip files");
                uploadFilesToNewCollections(
                    UPLOAD_STRATEGY.COLLECTION_PER_FOLDER,
                );
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
                addLogLine(`nested folders detected`);
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
            logError(e, "handleCollectionCreationAndUpload failed");
        }
    };

    const handleDesktopUpload = async (type: PICKED_UPLOAD_TYPE) => {
        let files: ElectronFile[];
        pickedUploadType.current = type;
        if (type === PICKED_UPLOAD_TYPE.FILES) {
            files = await ElectronAPIs.showUploadFilesDialog();
        } else if (type === PICKED_UPLOAD_TYPE.FOLDERS) {
            files = await ElectronAPIs.showUploadDirsDialog();
        } else {
            const response = await ElectronAPIs.showUploadZipDialog();
            files = response.files;
            zipPaths.current = response.zipPaths;
        }
        if (files?.length > 0) {
            addLogLine(
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
        if (isElectron()) {
            handleDesktopUpload(type);
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
            logError(e, "public upload failed ");
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
        uploadFilesToNewCollections(UPLOAD_STRATEGY.COLLECTION_PER_FOLDER);
    };

    return (
        <>
            <UploadStrategyChoiceModal
                open={choiceModalView}
                onClose={handleChoiceModalClose}
                uploadToSingleCollection={handleUploadToSingleCollection}
                uploadToMultipleCollection={handleUploadToMultipleCollections}
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
