import { AppContext } from 'pages/_app';
import React, { useContext } from 'react';
import { downloadAsFile } from 'utils/file';
import constants from 'utils/strings/constants';
import { addLogLine, getDebugLogs } from 'utils/logging';
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
                action: downloadDebugLogs,
            },
            close: {
                text: constants.CANCEL,
            },
        });

    const downloadDebugLogs = () => {
        addLogLine('exporting logs');
        const logs = getDebugLogs();
        const logString = logs.join('\n');
        downloadAsFile(`debug_logs_${Date.now()}.txt`, logString);
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
