import { UploadProgressDialog } from './dialog';
import { MinimizedUploadProgress } from './minimized';
import React, { useContext, useState } from 'react';

import constants from 'utils/strings/constants';
import { FileUploadResults, UPLOAD_STAGES } from 'constants/upload';
import { AppContext } from 'pages/_app';
import { dialogCloseHandler } from 'components/DialogBox/base';

interface Props {
    fileCounter;
    uploadStage;
    now;
    closeModal;
    retryFailed;
    fileProgress: Map<number, number>;
    filenames: Map<number, string>;
    show;
    uploadResult: Map<number, FileUploadResults>;
    hasLivePhotos: boolean;
    cancelUploads: () => void;
}
export interface FileProgresses {
    fileID: number;
    progress: number;
}

export default function UploadProgress(props: Props) {
    const appContext = useContext(AppContext);
    const [expanded, setExpanded] = useState(true);
    const fileProgressStatuses = [] as FileProgresses[];
    const fileUploadResultMap = new Map<FileUploadResults, number[]>();
    let filesNotUploaded = false;
    let sectionInfo = null;
    if (props.fileProgress) {
        for (const [localID, progress] of props.fileProgress) {
            fileProgressStatuses.push({
                fileID: localID,
                progress,
            });
        }
    }
    if (props.uploadResult) {
        for (const [localID, progress] of props.uploadResult) {
            if (!fileUploadResultMap.has(progress)) {
                fileUploadResultMap.set(progress, []);
            }
            if (
                progress !== FileUploadResults.UPLOADED &&
                progress !== FileUploadResults.UPLOADED_WITH_STATIC_THUMBNAIL
            ) {
                filesNotUploaded = true;
            }
            const fileList = fileUploadResultMap.get(progress);

            fileUploadResultMap.set(progress, [...fileList, localID]);
        }
    }
    if (props.hasLivePhotos) {
        sectionInfo = constants.LIVE_PHOTOS_DETECTED;
    }

    function confirmCancelUpload() {
        if (props.uploadStage !== UPLOAD_STAGES.FINISH) {
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
        } else {
            props.closeModal();
        }
    }

    const handleClose = dialogCloseHandler({
        staticBackdrop: true,
        onClose: confirmCancelUpload,
    });

    return (
        <>
            {expanded ? (
                <UploadProgressDialog
                    handleClose={handleClose}
                    setExpanded={setExpanded}
                    expanded={expanded}
                    fileProgressStatuses={fileProgressStatuses}
                    sectionInfo={sectionInfo}
                    fileUploadResultMap={fileUploadResultMap}
                    filesNotUploaded={filesNotUploaded}
                    {...props}
                />
            ) : (
                <MinimizedUploadProgress
                    setExpanded={setExpanded}
                    expanded={expanded}
                    handleClose={handleClose}
                    {...props}
                />
            )}
        </>
    );
}
