import { AppContext } from 'pages/_app';
import React, { useContext } from 'react';
import { downloadAsFile } from 'utils/file';
import constants from 'utils/strings/constants';
import { logUploadInfo, getUploadLogs } from 'utils/upload';
import SidebarButton from './Button';

export default function DebugLogs() {
    const appContext = useContext(AppContext);
    const confirmLogDownload = () =>
        appContext.setDialogMessage({
            title: constants.DOWNLOAD_LOGS,
            content: constants.DOWNLOAD_LOGS_MESSAGE(),
            proceed: {
                text: constants.DOWNLOAD,
                variant: 'accent',
                action: downloadUploadLogs,
            },
            close: {
                text: constants.CANCEL,
            },
        });

    const downloadUploadLogs = () => {
        logUploadInfo('exporting logs');
        const logs = getUploadLogs();
        const logString = logs.join('\n');
        downloadAsFile(`upload_logs_${Date.now()}.txt`, logString);
    };

    return (
        <SidebarButton
            onClick={confirmLogDownload}
            typographyVariant="caption"
            sx={{ fontWeight: 'normal', color: 'text.secondary' }}>
            {constants.DOWNLOAD_UPLOAD_LOGS}
        </SidebarButton>
    );
}
