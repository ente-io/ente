import React, {useEffect, useState} from 'react';
import UploadService, {FileWithCollection, UPLOAD_STAGES} from 'services/uploadService';
import {createAlbum} from 'services/collectionService';
import {File} from 'services/fileService';
import constants from 'utils/strings/constants';
import {SetDialogMessage} from 'components/MessageDialog';
import UploadProgress from './UploadProgress';

import ChoiceModal from './ChoiceModal';
import {SetCollectionNamerAttributes} from './CollectionNamer';
import {SetCollectionSelectorAttributes} from './CollectionSelector';
import {SetLoading} from '..';

interface Props {
    syncWithRemote: () => Promise<void>;
    setBannerMessage;
    acceptedFiles: globalThis.File[];
    existingFiles: File[];
    closeCollectionSelector: () => void;
    setCollectionSelectorAttributes: SetCollectionSelectorAttributes;
    setCollectionNamerAttributes: SetCollectionNamerAttributes;
    setLoading: SetLoading;
    setDialogMessage: SetDialogMessage;
    setUploadInProgress: any;
}

export enum UPLOAD_STRATEGY {
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
        UPLOAD_STAGES.START,
    );
    const [fileCounter, setFileCounter] = useState({current: 0, total: 0});
    const [fileProgress, setFileProgress] = useState(new Map<string, number>());
    const [percentComplete, setPercentComplete] = useState(0);
    const [choiceModalView, setChoiceModalView] = useState(false);
    const [fileAnalysisResult, setFileAnalysisResult] = useState<AnalysisResult>(null);
    useEffect(() => {
        if (props.acceptedFiles?.length > 0) {
            props.setLoading(true);
            const fileAnalysisResult = analyseUploadFiles();
            if (!fileAnalysisResult) {
                setFileAnalysisResult(fileAnalysisResult);
            }
            props.setCollectionSelectorAttributes({
                callback: uploadFilesToExistingCollection,
                showNextModal: nextModal.bind(null, fileAnalysisResult),
                title: 'upload to collection',
            });
            props.setLoading(false);
        }
    }, [props.acceptedFiles]);

    const uploadInit = function() {
        setUploadStage(UPLOAD_STAGES.START);
        setFileCounter({current: 0, total: 0});
        setFileProgress(new Map<string, number>());
        setPercentComplete(0);
    };
    const showCreateCollectionModal = (fileAnalysisResult?: AnalysisResult) => {
        props.setCollectionNamerAttributes({
            title: constants.CREATE_COLLECTION,
            buttonText: constants.CREATE,
            autoFilledName: fileAnalysisResult?.suggestedCollectionName,
            callback: async (collectionName) => {
                props.closeCollectionSelector();
                await uploadFilesToNewCollections(
                    UPLOAD_STRATEGY.SINGLE_COLLECTION,
                    collectionName,
                );
            },
        });
    };

    const nextModal = (fileAnalysisResult: AnalysisResult) => {
        fileAnalysisResult?.multipleFolders ?
            setChoiceModalView(true) :
            showCreateCollectionModal(fileAnalysisResult);
        setFileAnalysisResult(fileAnalysisResult);
    };

    function analyseUploadFiles() {
        if (props.acceptedFiles.length === 0) {
            return null;
        }
        const paths: string[] = props.acceptedFiles.map((file) => file.path);
        paths.sort();
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
                commonPathPrefix.lastIndexOf('/') - 1,
            );
        }
        return {
            suggestedCollectionName: commonPathPrefix,
            multipleFolders: firstFileFolder !== lastFileFolder,
        };
    }
    function getCollectionWiseFiles() {
        const collectionWiseFiles = new Map<string, any>();
        for (const file of props.acceptedFiles) {
            const filePath = file.path;
            const folderPath = filePath.substr(0, filePath.lastIndexOf('/'));
            const folderName = folderPath.substr(
                folderPath.lastIndexOf('/') + 1,
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
            setProgressView(true);

            const filesWithCollectionToUpload: FileWithCollection[] = props.acceptedFiles.map((file) => ({
                file,
                collection,
            }));
            await uploadFiles(filesWithCollectionToUpload);
        } catch (e) {
            console.error('Failed to upload files to existing collections', e);
        }
    };

    const uploadFilesToNewCollections = async (
        strategy: UPLOAD_STRATEGY,
        collectionName,
    ) => {
        try {
            uploadInit();
            setProgressView(true);
            const filesWithCollectionToUpload = [];
            try {
                if (strategy === UPLOAD_STRATEGY.SINGLE_COLLECTION) {
                    const collection = await createAlbum(collectionName);

                    return await uploadFilesToExistingCollection(collection);
                }
                const collectionWiseFiles = getCollectionWiseFiles();
                for (const [collectionName, files] of collectionWiseFiles) {
                    const collection = await createAlbum(collectionName);
                    for (const file of files) {
                        filesWithCollectionToUpload.push({collection, file});
                    }
                }
            } catch (e) {
                console.error('Failed to create album', e);
                props.setDialogMessage({
                    title: constants.ERROR,
                    staticBackdrop: true,
                    close: {variant: 'danger'},
                    content: constants.CREATE_ALBUM_FAILED,
                });
                throw e;
            }
            await uploadFiles(filesWithCollectionToUpload);
        } catch (e) {
            console.error('Failed to upload files to new collections', e);
        }
    };

    const uploadFiles = async (
        filesWithCollectionToUpload: FileWithCollection[],
    ) => {
        try {
            props.setUploadInProgress(true);
            props.closeCollectionSelector();
            await UploadService.uploadFiles(
                filesWithCollectionToUpload,
                props.existingFiles,
                {
                    setPercentComplete,
                    setFileCounter,
                    setUploadStage,
                    setFileProgress,
                },
            );
            props.setUploadInProgress(false);
        } catch (err) {
            props.setBannerMessage(err.message);
            setProgressView(false);
            throw err;
        } finally {
            props.syncWithRemote();
        }
    };

    return (
        <>
            <ChoiceModal
                show={choiceModalView}
                onHide={() => setChoiceModalView(false)}
                uploadFiles={uploadFilesToNewCollections}
                showCollectionCreateModal={() => showCreateCollectionModal(fileAnalysisResult)}
            />
            <UploadProgress
                now={percentComplete}
                fileCounter={fileCounter}
                uploadStage={uploadStage}
                fileProgress={fileProgress}
                show={progressView}
                closeModal={() => setProgressView(false)}
            />
        </>
    );
}
