import React, { useState } from 'react';
import { UPLOAD_STAGES } from 'services/uploadService';
import { getToken } from 'utils/common/key';
import CollectionSelector from './CollectionSelector';
import UploadProgress from './UploadProgress';
import UploadService from 'services/uploadService';
import { createAlbum } from 'services/collectionService';

interface Props {
    uploadModalView: any;
    closeUploadModal;
    collectionAndItsLatestFile;
    refetchData;
    setBannerErrorCode;
    acceptedFiles;
}
export default function Upload(props: Props) {
    const [progressView, setProgressView] = useState(false);
    const [uploadStage, setUploadStage] = useState<UPLOAD_STAGES>(
        UPLOAD_STAGES.START
    );
    const [fileCounter, setFileCounter] = useState({ current: 0, total: 0 });
    const [percentComplete, setPercentComplete] = useState(0);
    const [uploadErrors, setUploadErrors] = useState<Error[]>([]);
    const init = () => {
        setProgressView(false);
        setUploadStage(UPLOAD_STAGES.START);
        setFileCounter({ current: 0, total: 0 });
        setPercentComplete(0);
    };

    const uploadFiles = async (collection, collectionName) => {
        try {
            const token = getToken();
            setPercentComplete(0);
            setProgressView(true);
            props.closeUploadModal();
            if (!collection) {
                collection = await createAlbum(collectionName);
            }
            await UploadService.uploadFiles(
                props.acceptedFiles,
                collection,
                token,
                {
                    setPercentComplete,
                    setFileCounter,
                    setUploadStage,
                },
                setUploadErrors
            );
            props.refetchData();
        } catch (err) {
            props.setBannerErrorCode(err.message);
            setProgressView(false);
        }
    };
    let commonPathPrefix = '';
    if (props.acceptedFiles.length > 0) {
        commonPathPrefix = (() => {
            const paths: string[] = props.acceptedFiles.map(
                (files) => files.path
            );
            paths.sort();
            let firstPath = paths[0],
                lastPath = paths[paths.length - 1],
                L = firstPath.length,
                i = 0;
            while (i < L && firstPath.charAt(i) === lastPath.charAt(i)) i++;
            return firstPath.substring(0, i);
        })();
        if (commonPathPrefix) {
            commonPathPrefix = commonPathPrefix.substr(
                1,
                commonPathPrefix.lastIndexOf('/') - 1
            );
        }
    }
    return (
        <>
            <CollectionSelector
                collectionAndItsLatestFile={props.collectionAndItsLatestFile}
                uploadFiles={uploadFiles}
                uploadModalView={props.uploadModalView}
                closeUploadModal={props.closeUploadModal}
                suggestedCollectionName={commonPathPrefix}
            />
            <UploadProgress
                now={percentComplete}
                fileCounter={fileCounter}
                uploadStage={uploadStage}
                uploadErrors={uploadErrors}
                show={progressView}
                closeModal={() => setProgressView(false)}
                onHide={init}
            />
        </>
    );
}
