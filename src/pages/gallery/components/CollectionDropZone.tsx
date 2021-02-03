import React from 'react';
import UploadService from 'services/uploadService';
import { getToken } from 'utils/common/key';
import DropzoneWrapper from './DropzoneWrapper';


function CollectionDropZone(props) {
    const { children,
        closeModal,
        showModal,
        refetchData,
        collectionLatestFile,
        setProgressView,
        progressBarProps, setErrorCode } = props
    const upload = async (acceptedFiles) => {
        try {
            const token = getToken();
            closeModal();
            progressBarProps.setPercentComplete(0);
            setProgressView(true);

            await UploadService.uploadFiles(acceptedFiles, collectionLatestFile, token, progressBarProps);
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
