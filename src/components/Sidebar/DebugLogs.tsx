import React from 'react';
import { downloadAsFile } from 'utils/file';
import constants from 'utils/strings/constants';
import { logUploadInfo, getUploadLogs } from 'utils/upload';
import SidebarButton from './Button';

export default function DebugLogs() {
    const downloadUploadLogs = () => {
        logUploadInfo('exporting logs');
        const logs = getUploadLogs();
        const logString = logs.join('\n');
        downloadAsFile(`upload_logs_${Date.now()}.txt`, logString);
    };

    return (
        <SidebarButton
            onClick={downloadUploadLogs}
            typographyVariant="caption"
            sx={{ fontWeight: 'normal', color: 'text.secondary' }}>
            {constants.DOWNLOAD_UPLOAD_LOGS}
        </SidebarButton>
    );
}
