import React from 'react';
import UploadService from 'services/uploadService';
import { getToken } from 'utils/common/key';
import DropzoneWrapper from './DropzoneWrapper';


function CollectionDropZone({
    children,
    closeModal,
    showModal,
    refetchData,
    collectionAndItsLatestFile,
    setProgressView,
    progressBarProps,
    setErrorCode
}) {

    const upload = async (acceptedFiles) => {
        try {
            const token = getToken();
            closeModal();
            progressBarProps.setPercentComplete(0);
            setProgressView(true);

            await UploadService.uploadFiles(acceptedFiles, collectionAndItsLatestFile, token, progressBarProps);
            refetchData();
        } catch (err) {
            if (err.response)
                setErrorCode(err.response.status);
        }
        finally {
            setProgressView(false);
        }
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
