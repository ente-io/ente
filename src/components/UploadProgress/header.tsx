import React from 'react';
import { UploadProgressBar } from './progressBar';
import { UploadProgressTitle } from './title';

export function UploadProgressHeader({
    uploadStage,
    setExpanded,
    expanded,
    handleHideModal,
    fileCounter,
    now,
}) {
    return (
        <>
            <UploadProgressTitle
                uploadStage={uploadStage}
                setExpanded={setExpanded}
                expanded={expanded}
                handleHideModal={handleHideModal}
                fileCounter={fileCounter}
            />
            <UploadProgressBar now={now} uploadStage={uploadStage} />
        </>
    );
}
