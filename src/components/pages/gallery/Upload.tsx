import React, { useContext, useEffect, useRef, useState } from 'react';

import { syncCollections, createAlbum } from 'services/collectionService';
import constants from 'utils/strings/constants';
import { SetDialogMessage } from 'components/MessageDialog';
import UploadProgress from './UploadProgress';

import UploadStrategyChoiceModal from './UploadStrategyChoiceModal';
import { SetCollectionNamerAttributes } from './CollectionNamer';
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
import { getUserFacingErrorMessage } from 'utils/error';
import { Collection } from 'types/collection';
import { SetLoading, SetFiles } from 'types/gallery';
import { FileUploadResults, UPLOAD_STAGES } from 'constants/upload';
import { ElectronFile, FileWithCollection } from 'types/upload';
import UploadTypeChoiceModal from './UploadTypeChoiceModal';

const FIRST_ALBUM_NAME = 'My First Album';

interface Props {
    syncWithRemote: (force?: boolean, silent?: boolean) => Promise<void>;
    setBannerMessage: (message: string | JSX.Element) => void;
    acceptedFiles: File[];
    closeCollectionSelector: () => void;
    setCollectionSelectorAttributes: SetCollectionSelectorAttributes;
    setCollectionNamerAttributes: SetCollectionNamerAttributes;
    setLoading: SetLoading;
    setDialogMessage: SetDialogMessage;
    setUploadInProgress: any;
    showCollectionSelector: () => void;
    fileRejections: FileRejection[];
    setFiles: SetFiles;
    isFirstUpload: boolean;
    electronFiles: ElectronFile[];
    setElectronFiles: (files: ElectronFile[]) => void;
    showUploadTypeChoiceModal: boolean;
    setShowUploadTypeChoiceModal: (open: boolean) => void;
}

enum UPLOAD_STRATEGY {
    SINGLE_COLLECTION,
    COLLECTION_PER_FOLDER,
}

interface AnalysisResult {
    suggestedCollectionName: string;
    multipleFolders: boolean;
}

export default function Upload(props: Props) {
    const [progressView, setProgressView] = useState(false);
    const [uploadStage, setUploadStage] = useState<UPLOAD_STAGES>(
        UPLOAD_STAGES.START
    );
    const [filenames, setFilenames] = useState(new Map<number, string>());
    const [fileCounter, setFileCounter] = useState({ finished: 0, total: 0 });
    const [fileProgress, setFileProgress] = useState(new Map<number, number>());
    const [uploadResult, setUploadResult] = useState(
        new Map<number, FileUploadResults>()
    );
    const [percentComplete, setPercentComplete] = useState(0);
    const [hasLivePhotos, setHasLivePhotos] = useState(false);

    const [choiceModalView, setChoiceModalView] = useState(false);
    const [analysisResult, setAnalysisResult] = useState<AnalysisResult>({
        suggestedCollectionName: '',
        multipleFolders: false,
    });
    const appContext = useContext(AppContext);
    const galleryContext = useContext(GalleryContext);

    const toUploadFiles = useRef<File[] | ElectronFile[]>(null);
    const isPendingDesktopUpload = useRef(false);
    const pendingDesktopUploadCollectionName = useRef<string>('');
    const [isUploadDirs, setIsUploadDirs] = useState(false);

    useEffect(() => {
        UploadManager.initUploader(
            {
                setPercentComplete,
                setFileCounter,
                setFileProgress,
                setUploadResult,
                setUploadStage,
                setFilenames,
                setHasLivePhotos,
            },
            props.setFiles
        );

        if (isElectron()) {
            ImportService.hasPendingUploads().then((exists) => {
                if (exists) {
                    isPendingDesktopUpload.current = true;
                    resumeDesktopUpload();
                }
            });
        }
    }, []);

    useEffect(() => {
        if (
            props.acceptedFiles?.length > 0 ||
            appContext.sharedFiles?.length > 0 ||
            props.electronFiles?.length > 0
        ) {
            props.setLoading(true);

            let analysisResult: AnalysisResult;
            if (
                props.acceptedFiles?.length > 0 ||
                props.electronFiles?.length > 0
            ) {
                if (props.acceptedFiles?.length > 0) {
                    // File selection by drag and drop or selection of file.
                    toUploadFiles.current = props.acceptedFiles;
                } else {
                    // File selection from desktop app
                    toUploadFiles.current = props.electronFiles;
                }

                analysisResult = analyseUploadFiles();
                if (analysisResult) {
                    setAnalysisResult(analysisResult);
                }
            } else {
                toUploadFiles.current = appContext.sharedFiles;
            }
            handleCollectionCreationAndUpload(
                analysisResult,
                props.isFirstUpload
            );
            props.setLoading(false);
        }
    }, [props.acceptedFiles, appContext.sharedFiles, props.electronFiles]);

    const uploadInit = function () {
        setUploadStage(UPLOAD_STAGES.START);
        setFileCounter({ finished: 0, total: 0 });
        setFileProgress(new Map<number, number>());
        setUploadResult(new Map<number, number>());
        setPercentComplete(0);
        props.closeCollectionSelector();
        setProgressView(true);
    };

    const resumeDesktopUpload = async () => {
        try {
            const { files, collectionName } =
                await ImportService.getPendingUploads();

            pendingDesktopUploadCollectionName.current = collectionName;
            props.setElectronFiles(files);
        } catch (e) {
            logError(e, 'Failed to get previously failed files');
        }
    };

    function analyseUploadFiles(): AnalysisResult {
        if (toUploadFiles.current.length === 0) {
            return null;
        }
        if (isElectron() && !isUploadDirs) {
            return {
                suggestedCollectionName: null,
                multipleFolders: false,
            };
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
        const firstFileFolder = firstPath.substr(0, firstPath.lastIndexOf('/'));
        const lastFileFolder = lastPath.substr(0, lastPath.lastIndexOf('/'));
        while (i < L && firstPath.charAt(i) === lastPath.charAt(i)) i++;
        let commonPathPrefix = firstPath.substring(0, i);
        if (commonPathPrefix) {
            commonPathPrefix = commonPathPrefix.substr(
                1,
                commonPathPrefix.lastIndexOf('/') - 1
            );
            if (commonPathPrefix) {
                commonPathPrefix = commonPathPrefix.substr(
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

            let folderPath = filePath.substr(0, filePath.lastIndexOf('/'));
            if (folderPath.endsWith(METADATA_FOLDER_NAME)) {
                folderPath = folderPath.substr(0, folderPath.lastIndexOf('/'));
            }
            const folderName = folderPath.substr(
                folderPath.lastIndexOf('/') + 1
            );
            if (!collectionWiseFiles.has(folderName)) {
                collectionWiseFiles.set(folderName, []);
            }
            collectionWiseFiles.get(folderName).push(file);
        }
        return collectionWiseFiles;
    }

    const uploadFilesToExistingCollection = async (collection) => {
        try {
            uploadInit();
            const filesWithCollectionToUpload: FileWithCollection[] =
                toUploadFiles.current.map((file, index) => ({
                    file,
                    localID: index,
                    collectionID: collection.id,
                }));
            await uploadFiles(filesWithCollectionToUpload);
        } catch (e) {
            logError(e, 'Failed to upload files to existing collections');
        }
    };

    const uploadFilesToNewCollections = async (
        strategy: UPLOAD_STRATEGY,
        collectionName?: string
    ) => {
        try {
            uploadInit();

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
                setProgressView(false);
                logError(e, 'Failed to create album');
                props.setDialogMessage({
                    title: constants.ERROR,
                    staticBackdrop: true,
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
        collections?: Collection[]
    ) => {
        try {
            props.setUploadInProgress(true);
            props.closeCollectionSelector();
            await props.syncWithRemote(true, true);
            // set state to not done
            await ImportService.setToUploadFiles(
                filesWithCollectionToUpload,
                collections
            );
            await uploadManager.queueFilesForUpload(
                filesWithCollectionToUpload,
                collections
            );
        } catch (err) {
            const message = getUserFacingErrorMessage(
                err.message,
                galleryContext.showPlanSelectorModal
            );
            props.setBannerMessage(message);
            setProgressView(false);
            throw err;
        } finally {
            // set state to done
            await ImportService.setDoneUploadingFiles();
            appContext.resetSharedFiles();
            props.setUploadInProgress(false);
            props.syncWithRemote();
        }
    };
    const retryFailed = async () => {
        try {
            props.setUploadInProgress(true);
            uploadInit();
            await props.syncWithRemote(true, true);
            await uploadManager.retryFailedFiles();
        } catch (err) {
            const message = getUserFacingErrorMessage(
                err.message,
                galleryContext.showPlanSelectorModal
            );
            appContext.resetSharedFiles();
            props.setBannerMessage(message);
            setProgressView(false);
        } finally {
            props.setUploadInProgress(false);
            props.syncWithRemote();
        }
    };

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
            } else {
                uploadFilesToNewCollections(
                    UPLOAD_STRATEGY.COLLECTION_PER_FOLDER
                );
            }
        } else if (isFirstUpload) {
            const collectionName =
                analysisResult.suggestedCollectionName ?? FIRST_ALBUM_NAME;

            uploadToSingleNewCollection(collectionName);
        } else {
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
        }
    };

    return (
        <>
            <UploadStrategyChoiceModal
                show={choiceModalView}
                onHide={() => setChoiceModalView(false)}
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
            <UploadTypeChoiceModal
                setElectronFiles={props.setElectronFiles}
                showUploadTypeChoiceModal={props.showUploadTypeChoiceModal}
                setShowUploadTypeChoiceModal={
                    props.setShowUploadTypeChoiceModal
                }
                setIsUploadDirs={setIsUploadDirs}
            />
            <UploadProgress
                now={percentComplete}
                filenames={filenames}
                fileCounter={fileCounter}
                uploadStage={uploadStage}
                fileProgress={fileProgress}
                hasLivePhotos={hasLivePhotos}
                show={progressView}
                closeModal={() => setProgressView(false)}
                retryFailed={retryFailed}
                fileRejections={props.fileRejections}
                uploadResult={uploadResult}
            />
        </>
    );
}
