import { Link } from '@mui/material';
import React from 'react';
import { downloadAsFile } from 'utils/file';
import constants from 'utils/strings/constants';
import { logUploadInfo, getUploadLogs } from 'utils/upload';

export default function DebugLogs() {
    const downloadUploadLogs = () => {
        logUploadInfo('exporting logs');
        const logs = getUploadLogs();
        const logString = logs.join('\n');
        downloadAsFile(`upload_logs_${Date.now()}.txt`, logString);
    };

    return (
        <Link
            sx={{
                width: '100%',
                marginTop: '30px',
                marginBottom: '10px',
                fontSize: '14px',
                textAlign: 'center',
                color: 'grey.500',
            }}
            component="button"
            onClick={downloadUploadLogs}>
            {constants.DOWNLOAD_UPLOAD_LOGS}
        </Link>
    );
}
