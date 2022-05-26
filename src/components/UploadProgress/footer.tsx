import { Button, DialogActions } from '@mui/material';
import { UPLOAD_STAGES, FileUploadResults } from 'constants/upload';
import React from 'react';
import constants from 'utils/strings/constants';
export function UploadProgressFooter({
    uploadStage,
    fileUploadResultMap,
    retryFailed,
    closeModal,
}) {
    return (
        <DialogActions>
            {uploadStage === UPLOAD_STAGES.FINISH &&
                (fileUploadResultMap?.get(FileUploadResults.FAILED)?.length >
                    0 ||
                fileUploadResultMap?.get(FileUploadResults.BLOCKED)?.length >
                    0 ? (
                    <Button variant="contained" fullWidth onClick={retryFailed}>
                        {constants.RETRY_FAILED}
                    </Button>
                ) : (
                    <Button variant="contained" fullWidth onClick={closeModal}>
                        {constants.CLOSE}
                    </Button>
                ))}
        </DialogActions>
    );
}
