import React from 'react';
import { UploadProgressBar } from './progressBar';
import { UploadProgressTitle } from './title';

export function UploadProgressHeader({
    uploadStage,
    setExpanded,
    expanded,
    handleClose,
    fileCounter,
    now,
}) {
    return (
        <>
            <UploadProgressTitle
                uploadStage={uploadStage}
                setExpanded={setExpanded}
                expanded={expanded}
                handleClose={handleClose}
                fileCounter={fileCounter}
            />
            <UploadProgressBar now={now} uploadStage={uploadStage} />
        </>
    );
}
