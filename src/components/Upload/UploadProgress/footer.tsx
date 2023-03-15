import { Button, DialogActions } from '@mui/material';
import { UPLOAD_STAGES, UPLOAD_RESULT } from 'constants/upload';
import React, { useContext } from 'react';
import { t } from 'i18next';

import UploadProgressContext from 'contexts/uploadProgress';

export function UploadProgressFooter() {
    const { uploadStage, finishedUploads, retryFailed, onClose } = useContext(
        UploadProgressContext
    );

    return (
        <DialogActions>
            {uploadStage === UPLOAD_STAGES.FINISH &&
                (finishedUploads?.get(UPLOAD_RESULT.FAILED)?.length > 0 ||
                finishedUploads?.get(UPLOAD_RESULT.BLOCKED)?.length > 0 ? (
                    <Button variant="contained" fullWidth onClick={retryFailed}>
                        {t('RETRY_FAILED')}
                    </Button>
                ) : (
                    <Button variant="contained" fullWidth onClick={onClose}>
                        {t('CLOSE')}
                    </Button>
                ))}
        </DialogActions>
    );
}
