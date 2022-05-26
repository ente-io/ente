import { DialogContent } from '@mui/material';
import constants from 'utils/strings/constants';
import { UPLOAD_STAGES, FileUploadResults } from 'constants/upload';
import React from 'react';
import { UploadProgressFooter } from './footer';
import { UploadProgressHeader } from './header';
import { InProgressSection } from './inProgressSection';
import { ResultSection } from './resultSection';
import { NotUploadSectionHeader } from './styledComponents';
import { DESKTOP_APP_DOWNLOAD_URL } from 'utils/common';
import DialogBoxBase from 'components/DialogBox/base';
export function UploadProgressDialog({
    handleHideModal,
    setExpanded,
    expanded,
    fileProgressStatuses,
    sectionInfo,
    fileUploadResultMap,
    filesNotUploaded,
    ...props
}) {
    return (
        <DialogBoxBase
            maxWidth="xs"
            open={props.show}
            onClose={handleHideModal}>
            <UploadProgressHeader
                uploadStage={props.uploadStage}
                setExpanded={setExpanded}
                expanded={expanded}
                handleHideModal={handleHideModal}
                fileCounter={props.fileCounter}
                now={props.now}
            />
            <DialogContent
                sx={{
                    '&&&': { px: 0 },
                }}>
                {props.uploadStage === UPLOAD_STAGES.UPLOADING && (
                    <InProgressSection
                        filenames={props.filenames}
                        fileProgressStatuses={fileProgressStatuses}
                        sectionTitle={constants.INPROGRESS_UPLOADS}
                        sectionInfo={sectionInfo}
                    />
                )}

                <ResultSection
                    filenames={props.filenames}
                    fileUploadResultMap={fileUploadResultMap}
                    fileUploadResult={FileUploadResults.UPLOADED}
                    sectionTitle={constants.SUCCESSFUL_UPLOADS}
                />

                {props.uploadStage === UPLOAD_STAGES.FINISH &&
                    filesNotUploaded && (
                        <NotUploadSectionHeader>
                            {constants.FILE_NOT_UPLOADED_LIST}
                        </NotUploadSectionHeader>
                    )}

                <ResultSection
                    filenames={props.filenames}
                    fileUploadResultMap={fileUploadResultMap}
                    fileUploadResult={FileUploadResults.BLOCKED}
                    sectionTitle={constants.BLOCKED_UPLOADS}
                    sectionInfo={constants.ETAGS_BLOCKED(
                        DESKTOP_APP_DOWNLOAD_URL
                    )}
                />
                <ResultSection
                    filenames={props.filenames}
                    fileUploadResultMap={fileUploadResultMap}
                    fileUploadResult={FileUploadResults.FAILED}
                    sectionTitle={constants.FAILED_UPLOADS}
                />
                <ResultSection
                    filenames={props.filenames}
                    fileUploadResultMap={fileUploadResultMap}
                    fileUploadResult={FileUploadResults.ALREADY_UPLOADED}
                    sectionTitle={constants.SKIPPED_FILES}
                    sectionInfo={constants.SKIPPED_INFO}
                />
                <ResultSection
                    filenames={props.filenames}
                    fileUploadResultMap={fileUploadResultMap}
                    fileUploadResult={
                        FileUploadResults.LARGER_THAN_AVAILABLE_STORAGE
                    }
                    sectionTitle={
                        constants.LARGER_THAN_AVAILABLE_STORAGE_UPLOADS
                    }
                    sectionInfo={constants.LARGER_THAN_AVAILABLE_STORAGE_INFO}
                />
                <ResultSection
                    filenames={props.filenames}
                    fileUploadResultMap={fileUploadResultMap}
                    fileUploadResult={FileUploadResults.UNSUPPORTED}
                    sectionTitle={constants.UNSUPPORTED_FILES}
                    sectionInfo={constants.UNSUPPORTED_INFO}
                />
                <ResultSection
                    filenames={props.filenames}
                    fileUploadResultMap={fileUploadResultMap}
                    fileUploadResult={FileUploadResults.TOO_LARGE}
                    sectionTitle={constants.TOO_LARGE_UPLOADS}
                    sectionInfo={constants.TOO_LARGE_INFO}
                />
            </DialogContent>

            {props.uploadStage === UPLOAD_STAGES.FINISH && (
                <UploadProgressFooter
                    uploadStage={props.uploadStage}
                    retryFailed={props.retryFailed}
                    closeModal={props.cancelUploads}
                    fileUploadResultMap={fileUploadResultMap}
                />
            )}
        </DialogBoxBase>
    );
}
