import { UploadProgressDialog } from './dialog';
import { MinimizedUploadProgress } from './minimized';
import React, { useContext, useMemo, useState } from 'react';

import constants from 'utils/strings/constants';
import { UPLOAD_STAGES } from 'constants/upload';
import { AppContext } from 'pages/_app';
import { dialogCloseHandler } from 'components/DialogBox/base';
import {
    UploadFileNames,
    UploadCounter,
    InProgressUploads,
    InProgressUpload,
    FinishedUploads,
    SegregatedFinishedUploads,
} from 'types/upload/ui';
import UploadProgressContext from 'contexts/uploadProgress';

interface Props {
    open: boolean;
    onClose: () => void;
    uploadCounter: UploadCounter;
    uploadStage: UPLOAD_STAGES;
    percentComplete: number;
    retryFailed: () => void;
    inProgressUploads: InProgressUploads;
    uploadFileNames: UploadFileNames;
    finishedUploads: FinishedUploads;
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
    ...props
}: Props) {
    const appContext = useContext(AppContext);
    const [expanded, setExpanded] = useState(true);

    const inProgressUploads = useMemo(
        () =>
            [...props.inProgressUploads.entries()].map(
                ([localFileID, progress]) =>
                    ({
                        localFileID,
                        progress,
                    } as InProgressUpload)
            ),

        [props.inProgressUploads]
    );

    const finishedUploads = useMemo(() => {
        const finishedUploads = new Map() as SegregatedFinishedUploads;
        for (const [localID, result] of props.finishedUploads) {
            if (!finishedUploads.has(result)) {
                finishedUploads.set(result, []);
            }
            finishedUploads.get(result).push(localID);
        }
        return finishedUploads;
    }, [props.finishedUploads]);

    console.log(finishedUploads);

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

    const handleClose = dialogCloseHandler({
        onClose: onClose,
    });

    return (
        <UploadProgressContext.Provider
            value={{
                open,
                onClose: handleClose,
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
