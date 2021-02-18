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
    setBannerErrorCode,
    setUploadErrors,
}) {
    const upload = async (acceptedFiles) => {
        try {
            const token = getToken();
            closeModal();
            progressBarProps.setPercentComplete(0);
            setProgressView(true);

            await UploadService.uploadFiles(
                acceptedFiles,
                collectionAndItsLatestFile,
                token,
                progressBarProps,
                setUploadErrors
            );
            refetchData();
        } catch (err) {
            if (err.response) {
                setBannerErrorCode(err.response.status);
            }
        } finally {
            setProgressView(false);
        }
    };
    return (
        <DropzoneWrapper
            children={children}
            onDropAccepted={upload}
            onDragOver={showModal}
            onDropRejected={closeModal}
        />
    );
}

export default CollectionDropZone;
