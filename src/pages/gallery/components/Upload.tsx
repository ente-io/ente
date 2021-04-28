import React, { useEffect, useState } from 'react';
import { FileWithCollection, UPLOAD_STAGES } from 'services/uploadService';
import UploadProgress from './UploadProgress';
import UploadService from 'services/uploadService';
import { createAlbum } from 'services/collectionService';
import ChoiceModal from './ChoiceModal';
import { File } from 'services/fileService';
import constants from 'utils/strings/constants';
import { SetCollectionNamerAttributes } from './CollectionNamer';
import { SetCollectionSelectorAttributes } from './CollectionSelector';
import { SetLoading } from '..';

interface Props {
    syncWithRemote: () => Promise<void>;
    setBannerMessage;
    acceptedFiles: globalThis.File[];
    existingFiles: File[];
    closeCollectionSelector: () => void;
    setCollectionSelectorAttributes: SetCollectionSelectorAttributes;
    setCollectionNamerAttributes: SetCollectionNamerAttributes;
    setLoading: SetLoading;
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
        UPLOAD_STAGES.START
    );
    const [fileCounter, setFileCounter] = useState({ current: 0, total: 0 });
    const [fileProgress, setFileProgress] = useState(new Map<string, number>());
    const [percentComplete, setPercentComplete] = useState(0);
    const [choiceModalView, setChoiceModalView] = useState(false);
    const [
        fileAnalysisResult,
        setFileAnalysisResult,
    ] = useState<AnalysisResult>(null);
    useEffect(() => {
        if (props.acceptedFiles?.length > 0) {
            props.setLoading(true);
            let fileAnalysisResult = analyseUploadFiles();
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
    const showCreateCollectionModal = (fileAnalysisResult?: AnalysisResult) => {
        props.setCollectionNamerAttributes({
            title: constants.CREATE_COLLECTION,
            buttonText: constants.CREATE,
            autoFilledName: fileAnalysisResult?.suggestedCollectionName,
            callback: async (collectionName) => {
                props.closeCollectionSelector();
                await uploadFilesToNewCollections(
                    UPLOAD_STRATEGY.SINGLE_COLLECTION,
                    collectionName
                );
            },
        });
    };

    const nextModal = (fileAnalysisResult: AnalysisResult) => {
        fileAnalysisResult?.multipleFolders
            ? setChoiceModalView(true)
            : showCreateCollectionModal(fileAnalysisResult);
        setFileAnalysisResult(fileAnalysisResult);
    };

    function analyseUploadFiles() {
        if (props.acceptedFiles.length == 0) {
            return null;
        }
        const paths: string[] = props.acceptedFiles.map((file) => file['path']);
        paths.sort();
        let firstPath = paths[0],
            lastPath = paths[paths.length - 1],
            L = firstPath.length,
            i = 0;
        const firstFileFolder = firstPath.substr(0, firstPath.lastIndexOf('/'));
        const lastFileFolder = lastPath.substr(0, lastPath.lastIndexOf('/'));
        while (i < L && firstPath.charAt(i) === lastPath.charAt(i)) i++;
        let commonPathPrefix = firstPath.substring(0, i);
        if (commonPathPrefix) {
            commonPathPrefix = commonPathPrefix.substr(
                1,
                commonPathPrefix.lastIndexOf('/') - 1
            );
        }
        return {
            suggestedCollectionName: commonPathPrefix,
            multipleFolders: firstFileFolder !== lastFileFolder,
        };
    }
    function getCollectionWiseFiles() {
        let collectionWiseFiles = new Map<string, any>();
        for (let file of props.acceptedFiles) {
            const filePath = file['path'];
            const folderPath = filePath.substr(0, filePath.lastIndexOf('/'));
            const folderName = folderPath.substr(
                folderPath.lastIndexOf('/') + 1
            );
            if (!collectionWiseFiles.has(folderName)) {
                collectionWiseFiles.set(folderName, new Array<File>());
            }
            collectionWiseFiles.get(folderName).push(file);
        }
        return collectionWiseFiles;
    }

    const uploadFilesToExistingCollection = async (collection) => {
        try {
            setProgressView(true);

            let filesWithCollectionToUpload: FileWithCollection[] = props.acceptedFiles.map(
                (file) => ({
                    file,
                    collection,
                })
            );
            await uploadFiles(filesWithCollectionToUpload);
        } catch (e) {
            console.error('Failed to upload files to existing collections', e);
        }
    };

    const uploadFilesToNewCollections = async (
        strategy: UPLOAD_STRATEGY,
        collectionName
    ) => {
        try {
            setProgressView(true);

            if (strategy == UPLOAD_STRATEGY.SINGLE_COLLECTION) {
                let collection = await createAlbum(collectionName);

                return await uploadFilesToExistingCollection(collection);
            }
            const collectionWiseFiles = getCollectionWiseFiles();
            let filesWithCollectionToUpload = new Array<FileWithCollection>();
            for (let [collectionName, files] of collectionWiseFiles) {
                let collection = await createAlbum(collectionName);
                for (let file of files) {
                    filesWithCollectionToUpload.push({ collection, file });
                }
            }
            await uploadFiles(filesWithCollectionToUpload);
        } catch (e) {
            console.error('Failed to upload files to new collections', e);
        }
    };

    const uploadFiles = async (
        filesWithCollectionToUpload: FileWithCollection[]
    ) => {
        try {
            await UploadService.uploadFiles(
                filesWithCollectionToUpload,
                props.existingFiles,
                {
                    setPercentComplete,
                    setFileCounter,
                    setUploadStage,
                    setFileProgress,
                }
            );
        } catch (err) {
            props.setBannerMessage(err.message);
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
                showCollectionCreateModal={() =>
                    showCreateCollectionModal(fileAnalysisResult)
                }
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
