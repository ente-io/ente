import React from 'react';
import UploadService from 'services/uploadService';
import { getToken } from 'utils/common/key';
import DropzoneWrapper from './DropzoneWrapper';


function CollectionDropZone({
    children,
    closeModal,
    showModal,
    refetchData,
    collectionLatestFile,
    setProgressView,
    progressBarProps

}) {

    const upload = async (acceptedFiles) => {
        const token = getToken();
        closeModal();
        progressBarProps.setPercentComplete(0);
        setProgressView(true);

        await UploadService.uploadFiles(acceptedFiles, collectionLatestFile, token, progressBarProps);
        refetchData();
        setProgressView(false);
    }
    return (
        <DropzoneWrapper
            children={children}
            onDropAccepted={upload}
            onDragOver={showModal}
            onDropRejected={closeModal}
        />
    );
};

export default CollectionDropZone;
