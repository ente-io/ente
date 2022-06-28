import { Dialog, DialogContent } from '@mui/material';
import constants from 'utils/strings/constants';
import { UPLOAD_STAGES, UPLOAD_RESULT } from 'constants/upload';
import React, { useContext, useEffect, useState } from 'react';
import { UploadProgressFooter } from './footer';
import { UploadProgressHeader } from './header';
import { InProgressSection } from './inProgressSection';
import { ResultSection } from './resultSection';
import { NotUploadSectionHeader } from './styledComponents';
import { getOSSpecificDesktopAppDownloadLink } from 'utils/common';
import UploadProgressContext from 'contexts/uploadProgress';
import { dialogCloseHandler } from 'components/DialogBox/TitleWithCloseButton';

export function UploadProgressDialog() {
    const { open, onClose, uploadStage, finishedUploads } = useContext(
        UploadProgressContext
    );

    const [hasUnUploadedFiles, setHasUnUploadedFiles] = useState(false);

    useEffect(() => {
        if (!hasUnUploadedFiles) {
            if (
                finishedUploads.get(UPLOAD_RESULT.ALREADY_UPLOADED)?.length >
                    0 ||
                finishedUploads.get(UPLOAD_RESULT.BLOCKED)?.length > 0 ||
                finishedUploads.get(UPLOAD_RESULT.FAILED)?.length > 0 ||
                finishedUploads.get(UPLOAD_RESULT.LARGER_THAN_AVAILABLE_STORAGE)
                    ?.length > 0 ||
                finishedUploads.get(UPLOAD_RESULT.TOO_LARGE)?.length > 0 ||
                finishedUploads.get(UPLOAD_RESULT.UNSUPPORTED)?.length > 0
            ) {
                setHasUnUploadedFiles(true);
            }
        }
    }, [finishedUploads]);

    const handleClose = dialogCloseHandler({ staticBackdrop: true, onClose });

    return (
        <Dialog maxWidth="xs" open={open} onClose={handleClose}>
            <UploadProgressHeader />
            {(uploadStage === UPLOAD_STAGES.UPLOADING ||
                uploadStage === UPLOAD_STAGES.FINISH) && (
                <DialogContent sx={{ '&&&': { px: 0 } }}>
                    {uploadStage === UPLOAD_STAGES.UPLOADING && (
                        <InProgressSection />
                    )}

                    <ResultSection
                        uploadResult={UPLOAD_RESULT.UPLOADED}
                        sectionTitle={constants.SUCCESSFUL_UPLOADS}
                    />
                    <ResultSection
                        uploadResult={
                            UPLOAD_RESULT.UPLOADED_WITH_STATIC_THUMBNAIL
                        }
                        sectionTitle={
                            constants.THUMBNAIL_GENERATION_FAILED_UPLOADS
                        }
                        sectionInfo={constants.THUMBNAIL_GENERATION_FAILED_INFO}
                    />

                    {uploadStage === UPLOAD_STAGES.FINISH &&
                        hasUnUploadedFiles && (
                            <NotUploadSectionHeader>
                                {constants.FILE_NOT_UPLOADED_LIST}
                            </NotUploadSectionHeader>
                        )}

                    <ResultSection
                        uploadResult={UPLOAD_RESULT.BLOCKED}
                        sectionTitle={constants.BLOCKED_UPLOADS}
                        sectionInfo={constants.ETAGS_BLOCKED(
                            getOSSpecificDesktopAppDownloadLink()
                        )}
                    />
                    <ResultSection
                        uploadResult={UPLOAD_RESULT.FAILED}
                        sectionTitle={constants.FAILED_UPLOADS}
                    />
                    <ResultSection
                        uploadResult={UPLOAD_RESULT.ALREADY_UPLOADED}
                        sectionTitle={constants.SKIPPED_FILES}
                        sectionInfo={constants.SKIPPED_INFO}
                    />
                    <ResultSection
                        uploadResult={
                            UPLOAD_RESULT.LARGER_THAN_AVAILABLE_STORAGE
                        }
                        sectionTitle={
                            constants.LARGER_THAN_AVAILABLE_STORAGE_UPLOADS
                        }
                        sectionInfo={
                            constants.LARGER_THAN_AVAILABLE_STORAGE_INFO
                        }
                    />
                    <ResultSection
                        uploadResult={UPLOAD_RESULT.UNSUPPORTED}
                        sectionTitle={constants.UNSUPPORTED_FILES}
                        sectionInfo={constants.UNSUPPORTED_INFO}
                    />
                    <ResultSection
                        uploadResult={UPLOAD_RESULT.TOO_LARGE}
                        sectionTitle={constants.TOO_LARGE_UPLOADS}
                        sectionInfo={constants.TOO_LARGE_INFO}
                    />
                </DialogContent>
            )}
            {uploadStage === UPLOAD_STAGES.FINISH && <UploadProgressFooter />}
        </Dialog>
    );
}
