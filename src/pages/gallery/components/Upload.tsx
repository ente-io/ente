import React, { useEffect, useState } from 'react';
import { FileWithCollection, UPLOAD_STAGES } from 'services/uploadService';
import { getToken } from 'utils/common/key';
import CollectionSelector from './CollectionSelector';
import UploadProgress from './UploadProgress';
import UploadService from 'services/uploadService';
import { createAlbum } from 'services/collectionService';
import CreateCollection from './CreateCollection';
import ChoiceModal from './ChoiceModal';

interface Props {
    collectionSelectorView: any;
    closeCollectionSelector;
    collectionAndItsLatestFile;
    refetchData;
    setBannerErrorCode;
    acceptedFiles;
}

export enum UPLOAD_STRATEGY {
    SINGLE_COLLECTION,
    COLLECTION_PER_FOLDER,
}
export default function Upload(props: Props) {
    const [progressView, setProgressView] = useState(false);
    const [uploadStage, setUploadStage] = useState<UPLOAD_STAGES>(
        UPLOAD_STAGES.START
    );
    const [fileCounter, setFileCounter] = useState({ current: 0, total: 0 });
    const [fileProgress, setFileProgress] = useState(new Map<string, number>());
    const [percentComplete, setPercentComplete] = useState(0);
    const [uploadErrors, setUploadErrors] = useState<Error[]>([]);
    const [createCollectionView, setCreateCollectionView] = useState(false);
    const [choiceModalView, setChoiceModalView] = useState(false);
    const [suggestedCollectionName, setSuggestedCollectionName] = useState('');
    useEffect(() => {
        if (!props.collectionSelectorView) {
            return;
        }
        if (
            props.collectionAndItsLatestFile &&
            props.collectionAndItsLatestFile.length == 0
        ) {
            setCreateCollectionView(true);
        }
        setSuggestedCollectionName(getSuggestedCollectionName());
        init();
    }, [props.collectionSelectorView]);

    const init = () => {
        setUploadStage(UPLOAD_STAGES.START);
        setFileCounter({ current: 0, total: 0 });
        setPercentComplete(0);
    };

    function getSuggestedCollectionName() {
        if (props.acceptedFiles.length == 0) {
            return '';
        }
        const paths: string[] = props.acceptedFiles.map((file) => file.path);
        paths.sort();
        let firstPath = paths[0],
            lastPath = paths[paths.length - 1],
            L = firstPath.length,
            i = 0;
        while (i < L && firstPath.charAt(i) === lastPath.charAt(i)) i++;
        let commonPathPrefix = firstPath.substring(0, i);
        if (commonPathPrefix) {
            commonPathPrefix = commonPathPrefix.substr(
                1,
                commonPathPrefix.lastIndexOf('/') - 1
            );
        }
        return commonPathPrefix;
    }
    function getCollectionWiseFiles() {
        let collectionWiseFiles = new Map<string, any>();
        for (let file of props.acceptedFiles) {
            const filePath = file.path;
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
            let collectionWiseFiles: Map<string, any>;
            if (strategy == UPLOAD_STRATEGY.SINGLE_COLLECTION) {
                collectionWiseFiles = new Map<string, any>([
                    collectionName,
                    props.acceptedFiles,
                ]);
            } else {
                collectionWiseFiles = getCollectionWiseFiles();
            }
            let filesWithCollectionToUpload = new Array<FileWithCollection>();
            for (let [collectionName, files] of collectionWiseFiles) {
                let collection = await createAlbum(collectionName);
                for (let file of files) {
                    filesWithCollectionToUpload.push({ collection, file });
                }
            }
        } catch (e) {
            console.error('Failed to upload files to new collections', e);
        }
    };

    const uploadFiles = async (
        filesWithCollectionToUpload: FileWithCollection[]
    ) => {
        try {
            const token = getToken();
            setProgressView(true);
            props.closeCollectionSelector();
            setChoiceModalView(false);

            await UploadService.uploadFiles(
                filesWithCollectionToUpload,
                token,
                {
                    setPercentComplete,
                    setFileCounter,
                    setUploadStage,
                    setFileProgress,
                },
                setUploadErrors
            );
        } catch (err) {
            props.setBannerErrorCode(err.message);
        } finally {
            setProgressView(false);
            props.refetchData();
        }
    };

    return (
        <>
            <CollectionSelector
                collectionAndItsLatestFile={props.collectionAndItsLatestFile}
                uploadFiles={uploadFilesToExistingCollection}
                showChoiceModal={() => setChoiceModalView(true)}
                collectionSelectorView={props.collectionSelectorView}
                closeCollectionSelector={props.closeCollectionSelector}
                showCollectionCreateModal={() => setCreateCollectionView(true)}
            />
            <CreateCollection
                createCollectionView={createCollectionView}
                setCreateCollectionView={setCreateCollectionView}
                autoFilledName={suggestedCollectionName}
                uploadFiles={uploadFilesToNewCollections}
            />
            <ChoiceModal
                show={choiceModalView}
                onHide={() => setChoiceModalView(false)}
                uploadFiles={uploadFilesToNewCollections}
                showCollectionCreateModal={() => setCreateCollectionView(true)}
            />
            <UploadProgress
                now={percentComplete}
                fileCounter={fileCounter}
                uploadStage={uploadStage}
                uploadErrors={uploadErrors}
                fileProgress={fileProgress}
                show={progressView}
                closeModal={() => setProgressView(false)}
                onHide={init}
            />
        </>
    );
}
