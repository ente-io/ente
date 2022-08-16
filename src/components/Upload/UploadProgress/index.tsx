import { UploadProgressDialog } from './dialog';
import { MinimizedUploadProgress } from './minimized';
import React, { useContext, useEffect, useState } from 'react';

import constants from 'utils/strings/constants';
import { UPLOAD_STAGES } from 'constants/upload';
import { AppContext } from 'pages/_app';
import {
    UploadFileNames,
    UploadCounter,
    SegregatedFinishedUploads,
    InProgressUpload,
} from 'types/upload/ui';
import UploadProgressContext from 'contexts/uploadProgress';
import watchFolderService from 'services/watchFolder/watchFolderService';

interface Props {
    open: boolean;
    onClose: () => void;
    uploadCounter: UploadCounter;
    uploadStage: UPLOAD_STAGES;
    percentComplete: number;
    retryFailed: () => void;
    inProgressUploads: InProgressUpload[];
    uploadFileNames: UploadFileNames;
    finishedUploads: SegregatedFinishedUploads;
    hasLivePhotos: boolean;
    cancelUploads: () => void;
}

export default function UploadProgress({
    open,
    uploadCounter,
    uploadStage,
    percentComplete,
    retryFailed,
    uploadFileNames,
    hasLivePhotos,
    inProgressUploads,
    finishedUploads,
    ...props
}: Props) {
    const appContext = useContext(AppContext);
    const [expanded, setExpanded] = useState(true);

    // run watch folder minimized by default
    useEffect(() => {
        if (
            appContext.isFolderSyncRunning &&
            watchFolderService.isUploadRunning()
        ) {
            setExpanded(false);
        }
    }, [appContext.isFolderSyncRunning]);

    function confirmCancelUpload() {
        appContext.setDialogMessage({
            title: constants.STOP_UPLOADS_HEADER,
            content: constants.STOP_ALL_UPLOADS_MESSAGE,
            proceed: {
                text: constants.YES_STOP_UPLOADS,
                variant: 'danger',
                action: props.cancelUploads,
            },
            close: {
                text: constants.NO,
                variant: 'secondary',
                action: () => {},
            },
        });
    }

    function onClose() {
        if (uploadStage !== UPLOAD_STAGES.FINISH) {
            confirmCancelUpload();
        } else {
            props.onClose();
        }
    }

    if (!open) {
        return <></>;
    }

    return (
        <UploadProgressContext.Provider
            value={{
                open,
                onClose,
                uploadCounter,
                uploadStage,
                percentComplete,
                retryFailed,
                inProgressUploads,
                uploadFileNames,
                finishedUploads,
                hasLivePhotos,
                expanded,
                setExpanded,
            }}>
            {expanded ? <UploadProgressDialog /> : <MinimizedUploadProgress />}
        </UploadProgressContext.Provider>
    );
}
