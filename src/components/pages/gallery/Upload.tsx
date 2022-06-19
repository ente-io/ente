import React, { useContext, useEffect, useRef, useState } from 'react';

import { syncCollections, createAlbum } from 'services/collectionService';
import constants from 'utils/strings/constants';
import UploadProgress from '../../UploadProgress';

import UploadStrategyChoiceModal from './UploadStrategyChoiceModal';
import { SetCollectionNamerAttributes } from '../../Collections/CollectionNamer';
import { SetCollectionSelectorAttributes } from './CollectionSelector';
import { GalleryContext } from 'pages/gallery';
import { AppContext } from 'pages/_app';
import { logError } from 'utils/sentry';
import { FileRejection } from 'react-dropzone';
import UploadManager from 'services/upload/uploadManager';
import uploadManager from 'services/upload/uploadManager';
import ImportService from 'services/importService';
import isElectron from 'is-electron';
import { METADATA_FOLDER_NAME } from 'constants/export';
import { CustomError } from 'utils/error';
import { Collection } from 'types/collection';
import { SetLoading, SetFiles } from 'types/gallery';
import { ElectronFile, FileWithCollection } from 'types/upload';
import UploadTypeSelector from '../../UploadTypeSelector';
import Router from 'next/router';
import { isCanvasBlocked } from 'utils/upload/isCanvasBlocked';
import { downloadApp } from 'utils/common';
import watchFolderService from 'services/watchFolder/watchFolderService';
import DiscFullIcon from '@mui/icons-material/DiscFull';
import { NotificationAttributes } from 'types/Notification';
import {
    UploadFileNames,
    UploadCounter,
    SegregatedFinishedUploads,
    InProgressUpload,
} from 'types/upload/ui';
import { UPLOAD_STAGES } from 'constants/upload';

const FIRST_ALBUM_NAME = 'My First Album';

interface Props {
    syncWithRemote: (force?: boolean, silent?: boolean) => Promise<void>;
    setBannerMessage: (message: string | JSX.Element) => void;
    droppedFiles: File[];
    clearDroppedFiles: () => void;
    closeCollectionSelector: () => void;
    setCollectionSelectorAttributes: SetCollectionSelectorAttributes;
    setCollectionNamerAttributes: SetCollectionNamerAttributes;
    setLoading: SetLoading;
    uploadInProgress: boolean;
    setUploadInProgress: (value: boolean) => void;
    showCollectionSelector: () => void;
    fileRejections: FileRejection[];
    setFiles: SetFiles;
    isFirstUpload: boolean;
    electronFiles: ElectronFile[];
    setElectronFiles: (files: ElectronFile[]) => void;
    uploadTypeSelectorView: boolean;
    setUploadTypeSelectorView: (open: boolean) => void;
    showSessionExpiredMessage: () => void;
}

enum UPLOAD_STRATEGY {
    SINGLE_COLLECTION,
    COLLECTION_PER_FOLDER,
}

export enum DESKTOP_UPLOAD_TYPE {
    FILES = 'files',
    FOLDERS = 'folders',
    ZIPS = 'zips',
}

interface AnalysisResult {
    suggestedCollectionName: string;
    multipleFolders: boolean;
}

const NULL_ANALYSIS_RESULT = {
    suggestedCollectionName: '',
    multipleFolders: false,
};

export default function Upload(props: Props) {
    const [uploadProgressView, setUploadProgressView] = useState(false);
    const [uploadStage, setUploadStage] = useState<UPLOAD_STAGES>();
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
    const [analysisResult, setAnalysisResult] =
        useState<AnalysisResult>(NULL_ANALYSIS_RESULT);
    const appContext = useContext(AppContext);
    const galleryContext = useContext(GalleryContext);

    const toUploadFiles = useRef<File[] | ElectronFile[]>(null);
    const isPendingDesktopUpload = useRef(false);
    const pendingDesktopUploadCollectionName = useRef<string>('');
    const desktopUploadType = useRef<DESKTOP_UPLOAD_TYPE>(null);
    const zipPaths = useRef<string[]>(null);

    useEffect(() => {
        UploadManager.initUploader(
            {
                setPercentComplete,
                setUploadCounter,
                setInProgressUploads,
                setFinishedUploads,
                setUploadStage,
                setUploadFilenames: setUploadFileNames,
                setHasLivePhotos,
            },
            props.setFiles
        );

        if (isElectron() && ImportService.checkAllElectronAPIsExists()) {
            ImportService.getPendingUploads().then(
                ({ files: electronFiles, collectionName, type }) => {
                    resumeDesktopUpload(type, electronFiles, collectionName);
                }
            );
            watchFolderService.init(
                props.setElectronFiles,
                setCollectionName,
                props.syncWithRemote,
                appContext.setIsFolderSyncRunning
            );
        }
    }, []);

    const setCollectionName = (collectionName: string) => {
        isPendingDesktopUpload.current = true;
        pendingDesktopUploadCollectionName.current = collectionName;
    };

    useEffect(() => {
        if (
            props.electronFiles?.length > 0 ||
            props.droppedFiles?.length > 0 ||
            appContext.sharedFiles?.length > 0
        ) {
            if (props.uploadInProgress) {
                // no-op
                // a upload is already in progress
            } else if (isCanvasBlocked()) {
                appContext.setDialogMessage({
                    title: constants.CANVAS_BLOCKED_TITLE,

                    content: constants.CANVAS_BLOCKED_MESSAGE(),
                    close: { text: constants.CLOSE },
                    proceed: {
                        text: constants.DOWNLOAD_APP,
                        action: downloadApp,
                        variant: 'accent',
                    },
                });
            } else {
                props.setLoading(true);
                if (props.droppedFiles?.length > 0) {
                    // File selection by drag and drop or selection of file.
                    toUploadFiles.current = props.droppedFiles;
                    props.clearDroppedFiles();
                } else if (appContext.sharedFiles?.length > 0) {
                    toUploadFiles.current = appContext.sharedFiles;
                    appContext.resetSharedFiles();
                } else if (props.electronFiles?.length > 0) {
                    // File selection from desktop app
                    toUploadFiles.current = props.electronFiles;
                    props.setElectronFiles([]);
                }
                const analysisResult = analyseUploadFiles();
                setAnalysisResult(analysisResult);

                handleCollectionCreationAndUpload(
                    analysisResult,
                    props.isFirstUpload
                );
                props.setLoading(false);
            }
        }
    }, [props.droppedFiles, appContext.sharedFiles, props.electronFiles]);

    const uploadInit = function () {
        setUploadStage(UPLOAD_STAGES.START);
        setUploadCounter({ finished: 0, total: 0 });
        setInProgressUploads([]);
        setFinishedUploads(new Map());
        setPercentComplete(0);
        props.closeCollectionSelector();
        setUploadProgressView(true);
    };

    const resumeDesktopUpload = async (
        type: DESKTOP_UPLOAD_TYPE,
        electronFiles: ElectronFile[],
        collectionName: string
    ) => {
        if (electronFiles && electronFiles?.length > 0) {
            isPendingDesktopUpload.current = true;
            pendingDesktopUploadCollectionName.current = collectionName;
            desktopUploadType.current = type;
            props.setElectronFiles(electronFiles);
        }
    };

    function analyseUploadFiles(): AnalysisResult {
        if (
            isElectron() &&
            (!desktopUploadType.current ||
                desktopUploadType.current === DESKTOP_UPLOAD_TYPE.FILES)
        ) {
            return NULL_ANALYSIS_RESULT;
        }

        const paths: string[] = toUploadFiles.current.map(
            (file) => file['path']
        );
        const getCharCount = (str: string) => (str.match(/\//g) ?? []).length;
        paths.sort((path1, path2) => getCharCount(path1) - getCharCount(path2));
        const firstPath = paths[0];
        const lastPath = paths[paths.length - 1];

        const L = firstPath.length;
        let i = 0;
        const firstFileFolder = firstPath.substring(
            0,
            firstPath.lastIndexOf('/')
        );
        const lastFileFolder = lastPath.substring(0, lastPath.lastIndexOf('/'));
        while (i < L && firstPath.charAt(i) === lastPath.charAt(i)) i++;
        let commonPathPrefix = firstPath.substring(0, i);

        if (commonPathPrefix) {
            commonPathPrefix = commonPathPrefix.substring(
                0,
                commonPathPrefix.lastIndexOf('/')
            );
            if (commonPathPrefix) {
                commonPathPrefix = commonPathPrefix.substring(
                    commonPathPrefix.lastIndexOf('/') + 1
                );
            }
        }
        return {
            suggestedCollectionName: commonPathPrefix || null,
            multipleFolders: firstFileFolder !== lastFileFolder,
        };
    }
    function getCollectionWiseFiles() {
        const collectionWiseFiles = new Map<string, (File | ElectronFile)[]>();
        for (const file of toUploadFiles.current) {
            const filePath = file['path'] as string;

            let folderPath = filePath.substring(0, filePath.lastIndexOf('/'));
            if (folderPath.endsWith(METADATA_FOLDER_NAME)) {
                folderPath = folderPath.substring(
                    0,
                    folderPath.lastIndexOf('/')
                );
            }
            const folderName = folderPath.substring(
                folderPath.lastIndexOf('/') + 1
            );
            if (!collectionWiseFiles.has(folderName)) {
                collectionWiseFiles.set(folderName, []);
            }
            collectionWiseFiles.get(folderName).push(file);
        }
        return collectionWiseFiles;
    }

    const uploadFilesToExistingCollection = async (collection: Collection) => {
        try {
            const filesWithCollectionToUpload: FileWithCollection[] =
                toUploadFiles.current.map((file, index) => ({
                    file,
                    localID: index,
                    collectionID: collection.id,
                }));
            await uploadFiles(filesWithCollectionToUpload, [collection]);
        } catch (e) {
            logError(e, 'Failed to upload files to existing collections');
        }
    };

    const uploadFilesToNewCollections = async (
        strategy: UPLOAD_STRATEGY,
        collectionName?: string
    ) => {
        try {
            const filesWithCollectionToUpload: FileWithCollection[] = [];
            const collections: Collection[] = [];
            let collectionWiseFiles = new Map<
                string,
                (File | ElectronFile)[]
            >();
            if (strategy === UPLOAD_STRATEGY.SINGLE_COLLECTION) {
                collectionWiseFiles.set(collectionName, toUploadFiles.current);
            } else {
                collectionWiseFiles = getCollectionWiseFiles();
            }
            try {
                const existingCollection = await syncCollections();
                let index = 0;
                for (const [collectionName, files] of collectionWiseFiles) {
                    const collection = await createAlbum(
                        collectionName,
                        existingCollection
                    );
                    collections.push(collection);

                    filesWithCollectionToUpload.push(
                        ...files.map((file) => ({
                            localID: index++,
                            collectionID: collection.id,
                            file,
                        }))
                    );
                }
            } catch (e) {
                setUploadProgressView(false);
                logError(e, 'Failed to create album');
                appContext.setDialogMessage({
                    title: constants.ERROR,

                    close: { variant: 'danger' },
                    content: constants.CREATE_ALBUM_FAILED,
                });
                throw e;
            }
            await uploadFiles(filesWithCollectionToUpload, collections);
        } catch (e) {
            logError(e, 'Failed to upload files to new collections');
        }
    };

    const uploadFiles = async (
        filesWithCollectionToUpload: FileWithCollection[],
        collections: Collection[]
    ) => {
        try {
            uploadInit();
            props.setUploadInProgress(true);
            props.closeCollectionSelector();
            await props.syncWithRemote(true, true);
            if (isElectron() && !isPendingDesktopUpload.current) {
                await ImportService.setToUploadCollection(collections);
                if (zipPaths.current) {
                    await ImportService.setToUploadFiles(
                        DESKTOP_UPLOAD_TYPE.ZIPS,
                        zipPaths.current
                    );
                    zipPaths.current = null;
                }
                await ImportService.setToUploadFiles(
                    DESKTOP_UPLOAD_TYPE.FILES,
                    filesWithCollectionToUpload.map(
                        ({ file }) => (file as ElectronFile).path
                    )
                );
            }
            await uploadManager.queueFilesForUpload(
                filesWithCollectionToUpload,
                collections
            );
        } catch (err) {
            showUserFacingError(err.message);
            setUploadProgressView(false);
            throw err;
        } finally {
            props.setUploadInProgress(false);
            props.syncWithRemote();
            if (isElectron()) {
                await watchFolderService.allFileUploadsDone(
                    filesWithCollectionToUpload,
                    collections
                );
            }
        }
    };

    const retryFailed = async () => {
        try {
            props.setUploadInProgress(true);
            uploadInit();
            await props.syncWithRemote(true, true);
            await uploadManager.retryFailedFiles();
        } catch (err) {
            showUserFacingError(err.message);

            setUploadProgressView(false);
        } finally {
            props.setUploadInProgress(false);
            props.syncWithRemote();
        }
    };

    function showUserFacingError(err: CustomError) {
        let notification: NotificationAttributes;
        switch (err) {
            case CustomError.SESSION_EXPIRED:
                return props.showSessionExpiredMessage();
            case CustomError.SUBSCRIPTION_EXPIRED:
                notification = {
                    variant: 'danger',
                    message: constants.SUBSCRIPTION_EXPIRED,
                    action: {
                        text: constants.UPGRADE_NOW,
                        callback: galleryContext.showPlanSelectorModal,
                    },
                };
                break;
            case CustomError.STORAGE_QUOTA_EXCEEDED:
                notification = {
                    variant: 'danger',
                    message: constants.STORAGE_QUOTA_EXCEEDED,
                    action: {
                        text: constants.RENEW_NOW,
                        callback: galleryContext.showPlanSelectorModal,
                    },
                    icon: <DiscFullIcon fontSize="large" />,
                };
                break;
            default:
                notification = {
                    variant: 'danger',
                    message: constants.UNKNOWN_ERROR,
                };
        }
        galleryContext.setNotificationAttributes(notification);
    }

    const uploadToSingleNewCollection = (collectionName: string) => {
        if (collectionName) {
            uploadFilesToNewCollections(
                UPLOAD_STRATEGY.SINGLE_COLLECTION,
                collectionName
            );
        } else {
            showCollectionCreateModal();
        }
    };
    const showCollectionCreateModal = () => {
        props.setCollectionNamerAttributes({
            title: constants.CREATE_COLLECTION,
            buttonText: constants.CREATE,
            autoFilledName: null,
            callback: uploadToSingleNewCollection,
        });
    };

    const handleCollectionCreationAndUpload = (
        analysisResult: AnalysisResult,
        isFirstUpload: boolean
    ) => {
        if (isPendingDesktopUpload.current) {
            isPendingDesktopUpload.current = false;
            if (pendingDesktopUploadCollectionName.current) {
                uploadToSingleNewCollection(
                    pendingDesktopUploadCollectionName.current
                );
                pendingDesktopUploadCollectionName.current = null;
            } else {
                uploadFilesToNewCollections(
                    UPLOAD_STRATEGY.COLLECTION_PER_FOLDER
                );
            }
            return;
        }
        if (
            isElectron() &&
            desktopUploadType.current === DESKTOP_UPLOAD_TYPE.ZIPS
        ) {
            uploadFilesToNewCollections(UPLOAD_STRATEGY.COLLECTION_PER_FOLDER);
            return;
        }
        if (isFirstUpload && !analysisResult.suggestedCollectionName) {
            analysisResult.suggestedCollectionName = FIRST_ALBUM_NAME;
        }
        let showNextModal = () => {};
        if (analysisResult.multipleFolders) {
            showNextModal = () => setChoiceModalView(true);
        } else {
            showNextModal = () =>
                uploadToSingleNewCollection(
                    analysisResult.suggestedCollectionName
                );
        }
        props.setCollectionSelectorAttributes({
            callback: uploadFilesToExistingCollection,
            showNextModal,
            title: constants.UPLOAD_TO_COLLECTION,
        });
    };
    const handleDesktopUploadTypes = async (type: DESKTOP_UPLOAD_TYPE) => {
        let files: ElectronFile[];
        desktopUploadType.current = type;
        if (type === DESKTOP_UPLOAD_TYPE.FILES) {
            files = await ImportService.showUploadFilesDialog();
        } else if (type === DESKTOP_UPLOAD_TYPE.FOLDERS) {
            files = await ImportService.showUploadDirsDialog();
        } else {
            const response = await ImportService.showUploadZipDialog();
            files = response.files;
            zipPaths.current = response.zipPaths;
        }
        if (files?.length > 0) {
            props.setElectronFiles(files);
            props.setUploadTypeSelectorView(false);
        }
    };

    const cancelUploads = async () => {
        setUploadProgressView(false);
        if (isElectron()) {
            ImportService.cancelRemainingUploads();
        }
        await props.setUploadInProgress(false);
        Router.reload();
    };

    const closeUploadProgress = () => setUploadProgressView(false);

    return (
        <>
            <UploadStrategyChoiceModal
                open={choiceModalView}
                onClose={() => setChoiceModalView(false)}
                uploadToSingleCollection={() =>
                    uploadToSingleNewCollection(
                        analysisResult.suggestedCollectionName
                    )
                }
                uploadToMultipleCollection={() =>
                    uploadFilesToNewCollections(
                        UPLOAD_STRATEGY.COLLECTION_PER_FOLDER
                    )
                }
            />
            <UploadTypeSelector
                show={props.uploadTypeSelectorView}
                onHide={() => props.setUploadTypeSelectorView(false)}
                uploadFiles={() =>
                    handleDesktopUploadTypes(DESKTOP_UPLOAD_TYPE.FILES)
                }
                uploadFolders={() =>
                    handleDesktopUploadTypes(DESKTOP_UPLOAD_TYPE.FOLDERS)
                }
                uploadGoogleTakeoutZips={() =>
                    handleDesktopUploadTypes(DESKTOP_UPLOAD_TYPE.ZIPS)
                }
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
        </>
    );
}
